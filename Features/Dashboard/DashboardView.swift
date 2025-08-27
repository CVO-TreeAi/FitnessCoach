import SwiftUI

public struct DashboardView: View {
    @StateObject private var viewModel: DashboardViewModel
    @EnvironmentObject private var authManager: AuthenticationManager
    @EnvironmentObject private var healthKitManager: HealthKitManager
    @Environment(\.theme) private var theme
    
    public init() {
        // This will be updated when the view is created with environment objects
        self._viewModel = StateObject(wrappedValue: DashboardViewModel(
            healthKitManager: HealthKitManager(),
            authManager: AuthenticationManager()
        ))
    }
    
    public var body: some View {
        NavigationView {
            ZStack {
                theme.backgroundColor.ignoresSafeArea()
                
                if viewModel.isLoading {
                    LoadingView(message: "Loading dashboard...")
                } else {
                    ScrollView {
                        LazyVStack(spacing: theme.spacing.lg) {
                            // Header
                            headerSection
                            
                            // Quick Stats Grid
                            quickStatsSection
                            
                            // Progress Charts
                            progressChartsSection
                            
                            // Today's Goals
                            todaysGoalsSection
                            
                            // Recent Activity
                            recentActivitySection
                            
                            // Upcoming Workouts
                            upcomingWorkoutsSection
                            
                            // Weekly Summary
                            weeklySummarySection
                        }
                        .padding(.horizontal, theme.spacing.lg)
                        .padding(.bottom, theme.spacing.xl)
                    }
                    .refreshable {
                        await viewModel.refresh()
                    }
                }
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        // Settings action
                    } label: {
                        Image(systemName: "person.circle")
                            .foregroundColor(theme.primaryColor)
                    }
                }
            }
        }
        .onAppear {
            // Update view model with environment objects
            updateViewModel()
            Task {
                await viewModel.loadDashboardData()
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                Text(greetingText)
                    .font(theme.titleLargeFont)
                    .foregroundColor(theme.textPrimary)
                
                if let user = authManager.currentUser {
                    Text(user.firstName)
                        .font(theme.titleMediumFont)
                        .foregroundColor(theme.primaryColor)
                }
                
                Text(todayDateText)
                    .font(theme.bodyMediumFont)
                    .foregroundColor(theme.textSecondary)
            }
            
            Spacer()
            
            // Profile picture or avatar
            Circle()
                .fill(theme.primaryColor.gradient)
                .frame(width: 56, height: 56)
                .overlay(
                    Text(userInitials)
                        .font(theme.titleMediumFont)
                        .foregroundColor(.white)
                )
        }
        .padding(.top, theme.spacing.md)
    }
    
    // MARK: - Quick Stats Section
    
    private var quickStatsSection: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ],
            spacing: theme.spacing.md
        ) {
            if let currentWeight = viewModel.currentWeight {
                ThemedStatCard(
                    title: "Current Weight",
                    value: "\(Int(currentWeight)) lbs",
                    subtitle: goalWeightSubtitle,
                    icon: Image(systemName: "scalemass"),
                    trend: weightTrend,
                    trendValue: weightTrendValue
                )
            }
            
            ThemedStatCard(
                title: "Workouts This Week",
                value: "\(viewModel.weeklyStats.workoutsCompleted)",
                subtitle: "Target: 4",
                icon: Image(systemName: "figure.strengthtraining.traditional"),
                trend: workoutTrend,
                trendValue: workoutTrendValue
            )
            
            ThemedStatCard(
                title: "Today's Calories",
                value: "\(Int(viewModel.todayCalories))",
                subtitle: "Target: \(Int(viewModel.targetCalories))",
                icon: Image(systemName: "flame.fill"),
                trend: caloriesTrend,
                trendValue: caloriesTrendValue
            )
            
            ThemedStatCard(
                title: "Today's Protein",
                value: "\(Int(viewModel.todayProtein))g",
                subtitle: "Target: \(Int(viewModel.targetProtein))g",
                icon: Image(systemName: "leaf.fill"),
                trend: proteinTrend,
                trendValue: proteinTrendValue
            )
        }
    }
    
    // MARK: - Progress Charts Section
    
    private var progressChartsSection: some View {
        VStack(spacing: theme.spacing.lg) {
            SectionHeader(
                "Progress Tracking",
                subtitle: "Your fitness journey over time"
            )
            
            VStack(spacing: theme.spacing.md) {
                // Weight Progress Chart
                if !viewModel.weightProgress.isEmpty {
                    ProgressChart(
                        data: viewModel.weightProgress,
                        title: "Weight Progress",
                        yAxisLabel: "Weight (lbs)",
                        color: .blue
                    )
                }
                
                // Weekly Workouts Chart
                if #available(iOS 16.0, *) {
                    WeeklyWorkoutChart(
                        data: viewModel.weeklyWorkouts,
                        title: "Weekly Workout Minutes"
                    )
                }
                
                // Macro Breakdown Chart
                if viewModel.todayCalories > 0 {
                    MacroChart(
                        protein: viewModel.todayProtein,
                        carbs: viewModel.todayCarbs,
                        fat: viewModel.todayFat,
                        title: "Today's Macros"
                    )
                }
            }
        }
    }
    
    // MARK: - Today's Goals Section
    
    private var todaysGoalsSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            SectionHeader(
                "Today's Goals",
                subtitle: "\(viewModel.todayGoals.count) active goals",
                actionTitle: "View All"
            ) {
                // Navigate to goals view
            }
            
            if viewModel.todayGoals.isEmpty {
                InlineEmptyStateView(
                    message: "No active goals. Set some goals to track your progress!",
                    iconName: "target"
                )
            } else {
                VStack(spacing: theme.spacing.sm) {
                    ForEach(viewModel.todayGoals) { goal in
                        GoalProgressRow(goal: goal)
                    }
                }
            }
        }
    }
    
    // MARK: - Recent Activity Section
    
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            SectionHeader(
                "Recent Workouts",
                subtitle: "Your latest activity",
                actionTitle: "View All"
            ) {
                // Navigate to workouts view
            }
            
            if viewModel.recentWorkouts.isEmpty {
                InlineEmptyStateView(
                    message: "No recent workouts. Start your first workout!",
                    iconName: "figure.strengthtraining.traditional"
                )
            } else {
                VStack(spacing: theme.spacing.sm) {
                    ForEach(viewModel.recentWorkouts.prefix(3)) { workout in
                        RecentWorkoutRow(workout: workout)
                    }
                }
            }
        }
    }
    
    // MARK: - Upcoming Workouts Section
    
    private var upcomingWorkoutsSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            SectionHeader(
                "Upcoming Workouts",
                subtitle: "Your scheduled sessions"
            )
            
            if viewModel.upcomingWorkouts.isEmpty {
                InlineEmptyStateView(
                    message: "No upcoming workouts scheduled",
                    iconName: "calendar"
                )
            } else {
                VStack(spacing: theme.spacing.sm) {
                    ForEach(viewModel.upcomingWorkouts.prefix(2)) { workout in
                        UpcomingWorkoutRow(workout: workout)
                    }
                }
            }
        }
    }
    
    // MARK: - Weekly Summary Section
    
    private var weeklySummarySection: some View {
        ThemedCard {
            VStack(alignment: .leading, spacing: theme.spacing.md) {
                Text("Weekly Summary")
                    .font(theme.titleMediumFont)
                    .foregroundColor(theme.textPrimary)
                
                LazyVGrid(
                    columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ],
                    spacing: theme.spacing.md
                ) {
                    WeeklySummaryItem(
                        icon: "figure.walk",
                        title: "Workouts",
                        value: "\(viewModel.weeklyStats.workoutsCompleted)",
                        subtitle: "completed"
                    )
                    
                    WeeklySummaryItem(
                        icon: "clock",
                        title: "Active Time",
                        value: "\(viewModel.weeklyStats.totalWorkoutTime)",
                        subtitle: "minutes"
                    )
                    
                    WeeklySummaryItem(
                        icon: "flame",
                        title: "Avg Calories",
                        value: "\(viewModel.weeklyStats.averageCalories)",
                        subtitle: "per day"
                    )
                    
                    WeeklySummaryItem(
                        icon: "leaf",
                        title: "Avg Protein",
                        value: "\(viewModel.weeklyStats.averageProtein)g",
                        subtitle: "per day"
                    )
                }
                
                if viewModel.weeklyStats.workoutStreak > 1 {
                    HStack {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                        Text("\(viewModel.weeklyStats.workoutStreak)-day workout streak!")
                            .font(theme.bodyMediumFont)
                            .foregroundColor(theme.textPrimary)
                    }
                    .padding(.top, theme.spacing.sm)
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
    
    private var todayDateText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date())
    }
    
    private var userInitials: String {
        guard let user = authManager.currentUser else { return "FG" }
        let first = String(user.firstName.prefix(1))
        let last = String(user.lastName.prefix(1))
        return "\(first)\(last)".uppercased()
    }
    
    private var goalWeightSubtitle: String {
        if let goalWeight = viewModel.goalWeight {
            return "Goal: \(Int(goalWeight)) lbs"
        }
        return "No goal set"
    }
    
    private var weightTrend: ThemedStatCard.TrendDirection? {
        guard let weightChange = viewModel.weeklyStats.weightChange else { return nil }
        if weightChange > 0 { return .up }
        else if weightChange < 0 { return .down }
        else { return .neutral }
    }
    
    private var weightTrendValue: String? {
        guard let weightChange = viewModel.weeklyStats.weightChange else { return nil }
        let absChange = abs(weightChange)
        return String(format: "%.1f lbs", absChange)
    }
    
    private var workoutTrend: ThemedStatCard.TrendDirection {
        return viewModel.weeklyStats.workoutsCompleted >= 4 ? .up : .down
    }
    
    private var workoutTrendValue: String {
        let percentage = (Double(viewModel.weeklyStats.workoutsCompleted) / 4.0) * 100
        return "\(Int(percentage))%"
    }
    
    private var caloriesTrend: ThemedStatCard.TrendDirection {
        let percentage = viewModel.todayCalories / viewModel.targetCalories
        if percentage >= 0.9 && percentage <= 1.1 { return .neutral }
        else if percentage > 1.1 { return .up }
        else { return .down }
    }
    
    private var caloriesTrendValue: String {
        let percentage = (viewModel.todayCalories / viewModel.targetCalories) * 100
        return "\(Int(percentage))%"
    }
    
    private var proteinTrend: ThemedStatCard.TrendDirection {
        let percentage = viewModel.todayProtein / viewModel.targetProtein
        return percentage >= 0.8 ? .up : .down
    }
    
    private var proteinTrendValue: String {
        let percentage = (viewModel.todayProtein / viewModel.targetProtein) * 100
        return "\(Int(percentage))%"
    }
    
    // MARK: - Helper Methods
    
    private func updateViewModel() {
        // Create new view model with correct environment objects
        let newViewModel = DashboardViewModel(
            healthKitManager: healthKitManager,
            authManager: authManager
        )
        _viewModel.wrappedValue = newViewModel
    }
}

