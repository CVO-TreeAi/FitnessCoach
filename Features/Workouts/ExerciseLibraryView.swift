import SwiftUI

public struct ExerciseLibraryView: View {
    @StateObject private var viewModel = ExerciseLibraryViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    
    public var body: some View {
        NavigationView {
            ZStack {
                theme.backgroundColor.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search and filter section
                    VStack(spacing: theme.spacing.md) {
                        ThemedSearchBar(
                            text: $viewModel.searchText,
                            placeholder: "Search exercises..."
                        )
                        
                        // Category filter
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: theme.spacing.sm) {
                                CategoryChip(
                                    title: "All",
                                    isSelected: viewModel.selectedCategory == nil
                                ) {
                                    viewModel.selectedCategory = nil
                                }
                                
                                ForEach(ExerciseCategory.allCases, id: \.self) { category in
                                    CategoryChip(
                                        title: category.displayName,
                                        isSelected: viewModel.selectedCategory == category
                                    ) {
                                        viewModel.selectedCategory = category
                                    }
                                }
                            }
                            .padding(.horizontal, theme.spacing.lg)
                        }
                        
                        // Difficulty and equipment filters
                        HStack(spacing: theme.spacing.md) {
                            Menu {
                                Button("All Difficulties") {
                                    viewModel.selectedDifficulty = nil
                                }
                                Divider()
                                ForEach(ExerciseDifficulty.allCases, id: \.self) { difficulty in
                                    Button(difficulty.displayName) {
                                        viewModel.selectedDifficulty = difficulty
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(viewModel.selectedDifficulty?.displayName ?? "All Difficulties")
                                        .font(theme.bodySmallFont)
                                        .foregroundColor(theme.textPrimary)
                                    Image(systemName: "chevron.down")
                                        .font(.caption)
                                        .foregroundColor(theme.textSecondary)
                                }
                                .padding(.horizontal, theme.spacing.md)
                                .padding(.vertical, theme.spacing.sm)
                                .background(theme.surfaceColor)
                                .cornerRadius(theme.cornerRadius.medium)
                            }
                            
                            Menu {
                                Button("All Equipment") {
                                    viewModel.selectedEquipment = nil
                                }
                                Divider()
                                ForEach(Equipment.allCases, id: \.self) { equipment in
                                    Button(equipment.displayName) {
                                        viewModel.selectedEquipment = equipment
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(viewModel.selectedEquipment?.displayName ?? "All Equipment")
                                        .font(theme.bodySmallFont)
                                        .foregroundColor(theme.textPrimary)
                                    Image(systemName: "chevron.down")
                                        .font(.caption)
                                        .foregroundColor(theme.textSecondary)
                                }
                                .padding(.horizontal, theme.spacing.md)
                                .padding(.vertical, theme.spacing.sm)
                                .background(theme.surfaceColor)
                                .cornerRadius(theme.cornerRadius.medium)
                            }
                            
                            Spacer()
                        }
                    }
                    .padding(.horizontal, theme.spacing.lg)
                    .padding(.bottom, theme.spacing.md)
                    
                    // Exercise list
                    if viewModel.isLoading {
                        LoadingView(message: "Loading exercises...")
                    } else if viewModel.filteredExercises.isEmpty {
                        EmptyStateView(
                            title: "No Exercises Found",
                            message: viewModel.searchText.isEmpty ? 
                                "No exercises available in the selected category" :
                                "No exercises match your search criteria",
                            iconName: "magnifyingglass",
                            actionTitle: "Clear Filters"
                        ) {
                            viewModel.clearFilters()
                        }
                    } else {
                        ScrollView {
                            LazyVStack(spacing: theme.spacing.sm) {
                                ForEach(viewModel.filteredExercises) { exercise in
                                    ExerciseListRow(
                                        name: exercise.name,
                                        category: exercise.category,
                                        muscleGroups: exercise.muscleGroups,
                                        difficulty: exercise.difficulty,
                                        equipment: exercise.equipment
                                    ) {
                                        viewModel.selectedExercise = exercise
                                    }
                                }
                            }
                            .padding(.horizontal, theme.spacing.lg)
                            .padding(.bottom, theme.spacing.xl)
                        }
                    }
                }
            }
            .navigationTitle("Exercise Library")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Section("Sort By") {
                            Button("Name") {
                                viewModel.sortBy = .name
                            }
                            Button("Category") {
                                viewModel.sortBy = .category
                            }
                            Button("Difficulty") {
                                viewModel.sortBy = .difficulty
                            }
                        }
                        
                        Section("Muscle Groups") {
                            ForEach(MuscleGroup.allCases, id: \.self) { muscle in
                                Button(muscle.displayName) {
                                    viewModel.selectedMuscleGroup = muscle
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(theme.primaryColor)
                    }
                }
            }
        }
        .sheet(item: $viewModel.selectedExercise) { exercise in
            ExerciseDetailView(exercise: exercise)
        }
        .onAppear {
            Task {
                await viewModel.loadExercises()
            }
        }
    }
}

