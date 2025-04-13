import Foundation
import SwiftUI

struct JournalEntry: Identifiable {
    let id: UUID
    var title: String
    var content: String
    var creationDate: Date
    var lastRestoredDate: Date?
    var decayLevel: Int // 0-100, where 100 is completely decayed
    var tags: [String] = []
    var photoAttachments: [UUID: URL] = [:] // Store photo URLs keyed by UUID
    
    init(id: UUID = UUID(), title: String, content: String, creationDate: Date = Date(), lastRestoredDate: Date? = nil, decayLevel: Int = 0, tags: [String] = [], photoAttachments: [UUID: URL] = [:]) {
        self.id = id
        self.title = title
        self.content = content
        self.creationDate = creationDate
        self.lastRestoredDate = lastRestoredDate
        self.decayLevel = decayLevel
        self.tags = tags
        self.photoAttachments = photoAttachments
    }
    
    mutating func calculateDecay() {
        // Calculate decay based on time passed in days
        let calendar = Calendar.current
        let now = Date()
        let daysSinceCreation = calendar.dateComponents([.day], from: lastRestoredDate ?? creationDate, to: now).day ?? 0
        
        // Decay by 5 points per day 
        decayLevel = min(daysSinceCreation * 5, 100)
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
} 