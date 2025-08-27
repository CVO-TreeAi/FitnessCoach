import SwiftUI

struct FunctionalMainTabView: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    @EnvironmentObject private var dataManager: DataManager
    @Environment(\.theme) private var theme
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            FunctionalDashboardView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Dashboard")
                }
                .tag(0)
            
            FunctionalProgressView()
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("Progress")
                }
                .tag(1)
            
            FunctionalWorkoutsView()
                .tabItem {
                    Image(systemName: "figure.strengthtraining.traditional")
                    Text("Workouts")
                }
                .tag(2)
            
            FunctionalNutritionView()
                .tabItem {
                    Image(systemName: "leaf.fill")
                    Text("Nutrition")
                }
                .tag(3)
            
            FunctionalProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
                .tag(4)
        }
        .tint(theme.primaryColor)
    }
}

struct FunctionalDashboardView: View {
    @EnvironmentObject private var dataManager: DataManager
    @Environment(\.theme) private var theme
    @State private var showingWeightEntry = false
    @State private var showingQuickWorkout = false
    @State private var showingGoalSetting = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: theme.spacing.lg) {
                    // Header
                    headerSection
                    
                    // Quick Stats
                    quickStatsGrid
                    
                    // Today's Progress
                    todaysProgressSection
                    
                    // Quick Actions
                    quickActionsSection
                    
                    // Recent Activity
                    recentActivitySection
                }
                .padding(.horizontal)
                .padding(.bottom, 50)
            }
            .navigationTitle("Dashboard")
            .background(theme.backgroundColor)
            .sheet(isPresented: $showingWeightEntry) {
                WeightEntryForm(isPresented: $showingWeightEntry) { weight in
                    dataManager.updateWeight(weight)
                }
            }
            .sheet(isPresented: $showingQuickWorkout) {
                QuickWorkoutSheet(isPresented: $showingQuickWorkout)
            }
            .sheet(isPresented: $showingGoalSetting) {
                GoalSettingForm(isPresented: $showingGoalSetting)
            }
        }
    }
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(greetingText)
                    .font(theme.typography.headlineLarge)
                    .foregroundColor(theme.textPrimary)
                
                Text("Let's crush your goals today!")
                    .font(theme.typography.bodyMedium)
                    .foregroundColor(theme.textSecondary)
            }
            
            Spacer()
            
            Button {
                // Profile action
            } label: {
                Circle()
                    .fill(theme.primaryColor.gradient)
                    .frame(width: 60, height: 60)
                    .overlay(
                        Text("JD")
                            .font(theme.typography.titleMedium)
                            .foregroundColor(.white)
                    )
            }
        }
        .padding(.vertical)
    }
    
    private var quickStatsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: theme.spacing.md) {
            StatCard(
                title: "Weight",
                value: String(format: "%.1f", dataManager.currentWeight),
                unit: "lbs",
                trend: .down,
                trendValue: "2.5",
                icon: "scalemass",
                color: theme.primaryColor
            )
            .onTapGesture {
                showingWeightEntry = true
            }
            
            StatCard(
                title: "Calories",
                value: "\(dataManager.todaysCalories)",
                unit: "cal",
                trend: .up,
                trendValue: "320",
                icon: "flame.fill",
                color: .orange
            )
            
            StatCard(
                title: "Workouts",
                value: "\(dataManager.weeklyWorkouts)",
                unit: "this week",
                trend: .up,
                trendValue: "2",
                icon: "figure.run",
                color: .green
            )
            .onTapGesture {
                showingQuickWorkout = true
            }
            
            StatCard(
                title: "Water",
                value: "\(dataManager.waterIntake)",
                unit: "cups",
                trend: .neutral,
                trendValue: "Goal: 8",
                icon: "drop.fill",
                color: .blue
            )
        }
    }
    
    private var todaysProgressSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            Text("Today's Progress")
                .font(theme.typography.titleMedium)
                .foregroundColor(theme.textPrimary)
            
            VStack(spacing: theme.spacing.sm) {
                ProgressRow(
                    title: "Calories",
                    current: dataManager.todaysCalories,
                    goal: 2200,
                    unit: "cal",
                    color: .orange
                )
                
                ProgressRow(
                    title: "Protein",
                    current: 85,
                    goal: 120,
                    unit: "g",
                    color: .purple
                )
                
                ProgressRow(
                    title: "Steps",
                    current: 6500,
                    goal: 10000,
                    unit: "",
                    color: .green
                )
                
                ProgressRow(
                    title: "Water",
                    current: dataManager.waterIntake,
                    goal: 8,
                    unit: "cups",
                    color: .blue
                )
            }
            .padding()
            .background(theme.surfaceColor)
            .cornerRadius(theme.cornerRadius.medium)
        }
    }
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            Text("Quick Actions")
                .font(theme.typography.titleMedium)
                .foregroundColor(theme.textPrimary)
            
            HStack(spacing: theme.spacing.md) {
                QuickActionCard(
                    icon: "plus.circle.fill",
                    title: "Quick Workout",
                    color: theme.primaryColor
                ) {
                    showingQuickWorkout = true
                }
                
                QuickActionCard(
                    icon: "fork.knife",
                    title: "Log Meal",
                    color: .orange
                ) {
                    // Navigate to nutrition tab
                }
                
                QuickActionCard(
                    icon: "target",
                    title: "Set Goal",
                    color: .purple
                ) {
                    showingGoalSetting = true
                }
            }
        }
    }
    
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            HStack {
                Text("Recent Activity")
                    .font(theme.typography.titleMedium)
                    .foregroundColor(theme.textPrimary)
                
                Spacer()
                
                Button("See All") {
                    // Show all activity
                }
                .font(theme.typography.bodySmall)
                .foregroundColor(theme.primaryColor)
            }
            
            VStack(spacing: theme.spacing.sm) {
                ForEach(dataManager.workouts.prefix(3)) { workout in
                    HStack {
                        Circle()
                            .fill(workout.isCompleted ? Color.green : theme.primaryColor)
                            .frame(width: 40, height: 40)
                            .overlay(
                                Image(systemName: workout.isCompleted ? "checkmark" : "figure.run")
                                    .foregroundColor(.white)
                            )
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(workout.name)
                                .font(theme.typography.bodyMedium)
                                .foregroundColor(theme.textPrimary)
                            
                            Text("\(workout.duration) min • \(workout.category)")
                                .font(theme.typography.bodySmall)
                                .foregroundColor(theme.textSecondary)
                        }
                        
                        Spacer()
                        
                        Text(formatDate(workout.date))
                            .font(theme.typography.bodySmall)
                            .foregroundColor(theme.textTertiary)
                    }
                    .padding()
                    .background(theme.surfaceColor)
                    .cornerRadius(theme.cornerRadius.small)
                }
            }
        }
    }
    
    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 {
            return "Good Morning"
        } else if hour < 18 {
            return "Good Afternoon"
        } else {
            return "Good Evening"
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct FunctionalWorkoutsView: View {
    @EnvironmentObject private var dataManager: DataManager
    @Environment(\.theme) private var theme
    @State private var selectedCategory = "All"
    @State private var showingWorkoutBuilder = false
    @State private var searchText = ""
    
    let categories = ["All", "Strength", "Cardio", "HIIT", "Yoga", "Custom"]
    
    var filteredWorkouts: [DataManager.WorkoutData] {
        let categoryFiltered = selectedCategory == "All" ? dataManager.workouts :
            dataManager.workouts.filter { $0.category == selectedCategory }
        
        if searchText.isEmpty {
            return categoryFiltered
        }
        return categoryFiltered.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(theme.textSecondary)
                    
                    TextField("Search workouts...", text: $searchText)
                        .font(theme.typography.bodyMedium)
                }
                .padding()
                .background(theme.surfaceColor)
                .cornerRadius(theme.cornerRadius.medium)
                .padding()
                
                // Category filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: theme.spacing.sm) {
                        ForEach(categories, id: \.self) { category in
                            Button {
                                selectedCategory = category
                            } label: {
                                Text(category)
                                    .font(theme.typography.bodySmall)
                                    .foregroundColor(selectedCategory == category ? .white : theme.textPrimary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        selectedCategory == category ?
                                        theme.primaryColor : theme.surfaceColor
                                    )
                                    .cornerRadius(theme.cornerRadius.small)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                ScrollView {
                    LazyVStack(spacing: theme.spacing.md) {
                        if filteredWorkouts.isEmpty {
                            emptyStateView
                        } else {
                            ForEach(filteredWorkouts) { workout in
                                NavigationLink(destination: WorkoutDetailView(
                                    workoutName: workout.name,
                                    category: workout.category
                                )) {
                                    WorkoutCard(workout: workout)
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Workouts")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingWorkoutBuilder = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(theme.primaryColor)
                    }
                }
            }
            .sheet(isPresented: $showingWorkoutBuilder) {
                WorkoutBuilderForm(isPresented: $showingWorkoutBuilder)
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: theme.spacing.lg) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 60))
                .foregroundColor(theme.textTertiary)
            
            Text("No workouts found")
                .font(theme.typography.titleMedium)
                .foregroundColor(theme.textSecondary)
            
            Button {
                showingWorkoutBuilder = true
            } label: {
                Text("Create Your First Workout")
                    .font(theme.typography.bodyMedium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(theme.primaryColor)
                    .cornerRadius(theme.cornerRadius.medium)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

struct FunctionalNutritionView: View {
    @EnvironmentObject private var dataManager: DataManager
    @Environment(\.theme) private var theme
    @State private var showingFoodEntry = false
    @State private var showingMealPlanner = false
    @State private var selectedMealType = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: theme.spacing.lg) {
                    // Daily Summary
                    dailySummarySection
                    
                    // Meals
                    mealsSection
                    
                    // Water Intake
                    waterIntakeSection
                    
                    // Macros
                    macrosSection
                }
                .padding()
            }
            .navigationTitle("Nutrition")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingMealPlanner = true
                    } label: {
                        Image(systemName: "calendar")
                            .foregroundColor(theme.primaryColor)
                    }
                }
            }
            .sheet(isPresented: $showingFoodEntry) {
                FoodEntryForm(
                    isPresented: $showingFoodEntry,
                    mealType: selectedMealType
                ) { food, calories in
                    dataManager.addMeal(name: food, calories: calories, mealType: selectedMealType)
                }
            }
            .sheet(isPresented: $showingMealPlanner) {
                MealPlannerForm(isPresented: $showingMealPlanner)
            }
        }
    }
    
    private var dailySummarySection: some View {
        VStack(spacing: theme.spacing.md) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Today's Intake")
                        .font(theme.typography.titleMedium)
                        .foregroundColor(theme.textPrimary)
                    
                    Text("\(dataManager.todaysCalories) / 2200 cal")
                        .font(theme.typography.headlineLarge)
                        .foregroundColor(theme.primaryColor)
                }
                
                Spacer()
                
                CircularProgressView(
                    progress: Double(dataManager.todaysCalories) / 2200.0,
                    lineWidth: 8,
                    color: theme.primaryColor
                )
                .frame(width: 80, height: 80)
            }
            .padding()
            .background(theme.surfaceColor)
            .cornerRadius(theme.cornerRadius.medium)
        }
    }
    
    private var mealsSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            Text("Meals")
                .font(theme.typography.titleMedium)
                .foregroundColor(theme.textPrimary)
            
            ForEach(["Breakfast", "Lunch", "Dinner", "Snacks"], id: \.self) { meal in
                MealCard(
                    mealType: meal,
                    foods: dataManager.todaysMeals.filter { $0.mealType == meal },
                    onAdd: {
                        selectedMealType = meal
                        showingFoodEntry = true
                    }
                )
            }
        }
    }
    
    private var waterIntakeSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            HStack {
                Text("Water Intake")
                    .font(theme.typography.titleMedium)
                    .foregroundColor(theme.textPrimary)
                
                Spacer()
                
                Text("\(dataManager.waterIntake) / 8 cups")
                    .font(theme.typography.bodyMedium)
                    .foregroundColor(theme.textSecondary)
            }
            
            HStack(spacing: theme.spacing.sm) {
                ForEach(0..<8, id: \.self) { index in
                    Button {
                        if index < dataManager.waterIntake {
                            dataManager.updateWaterIntake(index)
                        } else {
                            dataManager.updateWaterIntake(index + 1)
                        }
                    } label: {
                        Image(systemName: index < dataManager.waterIntake ? "drop.fill" : "drop")
                            .font(.title2)
                            .foregroundColor(index < dataManager.waterIntake ? .blue : theme.textTertiary)
                    }
                }
            }
            .padding()
            .background(theme.surfaceColor)
            .cornerRadius(theme.cornerRadius.medium)
        }
    }
    
    private var macrosSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            Text("Macronutrients")
                .font(theme.typography.titleMedium)
                .foregroundColor(theme.textPrimary)
            
            HStack(spacing: theme.spacing.md) {
                MacroCard(
                    title: "Protein",
                    value: 85,
                    goal: 120,
                    unit: "g",
                    color: .purple
                )
                
                MacroCard(
                    title: "Carbs",
                    value: 180,
                    goal: 250,
                    unit: "g",
                    color: .orange
                )
                
                MacroCard(
                    title: "Fat",
                    value: 45,
                    goal: 65,
                    unit: "g",
                    color: .green
                )
            }
        }
    }
}

