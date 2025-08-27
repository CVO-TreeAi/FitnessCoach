import Foundation
import Combine

@MainActor
class WatchDataStore: ObservableObject {
    @Published var userStats = WatchUserStats()
    @Published var recentWorkouts: [WatchWorkout] = []
    @Published var activeWorkoutSession: WorkoutSession?
    @Published var waterIntake: [WaterEntry] = []
    @Published var bodyMetrics: [BodyMetricEntry] = []
    @Published var quickLogs: [QuickLogEntry] = []
    @Published var goals: [FitnessGoal] = []
    @Published var lastSyncDate: Date?
    @Published var isLoading = false
    
    private let userDefaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Storage Keys
    private enum StorageKey: String, CaseIterable {
        case userStats = "watchUserStats"
        case recentWorkouts = "watchRecentWorkouts"
        case activeWorkoutSession = "watchActiveWorkoutSession"
        case waterIntake = "watchWaterIntake"
        case bodyMetrics = "watchBodyMetrics"
        case quickLogs = "watchQuickLogs"
        case goals = "watchGoals"
        case lastSyncDate = "watchLastSyncDate"
    }
    
    init() {
        setupDateFormatters()
        loadAllData()
        setupAutoSave()
    }
    
    private func setupDateFormatters() {
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }
    
    // MARK: - Data Loading
    
    private func loadAllData() {
        loadUserStats()
        loadRecentWorkouts()
        loadActiveWorkoutSession()
        loadWaterIntake()
        loadBodyMetrics()
        loadQuickLogs()
        loadGoals()
        loadLastSyncDate()
    }
    
    private func loadUserStats() {
        userStats = load(WatchUserStats.self, key: .userStats) ?? WatchUserStats()
    }
    
    private func loadRecentWorkouts() {
        recentWorkouts = load([WatchWorkout].self, key: .recentWorkouts) ?? []
    }
    
    private func loadActiveWorkoutSession() {
        activeWorkoutSession = load(WorkoutSession.self, key: .activeWorkoutSession)
    }
    
    private func loadWaterIntake() {
        waterIntake = load([WaterEntry].self, key: .waterIntake) ?? []
        // Clean old entries (older than 7 days)
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        waterIntake = waterIntake.filter { $0.timestamp > cutoffDate }
    }
    
    private func loadBodyMetrics() {
        bodyMetrics = load([BodyMetricEntry].self, key: .bodyMetrics) ?? []
        // Keep only last 30 days
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        bodyMetrics = bodyMetrics.filter { $0.timestamp > cutoffDate }
    }
    
    private func loadQuickLogs() {
        quickLogs = load([QuickLogEntry].self, key: .quickLogs) ?? []
        // Clean old entries (older than 7 days)
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        quickLogs = quickLogs.filter { $0.timestamp > cutoffDate }
    }
    
    private func loadGoals() {
        goals = load([FitnessGoal].self, key: .goals) ?? createDefaultGoals()
    }
    
    private func loadLastSyncDate() {
        lastSyncDate = userDefaults.object(forKey: StorageKey.lastSyncDate.rawValue) as? Date
    }
    
    // MARK: - Generic Data Operations
    
    private func load<T: Codable>(_ type: T.Type, key: StorageKey) -> T? {
        guard let data = userDefaults.data(forKey: key.rawValue) else { return nil }
        
        do {
            return try decoder.decode(type, from: data)
        } catch {
            print("Failed to decode \(key.rawValue): \(error)")
            return nil
        }
    }
    
    private func save<T: Codable>(_ object: T, key: StorageKey) {
        do {
            let data = try encoder.encode(object)
            userDefaults.set(data, forKey: key.rawValue)
        } catch {
            print("Failed to encode \(key.rawValue): \(error)")
        }
    }
    
    // MARK: - Auto-Save Setup
    
    private func setupAutoSave() {
        // Auto-save userStats changes
        $userStats
            .dropFirst()
            .sink { [weak self] stats in
                self?.save(stats, key: .userStats)
            }
            .store(in: &cancellables)
        
        // Auto-save workout changes
        $recentWorkouts
            .dropFirst()
            .sink { [weak self] workouts in
                self?.save(workouts, key: .recentWorkouts)
            }
            .store(in: &cancellables)
        
        // Auto-save active workout session
        $activeWorkoutSession
            .dropFirst()
            .sink { [weak self] session in
                if let session = session {
                    self?.save(session, key: .activeWorkoutSession)
                } else {
                    self?.userDefaults.removeObject(forKey: StorageKey.activeWorkoutSession.rawValue)
                }
            }
            .store(in: &cancellables)
        
        // Auto-save other data types
        setupAutoSaveForArrays()
    }
    
