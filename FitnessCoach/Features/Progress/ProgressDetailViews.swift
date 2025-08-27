import SwiftUI
import Charts

// MARK: - Weight Progress View
struct WeightProgressView: View {
    @EnvironmentObject private var dataManager: FitnessDataManager
    @EnvironmentObject private var timeframeStore: ProgressTimeframeStore
    @Environment(\.theme) private var theme
    
    @State private var showingWeightEntry = false
    
    private var weightDataForTimeframe: [WeightEntry] {
        let timeframe = timeframeStore.selectedTimeframe
        let calendar = Calendar.current
        let now = Date()
        let startDate: Date
        
        switch timeframe {
        case .week:
            startDate = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        case .month:
            startDate = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        case .quarter:
            startDate = calendar.date(byAdding: .month, value: -3, to: now) ?? now
        case .year:
            startDate = calendar.date(byAdding: .year, value: -1, to: now) ?? now
        case .all:
            startDate = Date.distantPast
        }
        
        return dataManager.weightEntries.filter { $0.date >= startDate }
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Weight Chart
                weightChartCard
                
                // Weight Stats
                weightStatsCard
                
                // Recent Entries
                recentEntriesCard
            }
            .padding(.horizontal)
            .padding(.bottom, 100)
        }
    }
    
    private var weightChartCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Weight Trend")
                    .font(.headline)
                    .foregroundColor(theme.textPrimary)
                
                Spacer()
                
                Button("Add Entry") {
                    showingWeightEntry = true
                }
                .font(.caption)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(theme.primaryColor)
                .cornerRadius(8)
            }
            
            if weightDataForTimeframe.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "scalemass")
                        .font(.system(size: 50))
                        .foregroundColor(theme.textTertiary)
                    
                    Text("No Weight Data")
                        .font(.headline)
                        .foregroundColor(theme.textPrimary)
                    
                    Text("Start tracking your weight to see trends")
                        .font(.subheadline)
                        .foregroundColor(theme.textSecondary)
                        .multilineTextAlignment(.center)
                    
                    Button("Log First Weight") {
                        showingWeightEntry = true
                    }
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding()
                    .background(theme.primaryColor)
                    .cornerRadius(12)
                }
                .frame(height: 250)
            } else {
                Chart(weightDataForTimeframe) { entry in
                    LineMark(
                        x: .value("Date", entry.date),
                        y: .value("Weight", entry.weight)
                    )
                    .foregroundStyle(theme.primaryColor)
                    .interpolationMethod(.catmullRom)
                    
                    PointMark(
                        x: .value("Date", entry.date),
                        y: .value("Weight", entry.weight)
                    )
                    .foregroundStyle(theme.primaryColor)
                    .symbolSize(40)
                    
                    if let bodyFat = entry.bodyFatPercentage {
                        LineMark(
                            x: .value("Date", entry.date),
                            y: .value("Body Fat", bodyFat * 10) // Scale for visibility
                        )
                        .foregroundStyle(.orange)
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
                    }
                }
                .frame(height: 250)
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { _ in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel()
                    }
                }
            }
        }
        .padding()
        .background(theme.surfaceColor)
        .cornerRadius(16)
        .sheet(isPresented: $showingWeightEntry) {
            WeightEntryView()
        }
    }
    
    private var weightStatsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Weight Statistics")
                .font(.headline)
                .foregroundColor(theme.textPrimary)
            
            if !weightDataForTimeframe.isEmpty {
                let currentWeight = weightDataForTimeframe.last?.weight ?? 0
                let startWeight = weightDataForTimeframe.first?.weight ?? 0
                let minWeight = weightDataForTimeframe.min(by: { $0.weight < $1.weight })?.weight ?? 0
                let maxWeight = weightDataForTimeframe.max(by: { $0.weight < $1.weight })?.weight ?? 0
                let weightChange = currentWeight - startWeight
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    WeightStatItem(
                        title: "Current",
                        value: String(format: "%.1f", currentWeight),
                        unit: "lbs",
                        color: .blue
                    )
                    
                    WeightStatItem(
                        title: "Change",
                        value: String(format: "%+.1f", weightChange),
                        unit: "lbs",
                        color: weightChange < 0 ? .green : weightChange > 0 ? .red : .gray
                    )
                    
                    WeightStatItem(
                        title: "Lowest",
                        value: String(format: "%.1f", minWeight),
                        unit: "lbs",
                        color: .green
                    )
                    
                    WeightStatItem(
                        title: "Highest",
                        value: String(format: "%.1f", maxWeight),
                        unit: "lbs",
                        color: .orange
                    )
                }
            }
        }
        .padding()
        .background(theme.surfaceColor)
        .cornerRadius(16)
    }
    
    private var recentEntriesCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Entries")
                .font(.headline)
                .foregroundColor(theme.textPrimary)
            
            if weightDataForTimeframe.isEmpty {
                Text("No entries yet")
                    .font(.subheadline)
                    .foregroundColor(theme.textSecondary)
                    .padding(.vertical)
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(weightDataForTimeframe.reversed().prefix(5)), id: \.id) { entry in
                        WeightEntryRow(entry: entry)
                    }
                }
            }
        }
        .padding()
        .background(theme.surfaceColor)
        .cornerRadius(16)
    }
}

