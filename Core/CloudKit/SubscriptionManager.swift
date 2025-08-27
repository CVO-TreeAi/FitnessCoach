import Foundation
import CloudKit
import UserNotifications
import OSLog

/// Manages CloudKit subscriptions for real-time data synchronization and push notifications
@MainActor
public final class SubscriptionManager: ObservableObject {
    
    // MARK: - Properties
    private let container: CKContainer
    private let logger = Logger(subsystem: "FitnessCoach", category: "SubscriptionManager")
    
    @Published public var subscriptionsActive: Bool = false
    @Published public var pushNotificationsEnabled: Bool = false
    
    private var activeSubscriptions: [String: CKSubscription] = [:]
    
    // MARK: - Subscription Types
    public enum SubscriptionType: String, CaseIterable {
        case databaseChanges = "database-changes"
        case userDataChanges = "user-data-changes"
        case coachClientShared = "coach-client-shared"
        case workoutUpdates = "workout-updates"
        case nutritionUpdates = "nutrition-updates"
        case progressUpdates = "progress-updates"
        case goalUpdates = "goal-updates"
        case sharedWorkouts = "shared-workouts"
        case coachMessages = "coach-messages"
        case clientFeedback = "client-feedback"
    }
    
    // MARK: - Initialization
    public init(container: CKContainer = CKContainer.default()) {
        self.container = container
        setupInitialState()
    }
    
    private func setupInitialState() {
        Task {
            await checkExistingSubscriptions()
            await checkPushNotificationStatus()
        }
    }
    
    // MARK: - Subscription Management
    
    /// Sets up all necessary subscriptions for the app
    public func setupAllSubscriptions() async throws {
        logger.info("Setting up CloudKit subscriptions")
        
        // Request notification permissions first
        try await requestNotificationPermissions()
        
        // Setup database-level subscription
        try await setupDatabaseSubscription()
        
        // Setup record-level subscriptions
        try await setupRecordSubscriptions()
        
        // Setup zone-level subscriptions
        try await setupZoneSubscriptions()
        
        await MainActor.run {
            subscriptionsActive = true
        }
        
        logger.info("All CloudKit subscriptions set up successfully")
    }
    
    /// Sets up database-level subscription for general changes
    private func setupDatabaseSubscription() async throws {
        let subscriptionID = SubscriptionType.databaseChanges.rawValue
        
        // Check if subscription already exists
        if activeSubscriptions[subscriptionID] != nil {
            logger.info("Database subscription already exists")
            return
        }
        
        let subscription = CKDatabaseSubscription(subscriptionID: subscriptionID)
        
        // Configure notification info
        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.shouldSendContentAvailable = true
        notificationInfo.shouldBadge = false
        notificationInfo.title = "Data Updated"
        notificationInfo.subtitle = "Your fitness data has been updated"
        
        subscription.notificationInfo = notificationInfo
        
        try await saveSubscription(subscription)
        activeSubscriptions[subscriptionID] = subscription
    }
    
    /// Sets up record-level subscriptions for specific data types
    private func setupRecordSubscriptions() async throws {
        let subscriptions: [(SubscriptionType, String, NSPredicate)] = [
            (.workoutUpdates, "WorkoutSession", NSPredicate(format: "status == %@", "completed")),
            (.nutritionUpdates, "NutritionEntry", NSPredicate(format: "date >= %@", Date().addingTimeInterval(-86400) as NSDate)), // Last 24 hours
            (.progressUpdates, "ProgressEntry", NSPredicate(value: true)),
            (.goalUpdates, "Goal", NSPredicate(format: "status == %@", "completed")),
            (.sharedWorkouts, "SharedWorkout", NSPredicate(value: true)),
        ]
        
        for (subscriptionType, recordType, predicate) in subscriptions {
            try await setupRecordSubscription(subscriptionType, recordType: recordType, predicate: predicate)
        }
    }
    
    private func setupRecordSubscription(_ type: SubscriptionType, recordType: String, predicate: NSPredicate) async throws {
        let subscriptionID = type.rawValue
        
        if activeSubscriptions[subscriptionID] != nil {
            logger.info("\(subscriptionID) subscription already exists")
            return
        }
        
        let subscription = CKQuerySubscription(
            recordType: recordType,
            predicate: predicate,
            subscriptionID: subscriptionID,
            options: [.firesOnRecordCreation, .firesOnRecordUpdate, .firesOnRecordDeletion]
        )
        
        // Configure notification based on subscription type
        let notificationInfo = configureNotificationInfo(for: type)
        subscription.notificationInfo = notificationInfo
        
        try await saveSubscription(subscription)
        activeSubscriptions[subscriptionID] = subscription
    }
    
