import Foundation
import CloudKit
import CoreData
import Combine
import OSLog

/// Advanced sync coordinator managing bidirectional Core Data ↔ CloudKit synchronization
@MainActor
public final class SyncCoordinator: ObservableObject {
    
    // MARK: - Properties
    private let cloudKitManager: CloudKitManager
    private let coreDataManager: CoreDataManager
    private let logger = Logger(subsystem: "FitnessCoach", category: "SyncCoordinator")
    
    @Published public var isInitialSyncCompleted: Bool = false
    @Published public var conflictResolutionStrategy: ConflictResolutionStrategy = .serverWins
    
    private var cancellables = Set<AnyCancellable>()
    
    // Change tracking
    private var changeTokens: [String: CKServerChangeToken] = [:]
    private let changeTokenStore = UserDefaults.standard
    
    // Delta sync tracking
    private var lastSyncTimestamp: Date?
    private let syncTimestampKey = "lastSyncTimestamp"
    
    // Batch processing
    private let batchSize = 100
    private var syncQueue = DispatchQueue(label: "sync.queue", qos: .utility)
    
    // MARK: - Initialization
    public init(cloudKitManager: CloudKitManager = .shared, coreDataManager: CoreDataManager = .shared) {
        self.cloudKitManager = cloudKitManager
        self.coreDataManager = coreDataManager
        
        loadChangeTokens()
        loadLastSyncTimestamp()
        setupObservers()
    }
    
    // MARK: - Setup
    private func loadChangeTokens() {
        if let data = changeTokenStore.data(forKey: "cloudkit_change_tokens"),
           let tokens = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? [String: CKServerChangeToken] {
            changeTokens = tokens
        }
    }
    
    private func saveChangeTokens() {
        if let data = try? NSKeyedArchiver.archivedData(withRootObject: changeTokens, requiringSecureCoding: true) {
            changeTokenStore.set(data, forKey: "cloudkit_change_tokens")
        }
    }
    
    private func loadLastSyncTimestamp() {
        lastSyncTimestamp = changeTokenStore.object(forKey: syncTimestampKey) as? Date
    }
    
    private func saveLastSyncTimestamp() {
        changeTokenStore.set(lastSyncTimestamp, forKey: syncTimestampKey)
    }
    
