import SwiftUI
import HealthKit

struct WorkoutSelectionView: View {
    @EnvironmentObject private var workoutManager: WorkoutManager
    @EnvironmentObject private var healthKitManager: WatchHealthKitManager
    @EnvironmentObject private var dataStore: WatchDataStore
    @EnvironmentObject private var hapticManager: HapticManager
    @EnvironmentObject private var locationManager: WatchLocationManager
    
    @State private var selectedWorkoutType: WorkoutType = .strength
    @State private var showingStartConfirmation = false
    @State private var isStartingWorkout = false
    
    enum WorkoutType: String, CaseIterable {
        case strength = "strength"
        case cardio = "cardio"
        case outdoor = "outdoor"
        case yoga = "yoga"
        case custom = "custom"
        
        var title: String {
            switch self {
            case .strength: return "Strength"
            case .cardio: return "Cardio"
            case .outdoor: return "Outdoor"
            case .yoga: return "Yoga"
            case .custom: return "Custom"
            }
        }
        
        var subtitle: String {
            switch self {
            case .strength: return "Weights & resistance"
            case .cardio: return "Heart rate focused"
            case .outdoor: return "Running & cycling"
            case .yoga: return "Flexibility & balance"
            case .custom: return "Your own workout"
            }
        }
        
        var icon: String {
            switch self {
            case .strength: return "figure.strengthtraining.traditional"
            case .cardio: return "heart.fill"
            case .outdoor: return "figure.run"
            case .yoga: return "figure.yoga"
            case .custom: return "slider.horizontal.3"
            }
        }
        
        var color: Color {
            switch self {
            case .strength: return WatchTheme.Colors.primary
            case .cardio: return WatchTheme.Colors.heartRate
            case .outdoor: return WatchTheme.Colors.secondary
            case .yoga: return WatchTheme.Colors.accent
            case .custom: return WatchTheme.Colors.textSecondary
            }
        }
        
        var hkActivityType: HKWorkoutActivityType {
            switch self {
            case .strength: return .functionalStrengthTraining
            case .cardio: return .other
            case .outdoor: return .running
            case .yoga: return .yoga
            case .custom: return .other
            }
        }
        
