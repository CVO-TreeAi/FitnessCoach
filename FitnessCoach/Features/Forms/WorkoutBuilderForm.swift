import SwiftUI

struct WorkoutBuilderForm: View {
    @Binding var isPresented: Bool
    @State private var workoutName = ""
    @State private var category = "Full Body"
    @State private var exercises: [(name: String, sets: Int, reps: Int, rest: Int)] = []
    @State private var showingAddExercise = false
    @Environment(\.theme) private var theme
    
    let categories = ["Full Body", "Upper Body", "Lower Body", "Core", "Cardio", "HIIT", "Yoga", "Custom"]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: theme.spacing.lg) {
                    // Workout name
                    VStack(alignment: .leading, spacing: theme.spacing.sm) {
                        Text("Workout Name")
                            .font(theme.typography.titleMedium)
                            .foregroundColor(theme.textPrimary)
                        
                        TextField("Enter workout name", text: $workoutName)
                            .font(theme.typography.bodyMedium)
                            .padding()
                            .background(theme.surfaceColor)
                            .cornerRadius(theme.cornerRadius.medium)
                    }
                    
                    // Category picker
                    VStack(alignment: .leading, spacing: theme.spacing.sm) {
                        Text("Category")
                            .font(theme.typography.titleMedium)
                            .foregroundColor(theme.textPrimary)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: theme.spacing.sm) {
                                ForEach(categories, id: \.self) { cat in
                                    Button {
                                        category = cat
                                    } label: {
                                        Text(cat)
                                            .font(theme.typography.bodySmall)
                                            .foregroundColor(category == cat ? .white : theme.textPrimary)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(
                                                category == cat ?
                                                theme.primaryColor : theme.surfaceColor
                                            )
                                            .cornerRadius(theme.cornerRadius.small)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Exercises list
                    VStack(alignment: .leading, spacing: theme.spacing.md) {
                        HStack {
                            Text("Exercises")
                                .font(theme.typography.titleMedium)
                                .foregroundColor(theme.textPrimary)
                            
                            Spacer()
                            
                            Button {
                                showingAddExercise = true
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(theme.primaryColor)
                            }
                        }
                        
                        if exercises.isEmpty {
                            VStack(spacing: theme.spacing.md) {
                                Image(systemName: "figure.strengthtraining.traditional")
                                    .font(.system(size: 40))
                                    .foregroundColor(theme.textTertiary)
                                
                                Text("No exercises added yet")
                                    .font(theme.typography.bodyMedium)
                                    .foregroundColor(theme.textSecondary)
                                
                                Button {
                                    showingAddExercise = true
                                } label: {
                                    Text("Add First Exercise")
                                        .font(theme.typography.bodySmall)
                                        .foregroundColor(theme.primaryColor)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(theme.spacing.xl)
                            .background(theme.surfaceColor)
                            .cornerRadius(theme.cornerRadius.medium)
                        } else {
                            ForEach(Array(exercises.enumerated()), id: \.offset) { index, exercise in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(exercise.name)
                                            .font(theme.typography.bodyMedium)
                                            .foregroundColor(theme.textPrimary)
                                        
                                        Text("\(exercise.sets) sets × \(exercise.reps) reps • \(exercise.rest)s rest")
                                            .font(theme.typography.bodySmall)
                                            .foregroundColor(theme.textSecondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Button {
                                        exercises.remove(at: index)
                                    } label: {
                                        Image(systemName: "trash")
                                            .foregroundColor(theme.errorColor)
                                    }
                                }
                                .padding()
                                .background(theme.surfaceColor)
                                .cornerRadius(theme.cornerRadius.medium)
                            }
                        }
                    }
                    
                    // Duration estimate
                    if !exercises.isEmpty {
                        HStack {
                            Image(systemName: "clock")
                                .foregroundColor(theme.primaryColor)
                            Text("Estimated Duration: \(estimatedDuration) minutes")
                                .font(theme.typography.bodyMedium)
                                .foregroundColor(theme.textSecondary)
                        }
                        .padding()
                        .background(theme.surfaceColor)
                        .cornerRadius(theme.cornerRadius.medium)
                    }
                    
                    // Save button
                    Button {
                        // Save workout logic
                        isPresented = false
                    } label: {
                        Text("Save Workout")
                            .font(theme.typography.bodyMedium)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(!workoutName.isEmpty && !exercises.isEmpty ? theme.primaryColor : theme.textTertiary)
                            .cornerRadius(theme.cornerRadius.medium)
                    }
                    .disabled(workoutName.isEmpty || exercises.isEmpty)
                }
                .padding()
            }
            .navigationTitle("Create Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
            .sheet(isPresented: $showingAddExercise) {
                AddExerciseSheet(isPresented: $showingAddExercise) { name, sets, reps, rest in
                    exercises.append((name: name, sets: sets, reps: reps, rest: rest))
                }
            }
        }
    }
    
    var estimatedDuration: Int {
        let totalSets = exercises.reduce(0) { $0 + $1.sets }
        let avgTimePerSet = 45 // seconds
        let totalRestTime = exercises.reduce(0) { $0 + ($1.sets - 1) * $1.rest }
        return (totalSets * avgTimePerSet + totalRestTime) / 60
    }
}

struct AddExerciseSheet: View {
    @Binding var isPresented: Bool
    let onSave: (String, Int, Int, Int) -> Void
    
    @State private var exerciseName = ""
    @State private var sets = 3
    @State private var reps = 12
    @State private var restSeconds = 60
    @Environment(\.theme) private var theme
    
    let commonExercises = [
        "Push-ups", "Pull-ups", "Squats", "Lunges", "Plank",
        "Burpees", "Deadlifts", "Bench Press", "Rows", "Shoulder Press"
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: theme.spacing.lg) {
                    // Exercise name
                    VStack(alignment: .leading, spacing: theme.spacing.sm) {
                        Text("Exercise Name")
                            .font(theme.typography.titleMedium)
                            .foregroundColor(theme.textPrimary)
                        
                        TextField("Enter exercise name", text: $exerciseName)
                            .font(theme.typography.bodyMedium)
                            .padding()
                            .background(theme.surfaceColor)
                            .cornerRadius(theme.cornerRadius.medium)
                        
                        // Quick select
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: theme.spacing.sm) {
                                ForEach(commonExercises, id: \.self) { exercise in
                                    Button {
                                        exerciseName = exercise
                                    } label: {
                                        Text(exercise)
                                            .font(theme.typography.bodySmall)
                                            .foregroundColor(theme.primaryColor)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(theme.primaryColor.opacity(0.1))
                                            .cornerRadius(theme.cornerRadius.small)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Sets and reps
                    HStack(spacing: theme.spacing.md) {
                        VStack(alignment: .leading, spacing: theme.spacing.sm) {
                            Text("Sets")
                                .font(theme.typography.bodyMedium)
                                .foregroundColor(theme.textPrimary)
                            
                            HStack {
                                Button {
                                    if sets > 1 { sets -= 1 }
                                } label: {
                                    Image(systemName: "minus.circle")
                                        .foregroundColor(theme.primaryColor)
                                }
                                
                                Text("\(sets)")
                                    .font(theme.typography.titleMedium)
                                    .frame(minWidth: 40)
                                
                                Button {
                                    sets += 1
                                } label: {
                                    Image(systemName: "plus.circle")
                                        .foregroundColor(theme.primaryColor)
                                }
                            }
                            .padding()
                            .background(theme.surfaceColor)
                            .cornerRadius(theme.cornerRadius.medium)
                        }
                        
                        VStack(alignment: .leading, spacing: theme.spacing.sm) {
                            Text("Reps")
                                .font(theme.typography.bodyMedium)
                                .foregroundColor(theme.textPrimary)
                            
                            HStack {
                                Button {
                                    if reps > 1 { reps -= 1 }
                                } label: {
                                    Image(systemName: "minus.circle")
                                        .foregroundColor(theme.primaryColor)
                                }
                                
                                Text("\(reps)")
                                    .font(theme.typography.titleMedium)
                                    .frame(minWidth: 40)
                                
                                Button {
                                    reps += 1
                                } label: {
                                    Image(systemName: "plus.circle")
                                        .foregroundColor(theme.primaryColor)
                                }
                            }
                            .padding()
                            .background(theme.surfaceColor)
                            .cornerRadius(theme.cornerRadius.medium)
                        }
                    }
                    
                    // Rest time
                    VStack(alignment: .leading, spacing: theme.spacing.sm) {
                        Text("Rest Between Sets")
                            .font(theme.typography.bodyMedium)
                            .foregroundColor(theme.textPrimary)
                        
                        HStack {
                            Button {
                                if restSeconds > 15 { restSeconds -= 15 }
                            } label: {
                                Image(systemName: "minus.circle")
                                    .foregroundColor(theme.primaryColor)
                            }
                            
                            Text("\(restSeconds) seconds")
                                .font(theme.typography.titleMedium)
                                .frame(minWidth: 100)
                            
                            Button {
                                restSeconds += 15
                            } label: {
                                Image(systemName: "plus.circle")
                                    .foregroundColor(theme.primaryColor)
                            }
                        }
                        .padding()
                        .background(theme.surfaceColor)
                        .cornerRadius(theme.cornerRadius.medium)
                    }
                    
                    // Add button
                    Button {
                        onSave(exerciseName, sets, reps, restSeconds)
                        isPresented = false
                    } label: {
                        Text("Add Exercise")
                            .font(theme.typography.bodyMedium)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(!exerciseName.isEmpty ? theme.primaryColor : theme.textTertiary)
                            .cornerRadius(theme.cornerRadius.medium)
                    }
                    .disabled(exerciseName.isEmpty)
                }
                .padding()
            }
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
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