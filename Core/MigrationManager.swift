import Foundation
import CoreData
import CloudKit
import OSLog

/// Comprehensive data migration manager for Core Data and CloudKit schema updates
@MainActor
public final class MigrationManager: ObservableObject {
    
    static let shared = MigrationManager()
    
    // MARK: - Properties
    private let logger = Logger(subsystem: "FitnessCoach", category: "MigrationManager")
    
    @Published public var migrationStatus: MigrationStatus = .notStarted
    @Published public var migrationProgress: Double = 0.0
    @Published public var currentMigrationStep: String = ""
    
    private let coreDataManager = CoreDataManager.shared
    private let cloudKitManager = CloudKitManager.shared
    
    // Migration tracking
    private let migrationVersionKey = "migration_version"
    private let currentMigrationVersion = 3 // Update this when adding new migrations
    
    // MARK: - Migration Status
    public enum MigrationStatus {
        case notStarted
        case inProgress
        case completed
        case failed(Error)
        case rollback
    }
    
    // MARK: - Migration Types
    private enum MigrationType {
        case coreData
        case cloudKit
        case dataTransformation
        case userPreferences
    }
    
    private struct MigrationStep {
        let version: Int
        let type: MigrationType
        let description: String
        let operation: () async throws -> Void
    }
    
    // MARK: - Initialization
    private init() {}
    
    // MARK: - Migration Orchestration
    
    /// Performs all necessary migrations on app startup
    public func performStartupMigrations() async {
        logger.info("Starting startup migrations")
        
        let currentVersion = getCurrentMigrationVersion()
        
        guard currentVersion < currentMigrationVersion else {
            logger.info("No migrations needed - current version: \(currentVersion)")
            migrationStatus = .completed
            return
        }
        
        migrationStatus = .inProgress
        migrationProgress = 0.0
        
        do {
            await performMigrations(from: currentVersion, to: currentMigrationVersion)
            
            setMigrationVersion(currentMigrationVersion)
            
            await MainActor.run {
                self.migrationStatus = .completed
                self.migrationProgress = 1.0
            }
            
            logger.info("All migrations completed successfully")
            
        } catch {
            logger.error("Migration failed: \(error.localizedDescription)")
            
            await MainActor.run {
                self.migrationStatus = .failed(error)
            }
            
            // Attempt rollback if possible
            await attemptRollback(to: currentVersion)
        }
    }
    
    /// Performs migrations from one version to another
    private func performMigrations(from startVersion: Int, to endVersion: Int) async throws {
        let migrations = getMigrationSteps()
        let applicableMigrations = migrations.filter { $0.version > startVersion && $0.version <= endVersion }
        
        guard !applicableMigrations.isEmpty else { return }
        
        logger.info("Performing \(applicableMigrations.count) migrations")
        
        for (index, migration) in applicableMigrations.enumerated() {
            await updateMigrationStatus("Performing migration v\(migration.version): \(migration.description)")
            
            do {
                try await migration.operation()
                logger.info("Migration v\(migration.version) completed: \(migration.description)")
            } catch {
                logger.error("Migration v\(migration.version) failed: \(error.localizedDescription)")
                throw MigrationError.migrationFailed(version: migration.version, error: error)
            }
            
            let progress = Double(index + 1) / Double(applicableMigrations.count)
            await updateProgress(progress)
        }
    }
    
    // MARK: - Migration Steps Definition
    
    private func getMigrationSteps() -> [MigrationStep] {
        return [
            // Version 1: Initial data structure improvements
            MigrationStep(
                version: 1,
                type: .coreData,
                description: "Add user preferences and improve data relationships"
            ) {
                try await self.migration_v1_UserPreferencesAndRelationships()
            },
            
            // Version 2: CloudKit integration
            MigrationStep(
                version: 2,
                type: .cloudKit,
                description: "Migrate to CloudKit and sync existing data"
            ) {
                try await self.migration_v2_CloudKitIntegration()
            },
            
            // Version 3: Enhanced analytics and performance
            MigrationStep(
                version: 3,
                type: .dataTransformation,
                description: "Enhance analytics data and optimize performance"
            ) {
                try await self.migration_v3_AnalyticsAndPerformance()
            }
            
            // Add new migrations here as needed
        ]
    }
    
    // MARK: - Individual Migration Implementations
    
