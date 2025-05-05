import Foundation
import CoreData
import Firebase
import FirebaseAuth
import FirebaseFirestore

class JournalEntryStore: ObservableObject {
    @Published var entries: [JournalEntry] = []
    @Published var atRiskEntries: [JournalEntry] = [] // Track entries at risk of decaying
    @Published var isSyncing = false
    
    // Track if core data is ready
    private var isStoreLoaded = false
    
    // CoreData container
    let container: NSPersistentContainer
    
    // Constants for decay threshold
    private let atRiskThreshold = 75 // Entries with decay level >= this value are considered at risk
    
    // Create a reference to the user achievements tracker
    private var userAchievements: UserAchievements?
    
    init() {
        container = NSPersistentContainer(name: "ReMember")
        
        // Create the directory for the data model if it doesn't exist
        let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        let modelURL = url?.appendingPathComponent("ReMember.sqlite")
        
        // Create directories for media attachments
        createMediaDirectories()
        
        if let modelURL = modelURL, !FileManager.default.fileExists(atPath: modelURL.path) {
            do {
                try FileManager.default.createDirectory(at: url!, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Error creating directory: \(error)")
            }
        }
        
        // Configure persistent container options
        let description = NSPersistentStoreDescription()
        description.url = modelURL
        description.type = NSSQLiteStoreType
        description.shouldAddStoreAsynchronously = false
        container.persistentStoreDescriptions = [description]
        
        container.loadPersistentStores { description, error in
            if let error = error {
                print("Failed to load Core Data: \(error.localizedDescription)")
                
                // Create a backup plan with in-memory store if disk storage fails
                let inMemoryDescription = NSPersistentStoreDescription()
                inMemoryDescription.type = NSInMemoryStoreType
                self.container.persistentStoreDescriptions = [inMemoryDescription]
                
                self.container.loadPersistentStores { desc, err in
                    if let err = err {
                        print("Failed to create in-memory store: \(err)")
                    } else {
                        self.isStoreLoaded = true
                        self.loadEntries()
                    }
                }
            } else {
                self.isStoreLoaded = true
                
                // Load entries immediately after successful store loading
                DispatchQueue.main.async {
                    self.loadEntries()
                }
            }
        }
        
        // Initialize achievements tracker
        self.userAchievements = UserAchievements(container: container)
    }
    
    // Creates directories for storing media attachments
    private func createMediaDirectories() {
        let fileManager = FileManager.default
        let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        
        // Create directory for photos
        let photosURL = appSupportURL.appendingPathComponent("Photos", isDirectory: true)
        
        do {
            try fileManager.createDirectory(at: photosURL, withIntermediateDirectories: true)
        } catch {
            print("Error creating media directories: \(error)")
        }
    }
    
    // Returns the URL for storing photos
    func photoStorageDirectory() -> URL {
        return FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Photos", isDirectory: true)
    }
    
    // Get the current user ID
    private func getCurrentUserID() -> String? {
        return Auth.auth().currentUser?.uid
    }
    
    func loadEntries() {
        guard isStoreLoaded else {
            print("Cannot load entries - store not ready")
            return
        }
        
        let request = NSFetchRequest<JournalEntryEntity>(entityName: "JournalEntryEntity")
        
        // Filter entries by current user ID if logged in
        if let currentUserID = getCurrentUserID() {
            request.predicate = NSPredicate(format: "userID == %@ OR userID == nil", currentUserID)
        }
        
        let sortDescriptor = NSSortDescriptor(keyPath: \JournalEntryEntity.creationDate, ascending: false)
        request.sortDescriptors = [sortDescriptor]
        
        do {
            let fetchedEntities = try container.viewContext.fetch(request)
            
            // Use DispatchQueue.main to ensure UI updates properly
            DispatchQueue.main.async {
                self.entries = fetchedEntities.map { entity in
                    // Extract tags from JSON data
                    var extractedTags: [String] = []
                    if let tagsData = entity.tags {
                        extractedTags = (try? JSONDecoder().decode([String].self, from: tagsData)) ?? []
                    }
                    
                    // Extract photo attachments
                    var photoAttachments: [UUID: URL] = [:]
                    if let photosData = entity.photoAttachments {
                        if let photoDict = try? JSONDecoder().decode([String: String].self, from: photosData) {
                            for (key, value) in photoDict {
                                if let uuid = UUID(uuidString: key) {
                                    // Create an absolute file URL from the stored path
                                    let fileURL = self.photoStorageDirectory().appendingPathComponent(value)
                                    if FileManager.default.fileExists(atPath: fileURL.path) {
                                        photoAttachments[uuid] = fileURL
                                    }
                                }
                            }
                        }
                    }
                    
                    // Extract custom questions
                    var customQuestions: [MemoryQuestion] = []
                    if let questionsData = entity.customQuestions {
                        customQuestions = (try? JSONDecoder().decode([MemoryQuestion].self, from: questionsData)) ?? []
                    }
                    
                    return JournalEntry(
                        id: entity.id ?? UUID(),
                        title: entity.title ?? "Untitled",
                        content: entity.content ?? "",
                        creationDate: entity.creationDate ?? Date(),
                        lastRestoredDate: entity.lastRestoredDate,
                        decayLevel: Int(entity.decayLevel),
                        tags: extractedTags,
                        photoAttachments: photoAttachments,
                        customQuestions: customQuestions,
                        userID: entity.userID
                    )
                }
                
                // Update decay levels for all entries
                for i in 0..<self.entries.count {
                    self.entries[i].calculateDecay()
                }
                
                // Update at-risk entries
                self.updateAtRiskEntries()
                
                // Force objectWillChange notification to update any observing views
                self.objectWillChange.send()
            }
        } catch {
            print("Failed to fetch entries: \(error.localizedDescription)")
        }
    }
    
    func updateAtRiskEntries() {
        atRiskEntries = entries.filter { $0.decayLevel >= atRiskThreshold }
    }
    
    func addEntry(title: String, content: String, tags: [String] = [], photoAttachments: [UUID: URL] = [:], customQuestions: [MemoryQuestion] = []) {
        guard isStoreLoaded else {
            print("Cannot add entry - store not ready")
            return
        }
        
        let newEntry = JournalEntryEntity(context: container.viewContext)
        newEntry.id = UUID()
        newEntry.title = title
        newEntry.content = content
        newEntry.creationDate = Date()
        newEntry.decayLevel = 0
        
        // Store the current user ID with the entry
        newEntry.userID = getCurrentUserID()
        
        // Store tags as JSON data
        if let tagsData = try? JSONEncoder().encode(tags) {
            newEntry.tags = tagsData
        }
        
        // Store photo attachments as JSON data
        if !photoAttachments.isEmpty {
            var photoDict: [String: String] = [:]
            for (key, value) in photoAttachments {
                // Store only the filename component, not the full path
                photoDict[key.uuidString] = value.lastPathComponent
            }
            if let photoData = try? JSONEncoder().encode(photoDict) {
                newEntry.photoAttachments = photoData
            }
        }
        
        // Store custom questions as JSON data
        if !customQuestions.isEmpty {
            if let questionsData = try? JSONEncoder().encode(customQuestions) {
                newEntry.customQuestions = questionsData
            }
        }
        
        // Save to Core Data
        saveContext()
        
        // Also add to our in-memory array
        let entry = JournalEntry(
            id: newEntry.id ?? UUID(),
            title: title,
            content: content,
            creationDate: Date(),
            decayLevel: 0,
            tags: tags,
            photoAttachments: photoAttachments,
            customQuestions: customQuestions,
            userID: newEntry.userID
        )
        
        DispatchQueue.main.async {
            // Add to the beginning of the array since it's the newest
            self.entries.insert(entry, at: 0)
            
            // Force view update
            self.objectWillChange.send()
        }
        
        // Upload to cloud
        if Auth.auth().currentUser != nil {
            Task {
                do {
                    try await FirestoreService.shared.uploadEntry(entry)
                } catch {
                    print("Error uploading entry to cloud: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func updateEntry(_ entry: JournalEntry) {
        // Find the entry in Core Data
        let request = NSFetchRequest<JournalEntryEntity>(entityName: "JournalEntryEntity")
        request.predicate = NSPredicate(format: "id == %@", entry.id as CVarArg)
        
        do {
            let results = try container.viewContext.fetch(request)
            if let entity = results.first {
                // Update the entity
                entity.title = entry.title
                entity.content = entry.content
                // Don't update creation date
                // Don't update decay level directly - it's calculated
                
                // Store tags as JSON
                if let tagsData = try? JSONEncoder().encode(entry.tags) {
                    entity.tags = tagsData
                }
                
                // Store photo attachments as JSON
                if !entry.photoAttachments.isEmpty {
                    var photoDict: [String: String] = [:]
                    for (key, value) in entry.photoAttachments {
                        photoDict[key.uuidString] = value.lastPathComponent
                    }
                    if let photoData = try? JSONEncoder().encode(photoDict) {
                        entity.photoAttachments = photoData
                    }
                }
                
                // Store custom questions as JSON
                if let questionsData = try? JSONEncoder().encode(entry.customQuestions) {
                    entity.customQuestions = questionsData
                }
                
                try container.viewContext.save()
                
                // Update the entry in our local array
                if let index = entries.firstIndex(where: { $0.id == entry.id }) {
                    entries[index] = entry
                }
                
                // Update at-risk entries
                updateAtRiskEntries()
                
                // Signal that the entries have changed
                objectWillChange.send()
                
                // Upload to cloud
                if Auth.auth().currentUser != nil {
                    Task {
                        do {
                            try await FirestoreService.shared.uploadEntry(entry)
                        } catch {
                            print("Error uploading entry update to cloud: \(error.localizedDescription)")
                        }
                    }
                }
            } else {
                print("Failed to find entry in Core Data")
            }
        } catch {
            print("Failed to update entry: \(error.localizedDescription)")
        }
    }
    
    // Restore an entry from decay
    func restoreEntry(id: UUID) {
        // Find the entry in our local array first
        if let index = entries.firstIndex(where: { $0.id == id }) {
            var entry = entries[index]
            
            // Restore entry in memory
            entry.restore()
            entries[index] = entry
            
            // Update at-risk entries
            updateAtRiskEntries()
            
            // Update in Core Data
            let request = NSFetchRequest<JournalEntryEntity>(entityName: "JournalEntryEntity")
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            
            do {
                let results = try container.viewContext.fetch(request)
                if let entity = results.first {
                    entity.lastRestoredDate = Date()
                    entity.decayLevel = 0
                    
                    try container.viewContext.save()
                    
                    // Track successful memory restoration with the achievements system
                    userAchievements?.trackCompletedChallenge(success: true)
                    
                    // Force view update
                    objectWillChange.send()
                    
                    // Upload to cloud
                    if Auth.auth().currentUser != nil {
                        Task {
                            do {
                                try await FirestoreService.shared.uploadEntry(entry)
                            } catch {
                                print("Error uploading restored entry to cloud: \(error.localizedDescription)")
                            }
                        }
                    }
                } else {
                    print("Failed to find entry in Core Data")
                }
            } catch {
                print("Failed to restore entry: \(error.localizedDescription)")
            }
        }
    }
    
    // Get user achievements tracker
    func getUserAchievements() -> UserAchievements? {
        return userAchievements
    }
    
    func deleteEntry(id: UUID) {
        guard isStoreLoaded else {
            print("Cannot delete entry - store not ready")
            return
        }
        
        let request = NSFetchRequest<JournalEntryEntity>(entityName: "JournalEntryEntity")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        do {
            let results = try container.viewContext.fetch(request)
            if let entityToDelete = results.first {
                container.viewContext.delete(entityToDelete)
                saveContext()
                
                // Also delete from cloud
                if Auth.auth().currentUser != nil {
                    Task {
                        do {
                            try await FirestoreService.shared.deleteEntry(id: id)
                        } catch {
                            print("Error deleting entry from cloud: \(error.localizedDescription)")
                        }
                    }
                }
                
                // Force a refresh of entries to ensure UI updates
                loadEntries()
            }
        } catch {
            print("Failed to delete entry: \(error.localizedDescription)")
        }
    }
    
    func saveContext() {
        guard isStoreLoaded else {
            print("Cannot save context - store not ready")
            return
        }
        
        if container.viewContext.hasChanges {
            do {
                try container.viewContext.save()
            } catch {
                print("Failed to save context: \(error.localizedDescription)")
            }
        }
    }
    
    // Returns all unique tags in the system
    func getAllTags() -> [String] {
        var allTags = Set<String>()
        for entry in entries {
            for tag in entry.tags {
                allTags.insert(tag)
            }
        }
        return Array(allTags).sorted()
    }
    
    // Update entries when the user signs in/out
    func refreshEntriesForCurrentUser() {
        loadEntries()
        
        // Sync with cloud if the user is authenticated
        if Auth.auth().currentUser != nil {
            Task {
                await syncWithCloud()
            }
        }
    }
    
    // MARK: - Cloud Synchronization
    
    func syncWithCloud() async {
        guard Auth.auth().currentUser != nil else { 
            return 
        }
        
        DispatchQueue.main.async {
            self.isSyncing = true
        }
        
        do {
            // Use a timeout using Task
            try await withTimeout(seconds: 15) {
                // Fetch cloud entries
                let cloudEntries = try await FirestoreService.shared.fetchEntries()
                
                // Find entries to upload (local-only entries)
                let localEntryIDs = Set(self.entries.map { $0.id })
                let cloudEntryIDs = Set(cloudEntries.map { $0.id })
                
                let localOnlyIDs = localEntryIDs.subtracting(cloudEntryIDs)
                
                // Upload local entries that don't exist in the cloud
                for id in localOnlyIDs {
                    if let entry = self.entries.first(where: { $0.id == id }) {
                        try await FirestoreService.shared.uploadEntry(entry)
                    }
                }
                
                // Download cloud entries that don't exist locally
                let cloudOnlyEntries = cloudEntries.filter { !localEntryIDs.contains($0.id) }
                
                for cloudEntry in cloudOnlyEntries {
                    await self.saveCloudEntryLocally(cloudEntry)
                }
            }
            
            DispatchQueue.main.async {
                self.isSyncing = false
                self.loadEntries() // Refresh the UI after sync
            }
        } catch {
            DispatchQueue.main.async {
                self.isSyncing = false
            }
        }
    }
    
    /// Helper function to add timeout to an async operation
    private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            // Add the main operation
            group.addTask {
                try await operation()
            }
            
            // Add a timeout task
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw NSError(domain: "JournalEntryStore", code: 1, userInfo: [
                    NSLocalizedDescriptionKey: "Operation timed out after \(seconds) seconds"
                ])
            }
            
            // Return the first completed task (either the operation or the timeout)
            let result = try await group.next()!
            // Cancel any remaining tasks
            group.cancelAll()
            return result
        }
    }
    
    private func saveCloudEntryLocally(_ cloudEntry: FirestoreJournalEntry) async {
        // Create a new CoreData entity from the cloud entry
        let context = container.viewContext
        let entity = JournalEntryEntity(context: context)
        
        entity.id = cloudEntry.id
        entity.title = cloudEntry.title
        entity.content = cloudEntry.content
        entity.creationDate = cloudEntry.creationDate
        entity.lastRestoredDate = cloudEntry.lastRestoredDate
        entity.decayLevel = Int16(cloudEntry.decayLevel)
        entity.userID = cloudEntry.userID
        
        // Save tags
        if let tagsData = try? JSONEncoder().encode(cloudEntry.tags) {
            entity.tags = tagsData
        }
        
        // Save custom questions
        if !cloudEntry.customQuestions.isEmpty {
            if let questionsData = try? JSONEncoder().encode(cloudEntry.customQuestions) {
                entity.customQuestions = questionsData
            }
        }
        
        // Handle photo attachments (download required)
        if !cloudEntry.photoAttachmentPaths.isEmpty {
            var localPhotoDict: [String: String] = [:]
            
            for (uuid, path) in cloudEntry.photoAttachmentPaths {
                do {
                    // Download the photo from Firebase Storage
                    let imageData = try await FirestoreService.shared.downloadPhoto(path: path)
                    
                    // Create a local filename
                    let fileName = "\(uuid.uuidString).jpg"
                    let localURL = photoStorageDirectory().appendingPathComponent(fileName)
                    
                    // Save the image to local storage
                    try imageData.write(to: localURL)
                    
                    // Add to local dictionary
                    localPhotoDict[uuid.uuidString] = fileName
                } catch {
                    print("Error downloading photo: \(error.localizedDescription)")
                }
            }
            
            if let photoData = try? JSONEncoder().encode(localPhotoDict) {
                entity.photoAttachments = photoData
            }
        }
        
        // Save to CoreData
        saveContext()
    }
} 