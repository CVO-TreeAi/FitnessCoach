import SwiftUI

// MARK: - Pull to Refresh View
public struct PullToRefreshView<Content: View>: View {
    public enum RefreshState {
        case idle
        case pulling
        case refreshing
    }
    
    private let content: Content
    private let onRefresh: () async -> Void
    private let threshold: CGFloat
    private let maxPullDistance: CGFloat
    
    @Environment(\.theme) private var theme
    @State private var offset: CGFloat = 0
    @State private var refreshState: RefreshState = .idle
    @State private var rotationAngle: Double = 0
    @State private var scale: CGFloat = 1.0
    
    public init(
        threshold: CGFloat = 80,
        maxPullDistance: CGFloat = 120,
        onRefresh: @escaping () async -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.threshold = threshold
        self.maxPullDistance = maxPullDistance
        self.onRefresh = onRefresh
        self.content = content()
    }
    
    public var body: some View {
        GeometryReader { geometry in
            ScrollView {
                LazyVStack(spacing: 0) {
                    // Pull to refresh indicator
                    refreshIndicatorView
                        .frame(height: max(0, offset))
                        .opacity(offset > 10 ? 1 : 0)
                    
                    content
                }
                .background(
                    GeometryReader { contentGeometry in
                        Color.clear.preference(
                            key: OffsetPreferenceKey.self,
                            value: contentGeometry.frame(in: .named("scroll")).minY
                        )
                    }
                )
            }
            .coordinateSpace(name: "scroll")
            .onPreferenceChange(OffsetPreferenceKey.self) { value in
                handleOffsetChange(value)
            }
        }
        .refreshable {
            await onRefresh()
        }
    }
    
    private var refreshIndicatorView: some View {
        VStack(spacing: theme.spacing.sm) {
            HStack(spacing: theme.spacing.sm) {
                // Animated refresh icon
                Group {
                    switch refreshState {
                    case .idle:
                        Image(systemName: "arrow.down")
                            .foregroundColor(theme.textSecondary)
                            .rotationEffect(.degrees(rotationAngle))
                        
                    case .pulling:
                        Image(systemName: "arrow.down")
                            .foregroundColor(theme.primaryColor)
                            .rotationEffect(.degrees(180))
                        
                    case .refreshing:
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(theme.primaryColor)
                    }
                }
                .font(.title2)
                .scaleEffect(scale)
                
                // Status text
                Text(refreshStatusText)
                    .font(theme.typography.bodySmall)
                    .foregroundColor(refreshState == .refreshing ? theme.primaryColor : theme.textSecondary)
            }
            
            // Progress indicator
            if refreshState != .refreshing {
                ProgressView(value: min(offset / threshold, 1.0))
                    .tint(theme.primaryColor)
                    .frame(width: 60)
                    .scaleEffect(y: 0.5)
            }
        }
        .padding(.vertical, theme.spacing.sm)
        .animation(theme.animations.springFast, value: refreshState)
    }
    
    private var refreshStatusText: String {
        switch refreshState {
        case .idle:
            return "Pull to refresh"
        case .pulling:
            return "Release to refresh"
        case .refreshing:
            return "Refreshing..."
        }
    }
    
    private func handleOffsetChange(_ value: CGFloat) {
        guard refreshState != .refreshing else { return }
        
        let newOffset = max(0, value)
        offset = min(newOffset, maxPullDistance)
        
        // Update rotation angle for arrow
        withAnimation(.easeOut(duration: 0.1)) {
            rotationAngle = min(offset / threshold * 180, 180)
            scale = 1.0 + (offset / threshold * 0.3)
        }
        
        // Update refresh state
        if offset > threshold && refreshState == .idle {
            withAnimation(theme.animations.springFast) {
                refreshState = .pulling
            }
            
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
        } else if offset <= threshold && refreshState == .pulling {
            withAnimation(theme.animations.springFast) {
                refreshState = .idle
            }
        }
    }
    
    private func triggerRefresh() async {
        guard refreshState == .pulling else { return }
        
        withAnimation(theme.animations.springNormal) {
            refreshState = .refreshing
        }
        
        await onRefresh()
        
        withAnimation(theme.animations.springNormal) {
            refreshState = .idle
            offset = 0
        }
    }
}

// MARK: - Custom Refresh Indicators
public struct CustomRefreshIndicator: View {
    public enum Style {
        case spinner
        case dots
        case wave
        case bounce
        case pulse
    }
    
    private let style: Style
    private let isAnimating: Bool
    private let color: Color
    
    @Environment(\.theme) private var theme
    @State private var animationPhase: Double = 0
    
