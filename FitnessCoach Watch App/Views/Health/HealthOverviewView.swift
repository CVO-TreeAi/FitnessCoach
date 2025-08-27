import SwiftUI

struct HealthOverviewView: View {
    @EnvironmentObject private var healthKitManager: WatchHealthKitManager
    @EnvironmentObject private var hapticManager: HapticManager
    @EnvironmentObject private var dataStore: WatchDataStore
    
    @State private var selectedTab = 0
    @State private var showingDetailView = false
    @State private var selectedHealthMetric: HealthMetric?
    @State private var activityRingsData: ActivityRingsData?
    
    enum HealthMetric: String, CaseIterable {
        case heartRate = "heart_rate"
        case calories = "calories"
        case activity = "activity"
        case body = "body"
        
        var title: String {
            switch self {
            case .heartRate: return "Heart Rate"
            case .calories: return "Calories"
            case .activity: return "Activity"
            case .body: return "Body Metrics"
            }
        }
        
        var icon: String {
            switch self {
            case .heartRate: return "heart.fill"
            case .calories: return "flame.fill"
            case .activity: return "figure.walk"
            case .body: return "figure.arms.open"
            }
        }
        
        var color: Color {
            switch self {
            case .heartRate: return WatchTheme.Colors.heartRate
            case .calories: return WatchTheme.Colors.calories
            case .activity: return WatchTheme.Colors.steps
            case .body: return WatchTheme.Colors.primary
            }
        }
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Activity Rings Tab
            activityRingsTab
                .tag(0)
            
            // Heart Rate Tab
            heartRateTab
                .tag(1)
            
            // Calories Tab
            caloriesTab
                .tag(2)
            
