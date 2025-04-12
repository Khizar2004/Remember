import Foundation
import CoreData
import SwiftUI

class JournalEntryStore: ObservableObject {
    @Published var entries: [JournalEntry] = []
    
    // Track if core data is ready
    private var isStoreLoaded = false
    
    // CoreData container
    let container: NSPersistentContainer
    
    init() {
        print("Initializing JournalEntryStore")
        container = NSPersistentContainer(name: "ReMember")
        
        // Create the directory for the data model if it doesn't exist
        let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        let modelURL = url?.appendingPathComponent("ReMember.sqlite")
        
        if let modelURL = modelURL, !FileManager.default.fileExists(atPath: modelURL.path) {
            do {
                try FileManager.default.createDirectory(at: url!, withIntermediateDirectories: true, attributes: nil)
                print("Created directory for Core Data store")
            } catch {
                print("Error creating directory: \(error)")
            }
        }
        
        // Configure persistent container options
        let description = NSPersistentStoreDescription()
        description.url = modelURL
        description.type = NSSQLiteStoreType
        description.shouldAddStoreAsynchronously = false
        container.persistentStoreDescriptions = [description]
        
        container.loadPersistentStores { description, error in
            if let error = error {
                print("Failed to load Core Data: \(error.localizedDescription)")
                
                // Create a backup plan with in-memory store if disk storage fails
                let inMemoryDescription = NSPersistentStoreDescription()
                inMemoryDescription.type = NSInMemoryStoreType
                self.container.persistentStoreDescriptions = [inMemoryDescription]
                
                self.container.loadPersistentStores { desc, err in
                    if let err = err {
                        print("Failed to create in-memory store: \(err)")
                    } else {
                        print("Created in-memory store as fallback")
                        self.isStoreLoaded = true
                        self.loadEntries()
                    }
                }
            } else {
                print("Core Data loaded successfully")
                self.isStoreLoaded = true
                
                // Load entries immediately after successful store loading
                DispatchQueue.main.async {
                    self.loadEntries()
                }
            }
        }
    }
    
    func loadEntries() {
        guard isStoreLoaded else {
            print("Cannot load entries - store not ready")
            return
        }
        
        let request = NSFetchRequest<JournalEntryEntity>(entityName: "JournalEntryEntity")
        let sortDescriptor = NSSortDescriptor(keyPath: \JournalEntryEntity.creationDate, ascending: false)
        request.sortDescriptors = [sortDescriptor]
        
        do {
            let fetchedEntities = try container.viewContext.fetch(request)
            print("Fetched \(fetchedEntities.count) entries from Core Data")
            
            // Use DispatchQueue.main to ensure UI updates properly
            DispatchQueue.main.async {
                self.entries = fetchedEntities.map { entity in
                    JournalEntry(
                        id: entity.id ?? UUID(),
                        title: entity.title ?? "Untitled",
                        content: entity.content ?? "",
                        creationDate: entity.creationDate ?? Date(),
                        lastRestoredDate: entity.lastRestoredDate,
                        decayLevel: Int(entity.decayLevel)
                    )
                }
                
                // Update decay levels for all entries
                for i in 0..<self.entries.count {
                    self.entries[i].calculateDecay()
                }
                
                // Force objectWillChange notification to update any observing views
                self.objectWillChange.send()
                print("Updated entries array with \(self.entries.count) entries")
            }
        } catch {
            print("Failed to fetch entries: \(error.localizedDescription)")
        }
    }
    
    func addEntry(title: String, content: String) {
        print("Adding new entry with title: \(title)")
        
        guard isStoreLoaded else {
            print("Cannot add entry - store not ready")
            return
        }
        
        let newEntry = JournalEntryEntity(context: container.viewContext)
        newEntry.id = UUID()
        newEntry.title = title
        newEntry.content = content
        newEntry.creationDate = Date()
        newEntry.decayLevel = 0
        
        saveContext()
        
        // Force a refresh of entries to ensure UI updates
        loadEntries()
    }
    
    func updateEntry(_ entry: JournalEntry) {
        guard isStoreLoaded else {
            print("Cannot update entry - store not ready")
            return
        }
        
        let request = NSFetchRequest<JournalEntryEntity>(entityName: "JournalEntryEntity")
        request.predicate = NSPredicate(format: "id == %@", entry.id as CVarArg)
        
        do {
            let results = try container.viewContext.fetch(request)
            if let entityToUpdate = results.first {
                entityToUpdate.title = entry.title
                entityToUpdate.content = entry.content
                entityToUpdate.lastRestoredDate = entry.lastRestoredDate
                entityToUpdate.decayLevel = Int16(entry.decayLevel)
                
                saveContext()
                
                // Force a refresh of entries to ensure UI updates
                loadEntries()
            }
        } catch {
            print("Failed to update entry: \(error.localizedDescription)")
        }
    }
    
    func restoreEntry(id: UUID) {
        if let index = entries.firstIndex(where: { $0.id == id }) {
            var entryToRestore = entries[index]
            entryToRestore.restore()
            updateEntry(entryToRestore)
        }
    }
    
    func deleteEntry(id: UUID) {
        guard isStoreLoaded else {
            print("Cannot delete entry - store not ready")
            return
        }
        
        let request = NSFetchRequest<JournalEntryEntity>(entityName: "JournalEntryEntity")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        do {
            let results = try container.viewContext.fetch(request)
            if let entityToDelete = results.first {
                container.viewContext.delete(entityToDelete)
                saveContext()
                
                // Force a refresh of entries to ensure UI updates
                loadEntries()
            }
        } catch {
            print("Failed to delete entry: \(error.localizedDescription)")
        }
    }
    
    func saveContext() {
        guard isStoreLoaded else {
            print("Cannot save context - store not ready")
            return
        }
        
        if container.viewContext.hasChanges {
            do {
                try container.viewContext.save()
                print("Context saved successfully")
            } catch {
                print("Failed to save context: \(error.localizedDescription)")
            }
        }
    }
} 