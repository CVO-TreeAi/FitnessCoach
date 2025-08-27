import SwiftUI

public struct ThemedCard<Content: View>: View {
    private let content: () -> Content
    private let padding: EdgeInsets
    private let showShadow: Bool
    
    @Environment(\.theme) private var theme
    
    public init(
        padding: EdgeInsets = EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16),
        showShadow: Bool = true,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.content = content
        self.padding = padding
        self.showShadow = showShadow
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            content()
        }
        .padding(padding)
        .background(theme.surfaceColor)
        .cornerRadius(theme.cornerRadius.medium)
        .shadow(
            color: showShadow ? theme.shadows.medium.color : Color.clear,
            radius: showShadow ? theme.shadows.medium.radius : 0,
            x: showShadow ? theme.shadows.medium.x : 0,
            y: showShadow ? theme.shadows.medium.y : 0
        )
    }
}

public struct ThemedStatCard: View {
    private let title: String
    private let value: String
    private let subtitle: String?
    private let icon: Image?
    private let trend: TrendDirection?
    private let trendValue: String?
    
    @Environment(\.theme) private var theme
    
    public enum TrendDirection {
        case up, down, neutral
        
        var color: Color {
            switch self {
            case .up: return .green
            case .down: return .red
            case .neutral: return .gray
            }
        }
        
        var icon: String {
            switch self {
            case .up: return "arrow.up"
            case .down: return "arrow.down"
            case .neutral: return "minus"
            }
        }
    }
    
    public init(
        title: String,
        value: String,
        subtitle: String? = nil,
        icon: Image? = nil,
        trend: TrendDirection? = nil,
        trendValue: String? = nil
    ) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.icon = icon
        self.trend = trend
        self.trendValue = trendValue
    }
    
    public var body: some View {
        ThemedCard {
            VStack(alignment: .leading, spacing: theme.spacing.sm) {
                HStack {
                    if let icon = icon {
                        icon
                            .foregroundColor(theme.primaryColor)
                    }
                    
                    Text(title)
                        .font(theme.typography.bodySmall)
                        .foregroundColor(theme.textSecondary)
                    
                    Spacer()
                    
                    if let trend = trend, let trendValue = trendValue {
                        HStack(spacing: 2) {
                            Image(systemName: trend.icon)
                                .font(.caption2)
                            Text(trendValue)
                                .font(theme.typography.bodySmall)
                        }
                        .foregroundColor(trend.color)
                    }
                }
                
                Text(value)
                    .font(theme.titleMediumFont)
                    .foregroundColor(theme.textPrimary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(theme.typography.bodySmall)
                        .foregroundColor(theme.textTertiary)
                }
            }
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        ThemedStatCard(
            title: "Current Weight",
            value: "185 lbs",
            subtitle: "Goal: 180 lbs",
            icon: Image(systemName: "scalemass"),
            trend: .down,
            trendValue: "-2.3%"
        )
        
        ThemedStatCard(
            title: "Workouts This Week",
            value: "4",
            subtitle: "Target: 5",
            icon: Image(systemName: "figure.strengthtraining.traditional"),
            trend: .up,
            trendValue: "+25%"
        )
        
        ThemedCard {
            VStack(alignment: .leading) {
                Text("Custom Card")
                    .font(.headline)
                Text("This is a custom card with custom content inside.")
                    .font(.body)
            }
        }
    }
    .padding()
    .theme(FitnessTheme())
}