    private func setupAutoSaveForArrays() {
        $waterIntake
            .dropFirst()
            .sink { [weak self] entries in
                self?.save(entries, key: .waterIntake)
            }
            .store(in: &cancellables)
        
        $bodyMetrics
            .dropFirst()
            .sink { [weak self] entries in
                self?.save(entries, key: .bodyMetrics)
            }
            .store(in: &cancellables)
        
        $quickLogs
            .dropFirst()
            .sink { [weak self] entries in
                self?.save(entries, key: .quickLogs)
            }
            .store(in: &cancellables)
        
        $goals
            .dropFirst()
            .sink { [weak self] goals in
                self?.save(goals, key: .goals)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Water Tracking
    
    func addWaterEntry(_ amount: Double, unit: WaterUnit = .flOz) {
        let entry = WaterEntry(amount: amount, unit: unit)
        waterIntake.append(entry)
        updateDailyWaterGoal()
    }
    
    func getTodayWaterIntake() -> Double {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) ?? Date()
        
        return waterIntake
            .filter { $0.timestamp >= today && $0.timestamp < tomorrow }
            .reduce(0) { total, entry in
                total + entry.amountInFlOz
            }
    }
    
    private func updateDailyWaterGoal() {
        let todayIntake = getTodayWaterIntake()
        // Update goal progress if needed
        updateGoalProgress(.water, progress: todayIntake)
    }
    
    // MARK: - Body Metrics
    
    func addBodyMetric(_ type: BodyMetricType, value: Double, unit: String) {
        let entry = BodyMetricEntry(type: type, value: value, unit: unit)
        bodyMetrics.append(entry)
        
        // Update user stats if it's weight
        if type == .weight {
            userStats = WatchUserStats(
                currentWeight: value,
                goalWeight: userStats.goalWeight,
                workoutsThisWeek: userStats.workoutsThisWeek,
                workoutGoal: userStats.workoutGoal,
                caloriesToday: userStats.caloriesToday,
                calorieGoal: userStats.calorieGoal,
                proteinToday: userStats.proteinToday,
                proteinGoal: userStats.proteinGoal,
                lastUpdated: Date()
            )
        }
    }
    
    func getLatestBodyMetric(_ type: BodyMetricType) -> BodyMetricEntry? {
        return bodyMetrics
            .filter { $0.type == type }
            .sorted { $0.timestamp > $1.timestamp }
            .first
    }
    
    // MARK: - Quick Logs
    
    func addQuickLog(_ type: QuickLogType, value: Double, note: String? = nil) {
        let entry = QuickLogEntry(type: type, value: value, note: note)
        quickLogs.append(entry)
        
        // Update relevant stats
        updateStatsFromQuickLog(entry)
    }
    
    private func updateStatsFromQuickLog(_ log: QuickLogEntry) {
        switch log.type {
        case .calories:
            let newCalories = userStats.caloriesToday + Int(log.value)
            userStats = WatchUserStats(
                currentWeight: userStats.currentWeight,
                goalWeight: userStats.goalWeight,
                workoutsThisWeek: userStats.workoutsThisWeek,
                workoutGoal: userStats.workoutGoal,
                caloriesToday: newCalories,
                calorieGoal: userStats.calorieGoal,
                proteinToday: userStats.proteinToday,
                proteinGoal: userStats.proteinGoal,
                lastUpdated: Date()
            )
            
        case .protein:
            let newProtein = userStats.proteinToday + log.value
            userStats = WatchUserStats(
                currentWeight: userStats.currentWeight,
                goalWeight: userStats.goalWeight,
                workoutsThisWeek: userStats.workoutsThisWeek,
                workoutGoal: userStats.workoutGoal,
                caloriesToday: userStats.caloriesToday,
                calorieGoal: userStats.calorieGoal,
                proteinToday: newProtein,
                proteinGoal: userStats.proteinGoal,
                lastUpdated: Date()
            )
            
        default:
            break
        }
    }
    
    // MARK: - Goals Management
    
    private func createDefaultGoals() -> [FitnessGoal] {
        return [
            FitnessGoal(type: .water, target: 64, current: 0, unit: "fl oz"),
            FitnessGoal(type: .workouts, target: 5, current: 0, unit: "workouts"),
            FitnessGoal(type: .calories, target: 2200, current: 0, unit: "calories"),
            FitnessGoal(type: .protein, target: 140, current: 0, unit: "grams")
        ]
    }
    
    func updateGoalProgress(_ type: FitnessGoalType, progress: Double) {
        if let index = goals.firstIndex(where: { $0.type == type }) {
            goals[index] = FitnessGoal(
                id: goals[index].id,
                type: type,
                target: goals[index].target,
                current: progress,
                unit: goals[index].unit,
                deadline: goals[index].deadline
            )
        }
    }
    
    func getGoalProgress(_ type: FitnessGoalType) -> FitnessGoal? {
        return goals.first { $0.type == type }
    }
    
    // MARK: - Workout Session Management
    
    func startWorkoutSession(_ workout: WatchWorkout) {
        let session = WorkoutSession(
            workoutId: workout.id,
            startTime: Date(),
            activityType: workout.hkActivityType
        )
        activeWorkoutSession = session
    }
    
    func endWorkoutSession() {
        guard var session = activeWorkoutSession else { return }
        session.end()
        
        // Convert to WatchWorkout and add to recent workouts
        let workout = WatchWorkout(
            id: session.workoutId,
            name: "Watch Workout",
            activityType: session.hkActivityType,
            duration: session.duration,
            caloriesBurned: session.caloriesBurned,
            startDate: session.startTime,
            endDate: session.endTime ?? Date(),
            isCompleted: true
        )
        
        addCompletedWorkout(workout)
        activeWorkoutSession = nil
    }
    
    func addCompletedWorkout(_ workout: WatchWorkout) {
        recentWorkouts.insert(workout, at: 0)
        
        // Keep only last 20 workouts
        if recentWorkouts.count > 20 {
            recentWorkouts = Array(recentWorkouts.prefix(20))
        }
        
        // Update weekly workout count
        updateWeeklyWorkoutCount()
    }
    
    private func updateWeeklyWorkoutCount() {
        let calendar = Calendar.current
        let now = Date()
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        
        let weeklyCount = recentWorkouts.filter { workout in
            workout.startDate >= weekStart && workout.isCompleted
        }.count
        
        userStats = WatchUserStats(
            currentWeight: userStats.currentWeight,
            goalWeight: userStats.goalWeight,
            workoutsThisWeek: weeklyCount,
            workoutGoal: userStats.workoutGoal,
            caloriesToday: userStats.caloriesToday,
            calorieGoal: userStats.calorieGoal,
            proteinToday: userStats.proteinToday,
            proteinGoal: userStats.proteinGoal,
            lastUpdated: Date()
        )
        
        updateGoalProgress(.workouts, progress: Double(weeklyCount))
    }
    
    // MARK: - Data Sync
    
    func updateFromSync(_ stats: WatchUserStats, workouts: [WatchWorkout]) {
        userStats = stats
        recentWorkouts = workouts
        lastSyncDate = Date()
        userDefaults.set(lastSyncDate, forKey: StorageKey.lastSyncDate.rawValue)
    }
    
    func clearAllData() {
        for key in StorageKey.allCases {
            userDefaults.removeObject(forKey: key.rawValue)
        }
        
        // Reset to defaults
        userStats = WatchUserStats()
        recentWorkouts = []
        activeWorkoutSession = nil
        waterIntake = []
        bodyMetrics = []
        quickLogs = []
        goals = createDefaultGoals()
        lastSyncDate = nil
    }
    
    // MARK: - Data Export
    
    func getDataForSync() -> [String: Any] {
        var data: [String: Any] = [:]
        
        // Add water intake for today
        data["todayWaterIntake"] = getTodayWaterIntake()
        
        // Add recent body metrics
        if let latestWeight = getLatestBodyMetric(.weight) {
            data["currentWeight"] = latestWeight.value
        }
        
        // Add quick logs from today
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) ?? Date()
        let todayLogs = quickLogs.filter { $0.timestamp >= today && $0.timestamp < tomorrow }
        
        do {
            data["todayQuickLogs"] = try encoder.encode(todayLogs)
        } catch {
            print("Failed to encode quick logs for sync: \(error)")
        }
        
        return data
    }
}

