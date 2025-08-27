import SwiftUI

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let unit: String
    let subtitle: String
    let icon: String
    let color: Color
    let progress: Double
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Spacer()
            }
            
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(theme.textPrimary)
                Text(unit)
                    .font(theme.typography.bodySmall)
                    .foregroundColor(theme.textSecondary)
            }
            
            Text(subtitle)
                .font(theme.typography.bodySmall)
                .foregroundColor(theme.textTertiary)
            
            ProgressView(value: progress)
                .tint(color)
                .scaleEffect(x: 1, y: 0.5, anchor: .center)
        }
        .padding()
        .background(theme.surfaceColor)
        .cornerRadius(theme.cornerRadius.medium)
    }
}

// MARK: - Progress Row
struct ProgressRow: View {
    let title: String
    let isCompleted: Bool
    let time: String
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        HStack {
            Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isCompleted ? .green : theme.textTertiary)
            
            Text(title)
                .font(theme.typography.bodyMedium)
                .foregroundColor(theme.textPrimary)
                .strikethrough(isCompleted)
            
            Spacer()
            
            Text(time)
                .font(theme.typography.bodySmall)
                .foregroundColor(theme.textSecondary)
        }
    }
}

// MARK: - Quick Action Card
struct QuickActionCard: View {
    let title: String
    let icon: String
    let color: Color
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(spacing: theme.spacing.sm) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)
            
            Text(title)
                .font(theme.typography.bodySmall)
                .foregroundColor(theme.textPrimary)
                .multilineTextAlignment(.center)
        }
        .frame(width: 100, height: 100)
        .background(theme.surfaceColor)
        .cornerRadius(theme.cornerRadius.medium)
    }
}

// MARK: - Category Pill
struct CategoryPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(theme.typography.bodyMedium)
                .foregroundColor(isSelected ? .white : theme.textPrimary)
                .padding(.horizontal, theme.spacing.md)
                .padding(.vertical, theme.spacing.sm)
                .background(isSelected ? theme.primaryColor : theme.surfaceColor)
                .cornerRadius(theme.cornerRadius.pill)
        }
    }
}

// MARK: - Action Button
struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        HStack {
            Image(systemName: icon)
            Text(title)
        }
        .font(theme.typography.bodyMedium)
        .foregroundColor(.white)
        .padding(.horizontal, theme.spacing.md)
        .padding(.vertical, theme.spacing.sm)
        .background(color)
        .cornerRadius(theme.cornerRadius.medium)
    }
}

// MARK: - Workout Row
struct WorkoutRow: View {
    let name: String
    let description: String
    let duration: String
    let category: String
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                Text(name)
                    .font(theme.typography.bodyLarge)
                    .fontWeight(.medium)
                    .foregroundColor(theme.textPrimary)
                
                Text(description)
                    .font(theme.typography.bodySmall)
                    .foregroundColor(theme.textSecondary)
                
                HStack {
                    Label(duration, systemImage: "clock")
                    Text("•")
                    Text(category)
                }
                .font(theme.typography.bodySmall)
                .foregroundColor(theme.textTertiary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(theme.textTertiary)
        }
        .padding()
        .background(theme.surfaceColor)
        .cornerRadius(theme.cornerRadius.medium)
    }
}

// MARK: - Macro View
struct MacroView: View {
    let name: String
    let value: Double
    let target: Double
    let unit: String
    let color: Color
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(spacing: 4) {
            Text(name)
                .font(theme.typography.bodySmall)
                .foregroundColor(theme.textSecondary)
            
            Text("\(Int(value))\(unit)")
                .font(theme.typography.bodyMedium)
                .fontWeight(.bold)
                .foregroundColor(theme.textPrimary)
            
            Text("/ \(Int(target))")
                .font(.caption2)
                .foregroundColor(theme.textTertiary)
            
            ProgressView(value: value / target)
                .tint(color)
                .scaleEffect(x: 1, y: 0.5, anchor: .center)
        }
    }
}

// MARK: - Meal Section
struct MealSection: View {
    let meal: String
    let calories: Int
    let items: [String]
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            HStack {
                Text(meal)
                    .font(theme.typography.bodyMedium)
                    .fontWeight(.medium)
                Spacer()
                if calories > 0 {
                    Text("\(calories) cal")
                        .font(theme.typography.bodySmall)
                        .foregroundColor(theme.primaryColor)
                }
                Image(systemName: "plus.circle")
                    .foregroundColor(theme.primaryColor)
            }
            
            if items.isEmpty {
                Text("No items logged")
                    .font(theme.typography.bodySmall)
                    .foregroundColor(theme.textTertiary)
                    .italic()
            } else {
                ForEach(items, id: \.self) { item in
                    HStack {
                        Text("• \(item)")
                            .font(theme.typography.bodySmall)
                            .foregroundColor(theme.textSecondary)
                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background(theme.surfaceColor)
        .cornerRadius(theme.cornerRadius.medium)
    }
}