        var requiresLocation: Bool {
            switch self {
            case .outdoor: return true
            default: return false
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: WatchTheme.Spacing.md) {
                // Header
                headerSection
                
                // Quick Start Buttons
                quickStartSection
                
                // Workout Type Selection
                workoutTypeSelection
                
                // Start Button
                startWorkoutButton
                
                // Recent Workouts (if any)
                if !dataStore.recentWorkouts.isEmpty {
                    recentWorkoutsSection
                }
            }
            .padding(.horizontal, WatchTheme.Spacing.watchPadding)
        }
        .background(WatchTheme.Colors.background)
        .alert("Start Workout", isPresented: $showingStartConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Start") {
                startWorkout()
            }
        } message: {
            Text("Ready to start your \(selectedWorkoutType.title.lowercased()) workout?")
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: WatchTheme.Spacing.xs) {
            HStack {
                Text("Start Workout")
                    .font(WatchTheme.Typography.headlineMedium)
                    .foregroundColor(WatchTheme.Colors.textPrimary)
                
                Spacer()
                
                // Status indicator
                if healthKitManager.isAuthorized {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 12))
                        .foregroundColor(WatchTheme.Colors.success)
                } else {
                    Image(systemName: "heart.slash")
                        .font(.system(size: 12))
                        .foregroundColor(WatchTheme.Colors.error)
                }
            }
            
            if !healthKitManager.isAuthorized {
                Text("Health access required for workout tracking")
                    .font(WatchTheme.Typography.caption)
                    .foregroundColor(WatchTheme.Colors.textSecondary)
            }
        }
    }
    
    // MARK: - Quick Start Section
    
    private var quickStartSection: some View {
        VStack(alignment: .leading, spacing: WatchTheme.Spacing.sm) {
            Text("Quick Start")
                .font(WatchTheme.Typography.labelLarge)
                .foregroundColor(WatchTheme.Colors.textPrimary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: WatchTheme.Spacing.sm) {
                
                quickStartButton(
                    title: "Open Goal",
                    subtitle: "Free workout",
                    icon: "target",
                    color: WatchTheme.Colors.primary
                ) {
                    selectedWorkoutType = .custom
                    showingStartConfirmation = true
                }
                
                quickStartButton(
                    title: "Outdoor Run",
                    subtitle: "GPS tracking",
                    icon: "figure.run",
                    color: WatchTheme.Colors.secondary
                ) {
                    selectedWorkoutType = .outdoor
                    showingStartConfirmation = true
                }
            }
        }
    }
    
    private func quickStartButton(
        title: String,
        subtitle: String,
        icon: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: {
            hapticManager.playSelectionHaptic()
            action()
        }) {
            VStack(alignment: .leading, spacing: WatchTheme.Spacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                
                Text(title)
                    .font(WatchTheme.Typography.labelMedium)
                    .foregroundColor(WatchTheme.Colors.textPrimary)
                    .lineLimit(1)
                
                Text(subtitle)
                    .font(WatchTheme.Typography.caption)
                    .foregroundColor(WatchTheme.Colors.textSecondary)
                    .lineLimit(1)
            }
            .padding(WatchTheme.Spacing.sm)
            .frame(minHeight: 70, alignment: .topLeading)
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
    
    // MARK: - Workout Type Selection
    
    private var workoutTypeSelection: some View {
        VStack(alignment: .leading, spacing: WatchTheme.Spacing.sm) {
            Text("Workout Type")
                .font(WatchTheme.Typography.labelLarge)
                .foregroundColor(WatchTheme.Colors.textPrimary)
            
            LazyVStack(spacing: WatchTheme.Spacing.xs) {
                ForEach(WorkoutType.allCases, id: \.self) { workoutType in
                    workoutTypeRow(workoutType)
                }
            }
        }
        .padding(WatchTheme.Spacing.sm)
        .watchCard()
    }
    
    private func workoutTypeRow(_ workoutType: WorkoutType) -> some View {
        Button {
            hapticManager.playSelectionHaptic()
            selectedWorkoutType = workoutType
        } label: {
            HStack(spacing: WatchTheme.Spacing.sm) {
                // Selection indicator
                Image(systemName: selectedWorkoutType == workoutType ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 16))
                    .foregroundColor(selectedWorkoutType == workoutType ? workoutType.color : WatchTheme.Colors.textTertiary)
                
                // Workout icon
                Image(systemName: workoutType.icon)
                    .font(.system(size: 16))
                    .foregroundColor(workoutType.color)
                    .frame(width: 20)
                
                // Title and subtitle
                VStack(alignment: .leading, spacing: 1) {
                    Text(workoutType.title)
                        .font(WatchTheme.Typography.bodyMedium)
                        .foregroundColor(WatchTheme.Colors.textPrimary)
                    
                    Text(workoutType.subtitle)
                        .font(WatchTheme.Typography.caption)
                        .foregroundColor(WatchTheme.Colors.textSecondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Location indicator for outdoor workouts
                if workoutType.requiresLocation {
                    Image(systemName: locationManager.isLocationAuthorized ? "location.fill" : "location.slash")
                        .font(.system(size: 12))
                        .foregroundColor(locationManager.isLocationAuthorized ? WatchTheme.Colors.success : WatchTheme.Colors.error)
                }
            }
            .padding(.vertical, WatchTheme.Spacing.xs)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Start Workout Button
    
    private var startWorkoutButton: some View {
        Button {
            hapticManager.playButtonPressHaptic()
            
            // Check location permission for outdoor workouts
            if selectedWorkoutType.requiresLocation && !locationManager.isLocationAuthorized {
                locationManager.requestLocationPermission()
                return
            }
            
            showingStartConfirmation = true
            
        } label: {
            HStack {
                if isStartingWorkout {
                    ProgressView()
                        .scaleEffect(0.8)
                        .foregroundColor(WatchTheme.Colors.textOnPrimary)
                } else {
                    Image(systemName: "play.fill")
                    Text("Start \(selectedWorkoutType.title)")
                }
            }
        }
        .buttonStyle(WatchTheme.Components.primaryButtonStyle())
        .disabled(!healthKitManager.isAuthorized || isStartingWorkout)
        .opacity(healthKitManager.isAuthorized ? 1.0 : 0.6)
    }
    
    // MARK: - Recent Workouts Section
    
    private var recentWorkoutsSection: some View {
        VStack(alignment: .leading, spacing: WatchTheme.Spacing.sm) {
            Text("Recent Workouts")
                .font(WatchTheme.Typography.labelLarge)
                .foregroundColor(WatchTheme.Colors.textPrimary)
            
            LazyVStack(spacing: WatchTheme.Spacing.xs) {
                ForEach(Array(dataStore.recentWorkouts.prefix(3)), id: \.id) { workout in
                    recentWorkoutRow(workout)
                }
            }
        }
        .padding(WatchTheme.Spacing.sm)
        .watchCard()
    }
    
    private func recentWorkoutRow(_ workout: WatchWorkout) -> some View {
        HStack {
            // Workout type icon
            Image(systemName: workoutIconName(for: workout.hkActivityType))
                .font(.system(size: 14))
                .foregroundColor(WatchTheme.Colors.primary)
                .frame(width: 20)
            
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
            
            Button {
                hapticManager.playSelectionHaptic()
                // Could repeat this workout
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 12))
                    .foregroundColor(WatchTheme.Colors.textTertiary)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 2)
    }
    
    // MARK: - Workout Actions
    
    private func startWorkout() {
        guard !isStartingWorkout else { return }
        
        isStartingWorkout = true
        hapticManager.playWorkoutHaptic(.workoutStart)
        
        Task {
            do {
                // Create workout session
                let workout = WatchWorkout(
                    name: "\(selectedWorkoutType.title) Workout",
                    activityType: selectedWorkoutType.hkActivityType,
                    startDate: Date()
                )
                
                // Start HealthKit workout session
                try await healthKitManager.startWorkoutSession(activityType: selectedWorkoutType.hkActivityType)
                
                // Start data store session
                await MainActor.run {
                    dataStore.startWorkoutSession(workout)
                }
                
                // Start location tracking for outdoor workouts
                if selectedWorkoutType.requiresLocation {
                    await MainActor.run {
                        locationManager.startRouteTracking()
                    }
                }
                
                await MainActor.run {
                    isStartingWorkout = false
                    // Navigation would typically happen here to switch to ActiveWorkoutView
                }
                
            } catch {
                await MainActor.run {
                    print("Failed to start workout: \(error)")
                    hapticManager.playErrorHaptic()
                    isStartingWorkout = false
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
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
}

#Preview("Workout Selection") {
    WorkoutSelectionView()
        .environmentObject(WorkoutManager())
        .environmentObject(WatchHealthKitManager())
        .environmentObject(WatchDataStore())
        .environmentObject(HapticManager())
        .environmentObject(WatchLocationManager())
}

#Preview("Workout Selection - Not Authorized") {
    let healthKit = WatchHealthKitManager()
    healthKit.isAuthorized = false
    
    return WorkoutSelectionView()
        .environmentObject(WorkoutManager())
        .environmentObject(healthKit)
        .environmentObject(WatchDataStore())
        .environmentObject(HapticManager())
        .environmentObject(WatchLocationManager())
}