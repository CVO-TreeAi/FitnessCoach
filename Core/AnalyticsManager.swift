import Foundation
import Combine
import OSLog
import CryptoKit

/// Comprehensive analytics and usage tracking with privacy-first approach
@MainActor
public final class AnalyticsManager: ObservableObject {
    
    static let shared = AnalyticsManager()
    
    // MARK: - Properties
    private let logger = Logger(subsystem: "FitnessCoach", category: "AnalyticsManager")
    
    @Published public var isAnalyticsEnabled: Bool = true
    @Published public var isDataCollectionEnabled: Bool = true
    @Published public var sessionMetrics: SessionMetrics = SessionMetrics()
    
    // Analytics storage
    private let analyticsQueue = DispatchQueue(label: "analytics.queue", qos: .utility)
    private var eventQueue: [AnalyticsEvent] = []
    private let maxQueueSize = 100
    private let batchUploadSize = 50
    
    // Session tracking
    private var sessionStartTime: Date?
    private var lastActivityTime: Date = Date()
    private let sessionTimeoutInterval: TimeInterval = 300 // 5 minutes
    
    // Crash reporting
    private var crashReports: [CrashReport] = []
    
    // Performance monitoring
    private var performanceMetrics: [PerformanceMetric] = []
    
    // User preferences
    private let analyticsEnabledKey = "analytics_enabled"
    private let dataCollectionEnabledKey = "data_collection_enabled"
    
    // MARK: - Analytics Events
    public enum EventType: String, CaseIterable {
        // User Engagement
        case appLaunch = "app_launch"
        case appBackground = "app_background"
        case appForeground = "app_foreground"
        case sessionStart = "session_start"
        case sessionEnd = "session_end"
        
        // Workouts
        case workoutStarted = "workout_started"
        case workoutCompleted = "workout_completed"
        case workoutPaused = "workout_paused"
        case workoutAbandoned = "workout_abandoned"
        case exerciseCompleted = "exercise_completed"
        case personalRecord = "personal_record"
        
        // Nutrition
        case mealLogged = "meal_logged"
        case waterLogged = "water_logged"
        case nutritionGoalMet = "nutrition_goal_met"
        case barcodeScan = "barcode_scan"
        case foodSearched = "food_searched"
        
        // Progress
        case weightLogged = "weight_logged"
        case progressPhotoTaken = "progress_photo_taken"
        case measurementsTaken = "measurements_taken"
        case goalCreated = "goal_created"
        case goalAchieved = "goal_achieved"
        
        // Social/Coaching
        case coachMessageSent = "coach_message_sent"
        case clientAssigned = "client_assigned"
        case workoutShared = "workout_shared"
        case achievementShared = "achievement_shared"
        
        // Subscription
        case subscriptionViewed = "subscription_viewed"
        case subscriptionPurchased = "subscription_purchased"
        case featureBlocked = "feature_blocked"
        case trialStarted = "trial_started"
        
        // Technical
        case syncCompleted = "sync_completed"
        case syncFailed = "sync_failed"
        case errorOccurred = "error_occurred"
        case crashDetected = "crash_detected"
        case performanceIssue = "performance_issue"
        
        // UI/UX
        case screenViewed = "screen_viewed"
        case buttonTapped = "button_tapped"
        case featureUsed = "feature_used"
        case onboardingCompleted = "onboarding_completed"
        case tutorialCompleted = "tutorial_completed"
    }
    
    // MARK: - Initialization
    private init() {
        loadUserPreferences()
        setupSessionTracking()
        setupCrashDetection()
    }
    
    private func loadUserPreferences() {
        isAnalyticsEnabled = UserDefaults.standard.bool(forKey: analyticsEnabledKey)
        isDataCollectionEnabled = UserDefaults.standard.bool(forKey: dataCollectionEnabledKey)
        
        // Enable by default for new users
        if !UserDefaults.standard.objectExists(forKey: analyticsEnabledKey) {
            isAnalyticsEnabled = true
            UserDefaults.standard.set(true, forKey: analyticsEnabledKey)
        }
        
        if !UserDefaults.standard.objectExists(forKey: dataCollectionEnabledKey) {
            isDataCollectionEnabled = true
            UserDefaults.standard.set(true, forKey: dataCollectionEnabledKey)
        }
    }
    
