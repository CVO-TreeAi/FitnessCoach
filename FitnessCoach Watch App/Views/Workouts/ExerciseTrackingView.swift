import SwiftUI

struct ExerciseTrackingView: View {
    @EnvironmentObject private var hapticManager: HapticManager
    @EnvironmentObject private var dataStore: WatchDataStore
    
    @State private var currentExercise: Exercise
    @State private var currentSet = 1
    @State private var weight: Double = 135
    @State private var reps: Int = 10
    @State private var restTimer: RestTimer = RestTimer()
    @State private var showingRestTimer = false
    @State private var exerciseSets: [ExerciseSet] = []
    @State private var isCompleted = false
    
    init(exercise: Exercise = Exercise.defaultExercise) {
        _currentExercise = State(initialValue: exercise)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: WatchTheme.Spacing.md) {
                // Exercise Header
                exerciseHeader
                
                // Current Set Info
                currentSetSection
                
                // Weight and Reps Input
                inputSection
                
                // Action Buttons
                actionButtons
                
                // Previous Sets
                if !exerciseSets.isEmpty {
                    previousSetsSection
                }
                
                // Rest Timer (when visible)
                if showingRestTimer {
                    restTimerSection
                }
            }
            .padding(.horizontal, WatchTheme.Spacing.watchPadding)
        }
        .background(WatchTheme.Colors.background)
        .navigationTitle("Exercise")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadExerciseHistory()
        }
    }
    
    // MARK: - Exercise Header
    
    private var exerciseHeader: some View {
        VStack(spacing: WatchTheme.Spacing.xs) {
            Text(currentExercise.name)
                .font(WatchTheme.Typography.headlineMedium)
                .foregroundColor(WatchTheme.Colors.textPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            if let muscleGroup = currentExercise.primaryMuscleGroup {
                Text(muscleGroup)
                    .font(WatchTheme.Typography.caption)
                    .foregroundColor(WatchTheme.Colors.textSecondary)
                    .padding(.horizontal, WatchTheme.Spacing.sm)
                    .padding(.vertical, WatchTheme.Spacing.xxs)
                    .background(
                        RoundedRectangle(cornerRadius: WatchTheme.CornerRadius.sm)
                            .fill(WatchTheme.Colors.surface)
                    )
            }
        }
    }
    
    // MARK: - Current Set Section
    
    private var currentSetSection: some View {
        VStack(spacing: WatchTheme.Spacing.sm) {
            HStack {
                Text("Set \(currentSet)")
                    .font(WatchTheme.Typography.headlineSmall)
                    .foregroundColor(WatchTheme.Colors.primary)
                
                Spacer()
                
                if let lastSet = exerciseSets.last {
                    Text("Last: \(String(format: "%.0f", lastSet.weight))lbs × \(lastSet.reps)")
                        .font(WatchTheme.Typography.caption)
                        .foregroundColor(WatchTheme.Colors.textSecondary)
                }
            }
            
            // Target info if available
            if let targetReps = currentExercise.targetReps {
                HStack {
                    Text("Target:")
                        .font(WatchTheme.Typography.caption)
                        .foregroundColor(WatchTheme.Colors.textSecondary)
                    
                    Text("\(targetReps) reps")
                        .font(WatchTheme.Typography.caption)
                        .foregroundColor(WatchTheme.Colors.accent)
                    
                    if let targetWeight = currentExercise.lastWeight {
                        Text("@ \(String(format: "%.0f", targetWeight))lbs")
                            .font(WatchTheme.Typography.caption)
                            .foregroundColor(WatchTheme.Colors.accent)
                    }
                    
                    Spacer()
                }
            }
        }
        .padding(WatchTheme.Spacing.sm)
        .watchCard()
    }
    
    // MARK: - Input Section
    
    private var inputSection: some View {
        VStack(spacing: WatchTheme.Spacing.md) {
            // Weight Input
            VStack(spacing: WatchTheme.Spacing.xs) {
                HStack {
                    Text("Weight")
                        .font(WatchTheme.Typography.labelMedium)
                        .foregroundColor(WatchTheme.Colors.textSecondary)
                    
                    Spacer()
                    
                    Button {
                        copyLastWeight()
                    } label: {
                        Text("Use Last")
                            .font(WatchTheme.Typography.caption)
                            .foregroundColor(WatchTheme.Colors.primary)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .opacity(exerciseSets.isEmpty ? 0 : 1)
                }
                
                VStack {
                    Text(String(format: "%.0f", weight))
                        .font(WatchTheme.Typography.displayMedium)
                        .foregroundColor(WatchTheme.Colors.primary)
                        .monospacedDigit()
                    
                    Text("lbs")
                        .font(WatchTheme.Typography.bodySmall)
                        .foregroundColor(WatchTheme.Colors.textSecondary)
                }
                .focusable()
                .digitalCrownRotation($weight, from: 5, through: 500, by: 2.5, sensitivity: .medium)
                .onTapGesture {
                    hapticManager.playDigitalCrownTick()
                }
            }
            .padding(WatchTheme.Spacing.sm)
            .watchCard()
            
            // Reps Input
            VStack(spacing: WatchTheme.Spacing.xs) {
                HStack {
                    Text("Reps")
                        .font(WatchTheme.Typography.labelMedium)
                        .foregroundColor(WatchTheme.Colors.textSecondary)
                    
                    Spacer()
                    
                    Button {
                        copyLastReps()
                    } label: {
                        Text("Use Last")
                            .font(WatchTheme.Typography.caption)
                            .foregroundColor(WatchTheme.Colors.primary)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .opacity(exerciseSets.isEmpty ? 0 : 1)
                }
                
                HStack(spacing: WatchTheme.Spacing.md) {
                    Button {
                        adjustReps(-1)
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(WatchTheme.Colors.textSecondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(reps <= 1)
                    
                    VStack {
                        Text(String(reps))
                            .font(WatchTheme.Typography.displayMedium)
                            .foregroundColor(WatchTheme.Colors.secondary)
                            .monospacedDigit()
                        
                        Text("reps")
                            .font(WatchTheme.Typography.bodySmall)
                            .foregroundColor(WatchTheme.Colors.textSecondary)
                    }
                    
                    Button {
                        adjustReps(1)
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(WatchTheme.Colors.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(WatchTheme.Spacing.sm)
            .watchCard()
        }
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        VStack(spacing: WatchTheme.Spacing.sm) {
            // Complete Set Button
            Button {
                completeSet()
            } label: {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Complete Set")
                }
            }
            .buttonStyle(WatchTheme.Components.primaryButtonStyle())
            
            // Secondary Actions
            HStack(spacing: WatchTheme.Spacing.sm) {
                // Skip Set
                Button {
                    skipSet()
                } label: {
                    Text("Skip")
                }
                .buttonStyle(WatchTheme.Components.secondaryButtonStyle())
                
                // Rest Timer
                Button {
                    startRestTimer()
                } label: {
                    HStack {
                        Image(systemName: "timer")
                        Text("Rest")
                    }
                }
                .buttonStyle(WatchTheme.Components.secondaryButtonStyle())
            }
            
            // Complete Exercise Button (appears after sets)
            if exerciseSets.count >= (currentExercise.targetSets ?? 3) {
                Button {
                    completeExercise()
                } label: {
                    HStack {
                        Image(systemName: "flag.checkered.circle.fill")
                        Text("Finish Exercise")
                    }
                }
                .buttonStyle(WatchTheme.Components.primaryButtonStyle())
            }
        }
    }
    
    // MARK: - Previous Sets Section
    
    private var previousSetsSection: some View {
        VStack(alignment: .leading, spacing: WatchTheme.Spacing.sm) {
            Text("Completed Sets")
                .font(WatchTheme.Typography.labelLarge)
                .foregroundColor(WatchTheme.Colors.textPrimary)
            
            LazyVStack(spacing: WatchTheme.Spacing.xs) {
                ForEach(Array(exerciseSets.enumerated()), id: \.offset) { index, set in
                    setRow(set: set, setNumber: index + 1)
                }
            }
        }
        .padding(WatchTheme.Spacing.sm)
        .watchCard()
    }
    
    private func setRow(set: ExerciseSet, setNumber: Int) -> some View {
        HStack {
            // Set number
            Text("\(setNumber)")
                .font(WatchTheme.Typography.bodyMedium)
                .foregroundColor(WatchTheme.Colors.textPrimary)
                .frame(width: 20)
            
            // Weight and reps
            Text("\(String(format: "%.0f", set.weight))lbs × \(set.reps)")
                .font(WatchTheme.Typography.bodyMedium)
                .foregroundColor(WatchTheme.Colors.textPrimary)
            
            Spacer()
            
            // Performance indicator
            if let targetReps = currentExercise.targetReps {
                let performance = Double(set.reps) / Double(targetReps)
                performanceIndicator(performance: performance)
            }
            
            // Time ago
            Text(formatRelativeTime(set.completedAt))
                .font(WatchTheme.Typography.caption)
                .foregroundColor(WatchTheme.Colors.textTertiary)
        }
        .padding(.vertical, 2)
    }
    
    private func performanceIndicator(performance: Double) -> some View {
        Image(systemName: performance >= 1.0 ? "checkmark.circle.fill" : 
              performance >= 0.8 ? "checkmark.circle" : "exclamationmark.circle")
            .font(.system(size: 12))
            .foregroundColor(
                performance >= 1.0 ? WatchTheme.Colors.success :
                performance >= 0.8 ? WatchTheme.Colors.warning : WatchTheme.Colors.error
            )
    }
    
    // MARK: - Rest Timer Section
    
    private var restTimerSection: some View {
        VStack(spacing: WatchTheme.Spacing.md) {
            Text("Rest Timer")
                .font(WatchTheme.Typography.headlineSmall)
                .foregroundColor(WatchTheme.Colors.textPrimary)
            
            // Timer display
            Text(formatRestTime(restTimer.timeRemaining))
                .font(WatchTheme.Typography.timer)
                .foregroundColor(restTimer.isActive ? WatchTheme.Colors.primary : WatchTheme.Colors.textSecondary)
                .monospacedDigit()
            
            // Timer controls
            HStack(spacing: WatchTheme.Spacing.md) {
                Button {
                    if restTimer.isActive {
                        pauseRestTimer()
                    } else {
                        resumeRestTimer()
                    }
                } label: {
                    Image(systemName: restTimer.isActive ? "pause.fill" : "play.fill")
                        .font(.system(size: 16))
                }
                .buttonStyle(WatchTheme.Components.secondaryButtonStyle())
                
                Button {
                    stopRestTimer()
                } label: {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 16))
                }
                .buttonStyle(WatchTheme.Components.destructiveButtonStyle())
                
                Button {
                    addRestTime()
                } label: {
                    Text("+30s")
                        .font(WatchTheme.Typography.labelSmall)
                }
                .buttonStyle(WatchTheme.Components.secondaryButtonStyle())
            }
        }
        .padding(WatchTheme.Spacing.md)
        .watchCard()
        .background(
            RoundedRectangle(cornerRadius: WatchTheme.CornerRadius.watchCard)
                .stroke(WatchTheme.Colors.primary.opacity(0.5), lineWidth: 1)
        )
    }
    
    // MARK: - Actions
    
    private func completeSet() {
        hapticManager.playWorkoutHaptic(.setComplete)
        
        let newSet = ExerciseSet(
            weight: weight,
            reps: reps,
            completedAt: Date()
        )
        
        exerciseSets.append(newSet)
        currentSet += 1
        
        // Start rest timer automatically
        if !showingRestTimer {
            startRestTimer()
        }
        
        // Provide haptic feedback for achievements
        checkForPersonalRecord(newSet)
    }
    
    private func skipSet() {
        hapticManager.playSelectionHaptic()
        currentSet += 1
    }
    
    private func completeExercise() {
        hapticManager.playWorkoutHaptic(.exerciseComplete)
        isCompleted = true
        
        // Save exercise data to workout session
        saveExerciseToSession()
        
        // Could trigger navigation back or to next exercise
    }
    
    private func adjustReps(_ delta: Int) {
        hapticManager.playDigitalCrownTick()
        reps = max(1, reps + delta)
    }
    
    private func copyLastWeight() {
        guard let lastSet = exerciseSets.last else { return }
        weight = lastSet.weight
        hapticManager.playSelectionHaptic()
    }
    
    private func copyLastReps() {
        guard let lastSet = exerciseSets.last else { return }
        reps = lastSet.reps
        hapticManager.playSelectionHaptic()
    }
    
    // MARK: - Rest Timer Actions
    
    private func startRestTimer() {
        hapticManager.playButtonPressHaptic()
        let restDuration = currentExercise.restDuration ?? 90.0 // Default 90 seconds
        restTimer.start(duration: restDuration) { [weak self] in
            DispatchQueue.main.async {
                self?.restTimerCompleted()
            }
        }
        showingRestTimer = true
    }
    
    private func pauseRestTimer() {
        restTimer.pause()
        hapticManager.playButtonPressHaptic()
    }
    
    private func resumeRestTimer() {
        restTimer.resume()
        hapticManager.playButtonPressHaptic()
    }
    
    private func stopRestTimer() {
        restTimer.stop()
        showingRestTimer = false
        hapticManager.playButtonPressHaptic()
    }
    
    private func addRestTime() {
        restTimer.addTime(30) // Add 30 seconds
        hapticManager.playSelectionHaptic()
    }
    
    private func restTimerCompleted() {
        hapticManager.playWorkoutHaptic(.restTimerEnd)
        showingRestTimer = false
    }
    
    // MARK: - Helper Methods
    
    private func loadExerciseHistory() {
        // Load previous weights and reps if available
        if let lastWeight = currentExercise.lastWeight {
            weight = lastWeight
        }
        if let targetReps = currentExercise.targetReps {
            reps = targetReps
        }
    }
    
    private func checkForPersonalRecord(_ set: ExerciseSet) {
        // Check if this is a new personal record
        if let bestWeight = currentExercise.personalRecord?.weight,
           set.weight > bestWeight {
            hapticManager.playWorkoutHaptic(.newPersonalRecord)
        }
    }
    
    private func saveExerciseToSession() {
        // Save exercise data to the current workout session
        // This would integrate with the workout data store
    }
    
    private func formatRestTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval / 60)
        let seconds = Int(timeInterval.truncatingRemainder(dividingBy: 60))
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func formatRelativeTime(_ date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        if interval < 60 {
            return "now"
        } else if interval < 3600 {
            return "\(Int(interval / 60))m ago"
        } else {
            return "\(Int(interval / 3600))h ago"
        }
    }
}

// MARK: - Supporting Models

struct Exercise {
    let name: String
    let primaryMuscleGroup: String?
    let targetSets: Int?
    let targetReps: Int?
    let lastWeight: Double?
    let personalRecord: ExerciseSet?
    let restDuration: TimeInterval?
    
    static let defaultExercise = Exercise(
        name: "Bench Press",
        primaryMuscleGroup: "Chest",
        targetSets: 3,
        targetReps: 10,
        lastWeight: 135,
        personalRecord: nil,
        restDuration: 90
    )
}

struct ExerciseSet {
    let weight: Double
    let reps: Int
    let completedAt: Date
}

class RestTimer: ObservableObject {
    @Published var timeRemaining: TimeInterval = 0
    @Published var isActive = false
    
    private var timer: Timer?
    private var onComplete: (() -> Void)?
    
    func start(duration: TimeInterval, onComplete: @escaping () -> Void) {
        self.timeRemaining = duration
        self.onComplete = onComplete
        self.isActive = true
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.tick()
            }
        }
    }
    
    func pause() {
        isActive = false
        timer?.invalidate()
        timer = nil
    }
    
    func resume() {
        guard timeRemaining > 0 else { return }
        isActive = true
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.tick()
            }
        }
    }
    
    func stop() {
        isActive = false
        timeRemaining = 0
        timer?.invalidate()
        timer = nil
    }
    
    func addTime(_ seconds: TimeInterval) {
        timeRemaining += seconds
    }
    
    private func tick() {
        guard timeRemaining > 0 else {
            complete()
            return
        }
        
        timeRemaining -= 1
    }
    
    private func complete() {
        isActive = false
        timer?.invalidate()
        timer = nil
        onComplete?()
    }
}

#Preview("Exercise Tracking") {
    ExerciseTrackingView()
        .environmentObject(HapticManager())
        .environmentObject(WatchDataStore())
}

#Preview("Exercise Tracking - With Sets") {
    let view = ExerciseTrackingView()
    // Would populate with sample data in a real preview
    return view
        .environmentObject(HapticManager())
        .environmentObject(WatchDataStore())
}