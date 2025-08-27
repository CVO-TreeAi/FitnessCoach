import Foundation
import SwiftUI
import HealthKit

// MARK: - Core Data Models

// MARK: - Exercise & Workout Models
struct Exercise: Identifiable, Codable {
    let id = UUID()
    let name: String
    let category: ExerciseCategory
    let muscleGroups: [MuscleGroup]
    let instructions: [String]
    let equipment: Equipment
    let difficulty: Difficulty
    let imageURL: String?
    let videoURL: String?
    var isFavorite: Bool = false
    
    enum ExerciseCategory: String, CaseIterable, Codable {
        case chest = "Chest"
        case back = "Back"
        case shoulders = "Shoulders"
        case arms = "Arms"
        case legs = "Legs"
        case core = "Core"
        case cardio = "Cardio"
        case fullBody = "Full Body"
        
        var icon: String {
            switch self {
            case .chest: return "figure.strengthtraining.traditional"
            case .back: return "figure.mind.and.body"
            case .shoulders: return "figure.arms.open"
            case .arms: return "figure.flexibility"
            case .legs: return "figure.walk"
            case .core: return "figure.core.training"
            case .cardio: return "figure.run"
            case .fullBody: return "figure.mixed.cardio"
            }
        }
    }
    
    enum MuscleGroup: String, CaseIterable, Codable {
        case chest, triceps, shoulders, back, biceps, forearms
        case quads, hamstrings, glutes, calves
        case abs, obliques, lowerBack
        case cardio, fullBody
    }
    
    enum Equipment: String, CaseIterable, Codable {
        case bodyweight = "Bodyweight"
        case dumbbell = "Dumbbell"
        case barbell = "Barbell"
        case cable = "Cable"
        case machine = "Machine"
        case kettlebell = "Kettlebell"
        case resistance = "Resistance Band"
        case cardio = "Cardio Machine"
    }
    
    enum Difficulty: String, CaseIterable, Codable {
        case beginner = "Beginner"
        case intermediate = "Intermediate"
        case advanced = "Advanced"
    }
}

struct WorkoutTemplate: Identifiable, Codable {
    let id = UUID()
    let name: String
    let description: String
    let category: WorkoutCategory
    let estimatedDuration: Int // minutes
    let exercises: [WorkoutExercise]
    let difficulty: Exercise.Difficulty
    let equipment: [Exercise.Equipment]
    var isFavorite: Bool = false
    
    enum WorkoutCategory: String, CaseIterable, Codable {
        case pushPullLegs = "Push/Pull/Legs"
        case upperLower = "Upper/Lower"
        case fullBody = "Full Body"
        case cardio = "Cardio"
        case hiit = "HIIT"
        case strength = "Strength"
        case powerlifting = "Powerlifting"
        case bodybuilding = "Bodybuilding"
        case stronglifts = "StrongLifts 5x5"
    }
}

struct WorkoutExercise: Identifiable, Codable {
    let id = UUID()
    let exerciseId: UUID
    let exerciseName: String
    let sets: Int
    let reps: IntRange?
    let weight: Double?
    let duration: Int? // seconds
    let restTime: Int // seconds
    let notes: String?
    
    struct IntRange: Codable {
        let min: Int
        let max: Int
    }
}

struct WorkoutSession: Identifiable, Codable {
    let id = UUID()
    let templateId: UUID?
    let templateName: String
    let startTime: Date
    var endTime: Date?
    var completedExercises: [CompletedExercise]
    var totalCaloriesBurned: Double?
    var notes: String?
    var rating: Int? // 1-5
    
    var duration: TimeInterval {
        guard let endTime = endTime else {
            return Date().timeIntervalSince(startTime)
        }
        return endTime.timeIntervalSince(startTime)
    }
    
    var isCompleted: Bool {
        endTime != nil
    }
}

struct CompletedExercise: Identifiable, Codable {
    let id = UUID()
    let exerciseId: UUID
    let exerciseName: String
    var completedSets: [CompletedSet]
    var notes: String?
    let completedAt: Date
    
    var isCompleted: Bool {
        !completedSets.isEmpty
    }
}

struct CompletedSet: Identifiable, Codable {
    let id = UUID()
    let setNumber: Int
    var reps: Int?
    var weight: Double?
    var duration: TimeInterval? // for time-based exercises
    var restTime: TimeInterval?
    let completedAt: Date
    var isCompleted: Bool = false
}

