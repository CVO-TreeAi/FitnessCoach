import SwiftUI

// MARK: - Activity Ring Data Models
public struct ActivityRingData: Identifiable {
    public let id = UUID()
    public let date: Date
    public let move: Double // calories burned
    public let exercise: Double // minutes of exercise
    public let stand: Double // hours of standing
    public let moveGoal: Double
    public let exerciseGoal: Double
    public let standGoal: Double
    
    public init(
        date: Date,
        move: Double,
        exercise: Double,
        stand: Double,
        moveGoal: Double = 400,
        exerciseGoal: Double = 30,
        standGoal: Double = 12
    ) {
        self.date = date
        self.move = move
        self.exercise = exercise
        self.stand = stand
        self.moveGoal = moveGoal
        self.exerciseGoal = exerciseGoal
        self.standGoal = standGoal
    }
    
    public var moveProgress: Double { min(move / moveGoal, 1.0) }
    public var exerciseProgress: Double { min(exercise / exerciseGoal, 1.0) }
    public var standProgress: Double { min(stand / standGoal, 1.0) }
    
    public var hasCompletedAllRings: Bool {
        moveProgress >= 1.0 && exerciseProgress >= 1.0 && standProgress >= 1.0
    }
    
    public var completedRingsCount: Int {
        var count = 0
        if moveProgress >= 1.0 { count += 1 }
        if exerciseProgress >= 1.0 { count += 1 }
        if standProgress >= 1.0 { count += 1 }
        return count
    }
}

public struct WeeklyActivityRings: View {
    public enum ViewMode {
        case weekly
        case daily
        case summary
    }
    
    private let weekData: [ActivityRingData]
    private let mode: ViewMode
    private let showLabels: Bool
    private let showStreak: Bool
    
    @Environment(\.theme) private var theme
    @State private var selectedDay: ActivityRingData?
    @State private var animationProgress: CGFloat = 0
    
    public init(
        weekData: [ActivityRingData],
        mode: ViewMode = .weekly,
        showLabels: Bool = true,
        showStreak: Bool = true
    ) {
        self.weekData = weekData.sorted { $0.date < $1.date }
        self.mode = mode
        self.showLabels = showLabels
        self.showStreak = showStreak
    }
    
