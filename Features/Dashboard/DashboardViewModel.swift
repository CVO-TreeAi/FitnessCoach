import Foundation
import Combine
import CoreData

@MainActor
public class DashboardViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published public var currentWeight: Double?
    @Published public var goalWeight: Double?
    @Published public var weightProgress: [ProgressDataPoint] = []
    @Published public var weeklyWorkouts: [WorkoutData] = []
    @Published public var todayCalories: Double = 0
    @Published public var todayProtein: Double = 0
    @Published public var todayCarbs: Double = 0
    @Published public var todayFat: Double = 0
    @Published public var targetCalories: Double = 2200
    @Published public var targetProtein: Double = 140
    @Published public var recentWorkouts: [DashboardWorkout] = []
    @Published public var upcomingWorkouts: [DashboardWorkout] = []
    @Published public var todayGoals: [DashboardGoal] = []
    @Published public var weeklyStats: WeeklyStats = WeeklyStats.empty
    @Published public var isLoading: Bool = true
    @Published public var refreshing: Bool = false
    @Published public var errorMessage: String?
    
    // MARK: - Dependencies
    private let coreDataManager = CoreDataManager.shared
    private let healthKitManager: HealthKitManager
    private let authManager: AuthenticationManager
    private var cancellables = Set<AnyCancellable>()
    
    public init(
        healthKitManager: HealthKitManager,
        authManager: AuthenticationManager
    ) {
        self.healthKitManager = healthKitManager
        self.authManager = authManager
        setupSubscriptions()
        loadDashboardData()
    }
    
    // MARK: - Public Methods
    
    public func refresh() async {
        refreshing = true
        await loadDashboardData()
        refreshing = false
    }
    
    public func loadDashboardData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            guard let currentUser = getCurrentUser() else {
                throw DashboardError.userNotFound
            }
            
            async let weightDataTask = loadWeightData(for: currentUser)
            async let workoutDataTask = loadWorkoutData(for: currentUser)
            async let nutritionDataTask = loadNutritionData(for: currentUser)
            async let goalsDataTask = loadGoalsData(for: currentUser)
            
            _ = try await [
                weightDataTask,
                workoutDataTask,
                nutritionDataTask,
                goalsDataTask
            ]
            
            calculateWeeklyStats()
            isLoading = false
            
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
    
    // MARK: - Private Methods
    
    private func setupSubscriptions() {
        // Subscribe to authentication changes
        authManager.$currentUser
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.loadDashboardData()
                }
            }
            .store(in: &cancellables)
        
        // Refresh data every time app becomes active
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.refresh()
                }
            }
            .store(in: &cancellables)
    }
    
    private func getCurrentUser() -> User? {
        guard let userIdentifier = authManager.currentUser?.userIdentifier else { return nil }
        return coreDataManager.fetchUser(by: userIdentifier)
    }
    
    private func loadWeightData(for user: User) async throws {
        let weightEntries = coreDataManager.fetchProgressEntries(
            for: user,
            type: "weight",
            limit: 30
        ).reversed()
        
        weightProgress = weightEntries.compactMap { entry in
            guard let weight = entry.weight, weight > 0 else { return nil }
            return ProgressDataPoint(date: entry.date, value: weight)
        }
        
        currentWeight = weightProgress.last?.value
        
        // Get goal weight from user's client profile or set default
        if let clientProfile = user.clientProfile {
            goalWeight = clientProfile.goalWeight
        }
        
        // Try to get weight from HealthKit
        do {
            let healthWeight = try await healthKitManager.getMostRecentWeight()
            if let healthWeight = healthWeight, healthWeight > 0 {
                currentWeight = healthWeight
                // Create a new progress entry if this is more recent
                if let latestEntry = weightEntries.first,
                   Calendar.current.isDateInToday(latestEntry.date) == false {
                    createWeightEntry(for: user, weight: healthWeight)
                }
            }
        } catch {
            print("Failed to load weight from HealthKit: \(error)")
        }
    }
    
    private func loadWorkoutData(for user: User) async throws {
        // Load recent workout sessions
        let sessions = coreDataManager.fetchWorkoutSessions(for: user, limit: 5)
        recentWorkouts = sessions.compactMap { session in
            DashboardWorkout(
                id: session.id?.uuidString ?? UUID().uuidString,
                name: session.assignedWorkout?.workoutTemplate?.name ?? "Custom Workout",
                date: session.startTime,
                duration: Int(session.totalDuration),
                caloriesBurned: Int(session.caloriesBurned),
                exercises: session.exercises?.count ?? 0,
                status: .completed
            )
        }
        
        // Generate weekly workout data for chart
        let calendar = Calendar.current
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        
        weeklyWorkouts = (0..<7).map { dayOffset in
            let date = calendar.date(byAdding: .day, value: dayOffset, to: weekStart)!
            let dayName = calendar.shortWeekdaySymbols[calendar.component(.weekday, from: date) - 1]
            
            let dayWorkouts = sessions.filter { session in
                calendar.isDate(session.startTime, inSameDayAs: date)
            }
            
            let totalDuration = dayWorkouts.reduce(0) { $0 + Int($1.totalDuration) }
            return WorkoutData(day: dayName, duration: totalDuration)
        }
        
        // Load upcoming assigned workouts (mock for now)
        upcomingWorkouts = generateUpcomingWorkouts()
    }
    
    private func loadNutritionData(for user: User) async throws {
        let today = Date()
        let nutritionEntries = coreDataManager.fetchNutritionEntries(for: user, on: today)
        
        todayCalories = nutritionEntries.reduce(0) { $0 + $1.calories }
        todayProtein = nutritionEntries.reduce(0) { $0 + $1.protein }
        todayCarbs = nutritionEntries.reduce(0) { $0 + $1.carbs }
        todayFat = nutritionEntries.reduce(0) { $0 + $1.fat }
        
        // Calculate targets based on user profile (simplified calculation)
        if let height = user.height,
           let weight = currentWeight,
           let dateOfBirth = user.dateOfBirth {
            
            let age = Calendar.current.dateComponents([.year], from: dateOfBirth, to: Date()).year ?? 25
            let bmr = calculateBMR(weight: weight, height: height, age: age, gender: user.gender ?? "male")
            
            targetCalories = bmr * getActivityMultiplier(for: user.activityLevel ?? "moderate")
            targetProtein = weight * 1.6 // 1.6g per kg bodyweight for active individuals
        }
    }
    
    private func loadGoalsData(for user: User) async throws {
        let activeGoals = coreDataManager.fetchGoals(for: user, status: "active")
        
        todayGoals = activeGoals.prefix(3).map { goal in
            DashboardGoal(
                id: goal.id?.uuidString ?? UUID().uuidString,
                title: goal.title,
                currentValue: goal.currentValue,
                targetValue: goal.targetValue,
                unit: goal.unit,
                progress: calculateGoalProgress(goal),
                category: goal.category
            )
        }
    }
    
    private func calculateWeeklyStats() {
        let calendar = Calendar.current
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        
        weeklyStats = WeeklyStats(
            workoutsCompleted: weeklyWorkouts.reduce(0) { $0 + ($1.duration > 0 ? 1 : 0) },
            totalWorkoutTime: weeklyWorkouts.reduce(0) { $0 + $1.duration },
            averageCalories: Int(todayCalories), // Simplified - should calculate weekly average
            averageProtein: Int(todayProtein), // Simplified - should calculate weekly average
            workoutStreak: calculateWorkoutStreak(),
            weightChange: calculateWeeklyWeightChange()
        )
    }
    
    // MARK: - Helper Methods
    
    private func createWeightEntry(for user: User, weight: Double) {
        let context = coreDataManager.context
        let entry = ProgressEntry(context: context)
        entry.id = UUID()
        entry.user = user
        entry.date = Date()
        entry.type = "weight"
        entry.weight = weight
        coreDataManager.save()
    }
    
    private func calculateBMR(weight: Double, height: Double, age: Int, gender: String) -> Double {
        // Mifflin-St Jeor Equation
        if gender.lowercased() == "male" {
            return (10 * weight) + (6.25 * height) - (5 * Double(age)) + 5
        } else {
            return (10 * weight) + (6.25 * height) - (5 * Double(age)) - 161
        }
    }
    
    private func getActivityMultiplier(for level: String) -> Double {
        switch level.lowercased() {
        case "sedentary": return 1.2
        case "light": return 1.375
        case "moderate": return 1.55
        case "active": return 1.725
        case "very_active": return 1.9
        default: return 1.55
        }
    }
    
    private func calculateGoalProgress(_ goal: Goal) -> Double {
        guard let target = goal.targetValue, target > 0,
              let current = goal.currentValue else { return 0.0 }
        return min(current / target, 1.0)
    }
    
    private func calculateWorkoutStreak() -> Int {
        // Simplified streak calculation - should track consecutive workout days
        return weeklyWorkouts.filter { $0.duration > 0 }.count
    }
    
    private func calculateWeeklyWeightChange() -> Double? {
        guard weightProgress.count >= 7 else { return nil }
        let thisWeek = weightProgress.suffix(7)
        let lastWeek = weightProgress.dropLast(7).suffix(7)
        
        guard let thisWeekAvg = thisWeek.isEmpty ? nil : thisWeek.map(\.value).reduce(0, +) / Double(thisWeek.count),
              let lastWeekAvg = lastWeek.isEmpty ? nil : lastWeek.map(\.value).reduce(0, +) / Double(lastWeek.count) else {
            return nil
        }
        
        return thisWeekAvg - lastWeekAvg
    }
    
    private func generateUpcomingWorkouts() -> [DashboardWorkout] {
        // Mock upcoming workouts - in real app, this would come from assigned workouts
        let calendar = Calendar.current
        return [
            DashboardWorkout(
                id: UUID().uuidString,
                name: "Upper Body Strength",
                date: calendar.date(byAdding: .day, value: 1, to: Date())!,
                duration: 45,
                caloriesBurned: 0,
                exercises: 8,
                status: .scheduled
            ),
            DashboardWorkout(
                id: UUID().uuidString,
                name: "HIIT Cardio",
                date: calendar.date(byAdding: .day, value: 2, to: Date())!,
                duration: 30,
                caloriesBurned: 0,
                exercises: 6,
                status: .scheduled
            )
        ]
    }
}

