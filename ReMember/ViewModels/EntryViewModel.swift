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
    
    @Published var photoAttachments: [UUID: URL] = [:]
    
    @Published var customQuestionsForNewEntry: [MemoryQuestion] = []
    
    private let store: JournalEntryStore
    private var restorationTimer: Timer?
    
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
            var updatedEntry = existingEntry
            updatedEntry.title = title
            updatedEntry.content = content
            updatedEntry.tags = tags
            updatedEntry.photoAttachments = photoAttachments
            store.updateEntry(updatedEntry)
            
            DispatchQueue.main.async {
                if let index = self.store.entries.firstIndex(where: { $0.id == updatedEntry.id }) {
                    self.entry = self.store.entries[index]
                }
                
                self.objectWillChange.send()
            }
        } else {
            store.addEntry(
                title: title,
                content: content,
                tags: tags,
                photoAttachments: photoAttachments,
                customQuestions: customQuestionsForNewEntry
            )
        }
        
        store.loadEntries()
        
        entrySaved = true
        
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
        
        showRestoreAnimation = true
        restorationProgress = 0.0
        
        restorationTimer?.invalidate()
        restorationTimer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { [weak self] timer in
            guard let self = self else { 
                timer.invalidate()
                return 
            }
            
            self.restorationProgress += 0.01
            
            if self.restorationProgress >= 1.0 {
                timer.invalidate()
                self.restorationTimer = nil
                
                self.store.restoreEntry(id: entryToRestore.id)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.showRestoreAnimation = false
                    
                    HapticFeedback.success()
                    
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
            try FileManager.default.createDirectory(at: store.photoStorageDirectory(), 
                                                   withIntermediateDirectories: true)
            
            try imageData.write(to: photoURL)
            
            photoAttachments[photoID] = photoURL
            
            if isEditing, let existingEntry = entry {
                var updatedEntry = existingEntry
                updatedEntry.photoAttachments = photoAttachments
                
                DispatchQueue.main.async {
                    self.store.updateEntry(updatedEntry)
                    self.entry = updatedEntry
                    
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
    
    func reloadEntries() {
        store.loadEntries()
    }
    
    func startMemoryChallenge() {
        showingMemoryChallenge = true
    }
    
    func restoreMemory() {
        guard let entryToRestore = entry else { return }
        
        showRestoreAnimation = true
        restorationProgress = 0.0
        
        restorationTimer?.invalidate()
        restorationTimer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { [weak self] timer in
            guard let self = self else { 
                timer.invalidate()
                return 
            }
            
            self.restorationProgress += 0.01
            
            if self.restorationProgress >= 1.0 {
                timer.invalidate()
                self.restorationTimer = nil
                
                self.store.restoreEntry(id: entryToRestore.id)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.showRestoreAnimation = false
                    
                    HapticFeedback.success()
                    
                    if let index = self.store.entries.firstIndex(where: { $0.id == entryToRestore.id }) {
                        self.entry = self.store.entries[index]
                    }
                }
            }
        }
    }
}