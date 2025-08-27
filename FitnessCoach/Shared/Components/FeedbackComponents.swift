import SwiftUI

// MARK: - Toast Notifications

struct ToastView: View {
    let message: String
    let type: ToastType
    @Binding var isShowing: Bool
    @Environment(\.theme) private var theme
    
    enum ToastType {
        case success, error, info, warning
        
        var color: Color {
            switch self {
            case .success: return .green
            case .error: return .red
            case .info: return .blue
            case .warning: return .orange
            }
        }
        
        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .error: return "xmark.circle.fill"
            case .info: return "info.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: type.icon)
                .foregroundColor(type.color)
                .font(.title3)
            
            Text(message)
                .font(theme.typography.bodyMedium)
                .foregroundColor(theme.textPrimary)
            
            Spacer()
        }
        .padding()
        .background(theme.surfaceColor)
        .cornerRadius(theme.cornerRadius.medium)
        .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
        .transition(.asymmetric(
            insertion: .move(edge: .top).combined(with: .opacity),
            removal: .move(edge: .top).combined(with: .opacity)
        ))
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation {
                    isShowing = false
                }
            }
        }
    }
}

struct ToastModifier: ViewModifier {
    @Binding var toast: Toast?
    
    struct Toast: Equatable {
        let message: String
        let type: ToastView.ToastType
    }
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            VStack {
                if let toast = toast {
                    ToastView(
                        message: toast.message,
                        type: toast.type,
                        isShowing: Binding(
                            get: { self.toast != nil },
                            set: { if !$0 { self.toast = nil } }
                        )
                    )
                    .padding()
                }
                
                Spacer()
            }
        }
    }
}

extension View {
    func toast(_ toast: Binding<ToastModifier.Toast?>) -> some View {
        modifier(ToastModifier(toast: toast))
    }
}

// MARK: - Loading Overlays

struct LoadingOverlay: View {
    let message: String
    @Environment(\.theme) private var theme
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: theme.spacing.lg) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
                
                Text(message)
                    .font(theme.typography.bodyMedium)
                    .foregroundColor(.white)
            }
            .padding(theme.spacing.xl)
            .background(theme.surfaceColor)
            .cornerRadius(theme.cornerRadius.medium)
            .shadow(radius: 10)
        }
    }
}

// MARK: - Haptic Feedback

enum HapticFeedback {
    case light
    case medium
    case heavy
    case success
    case warning
    case error
    case selection
    
    func trigger() {
        let generator = UIImpactFeedbackGenerator(style: impactStyle)
        generator.prepare()
        generator.impactOccurred()
        
        if self == .success || self == .error || self == .warning {
            let notificationGenerator = UINotificationFeedbackGenerator()
            notificationGenerator.prepare()
            
            switch self {
            case .success:
                notificationGenerator.notificationOccurred(.success)
            case .error:
                notificationGenerator.notificationOccurred(.error)
            case .warning:
                notificationGenerator.notificationOccurred(.warning)
            default:
                break
            }
        }
    }
    
    private var impactStyle: UIImpactFeedbackGenerator.FeedbackStyle {
        switch self {
        case .light, .selection:
            return .light
        case .medium:
            return .medium
        case .heavy, .success, .warning, .error:
            return .heavy
        }
    }
}

// MARK: - Animated Buttons

struct AnimatedButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    @State private var isPressed = false
    @Environment(\.theme) private var theme
    
    init(title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }
    
    var body: some View {
        Button {
            HapticFeedback.light.trigger()
            action()
        } label: {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.body)
                }
                
                Text(title)
                    .font(theme.typography.bodyMedium)
                    .fontWeight(.medium)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(theme.primaryColor)
            .cornerRadius(theme.cornerRadius.medium)
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity) { _ in
            
        } onPressingChanged: { isPressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = isPressing
            }
        }
    }
}

// MARK: - Animated Card

struct AnimatedCard<Content: View>: View {
    let content: Content
    @State private var isPressed = false
    @Environment(\.theme) private var theme
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .background(theme.surfaceColor)
            .cornerRadius(theme.cornerRadius.medium)
            .shadow(color: .black.opacity(isPressed ? 0.05 : 0.1), 
                   radius: isPressed ? 2 : 5, 
                   y: isPressed ? 1 : 3)
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
            .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity) { _ in
                
            } onPressingChanged: { isPressing in
                isPressed = isPressing
                if isPressing {
                    HapticFeedback.light.trigger()
                }
            }
    }
}

// MARK: - Pull to Refresh