    public init(style: Style = .spinner, isAnimating: Bool, color: Color? = nil) {
        self.style = style
        self.isAnimating = isAnimating
        self.color = color ?? .blue
    }
    
    public var body: some View {
        Group {
            switch style {
            case .spinner:
                spinnerIndicator
            case .dots:
                dotsIndicator
            case .wave:
                waveIndicator
            case .bounce:
                bounceIndicator
            case .pulse:
                pulseIndicator
            }
        }
        .onAppear {
            if isAnimating {
                startAnimation()
            }
        }
        .onChange(of: isAnimating) { newValue in
            if newValue {
                startAnimation()
            }
        }
    }
    
    private var spinnerIndicator: some View {
        Circle()
            .trim(from: 0, to: 0.8)
            .stroke(
                AngularGradient(
                    colors: [color.opacity(0.2), color],
                    center: .center,
                    startAngle: .degrees(0),
                    endAngle: .degrees(360)
                ),
                style: StrokeStyle(lineWidth: 3, lineCap: .round)
            )
            .frame(width: 24, height: 24)
            .rotationEffect(.degrees(animationPhase))
    }
    
    private var dotsIndicator: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                    .scaleEffect(dotScale(for: index))
                    .animation(
                        .easeInOut(duration: 0.6)
                        .repeatForever()
                        .delay(Double(index) * 0.2),
                        value: animationPhase
                    )
            }
        }
    }
    
    private var waveIndicator: some View {
        HStack(spacing: 2) {
            ForEach(0..<5) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(color)
                    .frame(width: 3, height: waveHeight(for: index))
                    .animation(
                        .easeInOut(duration: 0.5)
                        .repeatForever()
                        .delay(Double(index) * 0.1),
                        value: animationPhase
                    )
            }
        }
    }
    
    private var bounceIndicator: some View {
        HStack(spacing: 6) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(color)
                    .frame(width: 10, height: 10)
                    .offset(y: bounceOffset(for: index))
                    .animation(
                        .easeInOut(duration: 0.8)
                        .repeatForever()
                        .delay(Double(index) * 0.2),
                        value: animationPhase
                    )
            }
        }
    }
    
    private var pulseIndicator: some View {
        ZStack {
            ForEach(0..<2) { index in
                Circle()
                    .fill(color.opacity(0.6))
                    .scaleEffect(pulseScale(for: index))
                    .opacity(pulseOpacity(for: index))
                    .animation(
                        .easeInOut(duration: 1.0)
                        .repeatForever()
                        .delay(Double(index) * 0.5),
                        value: animationPhase
                    )
            }
            
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
        }
        .frame(width: 32, height: 32)
    }
    
    private func startAnimation() {
        withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
            animationPhase = 360
        }
    }
    
    private func dotScale(for index: Int) -> CGFloat {
        let phase = (animationPhase + Double(index) * 120).truncatingRemainder(dividingBy: 360)
        return 0.5 + 0.5 * abs(sin(phase * .pi / 180))
    }
    
    private func waveHeight(for index: Int) -> CGFloat {
        let phase = (animationPhase + Double(index) * 72).truncatingRemainder(dividingBy: 360)
        return 6 + 8 * abs(sin(phase * .pi / 180))
    }
    
    private func bounceOffset(for index: Int) -> CGFloat {
        let phase = (animationPhase + Double(index) * 120).truncatingRemainder(dividingBy: 360)
        return -10 * abs(sin(phase * .pi / 180))
    }
    
    private func pulseScale(for index: Int) -> CGFloat {
        let phase = (animationPhase + Double(index) * 180).truncatingRemainder(dividingBy: 360)
        return 0.5 + 1.0 * (sin(phase * .pi / 180) + 1) / 2
    }
    
    private func pulseOpacity(for index: Int) -> Double {
        let phase = (animationPhase + Double(index) * 180).truncatingRemainder(dividingBy: 360)
        return 1.0 - (sin(phase * .pi / 180) + 1) / 2
    }
}

// MARK: - Fitness-themed Refresh Indicators
public struct FitnessRefreshIndicator: View {
    public enum FitnessStyle {
        case dumbbell
        case heartbeat
        case runner
        case flame
    }
    
    private let style: FitnessStyle
    private let isAnimating: Bool
    private let color: Color
    
    @Environment(\.theme) private var theme
    @State private var animationPhase: Double = 0
    @State private var heartbeatScale: CGFloat = 1.0
    
    public init(style: FitnessStyle, isAnimating: Bool, color: Color? = nil) {
        self.style = style
        self.isAnimating = isAnimating
        self.color = color ?? .red
    }
    