struct FunctionalProgressView: View {
    @EnvironmentObject private var dataManager: DataManager
    @Environment(\.theme) private var theme
    @State private var selectedTimeframe = "Week"
    
    let timeframes = ["Week", "Month", "Year"]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: theme.spacing.lg) {
                    // Timeframe selector
                    Picker("Timeframe", selection: $selectedTimeframe) {
                        ForEach(timeframes, id: \.self) { timeframe in
                            Text(timeframe).tag(timeframe)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    
                    // Weight Progress
                    weightProgressSection
                    
                    // Goals Progress
                    goalsProgressSection
                    
                    // Activity Summary
                    activitySummarySection
                    
                    // Achievements
                    achievementsSection
                }
                .padding(.vertical)
            }
            .navigationTitle("Progress")
        }
    }
    
    private var weightProgressSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            Text("Weight Progress")
                .font(theme.typography.titleMedium)
                .foregroundColor(theme.textPrimary)
                .padding(.horizontal)
            
            // Placeholder chart
            RoundedRectangle(cornerRadius: theme.cornerRadius.medium)
                .fill(theme.surfaceColor)
                .frame(height: 200)
                .overlay(
                    VStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.largeTitle)
                            .foregroundColor(theme.primaryColor)
                        Text("Weight trend chart")
                            .font(theme.typography.bodySmall)
                            .foregroundColor(theme.textSecondary)
                    }
                )
                .padding(.horizontal)
            
            HStack(spacing: theme.spacing.lg) {
                VStack(alignment: .leading) {
                    Text("Current")
                        .font(theme.typography.bodySmall)
                        .foregroundColor(theme.textSecondary)
                    Text("\(String(format: "%.1f", dataManager.currentWeight)) lbs")
                        .font(theme.typography.titleMedium)
                        .foregroundColor(theme.textPrimary)
                }
                
                VStack(alignment: .leading) {
                    Text("Goal")
                        .font(theme.typography.bodySmall)
                        .foregroundColor(theme.textSecondary)
                    Text("180 lbs")
                        .font(theme.typography.titleMedium)
                        .foregroundColor(theme.primaryColor)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Progress")
                        .font(theme.typography.bodySmall)
                        .foregroundColor(theme.textSecondary)
                    Text("-5 lbs")
                        .font(theme.typography.titleMedium)
                        .foregroundColor(.green)
                }
            }
            .padding()
            .background(theme.surfaceColor)
            .cornerRadius(theme.cornerRadius.medium)
            .padding(.horizontal)
        }
    }
    
    private var goalsProgressSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            HStack {
                Text("Active Goals")
                    .font(theme.typography.titleMedium)
                    .foregroundColor(theme.textPrimary)
                
                Spacer()
                
                Text("\(dataManager.activeGoals.count)")
                    .font(theme.typography.bodyMedium)
                    .foregroundColor(theme.primaryColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(theme.primaryColor.opacity(0.2))
                    .cornerRadius(theme.cornerRadius.small)
            }
            .padding(.horizontal)
            
            if dataManager.activeGoals.isEmpty {
                VStack(spacing: theme.spacing.md) {
                    Image(systemName: "target")
                        .font(.largeTitle)
                        .foregroundColor(theme.textTertiary)
                    
                    Text("No active goals")
                        .font(theme.typography.bodyMedium)
                        .foregroundColor(theme.textSecondary)
                    
                    Button("Set a Goal") {
                        // Show goal setting
                    }
                    .font(theme.typography.bodySmall)
                    .foregroundColor(theme.primaryColor)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(theme.surfaceColor)
                .cornerRadius(theme.cornerRadius.medium)
                .padding(.horizontal)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: theme.spacing.md) {
                        ForEach(dataManager.activeGoals) { goal in
                            GoalProgressCard(goal: goal)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
    private var activitySummarySection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            Text("Activity Summary")
                .font(theme.typography.titleMedium)
                .foregroundColor(theme.textPrimary)
                .padding(.horizontal)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: theme.spacing.md) {
                ActivityStatCard(
                    title: "Workouts",
                    value: "\(dataManager.weeklyWorkouts)",
                    subtitle: "This week",
                    icon: "figure.run",
                    color: .green
                )
                
                ActivityStatCard(
                    title: "Calories Burned",
                    value: "2,450",
                    subtitle: "This week",
                    icon: "flame.fill",
                    color: .orange
                )
                
                ActivityStatCard(
                    title: "Active Days",
                    value: "5",
                    subtitle: "This week",
                    icon: "calendar",
                    color: .blue
                )
                
                ActivityStatCard(
                    title: "Avg. Duration",
                    value: "45",
                    subtitle: "Minutes",
                    icon: "timer",
                    color: .purple
                )
            }
            .padding(.horizontal)
        }
    }
    
    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            HStack {
                Text("Achievements")
                    .font(theme.typography.titleMedium)
                    .foregroundColor(theme.textPrimary)
                
                Spacer()
                
                Button("View All") {
                    // Show all achievements
                }
                .font(theme.typography.bodySmall)
                .foregroundColor(theme.primaryColor)
            }
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: theme.spacing.md) {
                    AchievementBadge(
                        icon: "flame.fill",
                        title: "7 Day Streak",
                        color: .orange,
                        isUnlocked: true
                    )
                    
                    AchievementBadge(
                        icon: "figure.run",
                        title: "10 Workouts",
                        color: .green,
                        isUnlocked: true
                    )
                    
                    AchievementBadge(
                        icon: "drop.fill",
                        title: "Hydration Hero",
                        color: .blue,
                        isUnlocked: false
                    )
                    
                    AchievementBadge(
                        icon: "target",
                        title: "Goal Crusher",
                        color: .purple,
                        isUnlocked: false
                    )
                }
                .padding(.horizontal)
            }
        }
    }
}

