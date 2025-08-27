import Foundation
import SwiftUI
import Combine
import HealthKit

@MainActor
class FitnessDataManager: ObservableObject {
    static let shared = FitnessDataManager()
    
    // MARK: - Published Properties
    @Published var exercises: [Exercise] = []
    @Published var workoutTemplates: [WorkoutTemplate] = []
    @Published var workoutSessions: [WorkoutSession] = []
    @Published var foods: [Food] = []
    @Published var mealEntries: [MealEntry] = []
    @Published var waterEntries: [WaterEntry] = []
    @Published var weightEntries: [WeightEntry] = []
    @Published var bodyMeasurements: [BodyMeasurement] = []
    @Published var progressPhotos: [ProgressPhoto] = []
    @Published var personalRecords: [PersonalRecord] = []
    @Published var goals: [Goal] = []
    @Published var userProfile: UserProfile?
    @Published var dashboardStats: DashboardStats = DashboardStats(
        todayCalories: 0,
        calorieGoal: 2000,
        waterCups: 0,
        waterGoal: 8,
        activeMinutes: 0,
        activeGoal: 30,
        steps: 0,
        stepsGoal: 10000,
        workoutsThisWeek: 0,
        workoutGoal: 3,
        currentStreak: 0,
        longestStreak: 0
    )
    