// MARK: - Supporting Models

struct WaterEntry: Codable, Identifiable {
    let id = UUID()
    let amount: Double
    let unit: WaterUnit
    let timestamp: Date
    
    init(amount: Double, unit: WaterUnit = .flOz, timestamp: Date = Date()) {
        self.amount = amount
        self.unit = unit
        self.timestamp = timestamp
    }
    
    var amountInFlOz: Double {
        switch unit {
        case .flOz:
            return amount
        case .ml:
            return amount * 0.033814
        case .cups:
            return amount * 8
        case .liters:
            return amount * 33.814
        }
    }
}

enum WaterUnit: String, Codable, CaseIterable {
    case flOz = "fl_oz"
    case ml = "ml"
    case cups = "cups"
    case liters = "liters"
    
    var displayName: String {
        switch self {
        case .flOz: return "fl oz"
        case .ml: return "mL"
        case .cups: return "cups"
        case .liters: return "L"
        }
    }
}

struct BodyMetricEntry: Codable, Identifiable {
    let id = UUID()
    let type: BodyMetricType
    let value: Double
    let unit: String
    let timestamp: Date
    
    init(type: BodyMetricType, value: Double, unit: String, timestamp: Date = Date()) {
        self.type = type
        self.value = value
        self.unit = unit
        self.timestamp = timestamp
    }
}

