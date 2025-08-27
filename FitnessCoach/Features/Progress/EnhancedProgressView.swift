import SwiftUI

// MARK: - Enhanced Progress View
public struct EnhancedProgressView: View {
    @Environment(\.theme) private var theme
    @State private var selectedTimeRange: ProgressChartView.TimeRange = .month
    @State private var showingGoalSheet = false
    @State private var showingDetailsModal = false
    @State private var animateOnAppear = false
    
    // Sample data
    @State private var weightProgress: [ProgressDataPoint] = [
        ProgressDataPoint(date: Calendar.current.date(byAdding: .day, value: -30, to: Date())!, value: 180, category: "Weight"),
        ProgressDataPoint(date: Calendar.current.date(byAdding: .day, value: -25, to: Date())!, value: 178, category: "Weight"),
        ProgressDataPoint(date: Calendar.current.date(byAdding: .day, value: -20, to: Date())!, value: 176, category: "Weight"),
        ProgressDataPoint(date: Calendar.current.date(byAdding: .day, value: -15, to: Date())!, value: 175, category: "Weight"),
        ProgressDataPoint(date: Calendar.current.date(byAdding: .day, value: -10, to: Date())!, value: 173, category: "Weight"),
        ProgressDataPoint(date: Calendar.current.date(byAdding: .day, value: -5, to: Date())!, value: 172, category: "Weight"),
        ProgressDataPoint(date: Date(), value: 170, category: "Weight")
    ]
    
    @State private var bodyComposition = BodyCompositionData(
        muscle: 48.2,
        fat: 15.8,
        water: 58.5,
        bone: 16.1
    )
    
    @State private var weeklyActivity: [ActivityRingData] = [
        ActivityRingData(date: Calendar.current.date(byAdding: .day, value: -6, to: Date())!, move: 450, exercise: 35, stand: 10),
        ActivityRingData(date: Calendar.current.date(byAdding: .day, value: -5, to: Date())!, move: 520, exercise: 45, stand: 12),
        ActivityRingData(date: Calendar.current.date(byAdding: .day, value: -4, to: Date())!, move: 380, exercise: 25, stand: 8),
        ActivityRingData(date: Calendar.current.date(byAdding: .day, value: -3, to: Date())!, move: 610, exercise: 60, stand: 14),
        ActivityRingData(date: Calendar.current.date(byAdding: .day, value: -2, to: Date())!, move: 480, exercise: 40, stand: 11),
        ActivityRingData(date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!, move: 550, exercise: 55, stand: 13),
        ActivityRingData(date: Date(), move: 420, exercise: 30, stand: 9)
    ]
    
