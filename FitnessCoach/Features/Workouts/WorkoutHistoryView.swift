import SwiftUI

// MARK: - Workout History View
struct WorkoutHistoryView: View {
    @EnvironmentObject private var dataManager: FitnessDataManager
    @Environment(\.theme) private var theme
    
    @State private var selectedTimeframe: TimeFrame = .week
    @State private var showingSessionDetail: WorkoutSession?
    @State private var searchText = ""
    
    enum TimeFrame: String, CaseIterable {
        case week = "This Week"
        case month = "This Month"
        case quarter = "3 Months"
        case year = "This Year"
        case all = "All Time"
    }
    
    var filteredSessions: [WorkoutSession] {
        let sessions = getSessionsForTimeframe(selectedTimeframe)
            .filter { $0.isCompleted }
            .sorted { $0.startTime > $1.startTime }
        
        if searchText.isEmpty {
            return sessions
        } else {
            return sessions.filter {
                $0.templateName.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Stats Header
            workoutStatsHeader
            
            // Time Filter
            timeframeFilter
            
            // Search Bar
            searchBar
            
            // History List
            if filteredSessions.isEmpty {
                emptyStateView
            } else {
                historyList
            }
        }
    }
    
    private var workoutStatsHeader: some View {
        VStack(spacing: 16) {
            let stats = dataManager.getWorkoutStats(period: workoutStatsPeriod)
            
            HStack(spacing: 20) {
                StatItem(
                    title: "Workouts",
                    value: "\(stats.totalWorkouts)",
                    icon: "dumbbell.fill",
                    color: .blue
                )
                
                StatItem(
                    title: "Total Time",
                    value: formatTotalTime(stats.totalDuration),
                    icon: "clock.fill",
                    color: .orange
                )
                
                StatItem(
                    title: "Calories",
                    value: "\(Int(stats.totalCaloriesBurned))",
                    icon: "flame.fill",
                    color: .red
                )
                
                StatItem(
                    title: "Avg Time",
                    value: formatDuration(stats.averageWorkoutDuration),
                    icon: "chart.bar.fill",
                    color: .green
                )
            }
        }
        .padding()
        .background(theme.surfaceColor)
    }
    
    private var timeframeFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(TimeFrame.allCases, id: \.self) { timeframe in
                    TimeframeButton(
                        title: timeframe.rawValue,
                        isSelected: selectedTimeframe == timeframe
                    ) {
                        selectedTimeframe = timeframe
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(theme.textTertiary)
            
            TextField("Search workouts...", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
        }
        .padding()
        .background(theme.surfaceColor)
        .cornerRadius(12)
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
    
    private var historyList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(groupSessionsByDate(filteredSessions), id: \.key) { dateGroup in
                    Section {
                        ForEach(dateGroup.value, id: \.id) { session in
                            WorkoutSessionCard(session: session) {
                                showingSessionDetail = session
                            }
                        }
                    } header: {
                        SectionHeaderView(title: formatDateHeader(dateGroup.key))
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 100)
        }
        .sheet(item: $showingSessionDetail) { session in
            WorkoutSessionDetailView(session: session)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock")
                .font(.system(size: 50))
                .foregroundColor(theme.textTertiary)
            
            Text("No Workouts Found")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(theme.textPrimary)
            
            Text("Complete your first workout to see it here!")
                .font(.subheadline)
                .foregroundColor(theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // Helper Methods
    private func getSessionsForTimeframe(_ timeframe: TimeFrame) -> [WorkoutSession] {
        let calendar = Calendar.current
        let now = Date()
        let startDate: Date
        
        switch timeframe {
        case .week:
            startDate = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        case .month:
            startDate = calendar.dateInterval(of: .month, for: now)?.start ?? now
        case .quarter:
            startDate = calendar.date(byAdding: .month, value: -3, to: now) ?? now
        case .year:
            startDate = calendar.dateInterval(of: .year, for: now)?.start ?? now
        case .all:
            startDate = Date.distantPast
        }
        
        return dataManager.workoutSessions.filter { $0.startTime >= startDate }
    }
    
    private var workoutStatsPeriod: WorkoutStats.StatsPeriod {
        switch selectedTimeframe {
        case .week: return .week
        case .month: return .month
        case .quarter: return .quarter
        case .year: return .year
        case .all: return .allTime
        }
    }
    
    private func groupSessionsByDate(_ sessions: [WorkoutSession]) -> [(key: Date, value: [WorkoutSession])] {
        let grouped = Dictionary(grouping: sessions) { session in
            Calendar.current.startOfDay(for: session.startTime)
        }
        
        return grouped.sorted { $0.key > $1.key }
    }
    
    private func formatDateHeader(_ date: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else if calendar.isDate(date, equalTo: Date(), toGranularity: .year) {
            formatter.dateFormat = "EEEE, MMMM d"
        } else {
            formatter.dateFormat = "EEEE, MMMM d, yyyy"
        }
        
        return formatter.string(from: date)
    }
    
    private func formatTotalTime(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        return "\(minutes)m"
    }
}

struct StatItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            VStack(spacing: 2) {
                Text(value)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(theme.textPrimary)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(theme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct TimeframeButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : theme.textPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? theme.primaryColor : theme.surfaceColor)
                .cornerRadius(20)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SectionHeaderView: View {
    let title: String
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(theme.textPrimary)
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
}

struct WorkoutSessionCard: View {
    let session: WorkoutSession
    let action: () -> Void
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(session.templateName)
                            .font(.headline)
                            .foregroundColor(theme.textPrimary)
                            .multilineTextAlignment(.leading)
                        
                        Text(formatTime(session.startTime))
                            .font(.subheadline)
                            .foregroundColor(theme.textSecondary)
                    }
                    
                    Spacer()
                    
                    if let rating = session.rating {
                        HStack(spacing: 2) {
                            ForEach(0..<5) { i in
                                Image(systemName: i < rating ? "star.fill" : "star")
                                    .foregroundColor(i < rating ? .yellow : theme.textTertiary)
                                    .font(.caption)
                            }
                        }
                    }
                }
                
                HStack(spacing: 16) {
                    Label(formatDuration(session.duration), systemImage: "clock")
                    
                    if let calories = session.totalCaloriesBurned {
                        Label("\(Int(calories)) cal", systemImage: "flame")
                    }
                    
                    Label("\(session.completedExercises.count) exercises", systemImage: "list.number")
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(theme.textTertiary)
                }
                .font(.caption)
                .foregroundColor(theme.textSecondary)
            }
            .padding()
            .background(theme.surfaceColor)
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        return "\(minutes)m"
    }
}

// MARK: - Exercise Library View
struct ExerciseLibraryView: View {
    @EnvironmentObject private var dataManager: FitnessDataManager
    @Environment(\.theme) private var theme
    
    @State private var searchText = ""
    @State private var selectedCategory: Exercise.ExerciseCategory?
    @State private var selectedEquipment: Exercise.Equipment?
    @State private var showingFilters = false
    @State private var selectedExercise: Exercise?
    
    var filteredExercises: [Exercise] {
        dataManager.searchExercises(searchText, category: selectedCategory, equipment: selectedEquipment)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search and Filter Bar
            searchAndFilterBar
            
            // Active Filters
            if selectedCategory != nil || selectedEquipment != nil {
                activeFiltersBar
            }
            
            // Exercise List
            if filteredExercises.isEmpty {
                emptyExerciseState
            } else {
                exerciseList
            }
        }
        .sheet(isPresented: $showingFilters) {
            ExerciseFiltersSheet(
                selectedCategory: $selectedCategory,
                selectedEquipment: $selectedEquipment
            )
        }
        .sheet(item: $selectedExercise) { exercise in
            ExerciseDetailView(exercise: exercise)
        }
    }
    
    private var searchAndFilterBar: some View {
        HStack(spacing: 12) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(theme.textTertiary)
                
                TextField("Search exercises...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
            }
            .padding()
            .background(theme.surfaceColor)
            .cornerRadius(12)
            
            // Filter Button
            Button {
                showingFilters = true
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.title2)
                    .foregroundColor(hasActiveFilters ? .white : theme.textPrimary)
                    .padding()
                    .background(hasActiveFilters ? theme.primaryColor : theme.surfaceColor)
                    .cornerRadius(12)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    private var activeFiltersBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if let category = selectedCategory {
                    FilterChip(title: category.rawValue) {
                        selectedCategory = nil
                    }
                }
                
                if let equipment = selectedEquipment {
                    FilterChip(title: equipment.rawValue) {
                        selectedEquipment = nil
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
    
    private var exerciseList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(groupExercisesByCategory(filteredExercises), id: \.key) { categoryGroup in
                    Section {
                        ForEach(categoryGroup.value, id: \.id) { exercise in
                            ExerciseRowCard(exercise: exercise) {
                                selectedExercise = exercise
                            }
                        }
                    } header: {
                        if filteredExercises.count > 10 { // Only show category headers for large lists
                            SectionHeaderView(title: categoryGroup.key.rawValue)
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 100)
        }
    }
    
    private var emptyExerciseState: some View {
        VStack(spacing: 16) {
            Image(systemName: "dumbbell")
                .font(.system(size: 50))
                .foregroundColor(theme.textTertiary)
            
            Text("No Exercises Found")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(theme.textPrimary)
            
            Text("Try adjusting your search or filters")
                .font(.subheadline)
                .foregroundColor(theme.textSecondary)
                .multilineTextAlignment(.center)
            
            Button("Clear Filters") {
                selectedCategory = nil
                selectedEquipment = nil
                searchText = ""
            }
            .font(.subheadline)
            .foregroundColor(theme.primaryColor)
            .padding()
            .background(theme.primaryColor.opacity(0.1))
            .cornerRadius(12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var hasActiveFilters: Bool {
        selectedCategory != nil || selectedEquipment != nil
    }
    
    private func groupExercisesByCategory(_ exercises: [Exercise]) -> [(key: Exercise.ExerciseCategory, value: [Exercise])] {
        let grouped = Dictionary(grouping: exercises) { $0.category }
        return grouped.sorted { $0.key.rawValue < $1.key.rawValue }
    }
}

struct FilterChip: View {
    let title: String
    let onRemove: () -> Void
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        HStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
            
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.caption2)
            }
        }
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(theme.primaryColor)
        .cornerRadius(16)
    }
}

struct ExerciseRowCard: View {
    let exercise: Exercise
    let action: () -> Void
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Exercise Category Icon
                Image(systemName: exercise.category.icon)
                    .font(.title2)
                    .foregroundColor(theme.primaryColor)
                    .frame(width: 40, height: 40)
                    .background(theme.primaryColor.opacity(0.1))
                    .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name)
                        .font(.headline)
                        .foregroundColor(theme.textPrimary)
                        .multilineTextAlignment(.leading)
                    
                    HStack(spacing: 12) {
                        Text(exercise.category.rawValue)
                            .font(.caption)
                            .foregroundColor(theme.textSecondary)
                        
                        Text("•")
                            .font(.caption)
                            .foregroundColor(theme.textTertiary)
                        
                        Text(exercise.equipment.rawValue)
                            .font(.caption)
                            .foregroundColor(theme.textSecondary)
                        
                        Text("•")
                            .font(.caption)
                            .foregroundColor(theme.textTertiary)
                        
                        Text(exercise.difficulty.rawValue)
                            .font(.caption)
                            .foregroundColor(difficultyColor(exercise.difficulty))
                    }
                }
                
                Spacer()
                
                // Favorite Button
                Button {
                    dataManager.toggleExerciseFavorite(exercise.id)
                } label: {
                    Image(systemName: exercise.isFavorite ? "heart.fill" : "heart")
                        .foregroundColor(exercise.isFavorite ? .red : theme.textTertiary)
                }
                .buttonStyle(PlainButtonStyle())
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(theme.textTertiary)
            }
            .padding()
            .background(theme.surfaceColor)
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func difficultyColor(_ difficulty: Exercise.Difficulty) -> Color {
        switch difficulty {
        case .beginner: return .green
        case .intermediate: return .orange
        case .advanced: return .red
        }
    }
}

#Preview {
    WorkoutHistoryView()
        .environmentObject(FitnessDataManager.shared)
        .environmentObject(ThemeManager())
        .theme(FitnessTheme())
}