// MARK: - Supporting Views

private struct GoalProgressRow: View {
    let goal: DashboardGoal
    @Environment(\.theme) private var theme
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                Text(goal.title)
                    .font(theme.bodyMediumFont)
                    .foregroundColor(theme.textPrimary)
                
                Text("\(goal.formattedCurrentValue) / \(goal.formattedTargetValue)")
                    .font(theme.bodySmallFont)
                    .foregroundColor(theme.textSecondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: theme.spacing.xs) {
                Text("\(Int(goal.progress * 100))%")
                    .font(theme.bodyMediumFont)
                    .foregroundColor(theme.primaryColor)
                
                ProgressView(value: goal.progress)
                    .progressViewStyle(.linear)
                    .tint(theme.primaryColor)
                    .frame(width: 60)
            }
        }
        .padding(theme.spacing.md)
        .background(theme.surfaceColor)
        .cornerRadius(theme.cornerRadius.medium)
    }
}

private struct RecentWorkoutRow: View {
    let workout: DashboardWorkout
    @Environment(\.theme) private var theme
    
    var body: some View {
        HStack(spacing: theme.spacing.md) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundColor(.green)
            
            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                Text(workout.name)
                    .font(theme.bodyMediumFont)
                    .foregroundColor(theme.textPrimary)
                
                HStack(spacing: theme.spacing.sm) {
                    Text(formatDate(workout.date))
                        .font(theme.bodySmallFont)
                        .foregroundColor(theme.textSecondary)
                    
                    Text("• \(workout.duration)m")
                        .font(theme.bodySmallFont)
                        .foregroundColor(theme.textSecondary)
                    
                    Text("• \(workout.caloriesBurned) cal")
                        .font(theme.bodySmallFont)
                        .foregroundColor(theme.textSecondary)
                }
            }
            
