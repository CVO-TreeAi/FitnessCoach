import SwiftUI
import HealthKit

struct WorkoutSummaryView: View {
    let workoutSession: WorkoutSession
    let routeData: RouteData?
    
    @EnvironmentObject private var hapticManager: HapticManager
    @EnvironmentObject private var dataStore: WatchDataStore
    @EnvironmentObject private var watchConnectivity: WatchConnectivityManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingSaveConfirmation = false
    @State private var isSaving = false
    @State private var showingShareSheet = false
    @State private var achievementsUnlocked: [Achievement] = []
    
    var body: some View {
        ScrollView {
            VStack(spacing: WatchTheme.Spacing.lg) {
                // Header with completion animation
                headerSection
                
                // Key Metrics
                keyMetricsSection
                
                // Performance Insights
                performanceSection
                
                // Route Summary (if outdoor workout)
                if let routeData = routeData {
                    routeSection(routeData)
                }
                
                // Heart Rate Zones (if available)
                if !workoutSession.heartRateReadings.isEmpty {
                    heartRateSection
                }
                
                // Achievements (if any)
                if !achievementsUnlocked.isEmpty {
                    achievementsSection
                }
                
                // Action Buttons
                actionButtonsSection
            }
            .padding(.horizontal, WatchTheme.Spacing.watchPadding)
        }
        .background(WatchTheme.Colors.background)
        .onAppear {
            checkForAchievements()
            hapticManager.playWorkoutHaptic(.workoutEnd)
        }
        .alert("Save Workout", isPresented: $showingSaveConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Save") {
                saveWorkout()
            }
        } message: {
            Text("Save this workout to your fitness history?")
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: WatchTheme.Spacing.md) {
            // Completion Badge
            ZStack {
                Circle()
                    .fill(WatchTheme.Colors.success.opacity(0.2))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(WatchTheme.Colors.success)
            }
            .scaleEffect(1.0)
            .animation(.spring(response: 0.6, dampingFraction: 0.6), value: true)
            
            // Workout Title
            VStack(spacing: WatchTheme.Spacing.xs) {
                Text("Workout Complete!")
                    .font(WatchTheme.Typography.headlineLarge)
                    .foregroundColor(WatchTheme.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text(activityTypeName)
                    .font(WatchTheme.Typography.bodyMedium)
                    .foregroundColor(WatchTheme.Colors.textSecondary)
                
                Text(formatWorkoutDate(workoutSession.startTime))
                    .font(WatchTheme.Typography.caption)
                    .foregroundColor(WatchTheme.Colors.textTertiary)
            }
        }
    }
    
    // MARK: - Key Metrics Section
    
    private var keyMetricsSection: some View {
        VStack(alignment: .leading, spacing: WatchTheme.Spacing.md) {
            Text("Summary")
                .font(WatchTheme.Typography.labelLarge)
                .foregroundColor(WatchTheme.Colors.textPrimary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: WatchTheme.Spacing.sm) {
                
                // Duration
                metricCard(
                    icon: "clock.fill",
                    title: "Duration",
                    value: formatDuration(workoutSession.duration),
                    subtitle: "",
                    color: WatchTheme.Colors.primary
                )
                
                // Calories
                metricCard(
                    icon: "flame.fill",
                    title: "Calories",
                    value: String(Int(workoutSession.caloriesBurned)),
                    subtitle: "kcal",
                    color: WatchTheme.Colors.calories
                )
                
                // Heart Rate
                if workoutSession.averageHeartRate > 0 {
                    metricCard(
                        icon: "heart.fill",
                        title: "Avg Heart Rate",
                        value: String(Int(workoutSession.averageHeartRate)),
                        subtitle: "BPM",
                        color: WatchTheme.Colors.heartRate
                    )
                    
                    metricCard(
                        icon: "bolt.heart.fill",
                        title: "Max Heart Rate",
                        value: String(Int(maxHeartRate)),
                        subtitle: "BPM",
                        color: WatchTheme.Colors.heartRate
                    )
                }
                
                // Distance (if available)
                if let routeData = routeData, routeData.totalDistance > 0 {
                    metricCard(
                        icon: "location.fill",
                        title: "Distance",
                        value: String(format: "%.2f", routeData.totalDistanceMiles),
                        subtitle: "miles",
                        color: WatchTheme.Colors.secondary
                    )
                }
                
                // Pace (if available)
                if let routeData = routeData, let averagePace = routeData.averagePace {
                    metricCard(
                        icon: "speedometer",
                        title: "Avg Pace",
                        value: formatPace(averagePace),
                        subtitle: "min/mi",
                        color: WatchTheme.Colors.accent
                    )
                }
            }
        }
        .padding(WatchTheme.Spacing.md)
        .watchCard()
    }
    
