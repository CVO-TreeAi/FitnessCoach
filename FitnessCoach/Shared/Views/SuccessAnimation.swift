import SwiftUI

// MARK: - Success Animation
public struct SuccessAnimation: View {
    public enum AnimationType {
        case checkmark
        case thumbsUp
        case trophy
        case star
        case heart
        case flame
        case medal
        case confetti
    }
    
    public enum AnimationStyle {
        case bounce
        case scale
        case rotate
        case pulse
        case sparkle
        case celebration
    }
    
    private let type: AnimationType
    private let style: AnimationStyle
    private let color: Color
    private let size: CGFloat
    private let isAnimating: Bool
    private let onComplete: (() -> Void)?
    
    @Environment(\.theme) private var theme
    @State private var animationPhase = 0.0
    @State private var scaleEffect = 0.0
    @State private var rotationEffect = 0.0
    @State private var offsetEffect: CGSize = .zero
    @State private var opacityEffect = 0.0
    @State private var showConfetti = false
    
    public init(
        type: AnimationType = .checkmark,
        style: AnimationStyle = .bounce,
        color: Color? = nil,
        size: CGFloat = 60,
        isAnimating: Bool = true,
        onComplete: (() -> Void)? = nil
    ) {
        self.type = type
        self.style = style
        self.color = color ?? .green
        self.size = size
        self.isAnimating = isAnimating
        self.onComplete = onComplete
    }
    
    public var body: some View {
        ZStack {
            if style == .celebration {
                confettiBackground
            }
            
            mainAnimation
            
            if style == .sparkle {
                sparkleEffect
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
            } else {
                resetAnimation()
            }
        }
    }
    
    // MARK: - Main Animation
    
    private var mainAnimation: some View {
        Group {
            switch type {
            case .checkmark:
                checkmarkView
            case .thumbsUp:
                thumbsUpView
            case .trophy:
                trophyView
            case .star:
                starView
            case .heart:
                heartView
            case .flame:
                flameView
            case .medal:
                medalView
            case .confetti:
                confettiView
            }
        }
        .font(.system(size: size * 0.6, weight: .bold))
        .foregroundColor(color)
        .scaleEffect(scaleEffect)
        .rotationEffect(.degrees(rotationEffect))
        .offset(offsetEffect)
        .opacity(opacityEffect)
    }
    