// MARK: - Data Models

public struct DashboardWorkout: Identifiable, Hashable {
    public let id: String
    public let name: String
    public let date: Date
    public let duration: Int
    public let caloriesBurned: Int
    public let exercises: Int
    public let status: WorkoutStatus
    
    public enum WorkoutStatus {
        case scheduled, inProgress, completed, skipped
    }
}

public struct DashboardGoal: Identifiable, Hashable {
    public let id: String
    public let title: String
    public let currentValue: Double?
    public let targetValue: Double?
    public let unit: String?
    public let progress: Double
    public let category: String
    
    public var formattedCurrentValue: String {
        guard let current = currentValue, let unit = unit else { return "0" }
        return "\(Int(current))\(unit)"
    }
    
    public var formattedTargetValue: String {
        guard let target = targetValue, let unit = unit else { return "0" }
        return "\(Int(target))\(unit)"
    }
}

public struct WeeklyStats {
    public let workoutsCompleted: Int
    public let totalWorkoutTime: Int
    public let averageCalories: Int
    public let averageProtein: Int
    public let workoutStreak: Int
    public let weightChange: Double?
    
    public static let empty = WeeklyStats(
        workoutsCompleted: 0,
        totalWorkoutTime: 0,
        averageCalories: 0,
        averageProtein: 0,
        workoutStreak: 0,
        weightChange: nil
    )
}

// MARK: - Errors

public enum DashboardError: Error, LocalizedError {
    case userNotFound
    case dataLoadFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "User not found. Please sign in again."
        case .dataLoadFailed(let message):
            return "Failed to load dashboard data: \(message)"
        }
    }
}