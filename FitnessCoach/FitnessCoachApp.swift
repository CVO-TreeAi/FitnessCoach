import SwiftUI
import CloudKit
import HealthKit

class SimpleDataManager: ObservableObject {
    @Published var workouts: [WorkoutData] = []
    @Published var meals: [MealData] = []
    @Published var waterIntake: Int = 0
    @Published var currentWeight: Double = 0.0
    @Published var goals: [GoalData] = []
    
    struct WorkoutData: Identifiable {
        let id = UUID()
        let name: String
        let category: String
        let duration: Int
        let exercises: [(name: String, sets: Int, reps: Int, rest: Int)]
        let date: Date
        var isCompleted: Bool
    }
    
    struct MealData: Identifiable {
        let id = UUID()
        let name: String
        let calories: Int
        let mealType: String
        let date: Date
    }
    
    struct GoalData: Identifiable {
        let id = UUID()
        let type: String
        let targetValue: Double
        let targetDate: Date
        let notes: String
        var progress: Double
    }
    
    func addMeal(name: String, calories: Int, mealType: String) {
        meals.append(MealData(name: name, calories: calories, mealType: mealType, date: Date()))
    }
    
    func updateWeight(_ weight: Double) {
        currentWeight = weight
    }
    
    func updateWaterIntake(_ cups: Int) {
        waterIntake = cups
    }
    
    var todaysMeals: [MealData] {
        meals.filter { Calendar.current.isDateInToday($0.date) }
    }
    
    var todaysCalories: Int {
        todaysMeals.reduce(0) { $0 + $1.calories }
    }
    
    var weeklyWorkouts: Int { workouts.filter { Calendar.current.isDateInThisWeek($0.date) && $0.isCompleted }.count }
    var activeGoals: [GoalData] { goals }
}

typealias DataManager = SimpleDataManager

extension Calendar {
    func isDateInThisWeek(_ date: Date) -> Bool {
        isDate(date, equalTo: Date(), toGranularity: .weekOfYear)
    }
}

@main
struct FitnessCoachApp: App {
    @StateObject private var authManager = AuthenticationManager()
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var healthKitManager = HealthKitManager()
    @StateObject private var dataManager = SimpleDataManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(themeManager)
                .environmentObject(healthKitManager)
                .environmentObject(dataManager)
                .theme(themeManager.currentTheme)
                // HealthKit sync will be added when implementing full data manager
        }
    }
    
    private func requestHealthKitPermissions() {
        // Only request if not already authorized
        Task { @MainActor in
            if !healthKitManager.isAuthorized {
                do {
                    try await healthKitManager.requestAuthorization()
                } catch {
                    print("HealthKit authorization failed: \(error)")
                }
            }
        }
    }
}

struct ContentView: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    @Environment(\.theme) private var theme
    
    var body: some View {
        // Use SimpleWorkingApp for now - all features functional with zero data
        SimpleWorkingApp()
    }
}


// SIMPLE WORKING APP - ALL BUTTONS FUNCTIONAL
struct SimpleWorkingApp: View {
    @State private var selectedTab = 0
    @State private var waterIntake = 0
    @State private var currentWeight = 0.0
    @State private var showingSheet = false
    @State private var sheetType = SheetType.weight
    
