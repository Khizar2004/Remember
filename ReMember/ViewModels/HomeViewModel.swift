import Foundation
import SwiftUI
import Combine
import UserNotifications

class HomeViewModel: ObservableObject {
    @Published var store: JournalEntryStore
    @Published var isLoading = false
    @Published var searchText = ""
    @Published var lastRefresh = Date() // Track when entries were last refreshed
    @Published var selectedTags: [String] = []
    @Published var showingDecayTimeline = false // Control for showing decay timeline
    @Published var notificationsAuthorized = false // Track if notifications are authorized
    
    private var cancellables = Set<AnyCancellable>()
    
    var filteredEntries: [JournalEntry] {
        var filtered = store.entries
        
        // Apply text search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { entry in
                entry.title.localizedCaseInsensitiveContains(searchText) ||
                entry.content.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Apply tag filter if any tags are selected
        if !selectedTags.isEmpty {
            filtered = filtered.filter { entry in
                // Entry must contain at least one of the selected tags
                return entry.tags.contains { tag in
                    selectedTags.contains(tag)
                }
            }
        }
        
        return filtered
    }
    
    var atRiskEntries: [JournalEntry] {
        return store.atRiskEntries
    }
    
    var availableTags: [String] {
        store.getAllTags()
    }
    
    // Group entries by decay level for timeline visualization
    var entriesByDecayLevel: [DecayGroup] {
        let groups = [
            DecayGroup(name: "Fresh", range: 0..<25, entries: []),
            DecayGroup(name: "Fading", range: 25..<50, entries: []),
            DecayGroup(name: "Degrading", range: 50..<75, entries: []),
            DecayGroup(name: "Critical", range: 75..<101, entries: [])
        ]
        
        var result = groups
        
        for entry in store.entries {
            for i in 0..<result.count {
                if result[i].range.contains(entry.decayLevel) {
                    result[i].entries.append(entry)
                    break
                }
            }
        }
        
        return result
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
        
        // Watch for changes in at-risk entries
        self.store.$atRiskEntries
            .sink { [weak self] entries in
                print("At-risk entries changed: \(entries.count)")
                self?.checkForAtRiskEntries(entries)
            }
            .store(in: &cancellables)
        
        // Update decay levels periodically
        Timer.publish(every: 15, on: .main, in: .common) // Every 15 seconds
            .autoconnect()
            .sink { [weak self] _ in
                print("Timer triggered refresh")
                self?.refreshEntries()
            }
            .store(in: &cancellables)
        
        // Request notification authorization
        requestNotificationAuthorization()
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
    
    func toggleTag(_ tag: String) {
        if selectedTags.contains(tag) {
            selectedTags.removeAll { $0 == tag }
        } else {
            selectedTags.append(tag)
        }
        objectWillChange.send()
    }
    
    func clearTagSelection() {
        selectedTags.removeAll()
        objectWillChange.send()
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
    
    // MARK: - Notification System
    
    private func requestNotificationAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                self.notificationsAuthorized = granted
                if granted {
                    print("Notification authorization granted")
                } else if let error = error {
                    print("Failed to request notification authorization: \(error)")
                }
            }
        }
    }
    
    private func checkForAtRiskEntries(_ entries: [JournalEntry]) {
        guard notificationsAuthorized, !entries.isEmpty else { return }
        
        // Get the current notification center
        let center = UNUserNotificationCenter.current()
        
        // Clear existing notifications
        center.removeAllPendingNotificationRequests()
        
        // Create a notification for each at-risk entry
        for entry in entries {
            let content = UNMutableNotificationContent()
            content.title = "Memory at Risk of Decay"
            content.body = "Your memory '\(entry.title)' is fading. Restore it soon to preserve it."
            content.sound = .default
            
            // Create a trigger that fires immediately
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            
            // Create the request
            let request = UNNotificationRequest(
                identifier: entry.id.uuidString,
                content: content,
                trigger: trigger
            )
            
            // Add the request to the notification center
            center.add(request) { error in
                if let error = error {
                    print("Error scheduling notification: \(error)")
                }
            }
        }
    }
    
    func toggleDecayTimeline() {
        showingDecayTimeline.toggle()
    }
}

// Structure to group entries by decay level for visualization
struct DecayGroup: Identifiable {
    var id = UUID()
    var name: String
    var range: Range<Int>
    var entries: [JournalEntry]
    
    var color: Color {
        switch name {
        case "Fresh": return .green
        case "Fading": return .yellow
        case "Degrading": return .orange
        case "Critical": return .red
        default: return .gray
        }
    }
} 