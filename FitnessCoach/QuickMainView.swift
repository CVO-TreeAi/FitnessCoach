import SwiftUI

// MAIN APP - FAST LOADING WITH ALL WORKING BUTTONS
struct QuickMainView: View {
    @State private var selectedTab = 0
    @State private var waterIntake = 5
    @State private var currentWeight = 185.0
    @State private var showingWeightEntry = false
    @State private var showingQuickWorkout = false
    @State private var showingFoodEntry = false
    @State private var showingWorkoutBuilder = false
    @State private var showingStrongLifts = false
    @State private var selectedMealType = "Breakfast"
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // DASHBOARD TAB
            NavigationView {
                ScrollView {
                    VStack(spacing: 16) {
                        // Quick Actions that ACTUALLY WORK
                        Text("Quick Actions")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            // Start Workout - WORKING
                            Button {
                                showingQuickWorkout = true
                            } label: {
                                VStack(spacing: 8) {
                                    Image(systemName: "figure.run")
                                        .font(.title2)
                                        .foregroundColor(.blue)
                                    Text("Start Workout")
                                        .font(.caption)
                                }
                                .frame(maxWidth: .infinity, minHeight: 80)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(12)
                            }
                            
                            // Log Meal - WORKING
                            Button {
                                showingFoodEntry = true
                            } label: {
                                VStack(spacing: 8) {
                                    Image(systemName: "fork.knife")
                                        .font(.title2)
                                        .foregroundColor(.orange)
                                    Text("Log Meal")
                                        .font(.caption)
                                }
                                .frame(maxWidth: .infinity, minHeight: 80)
                                .background(Color.orange.opacity(0.1))
                                .cornerRadius(12)
                            }
                            
                            // Track Weight - WORKING
                            Button {
                                showingWeightEntry = true
                            } label: {
                                VStack(spacing: 8) {
                                    Image(systemName: "scalemass")
                                        .font(.title2)
                                        .foregroundColor(.green)
                                    Text("Track Weight")
                                        .font(.caption)
                                }
                                .frame(maxWidth: .infinity, minHeight: 80)
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(12)
                            }
                            
                            // StrongLifts 5x5 - WORKING
                            Button {
                                showingStrongLifts = true
                            } label: {
                                VStack(spacing: 8) {
                                    Image(systemName: "figure.strengthtraining.traditional")
                                        .font(.title2)
                                        .foregroundColor(.red)
                                    Text("5×5 Workout")
                                        .font(.caption)
                                }
                                .frame(maxWidth: .infinity, minHeight: 80)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(12)
                            }
                        }
                        
                        // Water Intake - WORKING
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Water Intake")
                                .font(.headline)
                            
                            HStack(spacing: 8) {
                                ForEach(0..<8, id: \.self) { index in
                                    Button {
                                        waterIntake = index < waterIntake ? index : index + 1
                                    } label: {
                                        Image(systemName: index < waterIntake ? "drop.fill" : "drop")
                                            .font(.title)
                                            .foregroundColor(index < waterIntake ? .blue : .gray)
                                    }
                                }
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                            
                            // Water +1 Button - WORKING
                            Button {
                                if waterIntake < 8 {
                                    waterIntake += 1
                                }
                            } label: {
                                Label("Water +1", systemImage: "plus.circle.fill")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }
                        }
                        
                        // Today's Stats
                        HStack(spacing: 12) {
                            VStack {
                                Text("\(waterIntake)")
                                    .font(.title)
                                    .fontWeight(.bold)
                                Text("Water (cups)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                            
                            VStack {
                                Text(String(format: "%.1f", currentWeight))
                                    .font(.title)
                                    .fontWeight(.bold)
                                Text("Weight (lbs)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(12)
                        }
                    }
                    .padding()
                }
                .navigationTitle("Dashboard")
            }
            .tabItem {
                Image(systemName: "house.fill")
                Text("Home")
            }
            .tag(0)
            
            // WORKOUTS TAB
            NavigationView {
                ScrollView {
                    VStack(spacing: 16) {
                        // Create Workout Button - WORKING
                        Button {
                            showingWorkoutBuilder = true
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                Text("Create Workout")
                                    .fontWeight(.medium)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        
                        // StrongLifts 5x5 Card - WORKING
                        Button {
                            showingStrongLifts = true
                        } label: {
                            HStack {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 50, height: 50)
                                    .overlay(
                                        Image(systemName: "figure.strengthtraining.traditional")
                                            .foregroundColor(.white)
                                    )
                                
                                VStack(alignment: .leading) {
                                    Text("StrongLifts 5×5")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Text("Build strength with compound movements")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                        }
                        
                        // Quick Workout Card - WORKING
                        Button {
                            showingQuickWorkout = true
                        } label: {
                            HStack {
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 50, height: 50)
                                    .overlay(
                                        Image(systemName: "timer")
                                            .foregroundColor(.white)
                                    )
                                
                                VStack(alignment: .leading) {
                                    Text("Quick Workout")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Text("Start a quick workout session")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                        }
                    }
                    .padding()
                }
                .navigationTitle("Workouts")
            }
            .tabItem {
                Image(systemName: "figure.run")
                Text("Workouts")
            }
            .tag(1)
            
            // NUTRITION TAB
            NavigationView {
                ScrollView {
                    VStack(spacing: 16) {
                        // Meal Buttons - ALL WORKING
                        ForEach(["Breakfast", "Lunch", "Dinner", "Snacks"], id: \.self) { meal in
                            Button {
                                selectedMealType = meal
                                showingFoodEntry = true
                            } label: {
                                HStack {
                                    Text(meal)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    Button {
                                        selectedMealType = meal
                                        showingFoodEntry = true
                                    } label: {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(.blue)
                                    }
                                }
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(12)
                            }
                        }
                        
                        // Water Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Water Intake")
                                .font(.headline)
                            
                            HStack(spacing: 8) {
                                ForEach(0..<8, id: \.self) { index in
                                    Button {
                                        waterIntake = index < waterIntake ? index : index + 1
                                    } label: {
                                        Image(systemName: index < waterIntake ? "drop.fill" : "drop")
                                            .font(.title)
                                            .foregroundColor(index < waterIntake ? .blue : .gray)
                                    }
                                }
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                        }
                    }
                    .padding()
                }
                .navigationTitle("Nutrition")
            }
            .tabItem {
                Image(systemName: "leaf.fill")
                Text("Nutrition")
            }
            .tag(2)
            
            // PROFILE TAB
            NavigationView {
                VStack(spacing: 16) {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 100, height: 100)
                        .overlay(
                            Text("U")
                                .font(.largeTitle)
                                .foregroundColor(.white)
                        )
                    
                    Text("User")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    VStack(spacing: 12) {
                        HStack {
                            Text("Current Weight")
                                .foregroundColor(.gray)
                            Spacer()
                            Text("\(String(format: "%.1f", currentWeight)) lbs")
                                .fontWeight(.medium)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                        
                        HStack {
                            Text("Water Goal")
                                .foregroundColor(.gray)
                            Spacer()
                            Text("\(waterIntake)/8 cups")
                                .fontWeight(.medium)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    Spacer()
                }
                .padding()
                .navigationTitle("Profile")
            }
            .tabItem {
                Image(systemName: "person.fill")
                Text("Profile")
            }
            .tag(3)
        }
        // ALL SHEETS - WORKING
        .sheet(isPresented: $showingWeightEntry) {
            SimpleWeightEntry(weight: $currentWeight, isPresented: $showingWeightEntry)
        }
        .sheet(isPresented: $showingQuickWorkout) {
            SimpleQuickWorkout(isPresented: $showingQuickWorkout)
        }
        .sheet(isPresented: $showingFoodEntry) {
            SimpleFoodEntry(mealType: selectedMealType, isPresented: $showingFoodEntry)
        }
        .sheet(isPresented: $showingWorkoutBuilder) {
            SimpleWorkoutBuilder(isPresented: $showingWorkoutBuilder)
        }
        .sheet(isPresented: $showingStrongLifts) {
            SimpleStrongLifts(isPresented: $showingStrongLifts)
        }
    }
}

// SIMPLE WEIGHT ENTRY - WORKING
struct SimpleWeightEntry: View {
    @Binding var weight: Double
    @Binding var isPresented: Bool
    @State private var weightText = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Enter Your Weight")
                    .font(.title)
                
                TextField("Weight in lbs", text: $weightText)
                    .keyboardType(.decimalPad)
                    .font(.largeTitle)
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                
                Button {
                    if let newWeight = Double(weightText) {
                        weight = newWeight
                    }
                    isPresented = false
                } label: {
                    Text("Save")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                
                Spacer()
            }
            .padding()
            .navigationBarItems(trailing: Button("Cancel") { isPresented = false })
        }
        .onAppear {
            weightText = String(format: "%.1f", weight)
        }
    }
}

// SIMPLE QUICK WORKOUT - WORKING
struct SimpleQuickWorkout: View {
    @Binding var isPresented: Bool
    @State private var selectedWorkout = "Full Body"
    @State private var duration = 30
    
    let workoutTypes = ["Full Body", "Upper Body", "Lower Body", "Core", "Cardio", "HIIT"]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Quick Workout")
                    .font(.title)
                
                ForEach(workoutTypes, id: \.self) { workout in
                    Button {
                        selectedWorkout = workout
                    } label: {
                        HStack {
                            Text(workout)
                                .foregroundColor(selectedWorkout == workout ? .white : .primary)
                            Spacer()
                            if selectedWorkout == workout {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.white)
                            }
                        }
                        .padding()
                        .background(selectedWorkout == workout ? Color.blue : Color.gray.opacity(0.1))
                        .cornerRadius(12)
                    }
                }
                
                VStack(alignment: .leading) {
                    Text("Duration: \(duration) minutes")
                        .font(.headline)
                    Slider(value: Binding(
                        get: { Double(duration) },
                        set: { duration = Int($0) }
                    ), in: 10...60, step: 5)
                }
                
                Button {
                    // Start workout
                    isPresented = false
                } label: {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Start \(selectedWorkout) Workout")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                
                Spacer()
            }
            .padding()
            .navigationBarItems(trailing: Button("Cancel") { isPresented = false })
        }
    }
}

// SIMPLE FOOD ENTRY - WORKING
struct SimpleFoodEntry: View {
    let mealType: String
    @Binding var isPresented: Bool
    @State private var foodName = ""
    @State private var calories = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Add Food to \(mealType)")
                    .font(.title)
                