    // MARK: - Performance Section
    
    private var performanceSection: some View {
        VStack(alignment: .leading, spacing: WatchTheme.Spacing.md) {
            Text("Performance")
                .font(WatchTheme.Typography.labelLarge)
                .foregroundColor(WatchTheme.Colors.textPrimary)
            
            VStack(spacing: WatchTheme.Spacing.sm) {
                // Intensity Analysis
                performanceRow(
                    title: "Workout Intensity",
                    value: intensityLevel,
                    color: intensityColor,
                    description: intensityDescription
                )
                
                // Efficiency Score (simplified calculation)
                performanceRow(
                    title: "Efficiency Score",
                    value: "\(efficiencyScore)/100",
                    color: WatchTheme.Colors.success,
                    description: "Based on heart rate zones"
                )
                
                // Calories per minute
                performanceRow(
                    title: "Calories/Min",
                    value: String(format: "%.1f", workoutSession.caloriesBurned / (workoutSession.duration / 60)),
                    color: WatchTheme.Colors.calories,
                    description: "Energy burn rate"
                )
            }
        }
        .padding(WatchTheme.Spacing.md)
        .watchCard()
    }
    
    // MARK: - Route Section
    
    private func routeSection(_ routeData: RouteData) -> some View {
        VStack(alignment: .leading, spacing: WatchTheme.Spacing.md) {
            Text("Route Details")
                .font(WatchTheme.Typography.labelLarge)
                .foregroundColor(WatchTheme.Colors.textPrimary)
            
            VStack(spacing: WatchTheme.Spacing.sm) {
                // Elevation gain
                if routeData.elevationGain > 0 {
                    routeDetailRow(
                        title: "Elevation Gain",
                        value: String(format: "%.0f ft", routeData.elevationGainFeet),
                        icon: "mountain.2.fill"
                    )
                }
                
                // Average speed
                if let avgSpeed = routeData.averageSpeedMPH {
                    routeDetailRow(
                        title: "Average Speed",
                        value: String(format: "%.1f mph", avgSpeed),
                        icon: "speedometer"
                    )
                }
                
                // Total locations tracked
                routeDetailRow(
                    title: "GPS Points",
                    value: String(routeData.locations.count),
                    icon: "location.fill"
                )
            }
        }
        .padding(WatchTheme.Spacing.md)
        .watchCard()
    }
    
    // MARK: - Heart Rate Section
    
    private var heartRateSection: some View {
        VStack(alignment: .leading, spacing: WatchTheme.Spacing.md) {
            Text("Heart Rate Analysis")
                .font(WatchTheme.Typography.labelLarge)
                .foregroundColor(WatchTheme.Colors.textPrimary)
            
            // Heart rate zones visualization (simplified)
            HStack(spacing: WatchTheme.Spacing.sm) {
                ForEach(0..<5, id: \.self) { zone in
                    VStack(spacing: 4) {
                        Rectangle()
                            .fill(heartRateZoneColor(zone))
                            .frame(width: 20, height: CGFloat(heartRateZonePercentage(zone) * 60))
                            .cornerRadius(2)
                        
                        Text("Z\(zone + 1)")
                            .font(WatchTheme.Typography.caption)
                            .foregroundColor(WatchTheme.Colors.textTertiary)
                    }
                }
            }
            .frame(height: 80)
            
            // Heart rate range
            HStack {
                Text("Range:")
                    .font(WatchTheme.Typography.bodySmall)
                    .foregroundColor(WatchTheme.Colors.textSecondary)
                
                Text("\(Int(minHeartRate)) - \(Int(maxHeartRate)) BPM")
                    .font(WatchTheme.Typography.bodySmall)
                    .foregroundColor(WatchTheme.Colors.textPrimary)
                
                Spacer()
            }
        }
        .padding(WatchTheme.Spacing.md)
        .watchCard()
    }
    