    private func setupSessionTracking() {
        // Track app lifecycle events
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.startSession()
                }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.endSession()
                }
            }
            .store(in: &cancellables)
        
        // Track user activity
        NotificationCenter.default.publisher(for: .userActivity)
            .sink { [weak self] _ in
                self?.updateActivityTime()
            }
            .store(in: &cancellables)
    }
    
    private func setupCrashDetection() {
        // Set up uncaught exception handler
        NSSetUncaughtExceptionHandler { exception in
            AnalyticsManager.shared.recordCrash(exception: exception)
        }
        
        // Check for previous crash on launch
        if let crashData = UserDefaults.standard.data(forKey: "pending_crash_report") {
            if let crashReport = try? JSONDecoder().decode(CrashReport.self, from: crashData) {
                Task {
                    await self.processCrashReport(crashReport)
                }
            }
            UserDefaults.standard.removeObject(forKey: "pending_crash_report")
        }
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Event Tracking
    
    /// Tracks an analytics event with optional parameters
    public func track(event: EventType, parameters: [String: Any] = [:]) {
        guard isAnalyticsEnabled else { return }
        
        var eventParameters = parameters
        eventParameters["timestamp"] = Date().timeIntervalSince1970
        eventParameters["session_id"] = getCurrentSessionId()
        eventParameters["user_id"] = getUserId()
        eventParameters["app_version"] = getAppVersion()
        eventParameters["platform"] = "iOS"
        
        let analyticsEvent = AnalyticsEvent(
            id: UUID().uuidString,
            type: event.rawValue,
            parameters: eventParameters,
            timestamp: Date()
        )
        
        queueEvent(analyticsEvent)
        
        logger.info("Tracked event: \(event.rawValue) with \(parameters.count) parameters")
    }
    
    /// Tracks screen views
    public func trackScreenView(_ screenName: String, previousScreen: String? = nil) {
        var parameters: [String: Any] = ["screen_name": screenName]
        if let previous = previousScreen {
            parameters["previous_screen"] = previous
        }
        
        track(event: .screenViewed, parameters: parameters)
    }
    
    /// Tracks user interactions
    public func trackInteraction(_ action: String, target: String, context: [String: Any] = [:]) {
        var parameters: [String: Any] = [
            "action": action,
            "target": target
        ]
        parameters.merge(context) { _, new in new }
        
        track(event: .buttonTapped, parameters: parameters)
    }
    
    /// Tracks workout metrics
    public func trackWorkout(type: String, duration: TimeInterval, caloriesBurned: Int, exerciseCount: Int) {
        let parameters: [String: Any] = [
            "workout_type": type,
            "duration_minutes": Int(duration / 60),
            "calories_burned": caloriesBurned,
            "exercise_count": exerciseCount,
            "completion_rate": 100.0 // Assuming completed since we're tracking it
        ]
        
        track(event: .workoutCompleted, parameters: parameters)
    }
    
    /// Tracks nutrition logging
    public func trackNutrition(mealType: String, calories: Double, foodCount: Int) {
        let parameters: [String: Any] = [
            "meal_type": mealType,
            "calories": calories,
            "food_count": foodCount
        ]
        
        track(event: .mealLogged, parameters: parameters)
    }
    
    /// Tracks progress updates
    public func trackProgress(type: String, value: Double, unit: String) {
        let parameters: [String: Any] = [
            "progress_type": type,
            "value": value,
            "unit": unit
        ]
        
        track(event: .weightLogged, parameters: parameters)
    }
    
    /// Tracks subscription events
    public func trackSubscription(event: String, productId: String?, price: Double? = nil) {
        var parameters: [String: Any] = ["subscription_event": event]
        if let productId = productId {
            parameters["product_id"] = productId
        }
        if let price = price {
            parameters["price"] = price
        }
        
        track(event: .subscriptionPurchased, parameters: parameters)
    }
    
    /// Tracks errors and exceptions
    public func trackError(_ error: Error, context: [String: Any] = [:]) {
        var parameters: [String: Any] = [
            "error_description": error.localizedDescription,
            "error_domain": (error as NSError).domain,
            "error_code": (error as NSError).code
        ]
        parameters.merge(context) { _, new in new }
        
        track(event: .errorOccurred, parameters: parameters)
    }
    
    // MARK: - Performance Monitoring
    
    /// Records performance metrics
    public func recordPerformance(operation: String, duration: TimeInterval, success: Bool) {
        let metric = PerformanceMetric(
            operation: operation,
            duration: duration,
            timestamp: Date(),
            success: success,
            memoryUsage: getCurrentMemoryUsage()
        )
        
        performanceMetrics.append(metric)
        
        // Track performance issues
        if duration > 5.0 { // Operations taking longer than 5 seconds
            track(event: .performanceIssue, parameters: [
                "operation": operation,
                "duration": duration,
                "memory_usage": metric.memoryUsage
            ])
        }
        
        // Keep only recent metrics
        if performanceMetrics.count > 1000 {
            performanceMetrics = Array(performanceMetrics.suffix(500))
        }
    }
    
    /// Measures execution time of a block
    public func measure<T>(operation: String, block: () throws -> T) rethrows -> T {
        let startTime = Date()
        var success = true
        
        do {
            let result = try block()
            return result
        } catch {
            success = false
            trackError(error, context: ["operation": operation])
            throw error
        }
        
        let duration = Date().timeIntervalSince(startTime)
        recordPerformance(operation: operation, duration: duration, success: success)
    }
    
    /// Async version of measure
    public func measure<T>(operation: String, block: () async throws -> T) async rethrows -> T {
        let startTime = Date()
        var success = true
        
        do {
            let result = try await block()
            return result
        } catch {
            success = false
            trackError(error, context: ["operation": operation])
            throw error
        }
        
        let duration = Date().timeIntervalSince(startTime)
        recordPerformance(operation: operation, duration: duration, success: success)
    }
    
    // MARK: - Session Management
    
    private func startSession() {
        sessionStartTime = Date()
        sessionMetrics.sessionCount += 1
        
        track(event: .sessionStart, parameters: [
            "session_count": sessionMetrics.sessionCount
        ])
    }
    
    private func endSession() {
        guard let startTime = sessionStartTime else { return }
        
        let duration = Date().timeIntervalSince(startTime)
        sessionMetrics.totalTime += duration
        sessionMetrics.averageSessionTime = sessionMetrics.totalTime / Double(sessionMetrics.sessionCount)
        
        track(event: .sessionEnd, parameters: [
            "session_duration": Int(duration),
            "total_sessions": sessionMetrics.sessionCount,
            "average_session_time": Int(sessionMetrics.averageSessionTime)
        ])
        
        sessionStartTime = nil
        
        // Upload queued events before app closes
        Task {
            await uploadQueuedEvents()
        }
    }
    
    private func updateActivityTime() {
        lastActivityTime = Date()
    }
    
    // MARK: - Crash Reporting
    
    private func recordCrash(exception: NSException) {
        let crashReport = CrashReport(
            id: UUID().uuidString,
            timestamp: Date(),
            exceptionName: exception.name.rawValue,
            reason: exception.reason ?? "Unknown",
            stackTrace: exception.callStackSymbols,
            appVersion: getAppVersion(),
            osVersion: UIDevice.current.systemVersion,
            deviceModel: UIDevice.current.model
        )
        
        // Store crash report to be sent on next launch
        if let crashData = try? JSONEncoder().encode(crashReport) {
            UserDefaults.standard.set(crashData, forKey: "pending_crash_report")
        }
    }
    
    private func processCrashReport(_ crashReport: CrashReport) async {
        track(event: .crashDetected, parameters: [
            "crash_id": crashReport.id,
            "exception_name": crashReport.exceptionName,
            "reason": crashReport.reason,
            "app_version": crashReport.appVersion,
            "os_version": crashReport.osVersion
        ])
        
        // Send to crash reporting service
        await uploadCrashReport(crashReport)
    }
    
    // MARK: - User Metrics
    
    /// Calculates user engagement metrics
    public func calculateEngagementMetrics() -> EngagementMetrics {
        let now = Date()
        let lastWeek = Calendar.current.date(byAdding: .day, value: -7, to: now) ?? now
        
        let recentEvents = eventQueue.filter { $0.timestamp >= lastWeek }
        
        let workoutEvents = recentEvents.filter { $0.type == EventType.workoutCompleted.rawValue }
        let nutritionEvents = recentEvents.filter { $0.type == EventType.mealLogged.rawValue }
        let screenViews = recentEvents.filter { $0.type == EventType.screenViewed.rawValue }
        
        return EngagementMetrics(
            dailyActiveUsers: sessionMetrics.sessionCount > 0 ? 1 : 0,
            averageSessionTime: sessionMetrics.averageSessionTime,
            workoutsPerWeek: workoutEvents.count,
            mealsLoggedPerWeek: nutritionEvents.count,
            screenViewsPerSession: Double(screenViews.count) / max(Double(sessionMetrics.sessionCount), 1.0),
            retentionRate: calculateRetentionRate()
        )
    }
    
    /// Calculates feature usage statistics
    public func calculateFeatureUsage() -> [String: Int] {
        var featureUsage: [String: Int] = [:]
        
        for event in eventQueue {
            featureUsage[event.type, default: 0] += 1
        }
        
        return featureUsage
    }
    
    /// Gets popular workout types
    public func getPopularWorkoutTypes() -> [String: Int] {
        var workoutTypes: [String: Int] = [:]
        
        let workoutEvents = eventQueue.filter { $0.type == EventType.workoutCompleted.rawValue }
        for event in workoutEvents {
            if let workoutType = event.parameters["workout_type"] as? String {
                workoutTypes[workoutType, default: 0] += 1
            }
        }
        
        return workoutTypes
    }
    
    // MARK: - Data Export and Privacy
    
    /// Exports user's analytics data for privacy compliance
    public func exportUserData() async -> AnalyticsExport {
        let export = AnalyticsExport(
            userId: getUserId(),
            exportDate: Date(),
            events: eventQueue,
            sessionMetrics: sessionMetrics,
            performanceMetrics: performanceMetrics,
            crashReports: crashReports
        )
        
        return export
    }
    
    /// Deletes all user analytics data
    public func deleteAllUserData() async {
        eventQueue.removeAll()
        performanceMetrics.removeAll()
        crashReports.removeAll()
        sessionMetrics = SessionMetrics()
        
        // Clear persisted data
        UserDefaults.standard.removeObject(forKey: "analytics_events")
        UserDefaults.standard.removeObject(forKey: "session_metrics")
        
        logger.info("All user analytics data deleted")
    }
    
    /// Updates user preferences for data collection
    public func updateDataCollectionPreference(analyticsEnabled: Bool, dataCollectionEnabled: Bool) {
        self.isAnalyticsEnabled = analyticsEnabled
        self.isDataCollectionEnabled = dataCollectionEnabled
        
        UserDefaults.standard.set(analyticsEnabled, forKey: analyticsEnabledKey)
        UserDefaults.standard.set(dataCollectionEnabled, forKey: dataCollectionEnabledKey)
        
        if !analyticsEnabled {
            // Clear existing data if user opts out
            Task {
                await deleteAllUserData()
            }
        }
        
        logger.info("Data collection preferences updated - Analytics: \(analyticsEnabled), Data Collection: \(dataCollectionEnabled)")
    }
    
    // MARK: - Event Queue Management
    
    private func queueEvent(_ event: AnalyticsEvent) {
        analyticsQueue.async {
            self.eventQueue.append(event)
            
            // Limit queue size
            if self.eventQueue.count > self.maxQueueSize {
                self.eventQueue.removeFirst(self.eventQueue.count - self.maxQueueSize)
            }
            
            // Auto-upload when batch size is reached
            if self.eventQueue.count >= self.batchUploadSize {
                Task {
                    await self.uploadQueuedEvents()
                }
            }
        }
    }
    
    private func uploadQueuedEvents() async {
        guard isDataCollectionEnabled, !eventQueue.isEmpty else { return }
        
        let eventsToUpload = Array(eventQueue.prefix(batchUploadSize))
        
        do {
            try await uploadEvents(eventsToUpload)
            
            // Remove successfully uploaded events
            analyticsQueue.async {
                self.eventQueue.removeFirst(min(eventsToUpload.count, self.eventQueue.count))
            }
            
            logger.info("Uploaded \(eventsToUpload.count) analytics events")
            
        } catch {
            logger.error("Failed to upload analytics events: \(error.localizedDescription)")
        }
    }
    
    private func uploadEvents(_ events: [AnalyticsEvent]) async throws {
        // Implementation would send events to your analytics backend
        // This is a placeholder for the actual upload logic
        
        guard let url = URL(string: "https://analytics.fitnesscoach.app/events") else {
            throw AnalyticsError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(getAPIKey(), forHTTPHeaderField: "Authorization")
        
        let payload = EventUploadPayload(
            events: events,
            userId: getUserId(),
            timestamp: Date().timeIntervalSince1970
        )
        
        request.httpBody = try JSONEncoder().encode(payload)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AnalyticsError.uploadFailed
        }
    }
    
    private func uploadCrashReport(_ crashReport: CrashReport) async {
        // Implementation would send crash report to your backend
        logger.info("Crash report uploaded: \(crashReport.id)")
    }
    
    // MARK: - Helper Methods
    
    private func getCurrentSessionId() -> String {
        return sessionStartTime?.timeIntervalSince1970.description ?? "no_session"
    }
    
    private func getUserId() -> String {
        if let userId = UserDefaults.standard.string(forKey: "analytics_user_id") {
            return userId
        }
        
        let newUserId = UUID().uuidString
        UserDefaults.standard.set(newUserId, forKey: "analytics_user_id")
        return newUserId
    }
    
    private func getAppVersion() -> String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
    }
    
    private func getAPIKey() -> String {
        // Return your analytics API key
        return "Bearer your-analytics-api-key"
    }
    
    private func getCurrentMemoryUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        guard result == KERN_SUCCESS else { return 0.0 }
        return Double(info.resident_size) / 1024 / 1024 // MB
    }
    
    private func calculateRetentionRate() -> Double {
        // Simplified retention calculation
        let totalSessions = sessionMetrics.sessionCount
        let recentSessions = eventQueue.filter { 
            $0.type == EventType.sessionStart.rawValue && 
            $0.timestamp >= Date().addingTimeInterval(-7 * 24 * 60 * 60) 
        }.count
        
        guard totalSessions > 0 else { return 0.0 }
        return Double(recentSessions) / Double(totalSessions)
    }
}

