import SwiftUI

struct StrongLifts5x5View: View {
    @EnvironmentObject private var dataManager: SimpleDataManager
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss
    @State private var currentWeek = 1
    @State private var workoutA = true
    @State private var weights = StrongLiftsWeights()
    @State private var completedSets: [String: [Bool]] = [:]
    @State private var showingWeightAdjustment = false
    
    struct StrongLiftsWeights {
        var squat: Double = 45
        var benchPress: Double = 45
        var barbellRow: Double = 65
        var overheadPress: Double = 45
        var deadlift: Double = 95
    }
    
    var currentWorkout: [(name: String, weight: Double, sets: Int, reps: Int)] {
        if workoutA {
            return [
                ("Squat", weights.squat, 5, 5),
                ("Bench Press", weights.benchPress, 5, 5),
                ("Barbell Row", weights.barbellRow, 5, 5)
            ]
        } else {
            return [
                ("Squat", weights.squat, 5, 5),
                ("Overhead Press", weights.overheadPress, 5, 5),
                ("Deadlift", weights.deadlift, 1, 5)
            ]
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: theme.spacing.lg) {
                    // Program Header
                    programHeader
                    
                    // Current Workout
                    workoutTypeSelector
                    
                    // Exercises
                    exercisesSection
                    
                    // Weight Progression Info
                    progressionInfo
                    
                    // Complete Workout Button
                    completeWorkoutButton
                }
                .padding()
            }
            .navigationTitle("StrongLifts 5×5")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Adjust Weights") {
                        showingWeightAdjustment = true
                    }
                }
            }
            .sheet(isPresented: $showingWeightAdjustment) {
                WeightAdjustmentSheet(weights: $weights)
            }
        }
    }
    
    private var programHeader: some View {
        VStack(spacing: theme.spacing.md) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Week \(currentWeek)")
                        .font(theme.typography.headlineMedium)
                        .foregroundColor(theme.textPrimary)
                    
                    Text("Progressive Overload Program")
                        .font(theme.typography.bodyMedium)
                        .foregroundColor(theme.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 40))
                    .foregroundColor(theme.primaryColor)
            }
            
            HStack(spacing: theme.spacing.xl) {
                VStack {
                    Text("\(completedWorkouts)")
                        .font(theme.typography.titleLarge)
                        .foregroundColor(theme.primaryColor)
                    Text("Completed")
                        .font(theme.typography.bodySmall)
                        .foregroundColor(theme.textSecondary)
                }
                
                VStack {
                    Text("\(totalWeightLifted) lbs")
                        .font(theme.typography.titleLarge)
                        .foregroundColor(theme.primaryColor)
                    Text("Total Volume")
                        .font(theme.typography.bodySmall)
                        .foregroundColor(theme.textSecondary)
                }
                
                VStack {
                    Text("+5 lbs")
                        .font(theme.typography.titleLarge)
                        .foregroundColor(.green)
                    Text("Next Session")
                        .font(theme.typography.bodySmall)
                        .foregroundColor(theme.textSecondary)
                }
            }
        }
        .padding()
        .background(theme.surfaceColor)
        .cornerRadius(theme.cornerRadius.medium)
    }
    
    private var workoutTypeSelector: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            Text("Today's Workout")
                .font(theme.typography.titleMedium)
                .foregroundColor(theme.textPrimary)
            
            HStack(spacing: theme.spacing.md) {
                Button {
                    workoutA = true
                } label: {
                    VStack(spacing: theme.spacing.sm) {
                        Text("Workout A")
                            .font(theme.typography.bodyMedium)
                            .fontWeight(.medium)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("• Squat 5×5")
                            Text("• Bench Press 5×5")
                            Text("• Barbell Row 5×5")
                        }
                        .font(theme.typography.bodySmall)
                    }
                    .foregroundColor(workoutA ? .white : theme.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(workoutA ? theme.primaryColor : theme.surfaceColor)
                    .cornerRadius(theme.cornerRadius.medium)
                }
                
                Button {
                    workoutA = false
                } label: {
                    VStack(spacing: theme.spacing.sm) {
                        Text("Workout B")
                            .font(theme.typography.bodyMedium)
                            .fontWeight(.medium)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("• Squat 5×5")
                            Text("• Overhead Press 5×5")
                            Text("• Deadlift 1×5")
                        }
                        .font(theme.typography.bodySmall)
                    }
                    .foregroundColor(!workoutA ? .white : theme.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(!workoutA ? theme.primaryColor : theme.surfaceColor)
                    .cornerRadius(theme.cornerRadius.medium)
                }
            }
        }
    }
    
    private var exercisesSection: some View {
        VStack(spacing: theme.spacing.md) {
            ForEach(currentWorkout, id: \.name) { exercise in
                ExerciseCard(
                    name: exercise.name,
                    weight: exercise.weight,
                    sets: exercise.sets,
                    reps: exercise.reps,
                    completedSets: completedSets[exercise.name] ?? Array(repeating: false, count: exercise.sets),
                    onSetToggle: { setIndex in
                        toggleSet(exercise: exercise.name, setIndex: setIndex, totalSets: exercise.sets)
                    }
                )
            }
        }
    }
    
    private var progressionInfo: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            Text("Progression Rules")
                .font(theme.typography.titleMedium)
                .foregroundColor(theme.textPrimary)
            
            VStack(alignment: .leading, spacing: theme.spacing.sm) {
                Label("Complete all 5×5? Add 5 lbs next session", systemImage: "checkmark.circle.fill")
                    .foregroundColor(.green)
                
                Label("Squat & Deadlift: Add 5-10 lbs per session", systemImage: "arrow.up.circle.fill")
                    .foregroundColor(theme.primaryColor)
                
                Label("Failed 3 times? Deload 10%", systemImage: "arrow.down.circle")
                    .foregroundColor(.orange)
                
                Label("Rest 90 sec (light) to 5 min (heavy)", systemImage: "timer")
                    .foregroundColor(theme.textSecondary)
            }
            .font(theme.typography.bodySmall)
            .padding()
            .background(theme.surfaceColor)
            .cornerRadius(theme.cornerRadius.medium)
        }
    }
    
    private var completeWorkoutButton: some View {
        Button {
            completeWorkout()
        } label: {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                Text("Complete Workout")
            }
            .font(theme.typography.bodyMedium)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(allSetsCompleted ? theme.primaryColor : theme.textTertiary)
            .cornerRadius(theme.cornerRadius.medium)
        }
        .disabled(!allSetsCompleted)
    }
    
    private func toggleSet(exercise: String, setIndex: Int, totalSets: Int) {
        if completedSets[exercise] == nil {
            completedSets[exercise] = Array(repeating: false, count: totalSets)
        }
        completedSets[exercise]?[setIndex].toggle()
    }
    
    private func completeWorkout() {
        // Add 5 lbs to each exercise for next session
        weights.squat += 5
        if workoutA {
            weights.benchPress += 5
            weights.barbellRow += 5
        } else {
            weights.overheadPress += 5
            weights.deadlift += 10 // Deadlift progresses faster
        }
        
        // Save workout
        let exercises = currentWorkout.map { ($0.name, $0.sets, $0.reps, 90) }
        dataManager.addWorkout(
            name: "StrongLifts 5×5 - Workout \(workoutA ? "A" : "B")",
            category: "Strength",
            duration: 60,
            exercises: exercises
        )
        
        // Reset and switch workout
        completedSets = [:]
        workoutA.toggle()
        
        // Update week if needed
        if dataManager.workouts.filter({ $0.name.contains("StrongLifts") }).count % 6 == 0 {
            currentWeek += 1
        }
        
        dismiss()
    }
    
    private var allSetsCompleted: Bool {
        for exercise in currentWorkout {
            let sets = completedSets[exercise.name] ?? []
            if sets.count != exercise.sets || !sets.allSatisfy({ $0 }) {
                return false
            }
        }
        return true
    }
    
    private var completedWorkouts: Int {
        dataManager.workouts.filter { $0.name.contains("StrongLifts") && $0.isCompleted }.count
    }
    
    private var totalWeightLifted: Int {
        let volume = currentWorkout.reduce(0) { total, exercise in
            total + Int(exercise.weight * Double(exercise.sets * exercise.reps))
        }
        return volume
    }
}

