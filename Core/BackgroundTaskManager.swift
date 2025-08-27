import Foundation
import BackgroundTasks
import HealthKit
import OSLog

/// Comprehensive background task management for health data sync, CloudKit sync, and maintenance
public final class BackgroundTaskManager: ObservableObject {
    
    static let shared = BackgroundTaskManager()
    
    // MARK: - Properties
    private let logger = Logger(subsystem: "FitnessCoach", category: "BackgroundTaskManager")
    
    @Published public var isBackgroundRefreshEnabled: Bool = false
    @Published public var lastBackgroundSync: Date?
    @Published public var backgroundSyncStatus: BackgroundSyncStatus = .idle
    
    // Background task identifiers - these must match Info.plist entries
    private let backgroundSyncTaskID = "com.fitnesscoach.background-sync"
    private let healthDataSyncTaskID = "com.fitnesscoach.health-sync"
    private let maintenanceTaskID = "com.fitnesscoach.maintenance"
    private let notificationTaskID = "com.fitnesscoach.notifications"
    
    // Managers
    private let cloudKitManager = CloudKitManager.shared
    private let healthKitManager = HealthKitManager.shared
    private let subscriptionValidator = SubscriptionValidator()
    
    // Task scheduling
    private var scheduledTasks: Set<String> = []
    
    // MARK: - Background Sync Status
    public enum BackgroundSyncStatus {
        case idle
        case syncing(task: String)
        case completed(Date)
        case failed(Error)
    }
    
    // MARK: - Initialization
    private init() {
        setupBackgroundTasks()
        checkBackgroundRefreshStatus()
    }
    
    // MARK: - Setup
    
    /// Registers all background task handlers
    private func setupBackgroundTasks() {
        logger.info("Setting up background task handlers")
        
        // Main background sync task
        BGTaskScheduler.shared.register(forTaskWithIdentifier: backgroundSyncTaskID, using: nil) { task in
            self.handleBackgroundSync(task as! BGAppRefreshTask)
        }
        
        // Health data sync task
        BGTaskScheduler.shared.register(forTaskWithIdentifier: healthDataSyncTaskID, using: nil) { task in
            self.handleHealthDataSync(task as! BGProcessingTask)
        }
        
        // Maintenance task
        BGTaskScheduler.shared.register(forTaskWithIdentifier: maintenanceTaskID, using: nil) { task in
            self.handleMaintenanceTask(task as! BGProcessingTask)
        }
        
        // Notification scheduling task
        BGTaskScheduler.shared.register(forTaskWithIdentifier: notificationTaskID, using: nil) { task in
            self.handleNotificationTask(task as! BGAppRefreshTask)
        }
    }
    
    private func checkBackgroundRefreshStatus() {
        Task {
            let status = await UIApplication.shared.backgroundRefreshStatus
            
            await MainActor.run {
                self.isBackgroundRefreshEnabled = (status == .available)
            }
            
            if status != .available {
                logger.warning("Background refresh is not available: \(status.rawValue)")
            }
        }
    }
    
    // MARK: - Task Scheduling
    
    /// Schedules all necessary background tasks
    public func scheduleAllBackgroundTasks() {
        logger.info("Scheduling all background tasks")
        
        scheduleBackgroundSync()
        scheduleHealthDataSync()
        scheduleMaintenanceTask()
        scheduleNotificationTask()
    }
    
    /// Schedules the main background sync task (runs every 4 hours)
    private func scheduleBackgroundSync() {
        let request = BGAppRefreshTaskRequest(identifier: backgroundSyncTaskID)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 4 * 60 * 60) // 4 hours
        
