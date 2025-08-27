import SwiftUI

public struct WorkoutDetailView: View {
    let workout: WorkoutTemplateModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    @State private var showStartWorkout = false
    
    public var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: theme.spacing.lg) {
                    // Header
                    headerSection
                    
                    // Quick stats
                    quickStatsSection
                    
                    // Description
                    if let description = workout.description, !description.isEmpty {
                        descriptionSection(description)
                    }
                    
                    // Exercises preview
                    exercisesSection
                    
                    // Tags
                    if !workout.tags.isEmpty {
                        tagsSection
                    }
                    
                    // Start workout button
                    startWorkoutButton
                }
                .padding(.horizontal, theme.spacing.lg)
                .padding(.bottom, theme.spacing.xl)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Add to Favorites") {
                            // Add to favorites
                        }
                        
                        Button("Share Workout") {
                            // Share workout
                        }
                        
                        Button("Duplicate") {
                            // Duplicate workout
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundColor(theme.primaryColor)
                    }
                }
            }
        }
        .sheet(isPresented: $showStartWorkout) {
            ActiveWorkoutView(workout: workout)
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            Text(workout.name)
                .font(theme.titleLargeFont)
                .foregroundColor(theme.textPrimary)
            
            HStack(spacing: theme.spacing.md) {
                DifficultyBadge(difficulty: workout.difficulty)
                
                Text(workout.category)
                    .font(theme.bodySmallFont)
                    .foregroundColor(theme.textSecondary)
                    .padding(.horizontal, theme.spacing.sm)
                    .padding(.vertical, theme.spacing.xs)
                    .background(theme.textSecondary.opacity(0.1))
                    .cornerRadius(theme.cornerRadius.small)
                
                if workout.isPublic {
                    Text("Public")
                        .font(theme.bodySmallFont)
                        .foregroundColor(.blue)
                        .padding(.horizontal, theme.spacing.sm)
                        .padding(.vertical, theme.spacing.xs)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(theme.cornerRadius.small)
                }
                
                Spacer()
            }
        }
    }
    
    // MARK: - Quick Stats Section
    
    private var quickStatsSection: some View {
        ThemedCard {
            HStack(spacing: theme.spacing.xl) {
                StatItem(
                    icon: "clock",
                    title: "Duration",
                    value: "\(workout.estimatedDuration)m"
                )
                
                StatItem(
                    icon: "list.bullet",
                    title: "Exercises",
                    value: "\(workout.exerciseCount)"
                )
                
                StatItem(
                    icon: "flame",
                    title: "Est. Calories",
                    value: "\(estimatedCalories)"
                )
                
                Spacer()
            }
        }
    }
    
    // MARK: - Description Section
    
    private func descriptionSection(_ description: String) -> some View {
        ThemedCard {
            VStack(alignment: .leading, spacing: theme.spacing.sm) {
                Text("Description")
                    .font(theme.titleMediumFont)
                    .foregroundColor(theme.textPrimary)
                
                Text(description)
                    .font(theme.bodyMediumFont)
                    .foregroundColor(theme.textSecondary)
            }
        }
    }
    
    // MARK: - Exercises Section
    
    private var exercisesSection: some View {
        ThemedCard {
            VStack(alignment: .leading, spacing: theme.spacing.md) {
                Text("Exercises (\(workout.exerciseCount))")
                    .font(theme.titleMediumFont)
                    .foregroundColor(theme.textPrimary)
                
                // Mock exercise list for preview
                VStack(spacing: theme.spacing.sm) {
                    ForEach(mockExercises, id: \.name) { exercise in
                        HStack {
                            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                                Text("\(exercise.order). \(exercise.name)")
                                    .font(theme.bodyMediumFont)
                                    .foregroundColor(theme.textPrimary)
                                
                                Text(exercise.details)
                                    .font(theme.bodySmallFont)
                                    .foregroundColor(theme.textSecondary)
                            }
                            
                            Spacer()
                            
                            Text(exercise.muscleGroup)
                                .font(theme.bodySmallFont)
                                .foregroundColor(theme.primaryColor)
                                .padding(.horizontal, theme.spacing.sm)
                                .padding(.vertical, theme.spacing.xs)
                                .background(theme.primaryColor.opacity(0.1))
                                .cornerRadius(theme.cornerRadius.small)
                        }
                        .padding(.vertical, theme.spacing.xs)
                        
                        if exercise != mockExercises.last {
                            Divider()
                        }
                    }
                }
                
                // View all exercises button
                Button {
                    // Show full exercise list
                } label: {
                    HStack {
                        Text("View All Exercises")
                            .font(theme.bodyMediumFont)
                            .foregroundColor(theme.primaryColor)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(theme.primaryColor)
                    }
                    .padding(.top, theme.spacing.sm)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    // MARK: - Tags Section
    
    private var tagsSection: some View {
        ThemedCard {
            VStack(alignment: .leading, spacing: theme.spacing.sm) {
                Text("Tags")
                    .font(theme.titleMediumFont)
                    .foregroundColor(theme.textPrimary)
                
                LazyVGrid(
                    columns: [
                        GridItem(.adaptive(minimum: 80))
                    ],
                    spacing: theme.spacing.sm
                ) {
                    ForEach(workout.tags, id: \.self) { tag in
                        Text(tag)
                            .font(theme.bodySmallFont)
                            .foregroundColor(theme.textSecondary)
                            .padding(.horizontal, theme.spacing.sm)
                            .padding(.vertical, theme.spacing.xs)
                            .background(theme.surfaceColor)
                            .cornerRadius(theme.cornerRadius.small)
                    }
                }
            }
        }
    }
    
    // MARK: - Start Workout Button
    
    private var startWorkoutButton: some View {
        VStack(spacing: theme.spacing.md) {
            ThemedButton("Start Workout", style: .primary, size: .large) {
                showStartWorkout = true
            }
            
            if let lastPerformed = workout.lastPerformed {
                Text("Last performed \(formatLastPerformed(lastPerformed))")
                    .font(theme.bodySmallFont)
                    .foregroundColor(theme.textSecondary)
            } else {
                Text("Never performed")
                    .font(theme.bodySmallFont)
                    .foregroundColor(theme.textTertiary)
            }
        }
    }
    
    // MARK: - Helper Properties
    
    private var estimatedCalories: Int {
        // Simple estimation based on duration and intensity
        let baseCaloriesPerMinute = 8
        let difficultyMultiplier: Double = {
            switch workout.difficulty.lowercased() {
            case "beginner": return 0.8
            case "intermediate": return 1.0
            case "advanced": return 1.2
            default: return 1.0
            }
        }()
        
        return Int(Double(workout.estimatedDuration * baseCaloriesPerMinute) * difficultyMultiplier)
    }
    
    private var mockExercises: [MockExercise] {
        // Mock exercises for preview - in real app, would load from CoreData
        switch workout.category.lowercased() {
        case "strength":
            return [
                MockExercise(order: 1, name: "Bench Press", details: "3 sets × 10 reps", muscleGroup: "Chest"),
                MockExercise(order: 2, name: "Squats", details: "3 sets × 12 reps", muscleGroup: "Legs"),
                MockExercise(order: 3, name: "Deadlifts", details: "3 sets × 8 reps", muscleGroup: "Back"),
            ]
        case "cardio":
            return [
                MockExercise(order: 1, name: "Jumping Jacks", details: "45 seconds", muscleGroup: "Full Body"),
                MockExercise(order: 2, name: "Burpees", details: "30 seconds", muscleGroup: "Full Body"),
                MockExercise(order: 3, name: "High Knees", details: "45 seconds", muscleGroup: "Legs"),
            ]
        default:
            return [
                MockExercise(order: 1, name: "Exercise 1", details: "3 sets × 10 reps", muscleGroup: "General"),
                MockExercise(order: 2, name: "Exercise 2", details: "3 sets × 12 reps", muscleGroup: "General"),
            ]
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatLastPerformed(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Supporting Views

private struct StatItem: View {
    let icon: String
    let title: String
    let value: String
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(spacing: theme.spacing.xs) {
            HStack(spacing: theme.spacing.xs) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(theme.primaryColor)
                
                Text(title)
                    .font(theme.bodySmallFont)
                    .foregroundColor(theme.textSecondary)
            }
            
            Text(value)
                .font(theme.titleSmallFont)
                .foregroundColor(theme.textPrimary)
        }
    }
}

// MARK: - Supporting Types

private struct MockExercise: Equatable {
    let order: Int
    let name: String
    let details: String
    let muscleGroup: String
}

// MARK: - Active Workout View Placeholder

private struct ActiveWorkoutView: View {
    let workout: WorkoutTemplateModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Active Workout")
                    .font(theme.titleLargeFont)
                
                Text(workout.name)
                    .font(theme.titleMediumFont)
                    .foregroundColor(theme.primaryColor)
                
                Text("This would be the active workout tracking view")
                    .font(theme.bodyMediumFont)
                    .foregroundColor(theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Spacer()
                
                ThemedButton("End Workout", style: .secondary, size: .large) {
                    dismiss()
                }
                .padding(.horizontal, theme.spacing.lg)
                .padding(.bottom, theme.spacing.xl)
            }
            .navigationTitle("Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    WorkoutDetailView(
        workout: WorkoutTemplateModel(
            id: UUID().uuidString,
            name: "Upper Body Strength",
            description: "Build upper body strength with compound movements",
            category: "Strength",
            difficulty: "Intermediate",
            estimatedDuration: 45,
            exerciseCount: 8,
            tags: ["strength", "upper body", "compound"],
            lastPerformed: Date().addingTimeInterval(-3*24*3600),
            isPublic: false
        )
    )
    .theme(FitnessTheme())
}