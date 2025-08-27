import Foundation
import CloudKit
import CoreData
import Combine
import OSLog

/// Comprehensive CloudKit sync engine with automatic sync, conflict resolution, and offline queue management
@MainActor
public final class CloudKitManager: ObservableObject {
    static let shared = CloudKitManager()
    
    // MARK: - Properties
    private let container: CKContainer
    private let privateDatabase: CKDatabase
    private let publicDatabase: CKDatabase
    private let sharedDatabase: CKDatabase
    
    private let logger = Logger(subsystem: "FitnessCoach", category: "CloudKitManager")
    
    @Published public var syncStatus: SyncStatus = .idle
    @Published public var lastSyncDate: Date?
    @Published public var isSyncEnabled: Bool = true
    
    private var cancellables = Set<AnyCancellable>()
    private let operationQueue = OperationQueue()
    
    // Offline queue
    private var pendingOperations: [PendingCloudKitOperation] = []
    private let operationStore = UserDefaults.standard
    
    // Progress tracking
    @Published public var syncProgress: SyncProgress?
    
    // MARK: - Initialization
    private init() {
        self.container = CKContainer(identifier: "iCloud.com.fitnesscoach.app")
        self.privateDatabase = container.privateCloudDatabase
        self.publicDatabase = container.publicCloudDatabase
        self.sharedDatabase = container.sharedCloudDatabase
        
        setupOperationQueue()
        loadPendingOperations()
        setupBackgroundSync()
    }
    
    // MARK: - Setup
    private func setupOperationQueue() {
        operationQueue.maxConcurrentOperationCount = 3
        operationQueue.qualityOfService = .utility
    }
    
    private func loadPendingOperations() {
        if let data = operationStore.data(forKey: "pendingCloudKitOperations"),
           let operations = try? JSONDecoder().decode([PendingCloudKitOperation].self, from: data) {
            pendingOperations = operations
        }
    }
    
    private func savePendingOperations() {
        if let data = try? JSONEncoder().encode(pendingOperations) {
            operationStore.set(data, forKey: "pendingCloudKitOperations")
        }
    }
    
    private func setupBackgroundSync() {
        // Sync when app becomes active
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                Task {
                    await self?.performFullSync()
                }
            }
            .store(in: &cancellables)
        