// MARK: - Nutrition Models
struct Food: Identifiable, Codable {
    let id = UUID()
    let name: String
    let brand: String?
    let barcode: String?
    let category: FoodCategory
    let nutritionPer100g: NutritionFacts
    var isFavorite: Bool = false
    var isVerified: Bool = false
    
    enum FoodCategory: String, CaseIterable, Codable {
        case grains = "Grains"
        case vegetables = "Vegetables"
        case fruits = "Fruits"
        case meat = "Meat"
        case fish = "Fish"
        case dairy = "Dairy"
        case nuts = "Nuts & Seeds"
        case beverages = "Beverages"
        case snacks = "Snacks"
        case condiments = "Condiments"
        case supplements = "Supplements"
    }
}

struct NutritionFacts: Codable {
    let calories: Double
    let protein: Double // grams
    let carbs: Double // grams
    let fat: Double // grams
    let fiber: Double // grams
    let sugar: Double // grams
    let sodium: Double // mg
    let cholesterol: Double // mg
    let vitaminA: Double? // mcg
    let vitaminC: Double? // mg
    let calcium: Double? // mg
    let iron: Double? // mg
}

struct MealEntry: Identifiable, Codable {
    let id = UUID()
    let foodId: UUID
    let foodName: String
    let quantity: Double // grams
    let mealType: MealType
    let consumedAt: Date
    let nutritionFacts: NutritionFacts
    var notes: String?
    
    enum MealType: String, CaseIterable, Codable {
        case breakfast = "Breakfast"
        case lunch = "Lunch"
        case dinner = "Dinner"
        case snack = "Snack"
        
        var icon: String {
            switch self {
            case .breakfast: return "sunrise.fill"
            case .lunch: return "sun.max.fill"
            case .dinner: return "sunset.fill"
            case .snack: return "star.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .breakfast: return .orange
            case .lunch: return .yellow
            case .dinner: return .purple
            case .snack: return .blue
            }
        }
    }
}

struct WaterEntry: Identifiable, Codable {
    let id = UUID()
    let amount: Double // ounces
    let timestamp: Date
    var notes: String?
}

struct Recipe: Identifiable, Codable {
    let id = UUID()
    let name: String
    let description: String
    let ingredients: [RecipeIngredient]
    let instructions: [String]
    let servings: Int
    let prepTime: Int // minutes
    let cookTime: Int // minutes
    let nutritionPerServing: NutritionFacts
    let category: Food.FoodCategory
    let difficulty: Recipe.Difficulty
    let imageURL: String?
    var isFavorite: Bool = false
    var userRating: Double?
    
    enum Difficulty: String, CaseIterable, Codable {
        case easy = "Easy"
        case medium = "Medium"
        case hard = "Hard"
    }
}

struct RecipeIngredient: Identifiable, Codable {
    let id = UUID()
    let foodId: UUID
    let foodName: String
    let quantity: Double
    let unit: String
    let notes: String?
}

// MARK: - Progress Models
struct WeightEntry: Identifiable, Codable {
    let id = UUID()
    let weight: Double // lbs
    let bodyFatPercentage: Double?
    let muscleMass: Double?
    let date: Date
    var notes: String?
}

struct BodyMeasurement: Identifiable, Codable {
    let id = UUID()
    let date: Date
    var chest: Double? // inches
    var waist: Double?
    var hips: Double?
    var biceps: Double?
    var thighs: Double?
    var neck: Double?
    var shoulders: Double?
    var forearms: Double?
    var calves: Double?
    var notes: String?
}

struct ProgressPhoto: Identifiable, Codable {
    let id = UUID()
    let imageData: Data
    let angle: PhotoAngle
    let date: Date
    var notes: String?
    
    enum PhotoAngle: String, CaseIterable, Codable {
        case front = "Front"
        case side = "Side"
        case back = "Back"
        
        var icon: String {
            switch self {
            case .front: return "person.fill"
            case .side: return "person.fill"
            case .back: return "person.fill"
            }
        }
    }
}

struct PersonalRecord: Identifiable, Codable {
    let id = UUID()
    let exerciseId: UUID
    let exerciseName: String
    let recordType: RecordType
    let value: Double
    let unit: String
    let achievedAt: Date
    let workoutSessionId: UUID?
    var notes: String?
    
