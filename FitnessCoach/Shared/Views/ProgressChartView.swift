import SwiftUI
import Charts

// MARK: - Progress Chart Data Models
public struct ProgressDataPoint: Identifiable, Hashable {
    public let id = UUID()
    public let date: Date
    public let value: Double
    public let category: String
    
    public init(date: Date, value: Double, category: String) {
        self.date = date
        self.value = value
        self.category = category
    }
}

public struct ProgressChartView: View {
    public enum ChartType {
        case line
        case area
        case bar
        case point
    }
    
    public enum TimeRange: String, CaseIterable {
        case week = "7D"
        case month = "1M"
        case threeMonths = "3M"
        case sixMonths = "6M"
        case year = "1Y"
        case all = "All"
        
        var title: String {
            switch self {
            case .week: return "Week"
            case .month: return "Month"
            case .threeMonths: return "3 Months"
            case .sixMonths: return "6 Months"
            case .year: return "Year"
            case .all: return "All Time"
            }
        }
        
        var days: Int? {
            switch self {
            case .week: return 7
            case .month: return 30
            case .threeMonths: return 90
            case .sixMonths: return 180
            case .year: return 365
            case .all: return nil
            }
        }
    }
    
    private let title: String
    private let data: [ProgressDataPoint]
    private let chartType: ChartType
    private let showLegend: Bool
    private let showGoalLine: Bool
    private let goalValue: Double?
    
    @Environment(\.theme) private var theme
    @State private var selectedTimeRange: TimeRange = .month
    @State private var selectedPoint: ProgressDataPoint?
    @State private var showDetails = false
    
    public init(
        title: String,
        data: [ProgressDataPoint],
        chartType: ChartType = .line,
        showLegend: Bool = true,
        showGoalLine: Bool = false,
        goalValue: Double? = nil
    ) {
        self.title = title
        self.data = data
        self.chartType = chartType
        self.showLegend = showLegend
        self.showGoalLine = showGoalLine
        self.goalValue = goalValue
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            headerView
            timeRangeSelector
            chartView
            if showLegend {
                legendView
            }
            statisticsView
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
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                Text(title)
                    .font(theme.typography.headlineMedium)
                    .foregroundColor(theme.textPrimary)
                
                if let selectedPoint = selectedPoint {
                    Text("\(selectedPoint.value, specifier: "%.1f")")
                        .font(theme.typography.displaySmall)
                        .foregroundColor(theme.primaryColor)
                        .animation(theme.animations.fadeIn, value: selectedPoint)
                } else if let latest = filteredData.last {
                    Text("\(latest.value, specifier: "%.1f")")
                        .font(theme.typography.displaySmall)
                        .foregroundColor(theme.textPrimary)
                }
            }
            
            Spacer()
            
