import SwiftUI
import Charts

// MARK: - Progress Chart Components

@available(iOS 16.0, *)
public struct ProgressLineChart: View {
    let data: [ProgressDataPoint]
    let title: String
    let yAxisLabel: String
    let color: Color
    
    @Environment(\.theme) private var theme
    
    public init(
        data: [ProgressDataPoint],
        title: String,
        yAxisLabel: String,
        color: Color
    ) {
        self.data = data
        self.title = title
        self.yAxisLabel = yAxisLabel
        self.color = color
    }
    
    public var body: some View {
        ThemedCard {
            VStack(alignment: .leading, spacing: theme.spacing.md) {
                Text(title)
                    .font(theme.titleMediumFont)
                    .foregroundColor(theme.textPrimary)
                
                if data.isEmpty {
                    InlineEmptyStateView(
                        message: "No data available yet",
                        iconName: "chart.line.uptrend.xyaxis"
                    )
                    .frame(height: 200)
                } else {
                    Chart(data) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value(yAxisLabel, point.value)
                        )
                        .foregroundStyle(color.gradient)
                        .symbol(Circle())
                        
                        AreaMark(
                            x: .value("Date", point.date),
                            y: .value(yAxisLabel, point.value)
                        )
                        .foregroundStyle(color.opacity(0.1).gradient)
                    }
                    .frame(height: 200)
                    .chartYAxis {
                        AxisMarks(position: .leading) { value in
                            AxisValueLabel()
                                .font(theme.bodySmallFont)
                                .foregroundStyle(theme.textSecondary)
                        }
                    }
                    .chartXAxis {
                        AxisMarks { value in
                            AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                                .font(theme.bodySmallFont)
                                .foregroundStyle(theme.textSecondary)
                        }
                    }
                }
            }
        }
    }
}

@available(iOS 16.0, *)
public struct MacroBreakdownChart: View {
    let protein: Double
    let carbs: Double
    let fat: Double
    let title: String
    
    @Environment(\.theme) private var theme
    
    public init(
        protein: Double,
        carbs: Double,
        fat: Double,
        title: String = "Macro Breakdown"
    ) {
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.title = title
    }
    
    private var chartData: [MacroData] {
        [
            MacroData(name: "Protein", value: protein, color: .blue),
            MacroData(name: "Carbs", value: carbs, color: .green),
            MacroData(name: "Fat", value: fat, color: .orange)
        ].filter { $0.value > 0 }
    }
    
    public var body: some View {
        ThemedCard {
            VStack(alignment: .leading, spacing: theme.spacing.md) {
                Text(title)
                    .font(theme.titleMediumFont)
                    .foregroundColor(theme.textPrimary)
                
                if chartData.isEmpty {
                    InlineEmptyStateView(
                        message: "No nutrition data available",
                        iconName: "chart.pie"
                    )
                    .frame(height: 200)
                } else {
                    VStack(spacing: theme.spacing.lg) {
                        Chart(chartData, id: \.name) { macro in
                            SectorMark(
                                angle: .value("Value", macro.value),
                                innerRadius: .ratio(0.5),
                                angularInset: 2
                            )
                            .foregroundStyle(macro.color)
                        }
                        .frame(height: 200)
                        
                        // Legend
                        HStack(spacing: theme.spacing.lg) {
                            ForEach(chartData, id: \.name) { macro in
                                HStack(spacing: theme.spacing.xs) {
                                    Circle()
                                        .fill(macro.color)
                                        .frame(width: 12, height: 12)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(macro.name)
                                            .font(theme.bodySmallFont)
                                            .foregroundColor(theme.textSecondary)
                                        
                                        Text("\(Int(macro.value))g")
                                            .font(theme.bodyMediumFont)
                                            .foregroundColor(theme.textPrimary)
                                    }
                                }
                            }
                            Spacer()
                        }
                    }
                }
            }
        }
    }
}

@available(iOS 16.0, *)
public struct WeeklyWorkoutChart: View {
    let data: [WorkoutData]
    let title: String
    
    @Environment(\.theme) private var theme
    
    public init(data: [WorkoutData], title: String = "Weekly Workouts") {
        self.data = data
        self.title = title
    }
    
