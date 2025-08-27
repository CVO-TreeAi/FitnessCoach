import Foundation
import CoreData
import Combine

@MainActor
public class CoreDataManager: ObservableObject {
    static let shared = CoreDataManager()
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "FitnessCoachDataModel")
        
        // Enable automatic migration
        let description = container.persistentStoreDescriptions.first
        description?.shouldInferMappingModelAutomatically = true
        description?.shouldMigrateStoreAutomatically = true
        
        container.loadPersistentStores(completionHandler: { [weak self] _, error in
            if let error = error as NSError? {
                print("CoreData error: \(error), \(error.userInfo)")
                // In production, handle this error appropriately
                // For development, we'll continue without crashing
            }
            self?.setupNotifications()
        })
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    var backgroundContext: NSManagedObjectContext {
        return persistentContainer.newBackgroundContext()
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Initialize the persistent container
        _ = persistentContainer
    }
    
    // MARK: - Core Operations
    
    public func save() {
        save(context: context)
    }
    
    func save(context: NSManagedObjectContext) {
        guard context.hasChanges else { return }
        
        do {
            try context.save()
        } catch {
            let nsError = error as NSError
            print("CoreData save error: \(nsError), \(nsError.userInfo)")
        }
    }
    
    func delete(_ object: NSManagedObject) {
        context.delete(object)
        save()
    }
    
    func deleteAll(entityName: String) {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try context.execute(deleteRequest)
            save()
        } catch {
            print("Error deleting all \(entityName): \(error)")
        }
    }
    
    // MARK: - Generic Fetch Operations
    
    func fetch<T: NSManagedObject>(_ entityType: T.Type, 
                                   predicate: NSPredicate? = nil,
                                   sortDescriptors: [NSSortDescriptor]? = nil,
                                   limit: Int? = nil) -> [T] {
        let request = NSFetchRequest<T>(entityName: String(describing: entityType))
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors
        if let limit = limit {
            request.fetchLimit = limit
        }
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching \(entityType): \(error)")
            return []
        }
    }
    
    func fetchFirst<T: NSManagedObject>(_ entityType: T.Type,
                                        predicate: NSPredicate? = nil) -> T? {
        return fetch(entityType, predicate: predicate, limit: 1).first
    }
    
    func count<T: NSManagedObject>(_ entityType: T.Type,
                                   predicate: NSPredicate? = nil) -> Int {
        let request = NSFetchRequest<T>(entityName: String(describing: entityType))
        request.predicate = predicate
        
        do {
            return try context.count(for: request)
        } catch {
            print("Error counting \(entityType): \(error)")
            return 0
        }
    }
    
    // MARK: - Batch Operations
    
    func batchUpdate(entityName: String, 
                     propertiesToUpdate: [String: Any],
                     predicate: NSPredicate? = nil) {
        let batchUpdate = NSBatchUpdateRequest(entityName: entityName)
        batchUpdate.predicate = predicate
        batchUpdate.propertiesToUpdate = propertiesToUpdate
        batchUpdate.resultType = .updatedObjectIDsResultType
        
        do {
            let result = try context.execute(batchUpdate) as? NSBatchUpdateResult
            if let objectIDs = result?.result as? [NSManagedObjectID] {
                let changes = [NSUpdatedObjectsKey: objectIDs]
                NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, 
                                                   into: [context])
            }
        } catch {
            print("Batch update error: \(error)")
        }
    }
    
    // MARK: - Notifications
    
    private func setupNotifications() {
        NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)
            .compactMap { $0.object as? NSManagedObjectContext }
            .filter { $0 != self.context }
            .sink { [weak self] context in
                self?.context.mergeChanges(fromContextDidSave: Notification(name: .NSManagedObjectContextDidSave, object: context))
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Entity Creation Helpers
    
    func createEntity<T: NSManagedObject>(_ entityType: T.Type) -> T {
        return T(context: context)
    }
    
    // MARK: - Migration Support
    
    func performLightweightMigration() {
        let coordinator = persistentContainer.persistentStoreCoordinator
        guard let url = persistentContainer.persistentStoreDescriptions.first?.url else { return }
        
        do {
            let options = [
                NSMigratePersistentStoresAutomaticallyOption: true,
                NSInferMappingModelAutomaticallyOption: true
            ]
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType,
                                              configurationName: nil,
                                              at: url,
                                              options: options)
        } catch {
            print("Migration failed: \(error)")
        }
    }
    
    // MARK: - Development Helpers
    
    #if DEBUG
    func printDatabasePath() {
        if let url = persistentContainer.persistentStoreDescriptions.first?.url {
            print("Core Data Database Path: \(url)")
        }
    }
    
    func resetDatabase() {
        guard let url = persistentContainer.persistentStoreDescriptions.first?.url else { return }
        
        let coordinator = persistentContainer.persistentStoreCoordinator
        
        do {
            try coordinator.destroyPersistentStore(at: url, ofType: NSSQLiteStoreType, options: nil)
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, 
                                              configurationName: nil,
                                              at: url, 
                                              options: nil)
            print("Database reset successfully")
        } catch {
            print("Error resetting database: \(error)")
        }
    }
    #endif
}

// MARK: - Convenience Extensions

extension NSManagedObject {
    class var entityName: String {
        return String(describing: self)
    }
}

// MARK: - Publisher Support

extension CoreDataManager {
    func publisher<T: NSManagedObject>(for entityType: T.Type,
                                       predicate: NSPredicate? = nil,
                                       sortDescriptors: [NSSortDescriptor]? = nil) -> AnyPublisher<[T], Never> {
        let request = NSFetchRequest<T>(entityName: String(describing: entityType))
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors
        
        return NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)
            .prepend(Notification(name: .NSManagedObjectContextDidSave))
            .compactMap { [weak self] _ in
                guard let self = self else { return nil }
                return try? self.context.fetch(request)
            }
            .replaceNil(with: [])
            .eraseToAnyPublisher()
    }
}