import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var dataStore: WatchDataStore
    @EnvironmentObject private var healthKitManager: WatchHealthKitManager
    @EnvironmentObject private var hapticManager: HapticManager
    @EnvironmentObject private var watchConnectivity: WatchConnectivityManager
    
    @State private var showingDetailSheet = false
    @State private var selectedMetric: MetricType?
    @State private var isRefreshing = false
    
    enum MetricType: String, CaseIterable {
        case heartRate = "heart_rate"
        case calories = "calories"
        case workouts = "workouts"
        case water = "water"
        
        var title: String {
            switch self {
            case .heartRate: return "Heart Rate"
            case .calories: return "Calories"
            case .workouts: return "Workouts"
            case .water: return "Water"
            }
        }
        
        var icon: String {
            switch self {
            case .heartRate: return "heart.fill"
            case .calories: return "flame.fill"
            case .workouts: return "figure.strengthtraining.traditional"
            case .water: return "drop.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .heartRate: return WatchTheme.Colors.heartRate
            case .calories: return WatchTheme.Colors.calories
            case .workouts: return WatchTheme.Colors.primary
            case .water: return WatchTheme.Colors.water
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: WatchTheme.Spacing.md) {
                // Header
                headerSection
                
                // Quick Stats Grid
                quickStatsGrid
                
                // Activity Rings (if available)
                if healthKitManager.isAuthorized {
                    activityRingsSection
                }
                
                // Recent Activity
                recentActivitySection
                
                // Connection Status
                connectionStatusSection
            }
            .padding(.horizontal, WatchTheme.Spacing.watchPadding)
        }
        .background(WatchTheme.Colors.background)
        .refreshable {
            await refreshData()
        }
        .sheet(isPresented: $showingDetailSheet) {
            if let metric = selectedMetric {
                MetricDetailView(metric: metric)
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: WatchTheme.Spacing.xs) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("FitnessCoach")
                        .font(WatchTheme.Typography.headlineSmall)
                        .foregroundColor(WatchTheme.Colors.textPrimary)
                    
                    Text(currentTimeGreeting)
                        .font(WatchTheme.Typography.bodySmall)
                        .foregroundColor(WatchTheme.Colors.textSecondary)
                }
                
                Spacer()
                
                // Current time
                Text(Date().formatted(date: .omitted, time: .shortened))
                    .font(WatchTheme.Typography.bodySmall)
                    .foregroundColor(WatchTheme.Colors.textSecondary)
            }
        }
        .padding(.bottom, WatchTheme.Spacing.sm)
    }
    
    // MARK: - Quick Stats Grid
    
    private var quickStatsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: WatchTheme.Spacing.sm) {
            // Heart Rate Card
            quickStatCard(
                title: "Heart Rate",
                value: heartRateValue,
                unit: "BPM",
                icon: "heart.fill",
                color: WatchTheme.Colors.heartRate,
                metric: .heartRate
            )
            
            // Calories Card
            quickStatCard(
                title: "Calories",
                value: String(Int(healthKitManager.activeEnergyBurned)),
                unit: "CAL",
                icon: "flame.fill",
                color: WatchTheme.Colors.calories,
                metric: .calories
            )
            
            // Workouts This Week Card
            quickStatCard(
                title: "Workouts",
                value: "\(dataStore.userStats.workoutsThisWeek)",
                unit: "THIS WEEK",
                icon: "figure.strengthtraining.traditional",
                color: WatchTheme.Colors.primary,
                metric: .workouts
            )
            
            // Water Intake Card
            quickStatCard(
                title: "Water",
                value: String(format: "%.0f", dataStore.getTodayWaterIntake()),
                unit: "FL OZ",
                icon: "drop.fill",
                color: WatchTheme.Colors.water,
                metric: .water
            )
        }
    }
    
    private func quickStatCard(
        title: String,
        value: String,
        unit: String,
        icon: String,
        color: Color,
        metric: MetricType
    ) -> some View {
        Button {
            hapticManager.playSelectionHaptic()
            selectedMetric = metric
            showingDetailSheet = true
        } label: {
            VStack(alignment: .leading, spacing: WatchTheme.Spacing.xs) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(color)
                    
                    Spacer()
                }
                
                Text(value)
                    .font(WatchTheme.Typography.displaySmall)
                    .foregroundColor(WatchTheme.Colors.textPrimary)
                    .lineLimit(1)
                
                Text(unit)
                    .font(WatchTheme.Typography.caption)
                    .foregroundColor(WatchTheme.Colors.textSecondary)
                    .lineLimit(1)
            }
            .padding(WatchTheme.Spacing.sm)
            .frame(minHeight: 70)
        }
        .buttonStyle(PlainButtonStyle())
        .background(
            RoundedRectangle(cornerRadius: WatchTheme.CornerRadius.watchCard)
                .fill(WatchTheme.Colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: WatchTheme.CornerRadius.watchCard)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Activity Rings Section
    
    private var activityRingsSection: some View {
        VStack(alignment: .leading, spacing: WatchTheme.Spacing.sm) {
            Text("Activity Rings")
                .font(WatchTheme.Typography.labelLarge)
                .foregroundColor(WatchTheme.Colors.textPrimary)
            
            WatchActivityRingsView()
        }
        .padding(WatchTheme.Spacing.sm)
        .watchCard()
    }
    
    // MARK: - Recent Activity Section
    
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: WatchTheme.Spacing.sm) {
            HStack {
                Text("Recent Activity")
                    .font(WatchTheme.Typography.labelLarge)
                    .foregroundColor(WatchTheme.Colors.textPrimary)
                
                Spacer()
                
                if let lastSync = dataStore.lastSyncDate {
                    Text("Updated \(formatRelativeTime(lastSync))")
                        .font(WatchTheme.Typography.caption)
                        .foregroundColor(WatchTheme.Colors.textTertiary)
                }
            }
            
            if dataStore.recentWorkouts.isEmpty {
                emptyRecentActivityView
            } else {
                recentWorkoutsList
            }
        }
        .padding(WatchTheme.Spacing.sm)
        .watchCard()
    }
    
    private var emptyRecentActivityView: some View {
        VStack(spacing: WatchTheme.Spacing.xs) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 20))
                .foregroundColor(WatchTheme.Colors.textTertiary)
            
            Text("No recent workouts")
                .font(WatchTheme.Typography.bodySmall)
                .foregroundColor(WatchTheme.Colors.textTertiary)
        }
        .padding(WatchTheme.Spacing.md)
    }
    
    private var recentWorkoutsList: some View {
        LazyVStack(spacing: WatchTheme.Spacing.xs) {
            ForEach(Array(dataStore.recentWorkouts.prefix(3)), id: \.id) { workout in
                recentWorkoutRow(workout)
            }
        }
    }
    
    private func recentWorkoutRow(_ workout: WatchWorkout) -> some View {
        HStack {
            // Workout type icon
            Image(systemName: workoutIconName(for: workout.hkActivityType))
                .font(.system(size: 12))
                .foregroundColor(WatchTheme.Colors.primary)
                .frame(width: 16)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(workout.name)
                    .font(WatchTheme.Typography.bodySmall)
                    .foregroundColor(WatchTheme.Colors.textPrimary)
                    .lineLimit(1)
                
                Text(formatWorkoutDetails(workout))
                    .font(WatchTheme.Typography.caption)
                    .foregroundColor(WatchTheme.Colors.textSecondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Text(formatRelativeTime(workout.startDate))
                .font(WatchTheme.Typography.caption)
                .foregroundColor(WatchTheme.Colors.textTertiary)
        }
        .padding(.vertical, 2)
    }
    
    // MARK: - Connection Status Section
    
    private var connectionStatusSection: some View {
        VStack(alignment: .leading, spacing: WatchTheme.Spacing.xs) {
            HStack {
                Image(systemName: watchConnectivity.isConnected ? "iphone.and.apple.watch" : "iphone.slash")
                    .font(.system(size: 12))
                    .foregroundColor(watchConnectivity.isConnected ? WatchTheme.Colors.success : WatchTheme.Colors.textTertiary)
                
                Text(watchConnectivity.connectionStatus.displayText)
                    .font(WatchTheme.Typography.bodySmall)
                    .foregroundColor(WatchTheme.Colors.textSecondary)
                
                Spacer()
                
                if isRefreshing {
                    ProgressView()
                        .scaleEffect(0.6)
                } else {
                    Button {
                        Task {
                            await refreshData()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 12))
                            .foregroundColor(WatchTheme.Colors.primary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(.horizontal, WatchTheme.Spacing.sm)
        .padding(.vertical, WatchTheme.Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: WatchTheme.CornerRadius.sm)
                .fill(WatchTheme.Colors.surface)
        )
    }
    
    // MARK: - Helper Methods
    
    private var currentTimeGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            return "Good Morning"
        case 12..<17:
            return "Good Afternoon"
        case 17..<21:
            return "Good Evening"
        default:
            return "Good Night"
        }
    }
    
    private var heartRateValue: String {
        guard healthKitManager.heartRate > 0 else { return "--" }
        return String(Int(healthKitManager.heartRate))
    }
    
    private func workoutIconName(for activityType: HKWorkoutActivityType) -> String {
        switch activityType {
        case .running:
            return "figure.run"
        case .walking:
            return "figure.walk"
        case .cycling:
            return "figure.outdoor.cycle"
        case .swimming:
            return "figure.pool.swim"
        case .functionalStrengthTraining, .traditionalStrengthTraining:
            return "figure.strengthtraining.traditional"
        case .yoga:
            return "figure.yoga"
        case .dance:
            return "figure.dance"
        default:
            return "figure.strengthtraining.traditional"
        }
    }
    
    private func formatWorkoutDetails(_ workout: WatchWorkout) -> String {
        let duration = formatDuration(workout.duration)
        if let calories = workout.caloriesBurned, calories > 0 {
            return "\(duration) • \(Int(calories)) cal"
        }
        return duration
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds / 60)
        if minutes < 60 {
            return "\(minutes)m"
        }
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        return "\(hours)h \(remainingMinutes)m"
    }
    
    private func formatRelativeTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    private func refreshData() async {
        isRefreshing = true
        hapticManager.playSelectionHaptic()
        
        await watchConnectivity.syncWithPhone()
        
        // Add a small delay to show the refresh animation
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        isRefreshing = false
    }
}