struct WeightStatItem: View {
    let title: String
    let value: String
    let unit: String
    let color: Color
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(theme.textSecondary)
            
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                
                Text(unit)
                    .font(.caption)
                    .foregroundColor(theme.textTertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct WeightEntryRow: View {
    let entry: WeightEntry
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(formatDate(entry.date))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(theme.textPrimary)
                
                if let bodyFat = entry.bodyFatPercentage {
                    Text("Body Fat: \(String(format: "%.1f", bodyFat))%")
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)
                }
            }
            
            Spacer()
            
            Text("\(String(format: "%.1f", entry.weight)) lbs")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(theme.primaryColor)
        }
        .padding()
        .background(theme.surfaceColor.opacity(0.5))
        .cornerRadius(8)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(date) {
            return "Today"
        } else if Calendar.current.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
    }
}

// MARK: - Body Measurements View
struct BodyMeasurementsView: View {
    @EnvironmentObject private var dataManager: FitnessDataManager
    @Environment(\.theme) private var theme
    
    @State private var showingMeasurementEntry = false
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Measurements Chart or Empty State
                if dataManager.bodyMeasurements.isEmpty {
                    emptyMeasurementsState
                } else {
                    measurementsChart
                    recentMeasurements
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 100)
        }
    }
    
    private var emptyMeasurementsState: some View {
        VStack(spacing: 20) {
            Image(systemName: "figure.arms.open")
                .font(.system(size: 60))
                .foregroundColor(theme.textTertiary)
            
            Text("No Body Measurements")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(theme.textPrimary)
            
            Text("Track your body measurements to see changes over time")
                .font(.subheadline)
                .foregroundColor(theme.textSecondary)
                .multilineTextAlignment(.center)
            
            Button("Add First Measurement") {
                showingMeasurementEntry = true
            }
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .background(theme.primaryColor)
            .cornerRadius(12)
        }
        .frame(maxHeight: .infinity)
        .padding()
        .sheet(isPresented: $showingMeasurementEntry) {
            BodyMeasurementEntryView()
        }
    }
    
    private var measurementsChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Body Measurements")
                    .font(.headline)
                    .foregroundColor(theme.textPrimary)
                
                Spacer()
                
                Button("Add Entry") {
                    showingMeasurementEntry = true
                }
                .font(.caption)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(theme.primaryColor)
                .cornerRadius(8)
            }
            
            Text("Coming Soon: Body measurement tracking and progress visualization")
                .font(.subheadline)
                .foregroundColor(theme.textSecondary)
                .padding(.vertical, 40)
        }
        .padding()
        .background(theme.surfaceColor)
        .cornerRadius(16)
        .sheet(isPresented: $showingMeasurementEntry) {
            BodyMeasurementEntryView()
        }
    }
    
    private var recentMeasurements: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Measurements")
                .font(.headline)
                .foregroundColor(theme.textPrimary)
            
            Text("Recent entries will appear here")
                .font(.subheadline)
                .foregroundColor(theme.textSecondary)
                .padding(.vertical)
        }
        .padding()
        .background(theme.surfaceColor)
        .cornerRadius(16)
    }
}

// MARK: - Workout Progress View
struct WorkoutProgressView: View {
    @EnvironmentObject private var dataManager: FitnessDataManager
    @EnvironmentObject private var timeframeStore: ProgressTimeframeStore
    @Environment(\.theme) private var theme
    
    private var workoutStats: WorkoutStats {
        dataManager.getWorkoutStats(period: workoutStatsPeriod)
    }
    
