import SwiftUI

struct FastMainTabView: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    @EnvironmentObject private var dataManager: SimpleDataManager
    @Environment(\.theme) private var theme
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            FastDashboardView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Dashboard")
                }
                .tag(0)
            
            FastWorkoutsView()
                .tabItem {
                    Image(systemName: "figure.strengthtraining.traditional")
                    Text("Workouts")
                }
                .tag(1)
            
            FastNutritionView()
                .tabItem {
                    Image(systemName: "leaf.fill")
                    Text("Nutrition")
                }
                .tag(2)
            
            ProgressTrackingView()
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("Progress")
                }
                .tag(3)
            
            FastProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
                .tag(4)
        }
        .tint(theme.primaryColor)
    }
}

struct FastDashboardView: View {
    @EnvironmentObject private var dataManager: SimpleDataManager
    @Environment(\.theme) private var theme
    @State private var showingWeightEntry = false
    @State private var showingQuickWorkout = false
    @State private var showingStrongLifts = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: theme.spacing.lg) {
                    // Quick Actions - WORKING BUTTONS
                    VStack(alignment: .leading, spacing: theme.spacing.md) {
                        Text("Quick Actions")
                            .font(theme.typography.titleMedium)
                            .foregroundColor(theme.textPrimary)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: theme.spacing.md) {
                            QuickActionButton(
                                icon: "figure.strengthtraining.traditional",
                                title: "StrongLifts 5×5",
                                color: .red,
                                action: { showingStrongLifts = true }
                            )
                            
                            QuickActionButton(
                                icon: "timer",
                                title: "Quick Workout",
                                color: theme.primaryColor,
                                action: { showingQuickWorkout = true }
                            )
                            
                            QuickActionButton(
                                icon: "scalemass",
                                title: "Log Weight",
                                color: .orange,
                                action: { showingWeightEntry = true }
                            )
                            
                            QuickActionButton(
                                icon: "drop.fill",
                                title: "Log Water",
                                color: .blue,
                                action: {
                                    dataManager.updateWaterIntake(dataManager.waterIntake + 1)
                                }
                            )
                        }
                    }
                    
                    // Today's Stats
                    VStack(alignment: .leading, spacing: theme.spacing.md) {
                        Text("Today's Progress")
                            .font(theme.typography.titleMedium)
                            .foregroundColor(theme.textPrimary)
                        
                        HStack(spacing: theme.spacing.md) {
                            StatBox(
                                value: "\(dataManager.waterIntake)",
                                label: "Water (cups)",
                                color: .blue
                            )
                            
                            StatBox(
                                value: "\(dataManager.todaysCalories)",
                                label: "Calories",
                                color: .orange
                            )
                            
                            StatBox(
                                value: String(format: "%.1f", dataManager.currentWeight),
                                label: "Weight (lbs)",
                                color: .green
                            )
                        }
                    }
                    
                    // Recent Workouts
                    VStack(alignment: .leading, spacing: theme.spacing.md) {
                        HStack {
                            Text("Recent Workouts")
                                .font(theme.typography.titleMedium)
                                .foregroundColor(theme.textPrimary)
                            
                            Spacer()
                            
                            Text("\(dataManager.workouts.count)")
                                .font(theme.typography.bodySmall)
                                .foregroundColor(theme.textSecondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(theme.primaryColor.opacity(0.2))
                                .cornerRadius(theme.cornerRadius.small)
                        }
                        
                        if dataManager.workouts.isEmpty {
                            EmptyStateCard(
                                icon: "figure.run",
                                message: "No workouts yet",
                                action: "Start StrongLifts 5×5",
                                onAction: { showingStrongLifts = true }
                            )
                        } else {
                            ForEach(dataManager.workouts.prefix(3)) { workout in
                                SimpleWorkoutRow(workout: workout)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("FitnessCoach")
            .sheet(isPresented: $showingWeightEntry) {
                WeightEntryForm(isPresented: $showingWeightEntry) { weight in
                    dataManager.updateWeight(weight)
                }
            }
            .sheet(isPresented: $showingQuickWorkout) {
                QuickWorkoutSheet(isPresented: $showingQuickWorkout)
            }
            .sheet(isPresented: $showingStrongLifts) {
                StrongLifts5x5View()
            }
        }
    }
}

struct FastWorkoutsView: View {
    @EnvironmentObject private var dataManager: SimpleDataManager
    @Environment(\.theme) private var theme
    @State private var showingStrongLifts = false
    @State private var showingWorkoutBuilder = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: theme.spacing.lg) {
                    // Featured Programs
                    VStack(alignment: .leading, spacing: theme.spacing.md) {
                        Text("Featured Programs")
                            .font(theme.typography.titleMedium)
                            .foregroundColor(theme.textPrimary)
                        
                        ProgramCard(
                            title: "StrongLifts 5×5",
                            description: "Build strength with compound movements",
                            icon: "figure.strengthtraining.traditional",
                            color: .red,
                            action: { showingStrongLifts = true }
                        )
                        
                        ProgramCard(
                            title: "Custom Workout",
                            description: "Create your own workout routine",
                            icon: "plus.circle.fill",
                            color: theme.primaryColor,
                            action: { showingWorkoutBuilder = true }
                        )
                    }
                    
                    // Workout History
                    VStack(alignment: .leading, spacing: theme.spacing.md) {
                        Text("Workout History")
                            .font(theme.typography.titleMedium)
                            .foregroundColor(theme.textPrimary)
                        
                        if dataManager.workouts.isEmpty {
                            EmptyStateCard(
                                icon: "figure.run",
                                message: "No workouts completed yet",
                                action: "Start Your First Workout",
                                onAction: { showingStrongLifts = true }
                            )
                        } else {
                            ForEach(dataManager.workouts) { workout in
                                SimpleWorkoutRow(workout: workout)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Workouts")
            .sheet(isPresented: $showingStrongLifts) {
                StrongLifts5x5View()
            }
            .sheet(isPresented: $showingWorkoutBuilder) {
                WorkoutBuilderForm(isPresented: $showingWorkoutBuilder)
            }
        }
    }
}

struct FastNutritionView: View {
    @EnvironmentObject private var dataManager: SimpleDataManager
    @Environment(\.theme) private var theme
    @State private var showingFoodEntry = false
    @State private var selectedMealType = "Breakfast"
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: theme.spacing.lg) {
                    // Water Intake
                    VStack(alignment: .leading, spacing: theme.spacing.md) {
                        Text("Water Intake")
                            .font(theme.typography.titleMedium)
                            .foregroundColor(theme.textPrimary)
                        
                        HStack(spacing: theme.spacing.sm) {
                            ForEach(0..<8, id: \.self) { index in
                                Button {
                                    dataManager.updateWaterIntake(index < dataManager.waterIntake ? index : index + 1)
                                } label: {
                                    Image(systemName: index < dataManager.waterIntake ? "drop.fill" : "drop")
                                        .font(.title)
                                        .foregroundColor(index < dataManager.waterIntake ? .blue : theme.textTertiary)
                                }
                            }
                        }
                        .padding()
                        .background(theme.surfaceColor)
                        .cornerRadius(theme.cornerRadius.medium)
                    }
                    
                    // Meal Tracking
                    VStack(alignment: .leading, spacing: theme.spacing.md) {
                        Text("Today's Meals")
                            .font(theme.typography.titleMedium)
                            .foregroundColor(theme.textPrimary)
                        
                        ForEach(["Breakfast", "Lunch", "Dinner", "Snacks"], id: \.self) { meal in
                            MealSection(
                                mealType: meal,
                                meals: dataManager.todaysMeals.filter { $0.mealType == meal },
                                onAdd: {
                                    selectedMealType = meal
                                    showingFoodEntry = true
                                }
                            )
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Nutrition")
            .sheet(isPresented: $showingFoodEntry) {
                FoodEntryForm(
                    isPresented: $showingFoodEntry,
                    mealType: selectedMealType
                ) { food, calories in
                    dataManager.addMeal(name: food, calories: calories, mealType: selectedMealType)
                }
            }
        }
    }
}

struct FastProfileView: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    @EnvironmentObject private var dataManager: SimpleDataManager
    @Environment(\.theme) private var theme
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: theme.spacing.lg) {
                    // Profile Header
                    VStack(spacing: theme.spacing.md) {
                        Circle()
                            .fill(theme.primaryColor.gradient)
                            .frame(width: 100, height: 100)
                            .overlay(
                                Text(authManager.currentUser?.initials ?? "U")
                                    .font(theme.typography.headlineLarge)
                                    .foregroundColor(.white)
                            )
                        
                        Text(authManager.currentUser?.displayName ?? "User")
                            .font(theme.typography.titleLarge)
                            .foregroundColor(theme.textPrimary)
                        
                        Text(authManager.currentUser?.email ?? "iCloud User")
                            .font(theme.typography.bodySmall)
                            .foregroundColor(theme.textSecondary)
                    }
                    .padding()
                    .background(theme.surfaceColor)
                    .cornerRadius(theme.cornerRadius.medium)
                    
                    // Stats
                    VStack(spacing: theme.spacing.md) {
                        ProfileStatRow(label: "Total Workouts", value: "\(dataManager.workouts.count)")
                        ProfileStatRow(label: "Current Weight", value: "\(String(format: "%.1f", dataManager.currentWeight)) lbs")
                        ProfileStatRow(label: "Active Goals", value: "\(dataManager.goals.count)")
                    }
                    .padding()
                    .background(theme.surfaceColor)
                    .cornerRadius(theme.cornerRadius.medium)
                    
                    // Sign Out
                    Button {
                        authManager.signOut()
                    } label: {
                        Text("Sign Out")
                            .font(theme.typography.bodyMedium)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(theme.cornerRadius.medium)
                    }
                }
                .padding()
            }
            .navigationTitle("Profile")
        }
    }
}

