import SwiftUI

public struct FloatingActionButton: View {
    public enum FABSize {
        case normal
        case mini
        case extended
        
        var diameter: CGFloat {
            switch self {
            case .normal: return 56
            case .mini: return 40
            case .extended: return 48
            }
        }
        
        var iconSize: Font {
            switch self {
            case .normal: return .title2
            case .mini: return .body
            case .extended: return .title3
            }
        }
    }
    
    public enum FABStyle {
        case primary
        case secondary
        case surface
        case custom(Color)
        
        func backgroundColor(theme: any ThemeProtocol) -> Color {
            switch self {
            case .primary: return theme.primaryColor
            case .secondary: return theme.secondaryColor
            case .surface: return theme.surfaceColor
            case .custom(let color): return color
            }
        }
        
        func foregroundColor(theme: any ThemeProtocol) -> Color {
            switch self {
            case .primary: return theme.textOnPrimary
            case .secondary: return theme.textOnSecondary
            case .surface: return theme.textPrimary
            case .custom: return .white
            }
        }
    }
    
    private let icon: String
    private let text: String?
    private let size: FABSize
    private let style: FABStyle
    private let action: () -> Void
    private let isVisible: Bool
    
    @Environment(\.theme) private var theme
    @State private var isPressed = false
    @State private var animationOffset: CGFloat = 0
    
    public init(
        icon: String,
        text: String? = nil,
        size: FABSize = .normal,
        style: FABStyle = .primary,
        isVisible: Bool = true,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.text = text
        self.size = size
        self.style = style
        self.isVisible = isVisible
        self.action = action
    }
    
    public var body: some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            action()
        }) {
            HStack(spacing: theme.spacing.sm) {
                Image(systemName: icon)
                    .font(size.iconSize)
                    .foregroundColor(style.foregroundColor(theme: theme))
                
                if let text = text, size == .extended {
                    Text(text)
                        .font(theme.typography.labelLarge)
                        .foregroundColor(style.foregroundColor(theme: theme))
                }
            }
            .frame(
                width: size == .extended && text != nil ? nil : size.diameter,
                height: size.diameter
            )
            .padding(.horizontal, size == .extended && text != nil ? theme.spacing.md : 0)
            .background(
                RoundedRectangle(cornerRadius: size == .extended ? theme.cornerRadius.button : theme.cornerRadius.round)
                    .fill(style.backgroundColor(theme: theme))
                    .shadow(
                        color: theme.shadows.lg.color,
                        radius: isPressed ? theme.shadows.sm.radius : theme.shadows.lg.radius,
                        x: theme.shadows.lg.x,
                        y: isPressed ? theme.shadows.sm.y : theme.shadows.lg.y
                    )
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .offset(y: animationOffset)
            .opacity(isVisible ? 1.0 : 0.0)
            .scaleEffect(isVisible ? 1.0 : 0.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            // Entrance animation
            animationOffset = 100
            withAnimation(theme.animations.springNormal.delay(0.2)) {
                animationOffset = 0
            }
        }
        .animation(theme.animations.springFast, value: isVisible)
        .animation(theme.animations.buttonPress, value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    isPressed = true
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
    }
}

// MARK: - FAB Menu
public struct FABMenu: View {
    public struct MenuItem: Identifiable {
        public let id = UUID()
        public let icon: String
        public let title: String
        public let action: () -> Void
        
        public init(icon: String, title: String, action: @escaping () -> Void) {
            self.icon = icon
            self.title = title
            self.action = action
        }
    }
    
    private let mainIcon: String
    private let items: [MenuItem]
    private let style: FloatingActionButton.FABStyle
    private let isVisible: Bool
    
    @Environment(\.theme) private var theme
    @State private var isExpanded = false
    @State private var animationProgress: CGFloat = 0
    
    public init(
        mainIcon: String = "plus",
        items: [MenuItem],
        style: FloatingActionButton.FABStyle = .primary,
        isVisible: Bool = true
    ) {
        self.mainIcon = mainIcon
        self.items = items
        self.style = style
        self.isVisible = isVisible
    }
    
    public var body: some View {
        VStack(spacing: theme.spacing.sm) {
            // Menu items
            ForEach(items.reversed().indices, id: \.self) { index in
                let item = items.reversed()[index]
                
                HStack(spacing: theme.spacing.sm) {
                    if isExpanded {
                        Text(item.title)
                            .font(theme.typography.labelMedium)
                            .foregroundColor(theme.textPrimary)
                            .padding(.horizontal, theme.spacing.sm)
                            .padding(.vertical, theme.spacing.xs)
                            .background(
                                RoundedRectangle(cornerRadius: theme.cornerRadius.sm)
                                    .fill(theme.cardColor)
                                    .shadow(
                                        color: theme.shadows.sm.color,
                                        radius: theme.shadows.sm.radius,
                                        x: theme.shadows.sm.x,
                                        y: theme.shadows.sm.y
                                    )
                            )
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .move(edge: .trailing)),
                                removal: .opacity.combined(with: .move(edge: .trailing))
                            ))
                    }
                    
                    FloatingActionButton(
                        icon: item.icon,
                        size: .mini,
                        style: .surface,
                        isVisible: isExpanded,
                        action: {
                            item.action()
                            withAnimation(theme.animations.springFast) {
                                isExpanded = false
                            }
                        }
                    )
                    .offset(y: isExpanded ? 0 : CGFloat(index + 1) * -8)
                    .opacity(isExpanded ? 1.0 : 0.0)
                    .scaleEffect(isExpanded ? 1.0 : 0.0)
                    .animation(
                        theme.animations.springNormal.delay(Double(index) * 0.05),
                        value: isExpanded
                    )
                }
            }
            
            // Main FAB
            FloatingActionButton(
                icon: isExpanded ? "xmark" : mainIcon,
                style: style,
                isVisible: isVisible,
                action: {
                    withAnimation(theme.animations.springNormal) {
                        isExpanded.toggle()
                    }
                }
            )
            .rotationEffect(.degrees(isExpanded ? 45 : 0))
            .animation(theme.animations.springFast, value: isExpanded)
        }
    }
}