    /// Sets up zone-level subscriptions
    private func setupZoneSubscriptions() async throws {
        // Subscribe to changes in the CoachClientShared zone
        let subscriptionID = SubscriptionType.coachClientShared.rawValue
        
        if activeSubscriptions[subscriptionID] != nil {
            logger.info("CoachClient shared subscription already exists")
            return
        }
        
        let zoneID = CKRecordZone.ID(zoneName: "CoachClientShared")
        let subscription = CKRecordZoneSubscription(zoneID: zoneID, subscriptionID: subscriptionID)
        
        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.shouldSendContentAvailable = true
        notificationInfo.title = "Coach Update"
        notificationInfo.subtitle = "Your coach has sent you something new"
        notificationInfo.category = "COACH_COMMUNICATION"
        
        subscription.notificationInfo = notificationInfo
        
        try await saveSubscription(subscription)
        activeSubscriptions[subscriptionID] = subscription
    }
    
    /// Saves a subscription to CloudKit
    private func saveSubscription(_ subscription: CKSubscription) async throws {
        let operation = CKModifySubscriptionsOperation(subscriptionsToSave: [subscription], subscriptionIDsToDelete: nil)
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            operation.modifySubscriptionsResultBlock = { result in
                switch result {
                case .success(let (savedSubscriptions, _)):
                    if let saved = savedSubscriptions.first {
                        self.logger.info("Subscription saved: \(saved.subscriptionID)")
                    }
                    continuation.resume(returning: ())
                case .failure(let error):
                    self.logger.error("Failed to save subscription: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                }
            }
            
            container.privateCloudDatabase.add(operation)
        }
    }
    
    // MARK: - Push Notification Handling
    
    /// Handles incoming CloudKit push notifications
    public func handleCloudKitNotification(_ userInfo: [AnyHashable: Any]) async {
        logger.info("Handling CloudKit notification")
        
        guard let notification = CKNotification(fromRemoteNotificationDictionary: userInfo) else {
            logger.error("Invalid CloudKit notification format")
            return
        }
        
        switch notification.notificationType {
        case .query:
            await handleQueryNotification(notification as! CKQueryNotification)
        case .recordZone:
            await handleRecordZoneNotification(notification as! CKRecordZoneNotification)
        case .database:
            await handleDatabaseNotification(notification as! CKDatabaseNotification)
        @unknown default:
            logger.warning("Unknown CloudKit notification type")
        }
    }
    
    private func handleQueryNotification(_ notification: CKQueryNotification) async {
        logger.info("Handling query notification for subscription: \(notification.subscriptionID ?? "unknown")")
        
        guard let subscriptionID = notification.subscriptionID,
              let subscriptionType = SubscriptionType(rawValue: subscriptionID) else {
            return
        }
        
        // Trigger appropriate sync based on notification type
        switch subscriptionType {
        case .workoutUpdates:
            await handleWorkoutUpdate(notification)
        case .nutritionUpdates:
            await handleNutritionUpdate(notification)
        case .progressUpdates:
            await handleProgressUpdate(notification)
        case .goalUpdates:
            await handleGoalUpdate(notification)
        case .sharedWorkouts:
            await handleSharedWorkoutUpdate(notification)
        default:
            break
        }
        
        // Post notification for UI updates
        NotificationCenter.default.post(name: .cloudKitDataChanged, object: subscriptionType)
    }
    
    private func handleRecordZoneNotification(_ notification: CKRecordZoneNotification) async {
        logger.info("Handling record zone notification")
        
        // Trigger zone-specific sync
        if let zoneID = notification.recordZoneID {
            NotificationCenter.default.post(name: .cloudKitZoneChanged, object: zoneID)
        }
    }
    
    private func handleDatabaseNotification(_ notification: CKDatabaseNotification) async {
        logger.info("Handling database notification")
        
        // Trigger full sync
        NotificationCenter.default.post(name: .cloudKitDatabaseChanged, object: nil)
    }
    
    // MARK: - Specific Update Handlers
    
    private func handleWorkoutUpdate(_ notification: CKQueryNotification) async {
        logger.info("Handling workout update notification")
        
        // Show local notification if workout was completed
        if notification.queryNotificationReason == .recordCreated {
            await showLocalNotification(
                title: "Workout Completed! 💪",
                body: "Great job finishing your workout!",
                category: "WORKOUT_COMPLETION"
            )
        }
    }
    
    private func handleNutritionUpdate(_ notification: CKQueryNotification) async {
        logger.info("Handling nutrition update notification")
        
        // Could trigger nutrition goal progress updates
    }
    
    private func handleProgressUpdate(_ notification: CKQueryNotification) async {
        logger.info("Handling progress update notification")
        
        // Show congratulations for progress milestones
        await showLocalNotification(
            title: "Progress Updated! 📊",
            body: "Your fitness progress has been recorded",
            category: "PROGRESS_UPDATE"
        )
    }
    
    private func handleGoalUpdate(_ notification: CKQueryNotification) async {
        logger.info("Handling goal update notification")
        
        // Show celebration for completed goals
        if notification.queryNotificationReason == .recordUpdated {
            await showLocalNotification(
                title: "Goal Achieved! 🎉",
                body: "Congratulations on reaching your fitness goal!",
                category: "GOAL_ACHIEVEMENT"
            )
        }
    }
    
    private func handleSharedWorkoutUpdate(_ notification: CKQueryNotification) async {
        logger.info("Handling shared workout update notification")
        
        // Notify about new assignments from coach
        if notification.queryNotificationReason == .recordCreated {
            await showLocalNotification(
                title: "New Workout Assignment",
                body: "Your coach has assigned you a new workout",
                category: "COACH_ASSIGNMENT"
            )
        }
    }
    
    // MARK: - Local Notifications
    
    private func showLocalNotification(title: String, body: String, category: String) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.categoryIdentifier = category
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // Show immediately
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            logger.error("Failed to show local notification: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Subscription Management
    
    /// Checks for existing subscriptions
    private func checkExistingSubscriptions() async {
        do {
            let operation = CKFetchSubscriptionsOperation.fetchAllSubscriptionsOperation()
            
            let subscriptions = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[CKSubscription], Error>) in
                operation.fetchSubscriptionResultBlock = { result in
                    switch result {
                    case .success(let subscriptions):
                        continuation.resume(returning: Array(subscriptions.values))
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
                
                container.privateCloudDatabase.add(operation)
            }
            
            for subscription in subscriptions {
                activeSubscriptions[subscription.subscriptionID] = subscription
            }
            
            await MainActor.run {
                subscriptionsActive = !activeSubscriptions.isEmpty
            }
            
            logger.info("Found \(subscriptions.count) existing subscriptions")
            
        } catch {
            logger.error("Failed to fetch existing subscriptions: \(error.localizedDescription)")
        }
    }
    
    /// Removes a specific subscription
    public func removeSubscription(_ type: SubscriptionType) async throws {
        let subscriptionID = type.rawValue
        
        guard activeSubscriptions[subscriptionID] != nil else {
            logger.info("Subscription \(subscriptionID) does not exist")
            return
        }
        
        let operation = CKModifySubscriptionsOperation(subscriptionsToSave: nil, subscriptionIDsToDelete: [subscriptionID])
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            operation.modifySubscriptionsResultBlock = { result in
                switch result {
                case .success:
                    self.activeSubscriptions.removeValue(forKey: subscriptionID)
                    self.logger.info("Removed subscription: \(subscriptionID)")
                    continuation.resume(returning: ())
                case .failure(let error):
                    self.logger.error("Failed to remove subscription \(subscriptionID): \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                }
            }
            
            container.privateCloudDatabase.add(operation)
        }
    }
    
    /// Removes all subscriptions
    public func removeAllSubscriptions() async throws {
        let subscriptionIDs = Array(activeSubscriptions.keys)
        
        guard !subscriptionIDs.isEmpty else {
            logger.info("No subscriptions to remove")
            return
        }
        
        let operation = CKModifySubscriptionsOperation(subscriptionsToSave: nil, subscriptionIDsToDelete: subscriptionIDs)
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            operation.modifySubscriptionsResultBlock = { result in
                switch result {
                case .success:
                    self.activeSubscriptions.removeAll()
                    Task { @MainActor in
                        self.subscriptionsActive = false
                    }
                    self.logger.info("Removed all subscriptions")
                    continuation.resume(returning: ())
                case .failure(let error):
                    self.logger.error("Failed to remove all subscriptions: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                }
            }
            
            container.privateCloudDatabase.add(operation)
        }
    }
    
    // MARK: - Notification Permissions
    
    private func requestNotificationPermissions() async throws {
        let center = UNUserNotificationCenter.current()
        
        // Define notification categories
        setupNotificationCategories()
        
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            
            await MainActor.run {
                pushNotificationsEnabled = granted
            }
            
            if granted {
                logger.info("Notification permissions granted")
            } else {
                logger.warning("Notification permissions denied")
            }
            
        } catch {
            logger.error("Failed to request notification permissions: \(error.localizedDescription)")
            throw error
        }
    }
    
    private func checkPushNotificationStatus() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        
        await MainActor.run {
            pushNotificationsEnabled = settings.authorizationStatus == .authorized
        }
    }
    
    private func setupNotificationCategories() {
        let workoutAction = UNNotificationAction(
            identifier: "VIEW_WORKOUT",
            title: "View Workout",
            options: [.foreground]
        )
        
        let workoutCategory = UNNotificationCategory(
            identifier: "WORKOUT_COMPLETION",
            actions: [workoutAction],
            intentIdentifiers: [],
            options: []
        )
        
        let coachAction = UNNotificationAction(
            identifier: "VIEW_MESSAGE",
            title: "View Message",
            options: [.foreground]
        )
        
        let coachCategory = UNNotificationCategory(
            identifier: "COACH_COMMUNICATION",
            actions: [coachAction],
            intentIdentifiers: [],
            options: []
        )
        
        let goalCategory = UNNotificationCategory(
            identifier: "GOAL_ACHIEVEMENT",
            actions: [],
            intentIdentifiers: [],
            options: []
        )
        
        let progressCategory = UNNotificationCategory(
            identifier: "PROGRESS_UPDATE",
            actions: [],
            intentIdentifiers: [],
            options: []
        )
        
        let assignmentCategory = UNNotificationCategory(
            identifier: "COACH_ASSIGNMENT",
            actions: [workoutAction],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([
            workoutCategory, coachCategory, goalCategory, progressCategory, assignmentCategory
        ])
    }
    
    // MARK: - Helper Methods
    
    private func configureNotificationInfo(for subscriptionType: SubscriptionType) -> CKSubscription.NotificationInfo {
        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.shouldSendContentAvailable = true
        notificationInfo.shouldBadge = false
        
        switch subscriptionType {
        case .workoutUpdates:
            notificationInfo.title = "Workout Update"
            notificationInfo.subtitle = "Your workout has been updated"
            notificationInfo.category = "WORKOUT_COMPLETION"
            
        case .nutritionUpdates:
            notificationInfo.title = "Nutrition Update"
            notificationInfo.subtitle = "Your nutrition log has been updated"
            
        case .progressUpdates:
            notificationInfo.title = "Progress Update"
            notificationInfo.subtitle = "Your progress has been recorded"
            notificationInfo.category = "PROGRESS_UPDATE"
            
        case .goalUpdates:
            notificationInfo.title = "Goal Update"
            notificationInfo.subtitle = "Your goal status has changed"
            notificationInfo.category = "GOAL_ACHIEVEMENT"
            
        case .sharedWorkouts:
            notificationInfo.title = "New Workout"
            notificationInfo.subtitle = "Your coach has assigned a new workout"
            notificationInfo.category = "COACH_ASSIGNMENT"
            
        default:
            notificationInfo.title = "Fitness Update"
            notificationInfo.subtitle = "Your fitness data has been updated"
        }
        
        return notificationInfo
    }
    
    /// Gets the status of a specific subscription
    public func isSubscriptionActive(_ type: SubscriptionType) -> Bool {
        return activeSubscriptions[type.rawValue] != nil
    }
    
    /// Gets all active subscription types
    public var activeSubscriptionTypes: [SubscriptionType] {
        return activeSubscriptions.keys.compactMap { SubscriptionType(rawValue: $0) }
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let cloudKitDataChanged = Notification.Name("cloudKitDataChanged")
    static let cloudKitZoneChanged = Notification.Name("cloudKitZoneChanged")
    static let cloudKitDatabaseChanged = Notification.Name("cloudKitDatabaseChanged")
}