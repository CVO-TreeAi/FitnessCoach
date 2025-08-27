import SwiftUI

// MARK: - Segmented Progress Bar Data Models
public struct ProgressSegment: Identifiable {
    public let id = UUID()
    public let title: String
    public let progress: Double // 0.0 to 1.0
    public let color: Color
    public let isCompleted: Bool
    
    public init(title: String, progress: Double, color: Color, isCompleted: Bool = false) {
        self.title = title
        self.progress = max(0, min(1, progress))
        self.color = color
        self.isCompleted = isCompleted
    }
}

public struct SegmentedProgressBar: View {
    public enum Style {
        case horizontal
        case vertical
        case circular
        case stepped
    }
    
    public enum LabelPosition {
        case top
        case bottom
        case inline
        case none
    }
    
    private let segments: [ProgressSegment]
    private let style: Style
    private let labelPosition: LabelPosition
    private let showPercentages: Bool
    private let animated: Bool
    private let height: CGFloat
    
    @Environment(\.theme) private var theme
    @State private var animationProgress: CGFloat = 0
    
    public init(
        segments: [ProgressSegment],
        style: Style = .horizontal,
        labelPosition: LabelPosition = .bottom,
        showPercentages: Bool = false,
        animated: Bool = true,
        height: CGFloat = 8
    ) {
        self.segments = segments
        self.style = style
        self.labelPosition = labelPosition
        self.showPercentages = showPercentages
        self.animated = animated
        self.height = height
    }
    
    public var body: some View {
        Group {
            switch style {
            case .horizontal:
                horizontalProgressBar
            case .vertical:
                verticalProgressBar
            case .circular:
                circularProgressBar
            case .stepped:
                steppedProgressBar
            }
        }
        .onAppear {
            if animated {
                withAnimation(theme.animations.springNormal.delay(0.3)) {
                    animationProgress = 1.0
                }
            } else {
                animationProgress = 1.0
            }
        }
    }
    
    // MARK: - Horizontal Progress Bar
    
