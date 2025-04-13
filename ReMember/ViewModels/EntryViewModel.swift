import Foundation
import SwiftUI
import Combine

class EntryViewModel: ObservableObject {
    @Published var entry: JournalEntry?
    @Published var title: String = ""
    @Published var content: String = ""
    @Published var tags: [String] = []
    @Published var isEditing: Bool = false
    @Published var showRestoreAnimation: Bool = false
    @Published var restorationProgress: Double = 0.0
    @Published var entrySaved: Bool = false
    @Published var newTagText: String = ""
    @Published var showingMemoryChallenge: Bool = false
    
    // Media attachment properties
    @Published var photoAttachments: [UUID: URL] = [:]
    
    // Temporary storage for custom questions when creating a new entry
    @Published var customQuestionsForNewEntry: [MemoryQuestion] = []
    
    private let store: JournalEntryStore
    private var restorationTimer: Timer?
    
    // Public accessor for the store
    var viewModelStore: JournalEntryStore {
        return store
    }
    
    var availableTags: [String] {
        store.getAllTags()
    }
    
    init(store: JournalEntryStore, entry: JournalEntry? = nil) {
        self.store = store
        
        if let existingEntry = entry {
            self.entry = existingEntry
            self.title = existingEntry.title
            self.content = existingEntry.content
            self.tags = existingEntry.tags
            self.photoAttachments = existingEntry.photoAttachments
            self.isEditing = true
        }
    }
    
    func saveEntry() {
        if isEditing, let existingEntry = entry {
            // Update existing entry
            var updatedEntry = existingEntry
            updatedEntry.title = title
            updatedEntry.content = content
            updatedEntry.tags = tags
            updatedEntry.photoAttachments = photoAttachments
            // Make sure we preserve customQuestions from the entry object
            // customQuestions are updated in the Entry object separately before this call
            store.updateEntry(updatedEntry)
            
            // Update the entry reference to trigger UI updates
            DispatchQueue.main.async {
                // Reload the entry from the store to ensure we have the latest version
                if let index = self.store.entries.firstIndex(where: { $0.id == updatedEntry.id }) {
                    self.entry = self.store.entries[index]
                }
                
                // Force UI update
                self.objectWillChange.send()
            }
        } else {
            // Create new entry
            store.addEntry(
                title: title,
                content: content,
                tags: tags,
                photoAttachments: photoAttachments,
                customQuestions: customQuestionsForNewEntry
            )
        }
        
        // Explicitly reload entries to ensure UI updates
        store.loadEntries()
        
        // Signal that entry was saved
        entrySaved = true
        
        // Reset fields if not editing
        if !isEditing {
            title = ""
            content = ""
            tags = []
            newTagText = ""
            photoAttachments = [:]
            customQuestionsForNewEntry = []
        }
    }
    
    func addTag() {
        let tag = newTagText.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if !tag.isEmpty && !tags.contains(tag) {
            tags.append(tag)
            newTagText = ""
        }
    }
    
    func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
    }
    
    func initiateRestoration() {
        guard let entryToRestore = entry else { return }
        
        // Start restoration animation
        showRestoreAnimation = true
        restorationProgress = 0.0
        
        // Create restoration animation
        restorationTimer?.invalidate()
        restorationTimer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { [weak self] timer in
            guard let self = self else { 
                timer.invalidate()
                return 
            }
            
            // Increase progress
            self.restorationProgress += 0.01
            
            // Finish restoration
            if self.restorationProgress >= 1.0 {
                timer.invalidate()
                self.restorationTimer = nil
                
                // Restore memory in the store
                self.store.restoreEntry(id: entryToRestore.id)
                
                // Update local entry reference
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    // Dismiss restoration animation
                    self.showRestoreAnimation = false
                    
                    // Trigger haptic feedback 
                    HapticFeedback.success()
                    
                    // Update UI with the restored entry
                    if let index = self.store.entries.firstIndex(where: { $0.id == entryToRestore.id }) {
                        self.entry = self.store.entries[index]
                    }
                }
            }
        }
    }
    
    // MARK: - Photo Management
    
    func addPhotoAttachment(imageData: Data) -> UUID? {
        let photoID = UUID()
        let fileName = "\(photoID.uuidString).jpg"
        let photoURL = store.photoStorageDirectory().appendingPathComponent(fileName)
        
        do {
            // Create the directory if it doesn't exist
            try FileManager.default.createDirectory(at: store.photoStorageDirectory(), 
                                                   withIntermediateDirectories: true)
            
            // Write the image data to the file
            try imageData.write(to: photoURL)
            
            // Store the URL in the dictionary
            photoAttachments[photoID] = photoURL
            
            // If this is an existing entry, update it immediately
            if isEditing, let existingEntry = entry {
                var updatedEntry = existingEntry
                updatedEntry.photoAttachments = photoAttachments
                
                // Update the entry in store and refresh local reference
                DispatchQueue.main.async {
                    self.store.updateEntry(updatedEntry)
                    self.entry = updatedEntry
                    
                    // Force UI refresh
                    self.objectWillChange.send()
                }
            }
            
            return photoID
        } catch {
            return nil
        }
    }
    
    func removePhotoAttachment(id: UUID) {
        guard let url = photoAttachments[id] else { return }
        
        do {
            try FileManager.default.removeItem(at: url)
            photoAttachments.removeValue(forKey: id)
        } catch {
            print("Failed to delete photo file: \(error)")
        }
    }
    
    // Add this method to make the loadEntries functionality accessible without exposing store directly
    func reloadEntries() {
        store.loadEntries()
    }
    
    // Start a memory challenge for this entry
    func startMemoryChallenge() {
        showingMemoryChallenge = true
    }
    
    // Restore memory after successful challenge
    func restoreMemory() {
        guard let entryToRestore = entry else { return }
        
        // Restore memory in the store
        store.restoreEntry(id: entryToRestore.id)
        
        // Update local entry reference
        if let index = store.entries.firstIndex(where: { $0.id == entryToRestore.id }) {
            self.entry = store.entries[index]
            // Force UI refresh
            self.objectWillChange.send()
        }
    }
} 