    enum RecordType: String, CaseIterable, Codable {
        case oneRepMax = "1 Rep Max"
        case maxVolume = "Max Volume"
        case maxReps = "Max Reps"
        case bestTime = "Best Time"
        case longestDuration = "Longest Duration"
    }
}

struct Goal: Identifiable, Codable {
    let id = UUID()
    let title: String
    let description: String
    let category: GoalCategory
    let type: GoalType
    let targetValue: Double
    let currentValue: Double
    let unit: String
    let targetDate: Date
    let createdAt: Date
    var completedAt: Date?
    var isActive: Bool = true
    var notes: String?
    
    enum GoalCategory: String, CaseIterable, Codable {
        case weight = "Weight"
        case strength = "Strength"
        case endurance = "Endurance"
        case nutrition = "Nutrition"
        case habit = "Habit"
        case body = "Body Composition"
    }
    
    enum GoalType: String, CaseIterable, Codable {
        case increase = "Increase"
        case decrease = "Decrease"
        case maintain = "Maintain"
        case achieve = "Achieve"
    }
    
    var progress: Double {
        guard targetValue != 0 else { return 0 }
        return min(currentValue / targetValue, 1.0)
    }
    
    var isCompleted: Bool {
        completedAt != nil
    }
}

// MARK: - Analytics Models
struct WorkoutStats: Codable {
    let totalWorkouts: Int
    let totalDuration: TimeInterval
    let totalCaloriesBurned: Double
    let averageWorkoutDuration: TimeInterval
    let workoutFrequency: Double // workouts per week
    let favoriteExercises: [String]
    let strengthProgress: [String: Double] // exercise name to max weight
    let period: StatsPeriod
    
    enum StatsPeriod: String, CaseIterable, Codable {
        case week = "This Week"
        case month = "This Month"
        case quarter = "3 Months"
        case year = "This Year"
        case allTime = "All Time"
    }
}

struct NutritionStats: Codable {
    let averageDailyCalories: Double
    let averageProtein: Double
    let averageCarbs: Double
    let averageFat: Double
    let averageWater: Double
    let calorieGoalAdherence: Double // percentage
    let macroBalance: MacroBalance
    let period: WorkoutStats.StatsPeriod
}

struct MacroBalance: Codable {
    let proteinPercentage: Double
    let carbsPercentage: Double
    let fatPercentage: Double
}

// MARK: - User Profile Models
struct UserProfile: Identifiable, Codable {
    let id = UUID()
    var name: String
    var email: String
    var dateOfBirth: Date?
    var gender: Gender?
    var heightInches: Double?
    var activityLevel: ActivityLevel
    var fitnessGoals: [FitnessGoal]
    var dietaryRestrictions: [DietaryRestriction]
    var preferences: UserPreferences
    let createdAt: Date
    var updatedAt: Date
    
    enum Gender: String, CaseIterable, Codable {
        case male = "Male"
        case female = "Female"
        case other = "Other"
    }
    
    enum ActivityLevel: String, CaseIterable, Codable {
        case sedentary = "Sedentary"
        case lightlyActive = "Lightly Active"
        case moderatelyActive = "Moderately Active"
        case veryActive = "Very Active"
        case extremelyActive = "Extremely Active"
        
        var multiplier: Double {
            switch self {
            case .sedentary: return 1.2
            case .lightlyActive: return 1.375
            case .moderatelyActive: return 1.55
            case .veryActive: return 1.725
            case .extremelyActive: return 1.9
            }
        }
    }
    
    enum FitnessGoal: String, CaseIterable, Codable {
        case weightLoss = "Weight Loss"
        case muscleGain = "Muscle Gain"
        case strengthGain = "Strength Gain"
        case enduranceImprovement = "Endurance"
        case generalFitness = "General Fitness"
        case bodyRecomposition = "Body Recomposition"
    }
    
    enum DietaryRestriction: String, CaseIterable, Codable {
        case vegetarian = "Vegetarian"
        case vegan = "Vegan"
        case glutenFree = "Gluten Free"
        case dairyFree = "Dairy Free"
        case keto = "Keto"
        case paleo = "Paleo"
        case lowCarb = "Low Carb"
        case lowFat = "Low Fat"
        case nutFree = "Nut Free"
    }
    
    // Calculated properties
    var age: Int? {
        guard let dateOfBirth = dateOfBirth else { return nil }
        return Calendar.current.dateComponents([.year], from: dateOfBirth, to: Date()).year
    }
    