struct FunctionalProfileView: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    @EnvironmentObject private var dataManager: DataManager
    @Environment(\.theme) private var theme
    @State private var showingSettings = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: theme.spacing.lg) {
                    // Profile Header
                    profileHeaderSection
                    
                    // Stats Overview
                    statsOverviewSection
                    
                    // Menu Options
                    menuOptionsSection
                    
                    // Sign Out Button
                    signOutButton
                }
                .padding()
            }
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(theme.primaryColor)
                    }
                }
            }
        }
    }
    
    private var profileHeaderSection: some View {
        VStack(spacing: theme.spacing.md) {
            Circle()
                .fill(theme.primaryColor.gradient)
                .frame(width: 100, height: 100)
                .overlay(
                    Text("JD")
                        .font(theme.typography.headlineLarge)
                        .foregroundColor(.white)
                )
            
            Text("John Doe")
                .font(theme.typography.titleLarge)
                .foregroundColor(theme.textPrimary)
            
            Text("Member since Nov 2024")
                .font(theme.typography.bodySmall)
                .foregroundColor(theme.textSecondary)
            
            HStack(spacing: theme.spacing.xl) {
                VStack {
                    Text("\(dataManager.workouts.count)")
                        .font(theme.typography.titleMedium)
                        .foregroundColor(theme.textPrimary)
                    Text("Workouts")
                        .font(theme.typography.bodySmall)
                        .foregroundColor(theme.textSecondary)
                }
                
                VStack {
                    Text("7")
                        .font(theme.typography.titleMedium)
                        .foregroundColor(theme.textPrimary)
                    Text("Streak")
                        .font(theme.typography.bodySmall)
                        .foregroundColor(theme.textSecondary)
                }
                
                VStack {
                    Text("\(dataManager.goals.count)")
                        .font(theme.typography.titleMedium)
                        .foregroundColor(theme.textPrimary)
                    Text("Goals")
                        .font(theme.typography.bodySmall)
                        .foregroundColor(theme.textSecondary)
                }
            }
        }
        .padding()
        .background(theme.surfaceColor)
        .cornerRadius(theme.cornerRadius.medium)
    }
    
    private var statsOverviewSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            Text("Personal Records")
                .font(theme.typography.titleMedium)
                .foregroundColor(theme.textPrimary)
            
            VStack(spacing: theme.spacing.sm) {
                PersonalRecordRow(
                    exercise: "Bench Press",
                    record: "225 lbs",
                    date: "2 weeks ago"
                )
                
                PersonalRecordRow(
                    exercise: "5K Run",
                    record: "24:30",
                    date: "Last month"
                )
                
                PersonalRecordRow(
                    exercise: "Deadlift",
                    record: "315 lbs",
                    date: "3 days ago"
                )
            }
            .padding()
            .background(theme.surfaceColor)
            .cornerRadius(theme.cornerRadius.medium)
        }
    }
    
    private var menuOptionsSection: some View {
        VStack(spacing: theme.spacing.sm) {
            ProfileMenuRow(
                icon: "person.fill",
                title: "Edit Profile",
                color: theme.primaryColor
            ) {
                // Edit profile action
            }
            
            ProfileMenuRow(
                icon: "bell.fill",
                title: "Notifications",
                color: .orange
            ) {
                // Notifications action
            }
            
            ProfileMenuRow(
                icon: "chart.bar.fill",
                title: "Export Data",
                color: .green
            ) {
                // Export data action
            }
            
            ProfileMenuRow(
                icon: "questionmark.circle.fill",
                title: "Help & Support",
                color: .blue
            ) {
                // Help action
            }
            
            ProfileMenuRow(
                icon: "shield.fill",
                title: "Privacy",
                color: .purple
            ) {
                // Privacy action
            }
        }
    }
    
    private var signOutButton: some View {
        Button {
            authManager.signOut()
        } label: {
            Text("Sign Out")
                .font(theme.typography.bodyMedium)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red)
                .cornerRadius(theme.cornerRadius.medium)
        }
    }
}