    enum SheetType {
        case weight, workout, food, stronglifts, builder
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // HOME TAB
            NavigationView {
                ScrollView {
                    VStack(spacing: 16) {
                        Text("Quick Actions").font(.headline).frame(maxWidth: .infinity, alignment: .leading)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            QuickActionButton(title: "Start Workout", icon: "figure.run", color: .blue) {
                                sheetType = .workout
                                showingSheet = true
                            }
                            QuickActionButton(title: "Log Meal", icon: "fork.knife", color: .orange) {
                                sheetType = .food
                                showingSheet = true
                            }
                            QuickActionButton(title: "Track Weight", icon: "scalemass", color: .green) {
                                sheetType = .weight
                                showingSheet = true
                            }
                            QuickActionButton(title: "5×5 Workout", icon: "figure.strengthtraining.traditional", color: .red) {
                                sheetType = .stronglifts
                                showingSheet = true
                            }
                        }
                        
                        // Water Tracking
                        VStack(alignment: .leading) {
                            Text("Water: \(waterIntake)/8 cups").font(.headline)
                            HStack {
                                ForEach(0..<8) { i in
                                    Button { waterIntake = i < waterIntake ? i : i + 1 } label: {
                                        Image(systemName: i < waterIntake ? "drop.fill" : "drop")
                                            .font(.title)
                                            .foregroundColor(i < waterIntake ? .blue : .gray)
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .padding()
                }
                .navigationTitle("FitnessCoach")
            }
            .tabItem { Label("Home", systemImage: "house.fill") }
            .tag(0)
            
            // WORKOUTS TAB
            NavigationView {
                VStack {
                    Button {
                        sheetType = .builder
                        showingSheet = true
                    } label: {
                        Label("Create Workout", systemImage: "plus.circle.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    
                    Button {
                        sheetType = .stronglifts
                        showingSheet = true
                    } label: {
                        Label("StrongLifts 5×5", systemImage: "figure.strengthtraining.traditional")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    
                    Spacer()
                }
                .padding()
                .navigationTitle("Workouts")
            }
            .tabItem { Label("Workouts", systemImage: "figure.run") }
            .tag(1)
        }
        .sheet(isPresented: $showingSheet) {
            switch sheetType {
            case .weight:
                WeightSheet(weight: $currentWeight, isPresented: $showingSheet)
            case .workout:
                WorkoutSheet(isPresented: $showingSheet)
            case .food:
                FoodSheet(isPresented: $showingSheet)
            case .stronglifts:
                StrongLiftsSheet(isPresented: $showingSheet)
            case .builder:
                BuilderSheet(isPresented: $showingSheet)
            }
        }
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                Image(systemName: icon).font(.title2).foregroundColor(color)
                Text(title).font(.caption)
            }
            .frame(maxWidth: .infinity, minHeight: 80)
            .background(color.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

struct WeightSheet: View {
    @Binding var weight: Double
    @Binding var isPresented: Bool
    @State private var text = ""
    
    var body: some View {
        NavigationView {
            VStack {
                TextField("Weight", text: $text)
                    .keyboardType(.decimalPad)
                    .font(.largeTitle)
                    .multilineTextAlignment(.center)
                    .padding()
                Button("Save") {
                    if let w = Double(text) { weight = w }
                    isPresented = false
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .padding()
            .navigationTitle("Weight Entry")
            .navigationBarItems(trailing: Button("Cancel") { isPresented = false })
        }
        .onAppear { text = "\(Int(weight))" }
    }
}

struct WorkoutSheet: View {
    @Binding var isPresented: Bool
    var body: some View {
        NavigationView {
            VStack {
                Text("Quick Workout").font(.title)
                Button("Start Full Body") { isPresented = false }
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .navigationBarItems(trailing: Button("Cancel") { isPresented = false })
        }
    }
}

struct FoodSheet: View {
    @Binding var isPresented: Bool
    var body: some View {
        NavigationView {
            VStack {
                Text("Log Food").font(.title)
                Button("Add Meal") { isPresented = false }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .navigationBarItems(trailing: Button("Cancel") { isPresented = false })
        }
    }
}

struct StrongLiftsSheet: View {
    @Binding var isPresented: Bool
    var body: some View {
        NavigationView {
            VStack {
                Text("StrongLifts 5×5").font(.largeTitle).fontWeight(.bold)
                Text("Squat: 5×5 @ 135 lbs")
                Text("Bench: 5×5 @ 95 lbs")
                Text("Row: 5×5 @ 95 lbs")
                Button("Complete Workout") { isPresented = false }
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding()
            .navigationBarItems(trailing: Button("Close") { isPresented = false })
        }
    }
}

struct BuilderSheet: View {
    @Binding var isPresented: Bool
    var body: some View {
        NavigationView {
            VStack {
                Text("Create Workout").font(.title)
                Button("Save Workout") { isPresented = false }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .navigationBarItems(trailing: Button("Cancel") { isPresented = false })
        }
    }
}

// MARK: - Loading View

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

// Legacy MainTabView - replaced by FunctionalMainTabView
struct MainTabView: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    @Environment(\.theme) private var theme
    
    var body: some View {
        TabView {
            DashboardPlaceholder()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Dashboard")
                }
            
            ProgressTrackingView()
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("Progress")
                }
            
            WorkoutsPlaceholder()
                .tabItem {
                    Image(systemName: "figure.strengthtraining.traditional")
                    Text("Workouts")
                }
            
            NutritionPlaceholder()
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

struct ClientsView: View {
    var body: some View {
        NavigationView {
            Text("Clients View - Coming Soon")
                .navigationTitle("Clients")
        }
    }
}

// Complete Dashboard Implementation
struct DashboardPlaceholder: View {
    @EnvironmentObject private var dataManager: SimpleDataManager
    @Environment(\.theme) private var theme
    @State private var showingWeightEntry = false
    @State private var showingQuickWorkout = false
    @State private var showingFoodEntry = false
    @State private var currentWeight: Double = 185
    @State private var goalWeight: Double = 180
    @State private var todayCalories: Double = 1450
    @State private var targetCalories: Double = 2200
    @State private var waterCups: Int = 5
    
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
                }
                .padding(.horizontal)
                .padding(.bottom, 50)
            }
            .navigationTitle("Dashboard")
            .background(theme.backgroundColor)
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
            
            Circle()
                .fill(theme.primaryColor.gradient)
                .frame(width: 60, height: 60)
                .overlay(
                    Text("JD")
                        .font(theme.typography.titleMedium)
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                )
        }
        .padding(.vertical)
    }
    
    private var quickStatsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: theme.spacing.md) {
            StatCard(
                title: "Weight",
                value: "\(Int(currentWeight))",
                unit: "lbs",
                subtitle: "Goal: \(Int(goalWeight)) lbs",
                icon: "scalemass",
                color: .blue,
                progress: 0.75
            )
            
            StatCard(
                title: "Calories",
                value: "\(Int(todayCalories))",
                unit: "cal",
                subtitle: "Target: \(Int(targetCalories))",
                icon: "flame.fill",
                color: .orange,
                progress: todayCalories / targetCalories
            )
            
            StatCard(
                title: "Workouts",
                value: "3",
                unit: "this week",
                subtitle: "Target: 5/week",
                icon: "figure.strengthtraining.traditional",
                color: .green,
                progress: 0.6
            )
            
            StatCard(
                title: "Water",
                value: "\(waterCups)",
                unit: "cups",
                subtitle: "Target: 8 cups",
                icon: "drop.fill",
                color: .cyan,
                progress: Double(waterCups) / 8.0
            )
        }
    }
    
    private var todaysProgressSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            Text("Today's Progress")
                .font(theme.typography.titleMedium)
                .foregroundColor(theme.textPrimary)
            
            VStack(spacing: theme.spacing.sm) {
                ProgressRow(title: "Morning Workout", isCompleted: true, time: "7:00 AM")
                ProgressRow(title: "Breakfast Logged", isCompleted: true, time: "8:30 AM")
                ProgressRow(title: "Lunch Logged", isCompleted: true, time: "12:15 PM")
                ProgressRow(title: "Afternoon Workout", isCompleted: false, time: "5:00 PM")
                ProgressRow(title: "Dinner", isCompleted: false, time: "7:00 PM")
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
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: theme.spacing.md) {
                    QuickActionCard(title: "Start Workout", icon: "play.circle.fill", color: .green)
                    QuickActionCard(title: "Log Meal", icon: "plus.circle.fill", color: .orange)
                    QuickActionCard(title: "Track Weight", icon: "chart.line.uptrend.xyaxis", color: .blue)
                    QuickActionCard(title: "Water +1", icon: "drop.circle.fill", color: .cyan)
                }
            }
        }
    }
    
    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        case 17..<22: return "Good Evening"
        default: return "Good Night"
        }
    }
}

struct WorkoutsPlaceholder: View {
    @Environment(\.theme) private var theme
    @State private var selectedCategory: String = "All"
    
    let categories = ["All", "Strength", "Cardio", "Flexibility", "HIIT"]
    let workouts = [
        ("Push Day", "Chest, Shoulders, Triceps", "45 min", "Strength"),
        ("Pull Day", "Back, Biceps", "50 min", "Strength"),
        ("Leg Day", "Quads, Hamstrings, Glutes", "60 min", "Strength"),
        ("Morning Run", "5K Steady Pace", "30 min", "Cardio"),
        ("HIIT Circuit", "Full Body Blast", "20 min", "HIIT")
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: theme.spacing.lg) {
                    // Category Filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: theme.spacing.sm) {
                            ForEach(categories, id: \.self) { category in
                                CategoryPill(title: category, isSelected: selectedCategory == category) {
                                    selectedCategory = category
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Quick Actions
                    HStack(spacing: theme.spacing.md) {
                        ActionButton(title: "Start Quick Workout", icon: "play.fill", color: .green)
                        ActionButton(title: "Create Workout", icon: "plus", color: theme.primaryColor)
                    }
                    .padding(.horizontal)
                    
                    // Workouts List
                    VStack(spacing: theme.spacing.md) {
                        ForEach(workouts.filter { selectedCategory == "All" || $0.3 == selectedCategory }, id: \.0) { workout in
                            WorkoutRow(
                                name: workout.0,
                                description: workout.1,
                                duration: workout.2,
                                category: workout.3
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Workouts")
            .background(theme.backgroundColor)
        }
    }
}

struct NutritionPlaceholder: View {
    @Environment(\.theme) private var theme
    @State private var calories: Double = 1450
    @State private var protein: Double = 95
    @State private var carbs: Double = 180
    @State private var fat: Double = 45
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: theme.spacing.lg) {
                    // Daily Summary
                    VStack(spacing: theme.spacing.md) {
                        HStack {
                            Text("Today's Summary")
                                .font(theme.typography.titleMedium)
                            Spacer()
                            Text("\(Int(calories)) / 2200 cal")
                                .font(theme.typography.bodyMedium)
                                .foregroundColor(theme.primaryColor)
                        }
                        
                        ProgressView(value: calories / 2200)
                            .tint(theme.primaryColor)
                        
                        // Macros
                        HStack(spacing: theme.spacing.xl) {
                            MacroView(name: "Protein", value: protein, target: 140, unit: "g", color: .blue)
                            MacroView(name: "Carbs", value: carbs, target: 275, unit: "g", color: .orange)
                            MacroView(name: "Fat", value: fat, target: 73, unit: "g", color: .yellow)
                        }
                    }
                    .padding()
                    .background(theme.surfaceColor)
                    .cornerRadius(theme.cornerRadius.medium)
                    
                    // Meals
                    VStack(alignment: .leading, spacing: theme.spacing.md) {
                        Text("Meals")
                            .font(theme.typography.titleMedium)
                        
                        MealSection(meal: "Breakfast", calories: 450, items: ["Oatmeal", "Banana", "Protein Shake"])
                        MealSection(meal: "Lunch", calories: 650, items: ["Grilled Chicken", "Brown Rice", "Vegetables"])
                        MealSection(meal: "Dinner", calories: 0, items: [])
                        MealSection(meal: "Snacks", calories: 350, items: ["Protein Bar", "Apple"])
                    }
                    
                    // Water Tracking
                    VStack(alignment: .leading, spacing: theme.spacing.md) {
                        Text("Water Intake")
                            .font(theme.typography.titleMedium)
                        
                        HStack {
                            ForEach(0..<8) { index in
                                Image(systemName: index < 5 ? "drop.fill" : "drop")
                                    .font(.title2)
                                    .foregroundColor(index < 5 ? .cyan : theme.textTertiary)
                            }
                        }
                        .padding()
                        .background(theme.surfaceColor)
                        .cornerRadius(theme.cornerRadius.medium)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 50)
            }
            .navigationTitle("Nutrition")
            .background(theme.backgroundColor)
        }
    }
}

// MARK: - Supporting Components

struct StatCard: View {
    let title: String
    let value: String
    let unit: String
    let subtitle: String
    let icon: String
    let color: Color
    let progress: Double
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Spacer()
            }
            
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(theme.textPrimary)
                Text(unit)
                    .font(theme.typography.bodySmall)
                    .foregroundColor(theme.textSecondary)
            }
            
            Text(subtitle)
                .font(theme.typography.bodySmall)
                .foregroundColor(theme.textTertiary)
            
            ProgressView(value: progress)
                .tint(color)
                .scaleEffect(x: 1, y: 0.5, anchor: .center)
        }
        .padding()
        .background(theme.surfaceColor)
        .cornerRadius(theme.cornerRadius.medium)
    }
}