struct ExerciseCard: View {
    let name: String
    let weight: Double
    let sets: Int
    let reps: Int
    let completedSets: [Bool]
    let onSetToggle: (Int) -> Void
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            HStack {
                VStack(alignment: .leading) {
                    Text(name)
                        .font(theme.typography.titleMedium)
                        .foregroundColor(theme.textPrimary)
                    
                    Text("\(Int(weight)) lbs × \(sets) sets × \(reps) reps")
                        .font(theme.typography.bodySmall)
                        .foregroundColor(theme.textSecondary)
                }
                
                Spacer()
                
                if completedSets.filter({ $0 }).count == sets {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.green)
                        .font(.title2)
                }
            }
            
            HStack(spacing: theme.spacing.sm) {
                ForEach(0..<sets, id: \.self) { setIndex in
                    Button {
                        onSetToggle(setIndex)
                    } label: {
                        VStack {
                            Text("Set \(setIndex + 1)")
                                .font(.caption2)
                            
                            Circle()
                                .fill(completedSets.indices.contains(setIndex) && completedSets[setIndex] ? 
                                      Color.green : theme.surfaceColor)
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Text("\(reps)")
                                        .font(theme.typography.bodyMedium)
                                        .fontWeight(.medium)
                                        .foregroundColor(completedSets.indices.contains(setIndex) && completedSets[setIndex] ? 
                                                       .white : theme.textPrimary)
                                )
                        }
                    }
                }
            }
        }
        .padding()
        .background(theme.surfaceColor)
        .cornerRadius(theme.cornerRadius.medium)
    }
}

struct WeightAdjustmentSheet: View {
    @Binding var weights: StrongLifts5x5View.StrongLiftsWeights
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    
    var body: some View {
        NavigationView {
            Form {
                Section("Workout A") {
                    WeightRow(title: "Squat", weight: $weights.squat)
                    WeightRow(title: "Bench Press", weight: $weights.benchPress)
                    WeightRow(title: "Barbell Row", weight: $weights.barbellRow)
                }
                
                Section("Workout B") {
                    WeightRow(title: "Squat", weight: $weights.squat)
                    WeightRow(title: "Overhead Press", weight: $weights.overheadPress)
                    WeightRow(title: "Deadlift", weight: $weights.deadlift)
                }
                
                Section {
                    Button("Reset to Starting Weights") {
                        weights = StrongLifts5x5View.StrongLiftsWeights()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Adjust Weights")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct WeightRow: View {
    let title: String
    @Binding var weight: Double
    @Environment(\.theme) private var theme
    
    var body: some View {
        HStack {
            Text(title)
                .font(theme.typography.bodyMedium)
            
            Spacer()
            
            HStack {
                Button {
                    if weight > 45 { weight -= 5 }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .foregroundColor(theme.primaryColor)
                }
                
                Text("\(Int(weight)) lbs")
                    .font(theme.typography.bodyMedium)
                    .frame(minWidth: 60)
                
                Button {
                    weight += 5
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(theme.primaryColor)
                }
            }
        }
    }
}