    private var checkmarkView: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.2))
                .frame(width: size, height: size)
            
            Circle()
                .stroke(color, lineWidth: 3)
                .frame(width: size, height: size)
            
            Image(systemName: "checkmark")
                .font(.system(size: size * 0.4, weight: .bold))
        }
    }
    
    private var thumbsUpView: some View {
        ZStack {
            Circle()
                .fill(LinearGradient(
                    colors: [color.opacity(0.2), color.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: size, height: size)
            
            Image(systemName: "hand.thumbsup.fill")
                .foregroundColor(color)
        }
    }
    
    private var trophyView: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(
                    colors: [Color.yellow.opacity(0.3), Color.orange.opacity(0.1)],
                    center: .center,
                    startRadius: 0,
                    endRadius: size/2
                ))
                .frame(width: size, height: size)
            
            Image(systemName: "trophy.fill")
                .foregroundColor(Color.yellow)
        }
    }
    
    private var starView: some View {
        ZStack {
            ForEach(0..<5, id: \.self) { index in
                Image(systemName: "star.fill")
                    .foregroundColor(Color.yellow)
                    .font(.system(size: size * 0.15))
                    .offset(starOffset(for: index))
                    .opacity(starOpacity(for: index))
                    .scaleEffect(starScale(for: index))
            }
            
            Image(systemName: "star.fill")
                .foregroundColor(color)
                .font(.system(size: size * 0.4))
        }
    }
    
    private var heartView: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { index in
                Image(systemName: "heart.fill")
                    .foregroundColor(Color.pink.opacity(heartOpacity(for: index)))
                    .font(.system(size: size * heartScale(for: index)))
                    .offset(heartOffset(for: index))
            }
            
            Image(systemName: "heart.fill")
                .foregroundColor(color)
        }
    }
    
    private var flameView: some View {
        ZStack {
            ForEach(0..<4, id: \.self) { index in
                Image(systemName: "flame.fill")
                    .foregroundColor(flameColor(for: index))
                    .font(.system(size: size * flameScale(for: index)))
                    .offset(flameOffset(for: index))
                    .opacity(flameOpacity(for: index))
            }
        }
    }
    
    private var medalView: some View {
        ZStack {
            Circle()
                .fill(LinearGradient(
                    colors: [Color.yellow, Color.orange],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: size * 0.8, height: size * 0.8)
            
            Circle()
                .stroke(Color.orange, lineWidth: 3)
                .frame(width: size * 0.8, height: size * 0.8)
            
            Text("1")
                .font(.system(size: size * 0.3, weight: .black))
                .foregroundColor(.white)
        }
    }
    
    private var confettiView: some View {
        Image(systemName: "party.popper.fill")
            .foregroundColor(color)
    }
    
    // MARK: - Background Effects
    
    private var confettiBackground: some View {
        ZStack {
            ForEach(0..<20, id: \.self) { index in
                confettiPiece(index: index)
            }
        }
        .opacity(showConfetti ? 1 : 0)
    }
    
    private func confettiPiece(index: Int) -> some View {
        let colors: [Color] = [.red, .blue, .green, .yellow, .purple, .orange, .pink]
        let color = colors[index % colors.count]
        
        return RoundedRectangle(cornerRadius: 2)
            .fill(color)
            .frame(width: 6, height: 6)
            .offset(confettiOffset(for: index))
            .rotationEffect(.degrees(confettiRotation(for: index)))
            .opacity(confettiOpacity(for: index))
    }
    
    private var sparkleEffect: some View {
        ZStack {
            ForEach(0..<8, id: \.self) { index in
                sparkle(index: index)
            }
        }
    }
    
    private func sparkle(index: Int) -> some View {
        Image(systemName: "sparkle")
            .foregroundColor(color.opacity(0.8))
            .font(.system(size: 12))
            .offset(sparkleOffset(for: index))
            .opacity(sparkleOpacity(for: index))
            .scaleEffect(sparkleScale(for: index))
    }
    
    // MARK: - Animation Logic
    
    private func startAnimation() {
        resetAnimation()
        
        switch style {
        case .bounce:
            bounceAnimation()
        case .scale:
            scaleAnimation()
        case .rotate:
            rotateAnimation()
        case .pulse:
            pulseAnimation()
        case .sparkle:
            sparkleAnimation()
        case .celebration:
            celebrationAnimation()
        }
    }
    
    private func resetAnimation() {
        animationPhase = 0
        scaleEffect = 0
        rotationEffect = 0
        offsetEffect = .zero
        opacityEffect = 0
        showConfetti = false
    }
    
    private func bounceAnimation() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            opacityEffect = 1
            scaleEffect = 1.5
        }
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1)) {
            scaleEffect = 1.0
        }
        
        withAnimation(.easeInOut(duration: 0.3).delay(0.6)) {
            offsetEffect = CGSize(width: 0, height: -10)
        }
        
        withAnimation(.easeInOut(duration: 0.3).delay(0.9)) {
            offsetEffect = .zero
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            onComplete?()
        }
    }
    
    private func scaleAnimation() {
        withAnimation(.easeOut(duration: 0.3)) {
            opacityEffect = 1
            scaleEffect = 1.3
        }
        
        withAnimation(.easeInOut(duration: 0.4).delay(0.3)) {
            scaleEffect = 1.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            onComplete?()
        }
    }
    
    private func rotateAnimation() {
        withAnimation(.easeOut(duration: 0.2)) {
            opacityEffect = 1
            scaleEffect = 1.0
        }
        
        withAnimation(.easeInOut(duration: 0.6).delay(0.2)) {
            rotationEffect = 360
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            onComplete?()
        }
    }
    
    private func pulseAnimation() {
        withAnimation(.easeOut(duration: 0.1)) {
            opacityEffect = 1
            scaleEffect = 1.0
        }
        
        withAnimation(.easeInOut(duration: 0.3).repeatCount(3, autoreverses: true).delay(0.1)) {
            scaleEffect = 1.2
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            onComplete?()
        }
    }
    
    private func sparkleAnimation() {
        withAnimation(.easeOut(duration: 0.3)) {
            opacityEffect = 1
            scaleEffect = 1.0
        }
        
        withAnimation(.linear(duration: 1.0).delay(0.3)) {
            animationPhase = 1.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            onComplete?()
        }
    }
    
    private func celebrationAnimation() {
        withAnimation(.easeOut(duration: 0.2)) {
            opacityEffect = 1
            scaleEffect = 1.2
        }
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.1)) {
            scaleEffect = 1.0
            showConfetti = true
        }
        
        withAnimation(.linear(duration: 2.0).delay(0.3)) {
            animationPhase = 1.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            onComplete?()
        }
    }
    
    // MARK: - Helper Functions
    
    private func starOffset(for index: Int) -> CGSize {
        let angle = Double(index) * 72 // 360/5 = 72 degrees
        let radius = size * 0.3 * animationPhase
        let x = cos(angle * .pi / 180) * radius
        let y = sin(angle * .pi / 180) * radius
        return CGSize(width: x, height: y)
    }
    
    private func starOpacity(for index: Int) -> Double {
        let phase = animationPhase * 5 - Double(index)
        return max(0, min(1, phase))
    }
    
    private func starScale(for index: Int) -> CGFloat {
        let phase = animationPhase * 5 - Double(index)
        return max(0.1, min(1.0, CGFloat(phase)))
    }
    
    private func heartOffset(for index: Int) -> CGSize {
        let angles: [Double] = [0, 120, 240]
        let angle = angles[index % angles.count]
        let radius = size * 0.2 * animationPhase
        let x = cos(angle * .pi / 180) * radius
        let y = sin(angle * .pi / 180) * radius
        return CGSize(width: x, height: y)
    }
    
    private func heartOpacity(for index: Int) -> Double {
        let phase = (animationPhase * 3 - Double(index))
        return max(0, min(0.8, phase))
    }
    
    private func heartScale(for index: Int) -> CGFloat {
        0.2 + CGFloat(index) * 0.15
    }
    
    private func flameColor(for index: Int) -> Color {
        let colors: [Color] = [.red, .orange, .yellow, .pink]
        return colors[index % colors.count]
    }
    
    private func flameScale(for index: Int) -> CGFloat {
        let baseScale = 0.3 + CGFloat(index) * 0.1
        let animatedScale = 1.0 + sin(animationPhase * .pi * 4 + Double(index)) * 0.2
        return baseScale * animatedScale
    }
    
    private func flameOffset(for index: Int) -> CGSize {
        let x = sin(animationPhase * .pi * 2 + Double(index)) * 5
        let y = cos(animationPhase * .pi * 3 + Double(index)) * 3
        return CGSize(width: x, height: y)
    }
    
    private func flameOpacity(for index: Int) -> Double {
        0.6 + sin(animationPhase * .pi * 3 + Double(index)) * 0.3
    }
    
    private func confettiOffset(for index: Int) -> CGSize {
        let progress = animationPhase
        let x = CGFloat.random(in: -100...100) * progress
        let y = CGFloat.random(in: -50...150) * progress
        return CGSize(width: x, height: y)
    }
    
    private func confettiRotation(for index: Int) -> Double {
        animationPhase * 360 * Double(index % 3 + 1)
    }
    
    private func confettiOpacity(for index: Int) -> Double {
        max(0, 1.0 - animationPhase * 1.2)
    }
    
    private func sparkleOffset(for index: Int) -> CGSize {
        let angle = Double(index) * 45 // 360/8 = 45 degrees
        let radius = size * 0.4 * animationPhase
        let x = cos(angle * .pi / 180) * radius
        let y = sin(angle * .pi / 180) * radius
        return CGSize(width: x, height: y)
    }
    
    private func sparkleOpacity(for index: Int) -> Double {
        let phase = (animationPhase * 8 - Double(index))
        return max(0, min(1, phase)) * (1 - animationPhase * 0.5)
    }
    
    private func sparkleScale(for index: Int) -> CGFloat {
        let phase = (animationPhase * 8 - Double(index))
        return max(0.1, min(1.0, CGFloat(phase)))
    }
}

