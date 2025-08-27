import Foundation
import Combine

@MainActor
public class ExerciseLibraryViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published public var exercises: [ExerciseModel] = []
    @Published public var searchText: String = ""
    @Published public var selectedCategory: ExerciseCategory?
    @Published public var selectedDifficulty: ExerciseDifficulty?
    @Published public var selectedEquipment: Equipment?
    @Published public var selectedMuscleGroup: MuscleGroup?
    @Published public var sortBy: ExerciseSortOption = .name
    @Published public var isLoading: Bool = true
    @Published public var selectedExercise: ExerciseModel?
    
    // MARK: - Dependencies
    private let coreDataManager = CoreDataManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    public init() {
        setupSubscriptions()
    }
    
    // MARK: - Computed Properties
    
    public var filteredExercises: [ExerciseModel] {
        var filtered = exercises
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { exercise in
                exercise.name.localizedCaseInsensitiveContains(searchText) ||
                exercise.muscleGroups.contains { $0.localizedCaseInsensitiveContains(searchText) } ||
                exercise.equipment.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        // Filter by category
        if let selectedCategory = selectedCategory {
            filtered = filtered.filter { $0.category == selectedCategory.rawValue }
        }
        
        // Filter by difficulty
        if let selectedDifficulty = selectedDifficulty {
            filtered = filtered.filter { $0.difficulty == selectedDifficulty.rawValue }
        }
        
        // Filter by equipment
        if let selectedEquipment = selectedEquipment {
            filtered = filtered.filter { exercise in
                exercise.equipment.contains(selectedEquipment.rawValue)
            }
        }
        
        // Filter by muscle group
        if let selectedMuscleGroup = selectedMuscleGroup {
            filtered = filtered.filter { exercise in
                exercise.muscleGroups.contains(selectedMuscleGroup.rawValue)
            }
        }
        
        // Sort exercises
        return sortedExercises(filtered)
    }
    
    // MARK: - Public Methods
    
    public func loadExercises() async {
        isLoading = true
        
        let coreDataExercises = coreDataManager.fetchExercises()
        exercises = coreDataExercises.map { exercise in
            ExerciseModel(
                id: exercise.id?.uuidString ?? UUID().uuidString,
                name: exercise.name ?? "Unknown Exercise",
                category: exercise.category ?? "General",
                muscleGroups: exercise.muscleGroups ?? [],
                equipment: exercise.equipment ?? [],
                instructions: exercise.instructions,
                difficulty: exercise.difficulty ?? "Beginner",
                videoURL: exercise.videoURL,
                imageURL: exercise.imageURL,
                isCustom: exercise.isCustom,
                isFavorite: false // This would come from user preferences
            )
        }
        
        // If no exercises exist, seed some sample data
        if exercises.isEmpty {
            exercises = generateSampleExercises()
        }
        
        isLoading = false
    }
    
    public func clearFilters() {
        searchText = ""
        selectedCategory = nil
        selectedDifficulty = nil
        selectedEquipment = nil
        selectedMuscleGroup = nil
        sortBy = .name
    }
    
    public func toggleFavorite(_ exercise: ExerciseModel) {
        if let index = exercises.firstIndex(where: { $0.id == exercise.id }) {
            exercises[index].isFavorite.toggle()
            // Save favorite status to persistent storage
            saveFavoriteStatus(exerciseId: exercise.id, isFavorite: exercises[index].isFavorite)
        }
    }
    
    // MARK: - Private Methods
    
    private func setupSubscriptions() {
        // React to search text changes with debouncing
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
        
        // React to filter changes
        Publishers.CombineLatest4(
            $selectedCategory,
            $selectedDifficulty,
            $selectedEquipment,
            $selectedMuscleGroup
        )
        .sink { [weak self] _, _, _, _ in
            self?.objectWillChange.send()
        }
        .store(in: &cancellables)
        
        // React to sort option changes
        $sortBy
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    private func sortedExercises(_ exercises: [ExerciseModel]) -> [ExerciseModel] {
        switch sortBy {
        case .name:
            return exercises.sorted { $0.name < $1.name }
        case .category:
            return exercises.sorted { $0.category < $1.category }
        case .difficulty:
            return exercises.sorted { difficultyOrder($0.difficulty) < difficultyOrder($1.difficulty) }
        case .muscleGroup:
            return exercises.sorted { $0.muscleGroups.first ?? "" < $1.muscleGroups.first ?? "" }
        }
    }
    
    private func difficultyOrder(_ difficulty: String) -> Int {
        switch difficulty.lowercased() {
        case "beginner": return 0
        case "intermediate": return 1
        case "advanced": return 2
        default: return 0
        }
    }
    
    private func saveFavoriteStatus(exerciseId: String, isFavorite: Bool) {
        // Save to UserDefaults for now - in a real app, this would be saved to CoreData
        UserDefaults.standard.set(isFavorite, forKey: "exercise_favorite_\(exerciseId)")
    }
    
    private func loadFavoriteStatus(exerciseId: String) -> Bool {
        return UserDefaults.standard.bool(forKey: "exercise_favorite_\(exerciseId)")
    }
    
    private func generateSampleExercises() -> [ExerciseModel] {
        return [
            ExerciseModel(
                id: UUID().uuidString,
                name: "Push-ups",
                category: "Chest",
                muscleGroups: ["Chest", "Shoulders", "Triceps"],
                equipment: ["Bodyweight"],
                instructions: "Start in a plank position with hands slightly wider than shoulders. Lower body until chest nearly touches the floor, then push back up.",
                difficulty: "Beginner",
                videoURL: nil,
                imageURL: nil,
                isCustom: false,
                isFavorite: false
            ),
            ExerciseModel(
                id: UUID().uuidString,
                name: "Squats",
                category: "Legs",
                muscleGroups: ["Quadriceps", "Glutes", "Hamstrings"],
                equipment: ["Bodyweight"],
                instructions: "Stand with feet shoulder-width apart. Lower body by bending knees and hips, keeping chest up. Return to starting position.",
                difficulty: "Beginner",
                videoURL: nil,
                imageURL: nil,
                isCustom: false,
                isFavorite: false
            ),
            ExerciseModel(
                id: UUID().uuidString,
                name: "Deadlifts",
                category: "Back",
                muscleGroups: ["Back", "Glutes", "Hamstrings"],
                equipment: ["Barbell"],
                instructions: "Stand with feet hip-width apart, bar over midfoot. Bend at hips and knees to grab bar. Lift by extending hips and knees simultaneously.",
                difficulty: "Advanced",
                videoURL: nil,
                imageURL: nil,
                isCustom: false,
                isFavorite: false
            ),
            ExerciseModel(
                id: UUID().uuidString,
                name: "Pull-ups",
                category: "Back",
                muscleGroups: ["Back", "Biceps"],
                equipment: ["Pull-up Bar"],
                instructions: "Hang from bar with palms facing away. Pull body up until chin clears bar. Lower with control.",
                difficulty: "Intermediate",
                videoURL: nil,
                imageURL: nil,
                isCustom: false,
                isFavorite: false
            ),
            ExerciseModel(
                id: UUID().uuidString,
                name: "Plank",
                category: "Core",
                muscleGroups: ["Core", "Shoulders"],
                equipment: ["Bodyweight"],
                instructions: "Hold a straight body position supported on forearms and toes. Keep core tight and maintain neutral spine.",
                difficulty: "Beginner",
                videoURL: nil,
                imageURL: nil,
                isCustom: false,
                isFavorite: false
            ),
            ExerciseModel(
                id: UUID().uuidString,
                name: "Bench Press",
                category: "Chest",
                muscleGroups: ["Chest", "Shoulders", "Triceps"],
                equipment: ["Barbell", "Bench"],
                instructions: "Lie on bench with feet flat on floor. Grip bar wider than shoulders. Lower to chest, then press up.",
                difficulty: "Intermediate",
                videoURL: nil,
                imageURL: nil,
                isCustom: false,
                isFavorite: false
            ),
            ExerciseModel(
                id: UUID().uuidString,
                name: "Burpees",
                category: "Full Body",
                muscleGroups: ["Full Body"],
                equipment: ["Bodyweight"],
                instructions: "Start standing. Drop to squat, kick feet back to plank, do push-up, jump feet in, jump up with arms overhead.",
                difficulty: "Intermediate",
                videoURL: nil,
                imageURL: nil,
                isCustom: false,
                isFavorite: false
            ),
            ExerciseModel(
                id: UUID().uuidString,
                name: "Dumbbell Rows",
                category: "Back",
                muscleGroups: ["Back", "Biceps"],
                equipment: ["Dumbbells"],
                instructions: "Hinge at hips with dumbbell in one hand. Pull elbow back, squeezing shoulder blade. Lower with control.",
                difficulty: "Beginner",
                videoURL: nil,
                imageURL: nil,
                isCustom: false,
                isFavorite: false
            ),
            ExerciseModel(
                id: UUID().uuidString,
                name: "Mountain Climbers",
                category: "Cardio",
                muscleGroups: ["Core", "Shoulders", "Legs"],
                equipment: ["Bodyweight"],
                instructions: "Start in plank position. Alternate bringing knees to chest rapidly while maintaining plank position.",
                difficulty: "Intermediate",
                videoURL: nil,
                imageURL: nil,
                isCustom: false,
                isFavorite: false
            ),
            ExerciseModel(
                id: UUID().uuidString,
                name: "Lunges",
                category: "Legs",
                muscleGroups: ["Quadriceps", "Glutes", "Hamstrings"],
                equipment: ["Bodyweight"],
                instructions: "Step forward into lunge position. Lower back knee toward floor. Push back to starting position.",
                difficulty: "Beginner",
                videoURL: nil,
                imageURL: nil,
                isCustom: false,
                isFavorite: false
            )
        ]
    }
}

// MARK: - Data Models

public struct ExerciseModel: Identifiable, Hashable {
    public let id: String
    public let name: String
    public let category: String
    public let muscleGroups: [String]
    public let equipment: [String]
    public let instructions: String?
    public let difficulty: String
    public let videoURL: String?
    public let imageURL: String?
    public let isCustom: Bool
    public var isFavorite: Bool
    
    public init(
        id: String,
        name: String,
        category: String,
        muscleGroups: [String],
        equipment: [String],
        instructions: String?,
        difficulty: String,
        videoURL: String?,
        imageURL: String?,
        isCustom: Bool,
        isFavorite: Bool
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.muscleGroups = muscleGroups
        self.equipment = equipment
        self.instructions = instructions
        self.difficulty = difficulty
        self.videoURL = videoURL
        self.imageURL = imageURL
        self.isCustom = isCustom
        self.isFavorite = isFavorite
    }
}

public enum ExerciseSortOption: String, CaseIterable {
    case name = "Name"
    case category = "Category"
    case difficulty = "Difficulty"
    case muscleGroup = "Muscle Group"
    
    public var displayName: String {
        return rawValue
    }
}