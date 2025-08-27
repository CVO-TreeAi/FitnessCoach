import SwiftUI

struct CompleteWorkoutsView: View {
    @EnvironmentObject private var dataManager: FitnessDataManager
    @Environment(\.theme) private var theme
    
    @State private var selectedTab: WorkoutTab = .templates
    @State private var showingWorkoutBuilder = false
    @State private var showingExerciseLibrary = false
    @State private var searchText = ""
    
    enum WorkoutTab: String, CaseIterable {
        case templates = "Templates"
        case active = "Active"
        case history = "History"
        case exercises = "Exercises"
        
        var icon: String {
            switch self {
            case .templates: return "doc.text.fill"
            case .active: return "play.circle.fill"
            case .history: return "clock.fill"
            case .exercises: return "dumbbell.fill"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Custom Tab Bar
                workoutTabBar
                
                // Content
                TabView(selection: $selectedTab) {
                    WorkoutTemplatesView()
                        .tag(WorkoutTab.templates)
                    
                    ActiveWorkoutView()
                        .tag(WorkoutTab.active)
                    
                    WorkoutHistoryView()
                        .tag(WorkoutTab.history)
                    
                    ExerciseLibraryView()
                        .tag(WorkoutTab.exercises)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("Workouts")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Create Workout", systemImage: "plus.circle") {
                            showingWorkoutBuilder = true
                        }
                        
                        Button("Exercise Library", systemImage: "book.fill") {
                            showingExerciseLibrary = true
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title2)
                    }
                }
            }
        }
        .sheet(isPresented: $showingWorkoutBuilder) {
            WorkoutBuilderView()
        }
        .sheet(isPresented: $showingExerciseLibrary) {
            ExerciseLibraryDetailView()
        }
    }
    
    private var workoutTabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(WorkoutTab.allCases, id: \.self) { tab in
                    WorkoutTabButton(
                        tab: tab,
                        isSelected: selectedTab == tab
                    ) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedTab = tab
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 12)
        .background(theme.backgroundColor)
    }
}

