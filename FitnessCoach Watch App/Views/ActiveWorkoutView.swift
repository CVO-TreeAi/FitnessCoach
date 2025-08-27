import SwiftUI
import HealthKit

struct ActiveWorkoutView: View {
    @EnvironmentObject private var workoutManager: WorkoutManager
    @EnvironmentObject private var healthKitManager: WatchHealthKitManager
    @EnvironmentObject private var dataStore: WatchDataStore
    @EnvironmentObject private var hapticManager: HapticManager
    @EnvironmentObject private var locationManager: WatchLocationManager
    
    @State private var selectedTab = 0
    @State private var showingEndWorkout = false
    @State private var showingPauseMenu = false
    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer?
    
    var body: some View {
        Group {
            if let session = dataStore.activeWorkoutSession {
                activeWorkoutContent(session: session)
            } else {
                noActiveWorkoutView
            }
        }
        .background(WatchTheme.Colors.background)
        .onAppear {
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
    }
    
    // MARK: - Active Workout Content
    
    private func activeWorkoutContent(session: WorkoutSession) -> some View {
        TabView(selection: $selectedTab) {
            // Main Metrics Tab
            workoutMetricsView(session: session)
                .tag(0)
            
            // Heart Rate Tab
            heartRateView
                .tag(1)
            
            // Location Tab (for outdoor workouts)
            if locationManager.isTrackingRoute {
                locationView
                    .tag(2)
            }
            
            // Controls Tab
            workoutControlsView(session: session)
                .tag(locationManager.isTrackingRoute ? 3 : 2)
        }
        .tabViewStyle(.page(indexDisplayMode: .automatic))
        .onChange(of: selectedTab) { _ in
            hapticManager.playMenuNavigationHaptic()
        }
    }
    
    // MARK: - Workout Metrics View
    
    private func workoutMetricsView(session: WorkoutSession) -> some View {
        VStack(spacing: WatchTheme.Spacing.md) {
            // Workout Title
            Text("Active Workout")
                .font(WatchTheme.Typography.headlineSmall)
                .foregroundColor(WatchTheme.Colors.textPrimary)
            
            // Timer Display
            Text(formatDuration(elapsedTime))
                .font(WatchTheme.Typography.timer)
                .foregroundColor(WatchTheme.Colors.primary)
                .monospacedDigit()
            
            // Metrics Grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: WatchTheme.Spacing.sm) {
                
                metricCard(
                    title: "Heart Rate",
                    value: heartRateValue,
                    unit: "BPM",
                    color: WatchTheme.Colors.heartRate
                )
                
                metricCard(
                    title: "Calories",
                    value: String(Int(session.caloriesBurned)),
                    unit: "CAL",
                    color: WatchTheme.Colors.calories
                )
                
                if locationManager.isTrackingRoute {
                    metricCard(
                        title: "Distance",
                        value: String(format: "%.2f", locationManager.getTotalDistanceInMiles()),
                        unit: "MI",
                        color: WatchTheme.Colors.secondary
                    )
                    
                    metricCard(
                        title: "Pace",
                        value: paceValue,
                        unit: "MIN/MI",
                        color: WatchTheme.Colors.accent
                    )
                }
            }
            
            Spacer()
            
            // Quick Controls
            quickControlsBar(session: session)
        }
        .padding(WatchTheme.Spacing.watchPadding)
    }
    
    // MARK: - Heart Rate View
    
    private var heartRateView: some View {
        VStack(spacing: WatchTheme.Spacing.lg) {
            Text("Heart Rate")
                .font(WatchTheme.Typography.headlineSmall)
                .foregroundColor(WatchTheme.Colors.textSecondary)
            
            // Large Heart Rate Display
            VStack(spacing: WatchTheme.Spacing.xs) {
                Text(heartRateValue)
                    .font(WatchTheme.Typography.displayLarge)
                    .foregroundColor(WatchTheme.Colors.heartRate)
                    .monospacedDigit()
                
                Text("BPM")
                    .font(WatchTheme.Typography.metricUnit)
                    .foregroundColor(WatchTheme.Colors.textSecondary)
            }
            
            // Heart Rate Zones (simplified)
            heartRateZoneIndicator
            
            // Average Heart Rate
            if let session = dataStore.activeWorkoutSession, session.averageHeartRate > 0 {
                VStack(spacing: 2) {
                    Text("Average")
                        .font(WatchTheme.Typography.caption)
                        .foregroundColor(WatchTheme.Colors.textSecondary)
                    
                    Text(String(Int(session.averageHeartRate)))
                        .font(WatchTheme.Typography.bodyLarge)
                        .foregroundColor(WatchTheme.Colors.textPrimary)
                }
            }
        }
        .padding(WatchTheme.Spacing.watchPadding)
    }
    
    private var heartRateZoneIndicator: some View {
        HStack(spacing: 4) {
            ForEach(0..<5, id: \.self) { zone in
                Rectangle()
                    .fill(heartRateZoneColor(for: zone))
                    .frame(height: 6)
                    .opacity(currentHeartRateZone == zone ? 1.0 : 0.3)
            }
        }
        .frame(height: 6)
        .cornerRadius(3)
    }
    