    private var workoutStatsPeriod: WorkoutStats.StatsPeriod {
        switch timeframeStore.selectedTimeframe {
        case .week: return .week
        case .month: return .month
        case .quarter: return .quarter
        case .year: return .year
        case .all: return .allTime
        }
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Workout Volume Chart
                workoutVolumeCard
                
                // Strength Progress
                strengthProgressCard
                
                // Workout Frequency
                workoutFrequencyCard
                
                // Favorite Exercises
                favoriteExercisesCard
            }
            .padding(.horizontal)
            .padding(.bottom, 100)
        }
    }
    
    private var workoutVolumeCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Workout Volume")
                .font(.headline)
                .foregroundColor(theme.textPrimary)
            
            HStack(spacing: 20) {
                VStack {
                    Text("\(workoutStats.totalWorkouts)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(theme.primaryColor)
                    
                    Text("Total Workouts")
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)
                }
                
                Divider()
                
                VStack {
                    Text(formatDuration(workoutStats.totalDuration))
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    
                    Text("Total Time")
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)
                }
                
                Divider()
                
                VStack {
                    Text("\(Int(workoutStats.totalCaloriesBurned))")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    
                    Text("Calories Burned")
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical)
        }
        .padding()
        .background(theme.surfaceColor)
        .cornerRadius(16)
    }
    
    private var strengthProgressCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Strength Progress")
                .font(.headline)
                .foregroundColor(theme.textPrimary)
            
            if workoutStats.strengthProgress.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "dumbbell")
                        .font(.title)
                        .foregroundColor(theme.textTertiary)
                    
                    Text("Complete workouts to track strength progress")
                        .font(.subheadline)
                        .foregroundColor(theme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 20)
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(workoutStats.strengthProgress.prefix(5)), id: \.key) { exercise, weight in
                        HStack {
                            Text(exercise)
                                .font(.subheadline)
                                .foregroundColor(theme.textPrimary)
                            
                            Spacer()
                            
                            Text("\(Int(weight)) lbs")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(theme.primaryColor)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .padding()
        .background(theme.surfaceColor)
        .cornerRadius(16)
    }
    
    private var workoutFrequencyCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Workout Frequency")
                .font(.headline)
                .foregroundColor(theme.textPrimary)
            
            HStack(spacing: 20) {
                VStack {
                    Text(String(format: "%.1f", workoutStats.workoutFrequency))
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    
                    Text("Per Week")
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)
                }
                
                Divider()
                
                VStack {
                    Text(formatDuration(workoutStats.averageWorkoutDuration))
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.purple)
                    
                    Text("Avg Duration")
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical)
        }
        .padding()
        .background(theme.surfaceColor)
        .cornerRadius(16)
    }
    
    private var favoriteExercisesCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Most Performed Exercises")
                .font(.headline)
                .foregroundColor(theme.textPrimary)
            
            if workoutStats.favoriteExercises.isEmpty {
                Text("Complete more workouts to see favorite exercises")
                    .font(.subheadline)
                    .foregroundColor(theme.textSecondary)
                    .padding(.vertical)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(workoutStats.favoriteExercises.enumerated()), id: \.offset) { index, exercise in
                        HStack {
                            Text("\(index + 1).")
                                .font(.caption)
                                .foregroundColor(theme.textTertiary)
                                .frame(width: 20, alignment: .leading)
                            
                            Text(exercise)
                                .font(.subheadline)
                                .foregroundColor(theme.textPrimary)
                            
                            Spacer()
                        }
                    }
                }
            }
        }
        .padding()
        .background(theme.surfaceColor)
        .cornerRadius(16)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Goals Progress View
struct GoalsProgressView: View {
    @EnvironmentObject private var dataManager: FitnessDataManager
    @Environment(\.theme) private var theme
    
    @State private var showingGoalCreation = false
    @State private var selectedGoalCategory: Goal.GoalCategory?
    
    private var activeGoals: [Goal] {
        dataManager.goals.filter { $0.isActive && !$0.isCompleted }
    }
    
    private var completedGoals: [Goal] {
        dataManager.goals.filter { $0.isCompleted }
    }
    
