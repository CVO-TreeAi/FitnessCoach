import Foundation
import UserNotifications
import Combine
import OSLog

/// Comprehensive push notification management for fitness coaching app
@MainActor
public final class NotificationManager: NSObject, ObservableObject {
    
    static let shared = NotificationManager()
    
    // MARK: - Properties
    private let logger = Logger(subsystem: "FitnessCoach", category: "NotificationManager")
    
    @Published public var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published public var isEnabled: Bool = false
    @Published public var pendingNotifications: [UNNotificationRequest] = []
    
    private let center = UNUserNotificationCenter.current()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Notification Categories
    public enum NotificationCategory: String, CaseIterable {
        case workoutReminder = "WORKOUT_REMINDER"
        case workoutMotivation = "WORKOUT_MOTIVATION"
        case workoutCompleted = "WORKOUT_COMPLETED"
        case nutritionReminder = "NUTRITION_REMINDER"
        case nutritionGoal = "NUTRITION_GOAL"
        case progressUpdate = "PROGRESS_UPDATE"
        case goalAchievement = "GOAL_ACHIEVEMENT"
        case coachMessage = "COACH_MESSAGE"
        case clientUpdate = "CLIENT_UPDATE"
        case habitReminder = "HABIT_REMINDER"
        case restDayReminder = "REST_DAY"
        case hydrationReminder = "HYDRATION_REMINDER"
        case sleepReminder = "SLEEP_REMINDER"
        case weeklyReport = "WEEKLY_REPORT"
        case streakCelebration = "STREAK_CELEBRATION"
        
        var displayName: String {
            switch self {
            case .workoutReminder: return "Workout Reminders"
            case .workoutMotivation: return "Workout Motivation"
            case .workoutCompleted: return "Workout Completion"
            case .nutritionReminder: return "Nutrition Reminders"
            case .nutritionGoal: return "Nutrition Goals"
            case .progressUpdate: return "Progress Updates"
            case .goalAchievement: return "Goal Achievements"
            case .coachMessage: return "Coach Messages"
            case .clientUpdate: return "Client Updates"
            case .habitReminder: return "Habit Reminders"
            case .restDayReminder: return "Rest Day Reminders"
            case .hydrationReminder: return "Hydration Reminders"
            case .sleepReminder: return "Sleep Reminders"
            case .weeklyReport: return "Weekly Reports"
            case .streakCelebration: return "Streak Celebrations"
            }
        }
        
        var actions: [UNNotificationAction] {
            switch self {
            case .workoutReminder:
                return [
                    UNNotificationAction(identifier: "START_WORKOUT", title: "Start Workout", options: [.foreground]),
                    UNNotificationAction(identifier: "SNOOZE_WORKOUT", title: "Snooze 30min", options: []),
                    UNNotificationAction(identifier: "SKIP_WORKOUT", title: "Skip Today", options: [.destructive])
                ]
            case .workoutCompleted:
                return [
                    UNNotificationAction(identifier: "VIEW_WORKOUT", title: "View Details", options: [.foreground]),
                    UNNotificationAction(identifier: "SHARE_WORKOUT", title: "Share", options: [.foreground])
                ]
            case .nutritionReminder:
                return [
                    UNNotificationAction(identifier: "LOG_MEAL", title: "Log Meal", options: [.foreground]),
                    UNNotificationAction(identifier: "SKIP_MEAL", title: "Skip", options: [])
                ]
            case .coachMessage:
                return [
                    UNNotificationAction(identifier: "REPLY_COACH", title: "Reply", options: [.foreground]),
                    UNNotificationAction(identifier: "VIEW_MESSAGE", title: "View", options: [.foreground])
                ]
            case .goalAchievement:
                return [
                    UNNotificationAction(identifier: "SHARE_ACHIEVEMENT", title: "Share", options: [.foreground]),
                    UNNotificationAction(identifier: "SET_NEW_GOAL", title: "Set New Goal", options: [.foreground])
                ]
            default:
                return []
            }
        }
    }
    
    // MARK: - Initialization
    override private init() {
        super.init()
        center.delegate = self
        setupNotificationCategories()
        checkAuthorizationStatus()
    }
    
    // MARK: - Setup
    
    private func setupNotificationCategories() {
        let categories = NotificationCategory.allCases.map { category in
            UNNotificationCategory(
                identifier: category.rawValue,
                actions: category.actions,
                intentIdentifiers: [],
                options: [.customDismissAction]
            )
        }
        
        center.setNotificationCategories(Set(categories))
        logger.info("Notification categories configured: \(categories.count)")
    }
    