    // Current active workout session
    @Published var activeWorkoutSession: WorkoutSession?
    @Published var isWorkoutInProgress: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        loadEmptyData()  // Start with clean slate
        setupDataObservers()
    }
    
    // MARK: - HealthKit Integration
    func syncWithHealthKit(_ healthKitManager: HealthKitManager) {
        // Update dashboard stats with HealthKit data
        if healthKitManager.isAuthorized {
            dashboardStats = DashboardStats(
                todayCalories: mealEntries.caloriesForDay(Date()),
                calorieGoal: 2000,
                waterCups: Int(waterEntries.totalForDay(Date()) / 8),
                waterGoal: 8,
                activeMinutes: healthKitManager.todaysActiveMinutes,
                activeGoal: 30,
                steps: healthKitManager.todaysSteps,
                stepsGoal: 10000,
                workoutsThisWeek: workoutSessions.sessionsForWeek().filter { $0.isCompleted }.count,
                workoutGoal: 4,
                currentStreak: calculateWorkoutStreak().current,
                longestStreak: calculateWorkoutStreak().longest
            )
        }
    }
    
    // MARK: - Data Loading
    private func loadEmptyData() {
        // Start with empty data for real user
        exercises = createSampleExercises()  // Keep exercise library
        workoutTemplates = createSampleWorkoutTemplates()  // Keep templates
        foods = createBasicFoods()  // Basic food database
        
        // Empty user profile - will be set from iCloud
        userProfile = UserProfile(
            name: ProcessInfo.processInfo.hostName.replacingOccurrences(of: ".local", with: ""),
            email: "",
            dateOfBirth: nil,
            gender: .notSpecified,
            heightInches: 70,
            activityLevel: .moderatelyActive,
            fitnessGoals: [],
            dietaryRestrictions: [],
            preferences: UserPreferences(),
            createdAt: Date(),
            updatedAt: Date()
        )
        
        // Start with empty data
        mealEntries = []
        waterEntries = []
        weightEntries = []
        workoutSessions = []
        bodyMeasurements = []
        progressPhotos = []
        personalRecords = []
        goals = []
        
        updateDashboardStats()
    }
    
    private func setupDataObservers() {
        // Update dashboard stats when relevant data changes
        Publishers.CombineLatest4(
            $mealEntries,
            $waterEntries,
            $workoutSessions,
            $goals
        )
        .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
        .sink { [weak self] _, _, _, _ in
            self?.updateDashboardStats()
        }
        .store(in: &cancellables)
    }
    
    // MARK: - Dashboard Stats
    private func updateDashboardStats() {
        let today = Date()
        let calendar = Calendar.current
        
        // Today's calories
        let todayCalories = mealEntries.caloriesForDay(today)
        
        // Water intake
        let waterOunces = waterEntries.totalForDay(today)
        let waterCups = Int(waterOunces / 8) // 8 oz per cup
        
        // Weekly workouts
        let weeklyWorkouts = workoutSessions.sessionsForWeek().filter { $0.isCompleted }.count
        
        // Workout streak
        let (currentStreak, longestStreak) = calculateWorkoutStreak()
        
        dashboardStats = DashboardStats(
            todayCalories: todayCalories,
            calorieGoal: 2000,
            waterCups: waterCups,
            waterGoal: 8,
            activeMinutes: 0, // Will come from HealthKit
            activeGoal: 30,
            steps: 0, // Will come from HealthKit
            stepsGoal: 10000,
            workoutsThisWeek: weeklyWorkouts,
            workoutGoal: 4,
            currentStreak: currentStreak,
            longestStreak: longestStreak
        )
    }
    
    private func calculateWorkoutStreak() -> (current: Int, longest: Int) {
        let sortedSessions = workoutSessions
            .filter { $0.isCompleted }
            .sorted { $0.startTime > $1.startTime }
        
        var currentStreak = 0
        var longestStreak = 0
        var tempStreak = 0
        var lastDate: Date?
        
        for session in sortedSessions {
            let sessionDate = Calendar.current.startOfDay(for: session.startTime)
            
            if let lastDate = lastDate {
                let daysDiff = Calendar.current.dateComponents([.day], from: sessionDate, to: lastDate).day ?? 0
                
                if daysDiff <= 1 {
                    tempStreak += 1
                } else {
                    longestStreak = max(longestStreak, tempStreak)
                    tempStreak = 1
                }
            } else {
                tempStreak = 1
                currentStreak = tempStreak
            }
            
            lastDate = sessionDate
        }
        
        longestStreak = max(longestStreak, tempStreak)
        
        return (currentStreak, longestStreak)
    }
    
    // MARK: - Exercise Management
    func searchExercises(_ searchText: String, category: Exercise.ExerciseCategory? = nil, equipment: Exercise.Equipment? = nil) -> [Exercise] {
        var filtered = exercises
        
        if !searchText.isEmpty {
            filtered = filtered.filter { 
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.muscleGroups.contains { $0.rawValue.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        if let category = category {
            filtered = filtered.filter { $0.category == category }
        }
        
        if let equipment = equipment {
            filtered = filtered.filter { $0.equipment == equipment }
        }
        
        return filtered
    }
    
    func toggleExerciseFavorite(_ exerciseId: UUID) {
        if let index = exercises.firstIndex(where: { $0.id == exerciseId }) {
            exercises[index].isFavorite.toggle()
        }
    }
    
    // MARK: - Workout Management
    func startWorkout(template: WorkoutTemplate) {
        let session = WorkoutSession(
            id: UUID(),
            templateId: template.id,
            templateName: template.name,
            startTime: Date(),
            endTime: nil,
            completedExercises: [],
            totalCaloriesBurned: nil,
            notes: nil,
            rating: nil
        )
        
        activeWorkoutSession = session
        isWorkoutInProgress = true
    }
    
    func completeWorkout(rating: Int? = nil, notes: String? = nil) {
        guard var session = activeWorkoutSession else { return }
        
        session.endTime = Date()
        session.rating = rating
        session.notes = notes
        
        // Calculate calories burned (simplified calculation)
        session.totalCaloriesBurned = session.duration / 60 * 8 // 8 calories per minute
        
        workoutSessions.append(session)
        activeWorkoutSession = nil
        isWorkoutInProgress = false
        
        updatePersonalRecords(from: session)
        updateDashboardStats()
    }
    
    func cancelWorkout() {
        activeWorkoutSession = nil
        isWorkoutInProgress = false
    }
    
    func logExerciseSet(exerciseId: UUID, exerciseName: String, setNumber: Int, reps: Int?, weight: Double?, duration: TimeInterval?) {
        guard var session = activeWorkoutSession else { return }
        
        // Find or create completed exercise
        if let exerciseIndex = session.completedExercises.firstIndex(where: { $0.exerciseId == exerciseId }) {
            // Add set to existing exercise
            let completedSet = CompletedSet(
                id: UUID(),
                setNumber: setNumber,
                reps: reps,
                weight: weight,
                duration: duration,
                restTime: nil,
                completedAt: Date(),
                isCompleted: true
            )
            session.completedExercises[exerciseIndex].completedSets.append(completedSet)
        } else {
            // Create new completed exercise
            let completedSet = CompletedSet(
                id: UUID(),
                setNumber: 1,
                reps: reps,
                weight: weight,
                duration: duration,
                restTime: nil,
                completedAt: Date(),
                isCompleted: true
            )
            
            let completedExercise = CompletedExercise(
                id: UUID(),
                exerciseId: exerciseId,
                exerciseName: exerciseName,
                completedSets: [completedSet],
                notes: nil,
                completedAt: Date()
            )
            
            session.completedExercises.append(completedExercise)
        }
        
        activeWorkoutSession = session
    }
    
    private func updatePersonalRecords(from session: WorkoutSession) {
        for completedExercise in session.completedExercises {
            // Find max weight for 1RM
            if let maxWeight = completedExercise.completedSets.compactMap({ $0.weight }).max() {
                let existingPR = personalRecords.first { 
                    $0.exerciseId == completedExercise.exerciseId && $0.recordType == .oneRepMax 
                }
                
                if existingPR?.value ?? 0 < maxWeight {
                    let newPR = PersonalRecord(
                        id: UUID(),
                        exerciseId: completedExercise.exerciseId,
                        exerciseName: completedExercise.exerciseName,
                        recordType: .oneRepMax,
                        value: maxWeight,
                        unit: "lbs",
                        achievedAt: Date(),
                        workoutSessionId: session.id,
                        notes: nil
                    )
                    
                    // Remove old record and add new one
                    personalRecords.removeAll { 
                        $0.exerciseId == completedExercise.exerciseId && $0.recordType == .oneRepMax 
                    }
                    personalRecords.append(newPR)
                }
            }
            
            // Find max reps
            if let maxReps = completedExercise.completedSets.compactMap({ $0.reps }).max() {
                let existingPR = personalRecords.first { 
                    $0.exerciseId == completedExercise.exerciseId && $0.recordType == .maxReps 
                }
                
                if existingPR?.value ?? 0 < Double(maxReps) {
                    let newPR = PersonalRecord(
                        id: UUID(),
                        exerciseId: completedExercise.exerciseId,
                        exerciseName: completedExercise.exerciseName,
                        recordType: .maxReps,
                        value: Double(maxReps),
                        unit: "reps",
                        achievedAt: Date(),
                        workoutSessionId: session.id,
                        notes: nil
                    )
                    
                    personalRecords.removeAll { 
                        $0.exerciseId == completedExercise.exerciseId && $0.recordType == .maxReps 
                    }
                    personalRecords.append(newPR)
                }
            }
        }
    }
    
    // MARK: - Nutrition Management
    func logMeal(_ food: Food, quantity: Double, mealType: MealEntry.MealType, date: Date = Date()) {
        let adjustedNutrition = adjustNutritionForQuantity(food.nutritionPer100g, quantity: quantity)
        
        let mealEntry = MealEntry(
            id: UUID(),
            foodId: food.id,
            foodName: food.name,
            quantity: quantity,
            mealType: mealType,
            consumedAt: date,
            nutritionFacts: adjustedNutrition,
            notes: nil
        )
        
        mealEntries.append(mealEntry)
        updateDashboardStats()
    }
    
    func logWater(amount: Double, date: Date = Date()) {
        let waterEntry = WaterEntry(
            id: UUID(),
            amount: amount,
            timestamp: date,
            notes: nil
        )
        
        waterEntries.append(waterEntry)
        updateDashboardStats()
    }
    
    private func adjustNutritionForQuantity(_ nutrition: NutritionFacts, quantity: Double) -> NutritionFacts {
        let multiplier = quantity / 100.0
        
        return NutritionFacts(
            calories: nutrition.calories * multiplier,
            protein: nutrition.protein * multiplier,
            carbs: nutrition.carbs * multiplier,
            fat: nutrition.fat * multiplier,
            fiber: nutrition.fiber * multiplier,
            sugar: nutrition.sugar * multiplier,
            sodium: nutrition.sodium * multiplier,
            cholesterol: nutrition.cholesterol * multiplier,
            vitaminA: nutrition.vitaminA.map { $0 * multiplier },
            vitaminC: nutrition.vitaminC.map { $0 * multiplier },
            calcium: nutrition.calcium.map { $0 * multiplier },
            iron: nutrition.iron.map { $0 * multiplier }
        )
    }
    
    func searchFoods(_ searchText: String, category: Food.FoodCategory? = nil) -> [Food] {
        var filtered = foods
        
        if !searchText.isEmpty {
            filtered = filtered.filter { 
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                ($0.brand?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        if let category = category {
            filtered = filtered.filter { $0.category == category }
        }
        
        return filtered.sorted { $0.name < $1.name }
    }
    
    // MARK: - Progress Tracking
    func logWeight(_ weight: Double, bodyFatPercentage: Double? = nil, date: Date = Date()) {
        let weightEntry = WeightEntry(
            id: UUID(),
            weight: weight,
            bodyFatPercentage: bodyFatPercentage,
            muscleMass: nil,
            date: date,
            notes: nil
        )
        
        weightEntries.append(weightEntry)
        weightEntries.sort { $0.date < $1.date }
    }
    
    func logBodyMeasurement(_ measurement: BodyMeasurement) {
        bodyMeasurements.append(measurement)
        bodyMeasurements.sort { $0.date < $1.date }
    }
    
    // MARK: - Goals Management
    func addGoal(_ goal: Goal) {
        goals.append(goal)
    }
    
    func updateGoal(_ goal: Goal) {
        if let index = goals.firstIndex(where: { $0.id == goal.id }) {
            goals[index] = goal
        }
    }
    
    func completeGoal(_ goalId: UUID) {
        if let index = goals.firstIndex(where: { $0.id == goalId }) {
            var updatedGoal = goals[index]
            updatedGoal.completedAt = Date()
            goals[index] = updatedGoal
        }
    }
    
    // MARK: - Analytics
    func getWorkoutStats(period: WorkoutStats.StatsPeriod) -> WorkoutStats {
        let sessions = getSessionsForPeriod(period)
        let completedSessions = sessions.filter { $0.isCompleted }
        
        let totalDuration = completedSessions.reduce(0) { $0 + $1.duration }
        let totalCalories = completedSessions.compactMap { $0.totalCaloriesBurned }.reduce(0, +)
        let averageDuration = completedSessions.isEmpty ? 0 : totalDuration / Double(completedSessions.count)
        
        // Calculate workout frequency
        let periodDays = getPeriodDays(period)
        let workoutFrequency = Double(completedSessions.count) / (periodDays / 7.0)
        
        return WorkoutStats(
            totalWorkouts: completedSessions.count,
            totalDuration: totalDuration,
            totalCaloriesBurned: totalCalories,
            averageWorkoutDuration: averageDuration,
            workoutFrequency: workoutFrequency,
            favoriteExercises: getFavoriteExercises(from: completedSessions),
            strengthProgress: getStrengthProgress(from: completedSessions),
            period: period
        )
    }
    
    private func getSessionsForPeriod(_ period: WorkoutStats.StatsPeriod) -> [WorkoutSession] {
        let calendar = Calendar.current
        let now = Date()
        let startDate: Date
        
        switch period {
        case .week:
            startDate = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        case .month:
            startDate = calendar.dateInterval(of: .month, for: now)?.start ?? now
        case .quarter:
            startDate = calendar.date(byAdding: .month, value: -3, to: now) ?? now
        case .year:
            startDate = calendar.dateInterval(of: .year, for: now)?.start ?? now
        case .allTime:
            startDate = Date.distantPast
        }
        
        return workoutSessions.filter { $0.startTime >= startDate }
    }
    
    private func getPeriodDays(_ period: WorkoutStats.StatsPeriod) -> Double {
        switch period {
        case .week: return 7
        case .month: return 30
        case .quarter: return 90
        case .year: return 365
        case .allTime: return 365 * 10 // Approximate
        }
    }
    
    private func getFavoriteExercises(from sessions: [WorkoutSession]) -> [String] {
        var exerciseCount: [String: Int] = [:]
        
        for session in sessions {
            for exercise in session.completedExercises {
                exerciseCount[exercise.exerciseName, default: 0] += 1
            }
        }
        
        return exerciseCount
            .sorted { $0.value > $1.value }
            .prefix(5)
            .map { $0.key }
    }
    
    private func getStrengthProgress(from sessions: [WorkoutSession]) -> [String: Double] {
        var maxWeights: [String: Double] = [:]
        
        for session in sessions {
            for exercise in session.completedExercises {
                if let maxWeight = exercise.completedSets.compactMap({ $0.weight }).max() {
                    maxWeights[exercise.exerciseName] = max(maxWeights[exercise.exerciseName] ?? 0, maxWeight)
                }
            }
        }
        
        return maxWeights
    }
    
    // MARK: - Sample Data Creation
    private func createSampleExercises() -> [Exercise] {
        return SampleDataFactory.createSampleExercises() + [
            // Chest Exercises
            Exercise(name: "Bench Press", category: .chest, muscleGroups: [.chest, .triceps, .shoulders], instructions: ["Lie on bench", "Lower bar to chest", "Press up"], equipment: .barbell, difficulty: .intermediate),
            Exercise(name: "Incline Dumbbell Press", category: .chest, muscleGroups: [.chest, .triceps], instructions: ["Set bench to incline", "Press dumbbells up", "Lower with control"], equipment: .dumbbell, difficulty: .intermediate),
            Exercise(name: "Chest Dips", category: .chest, muscleGroups: [.chest, .triceps], instructions: ["Grip parallel bars", "Lower body", "Press back up"], equipment: .bodyweight, difficulty: .intermediate),
            Exercise(name: "Chest Flyes", category: .chest, muscleGroups: [.chest], instructions: ["Lie on bench", "Open arms wide", "Bring dumbbells together"], equipment: .dumbbell, difficulty: .beginner),
            
            // Back Exercises
            Exercise(name: "Pull-ups", category: .back, muscleGroups: [.back, .biceps], instructions: ["Hang from bar", "Pull body up", "Lower with control"], equipment: .bodyweight, difficulty: .intermediate),
            Exercise(name: "Barbell Rows", category: .back, muscleGroups: [.back, .biceps], instructions: ["Bend at hips", "Pull bar to chest", "Lower with control"], equipment: .barbell, difficulty: .intermediate),
            Exercise(name: "Lat Pulldowns", category: .back, muscleGroups: [.back, .biceps], instructions: ["Sit at machine", "Pull bar to chest", "Control the return"], equipment: .machine, difficulty: .beginner),
            Exercise(name: "T-Bar Rows", category: .back, muscleGroups: [.back, .biceps], instructions: ["Straddle bar", "Pull to chest", "Squeeze shoulder blades"], equipment: .barbell, difficulty: .intermediate),
            
            // Leg Exercises
            Exercise(name: "Squats", category: .legs, muscleGroups: [.quads, .glutes], instructions: ["Feet shoulder width", "Lower into squat", "Drive through heels"], equipment: .bodyweight, difficulty: .beginner),
            Exercise(name: "Romanian Deadlift", category: .legs, muscleGroups: [.hamstrings, .glutes], instructions: ["Hold bar", "Hinge at hips", "Drive hips forward"], equipment: .barbell, difficulty: .intermediate),
            Exercise(name: "Leg Press", category: .legs, muscleGroups: [.quads, .glutes], instructions: ["Sit in machine", "Lower weight", "Press through heels"], equipment: .machine, difficulty: .beginner),
            Exercise(name: "Walking Lunges", category: .legs, muscleGroups: [.quads, .glutes], instructions: ["Step forward", "Lower back knee", "Alternate legs"], equipment: .bodyweight, difficulty: .beginner),
            
            // Shoulder Exercises
            Exercise(name: "Overhead Press", category: .shoulders, muscleGroups: [.shoulders, .triceps], instructions: ["Bar at shoulders", "Press overhead", "Lower with control"], equipment: .barbell, difficulty: .intermediate),
            Exercise(name: "Lateral Raises", category: .shoulders, muscleGroups: [.shoulders], instructions: ["Arms at sides", "Raise to shoulder height", "Lower slowly"], equipment: .dumbbell, difficulty: .beginner),
            Exercise(name: "Face Pulls", category: .shoulders, muscleGroups: [.shoulders, .back], instructions: ["Pull cable to face", "Squeeze shoulder blades", "Return slowly"], equipment: .cable, difficulty: .beginner),
            
            // Arm Exercises
            Exercise(name: "Bicep Curls", category: .arms, muscleGroups: [.biceps], instructions: ["Arms at sides", "Curl weights up", "Lower slowly"], equipment: .dumbbell, difficulty: .beginner),
            Exercise(name: "Tricep Dips", category: .arms, muscleGroups: [.triceps], instructions: ["Hands on bench", "Lower body", "Press back up"], equipment: .bodyweight, difficulty: .beginner),
            Exercise(name: "Close Grip Push-ups", category: .arms, muscleGroups: [.triceps, .chest], instructions: ["Hands close together", "Lower chest down", "Push back up"], equipment: .bodyweight, difficulty: .intermediate),
            
            // Core Exercises
            Exercise(name: "Plank", category: .core, muscleGroups: [.abs], instructions: ["Hold plank position", "Keep body straight", "Breathe steadily"], equipment: .bodyweight, difficulty: .beginner),
            Exercise(name: "Russian Twists", category: .core, muscleGroups: [.abs, .obliques], instructions: ["Sit with knees bent", "Twist side to side", "Keep core engaged"], equipment: .bodyweight, difficulty: .beginner),
            Exercise(name: "Dead Bug", category: .core, muscleGroups: [.abs], instructions: ["Lie on back", "Opposite arm and leg", "Hold and switch"], equipment: .bodyweight, difficulty: .beginner),
            
            // Cardio Exercises
            Exercise(name: "Burpees", category: .cardio, muscleGroups: [.fullBody], instructions: ["Squat down", "Jump back to plank", "Jump up with arms overhead"], equipment: .bodyweight, difficulty: .intermediate),
            Exercise(name: "Mountain Climbers", category: .cardio, muscleGroups: [.fullBody], instructions: ["Start in plank", "Alternate bringing knees to chest", "Keep fast pace"], equipment: .bodyweight, difficulty: .beginner),
            Exercise(name: "Jumping Jacks", category: .cardio, muscleGroups: [.fullBody], instructions: ["Start feet together", "Jump feet apart with arms up", "Return to start"], equipment: .bodyweight, difficulty: .beginner)
        ]
    }
    
    private func createSampleWorkoutTemplates() -> [WorkoutTemplate] {
        [
            // Push Day Template
            WorkoutTemplate(
                name: "Push Day - Chest, Shoulders, Triceps",
                description: "Upper body push muscles workout",
                category: .pushPullLegs,
                estimatedDuration: 60,
                exercises: [
                    WorkoutExercise(exerciseId: UUID(), exerciseName: "Bench Press", sets: 4, reps: WorkoutExercise.IntRange(min: 6, max: 8), weight: 135, duration: nil, restTime: 120, notes: nil),
                    WorkoutExercise(exerciseId: UUID(), exerciseName: "Incline Dumbbell Press", sets: 3, reps: WorkoutExercise.IntRange(min: 8, max: 10), weight: 60, duration: nil, restTime: 90, notes: nil),
                    WorkoutExercise(exerciseId: UUID(), exerciseName: "Overhead Press", sets: 3, reps: WorkoutExercise.IntRange(min: 8, max: 12), weight: 85, duration: nil, restTime: 90, notes: nil),
                    WorkoutExercise(exerciseId: UUID(), exerciseName: "Lateral Raises", sets: 3, reps: WorkoutExercise.IntRange(min: 12, max: 15), weight: 20, duration: nil, restTime: 60, notes: nil),
                    WorkoutExercise(exerciseId: UUID(), exerciseName: "Tricep Dips", sets: 3, reps: WorkoutExercise.IntRange(min: 10, max: 15), weight: nil, duration: nil, restTime: 60, notes: nil)
                ],
                difficulty: .intermediate,
                equipment: [.barbell, .dumbbell, .bodyweight]
            ),
            
            // Pull Day Template
            WorkoutTemplate(
                name: "Pull Day - Back & Biceps",
                description: "Upper body pull muscles workout",
                category: .pushPullLegs,
                estimatedDuration: 60,
                exercises: [
                    WorkoutExercise(exerciseId: UUID(), exerciseName: "Deadlift", sets: 4, reps: WorkoutExercise.IntRange(min: 5, max: 6), weight: 185, duration: nil, restTime: 180, notes: nil),
                    WorkoutExercise(exerciseId: UUID(), exerciseName: "Pull-ups", sets: 4, reps: WorkoutExercise.IntRange(min: 6, max: 10), weight: nil, duration: nil, restTime: 120, notes: nil),
                    WorkoutExercise(exerciseId: UUID(), exerciseName: "Barbell Rows", sets: 3, reps: WorkoutExercise.IntRange(min: 8, max: 10), weight: 115, duration: nil, restTime: 90, notes: nil),
                    WorkoutExercise(exerciseId: UUID(), exerciseName: "Lat Pulldowns", sets: 3, reps: WorkoutExercise.IntRange(min: 10, max: 12), weight: 130, duration: nil, restTime: 90, notes: nil),
                    WorkoutExercise(exerciseId: UUID(), exerciseName: "Bicep Curls", sets: 3, reps: WorkoutExercise.IntRange(min: 12, max: 15), weight: 35, duration: nil, restTime: 60, notes: nil)
                ],
                difficulty: .intermediate,
                equipment: [.barbell, .bodyweight, .machine, .dumbbell]
            ),
            
            // Leg Day Template
            WorkoutTemplate(
                name: "Leg Day - Quads, Glutes, Hamstrings",
                description: "Complete lower body workout",
                category: .pushPullLegs,
                estimatedDuration: 75,
                exercises: [
                    WorkoutExercise(exerciseId: UUID(), exerciseName: "Squats", sets: 4, reps: WorkoutExercise.IntRange(min: 6, max: 8), weight: 155, duration: nil, restTime: 180, notes: nil),
                    WorkoutExercise(exerciseId: UUID(), exerciseName: "Romanian Deadlift", sets: 3, reps: WorkoutExercise.IntRange(min: 8, max: 10), weight: 135, duration: nil, restTime: 120, notes: nil),
                    WorkoutExercise(exerciseId: UUID(), exerciseName: "Leg Press", sets: 3, reps: WorkoutExercise.IntRange(min: 12, max: 15), weight: 270, duration: nil, restTime: 90, notes: nil),
                    WorkoutExercise(exerciseId: UUID(), exerciseName: "Walking Lunges", sets: 3, reps: WorkoutExercise.IntRange(min: 20, max: 24), weight: nil, duration: nil, restTime: 90, notes: nil)
                ],
                difficulty: .intermediate,
                equipment: [.barbell, .machine, .bodyweight]
            ),
            
            // Full Body Beginner
            WorkoutTemplate(
                name: "Full Body Beginner",
                description: "Perfect for beginners - hits all major muscle groups",
                category: .fullBody,
                estimatedDuration: 45,
                exercises: [
                    WorkoutExercise(exerciseId: UUID(), exerciseName: "Push-ups", sets: 3, reps: WorkoutExercise.IntRange(min: 8, max: 12), weight: nil, duration: nil, restTime: 60, notes: nil),
                    WorkoutExercise(exerciseId: UUID(), exerciseName: "Squats", sets: 3, reps: WorkoutExercise.IntRange(min: 12, max: 15), weight: nil, duration: nil, restTime: 60, notes: nil),
                    WorkoutExercise(exerciseId: UUID(), exerciseName: "Plank", sets: 3, reps: nil, weight: nil, duration: 30, restTime: 45, notes: nil),
                    WorkoutExercise(exerciseId: UUID(), exerciseName: "Walking Lunges", sets: 2, reps: WorkoutExercise.IntRange(min: 16, max: 20), weight: nil, duration: nil, restTime: 60, notes: nil),
                    WorkoutExercise(exerciseId: UUID(), exerciseName: "Mountain Climbers", sets: 3, reps: WorkoutExercise.IntRange(min: 20, max: 30), weight: nil, duration: nil, restTime: 45, notes: nil)
                ],
                difficulty: .beginner,
                equipment: [.bodyweight]
            ),
            
            // HIIT Cardio
            WorkoutTemplate(
                name: "HIIT Cardio Blast",
                description: "High intensity interval training for fat burning",
                category: .hiit,
                estimatedDuration: 25,
                exercises: [
                    WorkoutExercise(exerciseId: UUID(), exerciseName: "Burpees", sets: 4, reps: WorkoutExercise.IntRange(min: 10, max: 15), weight: nil, duration: nil, restTime: 30, notes: nil),
                    WorkoutExercise(exerciseId: UUID(), exerciseName: "Mountain Climbers", sets: 4, reps: WorkoutExercise.IntRange(min: 30, max: 40), weight: nil, duration: nil, restTime: 30, notes: nil),
                    WorkoutExercise(exerciseId: UUID(), exerciseName: "Jumping Jacks", sets: 4, reps: WorkoutExercise.IntRange(min: 25, max: 35), weight: nil, duration: nil, restTime: 30, notes: nil),
                    WorkoutExercise(exerciseId: UUID(), exerciseName: "Russian Twists", sets: 4, reps: WorkoutExercise.IntRange(min: 20, max: 30), weight: nil, duration: nil, restTime: 30, notes: nil)
                ],
                difficulty: .intermediate,
                equipment: [.bodyweight]
            ),
            
            // StrongLifts 5x5
            WorkoutTemplate(
                name: "StrongLifts 5x5 - Workout A",
                description: "Classic strength building program - Workout A",
                category: .stronglifts,
                estimatedDuration: 60,
                exercises: [
                    WorkoutExercise(exerciseId: UUID(), exerciseName: "Squats", sets: 5, reps: WorkoutExercise.IntRange(min: 5, max: 5), weight: 135, duration: nil, restTime: 180, notes: nil),
                    WorkoutExercise(exerciseId: UUID(), exerciseName: "Bench Press", sets: 5, reps: WorkoutExercise.IntRange(min: 5, max: 5), weight: 115, duration: nil, restTime: 180, notes: nil),
                    WorkoutExercise(exerciseId: UUID(), exerciseName: "Barbell Rows", sets: 5, reps: WorkoutExercise.IntRange(min: 5, max: 5), weight: 95, duration: nil, restTime: 180, notes: nil)
                ],
                difficulty: .intermediate,
                equipment: [.barbell]
            )
        ]
    }
    
    private func createBasicFoods() -> [Food] {
        // Just basic foods for manual entry - no sample data
        return [
            // Common proteins
            Food(name: "Chicken Breast", brand: nil, barcode: nil, category: .meat, nutritionPer100g: NutritionFacts(calories: 165, protein: 31, carbs: 0, fat: 3.6, fiber: 0, sugar: 0, sodium: 74, cholesterol: 85), isVerified: true),
            Food(name: "Eggs", brand: nil, barcode: nil, category: .meat, nutritionPer100g: NutritionFacts(calories: 155, protein: 13, carbs: 1.1, fat: 11, fiber: 0, sugar: 1.1, sodium: 124, cholesterol: 373), isVerified: true),
            // Common carbs
            Food(name: "White Rice", brand: nil, barcode: nil, category: .grains, nutritionPer100g: NutritionFacts(calories: 130, protein: 2.7, carbs: 28, fat: 0.3, fiber: 0.4, sugar: 0.1, sodium: 1, cholesterol: 0), isVerified: true),
            Food(name: "Oatmeal", brand: nil, barcode: nil, category: .grains, nutritionPer100g: NutritionFacts(calories: 389, protein: 17, carbs: 66, fat: 7, fiber: 11, sugar: 0, sodium: 2, cholesterol: 0), isVerified: true),
            // Common vegetables
            Food(name: "Broccoli", brand: nil, barcode: nil, category: .vegetables, nutritionPer100g: NutritionFacts(calories: 34, protein: 2.8, carbs: 7, fat: 0.4, fiber: 2.6, sugar: 1.5, sodium: 33, cholesterol: 0), isVerified: true)
        ]
    }
    
    private func createSampleFoods() -> [Food] {
        return SampleDataFactory.createSampleFoods() + [
            // Proteins
            Food(name: "Salmon Fillet", brand: nil, barcode: nil, category: .fish, nutritionPer100g: NutritionFacts(calories: 208, protein: 25.4, carbs: 0, fat: 12.4, fiber: 0, sugar: 0, sodium: 59, cholesterol: 59), isVerified: true),
            Food(name: "Greek Yogurt", brand: "Chobani", barcode: nil, category: .dairy, nutritionPer100g: NutritionFacts(calories: 100, protein: 17, carbs: 9, fat: 0, fiber: 0, sugar: 6, sodium: 60, cholesterol: 5), isVerified: true),
            Food(name: "Eggs", brand: nil, barcode: nil, category: .meat, nutritionPer100g: NutritionFacts(calories: 155, protein: 13, carbs: 1.1, fat: 11, fiber: 0, sugar: 1.1, sodium: 124, cholesterol: 373), isVerified: true),
            Food(name: "Whey Protein", brand: "Optimum Nutrition", barcode: nil, category: .supplements, nutritionPer100g: NutritionFacts(calories: 367, protein: 73, carbs: 7, fat: 3, fiber: 1, sugar: 3, sodium: 400, cholesterol: 73), isVerified: true),
            
            // Carbohydrates
            Food(name: "Sweet Potato", brand: nil, barcode: nil, category: .vegetables, nutritionPer100g: NutritionFacts(calories: 86, protein: 1.6, carbs: 20, fat: 0.1, fiber: 3, sugar: 4.2, sodium: 6, cholesterol: 0), isVerified: true),
            Food(name: "Oatmeal", brand: "Quaker", barcode: nil, category: .grains, nutritionPer100g: NutritionFacts(calories: 389, protein: 17, carbs: 66, fat: 7, fiber: 11, sugar: 0, sodium: 2, cholesterol: 0), isVerified: true),
            Food(name: "Banana", brand: nil, barcode: nil, category: .fruits, nutritionPer100g: NutritionFacts(calories: 89, protein: 1.1, carbs: 23, fat: 0.3, fiber: 2.6, sugar: 12, sodium: 1, cholesterol: 0), isVerified: true),
            Food(name: "White Rice", brand: nil, barcode: nil, category: .grains, nutritionPer100g: NutritionFacts(calories: 130, protein: 2.7, carbs: 28, fat: 0.3, fiber: 0.4, sugar: 0.1, sodium: 1, cholesterol: 0), isVerified: true),
            
            // Fats
            Food(name: "Avocado", brand: nil, barcode: nil, category: .fruits, nutritionPer100g: NutritionFacts(calories: 160, protein: 2, carbs: 9, fat: 15, fiber: 7, sugar: 0.7, sodium: 7, cholesterol: 0), isVerified: true),
            Food(name: "Almonds", brand: nil, barcode: nil, category: .nuts, nutritionPer100g: NutritionFacts(calories: 579, protein: 21, carbs: 22, fat: 50, fiber: 12, sugar: 4.4, sodium: 1, cholesterol: 0), isVerified: true),
            Food(name: "Olive Oil", brand: nil, barcode: nil, category: .condiments, nutritionPer100g: NutritionFacts(calories: 884, protein: 0, carbs: 0, fat: 100, fiber: 0, sugar: 0, sodium: 2, cholesterol: 0), isVerified: true),
            
            // Vegetables
            Food(name: "Broccoli", brand: nil, barcode: nil, category: .vegetables, nutritionPer100g: NutritionFacts(calories: 34, protein: 2.8, carbs: 7, fat: 0.4, fiber: 2.6, sugar: 1.5, sodium: 33, cholesterol: 0), isVerified: true),
            Food(name: "Spinach", brand: nil, barcode: nil, category: .vegetables, nutritionPer100g: NutritionFacts(calories: 23, protein: 2.9, carbs: 3.6, fat: 0.4, fiber: 2.2, sugar: 0.4, sodium: 79, cholesterol: 0), isVerified: true),
            Food(name: "Bell Peppers", brand: nil, barcode: nil, category: .vegetables, nutritionPer100g: NutritionFacts(calories: 31, protein: 1, carbs: 7, fat: 0.3, fiber: 2.5, sugar: 4.2, sodium: 4, cholesterol: 0), isVerified: true)
        ]
    }
    
    private func addSampleMealEntries() {
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today) ?? today
        
        // Today's meals
        logMeal(foods.first { $0.name == "Oatmeal" }!, quantity: 50, mealType: .breakfast, date: today)
        logMeal(foods.first { $0.name == "Banana" }!, quantity: 120, mealType: .breakfast, date: today)
        logMeal(foods.first { $0.name == "Chicken Breast" }!, quantity: 150, mealType: .lunch, date: today)
        logMeal(foods.first { $0.name == "Brown Rice" }!, quantity: 80, mealType: .lunch, date: today)
        logMeal(foods.first { $0.name == "Broccoli" }!, quantity: 100, mealType: .lunch, date: today)
        logMeal(foods.first { $0.name == "Greek Yogurt" }!, quantity: 200, mealType: .snack, date: today)
        
        // Yesterday's meals
        logMeal(foods.first { $0.name == "Eggs" }!, quantity: 150, mealType: .breakfast, date: yesterday)
        logMeal(foods.first { $0.name == "Salmon Fillet" }!, quantity: 120, mealType: .dinner, date: yesterday)
        logMeal(foods.first { $0.name == "Sweet Potato" }!, quantity: 200, mealType: .dinner, date: yesterday)
    }
    
    private func addSampleWaterEntries() {
        let today = Date()
        // Add some water entries for today
        for i in 0..<5 {
            let time = Calendar.current.date(byAdding: .hour, value: i * 2, to: Calendar.current.startOfDay(for: today))!
            logWater(amount: 8, date: time) // 8 oz per entry
        }
    }
    
    private func addSampleWeightEntries() {
        let calendar = Calendar.current
        let today = Date()
        
        // Add weight entries for the past 30 days
        for i in 0..<30 {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                let weight = 185.0 + Double.random(in: -2...2) - (Double(i) * 0.1) // Slight downward trend
                logWeight(weight, bodyFatPercentage: 15.0 + Double.random(in: -1...1), date: date)
            }
        }
    }
    
    private func addSampleWorkoutSessions() {
        let calendar = Calendar.current
        let today = Date()
        
        // Add some completed workout sessions
        for i in 1...7 {
            if let date = calendar.date(byAdding: .day, value: -i * 2, to: today) {
                let template = workoutTemplates.randomElement()!
                
                var session = WorkoutSession(
                    id: UUID(),
                    templateId: template.id,
                    templateName: template.name,
                    startTime: date,
                    endTime: calendar.date(byAdding: .minute, value: template.estimatedDuration, to: date),
                    completedExercises: [],
                    totalCaloriesBurned: Double(template.estimatedDuration) * 0.15, // Rough estimate
                    notes: nil,
                    rating: Int.random(in: 3...5)
                )
                
                // Add some completed exercises
                for exercise in template.exercises.prefix(3) {
                    let completedSets = (1...exercise.sets).map { setNumber in
                        CompletedSet(
                            id: UUID(),
                            setNumber: setNumber,
                            reps: exercise.reps?.min ?? 10,
                            weight: exercise.weight,
                            duration: exercise.duration.map { TimeInterval($0) },
                            restTime: TimeInterval(exercise.restTime),
                            completedAt: date,
                            isCompleted: true
                        )
                    }
                    
                    let completedExercise = CompletedExercise(
                        id: UUID(),
                        exerciseId: exercise.exerciseId,
                        exerciseName: exercise.exerciseName,
                        completedSets: completedSets,
                        notes: nil,
                        completedAt: date
                    )
                    
                    session.completedExercises.append(completedExercise)
                }
                
                workoutSessions.append(session)
            }
        }
    }
    
    private func addSampleGoals() {
        let goals = [
            Goal(
                id: UUID(),
                title: "Lose 10 pounds",
                description: "Reach target weight of 175 lbs",
                category: .weight,
                type: .decrease,
                targetValue: 175,
                currentValue: 185,
                unit: "lbs",
                targetDate: Calendar.current.date(byAdding: .month, value: 3, to: Date())!,
                createdAt: Date(),
                completedAt: nil,
                isActive: true,
                notes: "Focus on consistent calorie deficit and regular exercise"
            ),
            Goal(
                id: UUID(),
                title: "Bench Press 200 lbs",
                description: "Increase bench press 1RM to 200 lbs",
                category: .strength,
                type: .increase,
                targetValue: 200,
                currentValue: 155,
                unit: "lbs",
                targetDate: Calendar.current.date(byAdding: .month, value: 6, to: Date())!,
                createdAt: Date(),
                completedAt: nil,
                isActive: true,
                notes: "Progressive overload with proper form"
            ),
            Goal(
                id: UUID(),
                title: "Workout 4x per week",
                description: "Maintain consistent workout schedule",
                category: .habit,
                type: .achieve,
                targetValue: 4,
                currentValue: 3,
                unit: "workouts/week",
                targetDate: Calendar.current.date(byAdding: .month, value: 1, to: Date())!,
                createdAt: Date(),
                completedAt: nil,
                isActive: true,
                notes: "Schedule workouts in advance"
            )
        ]
        
        self.goals = goals
    }
}