import SwiftUI

// MARK: - Fully Functional Dashboard
struct FunctionalDashboard: View {
    @Environment(\.theme) private var theme
    @State private var currentWeight: Double = 185
    @State private var goalWeight: Double = 180
    @State private var todayCalories: Double = 1450
    @State private var targetCalories: Double = 2200
    @State private var waterCups: Int = 5
    
    // Modal states
    @State private var showWeightEntry = false
    @State private var showFoodEntry = false
    @State private var showQuickWorkout = false
    @State private var showProfile = false
    @State private var selectedMeal = "Lunch"
    
    // Toast notification
    @State private var showToast = false
    @State private var toastMessage = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: theme.spacing.lg) {
                    // Header with functional profile button
                    headerSection
                    
                    // Stats with tap actions
                    quickStatsGrid
                    
                    // Progress with checkable items
                    todaysProgressSection
                    
                    // Functional quick actions
                    quickActionsSection
                }
                .padding(.horizontal)
                .padding(.bottom, 50)
            }
            .navigationTitle("Dashboard")
            .background(theme.backgroundColor)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showProfile = true
                    } label: {
                        Image(systemName: "person.circle")
                            .foregroundColor(theme.primaryColor)
                    }
                }
            }
        }
        .sheet(isPresented: $showWeightEntry) {
            WeightEntryForm(isPresented: $showWeightEntry) { weight in
                currentWeight = weight
                showSuccessToast("Weight updated: \(Int(weight)) lbs")
            }
        }
        .sheet(isPresented: $showFoodEntry) {
            FoodEntryForm(isPresented: $showFoodEntry, mealType: selectedMeal) { food, calories in
                todayCalories += Double(calories)
                showSuccessToast("\(food) added to \(selectedMeal)")
            }
        }
        .sheet(isPresented: $showQuickWorkout) {
            QuickWorkoutSheet(isPresented: $showQuickWorkout)
        }
        .sheet(isPresented: $showProfile) {
            ProfileView(isPresented: $showProfile)
        }
        .overlay(alignment: .top) {
            if showToast {
                ToastView(message: toastMessage)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(1)
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
                showProfile = true
            } label: {
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
        }
        .padding(.vertical)
    }
    
    private var quickStatsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: theme.spacing.md) {
            // Weight card - tappable
            Button {
                showWeightEntry = true
            } label: {
                StatCard(
                    title: "Weight",
                    value: "\(Int(currentWeight))",
                    unit: "lbs",
                    subtitle: "Goal: \(Int(goalWeight)) lbs",
                    icon: "scalemass",
                    color: .blue,
                    progress: 0.75
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            // Calories card - tappable
            Button {
                selectedMeal = getCurrentMeal()
                showFoodEntry = true
            } label: {
                StatCard(
                    title: "Calories",
                    value: "\(Int(todayCalories))",
                    unit: "cal",
                    subtitle: "Target: \(Int(targetCalories))",
                    icon: "flame.fill",
                    color: .orange,
                    progress: todayCalories / targetCalories
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            // Workouts card
            StatCard(
                title: "Workouts",
                value: "3",
                unit: "this week",
                subtitle: "Target: 5/week",
                icon: "figure.strengthtraining.traditional",
                color: .green,
                progress: 0.6
            )
            
            // Water card - tappable
            Button {
                waterCups = min(waterCups + 1, 8)
                showSuccessToast("Water intake: \(waterCups)/8 cups")
            } label: {
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
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    private var todaysProgressSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            Text("Today's Progress")
                .font(theme.typography.titleMedium)
                .foregroundColor(theme.textPrimary)
            
            VStack(spacing: theme.spacing.sm) {
                CheckableProgressRow(title: "Morning Workout", time: "7:00 AM", initialState: true)
                CheckableProgressRow(title: "Breakfast Logged", time: "8:30 AM", initialState: true)
                CheckableProgressRow(title: "Lunch Logged", time: "12:15 PM", initialState: true)
                CheckableProgressRow(title: "Afternoon Workout", time: "5:00 PM", initialState: false)
                CheckableProgressRow(title: "Dinner", time: "7:00 PM", initialState: false)
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
                    Button {
                        showQuickWorkout = true
                    } label: {
                        QuickActionCard(title: "Start Workout", icon: "play.circle.fill", color: .green)
                    }
                    
                    Button {
                        selectedMeal = getCurrentMeal()
                        showFoodEntry = true
                    } label: {
                        QuickActionCard(title: "Log Meal", icon: "plus.circle.fill", color: .orange)
                    }
                    
                    Button {
                        showWeightEntry = true
                    } label: {
                        QuickActionCard(title: "Track Weight", icon: "chart.line.uptrend.xyaxis", color: .blue)
                    }
                    
                    Button {
                        waterCups = min(waterCups + 1, 8)
                        showSuccessToast("Water intake: \(waterCups)/8 cups")
                    } label: {
                        QuickActionCard(title: "Water +1", icon: "drop.circle.fill", color: .cyan)
                    }
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
    
    private func getCurrentMeal() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<11: return "Breakfast"
        case 11..<15: return "Lunch"
        case 15..<20: return "Dinner"
        default: return "Snacks"
        }
    }
    
    private func showSuccessToast(_ message: String) {
        toastMessage = message
        showToast = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showToast = false
        }
    }
}

// MARK: - Fully Functional Workouts
struct FunctionalWorkouts: View {
    @Environment(\.theme) private var theme
    @State private var selectedCategory: String = "All"
    @State private var showQuickWorkout = false
    @State private var showWorkoutBuilder = false
    @State private var selectedWorkout: (String, String)? = nil
    
    let categories = ["All", "Strength", "Cardio", "Flexibility", "HIIT"]
    let workouts = [
        ("Push Day", "Chest, Shoulders, Triceps", "45 min", "Strength"),
        ("Pull Day", "Back, Biceps", "50 min", "Strength"),
        ("Leg Day", "Quads, Hamstrings, Glutes", "60 min", "Strength"),
        ("Morning Run", "5K Steady Pace", "30 min", "Cardio"),
        ("HIIT Circuit", "Full Body Blast", "20 min", "HIIT")
    ]
    
    var filteredWorkouts: [(String, String, String, String)] {
        workouts.filter { selectedCategory == "All" || $0.3 == selectedCategory }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: theme.spacing.lg) {
                    // Category Filter - Functional
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: theme.spacing.sm) {
                            ForEach(categories, id: \.self) { category in
                                CategoryPill(title: category, isSelected: selectedCategory == category) {
                                    withAnimation(.spring()) {
                                        selectedCategory = category
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Quick Actions - Functional
                    HStack(spacing: theme.spacing.md) {
                        Button {
                            showQuickWorkout = true
                        } label: {
                            ActionButton(title: "Start Quick Workout", icon: "play.fill", color: .green)
                        }
                        
                        Button {
                            showWorkoutBuilder = true
                        } label: {
                            ActionButton(title: "Create Workout", icon: "plus", color: theme.primaryColor)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Workouts List - Functional
                    VStack(spacing: theme.spacing.md) {
                        ForEach(filteredWorkouts, id: \.0) { workout in
                            NavigationLink(destination: WorkoutDetailView(workoutName: workout.0, category: workout.3)) {
                                WorkoutRow(
                                    name: workout.0,
                                    description: workout.1,
                                    duration: workout.2,
                                    category: workout.3
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Workouts")
            .background(theme.backgroundColor)
        }
        .sheet(isPresented: $showQuickWorkout) {
            QuickWorkoutSheet(isPresented: $showQuickWorkout)
        }
        .sheet(isPresented: $showWorkoutBuilder) {
            WorkoutBuilderView(isPresented: $showWorkoutBuilder)
        }
    }
}

// MARK: - Fully Functional Nutrition
struct FunctionalNutrition: View {
    @Environment(\.theme) private var theme
    @State private var calories: Double = 1450
    @State private var protein: Double = 95
    @State private var carbs: Double = 180
    @State private var fat: Double = 45
    @State private var waterIntake: Int = 5
    @State private var showFoodEntry = false
    @State private var selectedMeal = "Breakfast"
    
    @State private var meals: [String: [String]] = [
        "Breakfast": ["Oatmeal", "Banana", "Protein Shake"],
        "Lunch": ["Grilled Chicken", "Brown Rice", "Vegetables"],
        "Dinner": [],
        "Snacks": ["Protein Bar", "Apple"]
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: theme.spacing.lg) {
                    // Daily Summary
                    dailySummarySection
                    
                    // Meals - Functional
                    mealsSection
                    
                    // Water Tracking - Functional
                    waterTrackingSection
                }
                .padding(.horizontal)
                .padding(.bottom, 50)
            }
            .navigationTitle("Nutrition")
            .background(theme.backgroundColor)
            .overlay(alignment: .bottomTrailing) {
                // Floating Action Button
                Button {
                    selectedMeal = "Snacks"
                    showFoodEntry = true
                } label: {
                    Image(systemName: "plus")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(theme.primaryColor)
                        .clipShape(Circle())
                        .shadow(radius: 4)
                }
                .padding()
            }
        }
        .sheet(isPresented: $showFoodEntry) {
            FoodEntryForm(isPresented: $showFoodEntry, mealType: selectedMeal) { food, cals in
                if meals[selectedMeal] != nil {
                    meals[selectedMeal]?.append(food)
                }
                calories += Double(cals)
            }
        }
    }
    
    private var dailySummarySection: some View {
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
            
            HStack(spacing: theme.spacing.xl) {
                MacroView(name: "Protein", value: protein, target: 140, unit: "g", color: .blue)
                MacroView(name: "Carbs", value: carbs, target: 275, unit: "g", color: .orange)
                MacroView(name: "Fat", value: fat, target: 73, unit: "g", color: .yellow)
            }
        }
        .padding()
        .background(theme.surfaceColor)
        .cornerRadius(theme.cornerRadius.medium)
    }
    
    private var mealsSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            Text("Meals")
                .font(theme.typography.titleMedium)
            
            ForEach(["Breakfast", "Lunch", "Dinner", "Snacks"], id: \.self) { meal in
                Button {
                    selectedMeal = meal
                    showFoodEntry = true
                } label: {
                    FunctionalMealSection(
                        meal: meal,
                        items: meals[meal] ?? [],
                        onAdd: {
                            selectedMeal = meal
                            showFoodEntry = true
                        }
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    private var waterTrackingSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            Text("Water Intake")
                .font(theme.typography.titleMedium)
            
            HStack {
                ForEach(0..<8) { index in
                    Button {
                        if index < waterIntake {
                            waterIntake = index
                        } else {
                            waterIntake = index + 1
                        }
                    } label: {
                        Image(systemName: index < waterIntake ? "drop.fill" : "drop")
                            .font(.title2)
                            .foregroundColor(index < waterIntake ? .cyan : theme.textTertiary)
                    }
                }
            }
            .padding()
            .background(theme.surfaceColor)
            .cornerRadius(theme.cornerRadius.medium)
        }
    }
}

// MARK: - Supporting Views

struct CheckableProgressRow: View {
    let title: String
    let time: String
    @State private var isCompleted: Bool
    @Environment(\.theme) private var theme
    
    init(title: String, time: String, initialState: Bool) {
        self.title = title
        self.time = time
        self._isCompleted = State(initialValue: initialState)
    }
    
    var body: some View {
        Button {
            withAnimation(.spring()) {
                isCompleted.toggle()
            }
        } label: {
            HStack {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isCompleted ? .green : theme.textTertiary)
                    .font(.title3)
                
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
        .buttonStyle(PlainButtonStyle())
    }
}

struct FunctionalMealSection: View {
    let meal: String
    let items: [String]
    let onAdd: () -> Void
    @Environment(\.theme) private var theme
    
    var calories: Int {
        items.count * 150 // Simplified calculation
    }
    
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
                Button(action: onAdd) {
                    Image(systemName: "plus.circle")
                        .foregroundColor(theme.primaryColor)
                }
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

struct ProfileView: View {
    @Binding var isPresented: Bool
    @Environment(\.theme) private var theme
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack {
                        Circle()
                            .fill(theme.primaryColor)
                            .frame(width: 80, height: 80)
                            .overlay(Text("JD").font(.largeTitle).foregroundColor(.white))
                        VStack(alignment: .leading) {
                            Text("John Doe")
                                .font(theme.typography.titleMedium)
                            Text("john.doe@example.com")
                                .font(theme.typography.bodySmall)
                                .foregroundColor(theme.textSecondary)
                        }
                    }
                    .padding(.vertical)
                }
                
                Section("Settings") {
                    ListRowItem(title: "Goals", subtitle: "Weight, calories, macros", leadingIcon: "target")
                    ListRowItem(title: "Notifications", subtitle: "Reminders and alerts", leadingIcon: "bell")
                    ListRowItem(title: "Privacy", subtitle: "Data and sharing", leadingIcon: "lock")
                    ListRowItem(title: "Help", subtitle: "Support and feedback", leadingIcon: "questionmark.circle")
                }
                
                Section {
                    Button("Sign Out") {
                        isPresented = false
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

struct WorkoutBuilderView: View {
    @Binding var isPresented: Bool
    @Environment(\.theme) private var theme
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Workout Builder")
                    .font(theme.typography.titleLarge)
                Text("Create custom workouts")
                    .font(theme.typography.bodyMedium)
                    .foregroundColor(theme.textSecondary)
                
                Spacer()
                
                Button("Coming Soon") {
                    isPresented = false
                }
                .padding()
            }
            .navigationTitle("Create Workout")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

struct ToastView: View {
    let message: String
    @Environment(\.theme) private var theme
    
    var body: some View {
        Text(message)
            .font(theme.typography.bodyMedium)
            .foregroundColor(.white)
            .padding()
            .background(Color.green)
            .cornerRadius(theme.cornerRadius.medium)
            .shadow(radius: 4)
            .padding()
    }
}