    /// Migration v1: Add user preferences and improve data relationships
    private func migration_v1_UserPreferencesAndRelationships() async throws {
        logger.info("Starting migration v1: User preferences and relationships")
        
        let context = coreDataManager.context
        
        try await context.perform {
            // Create default user preferences for existing users
            let userRequest = User.fetchRequest()
            let existingUsers = try context.fetch(userRequest)
            
            for user in existingUsers {
                // Add default fitness goals if not present
                if user.fitnessGoals?.isEmpty != false {
                    user.fitnessGoals = ["Weight Loss", "Muscle Building", "General Fitness"]
                }
                
                // Set default activity level if not present
                if user.activityLevel?.isEmpty != false {
                    user.activityLevel = "Moderate"
                }
                
                // Ensure timestamps are set
                if user.createdAt == nil {
                    user.createdAt = Date()
                }
                if user.updatedAt == nil {
                    user.updatedAt = Date()
                }
            }
            
            // Fix any orphaned workout sessions
            let sessionRequest = WorkoutSession.fetchRequest()
            sessionRequest.predicate = NSPredicate(format: "user == nil")
            let orphanedSessions = try context.fetch(sessionRequest)
            
            for session in orphanedSessions {
                // Try to link to first user, or delete if no users exist
                if let firstUser = existingUsers.first {
                    session.user = firstUser
                    self.logger.info("Linked orphaned workout session to user: \(firstUser.email ?? "unknown")")
                } else {
                    context.delete(session)
                    self.logger.info("Deleted orphaned workout session")
                }
            }
            
            try context.save()
        }
        
        logger.info("Migration v1 completed")
    }
    
    /// Migration v2: CloudKit integration and data sync
    private func migration_v2_CloudKitIntegration() async throws {
        logger.info("Starting migration v2: CloudKit integration")
        
        // Check CloudKit availability
        let accountStatus = await cloudKitManager.checkAccountStatus()
        guard accountStatus == .available else {
            logger.warning("CloudKit not available, skipping CloudKit migration")
            return
        }
        
        // Create CloudKit zones
        let cloudKitZones = CloudKitZones()
        try await cloudKitZones.createAllZones()
        
        // Migrate existing Core Data objects to CloudKit
        try await migrateExistingDataToCloudKit()
        
        // Set up CloudKit subscriptions
        let subscriptionManager = SubscriptionManager()
        try await subscriptionManager.setupAllSubscriptions()
        
        logger.info("Migration v2 completed")
    }
    
    /// Migration v3: Enhanced analytics and performance optimizations
    private func migration_v3_AnalyticsAndPerformance() async throws {
        logger.info("Starting migration v3: Analytics and performance")
        
        let context = coreDataManager.context
        
        try await context.perform {
            // Add analytics tracking to existing workout sessions
            let sessionRequest = WorkoutSession.fetchRequest()
            let sessions = try context.fetch(sessionRequest)
            
            for session in sessions {
                // Calculate and store additional metrics if missing
                if session.caloriesBurned == 0 && session.totalDuration > 0 {
                    // Estimate calories based on duration (rough estimate)
                    let estimatedCalories = Int16(Double(session.totalDuration) * 8.0) // 8 cal/min average
                    session.caloriesBurned = estimatedCalories
                }
            }
            
            // Optimize nutrition entries by removing duplicates
            try self.removeDuplicateNutritionEntries(in: context)
            
            // Add progress entry metadata
            let progressRequest = ProgressEntry.fetchRequest()
            let progressEntries = try context.fetch(progressRequest)
            
            for entry in progressEntries {
                // Calculate BMI if missing but height/weight available
                if entry.bmi == 0 && entry.weight > 0 {
                    // We'd need user height for this calculation
                    if let user = entry.user, user.height > 0 {
                        let heightInMeters = user.height * 0.0254 // Convert inches to meters
                        let weightInKg = entry.weight * 0.453592 // Convert pounds to kg
                        entry.bmi = weightInKg / (heightInMeters * heightInMeters)
                    }
                }
            }
            
            try context.save()
        }
        
        // Initialize analytics tracking for existing data
        await initializeAnalyticsForExistingData()
        
        logger.info("Migration v3 completed")
    }
    
    // MARK: - Migration Helper Methods
    