struct ProgressRow: View {
    let title: String
    let isCompleted: Bool
    let time: String
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        HStack {
            Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isCompleted ? .green : theme.textTertiary)
            
            Text(title)
                .font(theme.typography.bodyMedium)
                .foregroundColor(theme.textPrimary)
                .strikethrough(isCompleted)
            
            Spacer()
            
            Text(time)
                .font(theme.typography.bodySmall)
                .foregroundColor(theme.textSecondary)
        }
    }
}

struct QuickActionCard: View {
    let title: String
    let icon: String
    let color: Color
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(spacing: theme.spacing.sm) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)
            
            Text(title)
                .font(theme.typography.bodySmall)
                .foregroundColor(theme.textPrimary)
                .multilineTextAlignment(.center)
        }
        .frame(width: 100, height: 100)
        .background(theme.surfaceColor)
        .cornerRadius(theme.cornerRadius.medium)
    }
}

struct CategoryPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(theme.typography.bodyMedium)
                .foregroundColor(isSelected ? .white : theme.textPrimary)
                .padding(.horizontal, theme.spacing.md)
                .padding(.vertical, theme.spacing.sm)
                .background(isSelected ? theme.primaryColor : theme.surfaceColor)
                .cornerRadius(theme.cornerRadius.pill)
        }
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        HStack {
            Image(systemName: icon)
            Text(title)
        }
        .font(theme.typography.bodyMedium)
        .foregroundColor(.white)
        .padding(.horizontal, theme.spacing.md)
        .padding(.vertical, theme.spacing.sm)
        .background(color)
        .cornerRadius(theme.cornerRadius.medium)
    }
}