// MARK: - Supporting Types

public struct SessionMetrics: Codable {
    public var sessionCount: Int = 0
    public var totalTime: TimeInterval = 0
    public var averageSessionTime: TimeInterval = 0
    public var lastSessionDate: Date?
}

public struct AnalyticsEvent: Codable {
    public let id: String
    public let type: String
    public let parameters: [String: Any]
    public let timestamp: Date
    
    private enum CodingKeys: String, CodingKey {
        case id, type, timestamp
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        type = try container.decode(String.self, forKey: .type)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        parameters = [:] // Parameters would need custom decoding
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(type, forKey: .type)
        try container.encode(timestamp, forKey: .timestamp)
        // Parameters would need custom encoding
    }
    
    public init(id: String, type: String, parameters: [String: Any], timestamp: Date) {
        self.id = id
        self.type = type
        self.parameters = parameters
        self.timestamp = timestamp
    }
}

public struct PerformanceMetric: Codable {
    public let operation: String
    public let duration: TimeInterval
    public let timestamp: Date
    public let success: Bool
    public let memoryUsage: Double
}

public struct CrashReport: Codable {
    public let id: String
    public let timestamp: Date
    public let exceptionName: String
    public let reason: String
    public let stackTrace: [String]
    public let appVersion: String
    public let osVersion: String
    public let deviceModel: String
}

public struct EngagementMetrics {
    public let dailyActiveUsers: Int
    public let averageSessionTime: TimeInterval
    public let workoutsPerWeek: Int
    public let mealsLoggedPerWeek: Int
    public let screenViewsPerSession: Double
    public let retentionRate: Double
}

public struct AnalyticsExport: Codable {
    public let userId: String
    public let exportDate: Date
    public let events: [AnalyticsEvent]
    public let sessionMetrics: SessionMetrics
    public let performanceMetrics: [PerformanceMetric]
    public let crashReports: [CrashReport]
}

private struct EventUploadPayload: Codable {
    let events: [AnalyticsEvent]
    let userId: String
    let timestamp: TimeInterval
}

public enum AnalyticsError: LocalizedError {
    case invalidURL
    case uploadFailed
    case encodingError
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid analytics URL"
        case .uploadFailed: return "Failed to upload analytics data"
        case .encodingError: return "Failed to encode analytics data"
        }
    }
}

// MARK: - UserDefaults Extension

extension UserDefaults {
    func objectExists(forKey key: String) -> Bool {
        return object(forKey: key) != nil
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let userActivity = Notification.Name("userActivity")
}