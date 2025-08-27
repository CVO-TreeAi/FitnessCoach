import Foundation
import Combine

@MainActor
public class WorkoutBuilderViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published public var workoutName: String = ""
    @Published public var workoutDescription: String = ""
    @Published public var selectedCategory: WorkoutCategory = .strength
    @Published public var selectedDifficulty: String = "Beginner"
    @Published public var estimatedDuration: Double = 45
    @Published public var workoutExercises: [WorkoutExerciseModel] = []
    @Published public var isPublic: Bool = false
    @Published public var useRestTimer: Bool = true
    @Published public var defaultRestTime: Double = 60
    @Published public var tagsText: String = ""
    @Published public var showExerciseSelection: Bool = false
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String?
    
    // MARK: - Properties
    public let isEditing: Bool
    public let workoutToEdit: WorkoutTemplateModel?
    
    private let coreDataManager = CoreDataManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    
    public var canSave: Bool {
        !workoutName.isEmpty && !workoutExercises.isEmpty
    }
    
    public var tags: [String] {
        tagsText.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
    }
    
    // MARK: - Initialization
    
    public init(workoutToEdit: WorkoutTemplateModel? = nil) {
        self.workoutToEdit = workoutToEdit
        self.isEditing = workoutToEdit != nil
        
        if let workout = workoutToEdit {
            loadExistingWorkout(workout)
        }
        
        setupSubscriptions()
    }
    
    // MARK: - Public Methods
    
    public func loadData() async {
        // Load any additional data needed for workout creation
        isLoading = true
        
        // Load exercises if needed
        // For now, this is handled by the exercise selection view
        
        isLoading = false
    }
    
    public func addExercises(_ exercises: [ExerciseModel]) {
        let newWorkoutExercises = exercises.map { exercise in
            WorkoutExerciseModel(
                id: UUID().uuidString,
                exerciseId: exercise.id,
                name: exercise.name,
                sets: getDefaultSets(for: exercise),
                reps: getDefaultReps(for: exercise),
                weight: 0,
                duration: getDefaultDuration(for: exercise),
                restTime: Int(defaultRestTime),
                notes: ""
            )
        }
        
        workoutExercises.append(contentsOf: newWorkoutExercises)
    }
    
    public func editExercise(at index: Int) {
        guard index < workoutExercises.count else { return }
        // This would typically show an edit sheet
        // For now, we'll just update some default values
        workoutExercises[index].sets = max(1, workoutExercises[index].sets)
        workoutExercises[index].reps = max(1, workoutExercises[index].reps)
    }
    
    public func removeExercise(at index: Int) {
        guard index < workoutExercises.count else { return }
        workoutExercises.remove(at: index)
    }
    
    public func moveExercise(from sourceIndex: Int, to destinationIndex: Int) {
        guard sourceIndex < workoutExercises.count && destinationIndex < workoutExercises.count else { return }
        let exercise = workoutExercises.remove(at: sourceIndex)
        workoutExercises.insert(exercise, at: destinationIndex)
    }
    
    public func saveWorkout() async {
        isLoading = true
        errorMessage = nil
        
        do {
            if isEditing {
                try await updateWorkout()
            } else {
                try await createWorkout()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Private Methods
    
    private func setupSubscriptions() {
        // Auto-calculate estimated duration based on exercises
        $workoutExercises
            .sink { [weak self] exercises in
                self?.updateEstimatedDuration(for: exercises)
            }
            .store(in: &cancellables)
    }
    
    private func loadExistingWorkout(_ workout: WorkoutTemplateModel) {
        workoutName = workout.name
        workoutDescription = workout.description ?? ""
        selectedCategory = WorkoutCategory(rawValue: workout.category.lowercased()) ?? .strength
        selectedDifficulty = workout.difficulty
        estimatedDuration = Double(workout.estimatedDuration)
        isPublic = workout.isPublic
        tagsText = workout.tags.joined(separator: ", ")
        
        // Load existing exercises
        // For now, we'll create mock exercises since we don't have the full relationship
        workoutExercises = generateMockExercisesForWorkout(workout)
    }
    
    private func createWorkout() async throws {
        let context = coreDataManager.context
        let workout = WorkoutTemplate(context: context)
        
        workout.id = UUID()
        workout.name = workoutName
        workout.desc = workoutDescription.isEmpty ? nil : workoutDescription
        workout.category = selectedCategory.rawValue
        workout.difficulty = selectedDifficulty
        workout.estimatedDuration = Int16(estimatedDuration)
        workout.isPublic = isPublic
        workout.tags = tags
        workout.createdAt = Date()
        
        // Create workout exercises
        for (index, exerciseModel) in workoutExercises.enumerated() {
            let workoutExercise = WorkoutExercise(context: context)
            workoutExercise.id = UUID()
            workoutExercise.orderIndex = Int16(index)
            workoutExercise.sets = Int16(exerciseModel.sets)
            workoutExercise.reps = Int16(exerciseModel.reps)
            workoutExercise.weight = exerciseModel.weight
            workoutExercise.duration = Int16(exerciseModel.duration)
            workoutExercise.restTime = Int16(exerciseModel.restTime)
            workoutExercise.notes = exerciseModel.notes.isEmpty ? nil : exerciseModel.notes
            workoutExercise.workoutTemplate = workout
            
            // Link to exercise (this would require finding the exercise by ID)
            // For now, we'll create this relationship later
        }
        
        coreDataManager.save()
    }
    
    private func updateWorkout() async throws {
        guard let workoutToEdit = workoutToEdit else { return }
        
        // Find existing workout in Core Data and update it
        let context = coreDataManager.context
        let request = WorkoutTemplate.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", UUID(uuidString: workoutToEdit.id)! as CVarArg)
        
        guard let existingWorkout = try context.fetch(request).first else {
            throw WorkoutBuilderError.workoutNotFound
        }
        
        existingWorkout.name = workoutName
        existingWorkout.desc = workoutDescription.isEmpty ? nil : workoutDescription
        existingWorkout.category = selectedCategory.rawValue
        existingWorkout.difficulty = selectedDifficulty
        existingWorkout.estimatedDuration = Int16(estimatedDuration)
        existingWorkout.isPublic = isPublic
        existingWorkout.tags = tags
        
        // Update exercises (simplified - in real app, would need more sophisticated merging)
        // For now, just save the changes
        coreDataManager.save()
    }
    
    private func updateEstimatedDuration(for exercises: [WorkoutExerciseModel]) {
        // Calculate estimated duration based on exercises
        var totalTime = 0
        
        for exercise in exercises {
            // Add time for sets and reps (assuming 2 seconds per rep)
            totalTime += exercise.sets * exercise.reps * 2
            
            // Add time for duration-based exercises
            totalTime += exercise.duration
            
            // Add rest time
            totalTime += exercise.restTime * (exercise.sets - 1)
        }
        
        // Convert to minutes and round up
        let estimatedMinutes = max(10, Int(ceil(Double(totalTime) / 60.0)))
        
        // Only update if significantly different to avoid constant changes
        if abs(Int(estimatedDuration) - estimatedMinutes) > 5 {
            estimatedDuration = Double(estimatedMinutes)
        }
    }
    
    private func getDefaultSets(for exercise: ExerciseModel) -> Int {
        switch exercise.category.lowercased() {
        case "strength", "chest", "back", "shoulders", "arms", "legs":
            return 3
        case "core":
            return 3
        case "cardio", "hiit":
            return 1
        default:
            return 3
        }
    }
    
    private func getDefaultReps(for exercise: ExerciseModel) -> Int {
        switch exercise.category.lowercased() {
        case "strength", "chest", "back", "shoulders", "arms", "legs":
            switch exercise.difficulty.lowercased() {
            case "beginner": return 12
            case "intermediate": return 10
            case "advanced": return 8
            default: return 10
            }
        case "core":
            return 15
        case "cardio", "hiit":
            return 0 // Duration-based
        default:
            return 10
        }
    }
    
    private func getDefaultDuration(for exercise: ExerciseModel) -> Int {
        switch exercise.category.lowercased() {
        case "core":
            return exercise.name.lowercased().contains("plank") ? 30 : 0
        case "cardio", "hiit":
            return 45
        default:
            return 0
        }
    }
    
    private func generateMockExercisesForWorkout(_ workout: WorkoutTemplateModel) -> [WorkoutExerciseModel] {
        // Generate mock exercises based on workout type
        switch workout.category.lowercased() {
        case "strength":
            return [
                WorkoutExerciseModel(
                    id: UUID().uuidString,
                    exerciseId: UUID().uuidString,
                    name: "Bench Press",
                    sets: 3,
                    reps: 10,
                    weight: 0,
                    duration: 0,
                    restTime: 60,
                    notes: ""
                ),
                WorkoutExerciseModel(
                    id: UUID().uuidString,
                    exerciseId: UUID().uuidString,
                    name: "Squats",
                    sets: 3,
                    reps: 12,
                    weight: 0,
                    duration: 0,
                    restTime: 60,
                    notes: ""
                ),
                WorkoutExerciseModel(
                    id: UUID().uuidString,
                    exerciseId: UUID().uuidString,
                    name: "Deadlifts",
                    sets: 3,
                    reps: 8,
                    weight: 0,
                    duration: 0,
                    restTime: 90,
                    notes: ""
                )
            ]
        default:
            return []
        }
    }
}

// MARK: - Data Models

public struct WorkoutExerciseModel: Identifiable, Hashable {
    public let id: String
    public let exerciseId: String
    public let name: String
    public var sets: Int
    public var reps: Int
    public var weight: Double
    public var duration: Int
    public var restTime: Int
    public var notes: String
    
    public init(
        id: String,
        exerciseId: String,
        name: String,
        sets: Int,
        reps: Int,
        weight: Double,
        duration: Int,
        restTime: Int,
        notes: String
    ) {
        self.id = id
        self.exerciseId = exerciseId
        self.name = name
        self.sets = sets
        self.reps = reps
        self.weight = weight
        self.duration = duration
        self.restTime = restTime
        self.notes = notes
    }
}

// MARK: - Errors

public enum WorkoutBuilderError: Error, LocalizedError {
    case workoutNotFound
    case invalidData
    case saveFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .workoutNotFound:
            return "Workout not found"
        case .invalidData:
            return "Invalid workout data"
        case .saveFailed(let message):
            return "Failed to save workout: \(message)"
        }
    }
}