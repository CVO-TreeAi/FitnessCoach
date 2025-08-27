import SwiftUI

// MARK: - Tab Item Data Model
public struct TabItem: Identifiable, Hashable {
    public let id = UUID()
    public let title: String
    public let icon: String
    public let selectedIcon: String?
    public let badgeCount: Int
    
    public init(title: String, icon: String, selectedIcon: String? = nil, badgeCount: Int = 0) {
        self.title = title
        self.icon = icon
        self.selectedIcon = selectedIcon
        self.badgeCount = badgeCount
    }
    
    public var displayIcon: String {
        selectedIcon ?? icon
    }
}

public struct AnimatedTabBar: View {
    public enum TabBarStyle {
        case floating
        case standard
        case minimal
        case curved
    }
    
    public enum AnimationStyle {
        case bounce
        case scale
        case slide
        case morphing
        case liquid
    }
    
    private let items: [TabItem]
    private let selectedIndex: Int
    private let style: TabBarStyle
    private let animationStyle: AnimationStyle
    private let showLabels: Bool
    private let onItemTapped: (Int) -> Void
    
    @Environment(\.theme) private var theme
    @State private var animationOffset: CGSize = .zero
    @State private var selectedItemScale: CGFloat = 1.0
    @State private var morphingProgress: CGFloat = 0
    
    public init(
        items: [TabItem],
        selectedIndex: Int,
        style: TabBarStyle = .floating,
        animationStyle: AnimationStyle = .bounce,
        showLabels: Bool = true,
        onItemTapped: @escaping (Int) -> Void
    ) {
        self.items = items
        self.selectedIndex = selectedIndex
        self.style = style
        self.animationStyle = animationStyle
        self.showLabels = showLabels
        self.onItemTapped = onItemTapped
    }
    
    public var body: some View {
        Group {
            switch style {
            case .floating:
                floatingTabBar
            case .standard:
                standardTabBar
            case .minimal:
                minimalTabBar
            case .curved:
                curvedTabBar
            }
        }
    }
    
    // MARK: - Floating Tab Bar
    
    private var floatingTabBar: some View {
        VStack {
            Spacer()
            
            HStack(spacing: 0) {
                ForEach(items.indices, id: \.self) { index in
                    tabItemView(at: index, isFloating: true)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, theme.spacing.md)
            .padding(.vertical, theme.spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: theme.cornerRadius.xxl)
                    .fill(theme.cardColor)
                    .shadow(
                        color: theme.shadows.lg.color,
                        radius: theme.shadows.lg.radius,
                        x: theme.shadows.lg.x,
                        y: theme.shadows.lg.y
                    )
            )
            .overlay(
                // Animated selection indicator
                RoundedRectangle(cornerRadius: theme.cornerRadius.xl)
                    .fill(theme.primaryColor.opacity(0.1))
                    .frame(width: indicatorWidth, height: 40)
                    .offset(x: indicatorOffset)
                    .animation(animationForStyle, value: selectedIndex)
            )
            .padding(.horizontal, theme.spacing.lg)
            .padding(.bottom, theme.spacing.md)
        }
    }
    
    // MARK: - Standard Tab Bar
    