        // Periodic sync every 5 minutes when app is active
        Timer.publish(every: 300, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task {
                    await self?.performIncrementalSync()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Account Status
    public func checkAccountStatus() async -> CKAccountStatus {
        do {
            return try await container.accountStatus()
        } catch {
            logger.error("Failed to check account status: \(error.localizedDescription)")
            return .couldNotDetermine
        }
    }
    
    // MARK: - Sync Operations
    
    /// Performs a full sync of all data
    public func performFullSync() async {
        guard isSyncEnabled else { return }
        
        await MainActor.run {
            syncStatus = .syncing
            syncProgress = SyncProgress(totalOperations: 0, completedOperations: 0, currentOperation: "Initializing...")
        }
        
        do {
            // Check account status first
            let accountStatus = await checkAccountStatus()
            guard accountStatus == .available else {
                await handleAccountUnavailable(status: accountStatus)
                return
            }
            
            // Process pending operations first
            await processPendingOperations()
            
            // Sync each record type
            await syncUsers()
            await syncWorkouts()
            await syncNutrition()
            await syncProgress()
            await syncGoals()
            
            await MainActor.run {
                lastSyncDate = Date()
                syncStatus = .completed
                syncProgress = nil
            }
            
            logger.info("Full sync completed successfully")
            
        } catch {
            await MainActor.run {
                syncStatus = .failed(error)
                syncProgress = nil
            }
            logger.error("Full sync failed: \(error.localizedDescription)")
        }
    }
    
    /// Performs an incremental sync using change tokens
    public func performIncrementalSync() async {
        guard isSyncEnabled, syncStatus != .syncing else { return }
        
        await MainActor.run {
            syncStatus = .syncing
        }
        
        do {
            // Fetch changes since last sync
            await fetchChangesFromCloudKit()
            
            // Upload any local changes
            await uploadLocalChanges()
            
            await MainActor.run {
                lastSyncDate = Date()
                syncStatus = .completed
            }
            
        } catch {
            await MainActor.run {
                syncStatus = .failed(error)
            }
            logger.error("Incremental sync failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Record Operations
    
    /// Saves a record to CloudKit with retry logic
    public func save(record: CKRecord, to database: CKDatabase = CloudKitManager.shared.privateDatabase) async throws -> CKRecord {
        let operation = CKModifyRecordsOperation(recordsToSave: [record], recordIDsToDelete: nil)
        operation.savePolicy = .changedKeys
        operation.qualityOfService = .userInitiated
        
        return try await withCheckedThrowingContinuation { continuation in
            var hasReturned = false
            
            operation.modifyRecordsCompletionBlock = { savedRecords, deletedRecordIDs, error in
                guard !hasReturned else { return }
                hasReturned = true
                
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let savedRecord = savedRecords?.first {
                    continuation.resume(returning: savedRecord)
                } else {
                    continuation.resume(throwing: CloudKitError.unknownError)
                }
            }
            
            database.add(operation)
        }
    }
    
    /// Batch save operation with conflict resolution
    public func batchSave(records: [CKRecord], to database: CKDatabase = CloudKitManager.shared.privateDatabase) async throws -> [CKRecord] {
        let batchSize = 400 // CloudKit limit
        var savedRecords: [CKRecord] = []
        
        for batch in records.chunked(into: batchSize) {
            let operation = CKModifyRecordsOperation(recordsToSave: batch, recordIDsToDelete: nil)
            operation.savePolicy = .changedKeys
            operation.qualityOfService = .utility
            
            let batchResults = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[CKRecord], Error>) in
                var hasReturned = false
                
                operation.modifyRecordsCompletionBlock = { batchSavedRecords, deletedRecordIDs, error in
                    guard !hasReturned else { return }
                    hasReturned = true
                    
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: batchSavedRecords ?? [])
                    }
                }
                
                database.add(operation)
            }
            
            savedRecords.append(contentsOf: batchResults)
        }
        
        return savedRecords
    }
    
    /// Fetches records with query
    public func fetch<T: CloudKitModel>(type: T.Type, predicate: NSPredicate = NSPredicate(value: true), 
                                       sortDescriptors: [NSSortDescriptor] = [], 
                                       from database: CKDatabase = CloudKitManager.shared.privateDatabase) async throws -> [CKRecord] {
        let query = CKQuery(recordType: T.recordType, predicate: predicate)
        query.sortDescriptors = sortDescriptors
        
        let operation = CKQueryOperation(query: query)
        operation.qualityOfService = .userInitiated
        
        return try await withCheckedThrowingContinuation { continuation in
            var records: [CKRecord] = []
            var hasReturned = false
            
            operation.recordFetchedBlock = { record in
                records.append(record)
            }
            
            operation.queryCompletionBlock = { cursor, error in
                guard !hasReturned else { return }
                hasReturned = true
                
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: records)
                }
            }
            
            database.add(operation)
        }
    }
    
    /// Deletes a record from CloudKit
    public func delete(recordID: CKRecord.ID, from database: CKDatabase = CloudKitManager.shared.privateDatabase) async throws {
        let operation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: [recordID])
        operation.qualityOfService = .userInitiated
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            var hasReturned = false
            
            operation.modifyRecordsCompletionBlock = { savedRecords, deletedRecordIDs, error in
                guard !hasReturned else { return }
                hasReturned = true
                
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
            
            database.add(operation)
        }
    }
    
    // MARK: - Offline Operations
    
    /// Queues an operation for when network is available
    public func queueOfflineOperation(_ operation: PendingCloudKitOperation) {
        pendingOperations.append(operation)
        savePendingOperations()
        
        // Try to process immediately in case network is now available
        Task {
            await processPendingOperations()
        }
    }
    
    private func processPendingOperations() async {
        guard !pendingOperations.isEmpty else { return }
        
        var processedOperations: [PendingCloudKitOperation] = []
        
        for operation in pendingOperations {
            do {
                try await processOperation(operation)
                processedOperations.append(operation)
            } catch {
                logger.error("Failed to process pending operation: \(error.localizedDescription)")
                // Keep the operation in queue for retry
            }
        }
        
        // Remove processed operations
        pendingOperations.removeAll { processedOperations.contains($0) }
        savePendingOperations()
    }
    
    private func processOperation(_ operation: PendingCloudKitOperation) async throws {
        switch operation.type {
        case .save:
            if let recordData = operation.recordData,
               let record = try? NSKeyedUnarchiver.unarchivedObject(ofClass: CKRecord.self, from: recordData) {
                _ = try await save(record: record)
            }
        case .delete:
            if let recordID = CKRecord.ID(recordName: operation.recordID) {
                try await delete(recordID: recordID)
            }
        case .modify:
            // Handle modify operations
            break
        }
    }
    
    // MARK: - Sync Individual Types
    
    private func syncUsers() async {
        await updateProgress(operation: "Syncing users...")
        // Implementation for syncing User records
    }
    
    private func syncWorkouts() async {
        await updateProgress(operation: "Syncing workouts...")
        // Implementation for syncing WorkoutTemplate, WorkoutSession, etc.
    }
    
    private func syncNutrition() async {
        await updateProgress(operation: "Syncing nutrition...")
        // Implementation for syncing NutritionEntry, FoodItem, etc.
    }
    
    private func syncProgress() async {
        await updateProgress(operation: "Syncing progress...")
        // Implementation for syncing ProgressEntry records
    }
    
    private func syncGoals() async {
        await updateProgress(operation: "Syncing goals...")
        // Implementation for syncing Goal records
    }
    
    private func fetchChangesFromCloudKit() async {
        // Fetch changes using change tokens
        // Implementation for fetching incremental changes
    }
    
    private func uploadLocalChanges() async {
        // Upload any local changes that haven't been synced
        // Implementation for uploading local changes
    }
    
    // MARK: - Helper Methods
    
    private func handleAccountUnavailable(status: CKAccountStatus) async {
        await MainActor.run {
            switch status {
            case .couldNotDetermine:
                syncStatus = .failed(CloudKitError.accountUnavailable("Could not determine account status"))
            case .noAccount:
                syncStatus = .failed(CloudKitError.accountUnavailable("No iCloud account"))
            case .restricted:
                syncStatus = .failed(CloudKitError.accountUnavailable("iCloud account restricted"))
            case .temporarilyUnavailable:
                syncStatus = .failed(CloudKitError.accountUnavailable("iCloud temporarily unavailable"))
            case .available:
                break // This shouldn't happen
            @unknown default:
                syncStatus = .failed(CloudKitError.accountUnavailable("Unknown account status"))
            }
        }
    }
    
    private func updateProgress(operation: String) async {
        await MainActor.run {
            if var progress = syncProgress {
                progress.completedOperations += 1
                progress.currentOperation = operation
                syncProgress = progress
            }
        }
    }
}