// MARK: - Supporting Views

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    @Environment(\.theme) private var theme
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(theme.typography.bodySmall)
                    .foregroundColor(theme.textPrimary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(theme.surfaceColor)
            .cornerRadius(theme.cornerRadius.medium)
        }
    }
}

struct StatBox: View {
    let value: String
    let label: String
    let color: Color
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(theme.typography.titleLarge)
                .foregroundColor(color)
            
            Text(label)
                .font(theme.typography.bodySmall)
                .foregroundColor(theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(theme.surfaceColor)
        .cornerRadius(theme.cornerRadius.medium)
    }
}

struct SimpleWorkoutRow: View {
    let workout: SimpleDataManager.WorkoutData
    @Environment(\.theme) private var theme
    
    var body: some View {
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
        }
        .padding()
        .background(theme.surfaceColor)
        .cornerRadius(theme.cornerRadius.medium)
    }
}

struct EmptyStateCard: View {
    let icon: String
    let message: String
    let action: String
    let onAction: () -> Void
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(spacing: theme.spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(theme.textTertiary)
            
            Text(message)
                .font(theme.typography.bodyMedium)
                .foregroundColor(theme.textSecondary)
            
            Button(action: onAction) {
                Text(action)
                    .font(theme.typography.bodySmall)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(theme.primaryColor)
                    .cornerRadius(theme.cornerRadius.small)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(theme.spacing.xl)
        .background(theme.surfaceColor)
        .cornerRadius(theme.cornerRadius.medium)
    }
}

struct ProgramCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let action: () -> Void
    @Environment(\.theme) private var theme
    