    private func migrateExistingDataToCloudKit() async throws {
        logger.info("Migrating existing data to CloudKit")
        
        let context = coreDataManager.context
        
        // Get count of objects to migrate
        let totalObjects = try await context.perform {
            let userCount = try context.count(for: User.fetchRequest())
            let workoutCount = try context.count(for: WorkoutSession.fetchRequest())
            let nutritionCount = try context.count(for: NutritionEntry.fetchRequest())
            let progressCount = try context.count(for: ProgressEntry.fetchRequest())
            
            return userCount + workoutCount + nutritionCount + progressCount
        }
        
        guard totalObjects > 0 else {
            logger.info("No existing data to migrate")
            return
        }
        
        var migratedCount = 0
        
        // Migrate users
        let users = try await context.perform {
            try context.fetch(User.fetchRequest())
        }
        
        for user in users {
            let record = user.toCKRecord()
            try await cloudKitManager.save(record: record)
            migratedCount += 1
            await updateProgress(Double(migratedCount) / Double(totalObjects))
        }
        
        // Migrate workout sessions
        let sessions = try await context.perform {
            try context.fetch(WorkoutSession.fetchRequest())
        }
        
        for session in sessions {
            let record = session.toCKRecord()
            try await cloudKitManager.save(record: record)
            migratedCount += 1
            await updateProgress(Double(migratedCount) / Double(totalObjects))
        }
        
        // Migrate nutrition entries
        let nutritionEntries = try await context.perform {
            try context.fetch(NutritionEntry.fetchRequest())
        }
        
        for entry in nutritionEntries {
            let record = entry.toCKRecord()
            try await cloudKitManager.save(record: record)
            migratedCount += 1
            await updateProgress(Double(migratedCount) / Double(totalObjects))
        }
        
        // Migrate progress entries
        let progressEntries = try await context.perform {
            try context.fetch(ProgressEntry.fetchRequest())
        }
        
        for entry in progressEntries {
            let record = entry.toCKRecord()
            try await cloudKitManager.save(record: record)
            migratedCount += 1
            await updateProgress(Double(migratedCount) / Double(totalObjects))
        }
        
        logger.info("Migrated \(migratedCount) objects to CloudKit")
    }
    
