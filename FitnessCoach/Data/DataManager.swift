import Foundation
import CoreData

class DataManager: ObservableObject {
    static let shared = DataManager()
    
    // Published properties for UI updates
    @Published var workouts: [WorkoutData] = []
    @Published var meals: [MealData] = []
    @Published var waterIntake: Int = 0
    @Published var currentWeight: Double = 0
    @Published var goals: [GoalData] = []
    @Published var exercises: [ExerciseData] = []
    
    private let userDefaults = UserDefaults.standard
    
    private init() {
        loadData()
    }
    
    // MARK: - Data Models
    
    struct WorkoutData: Identifiable, Codable {
        let id = UUID()
        let name: String
        let category: String
        let duration: Int
        let exercises: [(name: String, sets: Int, reps: Int, rest: Int)]
        let date: Date
        var isCompleted: Bool
    }
    
    struct MealData: Identifiable, Codable {
        let id = UUID()
        let name: String
        let calories: Int
        let mealType: String
        let date: Date
    }
    
    struct GoalData: Identifiable, Codable {
        let id = UUID()
        let type: String
        let targetValue: Double
        let targetDate: Date
        let notes: String
        var progress: Double
    }
    
    struct ExerciseData: Identifiable, Codable {
        let id = UUID()
        let name: String
        let sets: Int
        let reps: Int
        let weight: Double?
        let date: Date
    }
    
    // MARK: - Load/Save Methods
    
    private func loadData() {
        // Load from UserDefaults
        if let workoutData = userDefaults.data(forKey: "workouts"),
           let decoded = try? JSONDecoder().decode([WorkoutData].self, from: workoutData) {
            workouts = decoded
        }
        
        if let mealData = userDefaults.data(forKey: "meals"),
           let decoded = try? JSONDecoder().decode([MealData].self, from: mealData) {
            meals = decoded
        }
        
        waterIntake = userDefaults.integer(forKey: "waterIntake")
        currentWeight = userDefaults.double(forKey: "currentWeight")
        
        if let goalData = userDefaults.data(forKey: "goals"),
           let decoded = try? JSONDecoder().decode([GoalData].self, from: goalData) {
            goals = decoded
        }
    }
    
    private func saveWorkouts() {
        if let encoded = try? JSONEncoder().encode(workouts) {
            userDefaults.set(encoded, forKey: "workouts")
        }
    }
    
    private func saveMeals() {
        if let encoded = try? JSONEncoder().encode(meals) {
            userDefaults.set(encoded, forKey: "meals")
        }
    }
    
    private func saveGoals() {
        if let encoded = try? JSONEncoder().encode(goals) {
            userDefaults.set(encoded, forKey: "goals")
        }
    }
    
    // MARK: - Public Methods
    
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
        saveWorkouts()
    }
    
    func completeWorkout(id: UUID) {
        if let index = workouts.firstIndex(where: { $0.id == id }) {
            workouts[index].isCompleted = true
            saveWorkouts()
        }
    }
    
    func addMeal(name: String, calories: Int, mealType: String) {
        let meal = MealData(
            name: name,
            calories: calories,
            mealType: mealType,
            date: Date()
        )
        meals.append(meal)
        saveMeals()
    }
    
    func updateWeight(_ weight: Double) {
        currentWeight = weight
        userDefaults.set(weight, forKey: "currentWeight")
    }
    
    func updateWaterIntake(_ cups: Int) {
        waterIntake = cups
        userDefaults.set(cups, forKey: "waterIntake")
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
        saveGoals()
    }
    
    func updateGoalProgress(id: UUID, progress: Double) {
        if let index = goals.firstIndex(where: { $0.id == id }) {
            goals[index].progress = progress
            saveGoals()
        }
    }
    
    // MARK: - Computed Properties
    
    var todaysMeals: [MealData] {
        let calendar = Calendar.current
        let today = Date()
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
    
    // MARK: - Sample Data
    
    func loadSampleData() {
        // Add sample workouts
        addWorkout(
            name: "Morning Routine",
            category: "Full Body",
            duration: 45,
            exercises: [
                ("Push-ups", 3, 15, 60),
                ("Squats", 3, 20, 60),
                ("Plank", 3, 45, 30)
            ]
        )
        
        // Add sample meals
        addMeal(name: "Oatmeal with Berries", calories: 320, mealType: "Breakfast")
        addMeal(name: "Grilled Chicken Salad", calories: 450, mealType: "Lunch")
        
        // Add sample goals
        addGoal(
            type: "Weight Loss",
            targetValue: 10,
            targetDate: Date().addingTimeInterval(60 * 24 * 60 * 60),
            notes: "Lose 10 pounds in 2 months"
        )
        
        // Set sample weight and water
        updateWeight(185)
        updateWaterIntake(5)
    }
    
    // MARK: - Reset Methods
    
    func resetDailyData() {
        // Reset water intake daily
        waterIntake = 0
        userDefaults.set(0, forKey: "waterIntake")
        
        // Clean up old data (older than 30 days)
        let thirtyDaysAgo = Date().addingTimeInterval(-30 * 24 * 60 * 60)
        meals = meals.filter { $0.date > thirtyDaysAgo }
        workouts = workouts.filter { $0.date > thirtyDaysAgo }
        saveMeals()
        saveWorkouts()
    }
    
    func clearAllData() {
        workouts = []
        meals = []
        goals = []
        waterIntake = 0
        currentWeight = 0
        
        userDefaults.removeObject(forKey: "workouts")
        userDefaults.removeObject(forKey: "meals")
        userDefaults.removeObject(forKey: "goals")
        userDefaults.removeObject(forKey: "waterIntake")
        userDefaults.removeObject(forKey: "currentWeight")
    }
}