        do {
            try BGTaskScheduler.shared.submit(request)
            scheduledTasks.insert(backgroundSyncTaskID)
            logger.info("Scheduled background sync task")
        } catch {
            logger.error("Failed to schedule background sync: \(error.localizedDescription)")
        }
    }
    
    /// Schedules health data sync task (runs daily at optimal times)
    private func scheduleHealthDataSync() {
        let request = BGProcessingTaskRequest(identifier: healthDataSyncTaskID)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 2 * 60 * 60) // 2 hours
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = false
        
        do {
            try BGTaskScheduler.shared.submit(request)
            scheduledTasks.insert(healthDataSyncTaskID)
            logger.info("Scheduled health data sync task")
        } catch {
            logger.error("Failed to schedule health data sync: \(error.localizedDescription)")
        }
    }
    
    /// Schedules maintenance task (runs weekly)
    private func scheduleMaintenanceTask() {
        let request = BGProcessingTaskRequest(identifier: maintenanceTaskID)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 24 * 60 * 60) // 24 hours
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = true
        
        do {
            try BGTaskScheduler.shared.submit(request)
            scheduledTasks.insert(maintenanceTaskID)
            logger.info("Scheduled maintenance task")
        } catch {
            logger.error("Failed to schedule maintenance task: \(error.localizedDescription)")
        }
    }
    
    /// Schedules notification task (runs every 2 hours)
    private func scheduleNotificationTask() {
        let request = BGAppRefreshTaskRequest(identifier: notificationTaskID)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 2 * 60 * 60) // 2 hours
        
        do {
            try BGTaskScheduler.shared.submit(request)
            scheduledTasks.insert(notificationTaskID)
            logger.info("Scheduled notification task")
        } catch {
            logger.error("Failed to schedule notification task: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Task Handlers
    
    /// Handles background sync task
    private func handleBackgroundSync(_ task: BGAppRefreshTask) {
        logger.info("Handling background sync task")
        
        Task {
            await MainActor.run {
                self.backgroundSyncStatus = .syncing(task: "Background Sync")
            }
            
            let startTime = Date()
            var success = false
            
            do {
                // Perform incremental CloudKit sync
                try await cloudKitManager.performIncrementalSync()
                
                // Validate subscription status
                _ = await subscriptionValidator.validateSubscription()
                
                success = true
                
                await MainActor.run {
                    self.lastBackgroundSync = startTime
                    self.backgroundSyncStatus = .completed(startTime)
                }
                
                logger.info("Background sync completed successfully")
                
            } catch {
                await MainActor.run {
                    self.backgroundSyncStatus = .failed(error)
                }
                logger.error("Background sync failed: \(error.localizedDescription)")
            }
            
            // Schedule next sync
            scheduleBackgroundSync()
            
            // Complete the task
            task.setTaskCompleted(success: success)
        }
    }
    
    /// Handles health data sync task
    private func handleHealthDataSync(_ task: BGProcessingTask) {
        logger.info("Handling health data sync task")
        
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
        
        Task {
            await MainActor.run {
                self.backgroundSyncStatus = .syncing(task: "Health Data Sync")
            }
            
            var success = false
            
            do {
                // Sync recent health data
                try await syncRecentHealthData()
                
                // Update workout metrics
                try await updateWorkoutMetrics()
                
                // Sync progress data
                try await syncProgressData()
                
                success = true
                logger.info("Health data sync completed successfully")
                
            } catch {
                logger.error("Health data sync failed: \(error.localizedDescription)")
            }
            
            // Schedule next health data sync
            scheduleHealthDataSync()
            
            // Complete the task
            task.setTaskCompleted(success: success)
        }
    }
    
    /// Handles maintenance task
    private func handleMaintenanceTask(_ task: BGProcessingTask) {
        logger.info("Handling maintenance task")
        
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
        
        Task {
            await MainActor.run {
                self.backgroundSyncStatus = .syncing(task: "Maintenance")
            }
            
            var success = false
            
            do {
                // Clean up old data
                try await performDataCleanup()
                
                // Optimize database
                try await optimizeDatabase()
                
                // Update analytics
                try await updateAnalytics()
                
                // Check for app updates
                await checkForAppUpdates()
                
                success = true
                logger.info("Maintenance task completed successfully")
                
            } catch {
                logger.error("Maintenance task failed: \(error.localizedDescription)")
            }
            
            // Schedule next maintenance
            scheduleMaintenanceTask()
            
            // Complete the task
            task.setTaskCompleted(success: success)
        }
    }
    
    /// Handles notification scheduling task
    private func handleNotificationTask(_ task: BGAppRefreshTask) {
        logger.info("Handling notification task")
        
        Task {
            do {
                // Schedule workout reminders
                try await scheduleWorkoutReminders()
                
                // Schedule nutrition reminders
                try await scheduleNutritionReminders()
                
                // Check goal progress and schedule celebrations
                try await checkGoalProgress()
                
                logger.info("Notification task completed successfully")
                
            } catch {
                logger.error("Notification task failed: \(error.localizedDescription)")
            }
            
            // Schedule next notification task
            scheduleNotificationTask()
            
            // Complete the task
            task.setTaskCompleted(success: true)
        }
    }
    
    // MARK: - Specific Sync Operations
    
    private func syncRecentHealthData() async throws {
        logger.info("Syncing recent health data")
        
        // Sync data from the last 7 days
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: endDate) ?? endDate
        
        // Sync workout data
        if let workouts = try await healthKitManager.fetchWorkouts(from: startDate, to: endDate) {
            for workout in workouts {
                try await processHealthKitWorkout(workout)
            }
        }
        
        // Sync body measurements
        try await syncBodyMeasurements(from: startDate, to: endDate)
        
        // Sync nutrition data if available
        try await syncNutritionData(from: startDate, to: endDate)
    }
    
    private func updateWorkoutMetrics() async throws {
        logger.info("Updating workout metrics")
        
        // Calculate weekly workout frequency
        let weeklyFrequency = try await calculateWeeklyWorkoutFrequency()
        
        // Update personal records
        try await updatePersonalRecords()
        
        // Calculate calorie burn trends
        try await updateCalorieBurnTrends()
        
        logger.info("Workout metrics updated - Weekly frequency: \(weeklyFrequency)")
    }
    
    private func syncProgressData() async throws {
        logger.info("Syncing progress data")
        
        // Sync weight data
        try await syncWeightData()
        
        // Sync body composition data
        try await syncBodyCompositionData()
        
        // Update progress photos metadata
        try await updateProgressPhotosMetadata()
    }
    
    // MARK: - Maintenance Operations
    
    private func performDataCleanup() async throws {
        logger.info("Performing data cleanup")
        
        let context = CoreDataManager.shared.context
        
        await context.perform {
            do {
                // Delete old temporary workout sessions
                let oldSessionsRequest = WorkoutSession.fetchRequest()
                oldSessionsRequest.predicate = NSPredicate(
                    format: "status == %@ AND startTime < %@",
                    "in_progress",
                    Date().addingTimeInterval(-7 * 24 * 60 * 60) as NSDate // 7 days ago
                )
                
                let oldSessions = try context.fetch(oldSessionsRequest)
                for session in oldSessions {
                    context.delete(session)
                }
                
                // Delete old failed sync records
                // Implementation depends on your sync failure tracking
                
                try context.save()
                
                self.logger.info("Data cleanup completed - deleted \(oldSessions.count) old sessions")
                
            } catch {
                self.logger.error("Data cleanup failed: \(error.localizedDescription)")
                throw error
            }
        }
    }
    
    private func optimizeDatabase() async throws {
        logger.info("Optimizing database")
        
        // Perform Core Data maintenance
        let context = CoreDataManager.shared.context
        
        await context.perform {
            // Reset context to clear any cached objects
            context.reset()
            
            // Force save to ensure all changes are written
            if context.hasChanges {
                try? context.save()
            }
        }
        
        // Could also implement SQLite VACUUM if needed
        logger.info("Database optimization completed")
    }
    
    private func updateAnalytics() async throws {
        logger.info("Updating analytics")
        
        // Update usage statistics
        let dailyActiveUsers = try await calculateDailyActiveUsers()
        let workoutCompletionRate = try await calculateWorkoutCompletionRate()
        
        // Store analytics locally (could also sync to server)
        UserDefaults.standard.set(dailyActiveUsers, forKey: "analytics_dau")
        UserDefaults.standard.set(workoutCompletionRate, forKey: "analytics_workout_completion")
        
        logger.info("Analytics updated - DAU: \(dailyActiveUsers), Completion Rate: \(workoutCompletionRate)%")
    }
    
    private func checkForAppUpdates() async {
        logger.info("Checking for app updates")
        
        // This would typically involve checking your server for available updates
        // or using App Store API to check version information
        
        guard let bundleId = Bundle.main.bundleIdentifier else { return }
        
        do {
            let url = URL(string: "https://itunes.apple.com/lookup?bundleId=\(bundleId)")!
            let (data, _) = try await URLSession.shared.data(from: url)
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            
            if let results = json?["results"] as? [[String: Any]],
               let firstResult = results.first,
               let latestVersion = firstResult["version"] as? String {
                
                let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
                
                if latestVersion != currentVersion {
                    logger.info("New app version available: \(latestVersion) (current: \(currentVersion))")
                    // Could schedule a notification about the update
                }
            }
            
        } catch {
            logger.error("Failed to check for app updates: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Notification Scheduling
    
    private func scheduleWorkoutReminders() async throws {
        logger.info("Scheduling workout reminders")
        
        // Get user's workout schedule and preferences
        let upcomingWorkouts = try await getUpcomingWorkouts()
        
        for workout in upcomingWorkouts {
            try await scheduleWorkoutReminder(for: workout)
        }
    }
    
    private func scheduleNutritionReminders() async throws {
        logger.info("Scheduling nutrition reminders")
        
        // Schedule meal time reminders based on user preferences
        let mealTimes = getUserMealTimes()
        
        for mealTime in mealTimes {
            try await scheduleNutritionReminder(for: mealTime)
        }
    }
    
    private func checkGoalProgress() async throws {
        logger.info("Checking goal progress")
        
        let context = CoreDataManager.shared.context
        
        await context.perform {
            do {
                let goalsRequest = Goal.fetchRequest()
                goalsRequest.predicate = NSPredicate(format: "status == %@", "active")
                
                let activeGoals = try context.fetch(goalsRequest)
                
                for goal in activeGoals {
                    let progress = self.calculateGoalProgress(goal)
                    
                    if progress >= 1.0 && !goal.isCompleted {
                        // Goal completed! Schedule celebration notification
                        Task {
                            try? await self.scheduleGoalCelebration(for: goal)
                        }
                    } else if progress >= 0.5 && progress < 0.75 {
                        // Halfway milestone
                        Task {
                            try? await self.scheduleProgressMilestone(for: goal, progress: progress)
                        }
                    }
                }
                
            } catch {
                self.logger.error("Failed to check goal progress: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func processHealthKitWorkout(_ workout: HKWorkout) async throws {
        // Convert HealthKit workout to app workout session
        // This is a simplified version - you'd want more comprehensive mapping
        
        let context = CoreDataManager.shared.context
        
        await context.perform {
            let session = WorkoutSession(context: context)
            session.id = UUID()
            session.startTime = workout.startDate
            session.endTime = workout.endDate
            session.totalDuration = Int16(workout.duration / 60) // Convert to minutes
            session.caloriesBurned = Int16(workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0)
            session.status = "completed"
            
            // You'd typically link this to a User object here
            
            try? context.save()
        }
    }
    
    private func syncBodyMeasurements(from startDate: Date, to endDate: Date) async throws {
        // Sync weight, body fat, etc. from HealthKit
        logger.info("Syncing body measurements from \(startDate) to \(endDate)")
        
        if let weights = try await healthKitManager.fetchBodyWeight(from: startDate, to: endDate) {
            for weight in weights {
                try await processWeightMeasurement(weight)
            }
        }
    }
    
    private func syncNutritionData(from startDate: Date, to endDate: Date) async throws {
        // Sync nutrition data from HealthKit if available
        logger.info("Syncing nutrition data from \(startDate) to \(endDate)")
        
        // Implementation depends on what nutrition data you're tracking
    }
    
    private func calculateWeeklyWorkoutFrequency() async throws -> Int {
        let context = CoreDataManager.shared.context
        
        return await context.perform {
            let request = WorkoutSession.fetchRequest()
            let oneWeekAgo = Date().addingTimeInterval(-7 * 24 * 60 * 60)
            request.predicate = NSPredicate(format: "startTime >= %@ AND status == %@", oneWeekAgo as NSDate, "completed")
            
            return (try? context.fetch(request).count) ?? 0
        }
    }
    
    private func updatePersonalRecords() async throws {
        // Update user's personal records based on recent workouts
        logger.info("Updating personal records")
        
        // Implementation would involve analyzing recent workouts for PRs
    }
    
    private func updateCalorieBurnTrends() async throws {
        // Calculate and store calorie burn trends
        logger.info("Updating calorie burn trends")
        
        // Implementation would involve analyzing recent calorie data
    }
    
    private func syncWeightData() async throws {
        // Sync weight data from HealthKit to Core Data
        if let recentWeight = try await healthKitManager.fetchMostRecentBodyWeight() {
            try await processWeightMeasurement(recentWeight)
        }
    }
    
    private func syncBodyCompositionData() async throws {
        // Sync body composition data from HealthKit
        logger.info("Syncing body composition data")
        
        // Implementation depends on what body composition data you're tracking
    }
    
    private func updateProgressPhotosMetadata() async throws {
        // Update metadata for progress photos (face detection, categorization, etc.)
        logger.info("Updating progress photos metadata")
        
        // Implementation would involve photo analysis
    }
    
    private func calculateDailyActiveUsers() async throws -> Int {
        // For a single-user app, this might track daily engagement
        let context = CoreDataManager.shared.context
        
        return await context.perform {
            let today = Calendar.current.startOfDay(for: Date())
            let request = WorkoutSession.fetchRequest()
            request.predicate = NSPredicate(format: "startTime >= %@", today as NSDate)
            
            return (try? context.fetch(request).count) ?? 0 > 0 ? 1 : 0
        }
    }
    
    private func calculateWorkoutCompletionRate() async throws -> Double {
        let context = CoreDataManager.shared.context
        
        return await context.perform {
            let lastWeek = Date().addingTimeInterval(-7 * 24 * 60 * 60)
            
            // Completed workouts
            let completedRequest = WorkoutSession.fetchRequest()
            completedRequest.predicate = NSPredicate(format: "startTime >= %@ AND status == %@", lastWeek as NSDate, "completed")
            let completedCount = (try? context.fetch(completedRequest).count) ?? 0
            
            // Total workouts (including incomplete)
            let totalRequest = WorkoutSession.fetchRequest()
            totalRequest.predicate = NSPredicate(format: "startTime >= %@", lastWeek as NSDate)
            let totalCount = (try? context.fetch(totalRequest).count) ?? 0
            
            guard totalCount > 0 else { return 0.0 }
            return Double(completedCount) / Double(totalCount) * 100.0
        }
    }
    
    private func processWeightMeasurement(_ sample: HKQuantitySample) async throws {
        let context = CoreDataManager.shared.context
        
        await context.perform {
            let entry = ProgressEntry(context: context)
            entry.id = UUID()
            entry.date = sample.startDate
            entry.type = "weight"
            entry.weight = sample.quantity.doubleValue(for: .pound())
            
            try? context.save()
        }
    }
    
    private func getUpcomingWorkouts() async throws -> [AssignedWorkout] {
        let context = CoreDataManager.shared.context
        
        return await context.perform {
            let request = AssignedWorkout.fetchRequest()
            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
            request.predicate = NSPredicate(format: "scheduledDate <= %@ AND status == %@", tomorrow as NSDate, "assigned")
            request.sortDescriptors = [NSSortDescriptor(keyPath: \AssignedWorkout.scheduledDate, ascending: true)]
            
            return (try? context.fetch(request)) ?? []
        }
    }
    
    private func getUserMealTimes() -> [Date] {
        // Get user's preferred meal times
        // This would typically come from user preferences
        let now = Date()
        let calendar = Calendar.current
        
        var mealTimes: [Date] = []
        
        // Breakfast: 8 AM
        if let breakfast = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: now) {
            mealTimes.append(breakfast)
        }
        
        // Lunch: 12 PM
        if let lunch = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: now) {
            mealTimes.append(lunch)
        }
        
        // Dinner: 6 PM
        if let dinner = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: now) {
            mealTimes.append(dinner)
        }
        
        return mealTimes
    }
    
    private func scheduleWorkoutReminder(for workout: AssignedWorkout) async throws {
        // Schedule a notification for the workout
        guard let scheduledDate = workout.scheduledDate else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Workout Reminder 💪"
        content.body = "Time for your scheduled workout!"
        content.categoryIdentifier = "WORKOUT_REMINDER"
        content.sound = .default
        
        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: scheduledDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "workout-\(workout.id?.uuidString ?? UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        try await UNUserNotificationCenter.current().add(request)
    }
    
    private func scheduleNutritionReminder(for mealTime: Date) async throws {
        let content = UNMutableNotificationContent()
        content.title = "Meal Time 🍽️"
        content.body = "Don't forget to log your meal!"
        content.categoryIdentifier = "NUTRITION_REMINDER"
        content.sound = .default
        
        let triggerDate = Calendar.current.dateComponents([.hour, .minute], from: mealTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "nutrition-\(triggerDate.hour ?? 0)-\(triggerDate.minute ?? 0)",
            content: content,
            trigger: trigger
        )
        
        try await UNUserNotificationCenter.current().add(request)
    }
    
    private func calculateGoalProgress(_ goal: Goal) -> Double {
        guard let targetValue = goal.targetValue, targetValue > 0,
              let currentValue = goal.currentValue else {
            return 0.0
        }
        
        return min(currentValue / targetValue, 1.0)
    }
    
    private func scheduleGoalCelebration(for goal: Goal) async throws {
        let content = UNMutableNotificationContent()
        content.title = "🎉 Goal Achieved!"
        content.body = "Congratulations! You've completed your goal: \(goal.title ?? "Unknown Goal")"
        content.categoryIdentifier = "GOAL_CELEBRATION"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "goal-celebration-\(goal.id?.uuidString ?? UUID().uuidString)",
            content: content,
            trigger: nil // Show immediately
        )
        
        try await UNUserNotificationCenter.current().add(request)
    }
    
    private func scheduleProgressMilestone(for goal: Goal, progress: Double) async throws {
        let content = UNMutableNotificationContent()
        content.title = "Great Progress! 📈"
        content.body = "You're \(Int(progress * 100))% of the way to your goal: \(goal.title ?? "Unknown Goal")"
        content.categoryIdentifier = "PROGRESS_MILESTONE"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "goal-milestone-\(goal.id?.uuidString ?? UUID().uuidString)",
            content: content,
            trigger: nil // Show immediately
        )
        
        try await UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Public Interface
    
    /// Cancels all scheduled background tasks
    public func cancelAllBackgroundTasks() {
        BGTaskScheduler.shared.cancelAllTaskRequests()
        scheduledTasks.removeAll()
        logger.info("Cancelled all background tasks")
    }
    
    /// Gets the status of scheduled tasks
    public var scheduledTasksStatus: [String: Bool] {
        var status: [String: Bool] = [:]
        let allTasks = [backgroundSyncTaskID, healthDataSyncTaskID, maintenanceTaskID, notificationTaskID]
        
        for taskID in allTasks {
            status[taskID] = scheduledTasks.contains(taskID)
        }
        
        return status
    }
}