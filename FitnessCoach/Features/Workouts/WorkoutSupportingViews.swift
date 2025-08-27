import SwiftUI

// MARK: - Quick Start Workout View
struct QuickStartWorkoutView: View {
    @EnvironmentObject private var dataManager: FitnessDataManager
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.theme) private var theme
    
    private let quickWorkouts = [
        ("Push-ups & Squats", "5 min bodyweight", "bodyweight"),
        ("HIIT Cardio", "15 min high intensity", "cardio"),
        ("Core Blast", "10 min abs focused", "core"),
        ("Upper Body", "20 min strength", "strength")
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Quick Start")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.top)
                    
                    Text("Select a quick workout to get started")
                        .font(.subheadline)
                        .foregroundColor(theme.textSecondary)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ForEach(Array(quickWorkouts.enumerated()), id: \.offset) { index, workout in
                            QuickWorkoutCard(
                                title: workout.0,
                                subtitle: workout.1,
                                type: workout.2
                            ) {
                                startQuickWorkout(index)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Quick Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    private func startQuickWorkout(_ index: Int) {
        // Find appropriate template or create quick workout
        if let template = dataManager.workoutTemplates.first(where: { $0.estimatedDuration <= 30 }) {
            dataManager.startWorkout(template: template)
        }
        presentationMode.wrappedValue.dismiss()
    }
}

struct QuickWorkoutCard: View {
    let title: String
    let subtitle: String
    let type: String
    let action: () -> Void
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: iconForType(type))
                    .font(.title)
                    .foregroundColor(colorForType(type))
                
                VStack(spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(theme.textPrimary)
                        .multilineTextAlignment(.center)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(height: 120)
            .frame(maxWidth: .infinity)
            .background(theme.surfaceColor)
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func iconForType(_ type: String) -> String {
        switch type {
        case "bodyweight": return "figure.strengthtraining.traditional"
        case "cardio": return "figure.run"
        case "core": return "figure.core.training"
        case "strength": return "dumbbell.fill"
        default: return "figure.mixed.cardio"
        }
    }
    
    private func colorForType(_ type: String) -> Color {
        switch type {
        case "bodyweight": return .blue
        case "cardio": return .red
        case "core": return .orange
        case "strength": return .purple
        default: return .gray
        }
    }
}

// MARK: - Exercise Filters Sheet
struct ExerciseFiltersSheet: View {
    @Binding var selectedCategory: Exercise.ExerciseCategory?
    @Binding var selectedEquipment: Exercise.Equipment?
    
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.theme) private var theme
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Category Filter
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Category")
                            .font(.headline)
                            .foregroundColor(theme.textPrimary)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            ForEach(Exercise.ExerciseCategory.allCases, id: \.self) { category in
                                FilterOptionButton(
                                    title: category.rawValue,
                                    icon: category.icon,
                                    isSelected: selectedCategory == category
                                ) {
                                    selectedCategory = selectedCategory == category ? nil : category
                                }
                            }
                        }
                    }
                    
                    // Equipment Filter
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Equipment")
                            .font(.headline)
                            .foregroundColor(theme.textPrimary)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            ForEach(Exercise.Equipment.allCases, id: \.self) { equipment in
                                FilterOptionButton(
                                    title: equipment.rawValue,
                                    icon: "dumbbell.fill",
                                    isSelected: selectedEquipment == equipment
                                ) {
                                    selectedEquipment = selectedEquipment == equipment ? nil : equipment
                                }
                            }
                        }
                    }
                    
                    // Clear All Button
                    Button("Clear All Filters") {
                        selectedCategory = nil
                        selectedEquipment = nil
                    }
                    .font(.subheadline)
                    .foregroundColor(theme.primaryColor)
                    .padding()
                    .background(theme.primaryColor.opacity(0.1))
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

struct FilterOptionButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : theme.primaryColor)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : theme.textPrimary)
                    .multilineTextAlignment(.center)
            }
            .frame(height: 80)
            .frame(maxWidth: .infinity)
            .background(isSelected ? theme.primaryColor : theme.surfaceColor)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Exercise Detail View
