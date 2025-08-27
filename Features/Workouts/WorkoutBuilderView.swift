import SwiftUI

public struct WorkoutBuilderView: View {
    @StateObject private var viewModel = WorkoutBuilderViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    
    public var body: some View {
        NavigationView {
            ZStack {
                theme.backgroundColor.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: theme.spacing.lg) {
                        // Basic workout info
                        basicInfoSection
                        
                        // Exercise selection
                        exercisesSection
                        
                        // Workout settings
                        settingsSection
                        
                        // Save button
                        saveButton
                    }
                    .padding(.horizontal, theme.spacing.lg)
                    .padding(.bottom, theme.spacing.xl)
                }
            }
            .navigationTitle(viewModel.isEditing ? "Edit Workout" : "Create Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await viewModel.saveWorkout()
                            dismiss()
                        }
                    }
                    .disabled(!viewModel.canSave)
                }
            }
        }
        .sheet(isPresented: $viewModel.showExerciseSelection) {
            ExerciseSelectionView { exercises in
                viewModel.addExercises(exercises)
            }
        }
        .onAppear {
            Task {
                await viewModel.loadData()
            }
        }
    }
    
    // MARK: - Basic Info Section
    
    private var basicInfoSection: some View {
        ThemedCard {
            VStack(spacing: theme.spacing.lg) {
                Text("Workout Details")
                    .font(theme.titleMediumFont)
                    .foregroundColor(theme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(spacing: theme.spacing.md) {
                    ThemedTextField(
                        "Workout Name",
                        text: $viewModel.workoutName,
                        placeholder: "Enter workout name"
                    )
                    
                    ThemedTextEditor(
                        "Description",
                        text: $viewModel.workoutDescription,
                        placeholder: "Describe your workout (optional)",
                        minHeight: 80
                    )
                    
                    HStack(spacing: theme.spacing.md) {
                        ThemedPicker(
                            "Category",
                            selection: $viewModel.selectedCategory,
                            options: WorkoutCategory.allCases
                        )
                        
                        ThemedPicker(
                            "Difficulty",
                            selection: $viewModel.selectedDifficulty,
                            options: ["Beginner", "Intermediate", "Advanced"]
                        )
                    }
                    
                    ThemedSlider(
                        "Estimated Duration",
                        value: $viewModel.estimatedDuration,
                        in: 10...120,
                        step: 5,
                        unit: " min"
                    )
                }
            }
        }
    }
    
    // MARK: - Exercises Section
    
    private var exercisesSection: some View {
        ThemedCard {
            VStack(spacing: theme.spacing.lg) {
                HStack {
                    Text("Exercises (\(viewModel.workoutExercises.count))")
                        .font(theme.titleMediumFont)
                        .foregroundColor(theme.textPrimary)
                    
                    Spacer()
                    
                    Button {
                        viewModel.showExerciseSelection = true
                    } label: {
                        HStack(spacing: theme.spacing.xs) {
                            Image(systemName: "plus")
                            Text("Add Exercise")
                        }
                        .font(theme.bodyMediumFont)
                        .foregroundColor(theme.primaryColor)
                    }
                }
                
                if viewModel.workoutExercises.isEmpty {
                    InlineEmptyStateView(
                        message: "No exercises added yet. Tap 'Add Exercise' to get started.",
                        iconName: "dumbbell"
                    )
                    .frame(height: 120)
                } else {
                    LazyVStack(spacing: theme.spacing.sm) {
                        ForEach(Array(viewModel.workoutExercises.enumerated()), id: \.offset) { index, exercise in
                            WorkoutExerciseCard(
                                exercise: exercise,
                                index: index + 1,
                                onEdit: {
                                    viewModel.editExercise(at: index)
                                },
                                onDelete: {
                                    viewModel.removeExercise(at: index)
                                },
                                onMoveUp: index > 0 ? {
                                    viewModel.moveExercise(from: index, to: index - 1)
                                } : nil,
                                onMoveDown: index < viewModel.workoutExercises.count - 1 ? {
                                    viewModel.moveExercise(from: index, to: index + 1)
                                } : nil
                            )
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Settings Section
    
    private var settingsSection: some View {
        ThemedCard {
            VStack(spacing: theme.spacing.lg) {
                Text("Workout Settings")
                    .font(theme.titleMediumFont)
                    .foregroundColor(theme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(spacing: theme.spacing.md) {
                    ThemedToggle(
                        "Make Public",
                        isOn: $viewModel.isPublic,
                        subtitle: "Allow others to use this workout"
                    )
                    
                    ThemedToggle(
                        "Rest Timer",
                        isOn: $viewModel.useRestTimer,
                        subtitle: "Show rest timer between exercises"
                    )
                    
                    if viewModel.useRestTimer {
                        ThemedSlider(
                            "Default Rest Time",
                            value: $viewModel.defaultRestTime,
                            in: 30...300,
                            step: 15,
                            unit: " sec"
                        )
                    }
                    
                    ThemedTextEditor(
                        "Tags",
                        text: $viewModel.tagsText,
                        placeholder: "Add tags separated by commas (e.g., strength, upper body, gym)",
                        minHeight: 60
                    )
                }
            }
        }
    }
    
    // MARK: - Save Button
    
    private var saveButton: some View {
        VStack(spacing: theme.spacing.sm) {
            ThemedButton(
                viewModel.isEditing ? "Update Workout" : "Create Workout",
                style: .primary,
                size: .large
            ) {
                Task {
                    await viewModel.saveWorkout()
                    dismiss()
                }
            }
            .disabled(!viewModel.canSave)
            
            if !viewModel.canSave {
                Text("Add a name and at least one exercise to save")
                    .font(theme.bodySmallFont)
                    .foregroundColor(theme.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

// MARK: - Supporting Views

private struct WorkoutExerciseCard: View {
    let exercise: WorkoutExerciseModel
    let index: Int
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onMoveUp: (() -> Void)?
    let onMoveDown: (() -> Void)?
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        ThemedCard(padding: EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)) {
            VStack(spacing: theme.spacing.sm) {
                HStack {
                    Text("\(index). \(exercise.name)")
                        .font(theme.bodyLargeFont)
                        .foregroundColor(theme.textPrimary)
                    
                    Spacer()
                    
                    Menu {
                        Button("Edit") {
                            onEdit()
                        }
                        
                        if let onMoveUp = onMoveUp {
                            Button("Move Up") {
                                onMoveUp()
                            }
                        }
                        
                        if let onMoveDown = onMoveDown {
                            Button("Move Down") {
                                onMoveDown()
                            }
                        }
                        
                        Divider()
                        
                        Button("Remove", role: .destructive) {
                            onDelete()
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundColor(theme.textSecondary)
                    }
                }
                
                HStack(spacing: theme.spacing.lg) {
                    if exercise.sets > 0 {
                        ExerciseDetailBadge(label: "Sets", value: "\(exercise.sets)")
                    }
                    
                    if exercise.reps > 0 {
                        ExerciseDetailBadge(label: "Reps", value: "\(exercise.reps)")
                    }
                    
                    if exercise.weight > 0 {
                        ExerciseDetailBadge(label: "Weight", value: "\(Int(exercise.weight)) lbs")
                    }
                    
                    if exercise.duration > 0 {
                        ExerciseDetailBadge(label: "Time", value: "\(exercise.duration)s")
                    }
                    
                    if exercise.restTime > 0 {
                        ExerciseDetailBadge(label: "Rest", value: "\(exercise.restTime)s")
                    }
                    
                    Spacer()
                }
                
                if !exercise.notes.isEmpty {
                    HStack {
                        Text(exercise.notes)
                            .font(theme.bodySmallFont)
                            .foregroundColor(theme.textSecondary)
                            .lineLimit(2)
                        Spacer()
                    }
                }
            }
        }
    }
}

private struct ExerciseDetailBadge: View {
    let label: String
    let value: String
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(theme.bodySmallFont)
                .foregroundColor(theme.textPrimary)
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(theme.textTertiary)
        }
    }
}

// MARK: - Exercise Selection View

private struct ExerciseSelectionView: View {
    let onSelection: ([ExerciseModel]) -> Void
    
    @StateObject private var viewModel = ExerciseLibraryViewModel()
    @State private var selectedExercises: Set<ExerciseModel> = []
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    
    var body: some View {
        NavigationView {
            VStack {
                // Search bar
                ThemedSearchBar(
                    text: $viewModel.searchText,
                    placeholder: "Search exercises..."
                )
                .padding(.horizontal, theme.spacing.lg)
                
                // Exercise list
                if viewModel.isLoading {
                    LoadingView(message: "Loading exercises...")
                } else {
                    ScrollView {
                        LazyVStack(spacing: theme.spacing.sm) {
                            ForEach(viewModel.filteredExercises) { exercise in
                                SelectableExerciseRow(
                                    exercise: exercise,
                                    isSelected: selectedExercises.contains(exercise)
                                ) {
                                    if selectedExercises.contains(exercise) {
                                        selectedExercises.remove(exercise)
                                    } else {
                                        selectedExercises.insert(exercise)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, theme.spacing.lg)
                        .padding(.bottom, theme.spacing.xl)
                    }
                }
                
                // Add button
                if !selectedExercises.isEmpty {
                    VStack {
                        Divider()
                        
                        ThemedButton(
                            "Add \(selectedExercises.count) Exercise\(selectedExercises.count > 1 ? "s" : "")",
                            style: .primary,
                            size: .large
                        ) {
                            onSelection(Array(selectedExercises))
                            dismiss()
                        }
                        .padding(.horizontal, theme.spacing.lg)
                        .padding(.bottom, theme.spacing.lg)
                    }
                    .background(theme.backgroundColor)
                }
            }
            .navigationTitle("Select Exercises")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Clear") {
                        selectedExercises.removeAll()
                    }
                    .disabled(selectedExercises.isEmpty)
                }
            }
        }
        .onAppear {
            Task {
                await viewModel.loadExercises()
            }
        }
    }
}

private struct SelectableExerciseRow: View {
    let exercise: ExerciseModel
    let isSelected: Bool
    let onTap: () -> Void
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: theme.spacing.md) {
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    Text(exercise.name)
                        .font(theme.bodyLargeFont)
                        .foregroundColor(theme.textPrimary)
                        .lineLimit(1)
                    
                    Text(exercise.muscleGroups.joined(separator: ", "))
                        .font(theme.bodySmallFont)
                        .foregroundColor(theme.textSecondary)
                        .lineLimit(1)
                    
                    HStack(spacing: theme.spacing.sm) {
                        DifficultyBadge(difficulty: exercise.difficulty)
                        
                        if !exercise.equipment.isEmpty {
                            EquipmentBadge(equipment: exercise.equipment.first ?? "")
                        }
                    }
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(theme.primaryColor)
                } else {
                    Image(systemName: "circle")
                        .font(.title2)
                        .foregroundColor(theme.textTertiary)
                }
            }
            .padding(theme.spacing.md)
            .background(isSelected ? theme.primaryColor.opacity(0.1) : theme.surfaceColor)
            .cornerRadius(theme.cornerRadius.medium)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

#Preview {
    WorkoutBuilderView()
        .theme(FitnessTheme())
}