import SwiftUI

// MARK: - Nutrition Data Models
public struct NutritionData {
    public let carbs: Double
    public let protein: Double
    public let fat: Double
    public let fiber: Double?
    
    public init(carbs: Double, protein: Double, fat: Double, fiber: Double? = nil) {
        self.carbs = carbs
        self.protein = protein
        self.fat = fat
        self.fiber = fiber
    }
    
    public var totalMacros: Double {
        carbs + protein + fat
    }
    
    public var totalCalories: Double {
        (carbs * 4) + (protein * 4) + (fat * 9)
    }
}

public struct MacroGoals {
    public let carbs: Double
    public let protein: Double
    public let fat: Double
    public let calories: Double
    
    public init(carbs: Double, protein: Double, fat: Double, calories: Double) {
        self.carbs = carbs
        self.protein = protein
        self.fat = fat
        self.calories = calories
    }
}

public struct NutritionPieChart: View {
    public enum DisplayMode {
        case macros
        case calories
        case detailed
    }
    
    private let data: NutritionData
    private let goals: MacroGoals?
    private let mode: DisplayMode
    private let showProgress: Bool
    
    @Environment(\.theme) private var theme
    @State private var selectedMacro: MacroType?
    @State private var animationProgress: CGFloat = 0
    
    public init(
        data: NutritionData,
        goals: MacroGoals? = nil,
        mode: DisplayMode = .macros,
        showProgress: Bool = true
    ) {
        self.data = data
        self.goals = goals
        self.mode = mode
        self.showProgress = showProgress
    }
    
