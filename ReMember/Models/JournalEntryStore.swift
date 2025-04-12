import Foundation
import CoreData
import SwiftUI

class JournalEntryStore: ObservableObject {
    @Published var entries: [JournalEntry] = []
    @Published var atRiskEntries: [JournalEntry] = [] // Track entries at risk of decaying
    
    // Track if core data is ready
    private var isStoreLoaded = false
    
    // CoreData container
    let container: NSPersistentContainer
    
    // Constants for decay threshold
    private let atRiskThreshold = 75 // Entries with decay level >= this value are considered at risk
    
    init() {
        print("Initializing JournalEntryStore")
        container = NSPersistentContainer(name: "ReMember")
        
        // Create the directory for the data model if it doesn't exist
        let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        let modelURL = url?.appendingPathComponent("ReMember.sqlite")
        
        // Create directories for media attachments
        createMediaDirectories()
        
        if let modelURL = modelURL, !FileManager.default.fileExists(atPath: modelURL.path) {
            do {
                try FileManager.default.createDirectory(at: url!, withIntermediateDirectories: true, attributes: nil)
                print("Created directory for Core Data store")
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
                        print("Created in-memory store as fallback")
                        self.isStoreLoaded = true
                        self.loadEntries()
                    }
                }
            } else {
                print("Core Data loaded successfully")
                self.isStoreLoaded = true
                
                // Load entries immediately after successful store loading
                DispatchQueue.main.async {
                    self.loadEntries()
                }
            }
        }
    }
    
    // Creates directories for storing media attachments
    private func createMediaDirectories() {
        let fileManager = FileManager.default
        let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        
        // Create directory for photos
        let photosURL = appSupportURL.appendingPathComponent("Photos", isDirectory: true)
        
        do {
            try fileManager.createDirectory(at: photosURL, withIntermediateDirectories: true)
            print("Created media directories")
        } catch {
            print("Error creating media directories: \(error)")
        }
    }
    
    // Returns the URL for storing photos
    func photoStorageDirectory() -> URL {
        return FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Photos", isDirectory: true)
    }
    
    func loadEntries() {
        guard isStoreLoaded else {
            print("Cannot load entries - store not ready")
            return
        }
        
        let request = NSFetchRequest<JournalEntryEntity>(entityName: "JournalEntryEntity")
        let sortDescriptor = NSSortDescriptor(keyPath: \JournalEntryEntity.creationDate, ascending: false)
        request.sortDescriptors = [sortDescriptor]
        
        do {
            let fetchedEntities = try container.viewContext.fetch(request)
            print("Fetched \(fetchedEntities.count) entries from Core Data")
            
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
                    
                    return JournalEntry(
                        id: entity.id ?? UUID(),
                        title: entity.title ?? "Untitled",
                        content: entity.content ?? "",
                        creationDate: entity.creationDate ?? Date(),
                        lastRestoredDate: entity.lastRestoredDate,
                        decayLevel: Int(entity.decayLevel),
                        tags: extractedTags,
                        photoAttachments: photoAttachments
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
                print("Updated entries array with \(self.entries.count) entries")
            }
        } catch {
            print("Failed to fetch entries: \(error.localizedDescription)")
        }
    }
    
    func updateAtRiskEntries() {
        atRiskEntries = entries.filter { $0.decayLevel >= atRiskThreshold }
    }
    
    func addEntry(title: String, content: String, tags: [String] = [], photoAttachments: [UUID: URL] = [:]) {
        print("Adding new entry with title: \(title)")
        
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
        
        saveContext()
        
        // Force a refresh of entries to ensure UI updates
        loadEntries()
    }
    
    func updateEntry(_ entry: JournalEntry) {
        guard isStoreLoaded else {
            print("Cannot update entry - store not ready")
            return
        }
        
        let request = NSFetchRequest<JournalEntryEntity>(entityName: "JournalEntryEntity")
        request.predicate = NSPredicate(format: "id == %@", entry.id as CVarArg)
        
        do {
            let results = try container.viewContext.fetch(request)
            if let entityToUpdate = results.first {
                entityToUpdate.title = entry.title
                entityToUpdate.content = entry.content
                entityToUpdate.lastRestoredDate = entry.lastRestoredDate
                entityToUpdate.decayLevel = Int16(entry.decayLevel)
                
                // Store tags as JSON data
                if let tagsData = try? JSONEncoder().encode(entry.tags) {
                    entityToUpdate.tags = tagsData
                }
                
                // Store photo attachments as JSON data - improved
                if !entry.photoAttachments.isEmpty {
                    var photoDict: [String: String] = [:]
                    for (key, value) in entry.photoAttachments {
                        // Store only the filename component, not the full path
                        photoDict[key.uuidString] = value.lastPathComponent
                    }
                    if let photoData = try? JSONEncoder().encode(photoDict) {
                        entityToUpdate.photoAttachments = photoData
                    }
                } else {
                    entityToUpdate.photoAttachments = nil
                }
                
                // Save context immediately
                saveContext()
                
                // Update entries array directly to ensure proper UI updates
                if let index = entries.firstIndex(where: { $0.id == entry.id }) {
                    DispatchQueue.main.async {
                        // Replace the entry in the array with the updated one
                        self.entries[index] = entry
                        
                        // Force UI refresh 
                        self.objectWillChange.send()
                    }
                }
                
                // Also reload entries to ensure consistency
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.loadEntries()
                }
            }
        } catch {
            print("Failed to update entry: \(error.localizedDescription)")
        }
    }
    
    func restoreEntry(id: UUID) {
        if let index = entries.firstIndex(where: { $0.id == id }) {
            var entryToRestore = entries[index]
            entryToRestore.restore()
            updateEntry(entryToRestore)
        }
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
                print("Context saved successfully")
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
} 