// MARK: - Supporting Components

struct WorkoutCard: View {
    let workout: DataManager.WorkoutData
    @Environment(\.theme) private var theme
    
    var body: some View {
        HStack {
            Circle()
                .fill(theme.primaryColor.gradient)
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: iconForCategory(workout.category))
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.name)
                    .font(theme.typography.bodyMedium)
                    .foregroundColor(theme.textPrimary)
                
                HStack {
                    Text(workout.category)
                        .font(theme.typography.bodySmall)
                        .foregroundColor(theme.textSecondary)
                    
                    Text("•")
                        .foregroundColor(theme.textTertiary)
                    
                    Text("\(workout.duration) min")
                        .font(theme.typography.bodySmall)
                        .foregroundColor(theme.textSecondary)
                    
                    Text("•")
                        .foregroundColor(theme.textTertiary)
                    
                    Text("\(workout.exercises.count) exercises")
                        .font(theme.typography.bodySmall)
                        .foregroundColor(theme.textSecondary)
                }
            }
            
            Spacer()
            
            if workout.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            } else {
                Image(systemName: "chevron.right")
                    .foregroundColor(theme.textTertiary)
            }
        }
        .padding()
        .background(theme.surfaceColor)
        .cornerRadius(theme.cornerRadius.medium)
    }
    
    private func iconForCategory(_ category: String) -> String {
        switch category {
        case "Cardio": return "heart.fill"
        case "Strength": return "figure.strengthtraining.traditional"
        case "HIIT": return "bolt.fill"
        case "Yoga": return "figure.yoga"
        default: return "figure.run"
        }
    }
}