    private var horizontalProgressBar: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            if labelPosition == .top {
                labelsView
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(theme.surfaceColor)
                        .frame(height: height)
                    
                    // Progress segments
                    HStack(spacing: 2) {
                        ForEach(segments.indices, id: \.self) { index in
                            let segment = segments[index]
                            let segmentWidth = geometry.size.width / CGFloat(segments.count) - (CGFloat(segments.count - 1) * 2 / CGFloat(segments.count))
                            
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: height / 2)
                                    .fill(segment.color.opacity(0.2))
                                    .frame(width: segmentWidth, height: height)
                                
                                RoundedRectangle(cornerRadius: height / 2)
                                    .fill(segment.color)
                                    .frame(
                                        width: segmentWidth * CGFloat(segment.progress) * animationProgress,
                                        height: height
                                    )
                                    .animation(
                                        theme.animations.springNormal.delay(Double(index) * 0.1),
                                        value: animationProgress
                                    )
                                
                                if segment.isCompleted {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.white)
                                        .font(.caption2)
                                        .frame(width: height, height: height)
                                        .background(Circle().fill(segment.color))
                                        .offset(x: segmentWidth - height/2)
                                        .scaleEffect(animationProgress)
                                        .animation(
                                            theme.animations.springNormal.delay(Double(index) * 0.1 + 0.2),
                                            value: animationProgress
                                        )
                                }
                            }
                        }
                    }
                }
            }
            .frame(height: height)
            
            if labelPosition == .bottom {
                labelsView
            }
        }
    }
    
    // MARK: - Vertical Progress Bar
    
    private var verticalProgressBar: some View {
        HStack(alignment: .bottom, spacing: theme.spacing.sm) {
            if labelPosition == .inline {
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    ForEach(segments.reversed()) { segment in
                        HStack(spacing: theme.spacing.xs) {
                            Circle()
                                .fill(segment.color)
                                .frame(width: 8, height: 8)
                            
                            Text(segment.title)
                                .font(theme.typography.labelSmall)
                                .foregroundColor(theme.textSecondary)
                        }
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                ForEach(segments.reversed().indices, id: \.self) { index in
                    let segment = segments.reversed()[index]
                    let segmentHeight: CGFloat = 40
                    
                    ZStack(alignment: .bottom) {
                        RoundedRectangle(cornerRadius: height / 2)
                            .fill(segment.color.opacity(0.2))
                            .frame(width: height * 2, height: segmentHeight)
                        
                        RoundedRectangle(cornerRadius: height / 2)
                            .fill(segment.color)
                            .frame(
                                width: height * 2,
                                height: segmentHeight * CGFloat(segment.progress) * animationProgress
                            )
                            .animation(
                                theme.animations.springNormal.delay(Double(index) * 0.1),
                                value: animationProgress
                            )
                    }
                }
            }
            
            if labelPosition == .bottom {
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    ForEach(segments.reversed()) { segment in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(segment.title)
                                .font(theme.typography.labelSmall)
                                .foregroundColor(theme.textPrimary)
                            
                            if showPercentages {
                                Text("\(segment.progress * 100, specifier: "%.0f")%")
                                    .font(theme.typography.labelSmall)
                                    .foregroundColor(segment.color)
                            }
                        }
                        .frame(height: 40)
                    }
                }
            }
        }
    }
    
    // MARK: - Circular Progress Bar
    
    private var circularProgressBar: some View {
        ZStack {
            ForEach(segments.indices, id: \.self) { index in
                let segment = segments[index]
                let radius = 80 - (CGFloat(index) * 12)
                
                Circle()
                    .stroke(segment.color.opacity(0.2), lineWidth: 8)
                    .frame(width: radius, height: radius)
                
                Circle()
                    .trim(from: 0, to: CGFloat(segment.progress) * animationProgress)
                    .stroke(
                        segment.color,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: radius, height: radius)
                    .rotationEffect(.degrees(-90))
                    .animation(
                        theme.animations.springNormal.delay(Double(index) * 0.1),
                        value: animationProgress
                    )
            }
            
            if labelPosition != .none {
                VStack(spacing: theme.spacing.xs) {
                    Text("Overall")
                        .font(theme.typography.labelMedium)
                        .foregroundColor(theme.textSecondary)
                    
                    Text("\(overallProgress * 100, specifier: "%.0f")%")
                        .font(theme.typography.headlineMedium)
                        .foregroundColor(theme.primaryColor)
                }
            }
        }
    }
    
    // MARK: - Stepped Progress Bar
    
    private var steppedProgressBar: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            if labelPosition == .top {
                HStack {
                    Text("Progress")
                        .font(theme.typography.headlineSmall)
                        .foregroundColor(theme.textPrimary)
                    
                    Spacer()
                    
                    Text("\(completedSteps)/\(segments.count)")
                        .font(theme.typography.labelMedium)
                        .foregroundColor(theme.textSecondary)
                }
            }
            
            VStack(spacing: theme.spacing.sm) {
                ForEach(segments.indices, id: \.self) { index in
                    let segment = segments[index]
                    let isLast = index == segments.count - 1
                    
                    HStack(alignment: .top, spacing: theme.spacing.sm) {
                        // Step indicator
                        VStack(spacing: 0) {
                            ZStack {
                                Circle()
                                    .fill(stepBackgroundColor(segment))
                                    .frame(width: 24, height: 24)
                                
                                if segment.isCompleted {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.white)
                                        .font(.caption)
                                        .scaleEffect(animationProgress)
                                        .animation(
                                            theme.animations.springNormal.delay(Double(index) * 0.1),
                                            value: animationProgress
                                        )
                                } else {
                                    Text("\(index + 1)")
                                        .font(theme.typography.labelSmall)
                                        .foregroundColor(stepTextColor(segment))
                                }
                            }
                            
                            if !isLast {
                                Rectangle()
                                    .fill(connectorColor(segment))
                                    .frame(width: 2, height: 32)
                                    .scaleEffect(y: animationProgress)
                                    .animation(
                                        theme.animations.springNormal.delay(Double(index) * 0.1 + 0.1),
                                        value: animationProgress
                                    )
                            }
                        }
                        
                        // Step content
                        VStack(alignment: .leading, spacing: theme.spacing.xs) {
                            Text(segment.title)
                                .font(theme.typography.bodyMedium)
                                .foregroundColor(segment.isCompleted ? theme.textPrimary : theme.textSecondary)
                            
                            if segment.progress > 0 && segment.progress < 1 {
                                ProgressView(value: segment.progress)
                                    .tint(segment.color)
                                    .frame(height: 4)
                                    .scaleEffect(x: animationProgress, anchor: .leading)
                                    .animation(
                                        theme.animations.springNormal.delay(Double(index) * 0.1 + 0.2),
                                        value: animationProgress
                                    )
                            }
                            
                            if showPercentages {
                                Text("\(segment.progress * 100, specifier: "%.0f")% complete")
                                    .font(theme.typography.labelSmall)
                                    .foregroundColor(theme.textTertiary)
                            }
                        }
                        .padding(.top, 2)
                        
                        Spacer()
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Views
    
    private var labelsView: some View {
        HStack(spacing: 2) {
            ForEach(segments.indices, id: \.self) { index in
                let segment = segments[index]
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: theme.spacing.xs) {
                        Circle()
                            .fill(segment.color)
                            .frame(width: 8, height: 8)
                        
                        Text(segment.title)
                            .font(theme.typography.labelSmall)
                            .foregroundColor(theme.textPrimary)
                        
                        if segment.isCompleted {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(theme.successColor)
                                .font(.caption2)
                        }
                    }
                    
                    if showPercentages {
                        Text("\(segment.progress * 100, specifier: "%.0f")%")
                            .font(theme.typography.labelSmall)
                            .foregroundColor(segment.color)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                if index < segments.count - 1 {
                    Spacer()
                }
            }
        }
    }
    
    // MARK: - Helper Properties and Methods
    
    private var overallProgress: Double {
        guard !segments.isEmpty else { return 0 }
        return segments.map(\.progress).reduce(0, +) / Double(segments.count)
    }
    
    private var completedSteps: Int {
        segments.filter(\.isCompleted).count
    }
    
    private func stepBackgroundColor(_ segment: ProgressSegment) -> Color {
        if segment.isCompleted {
            return segment.color
        } else if segment.progress > 0 {
            return segment.color.opacity(0.3)
        } else {
            return theme.surfaceColor
        }
    }
    
    private func stepTextColor(_ segment: ProgressSegment) -> Color {
        if segment.isCompleted {
            return .white
        } else if segment.progress > 0 {
            return segment.color
        } else {
            return theme.textSecondary
        }
    }
    
    private func connectorColor(_ segment: ProgressSegment) -> Color {
        segment.isCompleted ? segment.color : theme.surfaceColor
    }
}

// MARK: - Multi-Step Progress Indicator
public struct MultiStepProgressIndicator: View {
    private let currentStep: Int
    private let totalSteps: Int
    private let stepTitles: [String]
    private let completedColor: Color
    private let activeColor: Color
    private let inactiveColor: Color
    
    @Environment(\.theme) private var theme
    @State private var animationProgress: CGFloat = 0
    
    public init(
        currentStep: Int,
        totalSteps: Int,
        stepTitles: [String] = [],
        completedColor: Color? = nil,
        activeColor: Color? = nil,
        inactiveColor: Color? = nil
    ) {
        self.currentStep = currentStep
        self.totalSteps = totalSteps
        self.stepTitles = stepTitles
        self.completedColor = completedColor ?? Color.green
        self.activeColor = activeColor ?? Color.blue
        self.inactiveColor = inactiveColor ?? Color.gray
    }
    
    public var body: some View {
        VStack(spacing: theme.spacing.md) {
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(inactiveColor.opacity(0.2))
                        .frame(height: 8)
                    
                    // Progress
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [completedColor, activeColor],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: geometry.size.width * progressPercentage * animationProgress,
                            height: 8
                        )
                        .animation(theme.animations.springNormal, value: animationProgress)
                }
            }
            .frame(height: 8)
            
            // Step indicators
            HStack {
                ForEach(0..<totalSteps, id: \.self) { step in
                    VStack(spacing: theme.spacing.xs) {
                        Circle()
                            .fill(colorForStep(step))
                            .frame(width: 24, height: 24)
                            .overlay(
                                Group {
                                    if step < currentStep {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.white)
                                            .font(.caption)
                                    } else {
                                        Text("\(step + 1)")
                                            .font(theme.typography.labelSmall)
                                            .foregroundColor(step == currentStep ? .white : textColorForStep(step))
                                    }
                                }
                            )
                            .scaleEffect(step == currentStep ? 1.2 : 1.0)
                            .animation(theme.animations.springFast, value: currentStep)
                        
                        if step < stepTitles.count {
                            Text(stepTitles[step])
                                .font(theme.typography.labelSmall)
                                .foregroundColor(step <= currentStep ? theme.textPrimary : theme.textTertiary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    
                    if step < totalSteps - 1 {
                        Spacer()
                    }
                }
            }
        }
        .onAppear {
            withAnimation(theme.animations.springNormal.delay(0.2)) {
                animationProgress = 1.0
            }
        }
    }
    
    private var progressPercentage: CGFloat {
        CGFloat(currentStep) / CGFloat(max(totalSteps - 1, 1))
    }
    
    private func colorForStep(_ step: Int) -> Color {
        if step < currentStep {
            return completedColor
        } else if step == currentStep {
            return activeColor
        } else {
            return inactiveColor.opacity(0.3)
        }
    }
    
    private func textColorForStep(_ step: Int) -> Color {
        step <= currentStep ? .white : theme.textTertiary
    }
}

