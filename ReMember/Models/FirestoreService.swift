import Foundation
import Firebase
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage

class FirestoreService {
    // Singleton instance
    static let shared = FirestoreService()
    
    // Firestore database reference
    private let db = Firestore.firestore()
    
    // Storage reference
    private let storage = Storage.storage().reference()
    
    // Collection name for journal entries
    private let entriesCollection = "journalEntries"
    
    // MARK: - Journal Entry Operations
    
    /// Upload a journal entry to Firestore
    func uploadEntry(_ entry: JournalEntry) async throws {
        guard let userID = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "FirestoreService", code: 1, userInfo: [NSLocalizedDescriptionKey: "No authenticated user"])
        }
        
        var entryData: [String: Any] = [
            "id": entry.id.uuidString,
            "title": entry.title,
            "content": entry.content,
            "creationDate": entry.creationDate,
            "decayLevel": entry.decayLevel,
            "userID": userID,
            "tags": entry.tags
        ]
        
        if let lastRestoredDate = entry.lastRestoredDate {
            entryData["lastRestoredDate"] = lastRestoredDate
        }
        
        if !entry.customQuestions.isEmpty {
            let questionsData = try JSONEncoder().encode(entry.customQuestions)
            entryData["customQuestionsData"] = questionsData
        }
        
        if !entry.photoAttachments.isEmpty {
            var photoDict: [String: String] = [:]
            
            for (photoID, localURL) in entry.photoAttachments {
                if FileManager.default.fileExists(atPath: localURL.path) {
                    let fileName = "\(userID)/photos/\(photoID.uuidString).jpg"
                    let storageRef = storage.child(fileName)
                    
                    do {
                        let imageData = try Data(contentsOf: localURL)
                        let metadata = StorageMetadata()
                        metadata.contentType = "image/jpeg"
                        
                        _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
                        
                        let downloadURL = try await storageRef.downloadURL()
                        
                        photoDict[photoID.uuidString] = fileName
                    } catch {
                        print("Error uploading photo: \(error.localizedDescription)")
                    }
                }
            }
            
            if !photoDict.isEmpty {
                entryData["photoAttachmentPaths"] = photoDict
            }
        }
        
        try await db.collection(entriesCollection).document(entry.id.uuidString).setData(entryData)
    }
    
    /// Delete a journal entry from Firestore
    func deleteEntry(id: UUID) async throws {
        if let userID = Auth.auth().currentUser?.uid {
            let entrySnapshot = try await db.collection(entriesCollection).document(id.uuidString).getDocument()
            
            if let data = entrySnapshot.data(),
               let photoPaths = data["photoAttachmentPaths"] as? [String: String] {
                
                for (_, path) in photoPaths {
                    try await storage.child(path).delete()
                }
            }
        }
        
        try await db.collection(entriesCollection).document(id.uuidString).delete()
    }
    
    /// Fetch all entries for the current user
    func fetchEntries() async throws -> [FirestoreJournalEntry] {
        guard let userID = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "FirestoreService", code: 1, userInfo: [NSLocalizedDescriptionKey: "No authenticated user"])
        }
        
        let snapshot = try await db.collection(entriesCollection)
            .whereField("userID", isEqualTo: userID)
            .getDocuments()
        
        return snapshot.documents.compactMap { document -> FirestoreJournalEntry? in
            let data = document.data()
            
            guard let idString = data["id"] as? String,
                  let id = UUID(uuidString: idString),
                  let title = data["title"] as? String,
                  let content = data["content"] as? String,
                  let creationDate = data["creationDate"] as? Timestamp,
                  let decayLevel = data["decayLevel"] as? Int,
                  let userID = data["userID"] as? String else {
                return nil
            }
            
            let lastRestoredDate = (data["lastRestoredDate"] as? Timestamp)?.dateValue()
            let tags = (data["tags"] as? [String]) ?? []
            
            var photoAttachmentPaths: [UUID: String] = [:]
            if let paths = data["photoAttachmentPaths"] as? [String: String] {
                for (key, value) in paths {
                    if let uuid = UUID(uuidString: key) {
                        photoAttachmentPaths[uuid] = value
                    }
                }
            }
            
            var customQuestions: [MemoryQuestion] = []
            if let questionsData = data["customQuestionsData"] as? Data {
                customQuestions = (try? JSONDecoder().decode([MemoryQuestion].self, from: questionsData)) ?? []
            }
            
            return FirestoreJournalEntry(
                id: id,
                title: title,
                content: content,
                creationDate: creationDate.dateValue(),
                lastRestoredDate: lastRestoredDate,
                decayLevel: decayLevel,
                tags: tags,
                photoAttachmentPaths: photoAttachmentPaths,
                customQuestions: customQuestions,
                userID: userID
            )
        }
    }
    
    // MARK: - Photo Operations
    
    /// Download a photo from Firebase Storage
    func downloadPhoto(path: String) async throws -> Data {
        let storageRef = storage.child(path)
        let maxSize: Int64 = 5 * 1024 * 1024 // 5MB max
        return try await storageRef.data(maxSize: maxSize)
    }
}

// Structure for journal entries fetched from Firestore
struct FirestoreJournalEntry {
    let id: UUID
    let title: String
    let content: String
    let creationDate: Date
    let lastRestoredDate: Date?
    let decayLevel: Int
    let tags: [String]
    let photoAttachmentPaths: [UUID: String]
    let customQuestions: [MemoryQuestion]
    let userID: String
}