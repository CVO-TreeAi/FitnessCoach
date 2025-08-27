import Foundation
import SwiftUI

class SimpleDataManager: ObservableObject {
    @Published var workouts: [WorkoutData] = []
    @Published var meals: [MealData] = []
    @Published var waterIntake: Int = 0
    @Published var currentWeight: Double = 185.0
    @Published var goals: [GoalData] = []
    
    init() {
        loadSampleData()
    }
    
    struct WorkoutData: Identifiable {
        let id = UUID()
        let name: String
        let category: String
        let duration: Int
        let exercises: [(name: String, sets: Int, reps: Int, rest: Int)]
        let date: Date
        var isCompleted: Bool
    }
    
    struct MealData: Identifiable {
        let id = UUID()
        let name: String
        let calories: Int
        let mealType: String
        let date: Date
    }
    
    struct GoalData: Identifiable {
        let id = UUID()
        let type: String
        let targetValue: Double
        let targetDate: Date
        let notes: String
        var progress: Double
    }
    
    func addWorkout(name: String, category: String, duration: Int, exercises: [(name: String, sets: Int, reps: Int, rest: Int)]) {
        let workout = WorkoutData(
            name: name,
            category: category,
            duration: duration,
            exercises: exercises,
            date: Date(),
            isCompleted: false
        )
        workouts.append(workout)
    }
    
    func addMeal(name: String, calories: Int, mealType: String) {
        let meal = MealData(
            name: name,
            calories: calories,
            mealType: mealType,
            date: Date()
        )
        meals.append(meal)
    }
    
    func updateWeight(_ weight: Double) {
        currentWeight = weight
    }
    
    func updateWaterIntake(_ cups: Int) {
        waterIntake = cups
    }
    
    func addGoal(type: String, targetValue: Double, targetDate: Date, notes: String) {
        let goal = GoalData(
            type: type,
            targetValue: targetValue,
            targetDate: targetDate,
            notes: notes,
            progress: 0
        )
        goals.append(goal)
    }
    
    var todaysMeals: [MealData] {
        let calendar = Calendar.current
        return meals.filter { calendar.isDateInToday($0.date) }
    }
    
    var todaysCalories: Int {
        return todaysMeals.reduce(0) { $0 + $1.calories }
    }
    
    var weeklyWorkouts: Int {
        let calendar = Calendar.current
        let oneWeekAgo = calendar.date(byAdding: .weekOfYear, value: -1, to: Date())!
        return workouts.filter { $0.date > oneWeekAgo && $0.isCompleted }.count
    }
    
    var activeGoals: [GoalData] {
        return goals.filter { $0.targetDate > Date() }
    }
    
    func loadSampleData() {
        // Sample workouts
        workouts = [
            WorkoutData(
                name: "Morning Routine",
                category: "Full Body",
                duration: 45,
                exercises: [
                    ("Push-ups", 3, 15, 60),
                    ("Squats", 3, 20, 60),
                    ("Plank", 3, 45, 30)
                ],
                date: Date(),
                isCompleted: false
            ),
            WorkoutData(
                name: "Upper Body Strength",
                category: "Strength",
                duration: 60,
                exercises: [
                    ("Bench Press", 4, 10, 90),
                    ("Pull-ups", 3, 8, 60),
                    ("Shoulder Press", 3, 12, 60)
                ],
                date: Date().addingTimeInterval(-86400),
                isCompleted: true
            ),
            WorkoutData(
                name: "HIIT Cardio",
                category: "Cardio",
                duration: 30,
                exercises: [
                    ("Burpees", 4, 10, 30),
                    ("Mountain Climbers", 4, 20, 30),
                    ("Jump Squats", 4, 15, 30)
                ],
                date: Date().addingTimeInterval(-172800),
                isCompleted: true
            )
        ]
        
        // Sample meals
        meals = [
            MealData(name: "Oatmeal with Berries", calories: 320, mealType: "Breakfast", date: Date()),
            MealData(name: "Grilled Chicken Salad", calories: 450, mealType: "Lunch", date: Date()),
            MealData(name: "Protein Shake", calories: 200, mealType: "Snacks", date: Date())
        ]
        
        // Sample goals
        goals = [
            GoalData(
                type: "Weight Loss",
                targetValue: 10,
                targetDate: Date().addingTimeInterval(60 * 24 * 60 * 60),
                notes: "Lose 10 pounds in 2 months",
                progress: 3.5
            ),
            GoalData(
                type: "Running Distance",
                targetValue: 10,
                targetDate: Date().addingTimeInterval(30 * 24 * 60 * 60),
                notes: "Run 10km without stopping",
                progress: 6.2
            )
        ]
        
        // Set initial values
        waterIntake = 5
        currentWeight = 185.0
    }
}

// Make DataManager typealias for compatibility
typealias DataManager = SimpleDataManager