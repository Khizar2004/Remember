import Foundation
import SwiftUI
import Combine
import UserNotifications
import Firebase
import FirebaseAuth

class HomeViewModel: ObservableObject {
    @Published var store: JournalEntryStore
    @Published var isLoading = false
    @Published var searchText = ""
    @Published var lastRefresh = Date() // Track when entries were last refreshed
    @Published var selectedTags: [String] = []
    @Published var showingDecayTimeline = false // Control for showing decay timeline
    @Published var notificationsAuthorized = false // Track if notifications are authorized
    @Published var showingAchievements = false // Control for showing achievements view
    @Published var selectedChallengeEntry: JournalEntry? // Entry selected for challenge
    @Published var showingSettings = false // Control for showing settings view
    @Published var isSyncing: Bool = false
    @Published var syncMessage: String? = nil
    
    private var cancellables = Set<AnyCancellable>()
    
    var filteredEntries: [JournalEntry] {
        var filtered = store.entries
        
        if !searchText.isEmpty {
            filtered = filtered.filter { entry in
                entry.title.localizedCaseInsensitiveContains(searchText) ||
                entry.content.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        if !selectedTags.isEmpty {
            filtered = filtered.filter { entry in
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
    
    var userAchievements: UserAchievements? {
        return store.getUserAchievements()
    }
    
    var isUserLoggedIn: Bool {
        return Auth.auth().currentUser != nil
    }
    
    init(store: JournalEntryStore = JournalEntryStore()) {
        self.store = store
        
        self.store.$entries
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
        
        self.store.$atRiskEntries
            .sink { [weak self] entries in
                self?.checkForAtRiskEntries(entries)
            }
            .store(in: &cancellables)
        
        self.store.$isSyncing
            .sink { [weak self] isSyncing in
                self?.isSyncing = isSyncing
            }
            .store(in: &cancellables)
        
        // Refresh entries and sync with cloud every 15 seconds
        Timer.publish(every: 15, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.refreshEntries()
                // Auto-sync with cloud every minute (less frequent than the UI refresh)
                if Date().timeIntervalSince1970.truncatingRemainder(dividingBy: 60) < 15 {
                    self?.quietlySyncWithCloud()
                }
            }
            .store(in: &cancellables)
        
        requestNotificationAuthorization()
        
        // Initial sync when app starts
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
            self?.quietlySyncWithCloud()
        }
    }
    
    func refreshEntries() {
        isLoading = true
        
        store.loadEntries()
        
        DispatchQueue.main.async {
            self.lastRefresh = Date()
            self.isLoading = false
            self.objectWillChange.send()
        }
    }
    
    // Quiet sync without UI indicators - for automatic background sync
    private func quietlySyncWithCloud() {
        guard isUserLoggedIn, !isSyncing else { return }
        
        Task {
            do {
                await store.syncWithCloud()
            } catch {
                // Silent failure - no need to log for background operations
            }
        }
    }
    
    // Helper function to add timeout to an async operation
    private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            // Add the main operation
            group.addTask {
                try await operation()
            }
            
            // Add a timeout task
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw NSError(domain: "HomeViewModel", code: 1, userInfo: [
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            self.store.deleteEntry(id: id)
            HapticFeedback.heavy()
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
                if let error = error {
                    print("Failed to request notification authorization: \(error)")
                }
            }
        }
    }
    
    private func checkForAtRiskEntries(_ entries: [JournalEntry]) {
        guard notificationsAuthorized, !entries.isEmpty else { return }
        
        let center = UNUserNotificationCenter.current()
        
        center.removeAllPendingNotificationRequests()
        
        let defaults = UserDefaults.standard
        let lastNotificationTimeKey = "lastNotificationTime"
        let currentTime = Date().timeIntervalSince1970
        
        let notificationThrottleInterval: TimeInterval = 3600
        let lastNotificationTime = defaults.double(forKey: lastNotificationTimeKey)
        
        if currentTime - lastNotificationTime < notificationThrottleInterval {
            return
        }
        
        let notifiableEntries = entries.filter { $0.decayLevel >= 50 && $0.decayLevel < 100 }
        
        guard !notifiableEntries.isEmpty else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Memories at Risk"
        
        if notifiableEntries.count == 1 {
            let entry = notifiableEntries[0]
            content.body = "Your memory '\(entry.title)' is fading. Restore it soon."
        } else {
            content.body = "\(notifiableEntries.count) memories are at risk of fading. Restore them soon."
        }
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "memory-decay-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            } else {
                defaults.set(currentTime, forKey: lastNotificationTimeKey)
            }
        }
    }
    
    func toggleDecayTimeline() {
        showingDecayTimeline.toggle()
    }
    
    func toggleAchievements() {
        // If showing decay timeline, hide it first
        if showingDecayTimeline {
            showingDecayTimeline = false
            // Small delay to avoid animation conflicts
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.spring()) {
                    self.showingAchievements.toggle()
                }
            }
        } else {
            withAnimation(.spring()) {
                showingAchievements.toggle()
            }
        }
    }
    
    func toggleSettings() {
        showingSettings.toggle()
    }
    
    func startMemoryChallenge(for entry: JournalEntry) {
        selectedChallengeEntry = entry
    }
}

struct DecayGroup: Identifiable {
    var id: String { name }
    let name: String
    let range: Range<Int>
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