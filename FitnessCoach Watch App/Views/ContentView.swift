import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var watchConnectivity: WatchConnectivityManager
    @EnvironmentObject private var workoutManager: WorkoutManager
    @EnvironmentObject private var healthKitManager: WatchHealthKitManager
    @EnvironmentObject private var hapticManager: HapticManager
    @EnvironmentObject private var dataStore: WatchDataStore
    @EnvironmentObject private var locationManager: WatchLocationManager
    
    @State private var selectedTab = 0
    @State private var showingOnboarding = false
    
    var body: some View {
        Group {
            if showingOnboarding {
                WatchOnboardingView {
                    showingOnboarding = false
                }
            } else {
                mainContent
            }
        }
        .onAppear {
            setupInitialState()
            hapticManager.playSelectionHaptic()
        }
        .onChange(of: selectedTab) { _ in
            hapticManager.playMenuNavigationHaptic()
        }
    }
    
    private var mainContent: some View {
        TabView(selection: $selectedTab) {
            // Dashboard Tab - Main overview
            DashboardView()
                .tag(0)
            
            // Active Workout Tab - Shows active workout or workout selection
            Group {
                if dataStore.activeWorkoutSession != nil {
                    ActiveWorkoutView()
                } else {
                    WorkoutSelectionView()
                }
            }
            .tag(1)
            
            // Health Tab - Health metrics and activity rings
            HealthOverviewView()
                .tag(2)
            
            // Progress Tab - Goals and achievements
            ProgressOverviewView()
                .tag(3)
            
            // Quick Actions Tab - Fast data entry
            QuickLogView()
                .tag(4)
        }
        .tabViewStyle(.page(indexDisplayMode: .automatic))
        .background(WatchTheme.Colors.background)
        .gesture(
            // Handle Digital Crown rotation for tab navigation
            DragGesture()
                .onEnded { value in
                    if abs(value.translation.y) > abs(value.translation.x) {
                        if value.translation.y < -20 {
                            // Swipe up - next tab
                            withAnimation(WatchTheme.Animation.pageTransition) {
                                selectedTab = min(selectedTab + 1, 4)
                            }
                            hapticManager.playDigitalCrownTick()
                        } else if value.translation.y > 20 {
                            // Swipe down - previous tab
                            withAnimation(WatchTheme.Animation.pageTransition) {
                                selectedTab = max(selectedTab - 1, 0)
                            }
                            hapticManager.playDigitalCrownTick()
                        }
                    }
                }
        )
    }
    
    private func setupInitialState() {
        // Check if this is first launch
        let hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedWatchOnboarding")
        
        if !hasCompletedOnboarding {
            showingOnboarding = true
            return
        }
        
        // Set up Watch Connectivity
        watchConnectivity.startSession()
        
        // Request location permission if needed
        if !locationManager.isLocationAuthorized {
            locationManager.requestLocationPermission()
        }
        
        // Start health data collection if authorized
        if healthKitManager.isAuthorized {
            healthKitManager.startHealthDataCollection()
        }
    }
}

// MARK: - Tab Indicator View (optional visual enhancement)

private struct TabIndicatorView: View {
    let currentTab: Int
    let totalTabs: Int = 5
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<totalTabs, id: \.self) { index in
                Circle()
                    .fill(index == currentTab ? WatchTheme.Colors.primary : WatchTheme.Colors.textTertiary)
                    .frame(width: 6, height: 6)
                    .animation(WatchTheme.Animation.fast, value: currentTab)
            }
        }
        .padding(.top, 4)
    }
}

// MARK: - Watch Onboarding View

struct WatchOnboardingView: View {
    let onComplete: () -> Void
    @EnvironmentObject private var healthKitManager: WatchHealthKitManager
    @EnvironmentObject private var hapticManager: HapticManager
    @EnvironmentObject private var locationManager: WatchLocationManager
    @State private var currentStep = 0
    
    private let onboardingSteps = [
        OnboardingStep(
            title: "Welcome to\nFitnessCoach",
            description: "Your fitness journey starts here",
            icon: "figure.strengthtraining.traditional",
            color: WatchTheme.Colors.primary
        ),
        OnboardingStep(
            title: "Health Access",
            description: "Grant access to track your fitness data",
            icon: "heart.fill",
            color: WatchTheme.Colors.heartRate
        ),
        OnboardingStep(
            title: "Location Services",
            description: "Enable location for outdoor workouts",
            icon: "location.fill",
            color: WatchTheme.Colors.secondary
        ),
        OnboardingStep(
            title: "You're Ready!",
            description: "Let's start your fitness journey",
            icon: "checkmark.circle.fill",
            color: WatchTheme.Colors.success
        )
    ]
    
    var body: some View {
        TabView(selection: $currentStep) {
            ForEach(0..<onboardingSteps.count, id: \.self) { index in
                OnboardingStepView(
                    step: onboardingSteps[index],
                    isLastStep: index == onboardingSteps.count - 1
                ) {
                    handleStepAction(for: index)
                }
                .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .background(WatchTheme.Colors.background)
        .onAppear {
            hapticManager.playSuccessHaptic()
        }
    }
    
    private func handleStepAction(for step: Int) {
        hapticManager.playButtonPressHaptic()
        
        switch step {
        case 1:
            // Request HealthKit authorization
            Task {
                try? await healthKitManager.requestAuthorization()
                await MainActor.run {
                    nextStep()
                }
            }
        case 2:
            // Request location authorization
            locationManager.requestLocationPermission()
            nextStep()
        case 3:
            // Complete onboarding
            completeOnboarding()
        default:
            nextStep()
        }
    }
    
    private func nextStep() {
        withAnimation(WatchTheme.Animation.pageTransition) {
            currentStep += 1
        }
    }
    
    private func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasCompletedWatchOnboarding")
        hapticManager.playAchievementUnlocked()
        onComplete()
    }
}

struct OnboardingStep {
    let title: String
    let description: String
    let icon: String
    let color: Color
}

struct OnboardingStepView: View {
    let step: OnboardingStep
    let isLastStep: Bool
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: WatchTheme.Spacing.lg) {
            Spacer()
            
            // Icon
            Image(systemName: step.icon)
                .font(.system(size: 50, weight: .light))
                .foregroundColor(step.color)
                .padding(.bottom, WatchTheme.Spacing.md)
            
            // Title
            Text(step.title)
                .font(WatchTheme.Typography.headlineLarge)
                .foregroundColor(WatchTheme.Colors.textPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
            
            // Description
            Text(step.description)
                .font(WatchTheme.Typography.bodyMedium)
                .foregroundColor(WatchTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .padding(.horizontal, WatchTheme.Spacing.sm)
            
            Spacer()
            
            // Action Button
            Button(action: action) {
                HStack {
                    Text(isLastStep ? "Get Started" : "Continue")
                        .font(WatchTheme.Typography.labelLarge)
                    
                    if !isLastStep {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                }
            }
            .buttonStyle(WatchTheme.Components.primaryButtonStyle())
        }
        .padding(WatchTheme.Spacing.md)
    }
}

#Preview("Content View") {
    ContentView()
        .environmentObject(WatchConnectivityManager())
        .environmentObject(WorkoutManager())
        .environmentObject(WatchHealthKitManager())
        .environmentObject(HapticManager())
        .environmentObject(WatchDataStore())
        .environmentObject(WatchLocationManager())
}

#Preview("Onboarding") {
    WatchOnboardingView {
        print("Onboarding completed")
    }
    .environmentObject(WatchHealthKitManager())
    .environmentObject(HapticManager())
    .environmentObject(WatchLocationManager())
}