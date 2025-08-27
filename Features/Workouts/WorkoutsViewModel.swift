import Foundation
import Combine

@MainActor
public class WorkoutsViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published public var workoutTemplates: [WorkoutTemplate] = []
    @Published public var recentWorkouts: [WorkoutHistory] = []
    @Published public var activeWorkout: ActiveWorkout?
    @Published public var searchText: String = ""
    @Published public var selectedCategory: WorkoutCategory?
    @Published public var isLoading: Bool = true
    @Published public var showCreateWorkout: Bool = false
    @Published public var showExerciseLibrary: Bool = false
    @Published public var selectedWorkout: WorkoutTemplateModel?
    
    // MARK: - Dependencies
    private let coreDataManager = CoreDataManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    public init() {
        setupSubscriptions()
    }
    
    // MARK: - Computed Properties
    
    public var filteredWorkouts: [WorkoutTemplateModel] {
        var filtered = workoutTemplates.map { template in
            WorkoutTemplateModel(
                id: template.id?.uuidString ?? UUID().uuidString,
                name: template.name ?? "Untitled Workout",
                description: template.desc,
                category: template.category ?? "General",
                difficulty: template.difficulty ?? "Beginner",
                estimatedDuration: Int(template.estimatedDuration),
                exerciseCount: template.exercises?.count ?? 0,
                tags: template.tags ?? [],
                lastPerformed: nil,
                isPublic: template.isPublic
            )
        }
        
        // Filter by category
        if let selectedCategory = selectedCategory {
            filtered = filtered.filter { $0.category.lowercased() == selectedCategory.rawValue }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { workout in
                workout.name.localizedCaseInsensitiveContains(searchText) ||
                workout.description?.localizedCaseInsensitiveContains(searchText) == true ||
                workout.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        return filtered.sorted { $0.name < $1.name }
    }
    
    // MARK: - Public Methods
    
    public func loadData() async {
        isLoading = true
        
        do {
            async let workoutTemplatesTask = loadWorkoutTemplates()
            async let recentWorkoutsTask = loadRecentWorkouts()
            async let activeWorkoutTask = loadActiveWorkout()
            
            _ = try await [
                workoutTemplatesTask,
                recentWorkoutsTask,
                activeWorkoutTask
            ]
            
            isLoading = false
        } catch {
            print("Failed to load workouts data: \(error)")
            isLoading = false
        }
    }
    
    public func refresh() async {
        await loadData()
    }
    
    public func performSearch() async {
        // Search is performed through the computed filteredWorkouts property
        // This method can be used to trigger additional search logic if needed
    }
    
    public func startQuickWorkout() {
        // Start a quick workout session
        let quickWorkout = ActiveWorkout(
            id: UUID().uuidString,
            name: "Quick Workout",
            startTime: Date(),
            totalExercises: 0,
            completedExercises: 0
        )
        activeWorkout = quickWorkout
    }
    
    public func resumeWorkout() {
        // Resume the active workout
        // This would typically navigate to the active workout view
    }
    
    public func repeatWorkout(_ workout: WorkoutHistory) {
        // Create a new workout session based on the previous workout
        let newWorkout = ActiveWorkout(
            id: UUID().uuidString,
            name: workout.name,
            startTime: Date(),
            totalExercises: workout.exercisesCompleted,
            completedExercises: 0
        )
        activeWorkout = newWorkout
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
        
        // React to category changes
        $selectedCategory
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    private func loadWorkoutTemplates() async throws {
        let templates = coreDataManager.fetchWorkoutTemplates()
        workoutTemplates = templates
    }
    
    private func loadRecentWorkouts() async throws {
        // For now, create mock data - in real app, this would fetch from CoreData
        recentWorkouts = generateMockRecentWorkouts()
    }
    
    private func loadActiveWorkout() async throws {
        // Check if there's an active workout session
        // For now, no active workout
        activeWorkout = nil
    }
    
    private func generateMockRecentWorkouts() -> [WorkoutHistory] {
        let calendar = Calendar.current
        return [
            WorkoutHistory(
                id: UUID().uuidString,
                name: "Upper Body Strength",
                completedAt: calendar.date(byAdding: .day, value: -1, to: Date())!,
                duration: 45,
                caloriesBurned: 320,
                exercisesCompleted: 8,
                rating: 4
            ),
            WorkoutHistory(
                id: UUID().uuidString,
                name: "HIIT Cardio",
                completedAt: calendar.date(byAdding: .day, value: -3, to: Date())!,
                duration: 30,
                caloriesBurned: 280,
                exercisesCompleted: 6,
                rating: 5
            ),
            WorkoutHistory(
                id: UUID().uuidString,
                name: "Lower Body Power",
                completedAt: calendar.date(byAdding: .day, value: -5, to: Date())!,
                duration: 50,
                caloriesBurned: 350,
                exercisesCompleted: 10,
                rating: 4
            )
        ]
    }
}

// MARK: - Data Models

public struct WorkoutTemplateModel: Identifiable, Hashable {
    public let id: String
    public let name: String
    public let description: String?
    public let category: String
    public let difficulty: String
    public let estimatedDuration: Int
    public let exerciseCount: Int
    public let tags: [String]
    public let lastPerformed: Date?
    public let isPublic: Bool
    
    public init(
        id: String,
        name: String,
        description: String?,
        category: String,
        difficulty: String,
        estimatedDuration: Int,
        exerciseCount: Int,
        tags: [String],
        lastPerformed: Date?,
        isPublic: Bool
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.category = category
        self.difficulty = difficulty
        self.estimatedDuration = estimatedDuration
        self.exerciseCount = exerciseCount
        self.tags = tags
        self.lastPerformed = lastPerformed
        self.isPublic = isPublic
    }
}

public struct WorkoutHistory: Identifiable, Hashable {
    public let id: String
    public let name: String
    public let completedAt: Date
    public let duration: Int
    public let caloriesBurned: Int
    public let exercisesCompleted: Int
    public let rating: Int?
    
    public init(
        id: String,
        name: String,
        completedAt: Date,
        duration: Int,
        caloriesBurned: Int,
        exercisesCompleted: Int,
        rating: Int?
    ) {
        self.id = id
        self.name = name
        self.completedAt = completedAt
        self.duration = duration
        self.caloriesBurned = caloriesBurned
        self.exercisesCompleted = exercisesCompleted
        self.rating = rating
    }
}

public struct ActiveWorkout: Identifiable, Hashable {
    public let id: String
    public let name: String
    public let startTime: Date
    public let totalExercises: Int
    public let completedExercises: Int
    
    public var elapsedTime: TimeInterval {
        Date().timeIntervalSince(startTime)
    }
    
    public var progress: Double {
        guard totalExercises > 0 else { return 0.0 }
        return Double(completedExercises) / Double(totalExercises)
    }
    
    public init(
        id: String,
        name: String,
        startTime: Date,
        totalExercises: Int,
        completedExercises: Int
    ) {
        self.id = id
        self.name = name
        self.startTime = startTime
        self.totalExercises = totalExercises
        self.completedExercises = completedExercises
    }
}