enum BodyMetricType: String, Codable, CaseIterable {
    case weight = "weight"
    case bodyFat = "body_fat"
    case muscleMass = "muscle_mass"
    case waist = "waist"
    case chest = "chest"
    case arms = "arms"
    
    var displayName: String {
        switch self {
        case .weight: return "Weight"
        case .bodyFat: return "Body Fat %"
        case .muscleMass: return "Muscle Mass"
        case .waist: return "Waist"
        case .chest: return "Chest"
        case .arms: return "Arms"
        }
    }
}

struct QuickLogEntry: Codable, Identifiable {
    let id = UUID()
    let type: QuickLogType
    let value: Double
    let note: String?
    let timestamp: Date
    
    init(type: QuickLogType, value: Double, note: String? = nil, timestamp: Date = Date()) {
        self.type = type
        self.value = value
        self.note = note
        self.timestamp = timestamp
    }
}

enum QuickLogType: String, Codable, CaseIterable {
    case calories = "calories"
    case protein = "protein"
    case carbs = "carbs"
    case fats = "fats"
    case mood = "mood"
    case energy = "energy"
    
    var displayName: String {
        switch self {
        case .calories: return "Calories"
        case .protein: return "Protein"
        case .carbs: return "Carbs"
        case .fats: return "Fats"
        case .mood: return "Mood"
        case .energy: return "Energy"
        }
    }
    
    var unit: String {
        switch self {
        case .calories: return "cal"
        case .protein, .carbs, .fats: return "g"
        case .mood, .energy: return "/10"
        }
    }
}

struct FitnessGoal: Codable, Identifiable {
    let id: UUID
    let type: FitnessGoalType
    let target: Double
    let current: Double
    let unit: String
    let deadline: Date?
    
    init(id: UUID = UUID(), type: FitnessGoalType, target: Double, current: Double, unit: String, deadline: Date? = nil) {
        self.id = id
        self.type = type
        self.target = target
        self.current = current
        self.unit = unit
        self.deadline = deadline
    }
    
    var progressPercentage: Double {
        guard target > 0 else { return 0 }
        return min(current / target, 1.0)
    }
    
    var isCompleted: Bool {
        current >= target
    }
}

enum FitnessGoalType: String, Codable, CaseIterable {
    case water = "water"
    case workouts = "workouts"
    case calories = "calories"
    case protein = "protein"
    case steps = "steps"
    case activeCalories = "active_calories"
    
    var displayName: String {
        switch self {
        case .water: return "Water"
        case .workouts: return "Workouts"
        case .calories: return "Calories"
        case .protein: return "Protein"
        case .steps: return "Steps"
        case .activeCalories: return "Active Calories"
        }
    }
    
    var iconName: String {
        switch self {
        case .water: return "drop.fill"
        case .workouts: return "figure.strengthtraining.traditional"
        case .calories: return "flame.fill"
        case .protein: return "fish.fill"
        case .steps: return "figure.walk"
        case .activeCalories: return "flame"
        }
    }
}