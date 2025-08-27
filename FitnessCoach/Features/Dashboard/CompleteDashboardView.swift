import SwiftUI
import HealthKit

struct CompleteDashboardView: View {
    @EnvironmentObject private var dataManager: FitnessDataManager
    @EnvironmentObject private var healthKitManager: HealthKitManager
    @Environment(\.theme) private var theme
    
    @State private var showingQuickWorkout = false
    @State private var showingMealLogger = false
    @State private var showingWeightEntry = false
    @State private var showingGoalSetting = false
    @State private var selectedQuickAction: QuickAction?
    
    private let motivationalQuotes = [
        "The only bad workout is the one that didn't happen.",
        "Your body can do it. It's your mind you need to convince.",
        "Success is what comes after you stop making excuses.",
        "The groundwork for all happiness is good health.",
        "Take care of your body. It's the only place you have to live."
    ]
    
    enum QuickAction: Identifiable {
        case workout, meal, weight, water, goals
        
        var id: String { String(describing: self) }
        
        var title: String {
            switch self {
            case .workout: return "Start Workout"
            case .meal: return "Log Meal"
            case .weight: return "Track Weight"
            case .water: return "Add Water"
            case .goals: return "Set Goal"
            }
        }
        
        var icon: String {
            switch self {
            case .workout: return "figure.strengthtraining.traditional"
            case .meal: return "fork.knife.circle.fill"
            case .weight: return "scalemass.fill"
            case .water: return "drop.fill"
            case .goals: return "target"
            }
        }
        
        var color: Color {
            switch self {
            case .workout: return .blue
            case .meal: return .orange
            case .weight: return .green
            case .water: return .cyan
            case .goals: return .purple
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Welcome Header
                    welcomeHeader
                    
                    // Today's Stats Grid
                    todaysStatsSection
                    
                    // Quick Actions
                    quickActionsSection
                    
                    // Weekly Progress
                    weeklyProgressSection
                    
                    // Recent Workouts
                    recentWorkoutsSection
                    
                    // Motivational Quote
                    motivationalQuoteSection
                    
                    // Goals Overview
                    goalsOverviewSection
                }
                .padding(.horizontal)
                .padding(.bottom, 100) // Extra padding for tab bar
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .background(theme.backgroundColor)
            .refreshable {
                await refreshData()
            }
        }
        .sheet(item: $selectedQuickAction) { action in
            quickActionSheet(for: action)
        }
        .onAppear {
            requestHealthKitPermissionsIfNeeded()
        }
    }
    
    // MARK: - Header Section
    private var welcomeHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(greetingText)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(theme.textPrimary)
                
