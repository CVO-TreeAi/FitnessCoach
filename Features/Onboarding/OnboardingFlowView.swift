import SwiftUI

public struct OnboardingFlowView: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    @EnvironmentObject private var healthKitManager: HealthKitManager
    @Environment(\.theme) private var theme
    
    @StateObject private var viewModel = OnboardingViewModel()
    
    public var body: some View {
        NavigationView {
            ZStack {
                theme.backgroundColor.ignoresSafeArea()
                
                TabView(selection: $viewModel.currentStep) {
                    WelcomeView(onNext: viewModel.nextStep)
                        .tag(OnboardingStep.welcome)
                    
                    RoleSelectionView(
                        selectedRole: $viewModel.selectedRole,
                        onNext: viewModel.nextStep
                    )
                    .tag(OnboardingStep.roleSelection)
                    
                    PersonalInfoView(
                        personalInfo: $viewModel.personalInfo,
                        onNext: viewModel.nextStep
                    )
                    .tag(OnboardingStep.personalInfo)
                    
                    FitnessGoalsView(
                        selectedGoals: $viewModel.selectedGoals,
                        onNext: viewModel.nextStep
                    )
                    .tag(OnboardingStep.fitnessGoals)
                    
                    ActivityLevelView(
                        selectedLevel: $viewModel.selectedActivityLevel,
                        onNext: viewModel.nextStep
                    )
                    .tag(OnboardingStep.activityLevel)
                    
                    HealthMetricsView(
                        healthMetrics: $viewModel.healthMetrics,
                        onNext: viewModel.nextStep
                    )
                    .tag(OnboardingStep.healthMetrics)
                    
                    PermissionsView(
                        onHealthKitPermissionGranted: {
                            Task {
                                await requestHealthKitPermission()
                            }
                        },
                        onNotificationPermissionGranted: {
                            requestNotificationPermission()
                        },
                        onNext: viewModel.nextStep
                    )
                    .tag(OnboardingStep.permissions)
                    
                    CompletionView(
                        onComplete: {
                            Task {
                                await completeOnboarding()
                            }
                        }
                    )
                    .tag(OnboardingStep.completion)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut, value: viewModel.currentStep)
                
                VStack {
                    Spacer()
                    
                    // Progress indicator and navigation
                    if viewModel.currentStep != .welcome && viewModel.currentStep != .completion {
                        VStack(spacing: theme.spacing.lg) {
                            // Progress bar
                            ProgressView(value: viewModel.progress)
                                .progressViewStyle(.linear)
                                .tint(theme.primaryColor)
                                .frame(height: 4)
                            
                            // Navigation buttons
                            HStack {
                                if viewModel.canGoBack {
                                    ThemedButton("Back", style: .secondary, size: .medium) {
                                        viewModel.previousStep()
                                    }
                                }
                                
                                Spacer()
                                
                                Text("Step \(viewModel.currentStep.rawValue) of \(OnboardingStep.allCases.count - 2)")
                                    .font(theme.bodySmallFont)
                                    .foregroundColor(theme.textSecondary)
                            }
                        }
                        .padding(.horizontal, theme.spacing.lg)
                        .padding(.bottom, theme.spacing.xl)
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // MARK: - Helper Methods
    
    private func requestHealthKitPermission() async {
        do {
            try await healthKitManager.requestAuthorization()
            viewModel.healthKitPermissionGranted = true
        } catch {
            print("HealthKit permission denied: \(error)")
            viewModel.healthKitPermissionGranted = false
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                viewModel.notificationPermissionGranted = granted
                if let error = error {
                    print("Notification permission error: \(error)")
                }
            }
        }
    }
    
    private func completeOnboarding() async {
        await viewModel.completeOnboarding()
        // The authentication manager will handle the transition to the main app
    }
}

// MARK: - Welcome View

private struct WelcomeView: View {
    let onNext: () -> Void
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(spacing: theme.spacing.xl) {
            Spacer()
            
            VStack(spacing: theme.spacing.lg) {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 100))
                    .foregroundColor(theme.primaryColor)
                
                Text("Welcome to FitnessCoach")
                    .font(theme.titleLargeFont)
                    .foregroundColor(theme.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text("Your personal fitness journey starts here. Let's set you up for success with a personalized experience.")
                    .font(theme.bodyLargeFont)
                    .foregroundColor(theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, theme.spacing.lg)
            }
            
            Spacer()
            
            ThemedButton("Get Started", style: .primary, size: .large) {
                onNext()
            }
            .padding(.horizontal, theme.spacing.lg)
            .padding(.bottom, theme.spacing.xl)
        }
    }
}

// MARK: - Role Selection View

private struct RoleSelectionView: View {
    @Binding var selectedRole: UserRole
    let onNext: () -> Void
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(spacing: theme.spacing.xl) {
            VStack(spacing: theme.spacing.md) {
                Text("What describes you best?")
                    .font(theme.titleLargeFont)
                    .foregroundColor(theme.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text("This helps us customize your experience")
                    .font(theme.bodyMediumFont)
                    .foregroundColor(theme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, theme.spacing.xl)
            
            VStack(spacing: theme.spacing.md) {
                RoleSelectionCard(
                    role: .user,
                    title: "I'm here to get fit",
                    description: "Track workouts, nutrition, and progress with personalized guidance",
                    icon: "figure.walk",
                    isSelected: selectedRole == .user
                ) {
                    selectedRole = .user
                }
                
                RoleSelectionCard(
                    role: .admin,
                    title: "I'm a fitness coach",
                    description: "Manage clients, create workout plans, and track their progress",
                    icon: "person.2.fill",
                    isSelected: selectedRole == .admin
                ) {
                    selectedRole = .admin
                }
            }
            
            Spacer()
            
            ThemedButton("Continue", style: .primary, size: .large) {
                onNext()
            }
            .padding(.horizontal, theme.spacing.lg)
            .padding(.bottom, theme.spacing.xl)
        }
        .padding(.horizontal, theme.spacing.lg)
    }
}

private struct RoleSelectionCard: View {
    let role: UserRole
    let title: String
    let description: String
    let icon: String
    let isSelected: Bool
    let onTap: () -> Void
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: theme.spacing.lg) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(isSelected ? theme.primaryColor : theme.textSecondary)
                    .frame(width: 48)
                
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    Text(title)
                        .font(theme.titleMediumFont)
                        .foregroundColor(theme.textPrimary)
                    
                    Text(description)
                        .font(theme.bodySmallFont)
                        .foregroundColor(theme.textSecondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(theme.primaryColor)
                }
            }
            .padding(theme.spacing.lg)
            .background(isSelected ? theme.primaryColor.opacity(0.1) : theme.surfaceColor)
            .overlay(
                RoundedRectangle(cornerRadius: theme.cornerRadius.medium)
                    .stroke(isSelected ? theme.primaryColor : Color.clear, lineWidth: 2)
            )
            .cornerRadius(theme.cornerRadius.medium)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Personal Info View

private struct PersonalInfoView: View {
    @Binding var personalInfo: PersonalInfo
    let onNext: () -> Void
    @Environment(\.theme) private var theme
    
    var body: some View {
        ScrollView {
            VStack(spacing: theme.spacing.xl) {
                VStack(spacing: theme.spacing.md) {
                    Text("Tell us about yourself")
                        .font(theme.titleLargeFont)
                        .foregroundColor(theme.textPrimary)
                        .multilineTextAlignment(.center)
                    
                    Text("This information helps us personalize your fitness recommendations")
                        .font(theme.bodyMediumFont)
                        .foregroundColor(theme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, theme.spacing.xl)
                
                VStack(spacing: theme.spacing.lg) {
                    ThemedDatePicker(
                        "Date of Birth",
                        selection: $personalInfo.dateOfBirth,
                        in: Calendar.current.date(byAdding: .year, value: -100, to: Date())!...Calendar.current.date(byAdding: .year, value: -13, to: Date())!
                    )
                    
                    ThemedSegmentedControl(
                        "Gender",
                        selection: $personalInfo.gender,
                        options: ["Male", "Female", "Other"]
                    )
                    
                    ThemedSlider(
                        "Height",
                        value: $personalInfo.height,
                        in: 120...220,
                        step: 1,
                        unit: " cm"
                    )
                    
                    ThemedSlider(
                        "Current Weight",
                        value: $personalInfo.currentWeight,
                        in: 40...200,
                        step: 0.5,
                        unit: " kg"
                    )
                }
                
                Spacer(minLength: 100)
                
                ThemedButton("Continue", style: .primary, size: .large) {
                    onNext()
                }
                .padding(.bottom, theme.spacing.xl)
            }
            .padding(.horizontal, theme.spacing.lg)
        }
    }
}

// MARK: - Fitness Goals View

private struct FitnessGoalsView: View {
    @Binding var selectedGoals: Set<FitnessGoal>
    let onNext: () -> Void
    @Environment(\.theme) private var theme
    
    var body: some View {
        ScrollView {
            VStack(spacing: theme.spacing.xl) {
                VStack(spacing: theme.spacing.md) {
                    Text("What are your fitness goals?")
                        .font(theme.titleLargeFont)
                        .foregroundColor(theme.textPrimary)
                        .multilineTextAlignment(.center)
                    
                    Text("Select all that apply - you can change these later")
                        .font(theme.bodyMediumFont)
                        .foregroundColor(theme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, theme.spacing.xl)
                
                LazyVGrid(
                    columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ],
                    spacing: theme.spacing.md
                ) {
                    ForEach(FitnessGoal.allCases, id: \.self) { goal in
                        GoalCard(
                            goal: goal,
                            isSelected: selectedGoals.contains(goal)
                        ) {
                            if selectedGoals.contains(goal) {
                                selectedGoals.remove(goal)
                            } else {
                                selectedGoals.insert(goal)
                            }
                        }
                    }
                }
                
                Spacer(minLength: 100)
                
                ThemedButton("Continue", style: .primary, size: .large) {
                    onNext()
                }
                .disabled(selectedGoals.isEmpty)
                .padding(.bottom, theme.spacing.xl)
            }
            .padding(.horizontal, theme.spacing.lg)
        }
    }
}

private struct GoalCard: View {
    let goal: FitnessGoal
    let isSelected: Bool
    let onTap: () -> Void
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: theme.spacing.md) {
                Image(systemName: goal.icon)
                    .font(.system(size: 32))
                    .foregroundColor(isSelected ? theme.primaryColor : theme.textSecondary)
                
                VStack(spacing: theme.spacing.xs) {
                    Text(goal.title)
                        .font(theme.bodyMediumFont)
                        .foregroundColor(theme.textPrimary)
                        .multilineTextAlignment(.center)
                    
                    Text(goal.description)
                        .font(theme.bodySmallFont)
                        .foregroundColor(theme.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(theme.spacing.md)
            .frame(maxWidth: .infinity, minHeight: 120)
            .background(isSelected ? theme.primaryColor.opacity(0.1) : theme.surfaceColor)
            .overlay(
                RoundedRectangle(cornerRadius: theme.cornerRadius.medium)
                    .stroke(isSelected ? theme.primaryColor : Color.clear, lineWidth: 2)
            )
            .cornerRadius(theme.cornerRadius.medium)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Activity Level View

private struct ActivityLevelView: View {
    @Binding var selectedLevel: ActivityLevel
    let onNext: () -> Void
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(spacing: theme.spacing.xl) {
            VStack(spacing: theme.spacing.md) {
                Text("How active are you?")
                    .font(theme.titleLargeFont)
                    .foregroundColor(theme.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text("This helps us calculate your calorie needs")
                    .font(theme.bodyMediumFont)
                    .foregroundColor(theme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, theme.spacing.xl)
            
            VStack(spacing: theme.spacing.md) {
                ForEach(ActivityLevel.allCases, id: \.self) { level in
                    ActivityLevelCard(
                        level: level,
                        isSelected: selectedLevel == level
                    ) {
                        selectedLevel = level
                    }
                }
            }
            
            Spacer()
            
            ThemedButton("Continue", style: .primary, size: .large) {
                onNext()
            }
            .padding(.horizontal, theme.spacing.lg)
            .padding(.bottom, theme.spacing.xl)
        }
        .padding(.horizontal, theme.spacing.lg)
    }
}

private struct ActivityLevelCard: View {
    let level: ActivityLevel
    let isSelected: Bool
    let onTap: () -> Void
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: theme.spacing.lg) {
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    Text(level.title)
                        .font(theme.titleSmallFont)
                        .foregroundColor(theme.textPrimary)
                    
                    Text(level.description)
                        .font(theme.bodySmallFont)
                        .foregroundColor(theme.textSecondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(theme.primaryColor)
                }
            }
            .padding(theme.spacing.lg)
            .background(isSelected ? theme.primaryColor.opacity(0.1) : theme.surfaceColor)
            .overlay(
                RoundedRectangle(cornerRadius: theme.cornerRadius.medium)
                    .stroke(isSelected ? theme.primaryColor : Color.clear, lineWidth: 2)
            )
            .cornerRadius(theme.cornerRadius.medium)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Health Metrics View

private struct HealthMetricsView: View {
    @Binding var healthMetrics: HealthMetrics
    let onNext: () -> Void
    @Environment(\.theme) private var theme
    
    var body: some View {
        ScrollView {
            VStack(spacing: theme.spacing.xl) {
                VStack(spacing: theme.spacing.md) {
                    Text("Health Information")
                        .font(theme.titleLargeFont)
                        .foregroundColor(theme.textPrimary)
                        .multilineTextAlignment(.center)
                    
                    Text("Optional information to help us provide better recommendations")
                        .font(theme.bodyMediumFont)
                        .foregroundColor(theme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, theme.spacing.xl)
                
                VStack(spacing: theme.spacing.lg) {
                    if !healthMetrics.goalWeight.isZero {
                        ThemedSlider(
                            "Goal Weight",
                            value: $healthMetrics.goalWeight,
                            in: 40...200,
                            step: 0.5,
                            unit: " kg"
                        )
                    }
                    
                    ThemedTextEditor(
                        "Medical Conditions",
                        text: $healthMetrics.medicalConditions,
                        placeholder: "List any medical conditions, allergies, or health concerns (optional)"
                    )
                    
                    ThemedTextEditor(
                        "Injuries or Limitations",
                        text: $healthMetrics.injuries,
                        placeholder: "List any injuries or physical limitations (optional)"
                    )
                    
                    ThemedTextEditor(
                        "Exercise Preferences",
                        text: $healthMetrics.preferences,
                        placeholder: "What types of exercises do you enjoy? Any dislikes? (optional)"
                    )
                }
                
                Spacer(minLength: 100)
                
                ThemedButton("Continue", style: .primary, size: .large) {
                    onNext()
                }
                .padding(.bottom, theme.spacing.xl)
            }
            .padding(.horizontal, theme.spacing.lg)
        }
    }
}

// MARK: - Permissions View

private struct PermissionsView: View {
    let onHealthKitPermissionGranted: () -> Void
    let onNotificationPermissionGranted: () -> Void
    let onNext: () -> Void
    
    @State private var healthKitRequested = false
    @State private var notificationRequested = false
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(spacing: theme.spacing.xl) {
            VStack(spacing: theme.spacing.md) {
                Text("Grant Permissions")
                    .font(theme.titleLargeFont)
                    .foregroundColor(theme.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text("Enable these features for the best experience")
                    .font(theme.bodyMediumFont)
                    .foregroundColor(theme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, theme.spacing.xl)
            
            VStack(spacing: theme.spacing.lg) {
                PermissionCard(
                    icon: "heart.fill",
                    title: "Health Data",
                    description: "Sync weight, workouts, and health metrics with Apple Health",
                    isRequested: healthKitRequested,
                    buttonTitle: "Enable Health Sync"
                ) {
                    healthKitRequested = true
                    onHealthKitPermissionGranted()
                }
                
                PermissionCard(
                    icon: "bell.fill",
                    title: "Notifications",
                    description: "Receive workout reminders and progress updates",
                    isRequested: notificationRequested,
                    buttonTitle: "Enable Notifications"
                ) {
                    notificationRequested = true
                    onNotificationPermissionGranted()
                }
            }
            
            Spacer()
            
            VStack(spacing: theme.spacing.md) {
                ThemedButton("Continue", style: .primary, size: .large) {
                    onNext()
                }
                
                Text("You can change these permissions later in Settings")
                    .font(theme.bodySmallFont)
                    .foregroundColor(theme.textTertiary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, theme.spacing.lg)
            .padding(.bottom, theme.spacing.xl)
        }
        .padding(.horizontal, theme.spacing.lg)
    }
}

private struct PermissionCard: View {
    let icon: String
    let title: String
    let description: String
    let isRequested: Bool
    let buttonTitle: String
    let onTap: () -> Void
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(spacing: theme.spacing.lg) {
            HStack(spacing: theme.spacing.md) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(theme.primaryColor)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    Text(title)
                        .font(theme.titleSmallFont)
                        .foregroundColor(theme.textPrimary)
                    
                    Text(description)
                        .font(theme.bodySmallFont)
                        .foregroundColor(theme.textSecondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
            }
            
            if isRequested {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Permission requested")
                        .font(theme.bodySmallFont)
                        .foregroundColor(theme.textSecondary)
                    Spacer()
                }
            } else {
                HStack {
                    Spacer()
                    ThemedButton(buttonTitle, style: .secondary, size: .small, action: onTap)
                }
            }
        }
        .padding(theme.spacing.lg)
        .background(theme.surfaceColor)
        .cornerRadius(theme.cornerRadius.medium)
    }
}

// MARK: - Completion View

private struct CompletionView: View {
    let onComplete: () -> Void
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(spacing: theme.spacing.xl) {
            Spacer()
            
            VStack(spacing: theme.spacing.lg) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 100))
                    .foregroundColor(.green)
                
                Text("You're all set!")
                    .font(theme.titleLargeFont)
                    .foregroundColor(theme.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text("Welcome to FitnessCoach! Your personalized fitness journey begins now. Let's start achieving your goals together.")
                    .font(theme.bodyLargeFont)
                    .foregroundColor(theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, theme.spacing.lg)
            }
            
            Spacer()
            
            ThemedButton("Start My Journey", style: .primary, size: .large) {
                onComplete()
            }
            .padding(.horizontal, theme.spacing.lg)
            .padding(.bottom, theme.spacing.xl)
        }
    }
}

// MARK: - Preview

#Preview {
    OnboardingFlowView()
        .environmentObject(AuthenticationManager())
        .environmentObject(HealthKitManager())
        .theme(FitnessTheme())
}