struct WorkoutTabButton: View {
    let tab: CompleteWorkoutsView.WorkoutTab
    let isSelected: Bool
    let action: () -> Void
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: tab.icon)
                    .font(.subheadline)
                
                Text(tab.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .foregroundColor(isSelected ? .white : theme.textPrimary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                isSelected ? theme.primaryColor : theme.surfaceColor
            )
            .cornerRadius(20)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Workout Templates View
struct WorkoutTemplatesView: View {
    @EnvironmentObject private var dataManager: FitnessDataManager
    @Environment(\.theme) private var theme
    
    @State private var selectedCategory: WorkoutTemplate.WorkoutCategory?
    @State private var searchText = ""
    @State private var showingTemplateDetail: WorkoutTemplate?
    
    var filteredTemplates: [WorkoutTemplate] {
        var templates = dataManager.workoutTemplates
        
        if let category = selectedCategory {
            templates = templates.filter { $0.category == category }
        }
        
        if !searchText.isEmpty {
            templates = templates.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.description.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return templates
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(theme.textTertiary)
                    
                    TextField("Search workouts...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding()
                .background(theme.surfaceColor)
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Category Filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        CategoryButton(
                            title: "All",
                            isSelected: selectedCategory == nil
                        ) {
                            selectedCategory = nil
                        }
                        
                        ForEach(WorkoutTemplate.WorkoutCategory.allCases, id: \.self) { category in
                            CategoryButton(
                                title: category.rawValue,
                                isSelected: selectedCategory == category
                            ) {
                                selectedCategory = category
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Templates List
                LazyVStack(spacing: 12) {
                    ForEach(filteredTemplates, id: \.id) { template in
                        WorkoutTemplateRow(template: template) {
                            showingTemplateDetail = template
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .sheet(item: $showingTemplateDetail) { template in
            WorkoutTemplateDetailView(template: template)
        }
    }
}

struct CategoryButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : theme.textPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? theme.primaryColor : theme.surfaceColor)
                .cornerRadius(20)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct WorkoutTemplateRow: View {
    let template: WorkoutTemplate
    let action: () -> Void
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(template.name)
                            .font(.headline)
                            .foregroundColor(theme.textPrimary)
                            .multilineTextAlignment(.leading)
                        
                        Text(template.description)
                            .font(.subheadline)
                            .foregroundColor(theme.textSecondary)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    // Favorite Button
                    Button {
                        // Toggle favorite
                    } label: {
                        Image(systemName: template.isFavorite ? "heart.fill" : "heart")
                            .foregroundColor(template.isFavorite ? .red : theme.textTertiary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                HStack(spacing: 16) {
                    Label("\(template.estimatedDuration)m", systemImage: "clock")
                    Label(template.difficulty.rawValue, systemImage: "gauge")
                    Label("\(template.exercises.count) exercises", systemImage: "list.number")
                    
                    Spacer()
                    
                    Image(systemName: "play.circle.fill")
                        .font(.title2)
                        .foregroundColor(theme.primaryColor)
                }
                .font(.caption)
                .foregroundColor(theme.textTertiary)
            }
            .padding()
            .background(theme.surfaceColor)
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Active Workout View
struct ActiveWorkoutView: View {
    @EnvironmentObject private var dataManager: FitnessDataManager
    @Environment(\.theme) private var theme
    
    var body: some View {
        if dataManager.isWorkoutInProgress,
           let activeSession = dataManager.activeWorkoutSession {
            ActiveWorkoutSessionView(session: activeSession)
        } else {
            EmptyActiveWorkoutView()
        }
    }
}

struct EmptyActiveWorkoutView: View {
    @EnvironmentObject private var dataManager: FitnessDataManager
    @Environment(\.theme) private var theme
    
    @State private var showingQuickStart = false
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 60))
                .foregroundColor(theme.textTertiary)
            
            VStack(spacing: 8) {
                Text("No Active Workout")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(theme.textPrimary)
                
                Text("Start a workout to track your progress")
                    .font(.subheadline)
                    .foregroundColor(theme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 16) {
                Button("Quick Start Workout") {
                    showingQuickStart = true
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(theme.primaryColor)
                .cornerRadius(12)
                
                Button("Browse Templates") {
                    // Switch to templates tab
                }
                .font(.subheadline)
                .foregroundColor(theme.primaryColor)
                .padding()
                .background(theme.primaryColor.opacity(0.1))
                .cornerRadius(12)
            }
            .padding(.horizontal, 40)
        }
        .sheet(isPresented: $showingQuickStart) {
            QuickStartWorkoutView()
        }
    }
}

struct ActiveWorkoutSessionView: View {
    let session: WorkoutSession
    @EnvironmentObject private var dataManager: FitnessDataManager
    @Environment(\.theme) private var theme
    
    @State private var currentExerciseIndex = 0
    @State private var showingRestTimer = false
    @State private var restTimeRemaining = 0
    @State private var restTimer: Timer?
    
    var currentTemplate: WorkoutTemplate? {
        dataManager.workoutTemplates.first { $0.id == session.templateId }
    }
    
    var currentExercise: WorkoutExercise? {
        currentTemplate?.exercises[safe: currentExerciseIndex]
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            workoutHeader
            
            // Exercise Progress
            if let exercise = currentExercise {
                exerciseSection(exercise)
            }
            
            // Navigation
            navigationControls
            
            // Complete Workout
            completeWorkoutButton
        }
        .sheet(isPresented: $showingRestTimer) {
            RestTimerView(
                duration: restTimeRemaining,
                onComplete: {
                    showingRestTimer = false
                    moveToNextExercise()
                }
            )
        }
    }
    
    private var workoutHeader: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.templateName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(theme.textPrimary)
                    
                    Text(formatDuration(session.duration))
                        .font(.subheadline)
                        .foregroundColor(theme.textSecondary)
                }
                
                Spacer()
                
                Button("End Workout") {
                    dataManager.completeWorkout()
                }
                .font(.subheadline)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.red)
                .cornerRadius(8)
            }
            
            // Progress Bar
            if let template = currentTemplate {
                ProgressView(value: Double(currentExerciseIndex), total: Double(template.exercises.count))
                    .progressViewStyle(LinearProgressViewStyle(tint: theme.primaryColor))
            }
        }
        .padding()
        .background(theme.surfaceColor)
    }
    
    private func exerciseSection(_ exercise: WorkoutExercise) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                // Exercise Info
                VStack(spacing: 12) {
                    Text(exercise.exerciseName)
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    HStack(spacing: 20) {
                        VStack {
                            Text("\(exercise.sets)")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("Sets")
                                .font(.caption)
                                .foregroundColor(theme.textSecondary)
                        }
                        
                        if let reps = exercise.reps {
                            VStack {
                                Text("\(reps.min)-\(reps.max)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Text("Reps")
                                    .font(.caption)
                                    .foregroundColor(theme.textSecondary)
                            }
                        }
                        
                        if let weight = exercise.weight {
                            VStack {
                                Text("\(Int(weight))")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Text("lbs")
                                    .font(.caption)
                                    .foregroundColor(theme.textSecondary)
                            }
                        }
                        
                        VStack {
                            Text("\(exercise.restTime)s")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("Rest")
                                .font(.caption)
                                .foregroundColor(theme.textSecondary)
                        }
                    }
                    .padding()
                    .background(theme.surfaceColor)
                    .cornerRadius(12)
                }
                
                // Set Logging
                SetLoggingView(
                    exercise: exercise,
                    completedSets: getCompletedSets(for: exercise),
                    onSetCompleted: { setNumber, reps, weight in
                        dataManager.logExerciseSet(
                            exerciseId: exercise.exerciseId,
                            exerciseName: exercise.exerciseName,
                            setNumber: setNumber,
                            reps: reps,
                            weight: weight,
                            duration: nil
                        )
                        
                        // Start rest timer
                        restTimeRemaining = exercise.restTime
                        showingRestTimer = true
                    }
                )
            }
            .padding()
        }
    }
    
    private var navigationControls: some View {
        HStack(spacing: 20) {
            Button("Previous") {
                moveToPreviousExercise()
            }
            .disabled(currentExerciseIndex == 0)
            
            Spacer()
            
            Text("Exercise \(currentExerciseIndex + 1) of \(currentTemplate?.exercises.count ?? 0)")
                .font(.subheadline)
                .foregroundColor(theme.textSecondary)
            
            Spacer()
            
            Button("Next") {
                moveToNextExercise()
            }
            .disabled(currentExerciseIndex >= (currentTemplate?.exercises.count ?? 0) - 1)
        }
        .padding()
        .background(theme.surfaceColor)
    }
    
    private var completeWorkoutButton: some View {
        Button("Complete Workout") {
            dataManager.completeWorkout(rating: 5, notes: nil)
        }
        .font(.headline)
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .padding()
        .background(theme.primaryColor)
        .cornerRadius(12)
        .padding()
    }
    
    private func getCompletedSets(for exercise: WorkoutExercise) -> [CompletedSet] {
        guard let session = dataManager.activeWorkoutSession else { return [] }
        
        let completedExercise = session.completedExercises.first { $0.exerciseId == exercise.exerciseId }
        return completedExercise?.completedSets ?? []
    }
    
    private func moveToNextExercise() {
        if currentExerciseIndex < (currentTemplate?.exercises.count ?? 0) - 1 {
            currentExerciseIndex += 1
        }
    }
    
    private func moveToPreviousExercise() {
        if currentExerciseIndex > 0 {
            currentExerciseIndex -= 1
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}

// MARK: - Set Logging View
struct SetLoggingView: View {
    let exercise: WorkoutExercise
    let completedSets: [CompletedSet]
    let onSetCompleted: (Int, Int?, Double?) -> Void
    
    @Environment(\.theme) private var theme
    @State private var currentReps = ""
    @State private var currentWeight = ""
    
    var nextSetNumber: Int {
        completedSets.count + 1
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Set \(nextSetNumber) of \(exercise.sets)")
                .font(.headline)
            
            // Previous Sets
            if !completedSets.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Completed Sets")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    ForEach(completedSets, id: \.id) { set in
                        HStack {
                            Text("Set \(set.setNumber)")
                                .font(.caption)
                                .foregroundColor(theme.textSecondary)
                            
                            Spacer()
                            
                            if let reps = set.reps {
                                Text("\(reps) reps")
                                    .font(.caption)
                            }
                            
                            if let weight = set.weight {
                                Text("@ \(Int(weight)) lbs")
                                    .font(.caption)
                            }
                            
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding()
                .background(theme.surfaceColor)
                .cornerRadius(12)
            }
            
            // Current Set Input
            if nextSetNumber <= exercise.sets {
                VStack(spacing: 16) {
                    HStack(spacing: 16) {
                        if exercise.reps != nil {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Reps")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                TextField("Reps", text: $currentReps)
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                        }
                        
                        if exercise.weight != nil {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Weight (lbs)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                TextField("Weight", text: $currentWeight)
                                    .keyboardType(.decimalPad)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                        }
                    }
                    
                    Button("Complete Set") {
                        let reps = Int(currentReps)
                        let weight = Double(currentWeight)
                        
                        onSetCompleted(nextSetNumber, reps, weight)
                        
                        // Reset for next set
                        currentReps = ""
                        // Keep weight for next set
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        (currentReps.isEmpty && exercise.reps != nil) ||
                        (currentWeight.isEmpty && exercise.weight != nil) ?
                        Color.gray : theme.primaryColor
                    )
                    .cornerRadius(12)
                    .disabled(
                        (currentReps.isEmpty && exercise.reps != nil) ||
                        (currentWeight.isEmpty && exercise.weight != nil)
                    )
                }
            }
        }
    }
}