    var body: some View {
        Button(action: action) {
            HStack {
                Circle()
                    .fill(color.gradient)
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: icon)
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(theme.typography.bodyMedium)
                        .fontWeight(.medium)
                        .foregroundColor(theme.textPrimary)
                    
                    Text(description)
                        .font(theme.typography.bodySmall)
                        .foregroundColor(theme.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(theme.textTertiary)
            }
            .padding()
            .background(theme.surfaceColor)
            .cornerRadius(theme.cornerRadius.medium)
        }
    }
}

struct MealSection: View {
    let mealType: String
    let meals: [SimpleDataManager.MealData]
    let onAdd: () -> Void
    @Environment(\.theme) private var theme
    
    private var totalCalories: Int {
        meals.reduce(0) { $0 + $1.calories }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            HStack {
                Text(mealType)
                    .font(theme.typography.bodyMedium)
                    .fontWeight(.medium)
                    .foregroundColor(theme.textPrimary)
                
                Spacer()
                
                if !meals.isEmpty {
                    Text("\(totalCalories) cal")
                        .font(theme.typography.bodySmall)
                        .foregroundColor(theme.textSecondary)
                }
                
                Button(action: onAdd) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(theme.primaryColor)
                }
            }
            
            if !meals.isEmpty {
                ForEach(meals) { meal in
                    HStack {
                        Text(meal.name)
                            .font(theme.typography.bodySmall)
                            .foregroundColor(theme.textPrimary)
                        
                        Spacer()
                        
                        Text("\(meal.calories) cal")
                            .font(theme.typography.bodySmall)
                            .foregroundColor(theme.textSecondary)
                    }
                }
            }
        }
        .padding()
        .background(theme.surfaceColor)
        .cornerRadius(theme.cornerRadius.medium)
    }
}

struct ProfileStatRow: View {
    let label: String
    let value: String
    @Environment(\.theme) private var theme
    
    var body: some View {
        HStack {
            Text(label)
                .font(theme.typography.bodyMedium)
                .foregroundColor(theme.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(theme.typography.bodyMedium)
                .fontWeight(.medium)
                .foregroundColor(theme.textPrimary)
        }
    }
}

// Extension for AuthUser
extension AuthUser {
    var initials: String {
        let first = firstName.first.map(String.init) ?? ""
        let last = lastName.first.map(String.init) ?? ""
        let result = "\(first)\(last)".uppercased()
        return result.isEmpty ? "U" : result
    }
    
    var displayName: String {
        if !firstName.isEmpty {
            if !lastName.isEmpty {
                return "\(firstName) \(lastName)"
            }
            return firstName
        }
        return email.isEmpty ? "User" : email
    }
}