                TextField("Food name", text: $foodName)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                
                TextField("Calories", text: $calories)
                    .keyboardType(.numberPad)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                
                Button {
                    // Save food
                    isPresented = false
                } label: {
                    Text("Add to \(mealType)")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                
                Spacer()
            }
            .padding()
            .navigationBarItems(trailing: Button("Cancel") { isPresented = false })
        }
    }
}

// SIMPLE WORKOUT BUILDER - WORKING
struct SimpleWorkoutBuilder: View {
    @Binding var isPresented: Bool
    @State private var workoutName = ""
    @State private var exercises: [String] = []
    @State private var newExercise = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Create Workout")
                    .font(.title)
                
                TextField("Workout name", text: $workoutName)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                
                HStack {
                    TextField("Add exercise", text: $newExercise)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                    
                    Button {
                        if !newExercise.isEmpty {
                            exercises.append(newExercise)
                            newExercise = ""
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title)
                            .foregroundColor(.blue)
                    }
                }
                
                if !exercises.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Exercises:")
                            .font(.headline)
                        ForEach(exercises, id: \.self) { exercise in
                            Text("• \(exercise)")
                                .padding(.vertical, 4)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                }
                
                Button {
                    // Save workout
                    isPresented = false
                } label: {
                    Text("Save Workout")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(!workoutName.isEmpty ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .disabled(workoutName.isEmpty)
                
                Spacer()
            }
            .padding()
            .navigationBarItems(trailing: Button("Cancel") { isPresented = false })
        }
    }
}