    public var body: some View {
        VStack(spacing: theme.spacing.lg) {
            headerView
            
            HStack(spacing: theme.spacing.xl) {
                pieChartView
                macroBreakdownView
            }
            
            if mode == .detailed {
                detailedStatsView
            }
        }
        .padding(theme.spacing.md)
        .background(theme.cardColor)
        .cornerRadius(theme.cornerRadius.card)
        .shadow(
            color: theme.shadows.md.color,
            radius: theme.shadows.md.radius,
            x: theme.shadows.md.x,
            y: theme.shadows.md.y
        )
        .onAppear {
            withAnimation(theme.animations.springNormal.delay(0.2)) {
                animationProgress = 1.0
            }
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                Text(mode == .calories ? "Calorie Distribution" : "Macro Distribution")
                    .font(theme.typography.headlineMedium)
                    .foregroundColor(theme.textPrimary)
                
                if let selectedMacro = selectedMacro {
                    HStack(spacing: theme.spacing.xs) {
                        Text(selectedMacro.name)
                            .font(theme.typography.titleSmall)
                            .foregroundColor(selectedMacro.color(theme: theme))
                        
                        Text("• \(valueForMacro(selectedMacro), specifier: "%.1f")g")
                            .font(theme.typography.labelMedium)
                            .foregroundColor(theme.textSecondary)
                    }
                } else {
                    Text("\(data.totalCalories, specifier: "%.0f") calories")
                        .font(theme.typography.labelMedium)
                        .foregroundColor(theme.textSecondary)
                }
            }
            
            Spacer()
            
            if goals != nil {
                Button(action: {}) {
                    Image(systemName: "target")
                        .foregroundColor(theme.primaryColor)
                        .font(.title3)
                }
            }
        }
    }
    
    // MARK: - Pie Chart View
    
    private var pieChartView: some View {
        ZStack {
            Circle()
                .stroke(theme.surfaceColor, lineWidth: 4)
                .frame(width: 160, height: 160)
            
            ForEach(macroSegments.indices, id: \.self) { index in
                let segment = macroSegments[index]
                
                Circle()
                    .trim(
                        from: segment.startAngle,
                        to: segment.startAngle + (segment.percentage * animationProgress)
                    )
                    .stroke(
                        segment.macro.color(theme: theme),
                        style: StrokeStyle(
                            lineWidth: selectedMacro == segment.macro ? 12 : 8,
                            lineCap: .round
                        )
                    )
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(-90))
                    .animation(
                        theme.animations.springNormal.delay(Double(index) * 0.1),
                        value: animationProgress
                    )
                    .animation(theme.animations.springFast, value: selectedMacro)
                    .onTapGesture {
                        selectedMacro = selectedMacro == segment.macro ? nil : segment.macro
                    }
            }
            
            // Center content
            VStack(spacing: theme.spacing.xs) {
                if mode == .calories {
                    Text("\(data.totalCalories, specifier: "%.0f")")
                        .font(theme.typography.headlineLarge)
                        .foregroundColor(theme.primaryColor)
                    
                    Text("calories")
                        .font(theme.typography.labelMedium)
                        .foregroundColor(theme.textSecondary)
                } else {
                    Text("\(data.totalMacros, specifier: "%.0f")g")
                        .font(theme.typography.headlineLarge)
                        .foregroundColor(theme.primaryColor)
                    
                    Text("macros")
                        .font(theme.typography.labelMedium)
                        .foregroundColor(theme.textSecondary)
                }
            }
        }
    }
    
    // MARK: - Macro Breakdown View
    
    private var macroBreakdownView: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            ForEach(MacroType.allCases, id: \.self) { macro in
                MacroRow(
                    macro: macro,
                    current: valueForMacro(macro),
                    goal: goalForMacro(macro),
                    percentage: percentageForMacro(macro),
                    isSelected: selectedMacro == macro,
                    showProgress: showProgress
                ) {
                    selectedMacro = selectedMacro == macro ? nil : macro
                }
            }
        }
    }
    
    // MARK: - Detailed Stats View
    
    private var detailedStatsView: some View {
        VStack(spacing: theme.spacing.md) {
            Divider()
                .foregroundColor(theme.surfaceColor)
            
            HStack(spacing: theme.spacing.lg) {
                DetailStatCard(
                    title: "Calories per Gram",
                    stats: [
                        ("Carbs", "4 cal/g"),
                        ("Protein", "4 cal/g"),
                        ("Fat", "9 cal/g")
                    ]
                )
                
                if let goals = goals {
                    DetailStatCard(
                        title: "Goal Progress",
                        stats: [
                            ("Calories", "\(data.totalCalories / goals.calories * 100, specifier: "%.0f")%"),
                            ("Carbs", "\(data.carbs / goals.carbs * 100, specifier: "%.0f")%"),
                            ("Protein", "\(data.protein / goals.protein * 100, specifier: "%.0f")%"),
                            ("Fat", "\(data.fat / goals.fat * 100, specifier: "%.0f")%")
                        ]
                    )
                }
                
                if let fiber = data.fiber {
                    DetailStatCard(
                        title: "Additional",
                        stats: [
                            ("Fiber", "\(fiber, specifier: "%.1f")g"),
                            ("Net Carbs", "\(data.carbs - fiber, specifier: "%.1f")g"),
                            ("P/C Ratio", "\(data.protein / data.carbs, specifier: "%.1f")")
                        ]
                    )
                }
            }
        }
    }
    
    // MARK: - Helper Views
    
    private struct MacroRow: View {
        let macro: MacroType
        let current: Double
        let goal: Double?
        let percentage: Double
        let isSelected: Bool
        let showProgress: Bool
        let onTap: () -> Void
        
        @Environment(\.theme) private var theme
        
        var body: some View {
            Button(action: onTap) {
                HStack(spacing: theme.spacing.sm) {
                    Circle()
                        .fill(macro.color(theme: theme))
                        .frame(width: 12, height: 12)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(macro.name)
                            .font(theme.typography.bodyMedium)
                            .foregroundColor(theme.textPrimary)
                        
                        if let goal = goal, showProgress {
                            ProgressView(value: current, total: goal)
                                .tint(macro.color(theme: theme))
                                .frame(height: 4)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(current, specifier: "%.1f")g")
                            .font(theme.typography.titleSmall)
                            .foregroundColor(macro.color(theme: theme))
                        
                        Text("\(percentage * 100, specifier: "%.0f")%")
                            .font(theme.typography.labelSmall)
                            .foregroundColor(theme.textTertiary)
                    }
                }
                .padding(.vertical, theme.spacing.xs)
                .background(
                    RoundedRectangle(cornerRadius: theme.cornerRadius.sm)
                        .fill(isSelected ? theme.surfaceColor : Color.clear)
                )
                .animation(theme.animations.springFast, value: isSelected)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    private struct DetailStatCard: View {
        let title: String
        let stats: [(String, String)]
        
        @Environment(\.theme) private var theme
        
        var body: some View {
            VStack(alignment: .leading, spacing: theme.spacing.sm) {
                Text(title)
                    .font(theme.typography.headlineSmall)
                    .foregroundColor(theme.textPrimary)
                
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    ForEach(stats, id: \.0) { stat in
                        HStack {
                            Text(stat.0)
                                .font(theme.typography.bodySmall)
                                .foregroundColor(theme.textSecondary)
                            
                            Spacer()
                            
                            Text(stat.1)
                                .font(theme.typography.labelMedium)
                                .foregroundColor(theme.textPrimary)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    // MARK: - Helper Types and Properties
    
    private enum MacroType: CaseIterable {
        case carbs, protein, fat
        
        var name: String {
            switch self {
            case .carbs: return "Carbohydrates"
            case .protein: return "Protein"
            case .fat: return "Fat"
            }
        }
        
        func color(theme: any ThemeProtocol) -> Color {
            switch self {
            case .carbs: return theme.primaryColor
            case .protein: return theme.successColor
            case .fat: return theme.warningColor
            }
        }
    }
    
    private var macroSegments: [(macro: MacroType, startAngle: CGFloat, percentage: CGFloat)] {
        var segments: [(macro: MacroType, startAngle: CGFloat, percentage: CGFloat)] = []
        var currentAngle: CGFloat = 0
        
        let macros: [(MacroType, Double)] = [
            (.carbs, data.carbs),
            (.protein, data.protein),
            (.fat, data.fat)
        ]
        
        for (macro, value) in macros {
            let percentage = CGFloat(value / data.totalMacros)
            segments.append((macro: macro, startAngle: currentAngle, percentage: percentage))
            currentAngle += percentage
        }
        
        return segments
    }
    
    private func valueForMacro(_ macro: MacroType) -> Double {
        switch macro {
        case .carbs: return data.carbs
        case .protein: return data.protein
        case .fat: return data.fat
        }
    }
    
    private func goalForMacro(_ macro: MacroType) -> Double? {
        guard let goals = goals else { return nil }
        switch macro {
        case .carbs: return goals.carbs
        case .protein: return goals.protein
        case .fat: return goals.fat
        }
    }
    
    private func percentageForMacro(_ macro: MacroType) -> Double {
        let value = valueForMacro(macro)
        return value / data.totalMacros
    }
}

// MARK: - Preview
#Preview {
    ScrollView {
        VStack(spacing: 24) {
            NutritionPieChart(
                data: NutritionData(carbs: 120, protein: 80, fat: 45, fiber: 25),
                goals: MacroGoals(carbs: 150, protein: 100, fat: 50, calories: 1600),
                mode: .detailed
            )
            
            NutritionPieChart(
                data: NutritionData(carbs: 90, protein: 110, fat: 35),
                mode: .calories,
                showProgress: false
            )
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
    .theme(FitnessTheme())
}