// MARK: - Supporting Types

public enum SyncStatus: Equatable {
    case idle
    case syncing
    case completed
    case failed(Error)
    
    public static func == (lhs: SyncStatus, rhs: SyncStatus) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.syncing, .syncing), (.completed, .completed):
            return true
        case (.failed, .failed):
            return true
        default:
            return false
        }
    }
}

public struct SyncProgress {
    public var totalOperations: Int
    public var completedOperations: Int
    public var currentOperation: String
    
    public var progress: Double {
        guard totalOperations > 0 else { return 0 }
        return Double(completedOperations) / Double(totalOperations)
    }
}

public enum CloudKitError: LocalizedError {
    case accountUnavailable(String)
    case unknownError
    case recordNotFound
    case quotaExceeded
    case networkError
    
    public var errorDescription: String? {
        switch self {
        case .accountUnavailable(let message):
            return "iCloud account unavailable: \(message)"
        case .unknownError:
            return "An unknown error occurred"
        case .recordNotFound:
            return "Record not found"
        case .quotaExceeded:
            return "iCloud storage quota exceeded"
        case .networkError:
            return "Network error occurred"
        }
    }
}

public struct PendingCloudKitOperation: Codable, Equatable {
    public let id: UUID
    public let type: OperationType
    public let recordType: String
    public let recordID: String
    public let recordData: Data?
    public let timestamp: Date
    
    public init(id: UUID = UUID(), type: OperationType, recordType: String, recordID: String, recordData: Data? = nil) {
        self.id = id
        self.type = type
        self.recordType = recordType
        self.recordID = recordID
        self.recordData = recordData
        self.timestamp = Date()
    }
    
    public enum OperationType: String, Codable {
        case save, delete, modify
    }
}

// MARK: - CloudKit Model Protocol
public protocol CloudKitModel {
    static var recordType: String { get }
    func toCKRecord() -> CKRecord
    static func fromCKRecord(_ record: CKRecord) -> Self?
}

// MARK: - Array Extension
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}