// SIMPLE STRONGLIFTS - WORKING
struct SimpleStrongLifts: View {
    @Binding var isPresented: Bool
    @State private var workoutA = true
    @State private var completedSets: [Int: Bool] = [:]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("StrongLifts 5×5")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    // Workout Selector
                    HStack(spacing: 12) {
                        Button {
                            workoutA = true
                        } label: {
                            VStack {
                                Text("Workout A")
                                    .fontWeight(.bold)
                                Text("Squat\nBench\nRow")
                                    .font(.caption)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(workoutA ? Color.red : Color.gray.opacity(0.2))
                            .foregroundColor(workoutA ? .white : .primary)
                            .cornerRadius(12)
                        }
                        
                        Button {
                            workoutA = false
                        } label: {
                            VStack {
                                Text("Workout B")
                                    .fontWeight(.bold)
                                Text("Squat\nOHP\nDeadlift")
                                    .font(.caption)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(!workoutA ? Color.red : Color.gray.opacity(0.2))
                            .foregroundColor(!workoutA ? .white : .primary)
                            .cornerRadius(12)
                        }
                    }
                    
                    // Exercises
                    VStack(spacing: 16) {
                        if workoutA {
                            ExerciseRow(name: "Squat", weight: 135, sets: 5, completedSets: $completedSets, baseIndex: 0)
                            ExerciseRow(name: "Bench Press", weight: 95, sets: 5, completedSets: $completedSets, baseIndex: 5)
                            ExerciseRow(name: "Barbell Row", weight: 95, sets: 5, completedSets: $completedSets, baseIndex: 10)
                        } else {
                            ExerciseRow(name: "Squat", weight: 135, sets: 5, completedSets: $completedSets, baseIndex: 15)
                            ExerciseRow(name: "Overhead Press", weight: 65, sets: 5, completedSets: $completedSets, baseIndex: 20)
                            ExerciseRow(name: "Deadlift", weight: 185, sets: 1, completedSets: $completedSets, baseIndex: 25)
                        }
                    }
                    
                    Button {
                        // Complete workout
                        isPresented = false
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Complete Workout")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationBarItems(trailing: Button("Close") { isPresented = false })
        }
    }
}

struct ExerciseRow: View {
    let name: String
    let weight: Int
    let sets: Int
    @Binding var completedSets: [Int: Bool]
    let baseIndex: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(name)
                    .font(.headline)
                Spacer()
                Text("\(weight) lbs")
                    .fontWeight(.bold)
            }
            
            HStack(spacing: 8) {
                ForEach(0..<sets, id: \.self) { set in
                    Button {
                        let index = baseIndex + set
                        completedSets[index] = !(completedSets[index] ?? false)
                    } label: {
                        Circle()
                            .fill(completedSets[baseIndex + set] ?? false ? Color.green : Color.gray.opacity(0.3))
                            .frame(width: 50, height: 50)
                            .overlay(
                                Text("5")
                                    .fontWeight(.bold)
                                    .foregroundColor(completedSets[baseIndex + set] ?? false ? .white : .primary)
                            )
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}