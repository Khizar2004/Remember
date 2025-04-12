import Foundation
import SwiftUI
import Combine

class EntryViewModel: ObservableObject {
    @Published var entry: JournalEntry?
    @Published var title: String = ""
    @Published var content: String = ""
    @Published var isEditing: Bool = false
    @Published var showRestoreAnimation: Bool = false
    @Published var restorationProgress: Double = 0.0
    @Published var entrySaved: Bool = false
    
    private let store: JournalEntryStore
    private var restorationTimer: Timer?
    
    // Public accessor for the store
    var viewModelStore: JournalEntryStore {
        return store
    }
    
    init(store: JournalEntryStore, entry: JournalEntry? = nil) {
        self.store = store
        
        if let existingEntry = entry {
            self.entry = existingEntry
            self.title = existingEntry.title
            self.content = existingEntry.content
            self.isEditing = true
        }
    }
    
    func saveEntry() {
        if isEditing, let existingEntry = entry {
            // Update existing entry
            var updatedEntry = existingEntry
            updatedEntry.title = title
            updatedEntry.content = content
            store.updateEntry(updatedEntry)
        } else {
            // Create new entry
            store.addEntry(title: title, content: content)
        }
        
        // Explicitly reload entries to ensure UI updates
        store.loadEntries()
        
        // Signal that entry was saved
        entrySaved = true
        
        // Reset fields
        title = ""
        content = ""
    }
    
    func restoreEntry() {
        guard let entry = entry else { return }
        
        // Start restoration animation
        showRestoreAnimation = true
        restorationProgress = 0.0
        
        // Simulate restoration process with timer
        restorationTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            self.restorationProgress += 0.01
            
            if self.restorationProgress >= 1.0 {
                timer.invalidate()
                self.completeRestoration()
            }
        }
    }
    
    private func completeRestoration() {
        guard let entry = entry else { return }
        
        // Apply restoration in store
        store.restoreEntry(id: entry.id)
        
        // Explicitly reload entries to ensure UI updates
        store.loadEntries()
        
        // Update local entry with restored version
        if let restoredIndex = store.entries.firstIndex(where: { $0.id == entry.id }) {
            self.entry = store.entries[restoredIndex]
        }
        
        // End animation after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.showRestoreAnimation = false
        }
    }
} 