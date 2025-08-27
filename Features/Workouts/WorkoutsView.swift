import SwiftUI

public struct WorkoutsView: View {
    @StateObject private var viewModel = WorkoutsViewModel()
    @EnvironmentObject private var authManager: AuthenticationManager
    @Environment(\.theme) private var theme
    
    public var body: some View {
        NavigationView {
            ZStack {
                theme.backgroundColor.ignoresSafeArea()
                
                if viewModel.isLoading {
                    LoadingView(message: "Loading workouts...")
                } else {
                    ScrollView {
                        LazyVStack(spacing: theme.spacing.lg) {
                            // Search bar
                            searchSection
                            
                            // Quick actions
                            quickActionsSection
                            
                            // Active workout
                            if let activeWorkout = viewModel.activeWorkout {
                                activeWorkoutSection(activeWorkout)
                            }
                            
                            // Categories filter
                            categoriesSection
                            
                            // Workout templates
                            workoutTemplatesSection
                            
                            // Recent workouts
                            recentWorkoutsSection
                        }
                        .padding(.horizontal, theme.spacing.lg)
                        .padding(.bottom, theme.spacing.xl)
                    }
                    .refreshable {
                        await viewModel.refresh()
                    }
                }
                
                // Floating action button for coaches
                if authManager.hasPermission(.createPrograms) {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            
                            Button {
                                viewModel.showCreateWorkout = true
                            } label: {
                                Image(systemName: "plus")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .frame(width: 56, height: 56)
                                    .background(theme.primaryColor)
                                    .clipShape(Circle())
                                    .shadow(radius: 4)
                            }
                            .padding(.trailing, theme.spacing.lg)
                            .padding(.bottom, theme.spacing.xl)
                        }
                    }
                }
            }
            .navigationTitle("Workouts")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("All Categories") {
                            viewModel.selectedCategory = nil
                        }
                        
                        Divider()
                        
