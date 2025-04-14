import Foundation
import SwiftUI

// Custom question structure
struct MemoryQuestion: Identifiable, Codable {
    let id: UUID
    var question: String
    var answer: String
    
    init(id: UUID = UUID(), question: String, answer: String) {
        self.id = id
        self.question = question
        self.answer = answer
    }
}

struct JournalEntry: Identifiable {
    let id: UUID
    var title: String
    var content: String
    var creationDate: Date
    var lastRestoredDate: Date?
    var decayLevel: Int // 0-100, where 100 is completely decayed
    var tags: [String] = []
    var photoAttachments: [UUID: URL] = [:] // Store photo URLs keyed by UUID
    var customQuestions: [MemoryQuestion] = [] // Custom memory questions
    
    init(id: UUID = UUID(), title: String, content: String, creationDate: Date = Date(), lastRestoredDate: Date? = nil, decayLevel: Int = 0, tags: [String] = [], photoAttachments: [UUID: URL] = [:], customQuestions: [MemoryQuestion] = []) {
        self.id = id
        self.title = title
        self.content = content
        self.creationDate = creationDate
        self.lastRestoredDate = lastRestoredDate
        self.decayLevel = decayLevel
        self.tags = tags
        self.photoAttachments = photoAttachments
        self.customQuestions = customQuestions
    }
    
    mutating func calculateDecay() {
        // Get the current decay time unit from settings
        let timeUnit = UserSettings.shared.decayTimeUnit
        
        // Calculate decay based on time passed
        let calendar = Calendar.current
        let now = Date()
        
        // Calculate total minutes since creation or restoration
        let minutesSinceLastUpdate = calendar.dateComponents([.minute], from: lastRestoredDate ?? creationDate, to: now).minute ?? 0
        
        // Convert minutes to the selected unit
        let unitsElapsed = Double(minutesSinceLastUpdate) / timeUnit.minuteMultiplier
        
        // Apply decay rate - 5 points per unit (day, hour, or minute)
        // For minutes: 5 points per minute (very fast decay for testing)
        let decayRate = 5.0
        decayLevel = min(Int(unitsElapsed * decayRate), 100)
    }
    
    mutating func restore() {
        self.lastRestoredDate = Date()
        self.decayLevel = 0
    }
    
    mutating func addTag(_ tag: String) {
        if !tag.isEmpty && !tags.contains(tag) {
            tags.append(tag)
        }
    }
    
    mutating func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
    }
    
    mutating func addPhotoAttachment(url: URL) -> UUID {
        let photoID = UUID()
        photoAttachments[photoID] = url
        return photoID
    }
    
    mutating func removePhotoAttachment(id: UUID) {
        photoAttachments.removeValue(forKey: id)
    }
    
    mutating func addQuestion(question: String, answer: String) {
        let newQuestion = MemoryQuestion(question: question, answer: answer)
        customQuestions.append(newQuestion)
    }
    
    mutating func removeQuestion(id: UUID) {
        customQuestions.removeAll { $0.id == id }
    }
    
    // Check if this memory has protection questions
    var hasProtectionQuestions: Bool {
        return !customQuestions.isEmpty
    }
} 