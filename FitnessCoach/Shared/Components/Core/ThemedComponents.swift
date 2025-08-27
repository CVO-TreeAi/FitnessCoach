import SwiftUI

// MARK: - Themed Card Component
public struct ThemedCard<Content: View>: View {
    let content: Content
    @Environment(\.theme) private var theme
    
    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    public var body: some View {
        content
            .padding(theme.spacing.md)
            .background(theme.surfaceColor)
            .cornerRadius(theme.cornerRadius.medium)
            .shadow(color: theme.shadowColor.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Themed Stat Card
public struct ThemedStatCard: View {
    let title: String
    let value: String
    let subtitle: String?
    let icon: Image?
    let trend: TrendDirection?
    let trendValue: String?
    
    @Environment(\.theme) private var theme
    
    public enum TrendDirection {
        case up, down, neutral
        
        var color: Color {
            switch self {
            case .up: return .green
            case .down: return .red
            case .neutral: return .orange
            }
        }
        
        var icon: String {
            switch self {
            case .up: return "arrow.up.right"
            case .down: return "arrow.down.right"
            case .neutral: return "arrow.right"
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
                            .font(.title2)
                            .foregroundColor(theme.primaryColor)
                    }
                    
                    Spacer()
                    
                    if let trend = trend {
                        HStack(spacing: 2) {
                            Image(systemName: trend.icon)
                                .font(.caption)
                            if let trendValue = trendValue {
                                Text(trendValue)
                                    .font(.caption)
                            }
                        }
                        .foregroundColor(trend.color)
                    }
                }
                
                Text(value)
                    .font(theme.typography.titleLarge)
                    .foregroundColor(theme.textPrimary)
                    .fontWeight(.bold)
                
                Text(title)
                    .font(theme.typography.bodyMedium)
                    .foregroundColor(theme.textSecondary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(theme.typography.bodySmall)
                        .foregroundColor(theme.textTertiary)
                }
            }
        }
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
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(theme.typography.titleMedium)
                    .foregroundColor(theme.textPrimary)
                    .fontWeight(.semibold)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(theme.typography.bodySmall)
                        .foregroundColor(theme.textSecondary)
                }
            }
            
            Spacer()
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(theme.typography.bodyMedium)
                        .foregroundColor(theme.primaryColor)
                }
            }
        }
    }
}

// MARK: - Empty State View
public struct InlineEmptyStateView: View {
    let message: String
    let iconName: String
    
    @Environment(\.theme) private var theme
    
    public init(message: String, iconName: String) {
        self.message = message
        self.iconName = iconName
    }
    
    public var body: some View {
        ThemedCard {
            VStack(spacing: theme.spacing.md) {
                Image(systemName: iconName)
                    .font(.largeTitle)
                    .foregroundColor(theme.textTertiary)
                
                Text(message)
                    .font(theme.typography.bodyMedium)
                    .foregroundColor(theme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(theme.spacing.lg)
        }
    }
}

// MARK: - Loading View
public struct LoadingView: View {
    let message: String?
    
    @Environment(\.theme) private var theme
    
    public init(message: String? = nil) {
        self.message = message
    }
    
    public var body: some View {
        VStack(spacing: theme.spacing.md) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(theme.primaryColor)
            
            if let message = message {
                Text(message)
                    .font(theme.typography.bodyMedium)
                    .foregroundColor(theme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.backgroundColor.opacity(0.95))
    }
}

// MARK: - Action Button
public struct ActionButton: View {
    let title: String
    let icon: String?
    let style: ButtonStyle
    let action: () -> Void
    
    @Environment(\.theme) private var theme
    
    public enum ButtonStyle {
        case primary, secondary, danger, success
        
        func backgroundColor(for theme: any ThemeProtocol) -> Color {
            switch self {
            case .primary: return theme.primaryColor
            case .secondary: return theme.surfaceColor
            case .danger: return .red
            case .success: return .green
            }
        }
        
        func foregroundColor(for theme: any ThemeProtocol) -> Color {
            switch self {
            case .primary: return .white
            case .secondary: return theme.textPrimary
            case .danger: return .white
            case .success: return .white
            }
        }
    }
    
    public init(
        _ title: String,
        icon: String? = nil,
        style: ButtonStyle = .primary,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            HStack(spacing: theme.spacing.sm) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.body)
                }
                
                Text(title)
                    .font(theme.typography.bodyMedium)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, theme.spacing.lg)
            .padding(.vertical, theme.spacing.md)
            .background(style.backgroundColor(for: theme))
            .foregroundColor(style.foregroundColor(for: theme))
            .cornerRadius(theme.cornerRadius.medium)
        }
    }
}