// MARK: - Supporting Views

private struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(theme.bodySmallFont)
                .foregroundColor(isSelected ? .white : theme.textPrimary)
                .padding(.horizontal, theme.spacing.md)
                .padding(.vertical, theme.spacing.sm)
                .background(isSelected ? theme.primaryColor : theme.surfaceColor)
                .cornerRadius(theme.cornerRadius.large)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Exercise Detail View

private struct ExerciseDetailView: View {
    let exercise: ExerciseModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: theme.spacing.lg) {
                    // Header
                    VStack(alignment: .leading, spacing: theme.spacing.md) {
                        Text(exercise.name)
                            .font(theme.titleLargeFont)
                            .foregroundColor(theme.textPrimary)
                        
                        HStack(spacing: theme.spacing.md) {
                            DifficultyBadge(difficulty: exercise.difficulty)
                            
                            ForEach(exercise.equipment.prefix(2), id: \.self) { equipment in
                                EquipmentBadge(equipment: equipment)
                            }
                        }
                    }
                    
                    // Muscle groups
                    VStack(alignment: .leading, spacing: theme.spacing.sm) {
                        Text("Muscle Groups")
                            .font(theme.titleSmallFont)
                            .foregroundColor(theme.textPrimary)
                        
                        LazyVGrid(
                            columns: [
                                GridItem(.adaptive(minimum: 100))
                            ],
                            spacing: theme.spacing.sm
                        ) {
                            ForEach(exercise.muscleGroups, id: \.self) { muscle in
                                Text(muscle)
                                    .font(theme.bodySmallFont)
                                    .foregroundColor(theme.textSecondary)
                                    .padding(.horizontal, theme.spacing.sm)
                                    .padding(.vertical, theme.spacing.xs)
                                    .background(theme.primaryColor.opacity(0.1))
                                    .cornerRadius(theme.cornerRadius.small)
                            }
                        }
                    }
                    
                    // Instructions
                    if let instructions = exercise.instructions, !instructions.isEmpty {
                        VStack(alignment: .leading, spacing: theme.spacing.sm) {
                            Text("Instructions")
                                .font(theme.titleSmallFont)
                                .foregroundColor(theme.textPrimary)
                            
                            Text(instructions)
                                .font(theme.bodyMediumFont)
                                .foregroundColor(theme.textSecondary)
                        }
                    }
                    
                    // Equipment needed
                    if !exercise.equipment.isEmpty {
                        VStack(alignment: .leading, spacing: theme.spacing.sm) {
                            Text("Equipment Needed")
                                .font(theme.titleSmallFont)
                                .foregroundColor(theme.textPrimary)
                            
                            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                                ForEach(exercise.equipment, id: \.self) { equipment in
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                        Text(equipment)
                                            .font(theme.bodyMediumFont)
                                            .foregroundColor(theme.textSecondary)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Add to workout button
                    ThemedButton("Add to Workout", style: .primary, size: .large) {
                        // Add exercise to current workout or favorites
                        dismiss()
                    }
                    .padding(.top, theme.spacing.lg)
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
                    Button {
                        // Add to favorites
                    } label: {
                        Image(systemName: "heart")
                            .foregroundColor(theme.primaryColor)
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Types

public enum ExerciseCategory: String, CaseIterable {
    case chest = "Chest"
    case back = "Back"
    case shoulders = "Shoulders"
    case arms = "Arms"
    case legs = "Legs"
    case core = "Core"
    case cardio = "Cardio"
    case fullBody = "Full Body"
    
    public var displayName: String {
        return rawValue
    }
}

public enum ExerciseDifficulty: String, CaseIterable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
    
    public var displayName: String {
        return rawValue
    }
}

public enum Equipment: String, CaseIterable {
    case bodyweight = "Bodyweight"
    case dumbbells = "Dumbbells"
    case barbell = "Barbell"
    case kettlebell = "Kettlebell"
    case resistanceBands = "Resistance Bands"
    case pullupBar = "Pull-up Bar"
    case bench = "Bench"
    case machine = "Machine"
    case cable = "Cable"
    case medicine = "Medicine Ball"
    
    public var displayName: String {
        return rawValue
    }
}

public enum MuscleGroup: String, CaseIterable {
    case chest = "Chest"
    case back = "Back"
    case shoulders = "Shoulders"
    case biceps = "Biceps"
    case triceps = "Triceps"
    case forearms = "Forearms"
    case quadriceps = "Quadriceps"
    case hamstrings = "Hamstrings"
    case glutes = "Glutes"
    case calves = "Calves"
    case core = "Core"
    case traps = "Traps"
    case lats = "Lats"
    
    public var displayName: String {
        return rawValue
    }
}

// MARK: - Preview

#Preview {
    ExerciseLibraryView()
        .theme(FitnessTheme())
}