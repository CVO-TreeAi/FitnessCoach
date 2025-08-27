import Foundation
import SwiftUI

// MARK: - Dashboard Data Models

public struct DashboardWorkout: Identifiable {
    public let id: String
    public let name: String
    public let date: Date
    public let duration: Int // in minutes
    public let caloriesBurned: Int
    public let isCompleted: Bool
    
    public init(
        id: String = UUID().uuidString,
        name: String,
        date: Date,
        duration: Int,
        caloriesBurned: Int = 0,
        isCompleted: Bool = false
    ) {
        self.id = id
        self.name = name
        self.date = date
        self.duration = duration
        self.caloriesBurned = caloriesBurned
        self.isCompleted = isCompleted
    }
}

public struct DashboardGoal: Identifiable {
    public let id: String
    public let title: String
    public let currentValue: Double
    public let targetValue: Double
    public let unit: String
    public let icon: String
    
    public var progress: Double {
        guard targetValue > 0 else { return 0 }
        return min(currentValue / targetValue, 1.0)
    }
    
    public var formattedCurrentValue: String {
        formatValue(currentValue)
    }
    
    public var formattedTargetValue: String {
        formatValue(targetValue)
    }
    
    private func formatValue(_ value: Double) -> String {
        if unit == "cal" || unit == "steps" {
            return "\(Int(value))"
        } else if unit == "g" || unit == "lbs" || unit == "kg" {
            return String(format: "%.1f", value)
        } else {
            return "\(Int(value))"
        }
    }
    
    public init(
        id: String = UUID().uuidString,
        title: String,
        currentValue: Double,
        targetValue: Double,
        unit: String,
        icon: String = "target"
    ) {
        self.id = id
        self.title = title
        self.currentValue = currentValue
        self.targetValue = targetValue
        self.unit = unit
        self.icon = icon
    }
}

public struct WeeklyStats {
    public let workoutsCompleted: Int
    public let totalWorkoutTime: Int // in minutes
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
    
    public init(
        workoutsCompleted: Int,
        totalWorkoutTime: Int,
        averageCalories: Int,
        averageProtein: Int,
        workoutStreak: Int,
        weightChange: Double?
    ) {
        self.workoutsCompleted = workoutsCompleted
        self.totalWorkoutTime = totalWorkoutTime
        self.averageCalories = averageCalories
        self.averageProtein = averageProtein
        self.workoutStreak = workoutStreak
        self.weightChange = weightChange
    }
}

public struct ProgressDataPoint: Identifiable {
    public let id = UUID()
    public let date: Date
    public let value: Double
    public let label: String?
    
    public init(date: Date, value: Double, label: String? = nil) {
        self.date = date
        self.value = value
        self.label = label
    }
}

public struct WorkoutData: Identifiable {
    public let id = UUID()
    public let day: String
    public let minutes: Int
    public let target: Int
    
    public init(day: String, minutes: Int, target: Int = 30) {
        self.day = day
        self.minutes = minutes
        self.target = target
    }
}

public enum DashboardError: LocalizedError {
    case userNotFound
    case dataLoadFailed
    case invalidData
    
    public var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "User profile not found. Please sign in again."
        case .dataLoadFailed:
            return "Failed to load dashboard data. Please try again."
        case .invalidData:
            return "Invalid data received. Please contact support."
        }
    }
}