                Text("Ready to crush your goals?")
                    .font(.subheadline)
                    .foregroundColor(theme.textSecondary)
            }
            
            Spacer()
            
            // Profile Avatar
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [theme.primaryColor, theme.primaryColor.opacity(0.7)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 50, height: 50)
                .overlay(
                    Text(initials)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                )
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Today's Stats
    private var todaysStatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Today's Stats", icon: "chart.bar.fill")
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                StatCard(
                    title: "Calories",
                    value: formatNumber(dataManager.dashboardStats.todayCalories),
                    target: formatNumber(dataManager.dashboardStats.calorieGoal),
                    unit: "cal",
                    progress: dataManager.dashboardStats.todayCalories / dataManager.dashboardStats.calorieGoal,
                    icon: "flame.fill",
                    color: .orange
                )
                
                StatCard(
                    title: "Water",
                    value: "\(dataManager.dashboardStats.waterCups)",
                    target: "\(dataManager.dashboardStats.waterGoal)",
                    unit: "cups",
                    progress: Double(dataManager.dashboardStats.waterCups) / Double(dataManager.dashboardStats.waterGoal),
                    icon: "drop.fill",
                    color: .blue
                )
                
                StatCard(
                    title: "Steps",
                    value: formatNumber(Double(dataManager.dashboardStats.steps)),
                    target: formatNumber(Double(dataManager.dashboardStats.stepsGoal)),
                    unit: "steps",
                    progress: Double(dataManager.dashboardStats.steps) / Double(dataManager.dashboardStats.stepsGoal),
                    icon: "figure.walk",
                    color: .green
                )
                
                StatCard(
                    title: "Active",
                    value: "\(dataManager.dashboardStats.activeMinutes)",
                    target: "\(dataManager.dashboardStats.activeGoal)",
                    unit: "min",
                    progress: Double(dataManager.dashboardStats.activeMinutes) / Double(dataManager.dashboardStats.activeGoal),
                    icon: "heart.fill",
                    color: .red
                )
            }
        }
    }
    
    // MARK: - Quick Actions
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Quick Actions", icon: "bolt.fill")
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach([QuickAction.workout, .meal, .weight, .water, .goals], id: \.id) { action in
                        QuickActionButton(
                            title: action.title,
                            icon: action.icon,
                            color: action.color
                        ) {
                            selectedQuickAction = action
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Weekly Progress
    private var weeklyProgressSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "This Week", icon: "calendar.circle.fill")
            
            VStack(spacing: 12) {
                WeeklyProgressRow(
                    title: "Workouts",
                    current: dataManager.dashboardStats.workoutsThisWeek,
                    target: dataManager.dashboardStats.workoutGoal,
                    unit: "workouts",
                    color: .blue
                )
                
                WeeklyProgressRow(
                    title: "Streak",
                    current: dataManager.dashboardStats.currentStreak,
                    target: nil,
                    unit: dataManager.dashboardStats.currentStreak == 1 ? "day" : "days",
                    color: .orange
                )
                
                WeeklyProgressRow(
                    title: "Best Streak",
                    current: dataManager.dashboardStats.longestStreak,
                    target: nil,
                    unit: dataManager.dashboardStats.longestStreak == 1 ? "day" : "days",
                    color: .purple
                )
            }
            .padding()
            .background(theme.surfaceColor)
            .cornerRadius(16)
        }
    }
    
    // MARK: - Recent Workouts
    private var recentWorkoutsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                SectionHeader(title: "Recent Workouts", icon: "dumbbell.fill")
                Spacer()
                NavigationLink("View All") {
                    // Navigation to workouts tab
                    EmptyView()
                }
                .font(.subheadline)
                .foregroundColor(theme.primaryColor)
            }
            
            if dataManager.workoutSessions.isEmpty {
                EmptyStateCard(
                    icon: "figure.strengthtraining.traditional",
                    title: "No Workouts Yet",
                    message: "Start your first workout to see it here!"
                )
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(dataManager.workoutSessions.suffix(3).reversed()), id: \.id) { session in
                        RecentWorkoutCard(session: session)
                    }
                }
            }
        }
    }
    
    // MARK: - Motivational Quote
    private var motivationalQuoteSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "quote.bubble.fill")
                .font(.title2)
                .foregroundColor(theme.primaryColor)
            
            Text(motivationalQuotes.randomElement() ?? "Stay strong and keep going!")
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(theme.textPrimary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
            
            Text("— Daily Motivation")
                .font(.caption)
                .foregroundColor(theme.textSecondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.primaryColor.opacity(0.1))
        )
    }
    
    // MARK: - Goals Overview
    private var goalsOverviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                SectionHeader(title: "Active Goals", icon: "target")
                Spacer()
                NavigationLink("Manage") {
                    // Navigation to goals view
                    EmptyView()
                }
                .font(.subheadline)
                .foregroundColor(theme.primaryColor)
            }
            
            let activeGoals = dataManager.goals.filter { $0.isActive && !$0.isCompleted }
            
            if activeGoals.isEmpty {
                EmptyStateCard(
                    icon: "target",
                    title: "No Active Goals",
                    message: "Set your first goal to track your progress!"
                )
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(activeGoals.prefix(3)), id: \.id) { goal in
                        GoalProgressCard(goal: goal)
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Properties
    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        case 17..<22: return "Good Evening"
        default: return "Good Night"
        }
    }
    
    private var initials: String {
        guard let profile = dataManager.userProfile else { return "FC" }
        let firstName = profile.name.components(separatedBy: " ").first ?? ""
        let lastName = profile.name.components(separatedBy: " ").last ?? ""
        return String((firstName.prefix(1) + lastName.prefix(1)).uppercased())
    }
    
    private func formatNumber(_ number: Double) -> String {
        if number >= 1000 {
            return String(format: "%.1fk", number / 1000)
        } else {
            return String(format: "%.0f", number)
        }
    }
    
    // MARK: - Quick Action Sheets
    @ViewBuilder
    private func quickActionSheet(for action: QuickAction) -> some View {
        NavigationView {
            switch action {
            case .workout:
                QuickWorkoutView()
            case .meal:
                QuickMealLoggerView()
            case .weight:
                QuickWeightEntryView()
            case .water:
                QuickWaterEntryView()
            case .goals:
                QuickGoalSettingView()
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    
    // MARK: - Data Refresh
    private func refreshData() async {
        // Simulate API refresh
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Update HealthKit data if available
        await updateHealthKitData()
    }
    
    private func updateHealthKitData() async {
        guard healthKitManager.isAuthorized else { return }
        
        do {
            // Fetch latest weight from HealthKit
            if let latestWeight = try await healthKitManager.fetchLatestWeight() {
                dataManager.logWeight(latestWeight)
            }
        } catch {
            print("Failed to fetch HealthKit data: \(error)")
        }
    }
    
    private func requestHealthKitPermissionsIfNeeded() {
        guard !healthKitManager.isAuthorized else { return }
        
        Task {
            do {
                try await healthKitManager.requestAuthorization()
            } catch {
                print("HealthKit authorization failed: \(error)")
            }
        }
    }
}

// MARK: - Supporting Components

struct SectionHeader: View {
    let title: String
    let icon: String
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(theme.primaryColor)
            
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(theme.textPrimary)
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let target: String
    let unit: String
    let progress: Double
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
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(theme.textSecondary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text(value)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(theme.textPrimary)
                    
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)
                }
                
                Text("Goal: \(target) \(unit)")
                    .font(.caption)
                    .foregroundColor(theme.textTertiary)
            }
            
            ProgressView(value: min(progress, 1.0))
                .progressViewStyle(LinearProgressViewStyle(tint: color))
                .scaleEffect(x: 1, y: 0.8, anchor: .center)
        }
        .padding()
        .background(theme.surfaceColor)
        .cornerRadius(16)
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(color)
                    )
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(theme.textPrimary)
                    .multilineTextAlignment(.center)
            }
            .frame(width: 80)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct WeeklyProgressRow: View {
    let title: String
    let current: Int
    let target: Int?
    let unit: String
    let color: Color
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(theme.textPrimary)
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text("\(current)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.textPrimary)
                    
                    if let target = target {
                        Text("/ \(target)")
                            .font(.caption)
                            .foregroundColor(theme.textSecondary)
                    }
                    
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(theme.textTertiary)
                }
                
                if let target = target {
                    ProgressView(value: Double(current) / Double(target))
                        .progressViewStyle(LinearProgressViewStyle(tint: color))
                        .frame(width: 60)
                        .scaleEffect(x: 1, y: 0.6, anchor: .center)
                }
            }
        }
    }
}