                        ForEach(WorkoutCategory.allCases, id: \.self) { category in
                            Button(category.displayName) {
                                viewModel.selectedCategory = category
                            }
                        }
                    } label: {
                        Image(systemName: "line.horizontal.3.decrease")
                            .foregroundColor(theme.primaryColor)
                    }
                }
            }
        }
        .sheet(isPresented: $viewModel.showCreateWorkout) {
            WorkoutBuilderView()
        }
        .sheet(item: $viewModel.selectedWorkout) { workout in
            WorkoutDetailView(workout: workout)
        }
        .sheet(isPresented: $viewModel.showExerciseLibrary) {
            ExerciseLibraryView()
        }
        .onAppear {
            Task {
                await viewModel.loadData()
            }
        }
    }
    
    // MARK: - Search Section
    
    private var searchSection: some View {
        ThemedSearchBar(
            text: $viewModel.searchText,
            placeholder: "Search workouts..."
        ) {
            Task {
                await viewModel.performSearch()
            }
        }
    }
    
    // MARK: - Quick Actions Section
    
    private var quickActionsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: theme.spacing.md) {
                QuickActionCard(
                    title: "Start Quick Workout",
                    icon: "play.circle.fill",
                    color: .green
                ) {
                    viewModel.startQuickWorkout()
                }
                
                QuickActionCard(
                    title: "Exercise Library",
                    icon: "books.vertical.fill",
                    color: theme.primaryColor
                ) {
                    viewModel.showExerciseLibrary = true
                }
                
                QuickActionCard(
                    title: "Custom Workout",
                    icon: "plus.circle.fill",
                    color: .orange
                ) {
                    viewModel.showCreateWorkout = true
                }
                
                if authManager.hasPermission(.createPrograms) {
                    QuickActionCard(
                        title: "Templates",
                        icon: "doc.text.fill",
                        color: .purple
                    ) {
                        // Navigate to templates
                    }
                }
            }
            .padding(.horizontal, theme.spacing.lg)
        }
    }
    
    // MARK: - Active Workout Section
    
    private func activeWorkoutSection(_ workout: ActiveWorkout) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            SectionHeader(
                "Active Workout",
                subtitle: "In progress"
            )
            
            ActiveWorkoutCard(workout: workout) {
                viewModel.resumeWorkout()
            }
        }
    }
    
    // MARK: - Categories Section
    
    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            SectionHeader("Categories")
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: theme.spacing.sm) {
                    CategoryChip(
                        title: "All",
                        isSelected: viewModel.selectedCategory == nil
                    ) {
                        viewModel.selectedCategory = nil
                    }
                    
                    ForEach(WorkoutCategory.allCases, id: \.self) { category in
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
        }
    }
    
    // MARK: - Workout Templates Section
    
    private var workoutTemplatesSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            SectionHeader(
                "Workout Templates",
                subtitle: "\(viewModel.filteredWorkouts.count) workouts",
                actionTitle: "See All"
            ) {
                // Navigate to all workouts
            }
            
            if viewModel.filteredWorkouts.isEmpty {
                InlineEmptyStateView(
                    message: viewModel.searchText.isEmpty ? "No workouts available" : "No workouts match your search",
                    iconName: "figure.strengthtraining.traditional"
                )
            } else {
                LazyVStack(spacing: theme.spacing.sm) {
                    ForEach(viewModel.filteredWorkouts.prefix(5)) { workout in
                        WorkoutListRow(
                            name: workout.name,
                            description: workout.description,
                            difficulty: workout.difficulty,
                            duration: workout.estimatedDuration,
                            exercises: workout.exerciseCount,
                            lastPerformed: workout.lastPerformed
                        ) {
                            viewModel.selectedWorkout = workout
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Recent Workouts Section
    
    private var recentWorkoutsSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            SectionHeader(
                "Recent Workouts",
                subtitle: "Your workout history",
                actionTitle: "View All"
            ) {
                // Navigate to workout history
            }
            
            if viewModel.recentWorkouts.isEmpty {
                InlineEmptyStateView(
                    message: "No recent workouts. Start your first workout!",
                    iconName: "clock.arrow.circlepath"
                )
            } else {
                LazyVStack(spacing: theme.spacing.sm) {
                    ForEach(viewModel.recentWorkouts.prefix(3)) { workout in
                        RecentWorkoutCard(workout: workout) {
                            viewModel.repeatWorkout(workout)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Views

private struct QuickActionCard: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: theme.spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
                
                Text(title)
                    .font(theme.bodySmallFont)
                    .foregroundColor(theme.textPrimary)
                    .multilineTextAlignment(.center)
            }
            .frame(width: 100, height: 80)
            .background(theme.surfaceColor)
            .cornerRadius(theme.cornerRadius.medium)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

private struct ActiveWorkoutCard: View {
    let workout: ActiveWorkout
    let onResume: () -> Void
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        ThemedCard {
            VStack(spacing: theme.spacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: theme.spacing.xs) {
                        Text(workout.name)
                            .font(theme.titleMediumFont)
                            .foregroundColor(theme.textPrimary)
                        
                        Text("Started \(formatTime(workout.startTime))")
                            .font(theme.bodySmallFont)
                            .foregroundColor(theme.textSecondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: theme.spacing.xs) {
                        Text(formatDuration(workout.elapsedTime))
                            .font(theme.titleSmallFont)
                            .foregroundColor(theme.primaryColor)
                        
                        Text("\(workout.completedExercises)/\(workout.totalExercises) exercises")
                            .font(theme.bodySmallFont)
                            .foregroundColor(theme.textSecondary)
                    }
                }
                
                ProgressView(value: workout.progress)
                    .progressViewStyle(.linear)
                    .tint(theme.primaryColor)
                
                ThemedButton("Resume Workout", style: .primary, size: .medium) {
                    onResume()
                }
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

private struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(theme.bodyMediumFont)
                .foregroundColor(isSelected ? .white : theme.textPrimary)
                .padding(.horizontal, theme.spacing.md)
                .padding(.vertical, theme.spacing.sm)
                .background(isSelected ? theme.primaryColor : theme.surfaceColor)
                .cornerRadius(theme.cornerRadius.large)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

private struct RecentWorkoutCard: View {
    let workout: WorkoutHistory
    let onRepeat: () -> Void
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        ThemedCard {
            VStack(spacing: theme.spacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: theme.spacing.xs) {
                        Text(workout.name)
                            .font(theme.bodyLargeFont)
                            .foregroundColor(theme.textPrimary)
                        
                        Text(formatDate(workout.completedAt))
                            .font(theme.bodySmallFont)
                            .foregroundColor(theme.textSecondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: theme.spacing.xs) {
                        Text("\(workout.duration)m")
                            .font(theme.bodyMediumFont)
                            .foregroundColor(theme.primaryColor)
                        
                        if let rating = workout.rating {
                            HStack(spacing: 2) {
                                ForEach(1...5, id: \.self) { index in
                                    Image(systemName: index <= rating ? "star.fill" : "star")
                                        .font(.caption)
                                        .foregroundColor(index <= rating ? .yellow : theme.textTertiary)
                                }
                            }
                        }
                    }
                }
                
                HStack(spacing: theme.spacing.md) {
                    WorkoutStatBadge(
                        icon: "flame.fill",
                        value: "\(workout.caloriesBurned)",
                        label: "cal"
                    )
                    
                    WorkoutStatBadge(
                        icon: "list.bullet",
                        value: "\(workout.exercisesCompleted)",
                        label: "exercises"
                    )
                    
                    Spacer()
                    
                    ThemedButton("Repeat", style: .secondary, size: .small) {
                        onRepeat()
                    }
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

private struct WorkoutStatBadge: View {
    let icon: String
    let value: String
    let label: String
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        HStack(spacing: theme.spacing.xs) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(theme.primaryColor)
            
            Text("\(value) \(label)")
                .font(theme.bodySmallFont)
                .foregroundColor(theme.textSecondary)
        }
    }
}

// MARK: - Supporting Types

public enum WorkoutCategory: String, CaseIterable {
    case strength = "strength"
    case cardio = "cardio"
    case flexibility = "flexibility"
    case hiit = "hiit"
    case bodyweight = "bodyweight"
    case powerlifting = "powerlifting"
    case crosstraining = "crosstraining"
    case yoga = "yoga"
    
    public var displayName: String {
        switch self {
        case .strength: return "Strength"
        case .cardio: return "Cardio"
        case .flexibility: return "Flexibility"
        case .hiit: return "HIIT"
        case .bodyweight: return "Bodyweight"
        case .powerlifting: return "Powerlifting"
        case .crosstraining: return "Cross Training"
        case .yoga: return "Yoga"
        }
    }
    
    public var icon: String {
        switch self {
        case .strength: return "dumbbell.fill"
        case .cardio: return "heart.fill"
        case .flexibility: return "figure.flexibility"
        case .hiit: return "timer"
        case .bodyweight: return "figure.strengthtraining.traditional"
        case .powerlifting: return "scalemass.fill"
        case .crosstraining: return "figure.cross.training"
        case .yoga: return "figure.yoga"
        }
    }
}

// MARK: - Preview

#Preview {
    WorkoutsView()
        .environmentObject(AuthenticationManager())
        .theme(FitnessTheme())
}