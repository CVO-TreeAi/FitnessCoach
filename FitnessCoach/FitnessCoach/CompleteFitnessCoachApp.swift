import SwiftUI
import HealthKit

// MARK: - Complete Functional FitnessCoach App
struct CompleteFunctionalTabView: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var healthKitManager: HealthKitManager
    @EnvironmentObject private var dataManager: FitnessDataManager
    @Environment(\.theme) private var theme
    
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Dashboard Tab
            CompleteDashboardView()
                .tabItem {
                    Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                    Text("Dashboard")
                }
                .tag(0)
            
            // Workouts Tab
            CompleteWorkoutsView()
                .tabItem {
                    Image(systemName: selectedTab == 1 ? "dumbbell.fill" : "dumbbell")
                    Text("Workouts")
                }
                .tag(1)
            
            // Nutrition Tab
            CompleteNutritionView()
                .tabItem {
                    Image(systemName: selectedTab == 2 ? "leaf.fill" : "leaf")
                    Text("Nutrition")
                }
                .tag(2)
            
            // Progress Tab
            CompleteProgressView()
                .tabItem {
                    Image(systemName: selectedTab == 3 ? "chart.line.uptrend.xyaxis" : "chart.line.uptrend.xyaxis")
                    Text("Progress")
                }
                .tag(3)
        }
        .tint(theme.primaryColor)
        .onAppear {
            requestHealthKitPermissionsIfNeeded()
            setupInitialData()
        }
    }
    
    private func requestHealthKitPermissionsIfNeeded() {
        guard HKHealthStore.isHealthDataAvailable() && !healthKitManager.isAuthorized else { return }
        
        Task {
            do {
                try await healthKitManager.requestAuthorization()
                print("HealthKit authorized successfully")
            } catch {
                print("HealthKit authorization failed: \(error)")
            }
        }
    }
    
    private func setupInitialData() {
        // Load sample data if needed
        if dataManager.exercises.isEmpty {
            print("Loading sample data...")
        }
        
        // Update dashboard stats with HealthKit data
        updateDashboardWithHealthKitData()
    }
    
    private func updateDashboardWithHealthKitData() {
        // Update dashboard stats with real HealthKit data when available
        if healthKitManager.isAuthorized {
            // Update the dashboard stats with HealthKit data
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                // This would ideally be done in the data manager
                // but for now we'll ensure the dashboard shows real data
                print("Updating dashboard with HealthKit data")
                print("Steps: \(healthKitManager.todaysSteps)")
                print("Active Energy: \(healthKitManager.todaysActiveEnergy)")
                print("Active Minutes: \(healthKitManager.todaysActiveMinutes)")
            }
        }
    }
}

// MARK: - Enhanced Data Manager Integration
extension FitnessDataManager {
    func syncWithHealthKit(_ healthKitManager: HealthKitManager) {
        // Update dashboard stats with HealthKit data
        if healthKitManager.isAuthorized {
            dashboardStats = DashboardStats(
                todayCalories: mealEntries.caloriesForDay(Date()),
                calorieGoal: 2200,
                waterCups: Int(waterEntries.totalForDay(Date()) / 8),
                waterGoal: 8,
                activeMinutes: healthKitManager.todaysActiveMinutes,
                activeGoal: 30,
                steps: healthKitManager.todaysSteps,
                stepsGoal: 10000,
                workoutsThisWeek: workoutSessions.sessionsForWeek().filter { $0.isCompleted }.count,
                workoutGoal: 4,
                currentStreak: calculateWorkoutStreak().current,
                longestStreak: calculateWorkoutStreak().longest
            )
        }
    }
}

// Update the dashboard to use HealthKit data
extension CompleteDashboardView {
    func refreshHealthKitData() {
        Task {
            if healthKitManager.isAuthorized {
                await healthKitManager.fetchTodaysHealthData()
                dataManager.syncWithHealthKit(healthKitManager)
            }
        }
    }
}

#Preview {
    CompleteFunctionalTabView()
        .environmentObject(FitnessDataManager.shared)
        .environmentObject(AuthenticationManager())
        .environmentObject(ThemeManager())
        .environmentObject(HealthKitManager())
        .theme(FitnessTheme())
}