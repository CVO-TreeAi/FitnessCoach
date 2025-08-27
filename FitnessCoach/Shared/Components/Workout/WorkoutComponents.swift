import SwiftUI

// MARK: - Workout List Row
public struct WorkoutListRow: View {
    let name: String
    let description: String?
    let difficulty: WorkoutDifficulty
    let duration: Int // in minutes
    let exercises: Int
    let lastPerformed: Date?
    let action: () -> Void
    
    @Environment(\.theme) private var theme
    
    public init(
        name: String,
        description: String? = nil,
        difficulty: WorkoutDifficulty,
        duration: Int,
        exercises: Int,
        lastPerformed: Date? = nil,
        action: @escaping () -> Void
    ) {
        self.name = name
        self.description = description
        self.difficulty = difficulty
        self.duration = duration
        self.exercises = exercises
        self.lastPerformed = lastPerformed
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            ThemedCard {
                HStack(spacing: theme.spacing.md) {
                    // Workout icon based on difficulty
                    Circle()
                        .fill(difficulty.color.gradient)
                        .frame(width: 50, height: 50)
                        .overlay(
                            Image(systemName: "figure.strengthtraining.traditional")
                                .font(.title2)
                                .foregroundColor(.white)
                        )
                    
                    VStack(alignment: .leading, spacing: theme.spacing.xs) {
                        Text(name)
                            .font(theme.typography.bodyLarge)
                            .fontWeight(.medium)
                            .foregroundColor(theme.textPrimary)
                            .lineLimit(1)
                        
                        if let description = description {
                            Text(description)
                                .font(theme.typography.bodySmall)
                                .foregroundColor(theme.textSecondary)
                                .lineLimit(2)
                        }
                        
                        HStack(spacing: theme.spacing.md) {
                            Label("\(duration) min", systemImage: "clock")
                                .font(theme.typography.bodySmall)
                                .foregroundColor(theme.textTertiary)
                            
                            Label("\(exercises) exercises", systemImage: "list.bullet")
                                .font(theme.typography.bodySmall)
                                .foregroundColor(theme.textTertiary)
                            
                            DifficultyBadge(difficulty: difficulty)
                        }
                        
                        if let lastPerformed = lastPerformed {
                            Text("Last: \(formatDate(lastPerformed))")
                                .font(theme.typography.bodySmall)
                                .foregroundColor(theme.textTertiary)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(theme.textTertiary)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Difficulty Badge
public struct DifficultyBadge: View {
    let difficulty: WorkoutDifficulty
    
    @Environment(\.theme) private var theme
    
    public init(difficulty: WorkoutDifficulty) {
        self.difficulty = difficulty
    }
    
    public var body: some View {
        HStack(spacing: 2) {
            ForEach(1...3, id: \.self) { level in
                Circle()
                    .fill(level <= difficulty.level ? difficulty.color : theme.textTertiary.opacity(0.3))
                    .frame(width: 6, height: 6)
            }
            
            Text(difficulty.displayName)
                .font(theme.typography.labelSmall)
                .foregroundColor(difficulty.color)
        }
    }
}

// MARK: - Exercise Row
public struct ExerciseRow: View {
    let name: String
    let category: String
    let equipment: String?
    let sets: Int?
    let reps: String?
    let weight: Double?
    let restTime: Int?
    let isCompleted: Bool
    let onToggle: (() -> Void)?
    
    @Environment(\.theme) private var theme
    
    public init(
        name: String,
        category: String,
        equipment: String? = nil,
        sets: Int? = nil,
        reps: String? = nil,
        weight: Double? = nil,
        restTime: Int? = nil,
        isCompleted: Bool = false,
        onToggle: (() -> Void)? = nil
    ) {
        self.name = name
        self.category = category
        self.equipment = equipment
        self.sets = sets
        self.reps = reps
        self.weight = weight
        self.restTime = restTime
        self.isCompleted = isCompleted
        self.onToggle = onToggle
    }
    
    public var body: some View {
        HStack(spacing: theme.spacing.md) {
            if let onToggle = onToggle {
                Button(action: onToggle) {
                    Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(isCompleted ? .green : theme.textTertiary)
                }
            }
            
            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                Text(name)
                    .font(theme.typography.bodyMedium)
                    .fontWeight(.medium)
                    .foregroundColor(theme.textPrimary)
                    .strikethrough(isCompleted)
                
                HStack(spacing: theme.spacing.sm) {
                    if let equipment = equipment {
                        Label(equipment, systemImage: "dumbbell")
                            .font(theme.typography.bodySmall)
                            .foregroundColor(theme.textSecondary)
                    }
                    
                    if let sets = sets, let reps = reps {
                        Text("\(sets) × \(reps)")
                            .font(theme.typography.bodySmall)
                            .foregroundColor(theme.textSecondary)
                    }
                    
                    if let weight = weight {
                        Text("\(Int(weight)) lbs")
                            .font(theme.typography.bodySmall)
                            .foregroundColor(theme.primaryColor)
                    }
                    
                    if let restTime = restTime {
                        Label("\(restTime)s rest", systemImage: "timer")
                            .font(theme.typography.bodySmall)
                            .foregroundColor(theme.textTertiary)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, theme.spacing.sm)
        .opacity(isCompleted ? 0.7 : 1.0)
    }
}

// MARK: - Workout Timer
public struct WorkoutTimer: View {
    @Binding var timeElapsed: TimeInterval
    let isActive: Bool
    
    @Environment(\.theme) private var theme
    @State private var timer: Timer?
    
    public init(timeElapsed: Binding<TimeInterval>, isActive: Bool) {
        self._timeElapsed = timeElapsed
        self.isActive = isActive
    }
    
    public var body: some View {
        VStack(spacing: theme.spacing.sm) {
            Text("Workout Time")
                .font(theme.typography.bodySmall)
                .foregroundColor(theme.textSecondary)
            
            Text(formatTime(timeElapsed))
                .font(.system(size: 48, weight: .bold, design: .monospaced))
                .foregroundColor(theme.primaryColor)
        }
        .onAppear {
            startTimerIfNeeded()
        }
        .onDisappear {
            stopTimer()
        }
        .onChange(of: isActive) { newValue in
            if newValue {
                startTimerIfNeeded()
            } else {
                stopTimer()
            }
        }
    }
    
    private func startTimerIfNeeded() {
        guard isActive, timer == nil else { return }
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            timeElapsed += 1
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func formatTime(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        let seconds = Int(interval) % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}

// MARK: - Rest Timer
public struct RestTimer: View {
    let duration: Int // in seconds
    let onComplete: () -> Void
    
    @Environment(\.theme) private var theme
    @State private var timeRemaining: Int
    @State private var timer: Timer?
    @State private var isActive = true
    
    public init(duration: Int, onComplete: @escaping () -> Void) {
        self.duration = duration
        self.onComplete = onComplete
        self._timeRemaining = State(initialValue: duration)
    }
    
    public var body: some View {
        VStack(spacing: theme.spacing.lg) {
            Text("Rest Time")
                .font(theme.typography.titleMedium)
                .foregroundColor(theme.textPrimary)
            
            ZStack {
                Circle()
                    .stroke(theme.surfaceColor, lineWidth: 10)
                    .frame(width: 200, height: 200)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(theme.primaryColor.gradient, lineWidth: 10)
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: progress)
                
                VStack {
                    Text(formatTime(timeRemaining))
                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                        .foregroundColor(theme.textPrimary)
                    
                    Text("seconds")
                        .font(theme.typography.bodySmall)
                        .foregroundColor(theme.textSecondary)
                }
            }
            
            HStack(spacing: theme.spacing.md) {
                ThemedButton(
                    isActive ? "Pause" : "Resume",
                    style: .secondary,
                    size: .medium
                ) {
                    toggleTimer()
                }
                
                ThemedButton(
                    "Skip",
                    style: .primary,
                    size: .medium
                ) {
                    skipTimer()
                }
            }
        }
        .onAppear {
            startTimer()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    private var progress: Double {
        Double(timeRemaining) / Double(duration)
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        
        if minutes > 0 {
            return String(format: "%d:%02d", minutes, remainingSeconds)
        } else {
            return String(seconds)
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if isActive {
                if timeRemaining > 0 {
                    timeRemaining -= 1
                } else {
                    timer?.invalidate()
                    onComplete()
                }
            }
        }
    }
    
    private func toggleTimer() {
        isActive.toggle()
    }
    
    private func skipTimer() {
        timer?.invalidate()
        onComplete()
    }
}

// MARK: - Supporting Types
public enum WorkoutDifficulty: Int, CaseIterable {
    case beginner = 1
    case intermediate = 2
    case advanced = 3
    
    public var displayName: String {
        switch self {
        case .beginner: return "Beginner"
        case .intermediate: return "Intermediate"
        case .advanced: return "Advanced"
        }
    }
    
    public var color: Color {
        switch self {
        case .beginner: return .green
        case .intermediate: return .orange
        case .advanced: return .red
        }
    }
    
    public var level: Int {
        rawValue
    }
}