struct MealCard: View {
    let mealType: String
    let foods: [DataManager.MealData]
    let onAdd: () -> Void
    @Environment(\.theme) private var theme
    
    private var totalCalories: Int {
        foods.reduce(0) { $0 + $1.calories }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            HStack {
                Text(mealType)
                    .font(theme.typography.bodyMedium)
                    .fontWeight(.medium)
                    .foregroundColor(theme.textPrimary)
                
                Spacer()
                
                if !foods.isEmpty {
                    Text("\(totalCalories) cal")
                        .font(theme.typography.bodySmall)
                        .foregroundColor(theme.textSecondary)
                }
                
                Button {
                    onAdd()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(theme.primaryColor)
                }
            }
            
            if foods.isEmpty {
                Text("No foods logged")
                    .font(theme.typography.bodySmall)
                    .foregroundColor(theme.textTertiary)
                    .padding(.vertical, 8)
            } else {
                ForEach(foods) { food in
                    HStack {
                        Text(food.name)
                            .font(theme.typography.bodySmall)
                            .foregroundColor(theme.textPrimary)
                        
                        Spacer()
                        
                        Text("\(food.calories) cal")
                            .font(theme.typography.bodySmall)
                            .foregroundColor(theme.textSecondary)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .padding()
        .background(theme.surfaceColor)
        .cornerRadius(theme.cornerRadius.medium)
    }
}

struct MacroCard: View {
    let title: String
    let value: Int
    let goal: Int
    let unit: String
    let color: Color
    @Environment(\.theme) private var theme
    
    private var progress: Double {
        Double(value) / Double(goal)
    }
    
    var body: some View {
        VStack(spacing: theme.spacing.sm) {
            Text(title)
                .font(theme.typography.bodySmall)
                .foregroundColor(theme.textSecondary)
            
            Text("\(value)\(unit)")
                .font(theme.typography.titleMedium)
                .foregroundColor(theme.textPrimary)
            
            ProgressView(value: progress)
                .tint(color)
            
            Text("of \(goal)\(unit)")
                .font(theme.typography.bodySmall)
                .foregroundColor(theme.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(theme.surfaceColor)
        .cornerRadius(theme.cornerRadius.medium)
    }
}

struct GoalProgressCard: View {
    let goal: DataManager.GoalData
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            HStack {
                Image(systemName: iconForGoalType(goal.type))
                    .foregroundColor(theme.primaryColor)
                
                Text(goal.type)
                    .font(theme.typography.bodyMedium)
                    .fontWeight(.medium)
                    .foregroundColor(theme.textPrimary)
            }
            
            Text("Target: \(String(format: "%.0f", goal.targetValue))")
                .font(theme.typography.bodySmall)
                .foregroundColor(theme.textSecondary)
            
            ProgressView(value: goal.progress / goal.targetValue)
                .tint(theme.primaryColor)
            
            Text("\(daysRemaining(until: goal.targetDate)) days left")
                .font(theme.typography.bodySmall)
                .foregroundColor(theme.textTertiary)
        }
        .frame(width: 160)
        .padding()
        .background(theme.surfaceColor)
        .cornerRadius(theme.cornerRadius.medium)
    }
    
    private func iconForGoalType(_ type: String) -> String {
        switch type {
        case "Weight Loss": return "scalemass"
        case "Muscle Gain": return "figure.strengthtraining.traditional"
        case "Running Distance": return "figure.run"
        default: return "target"
        }
    }
    
    private func daysRemaining(until date: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: date)
        return max(0, components.day ?? 0)
    }
}

struct ActivityStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(spacing: theme.spacing.sm) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                
                Spacer()
            }
            