// MARK: - Workout-Specific Success Animations
public struct WorkoutCompleteAnimation: View {
    private let isAnimating: Bool
    private let workoutType: String
    private let onComplete: (() -> Void)?
    
    @Environment(\.theme) private var theme
    
    public init(
        workoutType: String = "Workout",
        isAnimating: Bool = true,
        onComplete: (() -> Void)? = nil
    ) {
        self.workoutType = workoutType
        self.isAnimating = isAnimating
        self.onComplete = onComplete
    }
    
    public var body: some View {
        VStack(spacing: theme.spacing.lg) {
            SuccessAnimation(
                type: .trophy,
                style: .celebration,
                color: theme.primaryColor,
                size: 80,
                isAnimating: isAnimating
            )
            
            VStack(spacing: theme.spacing.sm) {
                Text("🎉 \(workoutType) Complete!")
                    .font(theme.typography.headlineLarge)
                    .foregroundColor(theme.textPrimary)
                    .fontWeight(.bold)
                
                Text("Great job! You've completed your workout.")
                    .font(theme.typography.bodyMedium)
                    .foregroundColor(theme.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(theme.spacing.xl)
        .background(
            RoundedRectangle(cornerRadius: theme.cornerRadius.card)
                .fill(theme.cardColor)
                .shadow(
                    color: theme.shadows.lg.color,
                    radius: theme.shadows.lg.radius,
                    x: theme.shadows.lg.x,
                    y: theme.shadows.lg.y
                )
        )
    }
}

public struct GoalAchievedAnimation: View {
    private let goalTitle: String
    private let isAnimating: Bool
    private let onComplete: (() -> Void)?
    
    @Environment(\.theme) private var theme
    
    public init(
        goalTitle: String,
        isAnimating: Bool = true,
        onComplete: (() -> Void)? = nil
    ) {
        self.goalTitle = goalTitle
        self.isAnimating = isAnimating
        self.onComplete = onComplete
    }
    
    public var body: some View {
        VStack(spacing: theme.spacing.lg) {
            SuccessAnimation(
                type: .medal,
                style: .sparkle,
                color: theme.successColor,
                size: 100,
                isAnimating: isAnimating
            )
            
            VStack(spacing: theme.spacing.sm) {
                Text("🏆 Goal Achieved!")
                    .font(theme.typography.displaySmall)
                    .foregroundColor(theme.successColor)
                    .fontWeight(.black)
                
                Text(goalTitle)
                    .font(theme.typography.headlineMedium)
                    .foregroundColor(theme.textPrimary)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                
                Text("You've reached another milestone!")
                    .font(theme.typography.bodyMedium)
                    .foregroundColor(theme.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(theme.spacing.xl)
        .background(
            RoundedRectangle(cornerRadius: theme.cornerRadius.card)
                .fill(
                    LinearGradient(
                        colors: [
                            theme.successColor.opacity(0.1),
                            theme.cardColor
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: theme.cornerRadius.card)
                        .stroke(theme.successColor.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Preview
#Preview {
    ScrollView {
        VStack(spacing: 40) {
            Text("Success Animations")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 20) {
                Group {
                    SuccessAnimation(type: .checkmark, style: .bounce, color: .green, size: 80)
                    SuccessAnimation(type: .thumbsUp, style: .scale, color: .blue, size: 80)
                    SuccessAnimation(type: .trophy, style: .celebration, color: .yellow, size: 80)
                    SuccessAnimation(type: .star, style: .sparkle, color: .purple, size: 80)
                    SuccessAnimation(type: .heart, style: .pulse, color: .pink, size: 80)
                    SuccessAnimation(type: .flame, style: .rotate, color: .orange, size: 80)
                }
            }
            
            WorkoutCompleteAnimation(workoutType: "Strength Training")
            
            GoalAchievedAnimation(goalTitle: "10,000 Steps Daily Goal")
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
    .theme(FitnessTheme())
}