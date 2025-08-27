import SwiftUI
import CloudKit

@main
struct FitnessCoachApp: App {
    @StateObject private var authManager = AuthenticationManager()
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var healthKitManager = HealthKitManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(themeManager)
                .environmentObject(healthKitManager)
                .theme(themeManager.currentTheme)
                .onAppear {
                    requestHealthKitPermissions()
                }
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
}

struct ContentView: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    @Environment(\.theme) private var theme
    
    var body: some View {
        Group {
            if authManager.isLoading {
                LoadingView()
            } else if authManager.isAuthenticated {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .preferredColorScheme(nil) // Let system handle dark/light mode
    }
}

struct LoadingView: View {
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(spacing: theme.spacing.lg) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(theme.primaryColor)
            
            Text("Loading...")
                .font(theme.typography.bodyLarge)
                .foregroundColor(theme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.backgroundColor)
    }
}

struct MainTabView: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    @Environment(\.theme) private var theme
    
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Dashboard")
                }
            
            ProgressTrackingView()
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("Progress")
                }
            
            WorkoutsView()
                .tabItem {
                    Image(systemName: "figure.strengthtraining.traditional")
                    Text("Workouts")
                }
            
            NutritionView()
                .tabItem {
                    Image(systemName: "leaf.fill")
                    Text("Nutrition")
                }
            
            if authManager.hasPermission(.manageClients) {
                ClientsView()
                    .tabItem {
                        Image(systemName: "person.2.fill")
                        Text("Clients")
                    }
            }
        }
        .tint(theme.primaryColor)
    }
}

// MARK: - Placeholder Views

struct OnboardingView: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    @Environment(\.theme) private var theme
    
    var body: some View {
        NavigationView {
            VStack(spacing: theme.spacing.xl) {
                Text("Welcome to FitnessCoach")
                    .font(theme.typography.displayLarge)
                    .foregroundColor(theme.textPrimary)
                
                ThemedButton("Sign In with Apple", style: .primary) {
                    authManager.signInWithApple()
                }
                .padding()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(theme.backgroundColor)
        }
    }
}

struct DashboardView: View {
    var body: some View {
        NavigationView {
            Text("Dashboard View")
                .navigationTitle("Dashboard")
        }
    }
}

struct WorkoutsView: View {
    var body: some View {
        NavigationView {
            Text("Workouts View")
                .navigationTitle("Workouts")
        }
    }
}

struct NutritionView: View {
    var body: some View {
        NavigationView {
            Text("Nutrition View")
                .navigationTitle("Nutrition")
        }
    }
}

struct ClientsView: View {
    var body: some View {
        NavigationView {
            Text("Clients View")
                .navigationTitle("Clients")
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthenticationManager())
        .environmentObject(ThemeManager())
        .environmentObject(HealthKitManager())
        .theme(FitnessTheme())
}