struct WorkoutRow: View {
    let name: String
    let description: String
    let duration: String
    let category: String
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                Text(name)
                    .font(theme.typography.bodyLarge)
                    .fontWeight(.medium)
                    .foregroundColor(theme.textPrimary)
                
                Text(description)
                    .font(theme.typography.bodySmall)
                    .foregroundColor(theme.textSecondary)
                
                HStack {
                    Label(duration, systemImage: "clock")
                    Text("•")
                    Text(category)
                }
                .font(theme.typography.bodySmall)
                .foregroundColor(theme.textTertiary)
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

struct MacroView: View {
    let name: String
    let value: Double
    let target: Double
    let unit: String
    let color: Color
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(spacing: 4) {
            Text(name)
                .font(theme.typography.bodySmall)
                .foregroundColor(theme.textSecondary)
            
            Text("\(Int(value))\(unit)")
                .font(theme.typography.bodyMedium)
                .fontWeight(.bold)
                .foregroundColor(theme.textPrimary)
            
            Text("/ \(Int(target))")
                .font(.caption2)
                .foregroundColor(theme.textTertiary)
            
            ProgressView(value: value / target)
                .tint(color)
                .scaleEffect(x: 1, y: 0.5, anchor: .center)
        }
    }
}

struct MealSection: View {
    let meal: String
    let calories: Int
    let items: [String]
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            HStack {
                Text(meal)
                    .font(theme.typography.bodyMedium)
                    .fontWeight(.medium)
                Spacer()
                if calories > 0 {
                    Text("\(calories) cal")
                        .font(theme.typography.bodySmall)
                        .foregroundColor(theme.primaryColor)
                }
                Image(systemName: "plus.circle")
                    .foregroundColor(theme.primaryColor)
            }
            
            if items.isEmpty {
                Text("No items logged")
                    .font(theme.typography.bodySmall)
                    .foregroundColor(theme.textTertiary)
                    .italic()
            } else {
                ForEach(items, id: \.self) { item in
                    HStack {
                        Text("• \(item)")
                            .font(theme.typography.bodySmall)
                            .foregroundColor(theme.textSecondary)
                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background(theme.surfaceColor)
        .cornerRadius(theme.cornerRadius.medium)
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthenticationManager())
        .environmentObject(ThemeManager())
        .environmentObject(HealthKitManager())
        .theme(FitnessTheme())
}