            Text(value)
                .font(theme.typography.titleLarge)
                .foregroundColor(theme.textPrimary)
            
            Text(title)
                .font(theme.typography.bodySmall)
                .foregroundColor(theme.textSecondary)
            
            Text(subtitle)
                .font(theme.typography.bodySmall)
                .foregroundColor(theme.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(theme.surfaceColor)
        .cornerRadius(theme.cornerRadius.medium)
    }
}

struct AchievementBadge: View {
    let icon: String
    let title: String
    let color: Color
    let isUnlocked: Bool
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(spacing: theme.spacing.sm) {
            Circle()
                .fill(isUnlocked ? color.gradient : Color.gray.gradient)
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(.white)
                )
            
            Text(title)
                .font(theme.typography.bodySmall)
                .foregroundColor(isUnlocked ? theme.textPrimary : theme.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(width: 80)
    }
}

struct PersonalRecordRow: View {
    let exercise: String
    let record: String
    let date: String
    @Environment(\.theme) private var theme
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(exercise)
                    .font(theme.typography.bodyMedium)
                    .foregroundColor(theme.textPrimary)
                
                Text(date)
                    .font(theme.typography.bodySmall)
                    .foregroundColor(theme.textTertiary)
            }
            
            Spacer()
            
            Text(record)
                .font(theme.typography.titleMedium)
                .foregroundColor(theme.primaryColor)
        }
        .padding(.vertical, 4)
    }
}

