import Foundation
import CloudKit
import OSLog

/// Manages CloudKit zones for different data types and user relationships
public final class CloudKitZones {
    
    // MARK: - Zone Definitions
    public enum Zone {
        case privateUserData        // Private database - user's personal data
        case coachClientShared     // Shared database - coach-client collaboration
        case publicTemplates       // Public database - shared workout/meal templates
        case exerciseLibrary       // Public database - exercise library
        
        var zoneID: CKRecordZone.ID {
            switch self {
            case .privateUserData:
                return CKRecordZone.ID(zoneName: "PrivateUserData", ownerName: CKCurrentUserDefaultName)
            case .coachClientShared:
                return CKRecordZone.ID(zoneName: "CoachClientShared", ownerName: CKCurrentUserDefaultName)
            case .publicTemplates:
                return CKRecordZone.ID(zoneName: "PublicTemplates", ownerName: CKCurrentUserDefaultName)
            case .exerciseLibrary:
                return CKRecordZone.ID(zoneName: "ExerciseLibrary", ownerName: CKCurrentUserDefaultName)
            }
        }
        
        var database: CKDatabase {
            switch self {
            case .privateUserData, .coachClientShared:
                return CKContainer.default().privateCloudDatabase
            case .publicTemplates, .exerciseLibrary:
                return CKContainer.default().publicCloudDatabase
            }
        }
        
        var recordTypes: [String] {
            switch self {
            case .privateUserData:
                return ["User", "Coach", "Client", "WorkoutSession", "NutritionEntry", "ProgressEntry", "Goal"]
            case .coachClientShared:
                return ["SharedWorkout", "SharedMealPlan", "CoachMessage", "ClientFeedback"]
            case .publicTemplates:
                return ["WorkoutTemplate", "MealPlanTemplate"]
            case .exerciseLibrary:
                return ["Exercise", "FoodItem"]
            }
        }
    }
    
    // MARK: - Properties
    private let container: CKContainer
    private let logger = Logger(subsystem: "FitnessCoach", category: "CloudKitZones")
    
    // MARK: - Initialization
    public init(container: CKContainer = CKContainer.default()) {
        self.container = container
    }
    
    // MARK: - Zone Management
    
    /// Creates all necessary zones for the app
    public func createAllZones() async throws {
        logger.info("Creating CloudKit zones")
        
        // Create private zones
        try await createPrivateZones()
        
        // Create public zones (only if user has permissions)
        if await hasPublicDatabasePermissions() {
            try await createPublicZones()
        }
        
        logger.info("All CloudKit zones created successfully")
    }
    
    /// Creates zones in the private database
    private func createPrivateZones() async throws {
        let privateDatabaseZones: [Zone] = [.privateUserData, .coachClientShared]
        
        for zone in privateDatabaseZones {
            try await createZone(zone)
        }
    }
    
    /// Creates zones in the public database
    private func createPublicZones() async throws {
        let publicDatabaseZones: [Zone] = [.publicTemplates, .exerciseLibrary]
        
        for zone in publicDatabaseZones {
            try await createZone(zone)
        }
    }
    
