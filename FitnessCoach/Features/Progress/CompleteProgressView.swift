import SwiftUI
import Charts

struct CompleteProgressView: View {
    @EnvironmentObject private var dataManager: FitnessDataManager
    @Environment(\.theme) private var theme
    
    @State private var selectedTab: ProgressTab = .overview
    @State private var selectedTimeframe: ProgressTimeframe = .month
    @State private var showingGoalCreation = false
    @State private var showingWeightEntry = false
    @State private var showingMeasurementEntry = false
    @State private var showingPhotoCapture = false
    
    enum ProgressTab: String, CaseIterable {
        case overview = "Overview"
        case weight = "Weight"
        case measurements = "Body"
        case workouts = "Workouts"
        case goals = "Goals"
        
        var icon: String {
            switch self {
            case .overview: return "chart.line.uptrend.xyaxis"
            case .weight: return "scalemass.fill"
            case .measurements: return "figure.arms.open"
            case .workouts: return "dumbbell.fill"
            case .goals: return "target"
            }
        }
    }
    
    enum ProgressTimeframe: String, CaseIterable {
        case week = "1W"
        case month = "1M"
        case quarter = "3M"
        case year = "1Y"
        case all = "All"
        
        var displayName: String {
            switch self {
            case .week: return "This Week"
            case .month: return "This Month"
            case .quarter: return "3 Months"
            case .year: return "This Year"
            case .all: return "All Time"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Custom Tab Bar
                progressTabBar
                
                // Timeframe Selector (only for relevant tabs)
                if selectedTab != .goals {
                    timeframeSelector
                }
                
                // Content
                TabView(selection: $selectedTab) {
                    ProgressOverviewView()
                        .tag(ProgressTab.overview)
                    
                    WeightProgressView()
                        .tag(ProgressTab.weight)
                    
                    BodyMeasurementsView()
                        .tag(ProgressTab.measurements)
                    
                    WorkoutProgressView()
                        .tag(ProgressTab.workouts)
                    
                    GoalsProgressView()
                        .tag(ProgressTab.goals)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("Progress")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Log Weight", systemImage: "scalemass") {
                            showingWeightEntry = true
                        }
                        
                        Button("Body Measurements", systemImage: "figure.arms.open") {
                            showingMeasurementEntry = true
                        }
                        
                        Button("Progress Photo", systemImage: "camera") {
                            showingPhotoCapture = true
                        }
                        
                        Button("Set Goal", systemImage: "target") {
                            showingGoalCreation = true
                        }
                    } label: {
                        Image(systemName: "plus.circle")
                            .font(.title2)
                    }
                }
            }
        }
        .sheet(isPresented: $showingGoalCreation) {
            GoalCreationView()
        }
        .sheet(isPresented: $showingWeightEntry) {
            WeightEntryView()
        }
        .sheet(isPresented: $showingMeasurementEntry) {
            BodyMeasurementEntryView()
        }
        .sheet(isPresented: $showingPhotoCapture) {
            ProgressPhotoView()
        }
        .environmentObject(ProgressTimeframeStore(selectedTimeframe: $selectedTimeframe))
    }
    
    private var progressTabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(ProgressTab.allCases, id: \.self) { tab in
                    ProgressTabButton(
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
    
    private var timeframeSelector: some View {
        HStack {
            ForEach(ProgressTimeframe.allCases, id: \.self) { timeframe in
                Button(timeframe.rawValue) {
                    selectedTimeframe = timeframe
                }
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(selectedTimeframe == timeframe ? .white : theme.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(selectedTimeframe == timeframe ? theme.primaryColor : Color.clear)
                .cornerRadius(16)
            }
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
}

// Progress Tab Button
struct ProgressTabButton: View {
    let tab: CompleteProgressView.ProgressTab
    let isSelected: Bool
    let action: () -> Void
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.subheadline)
                
                Text(tab.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(isSelected ? .white : theme.textPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                isSelected ? theme.primaryColor : theme.surfaceColor
            )
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Timeframe Store for sharing between views
class ProgressTimeframeStore: ObservableObject {
    @Binding var selectedTimeframe: CompleteProgressView.ProgressTimeframe
    
    init(selectedTimeframe: Binding<CompleteProgressView.ProgressTimeframe>) {
        self._selectedTimeframe = selectedTimeframe
    }
}

// MARK: - Progress Overview View
struct ProgressOverviewView: View {
    @EnvironmentObject private var dataManager: FitnessDataManager
    @EnvironmentObject private var timeframeStore: ProgressTimeframeStore
    @Environment(\.theme) private var theme
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Summary Cards
                summaryCards
                
                // Weight Chart
                weightChartCard
                
                // Workout Stats
                workoutStatsCard
                
                // Recent Achievements
                achievementsCard
                
                // Active Goals Preview
                activeGoalsPreview
            }
            .padding(.horizontal)
            .padding(.bottom, 100)
        }
    }
    
    private var summaryCards: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            SummaryCard(
                title: "Current Weight",
                value: currentWeightText,
                change: weightChangeText,
                changeColor: weightChangeColor,
                icon: "scalemass.fill",
                color: .blue
            )
            
            SummaryCard(
                title: "Workouts",
                value: "\(workoutCount)",
                change: workoutChangeText,
                changeColor: .green,
                icon: "dumbbell.fill",
                color: .orange
            )
            
            SummaryCard(
                title: "Personal Records",
                value: "\(personalRecordsCount)",
                change: prChangeText,
                changeColor: .green,
                icon: "trophy.fill",
                color: .yellow
            )
            
            SummaryCard(
                title: "Active Goals",
                value: "\(activeGoalsCount)",
                change: "\(completedGoalsCount) completed",
                changeColor: .green,
                icon: "target",
                color: .purple
            )
        }
    }
    
    private var weightChartCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Weight Trend")
                    .font(.headline)
                    .foregroundColor(theme.textPrimary)
                
                Spacer()
                
                Text(timeframeStore.selectedTimeframe.displayName)
                    .font(.caption)
                    .foregroundColor(theme.textSecondary)
            }
            
            if !weightDataForTimeframe.isEmpty {
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
                    .symbolSize(30)
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel()
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { _ in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel()
                    }
                }
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.title)
                        .foregroundColor(theme.textTertiary)
                    
                    Text("No weight data yet")
                        .font(.subheadline)
                        .foregroundColor(theme.textSecondary)
                }
                .frame(height: 200)
            }
        }
        .padding()
        .background(theme.surfaceColor)
        .cornerRadius(16)
    }
    
    private var workoutStatsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Workout Summary")
                .font(.headline)
                .foregroundColor(theme.textPrimary)
            
            let stats = dataManager.getWorkoutStats(period: workoutStatsPeriod)
            
            HStack(spacing: 20) {
                WorkoutStatColumn(
                    title: "Total Time",
                    value: formatDuration(stats.totalDuration),
                    color: .blue
                )
                
                WorkoutStatColumn(
                    title: "Calories Burned",
                    value: "\(Int(stats.totalCaloriesBurned))",
                    color: .red
                )
                
                WorkoutStatColumn(
                    title: "Avg Duration",
                    value: formatDuration(stats.averageWorkoutDuration),
                    color: .green
                )
                
                WorkoutStatColumn(
                    title: "Frequency",
                    value: String(format: "%.1f/week", stats.workoutFrequency),
                    color: .purple
                )
            }
        }
        .padding()
        .background(theme.surfaceColor)
        .cornerRadius(16)
    }
    
    private var achievementsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Achievements")
                    .font(.headline)
                    .foregroundColor(theme.textPrimary)
                
                Spacer()
                
                NavigationLink("View All") {
                    PersonalRecordsView()
                }
                .font(.caption)
                .foregroundColor(theme.primaryColor)
            }
            
            if recentPersonalRecords.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "trophy")
                        .font(.title)
                        .foregroundColor(theme.textTertiary)
                    
                    Text("Complete workouts to earn achievements!")
                        .font(.subheadline)
                        .foregroundColor(theme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 20)
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(recentPersonalRecords.prefix(3)), id: \.id) { record in
                        PersonalRecordRow(record: record)
                    }
                }
            }
        }
        .padding()
        .background(theme.surfaceColor)
        .cornerRadius(16)
    }
    
    private var activeGoalsPreview: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Active Goals")
                    .font(.headline)
                    .foregroundColor(theme.textPrimary)
                
                Spacer()
                
                Button("Manage") {
                    // Navigate to goals view
                }
                .font(.caption)
                .foregroundColor(theme.primaryColor)
            }
            
            let activeGoals = dataManager.goals.filter { $0.isActive && !$0.isCompleted }
            
            if activeGoals.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "target")
                        .font(.title)
                        .foregroundColor(theme.textTertiary)
                    
                    Text("Set your first goal to track progress!")
                        .font(.subheadline)
                        .foregroundColor(theme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 20)
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(activeGoals.prefix(3)), id: \.id) { goal in
                        GoalProgressRow(goal: goal)
                    }
                }
            }
        }
        .padding()
        .background(theme.surfaceColor)
        .cornerRadius(16)
    }
    
    // Computed Properties
    private var currentWeightText: String {
        if let latestWeight = dataManager.weightEntries.last?.weight {
            return "\(Int(latestWeight)) lbs"
        }
        return "-- lbs"
    }
    
    private var weightChangeText: String {
        guard dataManager.weightEntries.count >= 2 else { return "No change" }
        
        let latest = dataManager.weightEntries.last!.weight
        let previous = dataManager.weightEntries[dataManager.weightEntries.count - 2].weight
        let change = latest - previous
        
        let sign = change >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", change)) lbs"
    }
    
    private var weightChangeColor: Color {
        guard dataManager.weightEntries.count >= 2 else { return .gray }
        
        let latest = dataManager.weightEntries.last!.weight
        let previous = dataManager.weightEntries[dataManager.weightEntries.count - 2].weight
        let change = latest - previous
        
        return change < 0 ? .green : change > 0 ? .red : .gray
    }
    
    private var workoutCount: Int {
        getWorkoutSessionsForTimeframe().filter { $0.isCompleted }.count
    }
    
    private var workoutChangeText: String {
        let currentPeriodCount = workoutCount
        // For simplicity, assume "vs last period" comparison
        return "\(currentPeriodCount) this period"
    }
    
    private var personalRecordsCount: Int {
        dataManager.personalRecords.count
    }
    
    private var prChangeText: String {
        let recentPRs = dataManager.personalRecords.filter { record in
            let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
            return record.achievedAt >= thirtyDaysAgo
        }
        return "+\(recentPRs.count) this month"
    }
    
    private var activeGoalsCount: Int {
        dataManager.goals.filter { $0.isActive && !$0.isCompleted }.count
    }
    
    private var completedGoalsCount: Int {
        dataManager.goals.filter { $0.isCompleted }.count
    }
    
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
    
    private var recentPersonalRecords: [PersonalRecord] {
        dataManager.personalRecords
            .sorted { $0.achievedAt > $1.achievedAt }
            .prefix(5)
            .map { $0 }
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
    
    private func getWorkoutSessionsForTimeframe() -> [WorkoutSession] {
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
        
        return dataManager.workoutSessions.filter { $0.startTime >= startDate }
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

// MARK: - Supporting Components

struct SummaryCard: View {
    let title: String
    let value: String
    let change: String
    let changeColor: Color
    let icon: String
    let color: Color
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(theme.textPrimary)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(theme.textSecondary)
                
                Text(change)
                    .font(.caption2)
                    .foregroundColor(changeColor)
            }
        }
        .padding()
        .background(theme.surfaceColor)
        .cornerRadius(16)
    }
}