            Button(action: { showDetails.toggle() }) {
                Image(systemName: "info.circle")
                    .foregroundColor(theme.textSecondary)
                    .font(.title2)
            }
        }
    }
    
    private var timeRangeSelector: some View {
        HStack(spacing: theme.spacing.xs) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                Button(action: {
                    selectedTimeRange = range
                }) {
                    Text(range.rawValue)
                        .font(theme.typography.labelMedium)
                        .foregroundColor(selectedTimeRange == range ? theme.textOnPrimary : theme.textSecondary)
                        .padding(.horizontal, theme.spacing.sm)
                        .padding(.vertical, theme.spacing.xs)
                        .background(
                            RoundedRectangle(cornerRadius: theme.cornerRadius.sm)
                                .fill(selectedTimeRange == range ? theme.primaryColor : Color.clear)
                        )
                }
                .animation(theme.animations.springFast, value: selectedTimeRange)
            }
        }
    }
    
    private var chartView: some View {
        Chart(filteredData) { dataPoint in
            switch chartType {
            case .line:
                LineMark(
                    x: .value("Date", dataPoint.date),
                    y: .value("Value", dataPoint.value)
                )
                .foregroundStyle(colorForCategory(dataPoint.category))
                .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                .symbol(Circle().strokeBorder(lineWidth: 2))
                .symbolSize(selectedPoint?.id == dataPoint.id ? 100 : 50)
                
            case .area:
                AreaMark(
                    x: .value("Date", dataPoint.date),
                    y: .value("Value", dataPoint.value)
                )
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            colorForCategory(dataPoint.category).opacity(0.8),
                            colorForCategory(dataPoint.category).opacity(0.2)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                
            case .bar:
                BarMark(
                    x: .value("Date", dataPoint.date),
                    y: .value("Value", dataPoint.value)
                )
                .foregroundStyle(colorForCategory(dataPoint.category))
                .cornerRadius(theme.cornerRadius.xs)
                
            case .point:
                PointMark(
                    x: .value("Date", dataPoint.date),
                    y: .value("Value", dataPoint.value)
                )
                .foregroundStyle(colorForCategory(dataPoint.category))
                .symbolSize(selectedPoint?.id == dataPoint.id ? 100 : 64)
            }
            
            // Goal line
            if showGoalLine, let goalValue = goalValue {
                RuleMark(y: .value("Goal", goalValue))
                    .foregroundStyle(theme.warningColor)
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
            }
        }
        .frame(height: 200)
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: selectedTimeRange == .week ? 1 : 7)) { _ in
                AxisGridLine()
                AxisTick()
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
            }
        }
        .chartYAxis {
            AxisMarks { _ in
                AxisGridLine()
                AxisTick()
                AxisValueLabel()
            }
        }
        .chartAngleSelection(value: .constant(nil))
        .chartBackground { chartProxy in
            GeometryReader { geometry in
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .onTapGesture { location in
                        updateSelectedPoint(at: location, geometry: geometry, chartProxy: chartProxy)
                    }
            }
        }
        .animation(theme.animations.springNormal, value: filteredData)
    }
    
    private var legendView: some View {
        HStack(spacing: theme.spacing.md) {
            ForEach(uniqueCategories, id: \.self) { category in
                HStack(spacing: theme.spacing.xs) {
                    Circle()
                        .fill(colorForCategory(category))
                        .frame(width: 12, height: 12)
                    
                    Text(category)
                        .font(theme.typography.labelSmall)
                        .foregroundColor(theme.textSecondary)
                }
            }
        }
    }
    
    private var statisticsView: some View {
        HStack(spacing: theme.spacing.lg) {
            StatisticItem(
                title: "Average",
                value: "\(filteredData.map(\.value).reduce(0, +) / Double(max(filteredData.count, 1)), specifier: "%.1f")",
                color: theme.infoColor
            )
            
            StatisticItem(
                title: "Best",
                value: "\(filteredData.map(\.value).max() ?? 0, specifier: "%.1f")",
                color: theme.successColor
            )
            
            StatisticItem(
                title: "Trend",
                value: trendPercentage,
                color: trendColor
            )
        }
    }
    
    // MARK: - Helper Views
    
    private struct StatisticItem: View {
        let title: String
        let value: String
        let color: Color
        
        @Environment(\.theme) private var theme
        
        var body: some View {
            VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                Text(title)
                    .font(theme.typography.labelSmall)
                    .foregroundColor(theme.textTertiary)
                
                Text(value)
                    .font(theme.typography.titleSmall)
                    .foregroundColor(color)
            }
        }
    }
    
    // MARK: - Helper Properties & Methods
    
    private var filteredData: [ProgressDataPoint] {
        guard let days = selectedTimeRange.days else { return data }
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return data.filter { $0.date >= cutoffDate }.sorted { $0.date < $1.date }
    }
    
    private var uniqueCategories: [String] {
        Array(Set(filteredData.map(\.category))).sorted()
    }
    
    private var trendPercentage: String {
        guard filteredData.count >= 2 else { return "—" }
        let first = filteredData.first!.value
        let last = filteredData.last!.value
        let change = ((last - first) / first) * 100
        return "\(change >= 0 ? "+" : "")\(change, specifier: "%.1f")%"
    }
    
    private var trendColor: Color {
        guard filteredData.count >= 2 else { return theme.textSecondary }
        let first = filteredData.first!.value
        let last = filteredData.last!.value
        return last >= first ? theme.successColor : theme.errorColor
    }
    
    private func colorForCategory(_ category: String) -> Color {
        let colors = [theme.primaryColor, theme.secondaryColor, theme.infoColor, theme.warningColor]
        let index = abs(category.hashValue) % colors.count
        return colors[index]
    }
    
    private func updateSelectedPoint(at location: CGPoint, geometry: GeometryProxy, chartProxy: ChartProxy) {
        // Chart interaction logic would be implemented here
        // This is a simplified version - full implementation would need chart coordinate conversion
        selectedPoint = filteredData.randomElement()
    }
}

// MARK: - Preview
#Preview {
    ScrollView {
        VStack(spacing: 20) {
            ProgressChartView(
                title: "Weight Progress",
                data: [
                    ProgressDataPoint(date: Calendar.current.date(byAdding: .day, value: -30, to: Date())!, value: 180, category: "Weight"),
                    ProgressDataPoint(date: Calendar.current.date(byAdding: .day, value: -25, to: Date())!, value: 178, category: "Weight"),
                    ProgressDataPoint(date: Calendar.current.date(byAdding: .day, value: -20, to: Date())!, value: 176, category: "Weight"),
                    ProgressDataPoint(date: Calendar.current.date(byAdding: .day, value: -15, to: Date())!, value: 175, category: "Weight"),
                    ProgressDataPoint(date: Calendar.current.date(byAdding: .day, value: -10, to: Date())!, value: 173, category: "Weight"),
                    ProgressDataPoint(date: Calendar.current.date(byAdding: .day, value: -5, to: Date())!, value: 172, category: "Weight"),
                    ProgressDataPoint(date: Date(), value: 170, category: "Weight")
                ],
                chartType: .area,
                showGoalLine: true,
                goalValue: 165
            )
            
            ProgressChartView(
                title: "Body Fat %",
                data: [
                    ProgressDataPoint(date: Calendar.current.date(byAdding: .day, value: -30, to: Date())!, value: 22, category: "Body Fat"),
                    ProgressDataPoint(date: Calendar.current.date(byAdding: .day, value: -20, to: Date())!, value: 20, category: "Body Fat"),
                    ProgressDataPoint(date: Calendar.current.date(byAdding: .day, value: -10, to: Date())!, value: 18, category: "Body Fat"),
                    ProgressDataPoint(date: Date(), value: 16, category: "Body Fat")
                ],
                chartType: .line
            )
        }
        .padding()
    }
    .theme(FitnessTheme())
}