    /// Creates a specific zone
    public func createZone(_ zone: Zone) async throws {
        let recordZone = CKRecordZone(zoneID: zone.zoneID)
        let operation = CKModifyRecordZonesOperation(recordZonesToSave: [recordZone], recordZoneIDsToDelete: nil)
        
        operation.modifyRecordZonesResultBlock = { result in
            switch result {
            case .success(let (savedZones, _)):
                self.logger.info("Created zone: \(savedZones.first?.zoneID.zoneName ?? "unknown")")
            case .failure(let error):
                if let ckError = error as? CKError, ckError.code == .zoneNotEmpty {
                    // Zone already exists, which is fine
                    self.logger.info("Zone \(zone.zoneID.zoneName) already exists")
                } else {
                    self.logger.error("Failed to create zone \(zone.zoneID.zoneName): \(error.localizedDescription)")
                }
            }
        }
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            operation.modifyRecordZonesResultBlock = { result in
                switch result {
                case .success:
                    continuation.resume(returning: ())
                case .failure(let error):
                    // Ignore zone already exists error
                    if let ckError = error as? CKError, ckError.code == .zoneNotEmpty {
                        continuation.resume(returning: ())
                    } else {
                        continuation.resume(throwing: error)
                    }
                }
            }
            
            zone.database.add(operation)
        }
    }
    
    /// Deletes a specific zone
    public func deleteZone(_ zone: Zone) async throws {
        let operation = CKModifyRecordZonesOperation(recordZonesToSave: nil, recordZoneIDsToDelete: [zone.zoneID])
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            operation.modifyRecordZonesResultBlock = { result in
                switch result {
                case .success:
                    self.logger.info("Deleted zone: \(zone.zoneID.zoneName)")
                    continuation.resume(returning: ())
                case .failure(let error):
                    self.logger.error("Failed to delete zone \(zone.zoneID.zoneName): \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                }
            }
            
            zone.database.add(operation)
        }
    }
    
    /// Fetches all zones in a database
    public func fetchZones(in database: CKDatabase) async throws -> [CKRecordZone] {
        let operation = CKFetchRecordZonesOperation.fetchAllRecordZonesOperation()
        
        return try await withCheckedThrowingContinuation { continuation in
            operation.fetchRecordZonesResultBlock = { result in
                switch result {
                case .success(let zones):
                    continuation.resume(returning: Array(zones.values))
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            
            database.add(operation)
        }
    }
    
    // MARK: - Zone-Specific Operations
    
    /// Gets the appropriate zone for a record type
    public func getZone(for recordType: String) -> Zone? {
        for zone in [Zone.privateUserData, .coachClientShared, .publicTemplates, .exerciseLibrary] {
            if zone.recordTypes.contains(recordType) {
                return zone
            }
        }
        return nil
    }
    
    /// Saves a record to its appropriate zone
    public func saveRecord(_ record: CKRecord) async throws -> CKRecord {
        guard let zone = getZone(for: record.recordType) else {
            throw ZoneError.noAppropriateZone(recordType: record.recordType)
        }
        
        // Ensure record is in the correct zone
        let zoneRecord = record.copy() as! CKRecord
        zoneRecord.setObject(zone.zoneID, forKey: "zoneID")
        
        let operation = CKModifyRecordsOperation(recordsToSave: [zoneRecord], recordIDsToDelete: nil)
        operation.savePolicy = .changedKeys
        
        return try await withCheckedThrowingContinuation { continuation in
            operation.modifyRecordsResultBlock = { result in
                switch result {
                case .success(let (savedRecords, _)):
                    if let savedRecord = savedRecords.first {
                        continuation.resume(returning: savedRecord)
                    } else {
                        continuation.resume(throwing: ZoneError.recordNotSaved)
                    }
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            
            zone.database.add(operation)
        }
    }
    
    /// Fetches records from a specific zone
    public func fetchRecords(from zone: Zone, recordType: String, predicate: NSPredicate = NSPredicate(value: true)) async throws -> [CKRecord] {
        let query = CKQuery(recordType: recordType, predicate: predicate)
        let operation = CKQueryOperation(query: query)
        operation.zoneID = zone.zoneID
        
        return try await withCheckedThrowingContinuation { continuation in
            var records: [CKRecord] = []
            
            operation.recordFetchedBlock = { record in
                records.append(record)
            }
            
            operation.queryResultBlock = { result in
                switch result {
                case .success:
                    continuation.resume(returning: records)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            
            zone.database.add(operation)
        }
    }
    
    // MARK: - Sharing and Collaboration
    
    /// Creates a share for coach-client collaboration
    public func createCoachClientShare(for record: CKRecord, coachID: String, clientID: String) async throws -> CKShare {
        let share = CKShare(rootRecord: record)
        share[CKShare.SystemFieldKey.title] = "Fitness Plan Collaboration" as NSString
        share[CKShare.SystemFieldKey.shareType] = "fitness.collaboration" as NSString
        
        // Configure sharing permissions
        share.publicPermission = .none
        
        // Add coach and client as participants
        let coachParticipant = CKShare.Participant()
        coachParticipant.userIdentity = CKUserIdentity()
        coachParticipant.userIdentity?.userRecordID = CKRecord.ID(recordName: coachID)
        coachParticipant.permission = .readWrite
        coachParticipant.role = .owner
        
        let clientParticipant = CKShare.Participant()
        clientParticipant.userIdentity = CKUserIdentity()
        clientParticipant.userIdentity?.userRecordID = CKRecord.ID(recordName: clientID)
        clientParticipant.permission = .readWrite
        clientParticipant.role = .privateUser
        
        let operation = CKModifyRecordsOperation(recordsToSave: [record, share], recordIDsToDelete: nil)
        
        return try await withCheckedThrowingContinuation { continuation in
            operation.modifyRecordsResultBlock = { result in
                switch result {
                case .success(let (savedRecords, _)):
                    if let savedShare = savedRecords.first(where: { $0 is CKShare }) as? CKShare {
                        continuation.resume(returning: savedShare)
                    } else {
                        continuation.resume(throwing: ZoneError.shareNotCreated)
                    }
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            
            container.sharedCloudDatabase.add(operation)
        }
    }
    
    /// Accepts a share invitation
    public func acceptShare(_ share: CKShare.Metadata) async throws {
        let operation = CKAcceptSharesOperation(shareMetadatas: [share])
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            operation.acceptSharesResultBlock = { result in
                switch result {
                case .success:
                    self.logger.info("Successfully accepted share")
                    continuation.resume(returning: ())
                case .failure(let error):
                    self.logger.error("Failed to accept share: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                }
            }
            
            container.add(operation)
        }
    }
    
    // MARK: - Zone Migration
    
    /// Migrates data from one zone to another
    public func migrateRecords(from sourceZone: Zone, to destinationZone: Zone, recordTypes: [String]) async throws {
        logger.info("Migrating records from \(sourceZone.zoneID.zoneName) to \(destinationZone.zoneID.zoneName)")
        
        for recordType in recordTypes {
            let records = try await fetchRecords(from: sourceZone, recordType: recordType)
            
            // Create new records in destination zone
            let migratedRecords = records.map { record -> CKRecord in
                let newRecord = CKRecord(recordType: record.recordType, zoneID: destinationZone.zoneID)
                
                // Copy all fields except system fields
                for key in record.allKeys() {
                    if !key.hasPrefix("___") {  // Skip system fields
                        newRecord[key] = record[key]
                    }
                }
                
                return newRecord
            }
            
            // Save to destination zone
            let operation = CKModifyRecordsOperation(recordsToSave: migratedRecords, recordIDsToDelete: nil)
            
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                operation.modifyRecordsResultBlock = { result in
                    switch result {
                    case .success:
                        continuation.resume(returning: ())
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
                
                destinationZone.database.add(operation)
            }
            
            // Delete from source zone
            let recordIDsToDelete = records.map { $0.recordID }
            let deleteOperation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: recordIDsToDelete)
            
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                deleteOperation.modifyRecordsResultBlock = { result in
                    switch result {
                    case .success:
                        continuation.resume(returning: ())
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
                
                sourceZone.database.add(deleteOperation)
            }
        }
        
        logger.info("Migration completed")
    }
    
    // MARK: - Permissions and Capabilities
    
    /// Checks if the user has permissions for public database operations
    private func hasPublicDatabasePermissions() async -> Bool {
        do {
            let accountStatus = try await container.accountStatus()
            return accountStatus == .available
        } catch {
            logger.error("Failed to check account status: \(error.localizedDescription)")
            return false
        }
    }
    
    /// Checks if sharing is available
    public func isSharingAvailable() async -> Bool {
        do {
            let accountStatus = try await container.accountStatus()
            return accountStatus == .available
        } catch {
            return false
        }
    }
    
    // MARK: - Zone Health and Maintenance
    
    /// Validates zone integrity
    public func validateZoneIntegrity(_ zone: Zone) async throws -> ZoneHealthReport {
        logger.info("Validating zone integrity for \(zone.zoneID.zoneName)")
        
        var report = ZoneHealthReport(zoneName: zone.zoneID.zoneName)
        
        // Check if zone exists
        do {
            let zones = try await fetchZones(in: zone.database)
            report.zoneExists = zones.contains { $0.zoneID == zone.zoneID }
        } catch {
            report.zoneExists = false
            report.errors.append("Failed to fetch zones: \(error.localizedDescription)")
        }
        
        // Check record counts for each type
        for recordType in zone.recordTypes {
            do {
                let records = try await fetchRecords(from: zone, recordType: recordType)
                report.recordCounts[recordType] = records.count
            } catch {
                report.errors.append("Failed to count \(recordType) records: \(error.localizedDescription)")
            }
        }
        
        report.isHealthy = report.errors.isEmpty && report.zoneExists
        
        logger.info("Zone validation completed. Healthy: \(report.isHealthy)")
        return report
    }
    
    /// Performs zone maintenance (cleanup, optimization)
    public func performZoneMaintenance(_ zone: Zone) async throws {
        logger.info("Performing maintenance for zone \(zone.zoneID.zoneName)")
        
        // Remove duplicate records
        try await removeDuplicateRecords(in: zone)
        
        // Cleanup orphaned records
        try await cleanupOrphanedRecords(in: zone)
        
        logger.info("Zone maintenance completed")
    }
    
    private func removeDuplicateRecords(in zone: Zone) async throws {
        // Implementation for removing duplicate records based on unique identifiers
        for recordType in zone.recordTypes {
            let records = try await fetchRecords(from: zone, recordType: recordType)
            
            // Find duplicates based on a unique field (e.g., 'id' field)
            var seenIDs: Set<String> = []
            var duplicates: [CKRecord] = []
            
            for record in records {
                if let idValue = record["id"] as? String {
                    if seenIDs.contains(idValue) {
                        duplicates.append(record)
                    } else {
                        seenIDs.insert(idValue)
                    }
                }
            }
            
            if !duplicates.isEmpty {
                let recordIDsToDelete = duplicates.map { $0.recordID }
                let operation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: recordIDsToDelete)
                
                try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                    operation.modifyRecordsResultBlock = { result in
                        switch result {
                        case .success:
                            self.logger.info("Removed \(duplicates.count) duplicate \(recordType) records")
                            continuation.resume(returning: ())
                        case .failure(let error):
                            continuation.resume(throwing: error)
                        }
                    }
                    
                    zone.database.add(operation)
                }
            }
        }
    }
    
    private func cleanupOrphanedRecords(in zone: Zone) async throws {
        // Implementation for cleaning up records that have broken references
        // This would involve checking reference fields and removing records with invalid references
    }
}

// MARK: - Supporting Types

public struct ZoneHealthReport {
    public let zoneName: String
    public var zoneExists: Bool = false
    public var recordCounts: [String: Int] = [:]
    public var errors: [String] = []
    public var isHealthy: Bool = false
    
    public init(zoneName: String) {
        self.zoneName = zoneName
    }
}

public enum ZoneError: LocalizedError {
    case noAppropriateZone(recordType: String)
    case recordNotSaved
    case shareNotCreated
    case migrationFailed
    case zoneNotFound
    
    public var errorDescription: String? {
        switch self {
        case .noAppropriateZone(let recordType):
            return "No appropriate zone found for record type: \(recordType)"
        case .recordNotSaved:
            return "Record was not saved successfully"
        case .shareNotCreated:
            return "Share was not created successfully"
        case .migrationFailed:
            return "Zone migration failed"
        case .zoneNotFound:
            return "Zone not found"
        }
    }
}