    private func checkAuthorizationStatus() {
        center.getNotificationSettings { settings in
            Task { @MainActor in
                self.authorizationStatus = settings.authorizationStatus
                self.isEnabled = settings.authorizationStatus == .authorized
            }
        }
    }
    
    // MARK: - Authorization
    
    /// Requests notification permissions from user
    public func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound, .provisional, .criticalAlert])
            
            await MainActor.run {
                self.isEnabled = granted
                self.authorizationStatus = granted ? .authorized : .denied
            }
            
            if granted {
                logger.info("Notification authorization granted")
            } else {
                logger.warning("Notification authorization denied")
            }
            
            return granted
            
        } catch {
            logger.error("Failed to request notification authorization: \(error.localizedDescription)")
            return false
        }
    }
    
    /// Opens system settings for notification permissions
    public func openNotificationSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    // MARK: - Workout Notifications
    
    /// Schedules workout reminder notification
    public func scheduleWorkoutReminder(workoutName: String, scheduledDate: Date, workoutId: String) async throws {
        let content = UNMutableNotificationContent()
        content.title = "Time to Workout! 💪"
        content.body = "Your \(workoutName) is scheduled now. Let's crush it!"
        content.categoryIdentifier = NotificationCategory.workoutReminder.rawValue
        content.sound = .default
        content.badge = 1
        
        // Add workout ID to user info for handling
        content.userInfo = [
            "workoutId": workoutId,
            "type": "workout_reminder"
        ]
        
        // Schedule 15 minutes before
        let reminderDate = scheduledDate.addingTimeInterval(-15 * 60)
        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "workout-reminder-\(workoutId)",
            content: content,
            trigger: trigger
        )
        
        try await center.add(request)
        logger.info("Scheduled workout reminder for: \(workoutName)")
    }
    
    /// Sends workout motivation notification
    public func sendWorkoutMotivation(message: String? = nil) async throws {
        let motivationalMessages = [
            "Your only competition is who you were yesterday! 🔥",
            "Champions train, losers complain. Which one are you? 💪",
            "The pain you feel today will be the strength you feel tomorrow! ⚡",
            "Don't stop when you're tired, stop when you're done! 🏆",
            "Your body can stand almost anything. It's your mind you have to convince! 🧠",
            "Success starts with self-discipline! 🎯"
        ]
        
        let content = UNMutableNotificationContent()
        content.title = "Motivation Boost! 🚀"
        content.body = message ?? motivationalMessages.randomElement() ?? "Time to get moving!"
        content.categoryIdentifier = NotificationCategory.workoutMotivation.rawValue
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "motivation-\(UUID().uuidString)",
            content: content,
            trigger: nil // Show immediately
        )
        
        try await center.add(request)
        logger.info("Sent workout motivation notification")
    }
    
    /// Celebrates workout completion
    public func celebrateWorkoutCompletion(workoutName: String, duration: Int, calories: Int) async throws {
        let content = UNMutableNotificationContent()
        content.title = "Workout Complete! 🎉"
        content.body = "Amazing! You finished \(workoutName) in \(duration) minutes and burned \(calories) calories!"
        content.categoryIdentifier = NotificationCategory.workoutCompleted.rawValue
        content.sound = .default
        
        content.userInfo = [
            "type": "workout_completed",
            "duration": duration,
            "calories": calories
        ]
        
        let request = UNNotificationRequest(
            identifier: "workout-completed-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        
        try await center.add(request)
        logger.info("Sent workout completion celebration")
    }
    
    // MARK: - Nutrition Notifications
    
    /// Schedules daily nutrition reminders
    public func scheduleDailyNutritionReminders() async throws {
        let mealTimes = [
            (hour: 8, minute: 0, meal: "breakfast"),
            (hour: 12, minute: 30, meal: "lunch"),
            (hour: 18, minute: 0, meal: "dinner")
        ]
        
        for (hour, minute, meal) in mealTimes {
            let content = UNMutableNotificationContent()
            content.title = "Meal Time! 🍽️"
            content.body = "Time to fuel your body with a healthy \(meal). Don't forget to log it!"
            content.categoryIdentifier = NotificationCategory.nutritionReminder.rawValue
            content.sound = .default
            
            content.userInfo = [
                "type": "nutrition_reminder",
                "meal": meal
            ]
            
            var components = DateComponents()
            components.hour = hour
            components.minute = minute
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            
            let request = UNNotificationRequest(
                identifier: "nutrition-\(meal)-daily",
                content: content,
                trigger: trigger
            )
            
            try await center.add(request)
        }
        
        logger.info("Scheduled daily nutrition reminders")
    }
    
    /// Sends nutrition goal achievement notification
    public func celebrateNutritionGoal(goalType: String, targetValue: Double, unit: String) async throws {
        let content = UNMutableNotificationContent()
        content.title = "Nutrition Goal Achieved! 🥗"
        content.body = "Fantastic! You've reached your \(goalType) goal of \(Int(targetValue)) \(unit) today!"
        content.categoryIdentifier = NotificationCategory.nutritionGoal.rawValue
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "nutrition-goal-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        
        try await center.add(request)
        logger.info("Sent nutrition goal achievement notification")
    }
    
    // MARK: - Progress & Goal Notifications
    
    /// Sends weekly progress update
    public func sendWeeklyProgressUpdate(workoutsCompleted: Int, caloriesBurned: Int, weightChange: Double?) async throws {
        let content = UNMutableNotificationContent()
        content.title = "Your Weekly Progress! 📊"
        
        var body = "This week: \(workoutsCompleted) workouts completed, \(caloriesBurned) calories burned"
        if let weightChange = weightChange {
            let changeDirection = weightChange >= 0 ? "gained" : "lost"
            body += ", \(abs(weightChange)) lbs \(changeDirection)"
        }
        body += ". Keep up the great work!"
        
        content.body = body
        content.categoryIdentifier = NotificationCategory.weeklyReport.rawValue
        content.sound = .default
        
        content.userInfo = [
            "type": "weekly_progress",
            "workouts": workoutsCompleted,
            "calories": caloriesBurned
        ]
        
        let request = UNNotificationRequest(
            identifier: "weekly-progress-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )
        
        try await center.add(request)
        logger.info("Sent weekly progress update")
    }
    
    /// Celebrates goal achievement
    public func celebrateGoalAchievement(goalTitle: String, goalCategory: String) async throws {
        let content = UNMutableNotificationContent()
        content.title = "🎯 Goal Achieved!"
        content.body = "Incredible! You've completed your \(goalCategory) goal: \(goalTitle). Time to set a new challenge!"
        content.categoryIdentifier = NotificationCategory.goalAchievement.rawValue
        content.sound = .default
        content.badge = 1
        
        content.userInfo = [
            "type": "goal_achievement",
            "goalTitle": goalTitle,
            "category": goalCategory
        ]
        
        let request = UNNotificationRequest(
            identifier: "goal-achieved-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        
        try await center.add(request)
        logger.info("Sent goal achievement celebration")
    }
    
    // MARK: - Coach-Client Notifications
    
    /// Sends coach message notification to client
    public func sendCoachMessage(fromCoach: String, message: String, coachId: String) async throws {
        let content = UNMutableNotificationContent()
        content.title = "Message from \(fromCoach) 👨‍🏫"
        content.body = message
        content.categoryIdentifier = NotificationCategory.coachMessage.rawValue
        content.sound = .default
        content.badge = 1
        
        content.userInfo = [
            "type": "coach_message",
            "coachId": coachId,
            "message": message
        ]
        
        let request = UNNotificationRequest(
            identifier: "coach-message-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        
        try await center.add(request)
        logger.info("Sent coach message notification")
    }
    
    /// Sends client update notification to coach
    public func sendClientUpdate(fromClient: String, updateType: String, clientId: String) async throws {
        let content = UNMutableNotificationContent()
        content.title = "Update from \(fromClient) 👤"
        content.body = "Your client has a new \(updateType) update to review."
        content.categoryIdentifier = NotificationCategory.clientUpdate.rawValue
        content.sound = .default
        content.badge = 1
        
        content.userInfo = [
            "type": "client_update",
            "clientId": clientId,
            "updateType": updateType
        ]
        
        let request = UNNotificationRequest(
            identifier: "client-update-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        
        try await center.add(request)
        logger.info("Sent client update notification")
    }
    
    // MARK: - Habit & Lifestyle Notifications
    
    /// Schedules hydration reminders
    public func scheduleHydrationReminders() async throws {
        // Every 2 hours from 8 AM to 8 PM
        let hours = [8, 10, 12, 14, 16, 18, 20]
        
        for hour in hours {
            let content = UNMutableNotificationContent()
            content.title = "Stay Hydrated! 💧"
            content.body = "Time for some water! Your body needs hydration to perform at its best."
            content.categoryIdentifier = NotificationCategory.hydrationReminder.rawValue
            content.sound = .default
            
            var components = DateComponents()
            components.hour = hour
            components.minute = 0
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            
            let request = UNNotificationRequest(
                identifier: "hydration-\(hour)",
                content: content,
                trigger: trigger
            )
            
            try await center.add(request)
        }
        
        logger.info("Scheduled hydration reminders")
    }
    
    /// Schedules sleep reminder
    public func scheduleSleepReminder(bedtime: Date) async throws {
        let content = UNMutableNotificationContent()
        content.title = "Wind Down Time 🌙"
        content.body = "Consider starting your bedtime routine. Good sleep is crucial for recovery!"
        content.categoryIdentifier = NotificationCategory.sleepReminder.rawValue
        content.sound = .default
        
        // 30 minutes before bedtime
        let reminderTime = bedtime.addingTimeInterval(-30 * 60)
        let triggerDate = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "sleep-reminder-daily",
            content: content,
            trigger: trigger
        )
        
        try await center.add(request)
        logger.info("Scheduled sleep reminder for: \(bedtime)")
    }
    
    /// Celebrates workout streak
    public func celebrateWorkoutStreak(streakDays: Int) async throws {
        let content = UNMutableNotificationContent()
        content.title = "🔥 Streak Alert!"
        content.body = "Amazing! You're on a \(streakDays)-day workout streak! Don't break it now!"
        content.categoryIdentifier = NotificationCategory.streakCelebration.rawValue
        content.sound = .default
        
        content.userInfo = [
            "type": "streak_celebration",
            "streakDays": streakDays
        ]
        
        let request = UNNotificationRequest(
            identifier: "streak-\(streakDays)-days",
            content: content,
            trigger: nil
        )
        
        try await center.add(request)
        logger.info("Sent workout streak celebration: \(streakDays) days")
    }
    
    // MARK: - Notification Management
    
    /// Gets all pending notifications
    public func getPendingNotifications() async {
        let requests = await center.pendingNotificationRequests()
        
        await MainActor.run {
            self.pendingNotifications = requests
        }
    }
    
    /// Cancels specific notification
    public func cancelNotification(identifier: String) {
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        logger.info("Cancelled notification: \(identifier)")
    }
    
    /// Cancels all notifications of a category
    public func cancelNotifications(category: NotificationCategory) async {
        let requests = await center.pendingNotificationRequests()
        let identifiers = requests
            .filter { $0.content.categoryIdentifier == category.rawValue }
            .map { $0.identifier }
        
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        logger.info("Cancelled \(identifiers.count) notifications for category: \(category.rawValue)")
    }
    
    /// Cancels all pending notifications
    public func cancelAllNotifications() {
        center.removeAllPendingNotificationRequests()
        logger.info("Cancelled all pending notifications")
    }
    
    /// Clears delivered notifications
    public func clearDeliveredNotifications() {
        center.removeAllDeliveredNotifications()
        // Reset badge count
        UIApplication.shared.applicationIconBadgeNumber = 0
        logger.info("Cleared all delivered notifications")
    }
    
    // MARK: - Smart Notifications
    
    /// Sends contextual motivation based on user behavior
    public func sendContextualMotivation(context: MotivationContext) async throws {
        let message: String
        let title: String
        
        switch context {
        case .missedWorkout(let days):
            title = "We Miss You! 💪"
            message = "It's been \(days) days since your last workout. Ready to get back on track?"
            
        case .lowActivity:
            title = "Let's Move! 🚶‍♂️"
            message = "Your activity has been low today. Even a quick walk can make a difference!"
            
        case .plateauWeight:
            title = "Keep Going! 📈"
            message = "Weight plateaus are normal. Stay consistent and trust the process!"
            
        case .streakRisk(let currentStreak):
            title = "Don't Break the Streak! 🔥"
            message = "You're on a \(currentStreak)-day streak. One workout today keeps it alive!"
            
        case .weekendMotivation:
            title = "Weekend Warrior! 🏋️‍♀️"
            message = "Weekends are perfect for trying new workouts. What's your adventure today?"
        }
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.categoryIdentifier = NotificationCategory.workoutMotivation.rawValue
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "contextual-motivation-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        
        try await center.add(request)
        logger.info("Sent contextual motivation: \(context)")
    }
    
    // MARK: - Notification Analytics
    
    /// Tracks notification interaction
    public func trackNotificationInteraction(identifier: String, action: String) {
        logger.info("Notification interaction - ID: \(identifier), Action: \(action)")
        
        // Send to analytics
        let parameters = [
            "notification_id": identifier,
            "action": action,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        // AnalyticsManager.shared.track(event: "notification_interaction", parameters: parameters)
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationManager: UNUserNotificationCenterDelegate {
    
    /// Called when notification is received while app is in foreground
    public func userNotificationCenter(_ center: UNUserNotificationCenter, 
                                      willPresent notification: UNNotification, 
                                      withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        logger.info("Will present notification: \(notification.request.identifier)")
        
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    /// Called when user interacts with notification
    public func userNotificationCenter(_ center: UNUserNotificationCenter, 
                                      didReceive response: UNNotificationResponse, 
                                      withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let identifier = response.notification.request.identifier
        let actionIdentifier = response.actionIdentifier
        
        logger.info("Did receive notification response - ID: \(identifier), Action: \(actionIdentifier)")
        
        trackNotificationInteraction(identifier: identifier, action: actionIdentifier)
        
        // Handle different actions
        handleNotificationAction(response: response)
        
        completionHandler()
    }
    
    private func handleNotificationAction(response: UNNotificationResponse) {
        let userInfo = response.notification.request.content.userInfo
        let actionIdentifier = response.actionIdentifier
        
        switch actionIdentifier {
        case "START_WORKOUT":
            handleStartWorkout(userInfo: userInfo)
            
        case "SNOOZE_WORKOUT":
            handleSnoozeWorkout(identifier: response.notification.request.identifier)
            
        case "LOG_MEAL":
            handleLogMeal(userInfo: userInfo)
            
        case "SHARE_ACHIEVEMENT":
            handleShareAchievement(userInfo: userInfo)
            
        case "VIEW_WORKOUT", "VIEW_MESSAGE":
            handleViewContent(userInfo: userInfo)
            
        case UNNotificationDefaultActionIdentifier:
            // User tapped the notification (not an action button)
            handleDefaultAction(userInfo: userInfo)
            
        case UNNotificationDismissActionIdentifier:
            // User dismissed the notification
            logger.info("Notification dismissed")
            
        default:
            logger.warning("Unknown notification action: \(actionIdentifier)")
        }
    }
    
    private func handleStartWorkout(userInfo: [AnyHashable: Any]) {
        if let workoutId = userInfo["workoutId"] as? String {
            // Navigate to workout screen
            NotificationCenter.default.post(name: .startWorkout, object: workoutId)
        }
    }
    
    private func handleSnoozeWorkout(identifier: String) {
        Task {
            // Reschedule notification for 30 minutes later
            let snoozeDate = Date().addingTimeInterval(30 * 60)
            // Implementation would reschedule the specific workout reminder
            logger.info("Snoozed workout notification until: \(snoozeDate)")
        }
    }
    
    private func handleLogMeal(userInfo: [AnyHashable: Any]) {
        if let meal = userInfo["meal"] as? String {
            // Navigate to meal logging screen
            NotificationCenter.default.post(name: .logMeal, object: meal)
        }
    }
    
    private func handleShareAchievement(userInfo: [AnyHashable: Any]) {
        // Navigate to sharing screen
        NotificationCenter.default.post(name: .shareAchievement, object: userInfo)
    }
    
    private func handleViewContent(userInfo: [AnyHashable: Any]) {
        // Navigate to appropriate content screen
        NotificationCenter.default.post(name: .viewNotificationContent, object: userInfo)
    }
    
    private func handleDefaultAction(userInfo: [AnyHashable: Any]) {
        guard let type = userInfo["type"] as? String else { return }
        
        switch type {
        case "workout_reminder":
            handleStartWorkout(userInfo: userInfo)
        case "coach_message":
            handleViewContent(userInfo: userInfo)
        case "goal_achievement":
            handleViewContent(userInfo: userInfo)
        default:
            // Default behavior - open app
            logger.info("Opening app from notification")
        }
    }
}

// MARK: - Supporting Types

public enum MotivationContext {
    case missedWorkout(days: Int)
    case lowActivity
    case plateauWeight
    case streakRisk(currentStreak: Int)
    case weekendMotivation
}

// MARK: - Notification Names for Navigation

extension Notification.Name {
    static let startWorkout = Notification.Name("startWorkout")
    static let logMeal = Notification.Name("logMeal")
    static let shareAchievement = Notification.Name("shareAchievement")
    static let viewNotificationContent = Notification.Name("viewNotificationContent")
}