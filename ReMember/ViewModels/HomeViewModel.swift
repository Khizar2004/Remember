import Foundation
import SwiftUI
import Combine

class HomeViewModel: ObservableObject {
    @Published var store: JournalEntryStore
    @Published var isLoading = false
    @Published var searchText = ""
    @Published var lastRefresh = Date() // Track when entries were last refreshed
    
    private var cancellables = Set<AnyCancellable>()
    
    var filteredEntries: [JournalEntry] {
        if searchText.isEmpty {
            return store.entries
        } else {
            return store.entries.filter { entry in
                entry.title.localizedCaseInsensitiveContains(searchText) ||
                entry.content.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    init(store: JournalEntryStore = JournalEntryStore()) {
        self.store = store
        print("HomeViewModel initialized with store")
        
        // Watch for changes in the store's entries
        self.store.$entries
            .sink { [weak self] _ in
                print("Store entries changed - notifying HomeViewModel")
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
        
        // Update decay levels periodically
        Timer.publish(every: 300, on: .main, in: .common) // Every 5 minutes
            .autoconnect()
            .sink { [weak self] _ in
                print("Timer triggered refresh")
                self?.refreshEntries()
            }
            .store(in: &cancellables)
    }
    
    func refreshEntries() {
        print("HomeViewModel refreshing entries")
        isLoading = true
        
        // Force Core Data to reload and update the UI
        store.loadEntries()
        
        // Update the refresh time
        DispatchQueue.main.async {
            self.lastRefresh = Date()
            self.isLoading = false
            self.objectWillChange.send()
            print("HomeViewModel completed refresh")
        }
    }
    
    func deleteEntry(at offsets: IndexSet) {
        for index in offsets {
            if index < filteredEntries.count {
                let entry = filteredEntries[index]
                store.deleteEntry(id: entry.id)
            }
        }
    }
    
    func deleteEntry(id: UUID) {
        // Add a small delay to allow for animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            self.store.deleteEntry(id: id)
            HapticFeedback.heavy() // Stronger feedback when deletion completes
        }
    }
    
    func restoreEntry(id: UUID) {
        store.restoreEntry(id: id)
    }
} 