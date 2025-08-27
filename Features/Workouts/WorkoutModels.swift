import Foundation
import SwiftUI

// MARK: - Workout Template
public struct WorkoutTemplate: Identifiable {
    public let id: String
    public let name: String
    public let description: String
    public let category: WorkoutCategory
    public let difficulty: WorkoutDifficulty
    public let estimatedDuration: Int // in minutes
    public let exercises: [ExerciseTemplate]
    public let createdBy: String?
    public let lastPerformed: Date?
    public let isCustom: Bool
    
    public var exerciseCount: Int {
        exercises.count
    }
    
    public init(
        id: String = UUID().uuidString,
        name: String,
        description: String,
        category: WorkoutCategory,
        difficulty: WorkoutDifficulty,
        estimatedDuration: Int,
        exercises: [ExerciseTemplate] = [],
        createdBy: String? = nil,
        lastPerformed: Date? = nil,
        isCustom: Bool = false
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.category = category
        self.difficulty = difficulty
        self.estimatedDuration = estimatedDuration
        self.exercises = exercises
        self.createdBy = createdBy
        self.lastPerformed = lastPerformed
        self.isCustom = isCustom
    }
}

// MARK: - Exercise Template
public struct ExerciseTemplate: Identifiable {
    public let id: String
    public let name: String
    public let category: ExerciseCategory
    public let muscleGroups: [MuscleGroup]
    public let equipment: Equipment?
    public let instructions: String?
    public let videoUrl: String?
    public let defaultSets: Int
    public let defaultReps: String // Can be range like "8-12"
    public let defaultRestTime: Int // in seconds
    public let notes: String?
    
    public init(
        id: String = UUID().uuidString,
        name: String,
        category: ExerciseCategory,
        muscleGroups: [MuscleGroup],
        equipment: Equipment? = nil,
        instructions: String? = nil,
        videoUrl: String? = nil,
        defaultSets: Int = 3,
        defaultReps: String = "10",
        defaultRestTime: Int = 60,
        notes: String? = nil
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.muscleGroups = muscleGroups
        self.equipment = equipment
        self.instructions = instructions
        self.videoUrl = videoUrl
        self.defaultSets = defaultSets
        self.defaultReps = defaultReps
        self.defaultRestTime = defaultRestTime
        self.notes = notes
    }
}

// MARK: - Active Workout
public struct ActiveWorkout: Identifiable {
    public let id: String
    public let name: String
    public let startTime: Date
    public var elapsedTime: TimeInterval
    public var completedExercises: Int
    public let totalExercises: Int
    public var currentExerciseIndex: Int
    public var isPaused: Bool
    
    public var progress: Double {
        guard totalExercises > 0 else { return 0 }
        return Double(completedExercises) / Double(totalExercises)
    }
    
    public init(
        id: String = UUID().uuidString,
        name: String,
        startTime: Date = Date(),
        elapsedTime: TimeInterval = 0,
        completedExercises: Int = 0,
        totalExercises: Int,
        currentExerciseIndex: Int = 0,
        isPaused: Bool = false
    ) {
        self.id = id
        self.name = name
        self.startTime = startTime
        self.elapsedTime = elapsedTime
        self.completedExercises = completedExercises
        self.totalExercises = totalExercises
        self.currentExerciseIndex = currentExerciseIndex
        self.isPaused = isPaused
    }
}

// MARK: - Workout History
public struct WorkoutHistory: Identifiable {
    public let id: String
    public let name: String
    public let completedAt: Date
    public let duration: Int // in minutes
    public let caloriesBurned: Int
    public let exercisesCompleted: Int
    public let totalWeight: Double?
    public let rating: Int? // 1-5 stars
    public let notes: String?
    
    public init(
        id: String = UUID().uuidString,
        name: String,
        completedAt: Date,
        duration: Int,
        caloriesBurned: Int,
        exercisesCompleted: Int,
        totalWeight: Double? = nil,
        rating: Int? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.name = name
        self.completedAt = completedAt
        self.duration = duration
        self.caloriesBurned = caloriesBurned
        self.exercisesCompleted = exercisesCompleted
        self.totalWeight = totalWeight
        self.rating = rating
        self.notes = notes
    }
}

// MARK: - Exercise Category
public enum ExerciseCategory: String, CaseIterable {
    case chest = "Chest"
    case back = "Back"
    case shoulders = "Shoulders"
    case biceps = "Biceps"
    case triceps = "Triceps"
    case legs = "Legs"
    case glutes = "Glutes"
    case abs = "Abs"
    case cardio = "Cardio"
    case fullBody = "Full Body"
    case stretching = "Stretching"
    
    public var icon: String {
        switch self {
        case .chest: return "figure.strengthtraining.traditional"
        case .back: return "figure.rowing"
        case .shoulders: return "figure.arms.open"
        case .biceps, .triceps: return "figure.strengthtraining.functional"
        case .legs: return "figure.walk"
        case .glutes: return "figure.squats"
        case .abs: return "figure.core.training"
        case .cardio: return "heart.fill"
        case .fullBody: return "figure.mixed.cardio"
        case .stretching: return "figure.flexibility"
        }
    }
}

// MARK: - Muscle Group
public enum MuscleGroup: String, CaseIterable {
    case pectorals = "Pectorals"
    case deltoids = "Deltoids"
    case biceps = "Biceps"
    case triceps = "Triceps"
    case forearms = "Forearms"
    case lats = "Lats"
    case traps = "Traps"
    case rhomboids = "Rhomboids"
    case erectorSpinae = "Erector Spinae"
    case quadriceps = "Quadriceps"
    case hamstrings = "Hamstrings"
    case calves = "Calves"
    case glutes = "Glutes"
    case abs = "Abs"
    case obliques = "Obliques"
    case hipFlexors = "Hip Flexors"
    
    public var displayName: String {
        rawValue
    }
}

// MARK: - Equipment
public enum Equipment: String, CaseIterable {
    case barbell = "Barbell"
    case dumbbell = "Dumbbell"
    case kettlebell = "Kettlebell"
    case cable = "Cable"
    case machine = "Machine"
    case bodyweight = "Bodyweight"
    case resistance = "Resistance Band"
    case pullupBar = "Pull-up Bar"
    case bench = "Bench"
    case box = "Box"
    case ball = "Medicine Ball"
    case trx = "TRX"
    case none = "None"
    
    public var icon: String {
        switch self {
        case .barbell, .dumbbell: return "dumbbell"
        case .kettlebell: return "scalemass"
        case .cable, .machine: return "gear"
        case .bodyweight: return "figure.strengthtraining.traditional"
        case .resistance: return "line.diagonal"
        case .pullupBar: return "arrow.up.to.line"
        case .bench: return "rectangle.fill"
        case .box: return "cube"
        case .ball: return "circle.fill"
        case .trx: return "link"
        case .none: return "xmark"
        }
    }
}

// MARK: - Workout Set
public struct WorkoutSet: Identifiable {
    public let id: String
    public var reps: Int
    public var weight: Double?
    public var duration: TimeInterval?
    public var distance: Double?
    public var isCompleted: Bool
    public var notes: String?
    
    public init(
        id: String = UUID().uuidString,
        reps: Int,
        weight: Double? = nil,
        duration: TimeInterval? = nil,
        distance: Double? = nil,
        isCompleted: Bool = false,
        notes: String? = nil
    ) {
        self.id = id
        self.reps = reps
        self.weight = weight
        self.duration = duration
        self.distance = distance
        self.isCompleted = isCompleted
        self.notes = notes
    }
}