struct ProfileMenuRow: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    @Environment(\.theme) private var theme
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .frame(width: 30)
                
                Text(title)
                    .font(theme.typography.bodyMedium)
                    .foregroundColor(theme.textPrimary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(theme.textTertiary)
                    .font(.caption)
            }
            .padding()
            .background(theme.surfaceColor)
            .cornerRadius(theme.cornerRadius.medium)
        }
    }
}

// MARK: - Reusable Components

struct StatCard: View {
    let title: String
    let value: String
    let unit: String
    let trend: Trend
    let trendValue: String
    let icon: String
    let color: Color
    @Environment(\.theme) private var theme
    
    enum Trend {
        case up, down, neutral
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                
                Spacer()
                
                if trend != .neutral {
                    Image(systemName: trend == .up ? "arrow.up.right" : "arrow.down.right")
                        .foregroundColor(trend == .up ? .green : .red)
                        .font(.caption)
                }
            }
            
            Text(value)
                .font(theme.typography.titleLarge)
                .foregroundColor(theme.textPrimary)
            
            Text(unit)
                .font(theme.typography.bodySmall)
                .foregroundColor(theme.textSecondary)
            
            Text(trendValue)
                .font(theme.typography.bodySmall)
                .foregroundColor(theme.textTertiary)
        }
        .padding()
        .background(theme.surfaceColor)
        .cornerRadius(theme.cornerRadius.medium)
    }
}

struct ProgressRow: View {
    let title: String
    let current: Int
    let goal: Int
    let unit: String
    let color: Color
    @Environment(\.theme) private var theme
    
    private var progress: Double {
        min(Double(current) / Double(goal), 1.0)
    }
    
    private var percentage: Int {
        Int(progress * 100)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(title)
                    .font(theme.typography.bodyMedium)
                    .foregroundColor(theme.textPrimary)
                
                Spacer()
                
                Text("\(current) / \(goal) \(unit)")
                    .font(theme.typography.bodySmall)
                    .foregroundColor(theme.textSecondary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color.opacity(0.2))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geometry.size.width * progress, height: 8)
                }
            }
            .frame(height: 8)
        }
    }
}

struct QuickActionCard: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    @Environment(\.theme) private var theme
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: theme.spacing.sm) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(theme.typography.bodySmall)
                    .foregroundColor(theme.textPrimary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(theme.surfaceColor)
            .cornerRadius(theme.cornerRadius.medium)
        }
    }
}

struct CircularProgressView: View {
    let progress: Double
    let lineWidth: CGFloat
    let color: Color
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
            
            Text("\(Int(progress * 100))%")
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}