struct PullToRefresh: ViewModifier {
    let action: () async -> Void
    @State private var isRefreshing = false
    
    func body(content: Content) -> some View {
        content
            .refreshable {
                await action()
            }
    }
}

extension View {
    func pullToRefresh(action: @escaping () async -> Void) -> some View {
        modifier(PullToRefresh(action: action))
    }
}

// MARK: - Skeleton Loading

struct SkeletonView: View {
    @State private var isAnimating = false
    let width: CGFloat
    let height: CGFloat
    @Environment(\.theme) private var theme
    
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        theme.surfaceColor,
                        theme.surfaceColor.opacity(0.6),
                        theme.surfaceColor
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: width, height: height)
            .cornerRadius(theme.cornerRadius.small)
            .overlay(
                GeometryReader { geometry in
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0),
                                    Color.white.opacity(0.1),
                                    Color.white.opacity(0)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * 0.3)
                        .offset(x: isAnimating ? geometry.size.width : -geometry.size.width * 0.3)
                }
            )
            .onAppear {
                withAnimation(
                    Animation.linear(duration: 1.5)
                        .repeatForever(autoreverses: false)
                ) {
                    isAnimating = true
                }
            }
    }
}

// MARK: - Confetti Animation

struct ConfettiView: View {
    @State private var particles: [Particle] = []
    let trigger: Bool
    
    struct Particle: Identifiable {
        let id = UUID()
        let color: Color
        let size: CGFloat
        var position: CGPoint
        var velocity: CGVector
        var rotation: Double
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .position(particle.position)
                        .rotationEffect(.degrees(particle.rotation))
                }
            }
            .onChange(of: trigger) { _ in
                createConfetti(in: geometry.size)
            }
            .onAppear {
                Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
                    updateParticles()
                }
            }
        }
        .allowsHitTesting(false)
    }
    
    private func createConfetti(in size: CGSize) {
        let colors: [Color] = [.red, .blue, .green, .yellow, .orange, .purple, .pink]
        
        particles = (0..<50).map { _ in
            Particle(
                color: colors.randomElement()!,
                size: CGFloat.random(in: 4...8),
                position: CGPoint(x: size.width / 2, y: size.height / 2),
                velocity: CGVector(
                    dx: CGFloat.random(in: -5...5),
                    dy: CGFloat.random(in: -10...(-5))
                ),
                rotation: Double.random(in: 0...360)
            )
        }
    }
    
    private func updateParticles() {
        for i in particles.indices {
            particles[i].position.x += particles[i].velocity.dx
            particles[i].position.y += particles[i].velocity.dy
            particles[i].velocity.dy += 0.5 // Gravity
            particles[i].rotation += 5
        }
        
        particles = particles.filter { $0.position.y < UIScreen.main.bounds.height }
    }
}

// MARK: - Progress Ring

struct ProgressRing: View {
    let progress: Double
    let lineWidth: CGFloat
    let color: Color
    let showPercentage: Bool
    @Environment(\.theme) private var theme
    
    init(progress: Double, lineWidth: CGFloat = 10, color: Color, showPercentage: Bool = true) {
        self.progress = min(max(progress, 0), 1)
        self.lineWidth = lineWidth
        self.color = color
        self.showPercentage = showPercentage
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [color.opacity(0.7), color]),
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360 * progress)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 1.0), value: progress)
            
            if showPercentage {
                Text("\(Int(progress * 100))%")
                    .font(theme.typography.titleMedium)
                    .fontWeight(.bold)
                    .foregroundColor(theme.textPrimary)
            }
        }
    }
}

// MARK: - Sliding Tab View

struct SlidingTabView: View {
    @Binding var selectedTab: Int
    let tabs: [String]
    @Namespace private var namespace
    @Environment(\.theme) private var theme
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(tabs.enumerated()), id: \.offset) { index, tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedTab = index
                    }
                } label: {
                    VStack(spacing: 8) {
                        Text(tab)
                            .font(theme.typography.bodyMedium)
                            .fontWeight(selectedTab == index ? .medium : .regular)
                            .foregroundColor(selectedTab == index ? theme.primaryColor : theme.textSecondary)
                        
                        if selectedTab == index {
                            Rectangle()
                                .fill(theme.primaryColor)
                                .frame(height: 2)
                                .matchedGeometryEffect(id: "underline", in: namespace)
                        } else {
                            Rectangle()
                                .fill(Color.clear)
                                .frame(height: 2)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal)
        .background(theme.backgroundColor)
    }
}