    public var body: some View {
        ThemedCard {
            VStack(alignment: .leading, spacing: theme.spacing.md) {
                Text(title)
                    .font(theme.titleMediumFont)
                    .foregroundColor(theme.textPrimary)
                
                if data.isEmpty {
                    InlineEmptyStateView(
                        message: "No workout data available",
                        iconName: "chart.bar"
                    )
                    .frame(height: 200)
                } else {
                    Chart(data) { workout in
                        BarMark(
                            x: .value("Day", workout.day),
                            y: .value("Duration", workout.duration)
                        )
                        .foregroundStyle(theme.primaryColor.gradient)
                        .cornerRadius(4)
                    }
                    .frame(height: 200)
                    .chartYAxis {
                        AxisMarks(position: .leading) { value in
                            AxisValueLabel()
                                .font(theme.bodySmallFont)
                                .foregroundStyle(theme.textSecondary)
                        }
                    }
                    .chartXAxis {
                        AxisMarks { value in
                            AxisValueLabel()
                                .font(theme.bodySmallFont)
                                .foregroundStyle(theme.textSecondary)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Fallback Charts for iOS < 16

public struct LegacyProgressChart: View {
    let data: [ProgressDataPoint]
    let title: String
    let color: Color
    
    @Environment(\.theme) private var theme
    
    public init(data: [ProgressDataPoint], title: String, color: Color) {
        self.data = data
        self.title = title
        self.color = color
    }
    
    public var body: some View {
        ThemedCard {
            VStack(alignment: .leading, spacing: theme.spacing.md) {
                Text(title)
                    .font(theme.titleMediumFont)
                    .foregroundColor(theme.textPrimary)
                
                if data.isEmpty {
                    InlineEmptyStateView(
                        message: "No data available yet",
                        iconName: "chart.line.uptrend.xyaxis"
                    )
                    .frame(height: 200)
                } else {
                    // Simple line visualization using GeometryReader
                    GeometryReader { geometry in
                        Path { path in
                            let points = normalizedPoints(in: geometry.size)
                            if let firstPoint = points.first {
                                path.move(to: firstPoint)
                                points.dropFirst().forEach { path.addLine(to: $0) }
                            }
                        }
                        .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        
                        // Add data points
                        ForEach(Array(normalizedPoints(in: geometry.size).enumerated()), id: \.offset) { index, point in
                            Circle()
                                .fill(color)
                                .frame(width: 8, height: 8)
                                .position(x: point.x, y: point.y)
                        }
                    }
                    .frame(height: 200)
                }
            }
        }
    }
    
    private func normalizedPoints(in size: CGSize) -> [CGPoint] {
        guard !data.isEmpty else { return [] }
        
        let minValue = data.map(\.value).min() ?? 0
        let maxValue = data.map(\.value).max() ?? 1
        let valueRange = maxValue - minValue
        
        return data.enumerated().map { index, point in
            let x = CGFloat(index) * size.width / CGFloat(data.count - 1)
            let normalizedValue = valueRange > 0 ? (point.value - minValue) / valueRange : 0.5
            let y = size.height * (1 - normalizedValue)
            return CGPoint(x: x, y: y)
        }
    }
}

public struct LegacyMacroChart: View {
    let protein: Double
    let carbs: Double
    let fat: Double
    let title: String
    
    @Environment(\.theme) private var theme
    
    public init(protein: Double, carbs: Double, fat: Double, title: String = "Macro Breakdown") {
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.title = title
    }
    
    private var total: Double {
        protein + carbs + fat
    }
    
    private var macros: [(name: String, value: Double, color: Color, percentage: Double)] {
        guard total > 0 else { return [] }
        return [
            ("Protein", protein, .blue, protein / total),
            ("Carbs", carbs, .green, carbs / total),
            ("Fat", fat, .orange, fat / total)
        ].filter { $0.value > 0 }
    }
    
    public var body: some View {
        ThemedCard {
            VStack(alignment: .leading, spacing: theme.spacing.md) {
                Text(title)
                    .font(theme.titleMediumFont)
                    .foregroundColor(theme.textPrimary)
                
                if macros.isEmpty {
                    InlineEmptyStateView(
                        message: "No nutrition data available",
                        iconName: "chart.pie"
                    )
                    .frame(height: 200)
                } else {
                    VStack(spacing: theme.spacing.lg) {
                        // Simple pie chart using arcs
                        ZStack {
                            ForEach(Array(macros.enumerated()), id: \.offset) { index, macro in
                                let startAngle = macros.prefix(index).reduce(0) { $0 + $1.percentage } * 360
                                let endAngle = startAngle + (macro.percentage * 360)
                                
                                Path { path in
                                    let center = CGPoint(x: 100, y: 100)
                                    path.move(to: center)
                                    path.addArc(
                                        center: center,
                                        radius: 80,
                                        startAngle: .degrees(startAngle),
                                        endAngle: .degrees(endAngle),
                                        clockwise: false
                                    )
                                    path.closeSubpath()
                                }
                                .fill(macro.color)
                            }
                            
                            Circle()
                                .fill(theme.backgroundColor)
                                .frame(width: 80, height: 80)
                        }
                        .frame(width: 200, height: 200)
                        
                        // Legend
                        HStack(spacing: theme.spacing.lg) {
                            ForEach(macros, id: \.name) { macro in
                                HStack(spacing: theme.spacing.xs) {
                                    Circle()
                                        .fill(macro.color)
                                        .frame(width: 12, height: 12)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(macro.name)
                                            .font(theme.bodySmallFont)
                                            .foregroundColor(theme.textSecondary)
                                        
                                        Text("\(Int(macro.value))g")
                                            .font(theme.bodyMediumFont)
                                            .foregroundColor(theme.textPrimary)
                                    }
                                }
                            }
                            Spacer()
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Data Models

public struct ProgressDataPoint: Identifiable, Hashable {
    public let id = UUID()
    public let date: Date
    public let value: Double
    
    public init(date: Date, value: Double) {
        self.date = date
        self.value = value
    }
}

public struct MacroData {
    let name: String
    let value: Double
    let color: Color
}

public struct WorkoutData: Identifiable, Hashable {
    public let id = UUID()
    public let day: String
    public let duration: Int
    
    public init(day: String, duration: Int) {
        self.day = day
        self.duration = duration
    }
}

// MARK: - Chart Wrapper for Version Compatibility

public struct ProgressChart: View {
    let data: [ProgressDataPoint]
    let title: String
    let yAxisLabel: String
    let color: Color
    
    public init(
        data: [ProgressDataPoint],
        title: String,
        yAxisLabel: String = "Value",
        color: Color = .blue
    ) {
        self.data = data
        self.title = title
        self.yAxisLabel = yAxisLabel
        self.color = color
    }
    
    public var body: some View {
        if #available(iOS 16.0, *) {
            ProgressLineChart(
                data: data,
                title: title,
                yAxisLabel: yAxisLabel,
                color: color
            )
        } else {
            LegacyProgressChart(
                data: data,
                title: title,
                color: color
            )
        }
    }
}

public struct MacroChart: View {
    let protein: Double
    let carbs: Double
    let fat: Double
    let title: String
    
    public init(
        protein: Double,
        carbs: Double,
        fat: Double,
        title: String = "Macro Breakdown"
    ) {
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.title = title
    }
    
    public var body: some View {
        if #available(iOS 16.0, *) {
            MacroBreakdownChart(
                protein: protein,
                carbs: carbs,
                fat: fat,
                title: title
            )
        } else {
            LegacyMacroChart(
                protein: protein,
                carbs: carbs,
                fat: fat,
                title: title
            )
        }
    }
}

// MARK: - Previews

#Preview("Charts") {
    ScrollView {
        VStack(spacing: 20) {
            ProgressChart(
                data: [
                    ProgressDataPoint(date: Date().addingTimeInterval(-7*24*3600), value: 180),
                    ProgressDataPoint(date: Date().addingTimeInterval(-6*24*3600), value: 179),
                    ProgressDataPoint(date: Date().addingTimeInterval(-5*24*3600), value: 178),
                    ProgressDataPoint(date: Date().addingTimeInterval(-4*24*3600), value: 179),
                    ProgressDataPoint(date: Date().addingTimeInterval(-3*24*3600), value: 177),
                    ProgressDataPoint(date: Date().addingTimeInterval(-2*24*3600), value: 176),
                    ProgressDataPoint(date: Date().addingTimeInterval(-1*24*3600), value: 175)
                ],
                title: "Weight Progress",
                yAxisLabel: "Weight (lbs)",
                color: .blue
            )
            
            MacroChart(
                protein: 150,
                carbs: 200,
                fat: 80
            )
        }
        .padding()
    }
    .theme(FitnessTheme())
}