    private var filteredActiveGoals: [Goal] {
        if let category = selectedGoalCategory {
            return activeGoals.filter { $0.category == category }
        }
        return activeGoals
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Goals Overview
                goalsOverviewCard
                
                // Category Filter
                if !activeGoals.isEmpty {
                    categoryFilter
                }
                
                // Active Goals
                activeGoalsSection
                
                // Completed Goals
                if !completedGoals.isEmpty {
                    completedGoalsSection
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 100)
        }
    }
    
    private var goalsOverviewCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Goals Overview")
                    .font(.headline)
                    .foregroundColor(theme.textPrimary)
                
                Spacer()
                
                Button("New Goal") {
                    showingGoalCreation = true
                }
                .font(.caption)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(theme.primaryColor)
                .cornerRadius(8)
            }
            
            HStack(spacing: 20) {
                GoalOverviewItem(
                    title: "Active",
                    count: activeGoals.count,
                    color: .blue
                )
                
                GoalOverviewItem(
                    title: "Completed",
                    count: completedGoals.count,
                    color: .green
                )
                
                GoalOverviewItem(
                    title: "On Track",
                    count: activeGoals.filter { $0.progress >= 0.5 }.count,
                    color: .orange
                )
            }
        }
        .padding()
        .background(theme.surfaceColor)
        .cornerRadius(16)
        .sheet(isPresented: $showingGoalCreation) {
            GoalCreationView()
        }
    }
    
    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                CategoryFilterButton(
                    title: "All",
                    isSelected: selectedGoalCategory == nil
                ) {
                    selectedGoalCategory = nil
                }
                
                ForEach(Goal.GoalCategory.allCases, id: \.self) { category in
                    CategoryFilterButton(
                        title: category.rawValue,
                        isSelected: selectedGoalCategory == category
                    ) {
                        selectedGoalCategory = selectedGoalCategory == category ? nil : category
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var activeGoalsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Active Goals")
                .font(.headline)
                .foregroundColor(theme.textPrimary)
            
            if filteredActiveGoals.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "target")
                        .font(.system(size: 50))
                        .foregroundColor(theme.textTertiary)
                    
                    Text("No Active Goals")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(theme.textPrimary)
                    
                    Text("Set your first goal to start tracking progress!")
                        .font(.subheadline)
                        .foregroundColor(theme.textSecondary)
                        .multilineTextAlignment(.center)
                    
                    Button("Create Goal") {
                        showingGoalCreation = true
                    }
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding()
                    .background(theme.primaryColor)
                    .cornerRadius(12)
                }
                .padding(.vertical, 20)
            } else {
                VStack(spacing: 12) {
                    ForEach(filteredActiveGoals, id: \.id) { goal in
                        GoalCard(goal: goal)
                    }
                }
            }
        }
        .padding()
        .background(theme.surfaceColor)
        .cornerRadius(16)
    }
    
    private var completedGoalsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Completed Goals")
                .font(.headline)
                .foregroundColor(theme.textPrimary)
            
            VStack(spacing: 8) {
                ForEach(Array(completedGoals.prefix(5)), id: \.id) { goal in
                    CompletedGoalRow(goal: goal)
                }
                
                if completedGoals.count > 5 {
                    Button("View All (\(completedGoals.count))") {
                        // Navigate to all completed goals
                    }
                    .font(.caption)
                    .foregroundColor(theme.primaryColor)
                }
            }
        }
        .padding()
        .background(theme.surfaceColor)
        .cornerRadius(16)
    }
}

struct GoalOverviewItem: View {
    let title: String
    let count: Int
    let color: Color
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct CategoryFilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : theme.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? theme.primaryColor : theme.surfaceColor)
                .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct GoalCard: View {
    let goal: Goal
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(theme.textPrimary)
                    
                    Text(goal.category.rawValue)
                        .font(.caption)
                        .foregroundColor(goal.categoryColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(goal.categoryColor.opacity(0.1))
                        .cornerRadius(8)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(Int(goal.progress * 100))%")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(theme.primaryColor)
                    
                    Text(daysRemaining(until: goal.targetDate))
                        .font(.caption2)
                        .foregroundColor(theme.textTertiary)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("\(String(format: "%.1f", goal.currentValue))")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(theme.textPrimary)
                    
                    Text("/ \(String(format: "%.0f", goal.targetValue)) \(goal.unit)")
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)
                    
                    Spacer()
                }
                
                ProgressView(value: goal.progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: theme.primaryColor))
                    .scaleEffect(x: 1, y: 1.5, anchor: .center)
            }
            
            if !goal.description.isEmpty && goal.description != goal.title {
                Text(goal.description)
                    .font(.caption)
                    .foregroundColor(theme.textSecondary)
                    .lineLimit(2)
            }
        }
        .padding()
        .background(theme.surfaceColor.opacity(0.5))
        .cornerRadius(12)
    }
    
    private func daysRemaining(until date: Date) -> String {
        let days = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
        if days < 0 {
            return "Overdue"
        } else if days == 0 {
            return "Due today"
        } else if days == 1 {
            return "1 day left"
        } else {
            return "\(days) days left"
        }
    }
}

struct CompletedGoalRow: View {
    let goal: Goal
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(goal.title)
                    .font(.caption)
                    .foregroundColor(theme.textPrimary)
                    .strikethrough()
                
                Text("Completed \(RelativeDateTimeFormatter().localizedString(for: goal.completedAt ?? Date(), relativeTo: Date()))")
                    .font(.caption2)
                    .foregroundColor(theme.textTertiary)
            }
            
            Spacer()
            
            Text(goal.category.rawValue)
                .font(.caption2)
                .foregroundColor(goal.categoryColor)
        }
    }
}

extension Goal {
    var categoryColor: Color {
        switch category {
        case .weight: return .blue
        case .strength: return .red
        case .endurance: return .orange
        case .nutrition: return .green
        case .habit: return .purple
        case .body: return .pink
        }
    }
}

#Preview {
    CompleteProgressView()
        .environmentObject(FitnessDataManager.shared)
        .environmentObject(ThemeManager())
        .theme(FitnessTheme())
}