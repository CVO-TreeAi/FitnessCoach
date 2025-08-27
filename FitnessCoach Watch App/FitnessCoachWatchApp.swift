import SwiftUI
import WatchKit
import HealthKit

@main
struct FitnessCoachWatchApp: App {
    @StateObject private var watchConnectivityManager = WatchConnectivityManager()
    @StateObject private var workoutManager = WorkoutManager()
    @StateObject private var healthKitManager = WatchHealthKitManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(watchConnectivityManager)
                .environmentObject(workoutManager)
                .environmentObject(healthKitManager)
                .onAppear {
                    requestHealthKitPermissions()
                }
        }
        .backgroundTask(.appRefresh("fitness-update")) { 
            // Handle background app refresh
            await updateFitnessData()
        }
    }
    
    private func requestHealthKitPermissions() {
        Task {
            do {
                try await healthKitManager.requestAuthorization()
            } catch {
                print("HealthKit authorization failed: \(error)")
            }
        }
    }
    
    private func updateFitnessData() async {
        // Update fitness data in background
        await watchConnectivityManager.syncWithPhone()
    }
}

struct ContentView: View {
    @EnvironmentObject private var watchConnectivity: WatchConnectivityManager
    @EnvironmentObject private var workoutManager: WorkoutManager
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Dashboard Tab
            WatchDashboardView()
                .tag(0)
            
            // Workout Tab
            WorkoutView()
                .tag(1)
            
            // Stats Tab
            StatsView()
                .tag(2)
            
            // Settings Tab
            SettingsView()
                .tag(3)
        }
        .tabViewStyle(.page(indexDisplayMode: .automatic))
        .onAppear {
            // Set up Watch Connectivity
            watchConnectivity.startSession()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(WatchConnectivityManager())
        .environmentObject(WorkoutManager())
        .environmentObject(WatchHealthKitManager())
}