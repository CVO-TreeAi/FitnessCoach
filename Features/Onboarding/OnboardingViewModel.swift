import Foundation
import SwiftUI

@MainActor
public class OnboardingViewModel: ObservableObject {
    @Published public var currentStep: OnboardingStep = .welcome
    @Published public var selectedRole: UserRole = .user
    @Published public var personalInfo = PersonalInfo()
    @Published public var selectedGoals: Set<FitnessGoal> = []
    @Published public var selectedActivityLevel: ActivityLevel = .moderate
    @Published public var healthMetrics = HealthMetrics()
    @Published public var healthKitPermissionGranted = false
    @Published public var notificationPermissionGranted = false
    @Published public var isCompleting = false
    
    private let coreDataManager = CoreDataManager.shared
    
    // MARK: - Computed Properties
    
    public var progress: Double {
        let totalSteps = Double(OnboardingStep.allCases.count - 2) // Exclude welcome and completion
        let currentStepIndex = Double(max(0, currentStep.rawValue - 1))
        return min(currentStepIndex / totalSteps, 1.0)
    }
    
    public var canGoBack: Bool {
        currentStep.rawValue > OnboardingStep.roleSelection.rawValue
    }
    
    // MARK: - Navigation Methods
    
    public func nextStep() {
        withAnimation(.easeInOut(duration: 0.3)) {
            if let nextStep = OnboardingStep(rawValue: currentStep.rawValue + 1) {
                currentStep = nextStep
            }
        }
    }
    
    public func previousStep() {
        withAnimation(.easeInOut(duration: 0.3)) {
            if let previousStep = OnboardingStep(rawValue: currentStep.rawValue - 1) {
                currentStep = previousStep
            }
        }
    }
    
    // MARK: - Completion
    
    public func completeOnboarding() async {
        isCompleting = true
        
        do {
            // Save user data to Core Data
            try await saveUserProfile()
            
            // Update authentication manager
            // This would typically involve updating the user's onboarding status
            
            isCompleting = false
        } catch {
            print("Failed to complete onboarding: \(error)")
            isCompleting = false
        }
    }
    
    // MARK: - Private Methods
    
    private func saveUserProfile() async throws {
        // This would be implemented with proper user management
        // For now, we'll just save the data to UserDefaults as a placeholder
        
        let encoder = JSONEncoder()
        
        // Save role
        UserDefaults.standard.set(selectedRole.rawValue, forKey: "user_role")
        
        // Save personal info
        if let personalInfoData = try? encoder.encode(personalInfo) {
            UserDefaults.standard.set(personalInfoData, forKey: "personal_info")
        }
        
        // Save fitness goals
        let goalStrings = selectedGoals.map { $0.rawValue }
        UserDefaults.standard.set(goalStrings, forKey: "fitness_goals")
        
        // Save activity level
        UserDefaults.standard.set(selectedActivityLevel.rawValue, forKey: "activity_level")
        
        // Save health metrics
        if let healthMetricsData = try? encoder.encode(healthMetrics) {
            UserDefaults.standard.set(healthMetricsData, forKey: "health_metrics")
        }
        
        // Save permissions
        UserDefaults.standard.set(healthKitPermissionGranted, forKey: "healthkit_permission")
        UserDefaults.standard.set(notificationPermissionGranted, forKey: "notification_permission")
        
        // Mark onboarding as completed
        UserDefaults.standard.set(true, forKey: "onboarding_completed")
        
        // Seed initial data if needed
        coreDataManager.seedInitialData()
    }
}

// MARK: - Onboarding Step Enum

public enum OnboardingStep: Int, CaseIterable {
    case welcome = 0
    case roleSelection = 1
    case personalInfo = 2
    case fitnessGoals = 3
    case activityLevel = 4
    case healthMetrics = 5
    case permissions = 6
    case completion = 7
}

// MARK: - Personal Info Model

public struct PersonalInfo: Codable {
    public var dateOfBirth = Calendar.current.date(byAdding: .year, value: -25, to: Date()) ?? Date()
    public var gender = "Male"
    public var height: Double = 170 // cm
    public var currentWeight: Double = 70 // kg
    
    public init() {}
}

// MARK: - Fitness Goal Enum