struct ExerciseDetailView: View {
    let exercise: Exercise
    
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.theme) private var theme
    @EnvironmentObject private var dataManager: FitnessDataManager
    
    @State private var showingAddToWorkout = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 12) {
                        Text(exercise.name)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(theme.textPrimary)
                        
                        HStack(spacing: 16) {
                            InfoChip(text: exercise.category.rawValue, color: .blue)
                            InfoChip(text: exercise.equipment.rawValue, color: .orange)
                            InfoChip(text: exercise.difficulty.rawValue, color: difficultyColor)
                        }
                    }
                    
                    // Muscle Groups
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Target Muscles")
                            .font(.headline)
                            .foregroundColor(theme.textPrimary)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 8) {
                            ForEach(exercise.muscleGroups, id: \.self) { muscle in
                                Text(muscle.rawValue.capitalized)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(theme.primaryColor)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(theme.primaryColor.opacity(0.1))
                                    .cornerRadius(12)
                            }
                        }
                    }
                    
                    // Instructions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Instructions")
                            .font(.headline)
                            .foregroundColor(theme.textPrimary)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(Array(exercise.instructions.enumerated()), id: \.offset) { index, instruction in
                                HStack(alignment: .top, spacing: 12) {
                                    Text("\(index + 1)")
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .frame(width: 24, height: 24)
                                        .background(theme.primaryColor)
                                        .cornerRadius(12)
                                    
                                    Text(instruction)
                                        .font(.subheadline)
                                        .foregroundColor(theme.textPrimary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    }
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        Button("Add to Workout") {
                            showingAddToWorkout = true
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(theme.primaryColor)
                        .cornerRadius(12)
                        
                        Button("Start Quick Set") {
                            // Quick single exercise workout
                            presentationMode.wrappedValue.dismiss()
                        }
                        .font(.subheadline)
                        .foregroundColor(theme.primaryColor)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(theme.primaryColor.opacity(0.1))
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dataManager.toggleExerciseFavorite(exercise.id)
                    } label: {
                        Image(systemName: exercise.isFavorite ? "heart.fill" : "heart")
                            .foregroundColor(exercise.isFavorite ? .red : theme.textPrimary)
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddToWorkout) {
            AddExerciseToWorkoutSheet(exercise: exercise)
        }
    }
    
    private var difficultyColor: Color {
        switch exercise.difficulty {
        case .beginner: return .green
        case .intermediate: return .orange
        case .advanced: return .red
        }
    }
}

struct InfoChip: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(color)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(color.opacity(0.1))
            .cornerRadius(12)
    }
}

// MARK: - Add Exercise to Workout Sheet
struct AddExerciseToWorkoutSheet: View {
    let exercise: Exercise
    
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.theme) private var theme
    
    @State private var sets: String = "3"
    @State private var reps: String = "12"
    @State private var weight: String = ""
    @State private var restTime: String = "60"
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(exercise.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(theme.textPrimary)
                    
                    Text("Configure exercise parameters")
                        .font(.subheadline)
                        .foregroundColor(theme.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(spacing: 20) {
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Sets")
                                .font(.headline)
                            TextField("Sets", text: $sets)
                                .keyboardType(.numberPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Reps")
                                .font(.headline)
                            TextField("Reps", text: $reps)
                                .keyboardType(.numberPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    }
                    
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Weight (lbs)")
                                .font(.headline)
                            TextField("Optional", text: $weight)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Rest (sec)")
                                .font(.headline)
                            TextField("Rest time", text: $restTime)
                                .keyboardType(.numberPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    }
                }
                
                Spacer()
                
                Button("Add to Workout Builder") {
                    // Add to workout builder
                    presentationMode.wrappedValue.dismiss()
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(theme.primaryColor)
                .cornerRadius(12)
            }
            .padding()
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Workout Template Detail View
struct WorkoutTemplateDetailView: View {
    let template: WorkoutTemplate
    
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.theme) private var theme
    @EnvironmentObject private var dataManager: FitnessDataManager
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 12) {
                        Text(template.name)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(theme.textPrimary)
                        
                        Text(template.description)
                            .font(.subheadline)
                            .foregroundColor(theme.textSecondary)
                        
                        HStack(spacing: 16) {
                            InfoChip(text: "\(template.estimatedDuration)m", color: .blue)
                            InfoChip(text: template.difficulty.rawValue, color: .orange)
                            InfoChip(text: template.category.rawValue, color: .purple)
                        }
                    }
                    
                    // Equipment Needed
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Equipment Needed")
                            .font(.headline)
                            .foregroundColor(theme.textPrimary)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 8) {
                            ForEach(template.equipment, id: \.self) { equipment in
                                Text(equipment.rawValue)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(theme.primaryColor)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(theme.primaryColor.opacity(0.1))
                                    .cornerRadius(12)
                            }
                        }
                    }
                    
                    // Exercise List
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Exercises (\(template.exercises.count))")
                            .font(.headline)
                            .foregroundColor(theme.textPrimary)
                        
                        VStack(spacing: 8) {
                            ForEach(Array(template.exercises.enumerated()), id: \.offset) { index, exercise in
                                WorkoutExerciseRow(exercise: exercise, index: index + 1)
                            }
                        }
                    }
                    
                    // Start Workout Button
                    Button("Start This Workout") {
                        dataManager.startWorkout(template: template)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(theme.primaryColor)
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        // Toggle favorite
                    } label: {
                        Image(systemName: template.isFavorite ? "heart.fill" : "heart")
                            .foregroundColor(template.isFavorite ? .red : theme.textPrimary)
                    }
                }
            }
        }
    }
}