struct WorkoutStatColumn: View {
    let title: String
    let value: String
    let color: Color
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(theme.textPrimary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(theme.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
    }
}

struct PersonalRecordRow: View {
    let record: PersonalRecord
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        HStack {
            Image(systemName: "trophy.fill")
                .font(.caption)
                .foregroundColor(.yellow)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(record.exerciseName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(theme.textPrimary)
                
                Text(record.recordType.rawValue)
                    .font(.caption2)
                    .foregroundColor(theme.textSecondary)
            }
            
            Spacer()
            
            Text("\(Int(record.value)) \(record.unit)")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(theme.primaryColor)
            
            Text(relativeDateString(record.achievedAt))
                .font(.caption2)
                .foregroundColor(theme.textTertiary)
        }
    }
    
    private func relativeDateString(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .named
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct GoalProgressRow: View {
    let goal: Goal
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(goal.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(theme.textPrimary)
                    .lineLimit(1)
                
                Text("\(Int(goal.currentValue))/\(Int(goal.targetValue)) \(goal.unit)")
                    .font(.caption2)
                    .foregroundColor(theme.textSecondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(goal.progress * 100))%")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(theme.primaryColor)
                
                ProgressView(value: goal.progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: theme.primaryColor))
                    .frame(width: 50)
                    .scaleEffect(x: 1, y: 0.6, anchor: .center)
            }
        }
    }
}

#Preview {
    CompleteProgressView()
        .environmentObject(FitnessDataManager.shared)
        .environmentObject(ThemeManager())
        .theme(FitnessTheme())
}