// MARK: - Preview
#Preview {
    ScrollView {
        VStack(spacing: 32) {
            SegmentedProgressBar(
                segments: [
                    ProgressSegment(title: "Cardio", progress: 0.8, color: .red, isCompleted: false),
                    ProgressSegment(title: "Strength", progress: 1.0, color: .blue, isCompleted: true),
                    ProgressSegment(title: "Flexibility", progress: 0.3, color: .green, isCompleted: false)
                ],
                style: .horizontal,
                labelPosition: .bottom,
                showPercentages: true
            )
            
            SegmentedProgressBar(
                segments: [
                    ProgressSegment(title: "Week 1", progress: 1.0, color: .purple, isCompleted: true),
                    ProgressSegment(title: "Week 2", progress: 0.7, color: .orange, isCompleted: false),
                    ProgressSegment(title: "Week 3", progress: 0.2, color: .pink, isCompleted: false)
                ],
                style: .stepped,
                showPercentages: true
            )
            
            SegmentedProgressBar(
                segments: [
                    ProgressSegment(title: "Calories", progress: 0.9, color: .red, isCompleted: false),
                    ProgressSegment(title: "Exercise", progress: 0.7, color: .green, isCompleted: false),
                    ProgressSegment(title: "Sleep", progress: 0.5, color: .blue, isCompleted: false)
                ],
                style: .circular,
                labelPosition: .inline
            )
            
            MultiStepProgressIndicator(
                currentStep: 2,
                totalSteps: 5,
                stepTitles: ["Setup", "Profile", "Goals", "Plans", "Done"]
            )
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
    .theme(FitnessTheme())
}