// MARK: - FAB with Badge
public struct FloatingActionButtonWithBadge: View {
    private let fab: FloatingActionButton
    private let badgeCount: Int
    private let maxBadgeCount: Int
    
    @Environment(\.theme) private var theme
    
    public init(
        icon: String,
        text: String? = nil,
        size: FloatingActionButton.FABSize = .normal,
        style: FloatingActionButton.FABStyle = .primary,
        badgeCount: Int,
        maxBadgeCount: Int = 99,
        isVisible: Bool = true,
        action: @escaping () -> Void
    ) {
        self.fab = FloatingActionButton(
            icon: icon,
            text: text,
            size: size,
            style: style,
            isVisible: isVisible,
            action: action
        )
        self.badgeCount = badgeCount
        self.maxBadgeCount = maxBadgeCount
    }
    
    public var body: some View {
        ZStack(alignment: .topTrailing) {
            fab
            
            if badgeCount > 0 {
                BadgeView(count: badgeCount, maxCount: maxBadgeCount)
                    .offset(x: 8, y: -8)
            }
        }
    }
    
    private struct BadgeView: View {
        let count: Int
        let maxCount: Int
        
        @Environment(\.theme) private var theme
        
        var body: some View {
            Text(displayText)
                .font(theme.typography.labelSmall)
                .foregroundColor(.white)
                .padding(.horizontal, count > 9 ? theme.spacing.xs : 0)
                .frame(minWidth: 20, minHeight: 20)
                .background(
                    Circle()
                        .fill(theme.errorColor)
                )
        }
        
        private var displayText: String {
            if count > maxCount {
                return "\(maxCount)+"
            }
            return "\(count)"
        }
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Color(.systemGroupedBackground)
            .ignoresSafeArea()
        
        VStack(spacing: 40) {
            HStack(spacing: 20) {
                FloatingActionButton(icon: "plus", size: .mini) {}
                FloatingActionButton(icon: "heart.fill", size: .normal) {}
                FloatingActionButton(icon: "message", text: "Chat", size: .extended) {}
            }
            
            HStack(spacing: 20) {
                FloatingActionButton(icon: "plus", style: .secondary) {}
                FloatingActionButton(icon: "plus", style: .surface) {}
                FloatingActionButton(icon: "plus", style: .custom(.purple)) {}
            }
            
            FloatingActionButtonWithBadge(
                icon: "bell",
                badgeCount: 3
            ) {}
            
            Spacer()
            
            HStack {
                Spacer()
                
                VStack {
                    Spacer()
                    
                    FABMenu(
                        items: [
                            FABMenu.MenuItem(icon: "plus", title: "Add Workout") {},
                            FABMenu.MenuItem(icon: "camera", title: "Take Photo") {},
                            FABMenu.MenuItem(icon: "chart.bar", title: "View Stats") {}
                        ]
                    )
                }
            }
            .padding()
        }
        .padding()
    }
    .theme(FitnessTheme())
}