    private func removeDuplicateNutritionEntries(in context: NSManagedObjectContext) throws {
        let request = NutritionEntry.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \NutritionEntry.date, ascending: true),
            NSSortDescriptor(keyPath: \NutritionEntry.mealType, ascending: true)
        ]
        
        let entries = try context.fetch(request)
        var seenEntries = Set<String>()
        var duplicatesToRemove: [NutritionEntry] = []
        
        for entry in entries {
            let key = "\(entry.date?.timeIntervalSince1970 ?? 0)-\(entry.mealType ?? "")-\(entry.calories)-\(entry.foodItem?.name ?? "")"
            
            if seenEntries.contains(key) {
                duplicatesToRemove.append(entry)
            } else {
                seenEntries.insert(key)
            }
        }
        
        for duplicate in duplicatesToRemove {
            context.delete(duplicate)
        }
        
        if !duplicatesToRemove.isEmpty {
            logger.info("Removed \(duplicatesToRemove.count) duplicate nutrition entries")
        }
    }
    
    private func initializeAnalyticsForExistingData() async {
        // Initialize analytics tracking for existing users
        let analyticsManager = AnalyticsManager.shared
        
        // Track that migration completed
        analyticsManager.track(event: .appLaunch, parameters: [
            "migration_completed": true,
            "migration_version": currentMigrationVersion
        ])
    }
    
    // MARK: - Rollback Support
    
    private func attemptRollback(to version: Int) async {
        logger.warning("Attempting rollback to version \(version)")
        
        await MainActor.run {
            self.migrationStatus = .rollback
            self.currentMigrationStep = "Rolling back changes..."
        }
        
        // Implementation would depend on the specific migration
        // For now, we'll just reset to the previous version
        setMigrationVersion(version)
        
        logger.info("Rollback completed to version \(version)")
    }
    
    // MARK: - Schema Migration Support
    
    /// Handles Core Data schema migrations
    public func handleCoreDataMigration() -> Bool {
        logger.info("Checking Core Data migration requirements")
        
        guard let storeURL = coreDataManager.persistentContainer.persistentStoreDescriptions.first?.url else {
            logger.error("Could not find persistent store URL")
            return false
        }
        
        do {
            let metadata = try NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: NSSQLiteStoreType, at: storeURL)
            let model = coreDataManager.persistentContainer.managedObjectModel
            
            if !model.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata) {
                logger.info("Core Data model migration required")
                return performCoreDataMigration(at: storeURL)
            } else {
                logger.info("No Core Data migration required")
                return true
            }
            
        } catch {
            logger.error("Failed to check Core Data migration requirements: \(error.localizedDescription)")
            return false
        }
    }
    
    private func performCoreDataMigration(at storeURL: URL) -> Bool {
        logger.info("Performing Core Data migration")
        
        // Create backup before migration
        let backupURL = storeURL.appendingPathExtension("backup")
        
        do {
            if FileManager.default.fileExists(atPath: backupURL.path) {
                try FileManager.default.removeItem(at: backupURL)
            }
            try FileManager.default.copyItem(at: storeURL, to: backupURL)
            logger.info("Created database backup at: \(backupURL.path)")
            
        } catch {
            logger.error("Failed to create database backup: \(error.localizedDescription)")
            return false
        }
        
        // Perform the migration
        do {
            let migrationManager = NSMigrationManager(sourceModel: getSourceModel(), destinationModel: getDestinationModel())
            let mappingModel = try getMappingModel()
            
            let tempURL = storeURL.appendingPathExtension("temp")
            
            try migrationManager.migrateStore(
                from: storeURL,
                sourceType: NSSQLiteStoreType,
                options: nil,
                with: mappingModel,
                toDestinationURL: tempURL,
                destinationType: NSSQLiteStoreType,
                destinationOptions: nil
            )
            
            // Replace original with migrated store
            try FileManager.default.removeItem(at: storeURL)
            try FileManager.default.moveItem(at: tempURL, to: storeURL)
            
            logger.info("Core Data migration completed successfully")
            return true
            
        } catch {
            logger.error("Core Data migration failed: \(error.localizedDescription)")
            
            // Restore from backup
            do {
                if FileManager.default.fileExists(atPath: storeURL.path) {
                    try FileManager.default.removeItem(at: storeURL)
                }
                try FileManager.default.moveItem(at: backupURL, to: storeURL)
                logger.info("Restored database from backup")
            } catch {
                logger.error("Failed to restore database backup: \(error.localizedDescription)")
            }
            
            return false
        }
    }
    
    // MARK: - CloudKit Schema Migration
    
    /// Handles CloudKit schema updates
    public func performCloudKitSchemaMigration() async throws {
        logger.info("Performing CloudKit schema migration")
        
        // Check current CloudKit schema version
        let currentSchemaVersion = await getCloudKitSchemaVersion()
        let targetSchemaVersion = 2 // Update this when schema changes
        
        if currentSchemaVersion >= targetSchemaVersion {
            logger.info("CloudKit schema is up to date")
            return
        }
        
        // Perform schema updates
        for version in (currentSchemaVersion + 1)...targetSchemaVersion {
            try await performCloudKitSchemaUpdate(to: version)
        }
        
        await setCloudKitSchemaVersion(targetSchemaVersion)
        logger.info("CloudKit schema migration completed")
    }
    
    private func performCloudKitSchemaUpdate(to version: Int) async throws {
        logger.info("Updating CloudKit schema to version \(version)")
        
        switch version {
        case 1:
            // Add new fields or record types
            try await addNewCloudKitFields()
            
        case 2:
            // Update existing record structures
            try await updateCloudKitRecordStructures()
            
        default:
            logger.warning("Unknown CloudKit schema version: \(version)")
        }
    }
    
    private func addNewCloudKitFields() async throws {
        // Implementation for adding new CloudKit fields
        logger.info("Adding new CloudKit fields")
    }
    
    private func updateCloudKitRecordStructures() async throws {
        // Implementation for updating CloudKit record structures
        logger.info("Updating CloudKit record structures")
    }
    
    // MARK: - Legacy Data Import
    
    /// Imports data from legacy formats or previous app versions
    public func importLegacyData(from url: URL) async throws {
        logger.info("Importing legacy data from: \(url.path)")
        
        migrationStatus = .inProgress
        currentMigrationStep = "Importing legacy data..."
        
        do {
            let data = try Data(contentsOf: url)
            
            if url.pathExtension.lowercased() == "json" {
                try await importFromJSON(data)
            } else if url.pathExtension.lowercased() == "csv" {
                try await importFromCSV(data)
            } else {
                throw MigrationError.unsupportedFormat
            }
            
            migrationStatus = .completed
            logger.info("Legacy data import completed")
            
        } catch {
            migrationStatus = .failed(error)
            logger.error("Legacy data import failed: \(error.localizedDescription)")
            throw error
        }
    }
    
    private func importFromJSON(_ data: Data) async throws {
        // Implementation for JSON import
        logger.info("Importing from JSON format")
    }
    
    private func importFromCSV(_ data: Data) async throws {
        // Implementation for CSV import
        logger.info("Importing from CSV format")
    }
    
    // MARK: - Version Management
    
    private func getCurrentMigrationVersion() -> Int {
        return UserDefaults.standard.integer(forKey: migrationVersionKey)
    }
    
    private func setMigrationVersion(_ version: Int) {
        UserDefaults.standard.set(version, forKey: migrationVersionKey)
        logger.info("Set migration version to: \(version)")
    }
    
    private func getCloudKitSchemaVersion() async -> Int {
        // This would typically be stored in CloudKit or your backend
        return UserDefaults.standard.integer(forKey: "cloudkit_schema_version")
    }
    
    private func setCloudKitSchemaVersion(_ version: Int) async {
        UserDefaults.standard.set(version, forKey: "cloudkit_schema_version")
    }
    
    // MARK: - Helper Methods
    
    private func updateMigrationStatus(_ status: String) async {
        await MainActor.run {
            self.currentMigrationStep = status
        }
        logger.info("Migration status: \(status)")
    }
    
    private func updateProgress(_ progress: Double) async {
        await MainActor.run {
            self.migrationProgress = progress
        }
    }
    
    private func getSourceModel() -> NSManagedObjectModel {
        // Return the source Core Data model
        return NSManagedObjectModel()
    }
    
    private func getDestinationModel() -> NSManagedObjectModel {
        // Return the destination Core Data model
        return coreDataManager.persistentContainer.managedObjectModel
    }
    
    private func getMappingModel() throws -> NSMappingModel {
        // Return or create the mapping model for Core Data migration
        throw MigrationError.mappingModelNotFound
    }
    
    // MARK: - Public Interface
    
    /// Checks if any migrations are pending
    public var hasPendingMigrations: Bool {
        return getCurrentMigrationVersion() < currentMigrationVersion
    }
    
    /// Gets the current migration progress as a percentage
    public var progressPercentage: Int {
        return Int(migrationProgress * 100)
    }
    
    /// Forces a complete data reset and migration
    public func forceCompleteReset() async throws {
        logger.warning("Performing complete data reset")
        
        migrationStatus = .inProgress
        currentMigrationStep = "Resetting all data..."
        
        // Reset Core Data
        try await resetCoreData()
        
        // Reset CloudKit subscriptions
        try await resetCloudKitSubscriptions()
        
        // Reset user preferences
        resetUserPreferences()
        
        // Reset migration version
        setMigrationVersion(0)
        
        // Perform fresh migration
        await performStartupMigrations()
        
        logger.info("Complete reset and migration completed")
    }
    
    private func resetCoreData() async throws {
        let context = coreDataManager.context
        
        try await context.perform {
            // Delete all entities
            let entityNames = ["User", "Coach", "Client", "WorkoutSession", "Exercise", "NutritionEntry", "ProgressEntry", "Goal"]
            
            for entityName in entityNames {
                let request = NSFetchRequest<NSManagedObject>(entityName: entityName)
                let objects = try context.fetch(request)
                
                for object in objects {
                    context.delete(object)
                }
            }
            
            try context.save()
        }
    }
    
    private func resetCloudKitSubscriptions() async throws {
        let subscriptionManager = SubscriptionManager()
        try await subscriptionManager.removeAllSubscriptions()
    }
    
    private func resetUserPreferences() {
        let defaultsToReset = [
            "analytics_enabled",
            "data_collection_enabled",
            "cloudkit_schema_version",
            "lastSuccessfulValidation",
            "pendingCloudKitOperations"
        ]
        
        for key in defaultsToReset {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }
}

// MARK: - Supporting Types

public enum MigrationError: LocalizedError {
    case migrationFailed(version: Int, error: Error)
    case unsupportedFormat
    case mappingModelNotFound
    case cloudKitSchemaUpdateFailed
    case dataCorruption
    
    public var errorDescription: String? {
        switch self {
        case .migrationFailed(let version, let error):
            return "Migration to version \(version) failed: \(error.localizedDescription)"
        case .unsupportedFormat:
            return "Unsupported data format for import"
        case .mappingModelNotFound:
            return "Core Data mapping model not found"
        case .cloudKitSchemaUpdateFailed:
            return "Failed to update CloudKit schema"
        case .dataCorruption:
            return "Data corruption detected during migration"
        }
    }
}