// MARK: - Navigation Bar Title
public struct NavigationBarTitle: ViewModifier {
    let title: String
    let subtitle: String?
    
    @Environment(\.theme) private var theme
    
    public func body(content: Content) -> some View {
        content
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if let subtitle = subtitle {
                    ToolbarItem(placement: .principal) {
                        VStack(spacing: 0) {
                            Text(title)
                                .font(theme.typography.titleMedium)
                                .foregroundColor(theme.textPrimary)
                            Text(subtitle)
                                .font(theme.typography.bodySmall)
                                .foregroundColor(theme.textSecondary)
                        }
                    }
                }
            }
    }
}

public extension View {
    func navigationBarTitle(_ title: String, subtitle: String? = nil) -> some View {
        self.modifier(NavigationBarTitle(title: title, subtitle: subtitle))
    }
}

// MARK: - List Row Component
public struct ListRowItem: View {
    let title: String
    let subtitle: String?
    let leadingIcon: String?
    let trailingText: String?
    let action: (() -> Void)?
    
    @Environment(\.theme) private var theme
    
    public init(
        title: String,
        subtitle: String? = nil,
        leadingIcon: String? = nil,
        trailingText: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.leadingIcon = leadingIcon
        self.trailingText = trailingText
        self.action = action
    }
    
    public var body: some View {
        Button(action: action ?? {}) {
            HStack(spacing: theme.spacing.md) {
                if let leadingIcon = leadingIcon {
                    Image(systemName: leadingIcon)
                        .font(.title2)
                        .foregroundColor(theme.primaryColor)
                        .frame(width: 32)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(theme.typography.bodyMedium)
                        .foregroundColor(theme.textPrimary)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(theme.typography.bodySmall)
                            .foregroundColor(theme.textSecondary)
                    }
                }
                
                Spacer()
                
                if let trailingText = trailingText {
                    Text(trailingText)
                        .font(theme.typography.bodyMedium)
                        .foregroundColor(theme.textSecondary)
                }
                
                if action != nil {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(theme.textTertiary)
                }
            }
            .padding(.vertical, theme.spacing.sm)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(action == nil)
    }
}

// MARK: - Floating Action Button
public struct FloatingActionButton: View {
    let icon: String
    let action: () -> Void
    
    @Environment(\.theme) private var theme
    
    public init(icon: String, action: @escaping () -> Void) {
        self.icon = icon
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(theme.primaryColor)
                .clipShape(Circle())
                .shadow(
                    color: theme.primaryColor.opacity(0.3),
                    radius: 8,
                    x: 0,
                    y: 4
                )
        }
    }
}

// MARK: - Progress Ring
public struct ProgressRing: View {
    let progress: Double
    let lineWidth: CGFloat
    let size: CGFloat
    let primaryColor: Color
    let backgroundColor: Color
    
    @Environment(\.theme) private var theme
    
    public init(
        progress: Double,
        lineWidth: CGFloat = 8,
        size: CGFloat = 60,
        primaryColor: Color? = nil,
        backgroundColor: Color? = nil
    ) {
        self.progress = progress
        self.lineWidth = lineWidth
        self.size = size
        self.primaryColor = primaryColor ?? Color.blue
        self.backgroundColor = backgroundColor ?? Color.gray.opacity(0.2)
    }
    
    public var body: some View {
        ZStack {
            Circle()
                .stroke(backgroundColor, lineWidth: lineWidth)
            
            Circle()
                .trim(from: 0.0, to: min(progress, 1.0))
                .stroke(
                    primaryColor,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round,
                        lineJoin: .round
                    )
                )
                .rotationEffect(Angle(degrees: 270))
                .animation(.easeInOut, value: progress)
            
            Text("\(Int(progress * 100))%")
                .font(.system(size: size * 0.3, weight: .bold))
                .foregroundColor(theme.textPrimary)
        }
        .frame(width: size, height: size)
    }
}