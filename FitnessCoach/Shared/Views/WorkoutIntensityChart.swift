import SwiftUI

// MARK: - Workout Intensity Data Models
public struct WorkoutIntensityData: Identifiable {
    public let id = UUID()
    public let date: Date
    public let intensity: Double // 0.0 to 1.0
    public let duration: TimeInterval // in minutes
    public let workoutType: String
    public let caloriesBurned: Int?
    
    public init(date: Date, intensity: Double, duration: TimeInterval, workoutType: String, caloriesBurned: Int? = nil) {
        self.date = date
        self.intensity = max(0, min(1, intensity))
        self.duration = duration
        self.workoutType = workoutType
        self.caloriesBurned = caloriesBurned
    }
}

public struct WorkoutIntensityChart: View {
    private let data: [WorkoutIntensityData]
    private let title: String
    private let showStats: Bool
    
    @Environment(\.theme) private var theme
    @State private var selectedWorkout: WorkoutIntensityData?
    @State private var animationProgress: CGFloat = 0
    
    public init(
        data: [WorkoutIntensityData],
        title: String = "Workout Intensity",
        showStats: Bool = true
    ) {
        self.data = data
        self.title = title
        self.showStats = showStats
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            headerView
            heatmapGrid
            if showStats {
                statisticsView
            }
            legendView
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
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                Text(title)
                    .font(theme.typography.headlineMedium)
                    .foregroundColor(theme.textPrimary)
                
                if let selectedWorkout = selectedWorkout {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(selectedWorkout.workoutType)
                            .font(theme.typography.titleSmall)
                            .foregroundColor(theme.primaryColor)
                        
                        Text("\(selectedWorkout.duration / 60, specifier: "%.0f") min • \(intensityLabel(selectedWorkout.intensity))")
                            .font(theme.typography.labelMedium)
                            .foregroundColor(theme.textSecondary)
                    }
                } else {
                    Text("\(data.count) workouts • \(totalDuration / 60, specifier: "%.0f") min total")
                        .font(theme.typography.labelMedium)
                        .foregroundColor(theme.textSecondary)
                }
            }
            
            Spacer()
            
            Button(action: { selectedWorkout = nil }) {
                Image(systemName: selectedWorkout != nil ? "xmark.circle" : "calendar")
                    .foregroundColor(theme.textSecondary)
                    .font(.title3)
            }
        }
    }
    
    private var heatmapGrid: some View {
        VStack(spacing: 2) {
            // Week days header
            HStack(spacing: 2) {
                Text("")
                    .frame(width: 30)
                
                ForEach(weekDays, id: \.self) { day in
                    Text(day)
                        .font(theme.typography.labelSmall)
                        .foregroundColor(theme.textTertiary)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Heatmap grid
            ForEach(weekRows.indices, id: \.self) { weekIndex in
                HStack(spacing: 2) {
                    // Week number
                    Text("W\(weekIndex + 1)")
                        .font(theme.typography.labelSmall)
                        .foregroundColor(theme.textTertiary)
                        .frame(width: 30)
                    
                    ForEach(0..<7) { dayIndex in
                        let workout = workoutForDay(week: weekIndex, day: dayIndex)
                        
                        RoundedRectangle(cornerRadius: theme.cornerRadius.xs)
                            .fill(intensityColor(workout?.intensity ?? 0))
                            .frame(height: 24)
                            .overlay(
                                RoundedRectangle(cornerRadius: theme.cornerRadius.xs)
                                    .stroke(
                                        selectedWorkout?.id == workout?.id ? theme.primaryColor : Color.clear,
                                        lineWidth: 2
                                    )
                            )
                            .onTapGesture {
                                selectedWorkout = workout
                            }
                            .scaleEffect(animationProgress)
                            .animation(
                                theme.animations.springFast.delay(Double(weekIndex * 7 + dayIndex) * 0.01),
                                value: animationProgress
                            )
                    }
                }
            }
        }
    }
    
    private var statisticsView: some View {
        HStack(spacing: theme.spacing.lg) {
            StatCard(
                title: "Avg Intensity",
                value: "\(averageIntensity * 100, specifier: "%.0f")%",
                icon: "flame.fill",
                color: intensityColor(averageIntensity)
            )
            
            StatCard(
                title: "Total Time",
                value: "\(totalDuration / 3600, specifier: "%.1f")h",
                icon: "clock.fill",
                color: theme.infoColor
            )
            
            StatCard(
                title: "Streak",
                value: "\(currentStreak)d",
                icon: "bolt.fill",
                color: theme.warningColor
            )
            
            if let avgCalories = averageCalories {
                StatCard(
                    title: "Avg Calories",
                    value: "\(avgCalories)",
                    icon: "flame",
                    color: theme.errorColor
                )
            }
        }
    }
    
    private var legendView: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            Text("Intensity Level")
                .font(theme.typography.labelMedium)
                .foregroundColor(theme.textSecondary)
            
            HStack(spacing: theme.spacing.xs) {
                Text("Low")
                    .font(theme.typography.labelSmall)
                    .foregroundColor(theme.textTertiary)
                
                ForEach(0..<5) { level in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(intensityColor(Double(level) / 4.0))
                        .frame(width: 16, height: 12)
                }
                
                Text("High")
                    .font(theme.typography.labelSmall)
                    .foregroundColor(theme.textTertiary)
                
                Spacer()
                
                HStack(spacing: theme.spacing.sm) {
                    ForEach(intensityRanges, id: \.label) { range in
                        HStack(spacing: theme.spacing.xs) {
                            Circle()
                                .fill(range.color)
                                .frame(width: 8, height: 8)
                            
                            Text(range.label)
                                .font(theme.typography.labelSmall)
                                .foregroundColor(theme.textSecondary)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Views
    
    private struct StatCard: View {
        let title: String
        let value: String
        let icon: String
        let color: Color
        
        @Environment(\.theme) private var theme
        
        var body: some View {
            VStack(spacing: theme.spacing.xs) {
                HStack(spacing: theme.spacing.xs) {
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(.caption)
                    
                    Text(title)
                        .font(theme.typography.labelSmall)
                        .foregroundColor(theme.textTertiary)
                        .multilineTextAlignment(.center)
                }
                
                Text(value)
                    .font(theme.typography.titleSmall)
                    .foregroundColor(color)
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    // MARK: - Helper Properties and Methods
    
    private var weekDays: [String] {
        ["S", "M", "T", "W", "T", "F", "S"]
    }
    
    private var weekRows: [[WorkoutIntensityData?]] {
        // Create a 4-week grid (28 days)
        let calendar = Calendar.current
        let today = Date()
        let startDate = calendar.date(byAdding: .day, value: -27, to: today) ?? today
        
        var weeks: [[WorkoutIntensityData?]] = []
        
        for week in 0..<4 {
            var weekData: [WorkoutIntensityData?] = []
            for day in 0..<7 {
                let date = calendar.date(byAdding: .day, value: week * 7 + day, to: startDate) ?? Date()
                let workout = data.first { calendar.isDate($0.date, inSameDayAs: date) }
                weekData.append(workout)
            }
            weeks.append(weekData)
        }
        
        return weeks
    }
    
    private func workoutForDay(week: Int, day: Int) -> WorkoutIntensityData? {
        let calendar = Calendar.current
        let today = Date()
        let startDate = calendar.date(byAdding: .day, value: -27, to: today) ?? today
        let targetDate = calendar.date(byAdding: .day, value: week * 7 + day, to: startDate) ?? Date()
        
        return data.first { calendar.isDate($0.date, inSameDayAs: targetDate) }
    }
    
    private func intensityColor(_ intensity: Double) -> Color {
        switch intensity {
        case 0:
            return theme.surfaceColor
        case 0.01...0.25:
            return theme.successColor.opacity(0.3)
        case 0.26...0.50:
            return theme.successColor.opacity(0.6)
        case 0.51...0.75:
            return theme.warningColor
        case 0.76...1.0:
            return theme.errorColor
        default:
            return theme.surfaceColor
        }
    }
    
    private func intensityLabel(_ intensity: Double) -> String {
        switch intensity {
        case 0...0.25:
            return "Light"
        case 0.26...0.50:
            return "Moderate"
        case 0.51...0.75:
            return "Vigorous"
        case 0.76...1.0:
            return "Intense"
        default:
            return "Unknown"
        }
    }
    
    private var averageIntensity: Double {
        guard !data.isEmpty else { return 0 }
        return data.map(\.intensity).reduce(0, +) / Double(data.count)
    }
    
    private var totalDuration: TimeInterval {
        data.map(\.duration).reduce(0, +)
    }
    
    private var currentStreak: Int {
        let calendar = Calendar.current
        let today = Date()
        var streak = 0
        var currentDate = today
        
        while true {
            if data.contains(where: { calendar.isDate($0.date, inSameDayAs: currentDate) }) {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? Date()
            } else {
                break
            }
        }
        
        return streak
    }
    
    private var averageCalories: Int? {
        let workoutsWithCalories = data.compactMap(\.caloriesBurned)
        guard !workoutsWithCalories.isEmpty else { return nil }
        return workoutsWithCalories.reduce(0, +) / workoutsWithCalories.count
    }
    
    private var intensityRanges: [(label: String, color: Color)] {
        [
            ("Light", theme.successColor.opacity(0.3)),
            ("Moderate", theme.successColor.opacity(0.6)),
            ("Vigorous", theme.warningColor),
            ("Intense", theme.errorColor)
        ]
    }
}

// MARK: - Preview
#Preview {
    ScrollView {
        WorkoutIntensityChart(
            data: [
                WorkoutIntensityData(date: Calendar.current.date(byAdding: .day, value: -20, to: Date())!, intensity: 0.8, duration: 45*60, workoutType: "HIIT", caloriesBurned: 450),
                WorkoutIntensityData(date: Calendar.current.date(byAdding: .day, value: -19, to: Date())!, intensity: 0.4, duration: 30*60, workoutType: "Yoga", caloriesBurned: 200),
                WorkoutIntensityData(date: Calendar.current.date(byAdding: .day, value: -17, to: Date())!, intensity: 0.9, duration: 60*60, workoutType: "Strength", caloriesBurned: 400),
                WorkoutIntensityData(date: Calendar.current.date(byAdding: .day, value: -15, to: Date())!, intensity: 0.3, duration: 25*60, workoutType: "Walking", caloriesBurned: 150),
                WorkoutIntensityData(date: Calendar.current.date(byAdding: .day, value: -14, to: Date())!, intensity: 0.7, duration: 40*60, workoutType: "Running", caloriesBurned: 380),
                WorkoutIntensityData(date: Calendar.current.date(byAdding: .day, value: -12, to: Date())!, intensity: 0.6, duration: 35*60, workoutType: "Cycling", caloriesBurned: 320),
                WorkoutIntensityData(date: Calendar.current.date(byAdding: .day, value: -10, to: Date())!, intensity: 0.8, duration: 50*60, workoutType: "CrossFit", caloriesBurned: 500),
                WorkoutIntensityData(date: Calendar.current.date(byAdding: .day, value: -8, to: Date())!, intensity: 0.2, duration: 20*60, workoutType: "Stretching", caloriesBurned: 80),
                WorkoutIntensityData(date: Calendar.current.date(byAdding: .day, value: -5, to: Date())!, intensity: 0.9, duration: 45*60, workoutType: "Boxing", caloriesBurned: 550),
                WorkoutIntensityData(date: Calendar.current.date(byAdding: .day, value: -3, to: Date())!, intensity: 0.5, duration: 30*60, workoutType: "Swimming", caloriesBurned: 280),
                WorkoutIntensityData(date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!, intensity: 0.7, duration: 40*60, workoutType: "Dance", caloriesBurned: 350),
                WorkoutIntensityData(date: Date(), intensity: 0.85, duration: 55*60, workoutType: "Functional", caloriesBurned: 480)
            ]
        )
        .padding()
    }
    .background(Color(.systemGroupedBackground))
    .theme(FitnessTheme())
}