            // Body Metrics Tab
            bodyMetricsTab
                .tag(3)
        }
        .tabViewStyle(.page(indexDisplayMode: .automatic))
        .background(WatchTheme.Colors.background)
        .onChange(of: selectedTab) { _ in
            hapticManager.playMenuNavigationHaptic()
        }
        .onAppear {
            loadHealthData()
        }
        .sheet(isPresented: $showingDetailView) {
            if let metric = selectedHealthMetric {
                HealthMetricDetailView(metric: metric)
            }
        }
    }
    
    // MARK: - Activity Rings Tab
    
    private var activityRingsTab: some View {
        ScrollView {
            VStack(spacing: WatchTheme.Spacing.lg) {
                // Header
                VStack(spacing: WatchTheme.Spacing.xs) {
                    Text("Activity Rings")
                        .font(WatchTheme.Typography.headlineMedium)
                        .foregroundColor(WatchTheme.Colors.textPrimary)
                    
                    Text("Daily movement goals")
                        .font(WatchTheme.Typography.bodySmall)
                        .foregroundColor(WatchTheme.Colors.textSecondary)
                }
                
                // Activity Rings Display
                if let activityData = activityRingsData {
                    WatchActivityRingsView(activityData: activityData)
                        .frame(height: 120)
                } else {
                    activityRingsPlaceholder
                }
                
                // Activity Summary Cards
                if healthKitManager.isAuthorized {
                    activitySummaryCards
                }
                
                // Quick Actions
                quickActivityActions
            }
            .padding(.horizontal, WatchTheme.Spacing.watchPadding)
        }
    }
    
    // MARK: - Heart Rate Tab
    
    private var heartRateTab: some View {
        ScrollView {
            VStack(spacing: WatchTheme.Spacing.md) {
                // Header
                healthTabHeader(
                    title: "Heart Rate",
                    subtitle: "Real-time monitoring",
                    icon: "heart.fill",
                    color: WatchTheme.Colors.heartRate
                )
                
                // Current Heart Rate Display
                currentHeartRateCard
                
                // Heart Rate Summary
                if healthKitManager.isAuthorized {
                    heartRateSummaryCard
                }
                
                // Heart Rate Zones (if workout active)
                if dataStore.activeWorkoutSession != nil {
                    heartRateZonesCard
                }
            }
            .padding(.horizontal, WatchTheme.Spacing.watchPadding)
        }
    }
    
    // MARK: - Calories Tab
    
    private var caloriesTab: some View {
        ScrollView {
            VStack(spacing: WatchTheme.Spacing.md) {
                // Header
                healthTabHeader(
                    title: "Calories",
                    subtitle: "Energy burned today",
                    icon: "flame.fill",
                    color: WatchTheme.Colors.calories
                )
                
                // Calories Summary
                caloriesSummaryCard
                
                // Calorie Goal Progress
                if let goal = dataStore.getGoalProgress(.calories) {
                    calorieGoalCard(goal: goal)
                }
                
                // Calorie Breakdown
                calorieBreakdownCard
            }
            .padding(.horizontal, WatchTheme.Spacing.watchPadding)
        }
    }
    
    // MARK: - Body Metrics Tab
    
    private var bodyMetricsTab: some View {
        ScrollView {
            VStack(spacing: WatchTheme.Spacing.md) {
                // Header
                healthTabHeader(
                    title: "Body Metrics",
                    subtitle: "Physical measurements",
                    icon: "figure.arms.open",
                    color: WatchTheme.Colors.primary
                )
                
                // Latest Measurements
                latestMeasurementsCard
                
                // Quick Log Actions
                bodyMetricsQuickActions
            }
            .padding(.horizontal, WatchTheme.Spacing.watchPadding)
        }
    }
    
    // MARK: - Activity Rings Components
    
    private var activityRingsPlaceholder: some View {
        VStack(spacing: WatchTheme.Spacing.md) {
            // Placeholder rings
            ZStack {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .stroke(WatchTheme.Colors.surface, lineWidth: 8)
                        .frame(width: 60 + CGFloat(index * 20), height: 60 + CGFloat(index * 20))
                }
            }
            .frame(height: 100)
            
            Text("Health data not available")
                .font(WatchTheme.Typography.bodySmall)
                .foregroundColor(WatchTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
            
            if !healthKitManager.isAuthorized {
                Button("Enable Health Access") {
                    requestHealthAccess()
                }
                .buttonStyle(WatchTheme.Components.primaryButtonStyle())
            }
        }
        .padding(WatchTheme.Spacing.lg)
        .watchCard()
    }
    
    private var activitySummaryCards: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: WatchTheme.Spacing.sm) {
            
            // Steps
            activityMetricCard(
                title: "Steps",
                value: String(healthKitManager.stepCount),
                unit: "steps",
                icon: "figure.walk",
                color: WatchTheme.Colors.steps,
                progress: Double(healthKitManager.stepCount) / 10000.0 // Assuming 10k goal
            )
            
            // Distance
            activityMetricCard(
                title: "Distance",
                value: String(format: "%.1f", healthKitManager.distanceWalkingRunning),
                unit: "miles",
                icon: "location.fill",
                color: WatchTheme.Colors.secondary,
                progress: healthKitManager.distanceWalkingRunning / 5.0 // Assuming 5 mile goal
            )
        }
    }
    
    private var quickActivityActions: some View {
        VStack(alignment: .leading, spacing: WatchTheme.Spacing.sm) {
            Text("Quick Actions")
                .font(WatchTheme.Typography.labelLarge)
                .foregroundColor(WatchTheme.Colors.textPrimary)
            
            HStack(spacing: WatchTheme.Spacing.sm) {
                Button {
                    selectedHealthMetric = .activity
                    showingDetailView = true
                } label: {
                    Text("View Details")
                }
                .buttonStyle(WatchTheme.Components.secondaryButtonStyle())
                
                Button {
                    // Start outdoor walk
                    hapticManager.playButtonPressHaptic()
                } label: {
                    HStack {
                        Image(systemName: "figure.walk")
                        Text("Walk")
                    }
                }
                .buttonStyle(WatchTheme.Components.primaryButtonStyle())
            }
        }
        .padding(WatchTheme.Spacing.sm)
        .watchCard()
    }
    
    // MARK: - Heart Rate Components
    
    private var currentHeartRateCard: some View {
        VStack(spacing: WatchTheme.Spacing.md) {
            // Large heart rate display
            VStack(spacing: WatchTheme.Spacing.xs) {
                HStack {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 16))
                        .foregroundColor(WatchTheme.Colors.heartRate)
                    
                    Text("Current")
                        .font(WatchTheme.Typography.labelMedium)
                        .foregroundColor(WatchTheme.Colors.textSecondary)
                    
                    Spacer()
                    
                    if healthKitManager.heartRate > 0 {
                        Circle()
                            .fill(WatchTheme.Colors.success)
                            .frame(width: 8, height: 8)
                    }
                }
                
                Text(currentHeartRateText)
                    .font(WatchTheme.Typography.displayLarge)
                    .foregroundColor(WatchTheme.Colors.heartRate)
                    .monospacedDigit()
                
                Text("BPM")
                    .font(WatchTheme.Typography.bodySmall)
                    .foregroundColor(WatchTheme.Colors.textSecondary)
            }
            
            // Heart rate status
            heartRateStatusView
        }
        .padding(WatchTheme.Spacing.md)
        .watchCard()
    }
    
    private var heartRateSummaryCard: some View {
        VStack(alignment: .leading, spacing: WatchTheme.Spacing.sm) {
            Text("Today's Summary")
                .font(WatchTheme.Typography.labelLarge)
                .foregroundColor(WatchTheme.Colors.textPrimary)
            
            // Would show resting HR, average HR, etc. from HealthKit
            VStack(spacing: WatchTheme.Spacing.xs) {
                heartRateSummaryRow(title: "Resting", value: "65", unit: "BPM")
                heartRateSummaryRow(title: "Average", value: "78", unit: "BPM")
                heartRateSummaryRow(title: "Maximum", value: "142", unit: "BPM")
            }
        }
        .padding(WatchTheme.Spacing.sm)
        .watchCard()
    }
    
    private var heartRateZonesCard: some View {
        VStack(alignment: .leading, spacing: WatchTheme.Spacing.sm) {
            Text("Heart Rate Zones")
                .font(WatchTheme.Typography.labelLarge)
                .foregroundColor(WatchTheme.Colors.textPrimary)
            
            // Heart rate zones visualization
            HStack(spacing: 4) {
                ForEach(0..<5, id: \.self) { zone in
                    VStack(spacing: 4) {
                        Rectangle()
                            .fill(heartRateZoneColor(zone))
                            .frame(width: 16, height: CGFloat(20 + zone * 8))
                            .cornerRadius(2)
                        
                        Text("Z\(zone + 1)")
                            .font(WatchTheme.Typography.caption)
                            .foregroundColor(WatchTheme.Colors.textTertiary)
                    }
                }
            }
            
            Text("Current zone: \(currentHeartRateZone)")
                .font(WatchTheme.Typography.bodySmall)
                .foregroundColor(WatchTheme.Colors.textSecondary)
        }
        .padding(WatchTheme.Spacing.sm)
        .watchCard()
    }
    
    // MARK: - Calories Components
    
    private var caloriesSummaryCard: some View {
        VStack(spacing: WatchTheme.Spacing.md) {
            // Active calories
            VStack(spacing: WatchTheme.Spacing.xs) {
                HStack {
                    Text("Active Calories")
                        .font(WatchTheme.Typography.labelMedium)
                        .foregroundColor(WatchTheme.Colors.textSecondary)
                    
                    Spacer()
                    
                    Text("Goal: 400")
                        .font(WatchTheme.Typography.caption)
                        .foregroundColor(WatchTheme.Colors.textTertiary)
                }
                
                Text(String(Int(healthKitManager.activeEnergyBurned)))
                    .font(WatchTheme.Typography.displayLarge)
                    .foregroundColor(WatchTheme.Colors.calories)
                    .monospacedDigit()
                
                Text("calories")
                    .font(WatchTheme.Typography.bodySmall)
                    .foregroundColor(WatchTheme.Colors.textSecondary)
            }
            
            // Progress bar
            ProgressView(value: healthKitManager.activeEnergyBurned / 400.0)
                .progressViewStyle(LinearProgressViewStyle(tint: WatchTheme.Colors.calories))
                .frame(height: 4)
        }
        .padding(WatchTheme.Spacing.md)
        .watchCard()
    }
    
    private func calorieGoalCard(goal: FitnessGoal) -> some View {
        VStack(alignment: .leading, spacing: WatchTheme.Spacing.sm) {
            HStack {
                Text("Daily Goal")
                    .font(WatchTheme.Typography.labelLarge)
                    .foregroundColor(WatchTheme.Colors.textPrimary)
                
                Spacer()
                
                Text("\(Int(goal.progressPercentage * 100))%")
                    .font(WatchTheme.Typography.bodyMedium)
                    .foregroundColor(goal.isCompleted ? WatchTheme.Colors.success : WatchTheme.Colors.textSecondary)
            }
            
            HStack {
                Text("\(Int(goal.current)) / \(Int(goal.target))")
                    .font(WatchTheme.Typography.bodyMedium)
                    .foregroundColor(WatchTheme.Colors.textPrimary)
                
                Text(goal.unit)
                    .font(WatchTheme.Typography.bodySmall)
                    .foregroundColor(WatchTheme.Colors.textSecondary)
                
                Spacer()
            }
            
            ProgressView(value: goal.progressPercentage)
                .progressViewStyle(LinearProgressViewStyle(tint: WatchTheme.Colors.calories))
                .frame(height: 4)
        }
        .padding(WatchTheme.Spacing.sm)
        .watchCard()
    }
    
    private var calorieBreakdownCard: some View {
        VStack(alignment: .leading, spacing: WatchTheme.Spacing.sm) {
            Text("Breakdown")
                .font(WatchTheme.Typography.labelLarge)
                .foregroundColor(WatchTheme.Colors.textPrimary)
            
            HStack {
                calorieTypeColumn(
                    title: "Active",
                    value: Int(healthKitManager.activeEnergyBurned),
                    color: WatchTheme.Colors.activeCalories
                )
                
                Spacer()
                
                calorieTypeColumn(
                    title: "Total",
                    value: Int(healthKitManager.totalEnergyBurned),
                    color: WatchTheme.Colors.calories
                )
                
                Spacer()
                
                calorieTypeColumn(
                    title: "Food",
                    value: dataStore.userStats.caloriesToday,
                    color: WatchTheme.Colors.protein
                )
            }
        }
        .padding(WatchTheme.Spacing.sm)
        .watchCard()
    }
    
    // MARK: - Body Metrics Components
    
    private var latestMeasurementsCard: some View {
        VStack(alignment: .leading, spacing: WatchTheme.Spacing.md) {
            Text("Latest Measurements")
                .font(WatchTheme.Typography.labelLarge)
                .foregroundColor(WatchTheme.Colors.textPrimary)
            
            if let weightMetric = dataStore.getLatestBodyMetric(.weight) {
                bodyMetricRow(
                    title: "Weight",
                    value: String(format: "%.1f", weightMetric.value),
                    unit: weightMetric.unit,
                    date: weightMetric.timestamp,
                    icon: "scalemass.fill"
                )
            } else {
                emptyBodyMetricRow(title: "Weight", icon: "scalemass.fill")
            }
            
            if let bodyFatMetric = dataStore.getLatestBodyMetric(.bodyFat) {
                bodyMetricRow(
                    title: "Body Fat",
                    value: String(format: "%.1f", bodyFatMetric.value),
                    unit: "%",
                    date: bodyFatMetric.timestamp,
                    icon: "percent"
                )
            } else {
                emptyBodyMetricRow(title: "Body Fat", icon: "percent")
            }
        }
        .padding(WatchTheme.Spacing.sm)
        .watchCard()
    }
    
    private var bodyMetricsQuickActions: some View {
        VStack(alignment: .leading, spacing: WatchTheme.Spacing.sm) {
            Text("Quick Log")
                .font(WatchTheme.Typography.labelLarge)
                .foregroundColor(WatchTheme.Colors.textPrimary)
            
            HStack(spacing: WatchTheme.Spacing.sm) {
                Button {
                    // Open weight logging
                    logWeight()
                } label: {
                    HStack {
                        Image(systemName: "scalemass.fill")
                        Text("Weight")
                    }
                }
                .buttonStyle(WatchTheme.Components.secondaryButtonStyle())
                
                Button {
                    selectedHealthMetric = .body
                    showingDetailView = true
                } label: {
                    Text("View All")
                }
                .buttonStyle(WatchTheme.Components.primaryButtonStyle())
            }
        }
        .padding(WatchTheme.Spacing.sm)
        .watchCard()
    }
    
    // MARK: - Helper Views
    
    private func healthTabHeader(title: String, subtitle: String, icon: String, color: Color) -> some View {
        VStack(spacing: WatchTheme.Spacing.xs) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                
                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(WatchTheme.Typography.headlineMedium)
                        .foregroundColor(WatchTheme.Colors.textPrimary)
                    
                    Text(subtitle)
                        .font(WatchTheme.Typography.bodySmall)
                        .foregroundColor(WatchTheme.Colors.textSecondary)
                }
                
                Spacer()
                
                Button("Details") {
                    showHealthDetails(for: title.lowercased())
                }
                .font(WatchTheme.Typography.caption)
                .foregroundColor(color)
            }
        }
    }
    
    private func activityMetricCard(
        title: String,
        value: String,
        unit: String,
        icon: String,
        color: Color,
        progress: Double
    ) -> some View {
        VStack(alignment: .leading, spacing: WatchTheme.Spacing.xs) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(color)
                
                Spacer()
            }
            
            Text(value)
                .font(WatchTheme.Typography.displaySmall)
                .foregroundColor(WatchTheme.Colors.textPrimary)
                .monospacedDigit()
                .lineLimit(1)
            
            Text(unit)
                .font(WatchTheme.Typography.caption)
                .foregroundColor(WatchTheme.Colors.textSecondary)
                .lineLimit(1)
            
            ProgressView(value: min(progress, 1.0))
                .progressViewStyle(LinearProgressViewStyle(tint: color))
                .frame(height: 3)
        }
        .padding(WatchTheme.Spacing.sm)
        .frame(minHeight: 80, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: WatchTheme.CornerRadius.sm)
                .fill(WatchTheme.Colors.surface)
        )
    }
    
    private var heartRateStatusView: some View {
        HStack {
            Text(heartRateStatus)
                .font(WatchTheme.Typography.bodySmall)
                .foregroundColor(heartRateStatusColor)
            
            Spacer()
            
            if healthKitManager.heartRate > 0 {
                Text("Live")
                    .font(WatchTheme.Typography.caption)
                    .foregroundColor(WatchTheme.Colors.success)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(WatchTheme.Colors.success.opacity(0.2))
                    )
            }
        }
    }
    
    private func heartRateSummaryRow(title: String, value: String, unit: String) -> some View {
        HStack {
            Text(title)
                .font(WatchTheme.Typography.bodySmall)
                .foregroundColor(WatchTheme.Colors.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(WatchTheme.Typography.bodyMedium)
                .foregroundColor(WatchTheme.Colors.textPrimary)
                .monospacedDigit()
            
            Text(unit)
                .font(WatchTheme.Typography.caption)
                .foregroundColor(WatchTheme.Colors.textTertiary)
        }
    }
    
    private func calorieTypeColumn(title: String, value: Int, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(String(value))
                .font(WatchTheme.Typography.bodyLarge)
                .foregroundColor(color)
                .monospacedDigit()
            
            Text(title)
                .font(WatchTheme.Typography.caption)
                .foregroundColor(WatchTheme.Colors.textSecondary)
        }
    }
    
    private func bodyMetricRow(
        title: String,
        value: String,
        unit: String,
        date: Date,
        icon: String
    ) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(WatchTheme.Colors.primary)
                .frame(width: 16)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(WatchTheme.Typography.bodySmall)
                    .foregroundColor(WatchTheme.Colors.textPrimary)
                
                Text(formatRelativeTime(date))
                    .font(WatchTheme.Typography.caption)
                    .foregroundColor(WatchTheme.Colors.textSecondary)
            }
            
            Spacer()
            
            Text("\(value) \(unit)")
                .font(WatchTheme.Typography.bodyMedium)
                .foregroundColor(WatchTheme.Colors.textPrimary)
                .monospacedDigit()
        }
        .padding(.vertical, 2)
    }
    
    private func emptyBodyMetricRow(title: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(WatchTheme.Colors.textTertiary)
                .frame(width: 16)
            
            Text(title)
                .font(WatchTheme.Typography.bodySmall)
                .foregroundColor(WatchTheme.Colors.textSecondary)
            
            Spacer()
            
            Text("Not logged")
                .font(WatchTheme.Typography.caption)
                .foregroundColor(WatchTheme.Colors.textTertiary)
        }
        .padding(.vertical, 2)
    }
    
    // MARK: - Computed Properties
    
    private var currentHeartRateText: String {
        guard healthKitManager.heartRate > 0 else { return "--" }
        return String(Int(healthKitManager.heartRate))
    }
    
    private var heartRateStatus: String {
        let hr = healthKitManager.heartRate
        if hr == 0 { return "No reading" }
        if hr < 60 { return "Below normal" }
        if hr < 100 { return "Normal" }
        if hr < 120 { return "Elevated" }
        return "High"
    }
    
    private var heartRateStatusColor: Color {
        let hr = healthKitManager.heartRate
        if hr == 0 { return WatchTheme.Colors.textSecondary }
        if hr < 60 { return WatchTheme.Colors.warning }
        if hr < 100 { return WatchTheme.Colors.success }
        if hr < 120 { return WatchTheme.Colors.warning }
        return WatchTheme.Colors.error
    }
    
    private var currentHeartRateZone: String {
        let hr = healthKitManager.heartRate
        let maxHR = 190.0 // Simplified - would calculate from age
        let percentage = hr / maxHR
        
        switch percentage {
        case 0..<0.5: return "Recovery"
        case 0.5..<0.6: return "Fat Burn"
        case 0.6..<0.7: return "Aerobic"
        case 0.7..<0.85: return "Anaerobic"
        default: return "Maximum"
        }
    }
    
    // MARK: - Helper Methods
    
    private func heartRateZoneColor(_ zone: Int) -> Color {
        switch zone {
        case 0: return .gray
        case 1: return .blue
        case 2: return .green
        case 3: return .yellow
        case 4: return .red
        default: return .gray
        }
    }
    
    private func formatRelativeTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    // MARK: - Actions
    
    private func loadHealthData() {
        if healthKitManager.isAuthorized {
            Task {
                do {
                    activityRingsData = try await healthKitManager.fetchActivityRingsData()
                } catch {
                    print("Failed to load activity rings data: \(error)")
                }
            }
        }
    }
    
    private func requestHealthAccess() {
        hapticManager.playButtonPressHaptic()
        Task {
            do {
                try await healthKitManager.requestAuthorization()
                await MainActor.run {
                    loadHealthData()
                }
            } catch {
                print("Health access request failed: \(error)")
            }
        }
    }
    
    private func showHealthDetails(for metric: String) {
        hapticManager.playSelectionHaptic()
        if let healthMetric = HealthMetric.allCases.first(where: { $0.title.lowercased() == metric }) {
            selectedHealthMetric = healthMetric
            showingDetailView = true
        }
    }
    
    private func logWeight() {
        hapticManager.playButtonPressHaptic()
        // Would open weight logging interface
    }
}

