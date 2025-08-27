import SwiftUI

// MARK: - List Row Components

public struct ThemedListRow<Content: View>: View {
    let content: () -> Content
    let showChevron: Bool
    let backgroundColor: Color?
    let action: (() -> Void)?
    
    @Environment(\.theme) private var theme
    
    public init(
        showChevron: Bool = true,
        backgroundColor: Color? = nil,
        action: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.content = content
        self.showChevron = showChevron
        self.backgroundColor = backgroundColor
        self.action = action
    }
    
    public var body: some View {
        Button(action: action ?? {}) {
            HStack(spacing: theme.spacing.md) {
                content()
                
                if showChevron {
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(theme.textTertiary)
                }
            }
            .padding(theme.spacing.md)
            .background(backgroundColor ?? theme.surfaceColor)
            .cornerRadius(theme.cornerRadius.medium)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(action == nil)
    }
}

public struct ExerciseListRow: View {
    let name: String
    let category: String
    let muscleGroups: [String]
    let difficulty: String
    let equipment: [String]
    let action: (() -> Void)?
    
    @Environment(\.theme) private var theme
    
    public init(
        name: String,
        category: String,
        muscleGroups: [String],
        difficulty: String,
        equipment: [String] = [],
        action: (() -> Void)? = nil
    ) {
        self.name = name
        self.category = category
        self.muscleGroups = muscleGroups
        self.difficulty = difficulty
        self.equipment = equipment
        self.action = action
    }
    
    public var body: some View {
        ThemedListRow(action: action) {
            HStack(spacing: theme.spacing.md) {
                // Exercise icon based on category
                Image(systemName: categoryIcon(for: category))
                    .font(.title3)
                    .foregroundColor(theme.primaryColor)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    Text(name)
                        .font(theme.bodyLargeFont)
                        .foregroundColor(theme.textPrimary)
                        .lineLimit(1)
                    
                    Text(muscleGroups.joined(separator: ", "))
                        .font(theme.bodySmallFont)
                        .foregroundColor(theme.textSecondary)
                        .lineLimit(1)
                    
                    HStack(spacing: theme.spacing.sm) {
                        DifficultyBadge(difficulty: difficulty)
                        
                        if !equipment.isEmpty {
                            EquipmentBadge(equipment: equipment.first ?? "")
                        }
                    }
                }
            }
        }
    }
    
    private func categoryIcon(for category: String) -> String {
        switch category.lowercased() {
        case "chest": return "figure.strengthtraining.traditional"
        case "back": return "figure.strengthtraining.traditional"
        case "legs": return "figure.walk"
        case "shoulders": return "figure.arms.open"
        case "arms": return "dumbbell.fill"
        case "core": return "figure.core.training"
        case "cardio": return "heart.fill"
        default: return "dumbbell"
        }
    }
}

public struct WorkoutListRow: View {
    let name: String
    let description: String?
    let difficulty: String
    let duration: Int?
    let exercises: Int
    let lastPerformed: Date?
    let action: (() -> Void)?
    
    @Environment(\.theme) private var theme
    
    public init(
        name: String,
        description: String? = nil,
        difficulty: String,
        duration: Int? = nil,
        exercises: Int,
        lastPerformed: Date? = nil,
        action: (() -> Void)? = nil
    ) {
        self.name = name
        self.description = description
        self.difficulty = difficulty
        self.duration = duration
        self.exercises = exercises
        self.lastPerformed = lastPerformed
        self.action = action
    }
    