    public var body: some View {
        VStack(spacing: theme.spacing.lg) {
            headerView
            
            switch mode {
            case .weekly:
                weeklyRingsView
            case .daily:
                dailyDetailView
            case .summary:
                summaryView
            }
            
            if showStreak {
                streakView
            }
        }
        .padding(theme.spacing.md)
        .background(theme.cardColor)
        .cornerRadius(theme.cornerRadius.card)
        .shadow(
            color: theme.shadows.md.color,
            radius: theme.shadows.md.radius,
            x: theme.shadows.md.x,
            y: theme.shadows.md.y
        )
        .onAppear {
            withAnimation(theme.animations.springNormal.delay(0.3)) {
                animationProgress = 1.0
            }
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                Text("Activity Rings")
                    .font(theme.typography.headlineMedium)
                    .foregroundColor(theme.textPrimary)
                
                if let selectedDay = selectedDay {
                    Text(dayFormatter.string(from: selectedDay.date))
                        .font(theme.typography.labelMedium)
                        .foregroundColor(theme.textSecondary)
                } else {
                    Text("This Week")
                        .font(theme.typography.labelMedium)
                        .foregroundColor(theme.textSecondary)
                }
            }
            
            Spacer()
            
            if selectedDay != nil {
                Button(action: { selectedDay = nil }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(theme.textTertiary)
                        .font(.title3)
                }
            }
        }
    }
    
    // MARK: - Weekly Rings View
    
    private var weeklyRingsView: some View {
        VStack(spacing: theme.spacing.md) {
            // Week overview
            HStack(spacing: theme.spacing.sm) {
                ForEach(weekData.indices, id: \.self) { index in
                    let dayData = weekData[index]
                    
                    VStack(spacing: theme.spacing.xs) {
                        ActivityRingView(
                            data: dayData,
                            size: .small,
                            animationProgress: animationProgress,
                            onTap: {
                                selectedDay = selectedDay?.id == dayData.id ? nil : dayData
                            }
                        )
                        
                        if showLabels {
                            Text(dayOfWeekFormatter.string(from: dayData.date))
                                .font(theme.typography.labelSmall)
                                .foregroundColor(theme.textTertiary)
                        }
                    }
                    .opacity(selectedDay == nil || selectedDay?.id == dayData.id ? 1.0 : 0.5)
                    .animation(theme.animations.springFast, value: selectedDay)
                }
            }
            
            // Selected day details
            if let selectedDay = selectedDay {
                selectedDayDetailView(selectedDay)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
    }
    
    // MARK: - Daily Detail View
    
    private var dailyDetailView: some View {
        let todayData = weekData.last ?? ActivityRingData(date: Date(), move: 0, exercise: 0, stand: 0)
        
        VStack(spacing: theme.spacing.lg) {
            ActivityRingView(
                data: todayData,
                size: .large,
                animationProgress: animationProgress
            )
            
            HStack(spacing: theme.spacing.lg) {
                ActivityMetric(
                    title: "Move",
                    current: todayData.move,
                    goal: todayData.moveGoal,
                    unit: "cal",
                    color: moveColor,
                    icon: "flame.fill"
                )
                
                ActivityMetric(
                    title: "Exercise",
                    current: todayData.exercise,
                    goal: todayData.exerciseGoal,
                    unit: "min",
                    color: exerciseColor,
                    icon: "figure.run"
                )
                
                ActivityMetric(
                    title: "Stand",
                    current: todayData.stand,
                    goal: todayData.standGoal,
                    unit: "hrs",
                    color: standColor,
                    icon: "figure.stand"
                )
            }
        }
    }
    
    // MARK: - Summary View
    
    private var summaryView: some View {
        VStack(spacing: theme.spacing.md) {
            HStack(spacing: theme.spacing.lg) {
                // Weekly average rings
                VStack(spacing: theme.spacing.xs) {
                    ActivityRingView(
                        data: averageData,
                        size: .medium,
                        animationProgress: animationProgress
                    )
                    
                    Text("Weekly Avg")
                        .font(theme.typography.labelMedium)
                        .foregroundColor(theme.textSecondary)
                }
                
                // Stats
                VStack(alignment: .leading, spacing: theme.spacing.sm) {
                    SummaryStatRow(
                        title: "Perfect Days",
                        value: "\(perfectDaysCount)/7",
                        color: perfectDaysCount >= 5 ? theme.successColor : theme.warningColor
                    )
                    
                    SummaryStatRow(
                        title: "Total Calories",
                        value: "\(totalCalories, specifier: "%.0f")",
                        color: theme.primaryColor
                    )
                    
                    SummaryStatRow(
                        title: "Exercise Time",
                        value: "\(totalExerciseTime, specifier: "%.0f")m",
                        color: theme.infoColor
                    )
                    
                    SummaryStatRow(
                        title: "Stand Hours",
                        value: "\(totalStandHours, specifier: "%.0f")h",
                        color: theme.secondaryColor
                    )
                }
            }
        }
    }
    
    // MARK: - Streak View
    
    private var streakView: some View {
        HStack(spacing: theme.spacing.lg) {
            StreakItem(
                title: "Move Streak",
                count: moveStreak,
                color: moveColor
            )
            
            StreakItem(
                title: "Exercise Streak",
                count: exerciseStreak,
                color: exerciseColor
            )
            
            StreakItem(
                title: "Perfect Days",
                count: perfectDayStreak,
                color: theme.successColor
            )
        }
        .padding(theme.spacing.sm)
        .background(theme.surfaceColor)
        .cornerRadius(theme.cornerRadius.md)
    }
    
    // MARK: - Helper Views
    
    private func selectedDayDetailView(_ data: ActivityRingData) -> some View {
        VStack(spacing: theme.spacing.sm) {
            HStack(spacing: theme.spacing.md) {
                ActivityRingView(
                    data: data,
                    size: .medium,
                    animationProgress: 1.0
                )
                
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    HStack {
                        Text("Move")
                            .font(theme.typography.labelMedium)
                            .foregroundColor(theme.textSecondary)
                        Spacer()
                        Text("\(data.move, specifier: "%.0f")/\(data.moveGoal, specifier: "%.0f") cal")
                            .font(theme.typography.bodySmall)
                            .foregroundColor(moveColor)
                    }
                    
                    HStack {
                        Text("Exercise")
                            .font(theme.typography.labelMedium)
                            .foregroundColor(theme.textSecondary)
                        Spacer()
                        Text("\(data.exercise, specifier: "%.0f")/\(data.exerciseGoal, specifier: "%.0f") min")
                            .font(theme.typography.bodySmall)
                            .foregroundColor(exerciseColor)
                    }
                    
                    HStack {
                        Text("Stand")
                            .font(theme.typography.labelMedium)
                            .foregroundColor(theme.textSecondary)
                        Spacer()
                        Text("\(data.stand, specifier: "%.0f")/\(data.standGoal, specifier: "%.0f") hrs")
                            .font(theme.typography.bodySmall)
                            .foregroundColor(standColor)
                    }
                }
            }
            
            if data.hasCompletedAllRings {
                HStack(spacing: theme.spacing.xs) {
                    Image(systemName: "crown.fill")
                        .foregroundColor(theme.warningColor)
                        .font(.caption)
                    
                    Text("Perfect Day!")
                        .font(theme.typography.labelMedium)
                        .foregroundColor(theme.successColor)
                }
            }
        }
        .padding(theme.spacing.sm)
        .background(theme.surfaceColor)
        .cornerRadius(theme.cornerRadius.md)
    }
    
    private struct ActivityMetric: View {
        let title: String
        let current: Double
        let goal: Double
        let unit: String
        let color: Color
        let icon: String
        
        @Environment(\.theme) private var theme
        
        var body: some View {
            VStack(spacing: theme.spacing.xs) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                
                Text(title)
                    .font(theme.typography.labelMedium)
                    .foregroundColor(theme.textSecondary)
                
                Text("\(current, specifier: "%.0f")")
                    .font(theme.typography.titleMedium)
                    .foregroundColor(color)
                
                Text("\(unit)")
                    .font(theme.typography.labelSmall)
                    .foregroundColor(theme.textTertiary)
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    private struct SummaryStatRow: View {
        let title: String
        let value: String
        let color: Color
        
        @Environment(\.theme) private var theme
        
        var body: some View {
            HStack {
                Text(title)
                    .font(theme.typography.bodySmall)
                    .foregroundColor(theme.textSecondary)
                
                Spacer()
                
                Text(value)
                    .font(theme.typography.titleSmall)
                    .foregroundColor(color)
            }
        }
    }
    
    private struct StreakItem: View {
        let title: String
        let count: Int
        let color: Color
        
        @Environment(\.theme) private var theme
        
        var body: some View {
            VStack(spacing: theme.spacing.xs) {
                Text("\(count)")
                    .font(theme.typography.titleMedium)
                    .foregroundColor(color)
                
                Text(title)
                    .font(theme.typography.labelSmall)
                    .foregroundColor(theme.textTertiary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    // MARK: - Helper Properties
    
    private var moveColor: Color { Color.red }
    private var exerciseColor: Color { Color.green }
    private var standColor: Color { Color.blue }
    
    private var dayOfWeekFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter
    }
    
    private var dayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
    
    private var averageData: ActivityRingData {
        guard !weekData.isEmpty else {
            return ActivityRingData(date: Date(), move: 0, exercise: 0, stand: 0)
        }
        
        let avgMove = weekData.map(\.move).reduce(0, +) / Double(weekData.count)
        let avgExercise = weekData.map(\.exercise).reduce(0, +) / Double(weekData.count)
        let avgStand = weekData.map(\.stand).reduce(0, +) / Double(weekData.count)
        
        return ActivityRingData(
            date: Date(),
            move: avgMove,
            exercise: avgExercise,
            stand: avgStand
        )
    }
    
    private var perfectDaysCount: Int {
        weekData.filter(\.hasCompletedAllRings).count
    }
    
    private var totalCalories: Double {
        weekData.map(\.move).reduce(0, +)
    }
    
    private var totalExerciseTime: Double {
        weekData.map(\.exercise).reduce(0, +)
    }
    
    private var totalStandHours: Double {
        weekData.map(\.stand).reduce(0, +)
    }
    
    private var moveStreak: Int {
        calculateStreak { $0.moveProgress >= 1.0 }
    }
    
    private var exerciseStreak: Int {
        calculateStreak { $0.exerciseProgress >= 1.0 }
    }
    
    private var perfectDayStreak: Int {
        calculateStreak { $0.hasCompletedAllRings }
    }
    
    private func calculateStreak(condition: (ActivityRingData) -> Bool) -> Int {
        var streak = 0
        for data in weekData.reversed() {
            if condition(data) {
                streak += 1
            } else {
                break
            }
        }
        return streak
    }
}

// MARK: - Activity Ring View
private struct ActivityRingView: View {
    enum Size {
        case small, medium, large
        
        var diameter: CGFloat {
            switch self {
            case .small: return 60
            case .medium: return 100
            case .large: return 140
            }
        }
        
        var lineWidth: CGFloat {
            switch self {
            case .small: return 4
            case .medium: return 6
            case .large: return 8
            }
        }
    }
    
    let data: ActivityRingData
    let size: Size
    let animationProgress: CGFloat
    let onTap: (() -> Void)?
    
    @Environment(\.theme) private var theme
    
    init(data: ActivityRingData, size: Size, animationProgress: CGFloat, onTap: (() -> Void)? = nil) {
        self.data = data
        self.size = size
        self.animationProgress = animationProgress
        self.onTap = onTap
    }
    
    var body: some View {
        ZStack {
            // Background rings
            ForEach(0..<3) { index in
                Circle()
                    .stroke(ringBackgroundColor(for: index), lineWidth: size.lineWidth)
                    .frame(width: ringDiameter(for: index), height: ringDiameter(for: index))
            }
            
            // Progress rings
            ForEach(0..<3) { index in
                Circle()
                    .trim(from: 0, to: ringProgress(for: index) * animationProgress)
                    .stroke(
                        ringColor(for: index),
                        style: StrokeStyle(lineWidth: size.lineWidth, lineCap: .round)
                    )
                    .frame(width: ringDiameter(for: index), height: ringDiameter(for: index))
                    .rotationEffect(.degrees(-90))
                    .animation(
                        theme.animations.springNormal.delay(Double(index) * 0.1),
                        value: animationProgress
                    )
            }
            
            // Center content for larger sizes
            if size != .small {
                VStack(spacing: 2) {
                    Text("\(data.completedRingsCount)")
                        .font(size == .large ? theme.typography.headlineLarge : theme.typography.titleMedium)
                        .foregroundColor(theme.primaryColor)
                    
                    Text("rings")
                        .font(theme.typography.labelSmall)
                        .foregroundColor(theme.textTertiary)
                }
            }
        }
        .onTapGesture {
            onTap?()
        }
    }
    
    private func ringColor(for index: Int) -> Color {
        switch index {
        case 0: return Color.red      // Move
        case 1: return Color.green    // Exercise
        case 2: return Color.blue     // Stand
        default: return Color.gray
        }
    }
    
    private func ringBackgroundColor(for index: Int) -> Color {
        ringColor(for: index).opacity(0.2)
    }
    
    private func ringProgress(for index: Int) -> CGFloat {
        switch index {
        case 0: return CGFloat(data.moveProgress)
        case 1: return CGFloat(data.exerciseProgress)
        case 2: return CGFloat(data.standProgress)
        default: return 0
        }
    }
    
    private func ringDiameter(for index: Int) -> CGFloat {
        let spacing: CGFloat = size.lineWidth + 4
        return size.diameter - (CGFloat(index) * spacing)
    }
}

// MARK: - Preview
#Preview {
    ScrollView {
        VStack(spacing: 24) {
            WeeklyActivityRings(
                weekData: [
                    ActivityRingData(date: Calendar.current.date(byAdding: .day, value: -6, to: Date())!, move: 450, exercise: 35, stand: 10),
                    ActivityRingData(date: Calendar.current.date(byAdding: .day, value: -5, to: Date())!, move: 520, exercise: 45, stand: 12),
                    ActivityRingData(date: Calendar.current.date(byAdding: .day, value: -4, to: Date())!, move: 380, exercise: 25, stand: 8),
                    ActivityRingData(date: Calendar.current.date(byAdding: .day, value: -3, to: Date())!, move: 610, exercise: 60, stand: 14),
                    ActivityRingData(date: Calendar.current.date(byAdding: .day, value: -2, to: Date())!, move: 480, exercise: 40, stand: 11),
                    ActivityRingData(date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!, move: 550, exercise: 55, stand: 13),
                    ActivityRingData(date: Date(), move: 420, exercise: 30, stand: 9)
                ],
                mode: .weekly
            )
            
            WeeklyActivityRings(
                weekData: [
                    ActivityRingData(date: Date(), move: 480, exercise: 45, stand: 12)
                ],
                mode: .daily
            )
            
            WeeklyActivityRings(
                weekData: [
                    ActivityRingData(date: Calendar.current.date(byAdding: .day, value: -6, to: Date())!, move: 450, exercise: 35, stand: 10),
                    ActivityRingData(date: Calendar.current.date(byAdding: .day, value: -5, to: Date())!, move: 520, exercise: 45, stand: 12),
                    ActivityRingData(date: Calendar.current.date(byAdding: .day, value: -4, to: Date())!, move: 380, exercise: 25, stand: 8),
                    ActivityRingData(date: Calendar.current.date(byAdding: .day, value: -3, to: Date())!, move: 610, exercise: 60, stand: 14),
                    ActivityRingData(date: Calendar.current.date(byAdding: .day, value: -2, to: Date())!, move: 480, exercise: 40, stand: 11),
                    ActivityRingData(date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!, move: 550, exercise: 55, stand: 13),
                    ActivityRingData(date: Date(), move: 420, exercise: 30, stand: 9)
                ],
                mode: .summary
            )
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
    .theme(FitnessTheme())
}