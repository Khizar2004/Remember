import Foundation
import CoreData
import SwiftUI

class UserAchievements: ObservableObject {
    // Streak tracking
    @Published var currentStreak: Int = 0
    @Published var longestStreak: Int = 0
    @Published var lastChallengeDate: Date?
    
    // Achievements
    @Published var totalMemoriesRestored: Int = 0
    @Published var totalChallengesCompleted: Int = 0
    @Published var achievements: [Achievement] = []
    
    // Core Data container reference
    private let container: NSPersistentContainer
    
    init(container: NSPersistentContainer) {
        self.container = container
        loadUserData()
        setupAchievements()
    }
    
    // Track a completed memory challenge
    func trackCompletedChallenge(success: Bool) {
        let today = Calendar.current.startOfDay(for: Date())
        
        if success {
            // Update total challenges
            totalChallengesCompleted += 1
            
            // Update total memories restored if successful
            totalMemoriesRestored += 1
            
            // Check if we need to start a new streak or continue existing one
            if let lastDate = lastChallengeDate {
                let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
                
                if Calendar.current.isDate(lastDate, inSameDayAs: yesterday) || 
                   Calendar.current.isDate(lastDate, inSameDayAs: today) {
                    // Continue streak
                    currentStreak += 1
                } else {
                    // Reset streak
                    currentStreak = 1
                }
            } else {
                // First challenge completed
                currentStreak = 1
            }
            
            // Update longest streak if needed
            if currentStreak > longestStreak {
                longestStreak = currentStreak
            }
            
            // Set last challenge date to today
            lastChallengeDate = today
            
            // Check for unlocked achievements
            checkForAchievements()
            
            // Save changes
            saveUserData()
        }
    }
    
    // Setup available achievements
    private func setupAchievements() {
        achievements = [
            Achievement(id: "first_memory", 
                       title: "First Memory Restored", 
                       description: "Successfully restore your first memory", 
                       requiredCount: 1, 
                       type: .memoriesRestored),
            
            Achievement(id: "10_memories", 
                       title: "Memory Keeper", 
                       description: "Successfully restore 10 memories", 
                       requiredCount: 10, 
                       type: .memoriesRestored),
            
            Achievement(id: "memory_master", 
                       title: "Memory Master", 
                       description: "Successfully restore 50 memories", 
                       requiredCount: 50, 
                       type: .memoriesRestored),
            
            Achievement(id: "3_day_streak", 
                       title: "Consistent", 
                       description: "Complete memory challenges 3 days in a row", 
                       requiredCount: 3, 
                       type: .streak),
            
            Achievement(id: "7_day_streak", 
                       title: "Dedicated", 
                       description: "Complete memory challenges 7 days in a row", 
                       requiredCount: 7, 
                       type: .streak),
            
            Achievement(id: "30_day_streak", 
                       title: "Memory Guardian", 
                       description: "Complete memory challenges 30 days in a row", 
                       requiredCount: 30, 
                       type: .streak)
        ]
        
        // Load unlocked status from UserDefaults
        for index in 0..<achievements.count {
            let isUnlocked = UserDefaults.standard.bool(forKey: "achievement_\(achievements[index].id)")
            achievements[index].isUnlocked = isUnlocked
        }
    }
    
    // Check and update achievements
    private func checkForAchievements() {
        for index in 0..<achievements.count {
            if !achievements[index].isUnlocked {
                var unlocked = false
                
                switch achievements[index].type {
                case .memoriesRestored:
                    unlocked = totalMemoriesRestored >= achievements[index].requiredCount
                case .streak:
                    unlocked = currentStreak >= achievements[index].requiredCount
                }
                
                if unlocked {
                    achievements[index].isUnlocked = true
                    achievements[index].unlockDate = Date()
                    
                    // Save achievement status
                    UserDefaults.standard.set(true, forKey: "achievement_\(achievements[index].id)")
                    
                    // Notify the user
                    NotificationCenter.default.post(
                        name: NSNotification.Name("AchievementUnlocked"),
                        object: achievements[index]
                    )
                }
            }
        }
    }
    
    // Load user data from CoreData
    private func loadUserData() {
        let defaults = UserDefaults.standard
        currentStreak = defaults.integer(forKey: "currentStreak")
        longestStreak = defaults.integer(forKey: "longestStreak")
        totalMemoriesRestored = defaults.integer(forKey: "totalMemoriesRestored")
        totalChallengesCompleted = defaults.integer(forKey: "totalChallengesCompleted")
        
        if let lastDate = defaults.object(forKey: "lastChallengeDate") as? Date {
            lastChallengeDate = lastDate
        }
    }
    
    // Save user data to CoreData
    private func saveUserData() {
        let defaults = UserDefaults.standard
        defaults.set(currentStreak, forKey: "currentStreak")
        defaults.set(longestStreak, forKey: "longestStreak")
        defaults.set(totalMemoriesRestored, forKey: "totalMemoriesRestored")
        defaults.set(totalChallengesCompleted, forKey: "totalChallengesCompleted")
        
        if let lastDate = lastChallengeDate {
            defaults.set(lastDate, forKey: "lastChallengeDate")
        }
    }
}

// Achievement types
enum AchievementType {
    case memoriesRestored
    case streak
}

// Achievement struct
struct Achievement: Identifiable {
    let id: String
    let title: String
    let description: String
    let requiredCount: Int
    let type: AchievementType
    var isUnlocked: Bool = false
    var unlockDate: Date?
} 