    private func setupObservers() {
        // Listen for Core Data changes
        NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)
            .compactMap { $0.object as? NSManagedObjectContext }
            .filter { $0 == self.coreDataManager.context }
            .sink { [weak self] context in
                Task {
                    await self?.handleCoreDataChanges(context)
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Sync Operations
    
    /// Performs initial setup and sync
    public func performInitialSync() async throws {
        logger.info("Starting initial sync")
        
        // Check CloudKit availability
        let accountStatus = await cloudKitManager.checkAccountStatus()
        guard accountStatus == .available else {
            throw SyncError.cloudKitUnavailable
        }
        
        // Create custom zones if needed
        try await createCustomZones()
        
        // Subscribe to database changes
        try await setupSubscriptions()
        
        // Perform full sync
        try await performFullSync()
        
        await MainActor.run {
            isInitialSyncCompleted = true
        }
        
        logger.info("Initial sync completed")
    }
    
    /// Performs a full bidirectional sync
    public func performFullSync() async throws {
        logger.info("Starting full sync")
        
        // Download all records from CloudKit
        try await downloadAllRecords()
        
        // Upload all local changes
        try await uploadAllLocalChanges()
        
        // Update sync timestamp
        lastSyncTimestamp = Date()
        saveLastSyncTimestamp()
        
        logger.info("Full sync completed")
    }
    
    /// Performs incremental sync using change tokens
    public func performIncrementalSync() async throws {
        logger.info("Starting incremental sync")
        
        // Fetch changes from CloudKit
        try await fetchChangesFromCloudKit()
        
        // Upload local changes since last sync
        try await uploadLocalChangesSince(lastSyncTimestamp ?? Date.distantPast)
        
        // Update sync timestamp
        lastSyncTimestamp = Date()
        saveLastSyncTimestamp()
        
        logger.info("Incremental sync completed")
    }
    
    // MARK: - CloudKit → Core Data Sync
    
    private func downloadAllRecords() async throws {
        let recordTypes = [
            User.recordType, Coach.recordType, Client.recordType,
            Exercise.recordType, WorkoutTemplate.recordType, WorkoutSession.recordType,
            FoodItem.recordType, NutritionEntry.recordType,
            ProgressEntry.recordType, Goal.recordType
        ]
        
        for recordType in recordTypes {
            try await downloadRecords(ofType: recordType)
        }
    }
    
    private func downloadRecords(ofType recordType: String) async throws {
        let query = CKQuery(recordType: recordType, predicate: NSPredicate(value: true))
        let operation = CKQueryOperation(query: query)
        operation.resultsLimit = batchSize
        
        var allRecords: [CKRecord] = []
        
        repeat {
            let (records, cursor) = try await executeQuery(operation)
            allRecords.append(contentsOf: records)
            
            if let cursor = cursor {
                operation = CKQueryOperation(cursor: cursor)
                operation.resultsLimit = batchSize
            } else {
                break
            }
        } while true
        
        // Process records in batches
        for batch in allRecords.chunked(into: batchSize) {
            try await processBatch(batch, recordType: recordType)
        }
    }
    
    private func executeQuery(_ operation: CKQueryOperation) async throws -> ([CKRecord], CKQueryOperation.Cursor?) {
        return try await withCheckedThrowingContinuation { continuation in
            var records: [CKRecord] = []
            var cursor: CKQueryOperation.Cursor?
            
            operation.recordFetchedBlock = { record in
                records.append(record)
            }
            
            operation.queryCompletionBlock = { queryCursor, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    cursor = queryCursor
                    continuation.resume(returning: (records, cursor))
                }
            }
            
            cloudKitManager.privateDatabase.add(operation)
        }
    }
    
    private func processBatch(_ records: [CKRecord], recordType: String) async throws {
        await coreDataManager.context.perform {
            for record in records {
                self.processCloudKitRecord(record, recordType: recordType)
            }
            
            do {
                try self.coreDataManager.context.save()
            } catch {
                self.logger.error("Failed to save Core Data context: \(error.localizedDescription)")
            }
        }
    }
    
    private func processCloudKitRecord(_ record: CKRecord, recordType: String) {
        switch recordType {
        case User.recordType:
            processUserRecord(record)
        case Coach.recordType:
            processCoachRecord(record)
        case Client.recordType:
            processClientRecord(record)
        case Exercise.recordType:
            processExerciseRecord(record)
        case WorkoutTemplate.recordType:
            processWorkoutTemplateRecord(record)
        case WorkoutSession.recordType:
            processWorkoutSessionRecord(record)
        case FoodItem.recordType:
            processFoodItemRecord(record)
        case NutritionEntry.recordType:
            processNutritionEntryRecord(record)
        case ProgressEntry.recordType:
            processProgressEntryRecord(record)
        case Goal.recordType:
            processGoalRecord(record)
        default:
            logger.warning("Unknown record type: \(recordType)")
        }
    }
    
    // MARK: - Core Data → CloudKit Sync
    
    private func uploadAllLocalChanges() async throws {
        let recordTypes = [
            (User.self, User.recordType),
            (Coach.self, Coach.recordType),
            (Client.self, Client.recordType),
            (Exercise.self, Exercise.recordType),
            (WorkoutTemplate.self, WorkoutTemplate.recordType),
            (WorkoutSession.self, WorkoutSession.recordType),
            (FoodItem.self, FoodItem.recordType),
            (NutritionEntry.self, NutritionEntry.recordType),
            (ProgressEntry.self, ProgressEntry.recordType),
            (Goal.self, Goal.recordType)
        ]
        
        for (entityType, recordType) in recordTypes {
            try await uploadLocalEntities(entityType: entityType as! NSManagedObject.Type, recordType: recordType)
        }
    }
    
    private func uploadLocalEntities(entityType: NSManagedObject.Type, recordType: String) async throws {
        let entityName = String(describing: entityType)
        let request = NSFetchRequest<NSManagedObject>(entityName: entityName)
        
        let entities = try await coreDataManager.context.perform {
            try self.coreDataManager.context.fetch(request)
        }
        
        // Convert entities to CloudKit records
        let records = entities.compactMap { entity -> CKRecord? in
            guard let cloudKitModel = entity as? CloudKitModel else { return nil }
            return cloudKitModel.toCKRecord()
        }
        
        // Upload in batches
        for batch in records.chunked(into: batchSize) {
            try await cloudKitManager.batchSave(records: batch)
        }
    }
    
    private func uploadLocalChangesSince(_ date: Date) async throws {
        // Implementation for uploading only changes since a specific date
        // This would require timestamp tracking on Core Data entities
    }
    
    // MARK: - Change Detection and Handling
    
    private func handleCoreDataChanges(_ context: NSManagedObjectContext) async {
        // Extract changes and queue for CloudKit sync
        guard let userInfo = context.userInfo,
              let insertedObjects = userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject>,
              let updatedObjects = userInfo[NSUpdatedObjectsKey] as? Set<NSManagedObject>,
              let deletedObjects = userInfo[NSDeletedObjectsKey] as? Set<NSManagedObject> else {
            return
        }
        
        // Handle insertions
        for object in insertedObjects {
            if let cloudKitModel = object as? CloudKitModel {
                let record = cloudKitModel.toCKRecord()
                cloudKitManager.queueOfflineOperation(
                    PendingCloudKitOperation(
                        type: .save,
                        recordType: type(of: cloudKitModel).recordType,
                        recordID: record.recordID.recordName,
                        recordData: try? NSKeyedArchiver.archivedData(withRootObject: record, requiringSecureCoding: true)
                    )
                )
            }
        }
        
        // Handle updates
        for object in updatedObjects {
            if let cloudKitModel = object as? CloudKitModel {
                let record = cloudKitModel.toCKRecord()
                cloudKitManager.queueOfflineOperation(
                    PendingCloudKitOperation(
                        type: .modify,
                        recordType: type(of: cloudKitModel).recordType,
                        recordID: record.recordID.recordName,
                        recordData: try? NSKeyedArchiver.archivedData(withRootObject: record, requiringSecureCoding: true)
                    )
                )
            }
        }
        
        // Handle deletions
        for object in deletedObjects {
            if let cloudKitModel = object as? CloudKitModel,
               let objectID = (object as? NSManagedObject)?.objectID.uriRepresentation().absoluteString {
                cloudKitManager.queueOfflineOperation(
                    PendingCloudKitOperation(
                        type: .delete,
                        recordType: type(of: cloudKitModel).recordType,
                        recordID: objectID
                    )
                )
            }
        }
    }
    
    private func fetchChangesFromCloudKit() async throws {
        let configuration = CKFetchDatabaseChangesOperation.Configuration()
        configuration.previousServerChangeToken = changeTokens["database"]
        
        let operation = CKFetchDatabaseChangesOperation(configuration: configuration)
        
        var changedZoneIDs: [CKRecordZone.ID] = []
        var deletedZoneIDs: [CKRecordZone.ID] = []
        
        operation.recordZoneWithIDChangedBlock = { zoneID in
            changedZoneIDs.append(zoneID)
        }
        
        operation.recordZoneWithIDWasDeletedBlock = { zoneID in
            deletedZoneIDs.append(zoneID)
        }
        
        operation.fetchDatabaseChangesResultBlock = { result in
            switch result {
            case .success(let (serverChangeToken, _)):
                self.changeTokens["database"] = serverChangeToken
                self.saveChangeTokens()
            case .failure(let error):
                self.logger.error("Failed to fetch database changes: \(error.localizedDescription)")
            }
        }
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            operation.fetchDatabaseChangesResultBlock = { result in
                switch result {
                case .success:
                    continuation.resume(returning: ())
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            
            cloudKitManager.privateDatabase.add(operation)
        }
        
        // Fetch changes for each changed zone
        for zoneID in changedZoneIDs {
            try await fetchChangesInZone(zoneID)
        }
    }
    
    private func fetchChangesInZone(_ zoneID: CKRecordZone.ID) async throws {
        let configuration = CKFetchRecordZoneChangesOperation.Configuration()
        configuration.previousServerChangeToken = changeTokens[zoneID.zoneName]
        
        let operation = CKFetchRecordZoneChangesOperation(
            recordZoneIDs: [zoneID],
            configurationsByRecordZoneID: [zoneID: configuration]
        )
        
        var changedRecords: [CKRecord] = []
        var deletedRecordIDs: [CKRecord.ID] = []
        
        operation.recordWasChangedBlock = { recordID, result in
            switch result {
            case .success(let record):
                changedRecords.append(record)
            case .failure(let error):
                self.logger.error("Failed to process changed record \(recordID): \(error.localizedDescription)")
            }
        }
        
        operation.recordWithIDWasDeletedBlock = { recordID, _ in
            deletedRecordIDs.append(recordID)
        }
        
        operation.recordZoneFetchResultBlock = { zoneID, result in
            switch result {
            case .success(let (serverChangeToken, _, _)):
                self.changeTokens[zoneID.zoneName] = serverChangeToken
                self.saveChangeTokens()
            case .failure(let error):
                self.logger.error("Failed to fetch zone changes for \(zoneID): \(error.localizedDescription)")
            }
        }
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            operation.fetchRecordZoneChangesResultBlock = { result in
                switch result {
                case .success:
                    continuation.resume(returning: ())
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            
            cloudKitManager.privateDatabase.add(operation)
        }
        
        // Process changed records
        try await processBatch(changedRecords, recordType: "Mixed")
        
        // Process deleted records
        await processDeletedRecords(deletedRecordIDs)
    }
    
    // MARK: - Conflict Resolution
    
    private func resolveConflict(localObject: NSManagedObject, cloudRecord: CKRecord) -> ConflictResolution {
        switch conflictResolutionStrategy {
        case .serverWins:
            return .useCloudRecord
        case .clientWins:
            return .useLocalObject
        case .newestWins:
            return resolveByTimestamp(localObject: localObject, cloudRecord: cloudRecord)
        case .manual:
            return .requiresManualResolution
        }
    }
    
    private func resolveByTimestamp(localObject: NSManagedObject, cloudRecord: CKRecord) -> ConflictResolution {
        // Compare modification dates
        let localModifiedDate = (localObject as? NSManagedObject)?.value(forKey: "updatedAt") as? Date ?? Date.distantPast
        let cloudModifiedDate = cloudRecord.modificationDate ?? Date.distantPast
        
        return localModifiedDate > cloudModifiedDate ? .useLocalObject : .useCloudRecord
    }
    
    // MARK: - Custom Zones and Subscriptions
    
    private func createCustomZones() async throws {
        let privateZone = CKRecordZone(zoneName: "PrivateUserData")
        let sharedZone = CKRecordZone(zoneName: "CoachClientShared")
        
        let operation = CKModifyRecordZonesOperation(recordZonesToSave: [privateZone, sharedZone], recordZoneIDsToDelete: nil)
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            operation.modifyRecordZonesResultBlock = { result in
                switch result {
                case .success:
                    continuation.resume(returning: ())
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            
            cloudKitManager.privateDatabase.add(operation)
        }
    }
    
    private func setupSubscriptions() async throws {
        let privateSubscription = CKDatabaseSubscription(subscriptionID: "private-changes")
        privateSubscription.notificationInfo = CKSubscription.NotificationInfo()
        privateSubscription.notificationInfo?.shouldSendContentAvailable = true
        
        let operation = CKModifySubscriptionsOperation(subscriptionsToSave: [privateSubscription], subscriptionIDsToDelete: nil)
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            operation.modifySubscriptionsResultBlock = { result in
                switch result {
                case .success:
                    continuation.resume(returning: ())
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            
            cloudKitManager.privateDatabase.add(operation)
        }
    }
    
    // MARK: - Record Processing Methods
    
    private func processUserRecord(_ record: CKRecord) {
        // Implementation for processing User records
        if let user = User.fromCKRecord(record) {
            // Merge with existing or create new
            mergeOrCreateUser(user, from: record)
        }
    }
    
    private func processCoachRecord(_ record: CKRecord) {
        // Implementation for processing Coach records
        if let coach = Coach.fromCKRecord(record) {
            mergeOrCreateCoach(coach, from: record)
        }
    }
    
    private func processClientRecord(_ record: CKRecord) {
        // Implementation for processing Client records
        if let client = Client.fromCKRecord(record) {
            mergeOrCreateClient(client, from: record)
        }
    }
    
    private func processExerciseRecord(_ record: CKRecord) {
        if let exercise = Exercise.fromCKRecord(record) {
            mergeOrCreateExercise(exercise, from: record)
        }
    }
    
    private func processWorkoutTemplateRecord(_ record: CKRecord) {
        if let template = WorkoutTemplate.fromCKRecord(record) {
            mergeOrCreateWorkoutTemplate(template, from: record)
        }
    }
    
    private func processWorkoutSessionRecord(_ record: CKRecord) {
        if let session = WorkoutSession.fromCKRecord(record) {
            mergeOrCreateWorkoutSession(session, from: record)
        }
    }
    
    private func processFoodItemRecord(_ record: CKRecord) {
        if let foodItem = FoodItem.fromCKRecord(record) {
            mergeOrCreateFoodItem(foodItem, from: record)
        }
    }
    
    private func processNutritionEntryRecord(_ record: CKRecord) {
        if let entry = NutritionEntry.fromCKRecord(record) {
            mergeOrCreateNutritionEntry(entry, from: record)
        }
    }
    
    private func processProgressEntryRecord(_ record: CKRecord) {
        if let entry = ProgressEntry.fromCKRecord(record) {
            mergeOrCreateProgressEntry(entry, from: record)
        }
    }
    
    private func processGoalRecord(_ record: CKRecord) {
        if let goal = Goal.fromCKRecord(record) {
            mergeOrCreateGoal(goal, from: record)
        }
    }
    
    private func processDeletedRecords(_ recordIDs: [CKRecord.ID]) async {
        await coreDataManager.context.perform {
            for recordID in recordIDs {
                self.deleteLocalRecord(with: recordID)
            }
            
            do {
                try self.coreDataManager.context.save()
            } catch {
                self.logger.error("Failed to save deletions: \(error.localizedDescription)")
            }
        }
    }
    
    private func deleteLocalRecord(with recordID: CKRecord.ID) {
        // Find and delete the corresponding Core Data object
        let recordName = recordID.recordName
        guard let uuid = UUID(uuidString: recordName) else { return }
        
        // Search across all entity types
        let entityNames = ["User", "Coach", "Client", "Exercise", "WorkoutTemplate", "WorkoutSession", "FoodItem", "NutritionEntry", "ProgressEntry", "Goal"]
        
        for entityName in entityNames {
            let request = NSFetchRequest<NSManagedObject>(entityName: entityName)
            request.predicate = NSPredicate(format: "id == %@", uuid as CVarArg)
            request.fetchLimit = 1
            
            if let object = try? coreDataManager.context.fetch(request).first {
                coreDataManager.context.delete(object)
                break
            }
        }
    }
    
    // MARK: - Merge Methods (implement conflict resolution)
    
    private func mergeOrCreateUser(_ user: User, from record: CKRecord) {
        // Implementation with conflict resolution
    }
    
    private func mergeOrCreateCoach(_ coach: Coach, from record: CKRecord) {
        // Implementation with conflict resolution
    }
    
    private func mergeOrCreateClient(_ client: Client, from record: CKRecord) {
        // Implementation with conflict resolution
    }
    
    private func mergeOrCreateExercise(_ exercise: Exercise, from record: CKRecord) {
        // Implementation with conflict resolution
    }
    
    private func mergeOrCreateWorkoutTemplate(_ template: WorkoutTemplate, from record: CKRecord) {
        // Implementation with conflict resolution
    }
    
    private func mergeOrCreateWorkoutSession(_ session: WorkoutSession, from record: CKRecord) {
        // Implementation with conflict resolution
    }
    
    private func mergeOrCreateFoodItem(_ foodItem: FoodItem, from record: CKRecord) {
        // Implementation with conflict resolution
    }
    
    private func mergeOrCreateNutritionEntry(_ entry: NutritionEntry, from record: CKRecord) {
        // Implementation with conflict resolution
    }
    
    private func mergeOrCreateProgressEntry(_ entry: ProgressEntry, from record: CKRecord) {
        // Implementation with conflict resolution
    }
    
    private func mergeOrCreateGoal(_ goal: Goal, from record: CKRecord) {
        // Implementation with conflict resolution
    }
}

// MARK: - Supporting Types

public enum ConflictResolutionStrategy {
    case serverWins      // CloudKit data takes precedence
    case clientWins      // Local data takes precedence  
    case newestWins      // Most recently modified wins
    case manual          // Requires manual resolution
}

private enum ConflictResolution {
    case useLocalObject
    case useCloudRecord
    case requiresManualResolution
}

public enum SyncError: LocalizedError {
    case cloudKitUnavailable
    case coreDataError(Error)
    case conflictResolutionRequired
    case unknownError
    
    public var errorDescription: String? {
        switch self {
        case .cloudKitUnavailable:
            return "CloudKit is not available"
        case .coreDataError(let error):
            return "Core Data error: \(error.localizedDescription)"
        case .conflictResolutionRequired:
            return "Manual conflict resolution required"
        case .unknownError:
            return "An unknown sync error occurred"
        }
    }
}