    // MARK: - Location View
    
    private var locationView: some View {
        VStack(spacing: WatchTheme.Spacing.md) {
            Text("Location")
                .font(WatchTheme.Typography.headlineSmall)
                .foregroundColor(WatchTheme.Colors.textSecondary)
            
            // Distance
            VStack(spacing: WatchTheme.Spacing.xs) {
                Text(String(format: "%.2f", locationManager.getTotalDistanceInMiles()))
                    .font(WatchTheme.Typography.displayMedium)
                    .foregroundColor(WatchTheme.Colors.primary)
                    .monospacedDigit()
                
                Text("MILES")
                    .font(WatchTheme.Typography.metricUnit)
                    .foregroundColor(WatchTheme.Colors.textSecondary)
            }
            
            // Speed and Pace
            HStack(spacing: WatchTheme.Spacing.lg) {
                VStack {
                    Text("Speed")
                        .font(WatchTheme.Typography.caption)
                        .foregroundColor(WatchTheme.Colors.textSecondary)
                    
                    Text(String(format: "%.1f", (locationManager.currentSpeed * 2.237)))
                        .font(WatchTheme.Typography.bodyLarge)
                        .foregroundColor(WatchTheme.Colors.textPrimary)
                        .monospacedDigit()
                    
                    Text("MPH")
                        .font(WatchTheme.Typography.caption)
                        .foregroundColor(WatchTheme.Colors.textSecondary)
                }
                
                VStack {
                    Text("Pace")
                        .font(WatchTheme.Typography.caption)
                        .foregroundColor(WatchTheme.Colors.textSecondary)
                    
                    Text(paceValue)
                        .font(WatchTheme.Typography.bodyLarge)
                        .foregroundColor(WatchTheme.Colors.textPrimary)
                        .monospacedDigit()
                    
                    Text("MIN/MI")
                        .font(WatchTheme.Typography.caption)
                        .foregroundColor(WatchTheme.Colors.textSecondary)
                }
            }
            
            // Elevation
            if locationManager.getRouteElevationGain() > 0 {
                VStack {
                    Text("Elevation Gain")
                        .font(WatchTheme.Typography.caption)
                        .foregroundColor(WatchTheme.Colors.textSecondary)
                    
                    Text(String(format: "%.0f ft", locationManager.getRouteElevationGain() * 3.28084))
                        .font(WatchTheme.Typography.bodyLarge)
                        .foregroundColor(WatchTheme.Colors.accent)
                }
            }
        }
        .padding(WatchTheme.Spacing.watchPadding)
    }
    
    // MARK: - Workout Controls View
    
    private func workoutControlsView(session: WorkoutSession) -> some View {
        VStack(spacing: WatchTheme.Spacing.lg) {
            Text("Workout Controls")
                .font(WatchTheme.Typography.headlineSmall)
                .foregroundColor(WatchTheme.Colors.textSecondary)
            
            VStack(spacing: WatchTheme.Spacing.md) {
                // Pause/Resume Button
                Button {
                    toggleWorkoutPause()
                } label: {
                    HStack {
                        Image(systemName: healthKitManager.currentWorkoutSession?.state == .paused ? "play.fill" : "pause.fill")
                        Text(healthKitManager.currentWorkoutSession?.state == .paused ? "Resume" : "Pause")
                    }
                }
                .buttonStyle(WatchTheme.Components.primaryButtonStyle())
                
                // End Workout Button
                Button {
                    showingEndWorkout = true
                } label: {
                    HStack {
                        Image(systemName: "stop.fill")
                        Text("End Workout")
                    }
                }
                .buttonStyle(WatchTheme.Components.destructiveButtonStyle())
                
                // Water Break Button
                Button {
                    addWaterBreak()
                } label: {
                    HStack {
                        Image(systemName: "drop.fill")
                        Text("Water Break")
                    }
                }
                .buttonStyle(WatchTheme.Components.secondaryButtonStyle())
            }
        }
        .padding(WatchTheme.Spacing.watchPadding)
        .alert("End Workout", isPresented: $showingEndWorkout) {
            Button("Cancel", role: .cancel) { }
            Button("End", role: .destructive) {
                endWorkout()
            }
        } message: {
            Text("Are you sure you want to end this workout?")
        }
    }
    
    // MARK: - Quick Controls Bar
    