// MARK: - Metric Detail View

struct MetricDetailView: View {
    let metric: DashboardView.MetricType
    @EnvironmentObject private var dataStore: WatchDataStore
    @EnvironmentObject private var healthKitManager: WatchHealthKitManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: WatchTheme.Spacing.md) {
                // Header
                HStack {
                    Image(systemName: metric.icon)
                        .font(.system(size: 24))
                        .foregroundColor(metric.color)
                    
                    Text(metric.title)
                        .font(WatchTheme.Typography.headlineMedium)
                        .foregroundColor(WatchTheme.Colors.textPrimary)
                    
                    Spacer()
                    
                    Button("Done") {
                        dismiss()
                    }
                    .font(WatchTheme.Typography.labelMedium)
                    .foregroundColor(WatchTheme.Colors.primary)
                }
                
                // Metric-specific content
                switch metric {
                case .heartRate:
                    heartRateDetailView
                case .calories:
                    caloriesDetailView
                case .workouts:
                    workoutsDetailView
                case .water:
                    waterDetailView
                }
                
                Spacer()
            }
            .padding(WatchTheme.Spacing.md)
        }
        .background(WatchTheme.Colors.background)
    }
    
    private var heartRateDetailView: some View {
        VStack(alignment: .leading, spacing: WatchTheme.Spacing.sm) {
            Text("Current: \(Int(healthKitManager.heartRate)) BPM")
                .font(WatchTheme.Typography.displayMedium)
                .foregroundColor(WatchTheme.Colors.textPrimary)
            
            Text("Real-time heart rate from Apple Watch sensors")
                .font(WatchTheme.Typography.bodySmall)
                .foregroundColor(WatchTheme.Colors.textSecondary)
        }
    }
    
    private var caloriesDetailView: some View {
        VStack(alignment: .leading, spacing: WatchTheme.Spacing.sm) {
            Text("\(Int(healthKitManager.activeEnergyBurned)) cal")
                .font(WatchTheme.Typography.displayMedium)
                .foregroundColor(WatchTheme.Colors.textPrimary)
            
            Text("Active calories burned today")
                .font(WatchTheme.Typography.bodySmall)
                .foregroundColor(WatchTheme.Colors.textSecondary)
        }
    }
    
    private var workoutsDetailView: some View {
        VStack(alignment: .leading, spacing: WatchTheme.Spacing.sm) {
            Text("\(dataStore.userStats.workoutsThisWeek) of \(dataStore.userStats.workoutGoal)")
                .font(WatchTheme.Typography.displayMedium)
                .foregroundColor(WatchTheme.Colors.textPrimary)
            
            Text("Workouts completed this week")
                .font(WatchTheme.Typography.bodySmall)
                .foregroundColor(WatchTheme.Colors.textSecondary)
        }
    }
    
    private var waterDetailView: some View {
        VStack(alignment: .leading, spacing: WatchTheme.Spacing.sm) {
            Text("\(String(format: "%.0f", dataStore.getTodayWaterIntake())) fl oz")
                .font(WatchTheme.Typography.displayMedium)
                .foregroundColor(WatchTheme.Colors.textPrimary)
            
            Text("Water consumed today")
                .font(WatchTheme.Typography.bodySmall)
                .foregroundColor(WatchTheme.Colors.textSecondary)
        }
    }
}

#Preview("Dashboard") {
    DashboardView()
        .environmentObject(WatchDataStore())
        .environmentObject(WatchHealthKitManager())
        .environmentObject(HapticManager())
        .environmentObject(WatchConnectivityManager())
}

#Preview("Metric Detail") {
    MetricDetailView(metric: .heartRate)
        .environmentObject(WatchDataStore())
        .environmentObject(WatchHealthKitManager())
}