    // MARK: - Achievements Section
    
    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: WatchTheme.Spacing.md) {
            HStack {
                Text("Achievements")
                    .font(WatchTheme.Typography.labelLarge)
                    .foregroundColor(WatchTheme.Colors.textPrimary)
                
                Spacer()
                
                Image(systemName: "star.fill")
                    .font(.system(size: 16))
                    .foregroundColor(WatchTheme.Colors.warning)
            }
            
            LazyVStack(spacing: WatchTheme.Spacing.xs) {
                ForEach(achievementsUnlocked, id: \.id) { achievement in
                    achievementRow(achievement)
                }
            }
        }
        .padding(WatchTheme.Spacing.md)
        .watchCard()
        .background(
            RoundedRectangle(cornerRadius: WatchTheme.CornerRadius.watchCard)
                .stroke(WatchTheme.Colors.warning.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Action Buttons Section
    
    private var actionButtonsSection: some View {
        VStack(spacing: WatchTheme.Spacing.md) {
            // Primary Actions
            VStack(spacing: WatchTheme.Spacing.sm) {
                Button {
                    showingSaveConfirmation = true
                } label: {
                    HStack {
                        if isSaving {
                            ProgressView()
                                .scaleEffect(0.8)
                                .foregroundColor(WatchTheme.Colors.textOnPrimary)
                        } else {
                            Image(systemName: "square.and.arrow.down.fill")
                            Text("Save Workout")
                        }
                    }
                }
                .buttonStyle(WatchTheme.Components.primaryButtonStyle())
                .disabled(isSaving)
                
                Button {
                    shareWorkout()
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share")
                    }
                }
                .buttonStyle(WatchTheme.Components.secondaryButtonStyle())
            }
            
            // Secondary Actions
            HStack(spacing: WatchTheme.Spacing.sm) {
                Button("Discard") {
                    discardWorkout()
                }
                .buttonStyle(WatchTheme.Components.destructiveButtonStyle())
                
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(WatchTheme.Components.secondaryButtonStyle())
            }
        }
    }
    
    // MARK: - Helper Views
    
    private func metricCard(
        icon: String,
        title: String,
        value: String,
        subtitle: String,
        color: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: WatchTheme.Spacing.xs) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)
                
                Spacer()
            }
            
            Text(value)
                .font(WatchTheme.Typography.displaySmall)
                .foregroundColor(WatchTheme.Colors.textPrimary)
                .monospacedDigit()
                .lineLimit(1)
            
            HStack {
                Text(title)
                    .font(WatchTheme.Typography.caption)
                    .foregroundColor(WatchTheme.Colors.textSecondary)
                
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(WatchTheme.Typography.caption)
                        .foregroundColor(WatchTheme.Colors.textTertiary)
                }
            }
            .lineLimit(1)
        }
        .padding(WatchTheme.Spacing.sm)
        .frame(minHeight: 70, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: WatchTheme.CornerRadius.sm)
                .fill(WatchTheme.Colors.surface)
        )
    }
    
    private func performanceRow(
        title: String,
        value: String,
        color: Color,
        description: String
    ) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(WatchTheme.Typography.bodySmall)
                    .foregroundColor(WatchTheme.Colors.textPrimary)
                
                Text(description)
                    .font(WatchTheme.Typography.caption)
                    .foregroundColor(WatchTheme.Colors.textSecondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Text(value)
                .font(WatchTheme.Typography.bodyLarge)
                .foregroundColor(color)
                .monospacedDigit()
        }
        .padding(.vertical, 2)
    }
    
    private func routeDetailRow(title: String, value: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(WatchTheme.Colors.secondary)
                .frame(width: 16)
            
            Text(title)
                .font(WatchTheme.Typography.bodySmall)
                .foregroundColor(WatchTheme.Colors.textPrimary)
            
            Spacer()
            
            Text(value)
                .font(WatchTheme.Typography.bodySmall)
                .foregroundColor(WatchTheme.Colors.textSecondary)
                .monospacedDigit()
        }
        .padding(.vertical, 2)
    }
    
    private func achievementRow(_ achievement: Achievement) -> some View {
        HStack {
            Image(systemName: achievement.iconName)
                .font(.system(size: 16))
                .foregroundColor(achievement.color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(achievement.title)
                    .font(WatchTheme.Typography.bodySmall)
                    .foregroundColor(WatchTheme.Colors.textPrimary)
                
                Text(achievement.description)
                    .font(WatchTheme.Typography.caption)
                    .foregroundColor(WatchTheme.Colors.textSecondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Text("NEW")
                .font(WatchTheme.Typography.caption)
                .foregroundColor(WatchTheme.Colors.warning)
                .padding(.horizontal, 4)
                .padding(.vertical, 1)
                .background(
                    RoundedRectangle(cornerRadius: 3)
                        .fill(WatchTheme.Colors.warning.opacity(0.2))
                )
        }
        .padding(.vertical, 2)
    }
    
    // MARK: - Computed Properties
    
    private var activityTypeName: String {
        switch workoutSession.hkActivityType {
        case .running:
            return "Running"
        case .walking:
            return "Walking"
        case .cycling:
            return "Cycling"
        case .swimming:
            return "Swimming"
        case .functionalStrengthTraining, .traditionalStrengthTraining:
            return "Strength Training"
        case .yoga:
            return "Yoga"
        default:
            return "Workout"
        }
    }
    
    private var maxHeartRate: Double {
        workoutSession.heartRateReadings.map { $0.heartRate }.max() ?? 0
    }
    
    private var minHeartRate: Double {
        workoutSession.heartRateReadings.map { $0.heartRate }.min() ?? 0
    }
    
    private var intensityLevel: String {
        let avgHR = workoutSession.averageHeartRate
        if avgHR == 0 { return "Unknown" }
        
        // Simplified intensity calculation (would be more sophisticated in real app)
        let maxHR = 220 - 30 // Assuming age 30
        let percentage = avgHR / Double(maxHR)
        
        switch percentage {
        case 0..<0.5:
            return "Light"
        case 0.5..<0.7:
            return "Moderate"
        case 0.7..<0.85:
            return "Vigorous"
        default:
            return "Maximum"
        }
    }
    
    private var intensityColor: Color {
        switch intensityLevel {
        case "Light":
            return WatchTheme.Colors.success
        case "Moderate":
            return WatchTheme.Colors.warning
        case "Vigorous":
            return WatchTheme.Colors.calories
        case "Maximum":
            return WatchTheme.Colors.error
        default:
            return WatchTheme.Colors.textSecondary
        }
    }
    
    private var intensityDescription: String {
        switch intensityLevel {
        case "Light":
            return "Easy recovery pace"
        case "Moderate":
            return "Fat burning zone"
        case "Vigorous":
            return "Cardio training zone"
        case "Maximum":
            return "High intensity effort"
        default:
            return "Unable to determine"
        }
    }
    
    private var efficiencyScore: Int {
        // Simplified efficiency calculation
        let durationMinutes = workoutSession.duration / 60
        let caloriesPerMinute = workoutSession.caloriesBurned / durationMinutes
        
        // Score based on calories per minute (simplified)
        let score = min(Int(caloriesPerMinute * 10), 100)
        return max(score, 1)
    }
    
    // MARK: - Helper Methods
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds / 3600)
        let minutes = Int((seconds.truncatingRemainder(dividingBy: 3600)) / 60)
        let secs = Int(seconds.truncatingRemainder(dividingBy: 60))
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%02d:%02d", minutes, secs)
        }
    }
    
    private func formatPace(_ minutes: Double) -> String {
        let mins = Int(minutes)
        let secs = Int((minutes - Double(mins)) * 60)
        return String(format: "%d:%02d", mins, secs)
    }
    
    private func formatWorkoutDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
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
    
    private func heartRateZonePercentage(_ zone: Int) -> Double {
        // Simplified calculation - in real app would analyze actual HR data
        let percentages = [0.1, 0.2, 0.3, 0.25, 0.15]
        return percentages[zone]
    }
    
    private func checkForAchievements() {
        var achievements: [Achievement] = []
        
        // Check for duration milestones
        let durationMinutes = workoutSession.duration / 60
        if durationMinutes >= 30 {
            achievements.append(Achievement(
                title: "30 Minute Workout",
                description: "Completed a 30+ minute workout",
                iconName: "clock.fill",
                color: WatchTheme.Colors.primary
            ))
        }
        
        // Check for calorie milestones
        if workoutSession.caloriesBurned >= 300 {
            achievements.append(Achievement(
                title: "Calorie Crusher",
                description: "Burned 300+ calories in one workout",
                iconName: "flame.fill",
                color: WatchTheme.Colors.calories
            ))
        }
        
        // Check for heart rate achievements
        if maxHeartRate >= 150 {
            achievements.append(Achievement(
                title: "Heart Warrior",
                description: "Reached 150+ BPM during workout",
                iconName: "heart.fill",
                color: WatchTheme.Colors.heartRate
            ))
        }
        
        achievementsUnlocked = achievements
        
        if !achievements.isEmpty {
            hapticManager.playWorkoutHaptic(.goalAchieved)
        }
    }
    
    // MARK: - Actions
    
    private func saveWorkout() {
        isSaving = true
        hapticManager.playSuccessHaptic()
        
        // Save to data store
        let workout = WatchWorkout(
            id: workoutSession.workoutId,
            name: "\(activityTypeName) Workout",
            activityType: workoutSession.hkActivityType,
            duration: workoutSession.duration,
            caloriesBurned: workoutSession.caloriesBurned,
            startDate: workoutSession.startTime,
            endDate: workoutSession.endTime ?? Date(),
            isCompleted: true
        )
        
        dataStore.addCompletedWorkout(workout)
        
        // Sync with phone
        watchConnectivity.sendWorkoutData(workout)
        
        // Simulate save delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isSaving = false
            dismiss()
        }
    }
    
    private func shareWorkout() {
        hapticManager.playSelectionHaptic()
        showingShareSheet = true
        // Implementation would use share sheet
    }
    
    private func discardWorkout() {
        hapticManager.playButtonPressHaptic()
        dismiss()
    }
}

// MARK: - Supporting Models

struct Achievement {
    let id = UUID()
    let title: String
    let description: String
    let iconName: String
    let color: Color
}

#Preview("Workout Summary") {
    let session = WorkoutSession(
        workoutId: UUID(),
        startTime: Date().addingTimeInterval(-3600),
        activityType: .running
    )
    
    let routeData = RouteData(
        locations: [],
        startTime: Date().addingTimeInterval(-3600),
        endTime: Date(),
        duration: 3600,
        totalDistance: 5000, // 5km
        elevationGain: 100,
        averagePace: 8.5
    )
    
    return WorkoutSummaryView(workoutSession: session, routeData: routeData)
        .environmentObject(HapticManager())
        .environmentObject(WatchDataStore())
        .environmentObject(WatchConnectivityManager())
}

#Preview("Workout Summary - No Route") {
    let session = WorkoutSession(
        workoutId: UUID(),
        startTime: Date().addingTimeInterval(-1800),
        activityType: .functionalStrengthTraining
    )
    
    return WorkoutSummaryView(workoutSession: session, routeData: nil)
        .environmentObject(HapticManager())
        .environmentObject(WatchDataStore())
        .environmentObject(WatchConnectivityManager())
}