    public var body: some View {
        ThemedListRow(action: action) {
            HStack(spacing: theme.spacing.md) {
                // Workout icon
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.title2)
                    .foregroundColor(theme.primaryColor)
                    .frame(width: 32, height: 32)
                
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    Text(name)
                        .font(theme.bodyLargeFont)
                        .foregroundColor(theme.textPrimary)
                        .lineLimit(1)
                    
                    if let description = description {
                        Text(description)
                            .font(theme.bodySmallFont)
                            .foregroundColor(theme.textSecondary)
                            .lineLimit(2)
                    }
                    
                    HStack(spacing: theme.spacing.sm) {
                        DifficultyBadge(difficulty: difficulty)
                        
                        if let duration = duration {
                            HStack(spacing: 2) {
                                Image(systemName: "clock")
                                    .font(.caption2)
                                Text("\(duration)m")
                                    .font(theme.bodySmallFont)
                            }
                            .foregroundColor(theme.textSecondary)
                        }
                        
                        HStack(spacing: 2) {
                            Image(systemName: "list.bullet")
                                .font(.caption2)
                            Text("\(exercises)")
                                .font(theme.bodySmallFont)
                        }
                        .foregroundColor(theme.textSecondary)
                    }
                    
                    if let lastPerformed = lastPerformed {
                        Text("Last: \(formatDate(lastPerformed))")
                            .font(theme.bodySmallFont)
                            .foregroundColor(theme.textTertiary)
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

public struct ClientListRow: View {
    let name: String
    let email: String
    let joinDate: Date
    let lastActivity: Date?
    let progress: String?
    let action: (() -> Void)?
    
    @Environment(\.theme) private var theme
    
    public init(
        name: String,
        email: String,
        joinDate: Date,
        lastActivity: Date? = nil,
        progress: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.name = name
        self.email = email
        self.joinDate = joinDate
        self.lastActivity = lastActivity
        self.progress = progress
        self.action = action
    }
    
    public var body: some View {
        ThemedListRow(action: action) {
            HStack(spacing: theme.spacing.md) {
                // Client avatar
                Circle()
                    .fill(theme.primaryColor)
                    .frame(width: 48, height: 48)
                    .overlay(
                        Text(String(name.prefix(1)).uppercased())
                            .font(theme.titleMediumFont)
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    Text(name)
                        .font(theme.bodyLargeFont)
                        .foregroundColor(theme.textPrimary)
                        .lineLimit(1)
                    
                    Text(email)
                        .font(theme.bodySmallFont)
                        .foregroundColor(theme.textSecondary)
                        .lineLimit(1)
                    
                    HStack(spacing: theme.spacing.sm) {
                        Text("Joined: \(formatDate(joinDate))")
                            .font(theme.bodySmallFont)
                            .foregroundColor(theme.textTertiary)
                        
                        if let lastActivity = lastActivity {
                            Text("• Active: \(formatDate(lastActivity))")
                                .font(theme.bodySmallFont)
                                .foregroundColor(theme.textTertiary)
                        }
                    }
                    
                    if let progress = progress {
                        Text(progress)
                            .font(theme.bodySmallFont)
                            .foregroundColor(theme.primaryColor)
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

public struct FoodListRow: View {
    let name: String
    let brand: String?
    let calories: Double
    let protein: Double
    let serving: String
    let isVerified: Bool
    let action: (() -> Void)?
    
    @Environment(\.theme) private var theme
    
    public init(
        name: String,
        brand: String? = nil,
        calories: Double,
        protein: Double,
        serving: String,
        isVerified: Bool = false,
        action: (() -> Void)? = nil
    ) {
        self.name = name
        self.brand = brand
        self.calories = calories
        self.protein = protein
        self.serving = serving
        self.isVerified = isVerified
        self.action = action
    }
    
    public var body: some View {
        ThemedListRow(action: action) {
            HStack(spacing: theme.spacing.md) {
                // Food icon
                Image(systemName: "leaf.fill")
                    .font(.title3)
                    .foregroundColor(theme.primaryColor)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    HStack {
                        Text(name)
                            .font(theme.bodyLargeFont)
                            .foregroundColor(theme.textPrimary)
                            .lineLimit(1)
                        
                        if isVerified {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.caption)
                                .foregroundColor(theme.primaryColor)
                        }
                    }
                    
                    if let brand = brand {
                        Text(brand)
                            .font(theme.bodySmallFont)
                            .foregroundColor(theme.textSecondary)
                            .lineLimit(1)
                    }
                    
                    HStack(spacing: theme.spacing.sm) {
                        NutritionBadge(label: "Cal", value: "\(Int(calories))")
                        NutritionBadge(label: "Protein", value: "\(Int(protein))g")
                        
                        Spacer()
                        
                        Text(serving)
                            .font(theme.bodySmallFont)
                            .foregroundColor(theme.textTertiary)
                    }
                }
            }
        }
    }
}

// MARK: - Badge Components

public struct DifficultyBadge: View {
    let difficulty: String
    
    @Environment(\.theme) private var theme
    
    public init(difficulty: String) {
        self.difficulty = difficulty
    }
    
    public var body: some View {
        Text(difficulty)
            .font(theme.bodySmallFont)
            .foregroundColor(difficultyColor)
            .padding(.horizontal, theme.spacing.sm)
            .padding(.vertical, theme.spacing.xs)
            .background(difficultyColor.opacity(0.1))
            .cornerRadius(theme.cornerRadius.small)
    }
    
    private var difficultyColor: Color {
        switch difficulty.lowercased() {
        case "beginner": return .green
        case "intermediate": return .orange
        case "advanced": return .red
        default: return theme.textSecondary
        }
    }
}

public struct EquipmentBadge: View {
    let equipment: String
    
    @Environment(\.theme) private var theme
    
    public init(equipment: String) {
        self.equipment = equipment
    }
    
    public var body: some View {
        Text(equipment)
            .font(theme.bodySmallFont)
            .foregroundColor(theme.textSecondary)
            .padding(.horizontal, theme.spacing.sm)
            .padding(.vertical, theme.spacing.xs)
            .background(theme.textSecondary.opacity(0.1))
            .cornerRadius(theme.cornerRadius.small)
    }
}

public struct NutritionBadge: View {
    let label: String
    let value: String
    
    @Environment(\.theme) private var theme
    
    public init(label: String, value: String) {
        self.label = label
        self.value = value
    }
    
    public var body: some View {
        VStack(spacing: 1) {
            Text(value)
                .font(theme.bodySmallFont)
                .foregroundColor(theme.textPrimary)
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(theme.textTertiary)
        }
    }
}

// MARK: - Search Bar

public struct ThemedSearchBar: View {
    @Binding var text: String
    let placeholder: String
    let onSearchButtonClicked: (() -> Void)?
    
    @Environment(\.theme) private var theme
    
    public init(
        text: Binding<String>,
        placeholder: String = "Search...",
        onSearchButtonClicked: (() -> Void)? = nil
    ) {
        self._text = text
        self.placeholder = placeholder
        self.onSearchButtonClicked = onSearchButtonClicked
    }
    
    public var body: some View {
        HStack(spacing: theme.spacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(theme.textSecondary)
            
            TextField(placeholder, text: $text)
                .onSubmit {
                    onSearchButtonClicked?()
                }
            
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(theme.textSecondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(theme.spacing.md)
        .background(theme.surfaceColor)
        .cornerRadius(theme.cornerRadius.medium)
    }
}

// MARK: - Section Header

public struct SectionHeader: View {
    let title: String
    let subtitle: String?
    let actionTitle: String?
    let action: (() -> Void)?
    
    @Environment(\.theme) private var theme
    
    public init(
        _ title: String,
        subtitle: String? = nil,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.actionTitle = actionTitle
        self.action = action
    }
    
    public var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                Text(title)
                    .font(theme.titleMediumFont)
                    .foregroundColor(theme.textPrimary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(theme.bodySmallFont)
                        .foregroundColor(theme.textSecondary)
                }
            }
            
            Spacer()
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(theme.bodyMediumFont)
                        .foregroundColor(theme.primaryColor)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, theme.spacing.lg)
        .padding(.vertical, theme.spacing.sm)
    }
}

// MARK: - Previews

#Preview("List Components") {
    ScrollView {
        VStack(spacing: 16) {
            SectionHeader(
                "Exercises",
                subtitle: "18 exercises available",
                actionTitle: "See All"
            ) {
                print("See all tapped")
            }
            
            ThemedSearchBar(
                text: .constant(""),
                placeholder: "Search exercises..."
            )
            
            ExerciseListRow(
                name: "Push-ups",
                category: "Chest",
                muscleGroups: ["Chest", "Shoulders", "Triceps"],
                difficulty: "Beginner",
                equipment: ["Bodyweight"]
            ) {
                print("Exercise tapped")
            }
            
            WorkoutListRow(
                name: "Upper Body Strength",
                description: "Build upper body muscle and strength with this comprehensive workout",
                difficulty: "Intermediate",
                duration: 45,
                exercises: 8,
                lastPerformed: Date().addingTimeInterval(-3*24*3600)
            ) {
                print("Workout tapped")
            }
            
            ClientListRow(
                name: "John Smith",
                email: "john@example.com",
                joinDate: Date().addingTimeInterval(-30*24*3600),
                lastActivity: Date().addingTimeInterval(-2*24*3600),
                progress: "Lost 5 lbs this month"
            ) {
                print("Client tapped")
            }
            
            FoodListRow(
                name: "Chicken Breast",
                brand: "Organic Valley",
                calories: 165,
                protein: 31,
                serving: "100g",
                isVerified: true
            ) {
                print("Food tapped")
            }
        }
        .padding()
    }
    .theme(FitnessTheme())
}