// MARK: - Rest Timer View
struct RestTimerView: View {
    let duration: Int
    let onComplete: () -> Void
    
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.theme) private var theme
    @State private var timeRemaining: Int
    @State private var timer: Timer?
    
    init(duration: Int, onComplete: @escaping () -> Void) {
        self.duration = duration
        self.onComplete = onComplete
        self._timeRemaining = State(initialValue: duration)
    }
    
    var body: some View {
        VStack(spacing: 40) {
            Text("Rest Time")
                .font(.title)
                .fontWeight(.bold)
            
            ZStack {
                Circle()
                    .stroke(theme.surfaceColor, lineWidth: 20)
                    .frame(width: 200, height: 200)
                
                Circle()
                    .trim(from: 0, to: CGFloat(duration - timeRemaining) / CGFloat(duration))
                    .stroke(theme.primaryColor, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: timeRemaining)
                
                VStack {
                    Text("\(timeRemaining)")
                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                        .foregroundColor(theme.textPrimary)
                    
                    Text("seconds")
                        .font(.subheadline)
                        .foregroundColor(theme.textSecondary)
                }
            }
            
            HStack(spacing: 20) {
                Button("Skip Rest") {
                    timer?.invalidate()
                    presentationMode.wrappedValue.dismiss()
                    onComplete()
                }
                .font(.subheadline)
                .foregroundColor(theme.primaryColor)
                .padding()
                .background(theme.primaryColor.opacity(0.1))
                .cornerRadius(12)
                
                Button("Add 30s") {
                    timeRemaining += 30
                }
                .font(.subheadline)
                .foregroundColor(.white)
                .padding()
                .background(theme.primaryColor)
                .cornerRadius(12)
            }
        }
        .padding()
        .onAppear {
            startTimer()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                timer?.invalidate()
                presentationMode.wrappedValue.dismiss()
                onComplete()
            }
        }
    }
}

// MARK: - Array Extension
extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    CompleteWorkoutsView()
        .environmentObject(FitnessDataManager.shared)
        .environmentObject(ThemeManager())
        .theme(FitnessTheme())
}