    var bmr: Double? {
        guard let age = age,
              let heightInches = heightInches,
              let gender = gender else { return nil }
        
        // Using Mifflin-St Jeor Equation (requires current weight)
        // BMR calculation would need current weight from latest WeightEntry
        return nil
    }
}

struct UserPreferences: Codable {
    var units: UnitSystem = .imperial
    var theme: AppTheme = .system
    var notificationsEnabled: Bool = true
    var workoutReminders: Bool = true
    var mealReminders: Bool = true
    var waterReminders: Bool = true
    var healthKitSync: Bool = true
    var privateProfile: Bool = false
    
    enum UnitSystem: String, CaseIterable, Codable {
        case imperial = "Imperial"
        case metric = "Metric"
    }
    
    enum AppTheme: String, CaseIterable, Codable {
        case light = "Light"
        case dark = "Dark"
        case system = "System"
    }
}

// MARK: - Quick Stats Models
struct DashboardStats: Codable {
    let todayCalories: Double
    let calorieGoal: Double
    let waterCups: Int
    let waterGoal: Int
    let activeMinutes: Int
    let activeGoal: Int
    let steps: Int
    let stepsGoal: Int
    let workoutsThisWeek: Int
    let workoutGoal: Int
    let currentStreak: Int
    let longestStreak: Int
}

// MARK: - Helper Extensions
extension Array where Element == MealEntry {
    func caloriesForDay(_ date: Date) -> Double {
        filter { Calendar.current.isDate($0.consumedAt, inSameDayAs: date) }
            .reduce(0) { $0 + $1.nutritionFacts.calories }
    }
    
    func entriesForMealType(_ mealType: MealEntry.MealType, date: Date) -> [MealEntry] {
        filter { 
            $0.mealType == mealType && 
            Calendar.current.isDate($0.consumedAt, inSameDayAs: date)
        }
    }
}

extension Array where Element == WaterEntry {
    func totalForDay(_ date: Date) -> Double {
        filter { Calendar.current.isDate($0.timestamp, inSameDayAs: date) }
            .reduce(0) { $0 + $1.amount }
    }
}

extension Array where Element == WorkoutSession {
    func sessionsForWeek(_ date: Date = Date()) -> [WorkoutSession] {
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? date
        let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek) ?? date
        
        return filter { session in
            session.startTime >= startOfWeek && session.startTime < endOfWeek
        }
    }
}

// MARK: - Sample Data Factory
struct SampleDataFactory {
    static func createSampleExercises() -> [Exercise] {
        [
            Exercise(
                name: "Push-ups",
                category: .chest,
                muscleGroups: [.chest, .triceps, .shoulders],
                instructions: ["Start in plank position", "Lower chest to ground", "Push back up"],
                equipment: .bodyweight,
                difficulty: .beginner
            ),
            Exercise(
                name: "Squats",
                category: .legs,
                muscleGroups: [.quads, .glutes],
                instructions: ["Stand with feet shoulder-width apart", "Lower into squat position", "Return to standing"],
                equipment: .bodyweight,
                difficulty: .beginner
            ),
            Exercise(
                name: "Deadlift",
                category: .back,
                muscleGroups: [.back, .glutes, .hamstrings],
                instructions: ["Stand with feet hip-width apart", "Hinge at hips and knees", "Lift weight with straight back"],
                equipment: .barbell,
                difficulty: .intermediate
            )
        ]
    }
    
    static func createSampleFoods() -> [Food] {
        [
            Food(
                name: "Chicken Breast",
                brand: nil,
                barcode: nil,
                category: .meat,
                nutritionPer100g: NutritionFacts(
                    calories: 165,
                    protein: 31,
                    carbs: 0,
                    fat: 3.6,
                    fiber: 0,
                    sugar: 0,
                    sodium: 74,
                    cholesterol: 85
                ),
                isVerified: true
            ),
            Food(
                name: "Brown Rice",
                brand: nil,
                barcode: nil,
                category: .grains,
                nutritionPer100g: NutritionFacts(
                    calories: 123,
                    protein: 2.6,
                    carbs: 23,
                    fat: 0.9,
                    fiber: 1.8,
                    sugar: 0.4,
                    sodium: 5,
                    cholesterol: 0
                ),
                isVerified: true
            )
        ]
    }
}