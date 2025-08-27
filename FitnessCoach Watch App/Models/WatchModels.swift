import Foundation
import HealthKit

// MARK: - Shared Models for Watch Connectivity

struct WatchUserStats: Codable {
    let currentWeight: Double?
    let goalWeight: Double?
    let workoutsThisWeek: Int
    let workoutGoal: Int
    let caloriesToday: Int
    let calorieGoal: Int
    let proteinToday: Double
    let proteinGoal: Double
    let lastUpdated: Date
    
    init(
        currentWeight: Double? = nil,
        goalWeight: Double? = nil,
        workoutsThisWeek: Int = 0,
        workoutGoal: Int = 5,
        caloriesToday: Int = 0,
        calorieGoal: Int = 2200,
        proteinToday: Double = 0,
        proteinGoal: Double = 140,
        lastUpdated: Date = Date()
    ) {
        self.currentWeight = currentWeight
        self.goalWeight = goalWeight
        self.workoutsThisWeek = workoutsThisWeek
        self.workoutGoal = workoutGoal
        self.caloriesToday = caloriesToday
        self.calorieGoal = calorieGoal
        self.proteinToday = proteinToday
        self.proteinGoal = proteinGoal
        self.lastUpdated = lastUpdated
    }
}

struct WatchWorkout: Codable, Identifiable {
    let id: UUID
    let name: String
    let activityType: HKWorkoutActivityType.RawValue
    let duration: TimeInterval
    let caloriesBurned: Double?
    let startDate: Date
    let endDate: Date
    let isCompleted: Bool
    
    init(
        id: UUID = UUID(),
        name: String,
        activityType: HKWorkoutActivityType = .other,
        duration: TimeInterval = 0,
        caloriesBurned: Double? = nil,
        startDate: Date = Date(),
        endDate: Date = Date(),
        isCompleted: Bool = false
    ) {
        self.id = id
        self.name = name
        self.activityType = activityType.rawValue
        self.duration = duration
        self.caloriesBurned = caloriesBurned
        self.startDate = startDate
        self.endDate = endDate
        self.isCompleted = isCompleted
    }
    
    var hkActivityType: HKWorkoutActivityType {
        HKWorkoutActivityType(rawValue: activityType) ?? .other
    }
}

struct WatchMessage: Codable {
    let type: MessageType
    let data: Data?
    let timestamp: Date
    
    enum MessageType: String, Codable {
        case statsUpdate = "stats_update"
        case workoutStart = "workout_start"
        case workoutEnd = "workout_end"
        case workoutSync = "workout_sync"
        case heartRateUpdate = "heart_rate_update"
        case requestSync = "request_sync"
        case complicationUpdate = "complication_update"
    }
    
    init(type: MessageType, data: Data? = nil) {
        self.type = type
        self.data = data
        self.timestamp = Date()
    }
}

struct WatchHeartRateReading: Codable {
    let heartRate: Double
    let timestamp: Date
    let workoutId: UUID?
    
    init(heartRate: Double, timestamp: Date = Date(), workoutId: UUID? = nil) {
        self.heartRate = heartRate
        self.timestamp = timestamp
        self.workoutId = workoutId
    }
}

// MARK: - Complication Data

struct ComplicationData: Codable {
    let workoutsCompleted: Int
    let currentWeight: String
    let lastWorkout: String
    let calorieProgress: Double // 0.0 - 1.0
    
    init(
        workoutsCompleted: Int = 0,
        currentWeight: String = "--",
        lastWorkout: String = "None",
        calorieProgress: Double = 0.0
    ) {
        self.workoutsCompleted = workoutsCompleted
        self.currentWeight = currentWeight
        self.lastWorkout = lastWorkout
        self.calorieProgress = calorieProgress
    }
}

// MARK: - Watch Settings

struct WatchSettings: Codable {
    let enableHapticFeedback: Bool
    let autoStartWorkouts: Bool
    let showHeartRateAlerts: Bool
    let complicationStyle: ComplicationStyle
    let preferredUnits: UnitSystem
    
    enum ComplicationStyle: String, Codable, CaseIterable {
        case minimal = "minimal"
        case detailed = "detailed"
        case stats = "stats"
        
        var displayName: String {
            switch self {
            case .minimal: return "Minimal"
            case .detailed: return "Detailed"
            case .stats: return "Stats Focus"
            }
        }
    }
    
    enum UnitSystem: String, Codable, CaseIterable {
        case metric = "metric"
        case imperial = "imperial"
        
        var displayName: String {
            switch self {
            case .metric: return "Metric"
            case .imperial: return "Imperial"
            }
        }
    }
    
    static let `default` = WatchSettings(
        enableHapticFeedback: true,
        autoStartWorkouts: false,
        showHeartRateAlerts: true,
        complicationStyle: .detailed,
        preferredUnits: .imperial
    )
}

// MARK: - Workout Session Data

struct WorkoutSession: Codable {
    let id: UUID
    let workoutId: UUID
    let startTime: Date
    var endTime: Date?
    var heartRateReadings: [WatchHeartRateReading]
    var caloriesBurned: Double
    var duration: TimeInterval
    let activityType: HKWorkoutActivityType.RawValue
    
    init(
        id: UUID = UUID(),
        workoutId: UUID,
        startTime: Date = Date(),
        activityType: HKWorkoutActivityType = .other
    ) {
        self.id = id
        self.workoutId = workoutId
        self.startTime = startTime
        self.endTime = nil
        self.heartRateReadings = []
        self.caloriesBurned = 0
        self.duration = 0
        self.activityType = activityType.rawValue
    }
    
    var isActive: Bool {
        endTime == nil
    }
    
    var hkActivityType: HKWorkoutActivityType {
        HKWorkoutActivityType(rawValue: activityType) ?? .other
    }
    
    mutating func addHeartRateReading(_ reading: WatchHeartRateReading) {
        heartRateReadings.append(reading)
    }
    
    mutating func end(at date: Date = Date()) {
        endTime = date
        duration = date.timeIntervalSince(startTime)
    }
    
    var averageHeartRate: Double {
        guard !heartRateReadings.isEmpty else { return 0 }
        let sum = heartRateReadings.reduce(0) { $0 + $1.heartRate }
        return sum / Double(heartRateReadings.count)
    }
}