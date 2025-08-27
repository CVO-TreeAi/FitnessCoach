import SwiftUI
import HealthKit

// MARK: - View Integration File
// This file ensures all views are properly integrated and accessible

// Export all main views
typealias MainDashboardView = CompleteDashboardView
typealias MainWorkoutsView = CompleteWorkoutsView  
typealias MainNutritionView = CompleteNutritionView
typealias MainProgressView = CompleteProgressView

// Export data manager
typealias MainDataManager = FitnessDataManager

// Export supporting views
typealias WorkoutBuilderView = WorkoutTemplateDetailView
typealias ExerciseLibraryDetailView = ExerciseDetailView

// Integration utilities
struct ViewHelpers {
    static func formatNumber(_ number: Double) -> String {
        if number >= 1000 {
            return String(format: "%.1fk", number / 1000)
        } else {
            return String(format: "%.0f", number)
        }
    }
    
    static func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else if calendar.isDate(date, equalTo: Date(), toGranularity: .year) {
            formatter.dateFormat = "EEEE, MMMM d"
        } else {
            formatter.dateFormat = "EEEE, MMMM d, yyyy"
        }
        
        return formatter.string(from: date)
    }
    
    static func formatWeight(_ weight: Double) -> String {
        return String(format: "%.1f lbs", weight)
    }
    
    static func formatCalories(_ calories: Double) -> String {
        return String(format: "%.0f cal", calories)
    }
}

// Color extensions for consistency
extension Color {
    static let fitnessBlue = Color.blue
    static let fitnessGreen = Color.green
    static let fitnessOrange = Color.orange
    static let fitnessRed = Color.red
    static let fitnessPurple = Color.purple
}

// MARK: - App State Management
@MainActor
class AppStateManager: ObservableObject {
    @Published var isHealthKitAuthorized = false
    @Published var hasCompletedOnboarding = true // Set to true for immediate access
    @Published var selectedMainTab = 0
    
    func setupApp(with healthKitManager: HealthKitManager) {
        // Setup initial app state
        isHealthKitAuthorized = healthKitManager.isAuthorized
        
        // Request HealthKit permissions if needed
        if !isHealthKitAuthorized {
            Task {
                do {
                    try await healthKitManager.requestAuthorization()
                    isHealthKitAuthorized = true
                } catch {
                    print("HealthKit setup failed: \(error)")
                }
            }
        }
    }
}

#Preview("Complete App") {
    CompleteFunctionalTabView()
        .environmentObject(FitnessDataManager.shared)
        .environmentObject(AuthenticationManager())
        .environmentObject(ThemeManager())
        .environmentObject(HealthKitManager())
        .theme(FitnessTheme())
}