    public var body: some View {
        Group {
            switch style {
            case .dumbbell:
                dumbbellIndicator
            case .heartbeat:
                heartbeatIndicator
            case .runner:
                runnerIndicator
            case .flame:
                flameIndicator
            }
        }
        .onAppear {
            if isAnimating {
                startAnimation()
            }
        }
    }
    
    private var dumbbellIndicator: some View {
        Image(systemName: "dumbbell.fill")
            .font(.title2)
            .foregroundColor(color)
            .rotationEffect(.degrees(animationPhase))
            .scaleEffect(1.0 + 0.2 * sin(animationPhase * .pi / 180))
    }
    
    private var heartbeatIndicator: some View {
        Image(systemName: "heart.fill")
            .font(.title2)
            .foregroundColor(color)
            .scaleEffect(heartbeatScale)
            .onAppear {
                if isAnimating {
                    withAnimation(.easeInOut(duration: 0.6).repeatForever()) {
                        heartbeatScale = 1.3
                    }
                }
            }
    }
    
    private var runnerIndicator: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Image(systemName: "figure.run")
                    .font(.caption)
                    .foregroundColor(color.opacity(runnerOpacity(for: index)))
                    .scaleEffect(runnerScale(for: index))
            }
        }
    }
    
    private var flameIndicator: some View {
        VStack(spacing: -2) {
            ForEach(0..<3) { index in
                Image(systemName: "flame.fill")
                    .font(.caption)
                    .foregroundColor(color.opacity(flameOpacity(for: index)))
                    .scaleEffect(flameScale(for: index))
                    .offset(x: flameOffset(for: index))
            }
        }
    }
    
    private func startAnimation() {
        withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
            animationPhase = 360
        }
    }
    
    private func runnerOpacity(for index: Int) -> Double {
        let phase = (animationPhase + Double(index) * 120).truncatingRemainder(dividingBy: 360)
        return 0.3 + 0.7 * (sin(phase * .pi / 180) + 1) / 2
    }
    
    private func runnerScale(for index: Int) -> CGFloat {
        let phase = (animationPhase + Double(index) * 120).truncatingRemainder(dividingBy: 360)
        return 0.8 + 0.4 * (sin(phase * .pi / 180) + 1) / 2
    }
    
    private func flameOpacity(for index: Int) -> Double {
        let phase = (animationPhase + Double(index) * 90).truncatingRemainder(dividingBy: 360)
        return 0.4 + 0.6 * (sin(phase * .pi / 180) + 1) / 2
    }
    
    private func flameScale(for index: Int) -> CGFloat {
        let phase = (animationPhase + Double(index) * 90).truncatingRemainder(dividingBy: 360)
        return 0.6 + 0.8 * (sin(phase * .pi / 180) + 1) / 2
    }
    
    private func flameOffset(for index: Int) -> CGFloat {
        let phase = (animationPhase + Double(index) * 90).truncatingRemainder(dividingBy: 360)
        return 2 * sin(phase * .pi / 180)
    }
}

// MARK: - Preference Key
private struct OffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 40) {
        Text("Pull to Refresh Demo")
            .font(.title)
            .fontWeight(.bold)
        
        PullToRefreshView(onRefresh: {
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        }) {
            LazyVStack(spacing: 16) {
                ForEach(0..<20) { index in
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.opacity(0.1))
                        .frame(height: 60)
                        .overlay(
                            Text("Item \(index + 1)")
                                .font(.headline)
                        )
                }
            }
            .padding()
        }
        .frame(height: 300)
        .background(Color(.systemGroupedBackground))
        .cornerRadius(12)
        
        // Refresh indicators demo
        VStack(spacing: 20) {
            Text("Refresh Indicators")
                .font(.headline)
            
            HStack(spacing: 30) {
                CustomRefreshIndicator(style: .spinner, isAnimating: true)
                CustomRefreshIndicator(style: .dots, isAnimating: true, color: .green)
                CustomRefreshIndicator(style: .wave, isAnimating: true, color: .orange)
                CustomRefreshIndicator(style: .bounce, isAnimating: true, color: .purple)
                CustomRefreshIndicator(style: .pulse, isAnimating: true, color: .red)
            }
            
            HStack(spacing: 30) {
                FitnessRefreshIndicator(style: .dumbbell, isAnimating: true)
                FitnessRefreshIndicator(style: .heartbeat, isAnimating: true, color: .red)
                FitnessRefreshIndicator(style: .runner, isAnimating: true, color: .blue)
                FitnessRefreshIndicator(style: .flame, isAnimating: true, color: .orange)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
    .padding()
    .theme(FitnessTheme())
}