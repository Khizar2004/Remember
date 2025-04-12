import Foundation
import SwiftUI

struct JournalEntry: Identifiable {
    let id: UUID
    var title: String
    var content: String
    var creationDate: Date
    var lastRestoredDate: Date?
    var decayLevel: Int // 0-100, where 100 is completely decayed
    
    init(id: UUID = UUID(), title: String, content: String, creationDate: Date = Date(), lastRestoredDate: Date? = nil, decayLevel: Int = 0) {
        self.id = id
        self.title = title
        self.content = content
        self.creationDate = creationDate
        self.lastRestoredDate = lastRestoredDate
        self.decayLevel = decayLevel
    }
    
    mutating func calculateDecay() {
        // Calculate decay based on time passed
        let calendar = Calendar.current
        let now = Date()
        let daysSinceCreation = calendar.dateComponents([.day], from: lastRestoredDate ?? creationDate, to: now).day ?? 0
        
        // Simple decay algorithm: increase by 5 points per day, max 100
        decayLevel = min(daysSinceCreation * 5, 100)
    }
    
    mutating func restore() {
        self.lastRestoredDate = Date()
        self.decayLevel = 0
    }
} 