struct RecentWorkoutCard: View {
    let session: WorkoutSession
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        HStack {
            // Workout icon
            Image(systemName: "dumbbell.fill")
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(theme.primaryColor)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(session.templateName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(theme.textPrimary)
                
                HStack(spacing: 16) {
                    Label(formatDuration(session.duration), systemImage: "clock")
                    
                    if let calories = session.totalCaloriesBurned {
                        Label("\(Int(calories)) cal", systemImage: "flame")
                    }
                    
                    if let rating = session.rating {
                        HStack(spacing: 2) {
                            ForEach(0..<5) { i in
                                Image(systemName: i < rating ? "star.fill" : "star")
                                    .foregroundColor(.yellow)
                                    .font(.caption)
                            }
                        }
                    }
                }
                .font(.caption)
                .foregroundColor(theme.textSecondary)
            }
            
            Spacer()
            
            Text(RelativeDateTimeFormatter().localizedString(for: session.startTime, relativeTo: Date()))
                .font(.caption)
                .foregroundColor(theme.textTertiary)
        }
        .padding()
        .background(theme.surfaceColor)
        .cornerRadius(12)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        return "\(minutes)m"
    }
}

struct GoalProgressCard: View {
    let goal: Goal
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(goal.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(theme.textPrimary)
                
                Text(goal.description)
                    .font(.caption)
                    .foregroundColor(theme.textSecondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(goal.progress * 100))%")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.primaryColor)
                
                ProgressView(value: goal.progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: theme.primaryColor))
                    .frame(width: 60)
                    .scaleEffect(x: 1, y: 0.6, anchor: .center)
            }
        }
        .padding()
        .background(theme.surfaceColor)
        .cornerRadius(12)
    }
}

struct EmptyStateCard: View {
    let icon: String
    let title: String
    let message: String
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(theme.textTertiary)
            
            Text(title)
                .font(.headline)
                .foregroundColor(theme.textSecondary)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(theme.textTertiary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(theme.surfaceColor)
        .cornerRadius(16)
    }
}

#Preview {
    CompleteDashboardView()
        .environmentObject(FitnessDataManager.shared)
        .environmentObject(HealthKitManager())
        .environmentObject(ThemeManager())
        .theme(FitnessTheme())
}