// MARK: - Activity Rings View

struct WatchActivityRingsView: View {
    let activityData: ActivityRingsData?
    
    private let ringWidth: CGFloat = 12
    private let ringSpacing: CGFloat = 6
    
    var body: some View {
        ZStack {
            if let data = activityData {
                // Move Ring (outer)
                activityRing(
                    progress: data.activeEnergyProgress,
                    color: WatchTheme.Colors.moveRing,
                    radius: 54
                )
                
                // Exercise Ring (middle)
                activityRing(
                    progress: data.exerciseMinutesProgress,
                    color: WatchTheme.Colors.exerciseRing,
                    radius: 42
                )
                
                // Stand Ring (inner)
                activityRing(
                    progress: data.standHoursProgress,
                    color: WatchTheme.Colors.standRing,
                    radius: 30
                )
                
                // Center text
                centerText(data: data)
            } else {
                // Placeholder rings
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .stroke(WatchTheme.Colors.surface, lineWidth: ringWidth)
                        .frame(width: CGFloat(108 - index * 24), height: CGFloat(108 - index * 24))
                }
                
                Text("No Data")
                    .font(WatchTheme.Typography.caption)
                    .foregroundColor(WatchTheme.Colors.textTertiary)
            }
        }
        .frame(width: 120, height: 120)
    }
    
    private func activityRing(progress: CGFloat, color: Color, radius: CGFloat) -> some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(color.opacity(0.2), lineWidth: ringWidth)
                .frame(width: radius * 2, height: radius * 2)
            
            // Progress ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: ringWidth, lineCap: .round)
                )
                .frame(width: radius * 2, height: radius * 2)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 1.0), value: progress)
        }
    }
    
    private func centerText(data: ActivityRingsData) -> some View {
        VStack(spacing: 1) {
            Text("\(Int(data.activeEnergy))")
                .font(WatchTheme.Typography.bodyLarge)
                .foregroundColor(WatchTheme.Colors.textPrimary)
                .monospacedDigit()
            
            Text("cal")
                .font(WatchTheme.Typography.caption)
                .foregroundColor(WatchTheme.Colors.textSecondary)
        }
    }
}

// MARK: - Health Metric Detail View

struct HealthMetricDetailView: View {
    let metric: HealthOverviewView.HealthMetric
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var healthKitManager: WatchHealthKitManager
    @EnvironmentObject private var dataStore: WatchDataStore
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: WatchTheme.Spacing.lg) {
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
                
                // Metric-specific detailed content would go here
                switch metric {
                case .heartRate:
                    Text("Detailed heart rate analysis would be shown here")
                case .calories:
                    Text("Detailed calorie breakdown would be shown here")
                case .activity:
                    Text("Detailed activity metrics would be shown here")
                case .body:
                    Text("Detailed body metrics history would be shown here")
                }
                
                Spacer()
            }
            .padding(WatchTheme.Spacing.md)
        }
        .background(WatchTheme.Colors.background)
    }
}

#Preview("Health Overview") {
    HealthOverviewView()
        .environmentObject(WatchHealthKitManager())
        .environmentObject(HapticManager())
        .environmentObject(WatchDataStore())
}

#Preview("Activity Rings") {
    WatchActivityRingsView(activityData: ActivityRingsData(
        activeEnergy: 250,
        exerciseMinutes: 15,
        standHours: 8
    ))
}