import SwiftUI
import Charts

// MARK: - Progress Chart
@available(iOS 16.0, *)
public struct ProgressChart: View {
    let data: [ChartDataPoint]
    let title: String
    let yAxisLabel: String
    let color: Color
    
    @Environment(\.theme) private var theme
    
    public struct ChartDataPoint: Identifiable {
        public let id = UUID()
        public let date: Date
        public let value: Double
        public let label: String?
        
        public init(date: Date, value: Double, label: String? = nil) {
            self.date = date
            self.value = value
            self.label = label
        }
    }
    
    public init(
        data: [ChartDataPoint],
        title: String,
        yAxisLabel: String,
        color: Color = .blue
    ) {
        self.data = data
        self.title = title
        self.yAxisLabel = yAxisLabel
        self.color = color
    }
    
    public var body: some View {
        ThemedCard {
            VStack(alignment: .leading, spacing: theme.spacing.md) {
                Text(title)
                    .font(theme.typography.titleMedium)
                    .foregroundColor(theme.textPrimary)
                
                if data.isEmpty {
                    Text("No data available")
                        .font(theme.typography.bodyMedium)
                        .foregroundColor(theme.textSecondary)
                        .frame(maxWidth: .infinity, minHeight: 200)
                        .frame(alignment: .center)
                } else {
                    Chart(data) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value(yAxisLabel, point.value)
                        )
                        .foregroundStyle(color.gradient)
                        .interpolationMethod(.catmullRom)
                        
                        AreaMark(
                            x: .value("Date", point.date),
                            y: .value(yAxisLabel, point.value)
                        )
                        .foregroundStyle(color.gradient.opacity(0.1))
                        .interpolationMethod(.catmullRom)
                        
                        PointMark(
                            x: .value("Date", point.date),
                            y: .value(yAxisLabel, point.value)
                        )
                        .foregroundStyle(color)
                        .symbolSize(100)
                    }
                    .frame(height: 200)
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day)) { value in
                            AxisGridLine()
                            AxisValueLabel(format: .dateTime.day().month())
                        }
                    }
                    .chartYAxis {
                        AxisMarks { value in
                            AxisGridLine()
                            AxisValueLabel()
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Weekly Workout Chart
@available(iOS 16.0, *)
public struct WeeklyWorkoutChart: View {
    let data: [WorkoutDataPoint]
    let title: String
    
    @Environment(\.theme) private var theme
    
    public struct WorkoutDataPoint: Identifiable {
        public let id = UUID()
        public let day: String
        public let minutes: Int
        public let target: Int
        
        public init(day: String, minutes: Int, target: Int = 30) {
            self.day = day
            self.minutes = minutes
            self.target = target
        }
    }
    
    public init(data: [WorkoutDataPoint], title: String) {
        self.data = data
        self.title = title
    }
    
    public var body: some View {
        ThemedCard {
            VStack(alignment: .leading, spacing: theme.spacing.md) {
                Text(title)
                    .font(theme.typography.titleMedium)
                    .foregroundColor(theme.textPrimary)
                
                if data.isEmpty {
                    Text("No workout data this week")
                        .font(theme.typography.bodyMedium)
                        .foregroundColor(theme.textSecondary)
                        .frame(maxWidth: .infinity, minHeight: 200)
                        .frame(alignment: .center)
                } else {
                    Chart(data) { point in
                        BarMark(
                            x: .value("Day", point.day),
                            y: .value("Minutes", point.minutes)
                        )
                        .foregroundStyle(
                            point.minutes >= point.target ? 
                            Color.green.gradient : 
                            theme.primaryColor.gradient
                        )
                        .cornerRadius(4)
                        
                        RuleMark(
                            y: .value("Target", point.target)
                        )
                        .foregroundStyle(.red.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                    }
                    .frame(height: 200)
                    .chartYAxis {
                        AxisMarks { value in
                            AxisGridLine()
                            AxisValueLabel()
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Macro Chart
public struct MacroChart: View {
    let protein: Double
    let carbs: Double
    let fat: Double
    let title: String
    
    @Environment(\.theme) private var theme
    
    public init(protein: Double, carbs: Double, fat: Double, title: String) {
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.title = title
    }
    
    private var total: Double {
        protein + carbs + fat
    }
    
    private var proteinCalories: Double {
        protein * 4
    }
    
    private var carbCalories: Double {
        carbs * 4
    }
    
    private var fatCalories: Double {
        fat * 9
    }
    
    private var totalCalories: Double {
        proteinCalories + carbCalories + fatCalories
    }
    
    public var body: some View {
        ThemedCard {
            VStack(alignment: .leading, spacing: theme.spacing.md) {
                Text(title)
                    .font(theme.typography.titleMedium)
                    .foregroundColor(theme.textPrimary)
                
                if total > 0 {
                    GeometryReader { geometry in
                        ZStack {
                            // Background circle
                            Circle()
                                .stroke(theme.surfaceColor, lineWidth: 40)
                            
                            // Protein arc
                            Circle()
                                .trim(from: 0, to: proteinCalories / totalCalories)
                                .stroke(Color.blue, lineWidth: 40)
                                .rotationEffect(.degrees(-90))
                            
                            // Carbs arc
                            Circle()
                                .trim(
                                    from: proteinCalories / totalCalories,
                                    to: (proteinCalories + carbCalories) / totalCalories
                                )
                                .stroke(Color.orange, lineWidth: 40)
                                .rotationEffect(.degrees(-90))
                            
                            // Fat arc
                            Circle()
                                .trim(
                                    from: (proteinCalories + carbCalories) / totalCalories,
                                    to: 1.0
                                )
                                .stroke(Color.yellow, lineWidth: 40)
                                .rotationEffect(.degrees(-90))
                            
                            // Center text
                            VStack {
                                Text("\(Int(totalCalories))")
                                    .font(theme.typography.titleLarge)
                                    .fontWeight(.bold)
                                    .foregroundColor(theme.textPrimary)
                                
                                Text("calories")
                                    .font(theme.typography.bodySmall)
                                    .foregroundColor(theme.textSecondary)
                            }
                        }
                        .padding(20)
                    }
                    .frame(height: 200)
                    
                    // Legend
                    HStack(spacing: theme.spacing.lg) {
                        MacroLegendItem(
                            color: .blue,
                            title: "Protein",
                            value: "\(Int(protein))g",
                            percentage: Int((proteinCalories / totalCalories) * 100)
                        )
                        
                        MacroLegendItem(
                            color: .orange,
                            title: "Carbs",
                            value: "\(Int(carbs))g",
                            percentage: Int((carbCalories / totalCalories) * 100)
                        )
                        
                        MacroLegendItem(
                            color: .yellow,
                            title: "Fat",
                            value: "\(Int(fat))g",
                            percentage: Int((fatCalories / totalCalories) * 100)
                        )
                    }
                } else {
                    Text("No macro data available")
                        .font(theme.typography.bodyMedium)
                        .foregroundColor(theme.textSecondary)
                        .frame(maxWidth: .infinity, minHeight: 200)
                        .frame(alignment: .center)
                }
            }
        }
    }
}

private struct MacroLegendItem: View {
    let color: Color
    let title: String
    let value: String
    let percentage: Int
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                
                Text(title)
                    .font(theme.typography.bodySmall)
                    .foregroundColor(theme.textSecondary)
            }
            
            Text(value)
                .font(theme.typography.bodyMedium)
                .fontWeight(.semibold)
                .foregroundColor(theme.textPrimary)
            
            Text("\(percentage)%")
                .font(theme.typography.bodySmall)
                .foregroundColor(theme.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Activity Ring Chart
public struct ActivityRingChart: View {
    let moveProgress: Double
    let exerciseProgress: Double
    let standProgress: Double
    
    @Environment(\.theme) private var theme
    
    public init(
        moveProgress: Double,
        exerciseProgress: Double,
        standProgress: Double
    ) {
        self.moveProgress = moveProgress
        self.exerciseProgress = exerciseProgress
        self.standProgress = standProgress
    }
    
    public var body: some View {
        ZStack {
            // Stand ring (outermost)
            ProgressRing(
                progress: standProgress,
                lineWidth: 12,
                size: 120,
                primaryColor: .cyan,
                backgroundColor: .cyan.opacity(0.2)
            )
            
            // Exercise ring (middle)
            ProgressRing(
                progress: exerciseProgress,
                lineWidth: 12,
                size: 90,
                primaryColor: .green,
                backgroundColor: .green.opacity(0.2)
            )
            
            // Move ring (innermost)
            ProgressRing(
                progress: moveProgress,
                lineWidth: 12,
                size: 60,
                primaryColor: .red,
                backgroundColor: .red.opacity(0.2)
            )
        }
    }
}

// MARK: - Streak Calendar
public struct StreakCalendar: View {
    let streakDates: Set<DateComponents>
    let currentMonth: Date
    
    @Environment(\.theme) private var theme
    
    public init(streakDates: Set<DateComponents>, currentMonth: Date = Date()) {
        self.streakDates = streakDates
        self.currentMonth = currentMonth
    }
    
    public var body: some View {
        ThemedCard {
            VStack(alignment: .leading, spacing: theme.spacing.md) {
                Text("Workout Streak")
                    .font(theme.typography.titleMedium)
                    .foregroundColor(theme.textPrimary)
                
                CalendarGrid(
                    streakDates: streakDates,
                    currentMonth: currentMonth
                )
            }
        }
    }
}

private struct CalendarGrid: View {
    let streakDates: Set<DateComponents>
    let currentMonth: Date
    
    @Environment(\.theme) private var theme
    
    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    private var monthDays: [Date?] {
        guard let monthRange = calendar.range(of: .day, in: .month, for: currentMonth),
              let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth))
        else { return [] }
        
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth) - 1
        var days: [Date?] = Array(repeating: nil, count: firstWeekday)
        
        for day in monthRange {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth) {
                days.append(date)
            }
        }
        
        while days.count % 7 != 0 {
            days.append(nil)
        }
        
        return days
    }
    
    var body: some View {
        VStack(spacing: theme.spacing.sm) {
            // Month header
            Text(dateFormatter.string(from: currentMonth))
                .font(theme.typography.bodyMedium)
                .foregroundColor(theme.textSecondary)
            
            // Weekday headers
            HStack {
                ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                    Text(day)
                        .font(theme.typography.bodySmall)
                        .foregroundColor(theme.textTertiary)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: theme.spacing.xs) {
                ForEach(Array(monthDays.enumerated()), id: \.offset) { _, date in
                    if let date = date {
                        DayCell(
                            date: date,
                            hasStreak: hasStreak(for: date)
                        )
                    } else {
                        Color.clear
                            .frame(height: 30)
                    }
                }
            }
        }
    }
    
    private func hasStreak(for date: Date) -> Bool {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return streakDates.contains(components)
    }
}

private struct DayCell: View {
    let date: Date
    let hasStreak: Bool
    
    @Environment(\.theme) private var theme
    
    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    var body: some View {
        ZStack {
            if hasStreak {
                Circle()
                    .fill(theme.primaryColor)
                    .frame(width: 30, height: 30)
            } else if isToday {
                Circle()
                    .stroke(theme.primaryColor, lineWidth: 2)
                    .frame(width: 30, height: 30)
            }
            
            Text(dayNumber)
                .font(theme.typography.bodySmall)
                .foregroundColor(hasStreak ? .white : theme.textPrimary)
        }
        .frame(height: 30)
    }
}