    private var standardTabBar: some View {
        VStack(spacing: 0) {
            // Top border
            Rectangle()
                .fill(theme.surfaceColor)
                .frame(height: 0.5)
            
            HStack(spacing: 0) {
                ForEach(items.indices, id: \.self) { index in
                    tabItemView(at: index, isFloating: false)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, theme.spacing.sm)
            .background(theme.backgroundColor)
        }
    }
    
    // MARK: - Minimal Tab Bar
    
    private var minimalTabBar: some View {
        HStack(spacing: theme.spacing.xl) {
            ForEach(items.indices, id: \.self) { index in
                Button(action: { handleTap(index) }) {
                    VStack(spacing: theme.spacing.xs) {
                        Image(systemName: selectedIndex == index ? items[index].displayIcon : items[index].icon)
                            .font(.title2)
                            .foregroundColor(selectedIndex == index ? theme.primaryColor : theme.textTertiary)
                            .scaleEffect(selectedIndex == index ? 1.2 : 1.0)
                        
                        if showLabels {
                            Text(items[index].title)
                                .font(theme.typography.labelSmall)
                                .foregroundColor(selectedIndex == index ? theme.primaryColor : theme.textTertiary)
                        }
                    }
                    .animation(animationForStyle, value: selectedIndex)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, theme.spacing.lg)
        .padding(.vertical, theme.spacing.md)
    }
    
    // MARK: - Curved Tab Bar
    
    private var curvedTabBar: some View {
        ZStack {
            // Curved background
            CurvedTabBarShape()
                .fill(theme.cardColor)
                .shadow(
                    color: theme.shadows.lg.color,
                    radius: theme.shadows.lg.radius,
                    x: theme.shadows.lg.x,
                    y: theme.shadows.lg.y
                )
            
            HStack(spacing: 0) {
                ForEach(items.indices, id: \.self) { index in
                    tabItemView(at: index, isFloating: false)
                        .frame(maxWidth: .infinity)
                        .offset(y: selectedIndex == index ? -10 : 0)
                        .animation(theme.animations.springNormal, value: selectedIndex)
                }
            }
            .padding(.horizontal, theme.spacing.lg)
            .padding(.vertical, theme.spacing.md)
        }
        .frame(height: 80)
    }
    
    // MARK: - Tab Item View
    
    private func tabItemView(at index: Int, isFloating: Bool) -> some View {
        let item = items[index]
        let isSelected = selectedIndex == index
        
        return Button(action: { handleTap(index) }) {
            VStack(spacing: theme.spacing.xs) {
                ZStack {
                    // Icon background for floating style
                    if isFloating && isSelected {
                        Circle()
                            .fill(theme.primaryColor)
                            .frame(width: 32, height: 32)
                            .scaleEffect(selectedItemScale)
                            .animation(animationForStyle, value: selectedIndex)
                    }
                    
                    // Icon with badge
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: isSelected ? item.displayIcon : item.icon)
                            .font(.title3)
                            .foregroundColor(iconColor(isSelected: isSelected, isFloating: isFloating))
                            .scaleEffect(iconScale(isSelected: isSelected))
                            .offset(animationOffset)
                        
                        // Badge
                        if item.badgeCount > 0 {
                            BadgeView(count: item.badgeCount)
                                .scaleEffect(0.8)
                                .offset(x: 8, y: -8)
                        }
                    }
                }
                
                // Label
                if showLabels {
                    Text(item.title)
                        .font(theme.typography.labelSmall)
                        .foregroundColor(labelColor(isSelected: isSelected))
                        .scaleEffect(isSelected ? 1.05 : 1.0)
                }
            }
            .animation(animationForStyle, value: selectedIndex)
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            if isSelected {
                triggerSelectionAnimation()
            }
        }
    }
    
    // MARK: - Helper Views
    
    private struct BadgeView: View {
        let count: Int
        
        @Environment(\.theme) private var theme
        
        var body: some View {
            Text(count > 99 ? "99+" : "\(count)")
                .font(theme.typography.labelSmall)
                .foregroundColor(.white)
                .padding(.horizontal, count > 9 ? theme.spacing.xs : 0)
                .frame(minWidth: 16, minHeight: 16)
                .background(
                    Capsule()
                        .fill(theme.errorColor)
                )
        }
    }
    
    private struct CurvedTabBarShape: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            
            let curveHeight: CGFloat = 20
            let curveWidth: CGFloat = 80
            let centerX = rect.midX
            
            path.move(to: CGPoint(x: 0, y: curveHeight))
            
            // Left curve
            path.addLine(to: CGPoint(x: centerX - curveWidth/2, y: curveHeight))
            path.addQuadCurve(
                to: CGPoint(x: centerX + curveWidth/2, y: curveHeight),
                control: CGPoint(x: centerX, y: -curveHeight/2)
            )
            
            // Right side
            path.addLine(to: CGPoint(x: rect.maxX, y: curveHeight))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: 0, y: rect.maxY))
            path.closeSubpath()
            
            return path
        }
    }
    
    // MARK: - Helper Methods
    
    private func handleTap(_ index: Int) {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        triggerSelectionAnimation()
        onItemTapped(index)
    }
    
    private func triggerSelectionAnimation() {
        switch animationStyle {
        case .bounce:
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                selectedItemScale = 1.2
            }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6).delay(0.1)) {
                selectedItemScale = 1.0
            }
            
        case .scale:
            withAnimation(theme.animations.springFast) {
                selectedItemScale = 1.3
            }
            withAnimation(theme.animations.springFast.delay(0.1)) {
                selectedItemScale = 1.0
            }
            
        case .slide:
            withAnimation(theme.animations.springFast) {
                animationOffset = CGSize(width: 0, height: -5)
            }
            withAnimation(theme.animations.springFast.delay(0.1)) {
                animationOffset = .zero
            }
            
        case .morphing:
            withAnimation(theme.animations.springNormal) {
                morphingProgress = 1.0
            }
            withAnimation(theme.animations.springNormal.delay(0.2)) {
                morphingProgress = 0.0
            }
            
        case .liquid:
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                selectedItemScale = 1.4
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1)) {
                selectedItemScale = 1.0
            }
        }
    }
    
    private func iconColor(isSelected: Bool, isFloating: Bool) -> Color {
        if isSelected {
            return isFloating ? .white : theme.primaryColor
        }
        return theme.textTertiary
    }
    
    private func labelColor(isSelected: Bool) -> Color {
        isSelected ? theme.primaryColor : theme.textTertiary
    }
    
    private func iconScale(isSelected: Bool) -> CGFloat {
        switch animationStyle {
        case .scale, .bounce, .liquid:
            return isSelected ? selectedItemScale : 1.0
        default:
            return isSelected ? 1.1 : 1.0
        }
    }
    
    private var indicatorWidth: CGFloat {
        guard !items.isEmpty else { return 0 }
        return UIScreen.main.bounds.width / CGFloat(items.count) * 0.8
    }
    
    private var indicatorOffset: CGFloat {
        let itemWidth = UIScreen.main.bounds.width / CGFloat(items.count)
        let baseOffset = itemWidth * CGFloat(selectedIndex)
        let centeringOffset = itemWidth / 2 - indicatorWidth / 2
        return baseOffset + centeringOffset - UIScreen.main.bounds.width / 2 + theme.spacing.lg
    }
    
    private var animationForStyle: Animation {
        switch animationStyle {
        case .bounce:
            return .spring(response: 0.5, dampingFraction: 0.7)
        case .scale:
            return theme.animations.springFast
        case .slide:
            return theme.animations.easeInOut
        case .morphing:
            return .easeInOut(duration: 0.3)
        case .liquid:
            return .spring(response: 0.6, dampingFraction: 0.8)
        }
    }
}

