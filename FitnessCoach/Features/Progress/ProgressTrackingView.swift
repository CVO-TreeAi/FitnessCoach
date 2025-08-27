import SwiftUI
import HealthKit

struct ProgressTrackingView: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    @EnvironmentObject private var healthKitManager: HealthKitManager
    @Environment(\.theme) private var theme
    
    @StateObject private var viewModel = ProgressTrackingViewModel()
    @State private var showingWeightEntry = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: theme.spacing.lg) {
                    // Quick Stats Cards
                    quickStatsSection
                    
                    // Simple Chart Placeholder
                    chartSection
                    
                    // Health Metrics
                    healthMetricsSection
                }
                .padding(theme.spacing.md)
            }
            .navigationTitle("Progress")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add Weight") {
                        showingWeightEntry = true
                    }
                    .foregroundColor(theme.primaryColor)
                }
            }
        }
        .sheet(isPresented: $showingWeightEntry) {
            WeightEntryView(viewModel: viewModel)
        }
        .onAppear {
            viewModel.loadProgressData()
        }
    }
    
    private var quickStatsSection: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: theme.spacing.md) {
            ThemedStatCard(
                title: "Current Weight",
                value: viewModel.currentWeightString,
                subtitle: viewModel.weightGoalString,
                icon: Image(systemName: "scalemass"),
                trend: .down,
                trendValue: "-2.3%"
            )
            
            ThemedStatCard(
                title: "Days Tracked",
                value: "7",
                subtitle: "This month",
                icon: Image(systemName: "calendar"),
                trend: .up,
                trendValue: "+7"
            )
        }
    }
    
    private var chartSection: some View {
        ThemedCard {
            VStack(alignment: .leading, spacing: theme.spacing.md) {
                Text("Weight Progress")
                    .font(theme.typography.titleSmall)
                    .foregroundColor(theme.textPrimary)
                
                // Simple chart placeholder
                RoundedRectangle(cornerRadius: theme.cornerRadius.medium)
                    .fill(theme.primaryColor.opacity(0.1))
                    .frame(height: 200)
                    .overlay(
                        VStack {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 40))
                                .foregroundColor(theme.primaryColor)
                            Text("Progress Chart")
                                .font(theme.bodyMediumFont)
                                .foregroundColor(theme.textSecondary)
                        }
                    )
            }
        }
    }
    
    private var healthMetricsSection: some View {
        ThemedCard {
            VStack(alignment: .leading, spacing: theme.spacing.md) {
                HStack {
                    Text("Health Metrics")
                        .font(theme.typography.titleSmall)
                        .foregroundColor(theme.textPrimary)
                    
                    Spacer()
                    
                    if !healthKitManager.isAuthorized {
                        Button("Connect Health") {
                            Task {
                                try await healthKitManager.requestAuthorization()
                            }
                        }
                        .font(theme.typography.bodySmall)
                        .foregroundColor(theme.primaryColor)
                    }
                }
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: theme.spacing.sm) {
                    HealthMetricCard(
                        title: "Heart Rate",
                        value: "72",
                        unit: "bpm",
                        icon: "heart.fill",
                        color: .red
                    )
                    
                    HealthMetricCard(
                        title: "Blood Pressure",
                        value: "120/80",
                        unit: "mmHg",
                        icon: "heart.circle",
                        color: .blue
                    )
                }
            }
        }
    }
}

struct HealthMetricCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.caption)
                
                Text(title)
                    .font(theme.typography.bodySmall)
                    .foregroundColor(theme.textSecondary)
                
                Spacer()
            }
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(theme.typography.titleSmall)
                    .foregroundColor(theme.textPrimary)
                
                Text(unit)
                    .font(theme.typography.bodySmall)
                    .foregroundColor(theme.textTertiary)
            }
        }
        .padding(theme.spacing.sm)
        .background(theme.backgroundColor)
        .cornerRadius(theme.cornerRadius.small)
    }
}

#Preview {
    ProgressTrackingView()
        .environmentObject(AuthenticationManager())
        .environmentObject(HealthKitManager())
        .theme(FitnessTheme())
}