            Spacer()
        }
        .padding(theme.spacing.md)
        .background(theme.surfaceColor)
        .cornerRadius(theme.cornerRadius.medium)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

private struct UpcomingWorkoutRow: View {
    let workout: DashboardWorkout
    @Environment(\.theme) private var theme
    
    var body: some View {
        HStack(spacing: theme.spacing.md) {
            Image(systemName: "calendar")
                .font(.title2)
                .foregroundColor(theme.primaryColor)
            
            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                Text(workout.name)
                    .font(theme.bodyMediumFont)
                    .foregroundColor(theme.textPrimary)
                
                Text(formatDate(workout.date))
                    .font(theme.bodySmallFont)
                    .foregroundColor(theme.textSecondary)
            }
            
            Spacer()
            
            ThemedButton("Start", style: .primary, size: .small) {
                // Start workout action
            }
        }
        .padding(theme.spacing.md)
        .background(theme.surfaceColor)
        .cornerRadius(theme.cornerRadius.medium)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

private struct WeeklySummaryItem: View {
    let icon: String
    let title: String
    let value: String
    let subtitle: String
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(spacing: theme.spacing.sm) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(theme.primaryColor)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                Text(value)
                    .font(theme.titleMediumFont)
                    .foregroundColor(theme.textPrimary)
                
                Text("\(title) \(subtitle)")
                    .font(theme.bodySmallFont)
                    .foregroundColor(theme.textSecondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Preview

#Preview {
    DashboardView()
        .environmentObject(AuthenticationManager())
        .environmentObject(HealthKitManager())
        .theme(FitnessTheme())
}