    private func quickControlsBar(session: WorkoutSession) -> some View {
        HStack(spacing: WatchTheme.Spacing.md) {
            // Pause/Resume
            Button {
                toggleWorkoutPause()
            } label: {
                Image(systemName: healthKitManager.currentWorkoutSession?.state == .paused ? "play.circle.fill" : "pause.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(WatchTheme.Colors.primary)
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            // Water Logging
            Button {
                addWaterBreak()
            } label: {
                Image(systemName: "drop.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(WatchTheme.Colors.water)
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            // End Workout
            Button {
                showingEndWorkout = true
            } label: {
                Image(systemName: "stop.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(WatchTheme.Colors.error)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, WatchTheme.Spacing.sm)
    }
    
    // MARK: - No Active Workout View
    
    private var noActiveWorkoutView: some View {
        VStack(spacing: WatchTheme.Spacing.lg) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 40))
                .foregroundColor(WatchTheme.Colors.textTertiary)
            
            Text("No Active Workout")
                .font(WatchTheme.Typography.headlineMedium)
                .foregroundColor(WatchTheme.Colors.textPrimary)
            
            Text("Start a workout to see live metrics here")
                .font(WatchTheme.Typography.bodyMedium)
                .foregroundColor(WatchTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
            
            Button("Start Workout") {
                // This would typically navigate to workout selection
                hapticManager.playButtonPressHaptic()
            }
            .buttonStyle(WatchTheme.Components.primaryButtonStyle())
        }
        .padding(WatchTheme.Spacing.lg)
    }
    
    // MARK: - Helper Methods
    
    private var heartRateValue: String {
        guard healthKitManager.heartRate > 0 else { return "--" }
        return String(Int(healthKitManager.heartRate))
    }
    
    private var paceValue: String {
        guard let pace = locationManager.getCurrentPace(), pace.isFinite else { return "--:--" }
        let minutes = Int(pace)
        let seconds = Int((pace - Double(minutes)) * 60)
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private var currentHeartRateZone: Int {
        let hr = healthKitManager.heartRate
        // Simplified heart rate zones based on percentage of max HR (220 - age)
        let maxHR = 190.0 // Assuming average age of 30
        let percentage = hr / maxHR
        
        switch percentage {
        case 0..<0.5: return 0 // Rest
        case 0.5..<0.6: return 1 // Fat Burn
        case 0.6..<0.7: return 2 // Aerobic
        case 0.7..<0.85: return 3 // Anaerobic
        default: return 4 // Maximum
        }
    }
    
    private func heartRateZoneColor(for zone: Int) -> Color {
        switch zone {
        case 0: return .gray
        case 1: return .blue
        case 2: return .green
        case 3: return .yellow
        case 4: return .red
        default: return .gray
        }
    }
    
    private func metricCard(title: String, value: String, unit: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(WatchTheme.Typography.caption)
                .foregroundColor(WatchTheme.Colors.textSecondary)
            
            Text(value)
                .font(WatchTheme.Typography.displaySmall)
                .foregroundColor(color)
                .monospacedDigit()
                .lineLimit(1)
            
            Text(unit)
                .font(WatchTheme.Typography.caption)
                .foregroundColor(WatchTheme.Colors.textTertiary)
        }
        .padding(.vertical, WatchTheme.Spacing.xs)
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds / 3600)
        let minutes = Int((seconds.truncatingRemainder(dividingBy: 3600)) / 60)
        let seconds = Int(seconds.truncatingRemainder(dividingBy: 60))
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    // MARK: - Workout Actions
    
    private func toggleWorkoutPause() {
        hapticManager.playButtonPressHaptic()
        
        do {
            if healthKitManager.currentWorkoutSession?.state == .paused {
                try healthKitManager.resumeWorkoutSession()
                startTimer()
            } else {
                try healthKitManager.pauseWorkoutSession()
                stopTimer()
            }
        } catch {
            print("Failed to toggle workout pause: \(error)")
            hapticManager.playErrorHaptic()
        }
    }
    
    private func endWorkout() {
        hapticManager.playWorkoutHaptic(.workoutEnd)
        stopTimer()
        
        Task {
            do {
                try await healthKitManager.endWorkoutSession()
                await MainActor.run {
                    dataStore.endWorkoutSession()
                    locationManager.stopRouteTracking()
                }
            } catch {
                print("Failed to end workout: \(error)")
                await MainActor.run {
                    hapticManager.playErrorHaptic()
                }
            }
        }
    }
    
    private func addWaterBreak() {
        hapticManager.playSelectionHaptic()
        dataStore.addWaterEntry(8.0) // 8 fl oz
    }
    
    // MARK: - Timer Management
    
    private func startTimer() {
        guard timer == nil else { return }
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if let session = dataStore.activeWorkoutSession {
                elapsedTime = Date().timeIntervalSince(session.startTime)
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

#Preview("Active Workout") {
    ActiveWorkoutView()
        .environmentObject(WorkoutManager())
        .environmentObject(WatchHealthKitManager())
        .environmentObject(WatchDataStore())
        .environmentObject(HapticManager())
        .environmentObject(WatchLocationManager())
}

#Preview("No Active Workout") {
    let dataStore = WatchDataStore()
    dataStore.activeWorkoutSession = nil
    
    return ActiveWorkoutView()
        .environmentObject(WorkoutManager())
        .environmentObject(WatchHealthKitManager())
        .environmentObject(dataStore)
        .environmentObject(HapticManager())
        .environmentObject(WatchLocationManager())
}