public enum FitnessGoal: String, CaseIterable, Codable, Hashable {
    case weightLoss = "weight_loss"
    case muscleGain = "muscle_gain"
    case strengthBuilding = "strength_building"
    case enduranceImprovement = "endurance_improvement"
    case generalFitness = "general_fitness"
    case bodyRecomposition = "body_recomposition"
    case sportPerformance = "sport_performance"
    case rehabilitation = "rehabilitation"
    
    public var title: String {
        switch self {
        case .weightLoss: return "Weight Loss"
        case .muscleGain: return "Muscle Gain"
        case .strengthBuilding: return "Strength Building"
        case .enduranceImprovement: return "Endurance"
        case .generalFitness: return "General Fitness"
        case .bodyRecomposition: return "Body Recomposition"
        case .sportPerformance: return "Sport Performance"
        case .rehabilitation: return "Rehabilitation"
        }
    }
    
    public var description: String {
        switch self {
        case .weightLoss: return "Lose body fat and reach your target weight"
        case .muscleGain: return "Build lean muscle mass and size"
        case .strengthBuilding: return "Increase overall strength and power"
        case .enduranceImprovement: return "Improve cardiovascular fitness"
        case .generalFitness: return "Stay healthy and feel great"
        case .bodyRecomposition: return "Lose fat while gaining muscle"
        case .sportPerformance: return "Enhance athletic performance"
        case .rehabilitation: return "Recover from injury safely"
        }
    }
    
    public var icon: String {
        switch self {
        case .weightLoss: return "scalemass"
        case .muscleGain: return "figure.strengthtraining.traditional"
        case .strengthBuilding: return "dumbbell.fill"
        case .enduranceImprovement: return "heart.fill"
        case .generalFitness: return "figure.walk"
        case .bodyRecomposition: return "arrow.triangle.2.circlepath"
        case .sportPerformance: return "sportscourt.fill"
        case .rehabilitation: return "cross.fill"
        }
    }
}

// MARK: - Activity Level Enum

public enum ActivityLevel: String, CaseIterable, Codable {
    case sedentary = "sedentary"
    case lightlyActive = "lightly_active"
    case moderate = "moderate"
    case veryActive = "very_active"
    case extremelyActive = "extremely_active"
    
    public var title: String {
        switch self {
        case .sedentary: return "Sedentary"
        case .lightlyActive: return "Lightly Active"
        case .moderate: return "Moderately Active"
        case .veryActive: return "Very Active"
        case .extremelyActive: return "Extremely Active"
        }
    }
    
    public var description: String {
        switch self {
        case .sedentary: return "Little to no exercise, desk job"
        case .lightlyActive: return "Light exercise 1-3 days per week"
        case .moderate: return "Moderate exercise 3-5 days per week"
        case .veryActive: return "Hard exercise 6-7 days per week"
        case .extremelyActive: return "Very hard exercise, physical job, training 2x/day"
        }
    }
    
    public var multiplier: Double {
        switch self {
        case .sedentary: return 1.2
        case .lightlyActive: return 1.375
        case .moderate: return 1.55
        case .veryActive: return 1.725
        case .extremelyActive: return 1.9
        }
    }
}

// MARK: - Health Metrics Model

public struct HealthMetrics: Codable {
    public var goalWeight: Double = 0
    public var medicalConditions: String = ""
    public var injuries: String = ""
    public var preferences: String = ""
    
    public init() {}
}

// MARK: - UserDefaults Extension

extension UserDefaults {
    public func getPersonalInfo() -> PersonalInfo? {
        guard let data = data(forKey: "personal_info") else { return nil }
        let decoder = JSONDecoder()
        return try? decoder.decode(PersonalInfo.self, from: data)
    }
    
    public func getFitnessGoals() -> Set<FitnessGoal> {
        guard let goalStrings = array(forKey: "fitness_goals") as? [String] else { return [] }
        let goals = goalStrings.compactMap { FitnessGoal(rawValue: $0) }
        return Set(goals)
    }
    
    public func getActivityLevel() -> ActivityLevel {
        guard let levelString = string(forKey: "activity_level"),
              let level = ActivityLevel(rawValue: levelString) else {
            return .moderate
        }
        return level
    }
    
    public func getHealthMetrics() -> HealthMetrics? {
        guard let data = data(forKey: "health_metrics") else { return nil }
        let decoder = JSONDecoder()
        return try? decoder.decode(HealthMetrics.self, from: data)
    }
    
    public func isOnboardingCompleted() -> Bool {
        return bool(forKey: "onboarding_completed")
    }
}