struct WorkoutExerciseRow: View {
    let exercise: WorkoutExercise
    let index: Int
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        HStack(spacing: 12) {
            Text("\(index)")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(theme.primaryColor)
                .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.exerciseName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(theme.textPrimary)
                
                HStack(spacing: 12) {
                    Text("\(exercise.sets) sets")
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)
                    
                    if let reps = exercise.reps {
                        Text("\(reps.min)-\(reps.max) reps")
                            .font(.caption)
                            .foregroundColor(theme.textSecondary)
                    }
                    
                    if let weight = exercise.weight {
                        Text("\(Int(weight)) lbs")
                            .font(.caption)
                            .foregroundColor(theme.textSecondary)
                    }
                    
                    Text("\(exercise.restTime)s rest")
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(theme.surfaceColor)
        .cornerRadius(12)
    }
}

// MARK: - Workout Session Detail View
struct WorkoutSessionDetailView: View {
    let session: WorkoutSession
    
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.theme) private var theme
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header Stats
                    VStack(alignment: .leading, spacing: 16) {
                        Text(session.templateName)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(theme.textPrimary)
                        
                        HStack(spacing: 20) {
                            StatColumn(title: "Duration", value: formatDuration(session.duration))
                            
                            if let calories = session.totalCaloriesBurned {
                                StatColumn(title: "Calories", value: "\(Int(calories))")
                            }
                            
                            StatColumn(title: "Exercises", value: "\(session.completedExercises.count)")
                            
                            if let rating = session.rating {
                                StatColumn(title: "Rating", value: "\(rating)/5")
                            }
                        }
                        .padding()
                        .background(theme.surfaceColor)
                        .cornerRadius(16)
                    }
                    
                    // Exercise Details
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Exercises Completed")
                            .font(.headline)
                            .foregroundColor(theme.textPrimary)
                        
                        VStack(spacing: 12) {
                            ForEach(session.completedExercises, id: \.id) { exercise in
                                CompletedExerciseCard(exercise: exercise)
                            }
                        }
                    }
                    
                    // Notes
                    if let notes = session.notes, !notes.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes")
                                .font(.headline)
                                .foregroundColor(theme.textPrimary)
                            
                            Text(notes)
                                .font(.subheadline)
                                .foregroundColor(theme.textSecondary)
                                .padding()
                                .background(theme.surfaceColor)
                                .cornerRadius(12)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle(DateFormatter.dayMonthFormatter.string(from: session.startTime))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        return "\(minutes)m"
    }
}

struct StatColumn: View {
    let title: String
    let value: String
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(theme.textPrimary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(theme.textSecondary)
        }
    }
}

struct CompletedExerciseCard: View {
    let exercise: CompletedExercise
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(exercise.exerciseName)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(theme.textPrimary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(exercise.completedSets, id: \.id) { set in
                    VStack(spacing: 2) {
                        Text("Set \(set.setNumber)")
                            .font(.caption2)
                            .foregroundColor(theme.textTertiary)
                        
                        if let reps = set.reps {
                            Text("\(reps)")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(theme.textPrimary)
                        }
                        
                        if let weight = set.weight {
                            Text("\(Int(weight))lb")
                                .font(.caption2)
                                .foregroundColor(theme.textSecondary)
                        }
                    }
                    .padding(8)
                    .background(theme.surfaceColor)
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(theme.surfaceColor.opacity(0.5))
        .cornerRadius(12)
    }
}

// MARK: - Date Formatter Extension
extension DateFormatter {
    static let dayMonthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()
}

#Preview {
    QuickStartWorkoutView()
        .environmentObject(FitnessDataManager.shared)
        .environmentObject(ThemeManager())
        .theme(FitnessTheme())
}