// MARK: - Custom Tab Container
public struct AnimatedTabContainer<Content: View>: View {
    private let tabs: [TabItem]
    private let content: Content
    private let style: AnimatedTabBar.TabBarStyle
    private let animationStyle: AnimatedTabBar.AnimationStyle
    
    @State private var selectedIndex = 0
    
    public init(
        tabs: [TabItem],
        style: AnimatedTabBar.TabBarStyle = .floating,
        animationStyle: AnimatedTabBar.AnimationStyle = .bounce,
        @ViewBuilder content: () -> Content
    ) {
        self.tabs = tabs
        self.style = style
        self.animationStyle = animationStyle
        self.content = content()
    }
    
    public var body: some View {
        ZStack(alignment: .bottom) {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            AnimatedTabBar(
                items: tabs,
                selectedIndex: selectedIndex,
                style: style,
                animationStyle: animationStyle
            ) { index in
                selectedIndex = index
            }
        }
    }
}

// MARK: - Preview
#Preview {
    AnimatedTabContainer(
        tabs: [
            TabItem(title: "Home", icon: "house", selectedIcon: "house.fill"),
            TabItem(title: "Workouts", icon: "figure.strengthtraining.traditional", badgeCount: 2),
            TabItem(title: "Progress", icon: "chart.line.uptrend.xyaxis"),
            TabItem(title: "Nutrition", icon: "leaf", selectedIcon: "leaf.fill"),
            TabItem(title: "Profile", icon: "person", selectedIcon: "person.fill", badgeCount: 1)
        ],
        style: .floating,
        animationStyle: .bounce
    ) {
        LinearGradient(
            colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        
        VStack(spacing: 40) {
            Text("Tab Content")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            VStack(spacing: 20) {
                ForEach([
                    ("Standard", AnimatedTabBar.TabBarStyle.standard),
                    ("Floating", AnimatedTabBar.TabBarStyle.floating),
                    ("Minimal", AnimatedTabBar.TabBarStyle.minimal),
                    ("Curved", AnimatedTabBar.TabBarStyle.curved)
                ], id: \.0) { title, tabStyle in
                    
                    VStack {
                        Text(title)
                            .font(.headline)
                        
                        AnimatedTabBar(
                            items: [
                                TabItem(title: "Home", icon: "house", selectedIcon: "house.fill"),
                                TabItem(title: "Search", icon: "magnifyingglass", badgeCount: 3),
                                TabItem(title: "Heart", icon: "heart", selectedIcon: "heart.fill")
                            ],
                            selectedIndex: 1,
                            style: tabStyle,
                            animationStyle: .bounce
                        ) { _ in }
                    }
                }
            }
        }
    }
    .theme(FitnessTheme())
}