    @State private var workoutIntensity: [WorkoutIntensityData] = [
        WorkoutIntensityData(date: Calendar.current.date(byAdding: .day, value: -20, to: Date())!, intensity: 0.8, duration: 45*60, workoutType: "HIIT", caloriesBurned: 450),
        WorkoutIntensityData(date: Calendar.current.date(byAdding: .day, value: -19, to: Date())!, intensity: 0.4, duration: 30*60, workoutType: "Yoga", caloriesBurned: 200),
        WorkoutIntensityData(date: Calendar.current.date(byAdding: .day, value: -17, to: Date())!, intensity: 0.9, duration: 60*60, workoutType: "Strength", caloriesBurned: 400),
        WorkoutIntensityData(date: Calendar.current.date(byAdding: .day, value: -15, to: Date())!, intensity: 0.3, duration: 25*60, workoutType: "Walking", caloriesBurned: 150),
        WorkoutIntensityData(date: Calendar.current.date(byAdding: .day, value: -14, to: Date())!, intensity: 0.7, duration: 40*60, workoutType: "Running", caloriesBurned: 380)
    ]
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            ZStack(alignment: .bottomTrailing) {
                ScrollView {
                    LazyVStack(spacing: theme.spacing.lg) {
                        headerSection
                        
                        quickStatsSection
                        
                        progressChartsSection
                        
                        bodyCompositionSection
                        
                        activityRingsSection
                        
                        workoutIntensitySection
                        
                        achievementsSection
                        
                        // Bottom padding for FAB
                        Color.clear.frame(height: 100)
                    }
                    .padding(.horizontal, theme.spacing.md)
                    .opacity(animateOnAppear ? 1 : 0)
                    .offset(y: animateOnAppear ? 0 : 50)
                    .animation(theme.animations.springNormal.delay(0.2), value: animateOnAppear)
                }
                .background(Color(.systemGroupedBackground))
                
                // Floating Action Menu
                FABMenu(
                    mainIcon: "plus",
                    items: [
                        FABMenu.MenuItem(icon: "camera", title: "Progress Photo") {
                            // Handle photo action
                        },
                        FABMenu.MenuItem(icon: "scalemass", title: "Log Weight") {
                            // Handle weight logging
                        },
                        FABMenu.MenuItem(icon: "ruler", title: "Body Measurements") {
                            // Handle measurements
                        },
                        FABMenu.MenuItem(icon: "target", title: "Set Goal") {
                            showingGoalSheet = true
                        }
                    ]
                )
                .padding(.bottom, theme.spacing.xl)
                .padding(.trailing, theme.spacing.lg)
            }
            .navigationTitle("Progress")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingDetailsModal = true }) {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(theme.primaryColor)
                    }
                }
            }
        }
        .sheet(isPresented: $showingGoalSheet) {
            goalSheetView
        }
        .sheet(isPresented: $showingDetailsModal) {
            detailsModalView
        }
        .onAppear {
            withAnimation(theme.animations.springNormal.delay(0.1)) {
                animateOnAppear = true
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    Text("Welcome back, Alex!")
                        .font(theme.typography.headlineLarge)
                        .foregroundColor(theme.textPrimary)
                        .fontWeight(.bold)
                    
                    Text("You're making great progress this week")
                        .font(theme.typography.bodyMedium)
                        .foregroundColor(theme.textSecondary)
                }
                
                Spacer()
                
                // Profile avatar
                Circle()
                    .fill(theme.gradients.primary)
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text("A")
                            .font(theme.typography.headlineMedium)
                            .foregroundColor(.white)
                            .fontWeight(.bold)
                    )
            }
            
            // Progress streak
            HStack(spacing: theme.spacing.sm) {
                Image(systemName: "flame.fill")
                    .foregroundColor(theme.warningColor)
                    .font(.title3)
                
                Text("7-day streak!")
                    .font(theme.typography.labelLarge)
                    .foregroundColor(theme.warningColor)
                    .fontWeight(.semibold)
                
                Spacer()
                
                SuccessAnimation(
                    type: .flame,
                    style: .pulse,
                    color: theme.warningColor,
                    size: 24,
                    isAnimating: animateOnAppear
                )
            }
            .padding(theme.spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: theme.cornerRadius.md)
                    .fill(theme.warningColor.opacity(0.1))
            )
        }
        .padding(.top, theme.spacing.md)
    }
    
    // MARK: - Quick Stats Section
    
    private var quickStatsSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            HStack {
                Text("This Week")
                    .font(theme.typography.headlineMedium)
                    .foregroundColor(theme.textPrimary)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("See All") {
                    showingDetailsModal = true
                }
                .font(theme.typography.labelMedium)
                .foregroundColor(theme.primaryColor)
            }
            
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible()), count: 2),
                spacing: theme.spacing.sm
            ) {
                quickStatCard(
                    title: "Weight Lost",
                    value: "2.5 lbs",
                    subtitle: "This month",
                    color: theme.successColor,
                    icon: "arrow.down.circle.fill"
                )
                
                quickStatCard(
                    title: "Workouts",
                    value: "12",
                    subtitle: "This week",
                    color: theme.primaryColor,
                    icon: "figure.strengthtraining.traditional"
                )
                
                quickStatCard(
                    title: "Calories Burned",
                    value: "3,240",
                    subtitle: "This week",
                    color: theme.errorColor,
                    icon: "flame.fill"
                )
                
                quickStatCard(
                    title: "Sleep Quality",
                    value: "87%",
                    subtitle: "Average",
                    color: theme.infoColor,
                    icon: "moon.fill"
                )
            }
        }
    }
    
    private func quickStatCard(title: String, value: String, subtitle: String, color: Color, icon: String) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                Text(value)
                    .font(theme.typography.headlineLarge)
                    .foregroundColor(color)
                    .fontWeight(.bold)
                
                Text(title)
                    .font(theme.typography.bodySmall)
                    .foregroundColor(theme.textPrimary)
                    .fontWeight(.medium)
                
                Text(subtitle)
                    .font(theme.typography.labelSmall)
                    .foregroundColor(theme.textSecondary)
            }
        }
        .padding(theme.spacing.md)
        .background(theme.cardColor)
        .cornerRadius(theme.cornerRadius.card)
        .shadow(
            color: theme.shadows.sm.color,
            radius: theme.shadows.sm.radius,
            x: theme.shadows.sm.x,
            y: theme.shadows.sm.y
        )
    }
    
    // MARK: - Progress Charts Section
    
    private var progressChartsSection: some View {
        VStack(spacing: theme.spacing.md) {
            ProgressChartView(
                title: "Weight Progress",
                data: weightProgress,
                chartType: .area,
                showGoalLine: true,
                goalValue: 165
            )
        }
    }
    
    // MARK: - Body Composition Section
    
    private var bodyCompositionSection: some View {
        BodyCompositionView(
            data: bodyComposition,
            style: .detailed
        )
    }
    
    // MARK: - Activity Rings Section
    
    private var activityRingsSection: some View {
        WeeklyActivityRings(
            weekData: weeklyActivity,
            mode: .weekly
        )
    }
    
    // MARK: - Workout Intensity Section
    
    private var workoutIntensitySection: some View {
        WorkoutIntensityChart(data: workoutIntensity)
    }
    
    // MARK: - Achievements Section
    
    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            HStack {
                Text("Recent Achievements")
                    .font(theme.typography.headlineMedium)
                    .foregroundColor(theme.textPrimary)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("View All") {
                    // Handle view all achievements
                }
                .font(theme.typography.labelMedium)
                .foregroundColor(theme.primaryColor)
            }
            
            LazyVStack(spacing: theme.spacing.sm) {
                achievementCard(
                    title: "First Week Complete",
                    description: "Completed your first week of workouts",
                    date: "2 days ago",
                    icon: "trophy.fill",
                    color: theme.warningColor
                )
                
                achievementCard(
                    title: "Weight Loss Milestone",
                    description: "Lost 5 pounds - great progress!",
                    date: "1 week ago",
                    icon: "target",
                    color: theme.successColor
                )
                
                achievementCard(
                    title: "Consistency King",
                    description: "7 days of logging your workouts",
                    date: "Today",
                    icon: "flame.fill",
                    color: theme.primaryColor
                )
            }
        }
    }
    
    private func achievementCard(title: String, description: String, date: String, icon: String, color: Color) -> some View {
        HStack(spacing: theme.spacing.md) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
            }
            
            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                Text(title)
                    .font(theme.typography.bodyMedium)
                    .foregroundColor(theme.textPrimary)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(theme.typography.bodySmall)
                    .foregroundColor(theme.textSecondary)
                
                Text(date)
                    .font(theme.typography.labelSmall)
                    .foregroundColor(theme.textTertiary)
            }
            
            Spacer()
            
            Button(action: {}) {
                Image(systemName: "chevron.right")
                    .foregroundColor(theme.textTertiary)
                    .font(.caption)
            }
        }
        .padding(theme.spacing.md)
        .background(theme.cardColor)
        .cornerRadius(theme.cornerRadius.card)
        .shadow(
            color: theme.shadows.xs.color,
            radius: theme.shadows.xs.radius,
            x: theme.shadows.xs.x,
            y: theme.shadows.xs.y
        )
    }
    
    // MARK: - Sheet Views
    
    private var goalSheetView: some View {
        NavigationView {
            VStack(spacing: theme.spacing.lg) {
                Text("Set New Goal")
                    .font(theme.typography.headlineLarge)
                    .foregroundColor(theme.textPrimary)
                    .fontWeight(.bold)
                
                // Goal setting form would go here
                Text("Goal setting form coming soon!")
                    .font(theme.typography.bodyMedium)
                    .foregroundColor(theme.textSecondary)
                
                Spacer()
            }
            .padding(theme.spacing.lg)
            .navigationTitle("New Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showingGoalSheet = false
                    }
                }
            }
        }
    }
    
    private var detailsModalView: some View {
        NavigationView {
            VStack(spacing: theme.spacing.lg) {
                Text("Detailed Progress")
                    .font(theme.typography.headlineLarge)
                    .foregroundColor(theme.textPrimary)
                    .fontWeight(.bold)
                
                // Detailed views would go here
                Text("Detailed analytics coming soon!")
                    .font(theme.typography.bodyMedium)
                    .foregroundColor(theme.textSecondary)
                
                Spacer()
            }
            .padding(theme.spacing.lg)
            .navigationTitle("Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        showingDetailsModal = false
                    }
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    EnhancedProgressView()
        .theme(FitnessTheme())
}