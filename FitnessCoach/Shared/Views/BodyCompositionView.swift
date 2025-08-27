import SwiftUI

// MARK: - Body Composition Data Models
public struct BodyCompositionData {
    public let muscle: Double
    public let fat: Double
    public let water: Double
    public let bone: Double
    public let other: Double
    
    public init(muscle: Double, fat: Double, water: Double, bone: Double, other: Double = 0) {
        self.muscle = muscle
        self.fat = fat
        self.water = water
        self.bone = bone
        self.other = other
    }
    
    public var total: Double {
        muscle + fat + water + bone + other
    }
}

public struct BodyCompositionView: View {
    public enum DisplayStyle {
        case circular
        case horizontal
        case detailed
    }
    
    private let data: BodyCompositionData
    private let style: DisplayStyle
    private let showPercentages: Bool
    private let animated: Bool
    
    @Environment(\.theme) private var theme
    @State private var animationProgress: CGFloat = 0
    
    public init(
        data: BodyCompositionData,
        style: DisplayStyle = .circular,
        showPercentages: Bool = true,
        animated: Bool = true
    ) {
        self.data = data
        self.style = style
        self.showPercentages = showPercentages
        self.animated = animated
    }
    
    public var body: some View {
        Group {
            switch style {
            case .circular:
                circularView
            case .horizontal:
                horizontalView
            case .detailed:
                detailedView
            }
        }
        .onAppear {
            if animated {
                withAnimation(theme.animations.springNormal.delay(0.2)) {
                    animationProgress = 1.0
                }
            } else {
                animationProgress = 1.0
            }
        }
    }
    
    // MARK: - Circular View
    
    private var circularView: some View {
        VStack(spacing: theme.spacing.lg) {
            ZStack {
                Circle()
                    .stroke(theme.surfaceColor, lineWidth: 8)
                    .frame(width: 200, height: 200)
                
                ForEach(compositionSegments.indices, id: \.self) { index in
                    let segment = compositionSegments[index]
                    
                    Circle()
                        .trim(from: segment.startAngle, to: segment.startAngle + segment.percentage * animationProgress)
                        .stroke(
                            segment.color,
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 200, height: 200)
                        .rotationEffect(.degrees(-90))
                        .animation(
                            theme.animations.springNormal.delay(Double(index) * 0.1),
                            value: animationProgress
                        )
                }
                
                VStack(spacing: theme.spacing.xs) {
                    Text("\(Int(data.muscle), specifier: "%d")%")
                        .font(theme.typography.headlineLarge)
                        .foregroundColor(theme.primaryColor)
                    
                    Text("Muscle")
                        .font(theme.typography.labelMedium)
                        .foregroundColor(theme.textSecondary)
                }
            }
            
            legendView
        }
    }
    
    // MARK: - Horizontal View
    
    private var horizontalView: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            Text("Body Composition")
                .font(theme.typography.headlineMedium)
                .foregroundColor(theme.textPrimary)
            
            VStack(spacing: theme.spacing.sm) {
                ForEach(horizontalSegments.indices, id: \.self) { index in
                    let segment = horizontalSegments[index]
                    
                    HStack(spacing: theme.spacing.sm) {
                        HStack(spacing: theme.spacing.xs) {
                            Circle()
                                .fill(segment.color)
                                .frame(width: 12, height: 12)
                            
                            Text(segment.label)
                                .font(theme.typography.bodyMedium)
                                .foregroundColor(theme.textPrimary)
                        }
                        .frame(width: 80, alignment: .leading)
                        
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: theme.cornerRadius.sm)
                                    .fill(theme.surfaceColor)
                                    .frame(height: 8)
                                
                                RoundedRectangle(cornerRadius: theme.cornerRadius.sm)
                                    .fill(segment.color)
                                    .frame(
                                        width: geometry.size.width * segment.percentage * animationProgress,
                                        height: 8
                                    )
                                    .animation(
                                        theme.animations.springNormal.delay(Double(index) * 0.1),
                                        value: animationProgress
                                    )
                            }
                        }
                        .frame(height: 8)
                        
                        Text("\(segment.percentage * 100, specifier: "%.1f")%")
                            .font(theme.typography.labelMedium)
                            .foregroundColor(theme.textSecondary)
                            .frame(width: 40, alignment: .trailing)
                    }
                }
            }
        }
        .padding(theme.spacing.md)
        .background(theme.cardColor)
        .cornerRadius(theme.cornerRadius.card)
    }
    
    // MARK: - Detailed View
    
    private var detailedView: some View {
        VStack(spacing: theme.spacing.lg) {
            HStack {
                Text("Body Composition Analysis")
                    .font(theme.typography.headlineMedium)
                    .foregroundColor(theme.textPrimary)
                
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "arrow.trianglehead.2.clockwise")
                        .foregroundColor(theme.primaryColor)
                }
            }
            
            HStack(spacing: theme.spacing.lg) {
                circularView
                
                VStack(alignment: .leading, spacing: theme.spacing.md) {
                    MetricRow(
                        title: "Muscle Mass",
                        value: "\(data.muscle, specifier: "%.1f")%",
                        color: muscleColor,
                        ideal: "45-55%",
                        isGood: data.muscle >= 45
                    )
                    
                    MetricRow(
                        title: "Body Fat",
                        value: "\(data.fat, specifier: "%.1f")%",
                        color: fatColor,
                        ideal: "10-20%",
                        isGood: data.fat <= 20
                    )
                    
                    MetricRow(
                        title: "Water",
                        value: "\(data.water, specifier: "%.1f")%",
                        color: waterColor,
                        ideal: "50-65%",
                        isGood: data.water >= 50 && data.water <= 65
                    )
                    
                    MetricRow(
                        title: "Bone",
                        value: "\(data.bone, specifier: "%.1f")%",
                        color: boneColor,
                        ideal: "12-20%",
                        isGood: data.bone >= 12
                    )
                }
            }
            
            recommendationsView
        }
        .padding(theme.spacing.lg)
        .background(theme.cardColor)
        .cornerRadius(theme.cornerRadius.card)
    }
    
    // MARK: - Helper Views
    
    private var legendView: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: theme.spacing.sm) {
            ForEach(legendItems.indices, id: \.self) { index in
                let item = legendItems[index]
                
                HStack(spacing: theme.spacing.xs) {
                    Circle()
                        .fill(item.color)
                        .frame(width: 12, height: 12)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.label)
                            .font(theme.typography.labelMedium)
                            .foregroundColor(theme.textPrimary)
                        
                        if showPercentages {
                            Text("\(item.percentage * 100, specifier: "%.1f")%")
                                .font(theme.typography.labelSmall)
                                .foregroundColor(theme.textSecondary)
                        }
                    }
                    
                    Spacer()
                }
            }
        }
    }
    
    private var recommendationsView: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            Text("Recommendations")
                .font(theme.typography.headlineSmall)
                .foregroundColor(theme.textPrimary)
            
            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                if data.muscle < 45 {
                    RecommendationItem(
                        icon: "figure.strengthtraining.traditional",
                        text: "Increase muscle mass with strength training",
                        color: theme.warningColor
                    )
                }
                
                if data.fat > 20 {
                    RecommendationItem(
                        icon: "flame",
                        text: "Focus on cardio and caloric deficit",
                        color: theme.errorColor
                    )
                }
                
                if data.water < 50 {
                    RecommendationItem(
                        icon: "drop",
                        text: "Increase daily water intake",
                        color: theme.infoColor
                    )
                }
                
                RecommendationItem(
                    icon: "checkmark.circle",
                    text: "Maintain balanced nutrition",
                    color: theme.successColor
                )
            }
        }
    }
    
    private struct MetricRow: View {
        let title: String
        let value: String
        let color: Color
        let ideal: String
        let isGood: Bool
        
        @Environment(\.theme) private var theme
        
        var body: some View {
            HStack {
                VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                    Text(title)
                        .font(theme.typography.bodyMedium)
                        .foregroundColor(theme.textPrimary)
                    
                    Text("Ideal: \(ideal)")
                        .font(theme.typography.labelSmall)
                        .foregroundColor(theme.textTertiary)
                }
                
                Spacer()
                
                HStack(spacing: theme.spacing.xs) {
                    Text(value)
                        .font(theme.typography.titleMedium)
                        .foregroundColor(color)
                    
                    Image(systemName: isGood ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                        .foregroundColor(isGood ? theme.successColor : theme.warningColor)
                        .font(.caption)
                }
            }
        }
    }
    
    private struct RecommendationItem: View {
        let icon: String
        let text: String
        let color: Color
        
        @Environment(\.theme) private var theme
        
        var body: some View {
            HStack(spacing: theme.spacing.sm) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .frame(width: 20)
                
                Text(text)
                    .font(theme.typography.bodySmall)
                    .foregroundColor(theme.textSecondary)
                
                Spacer()
            }
        }
    }
    
    // MARK: - Helper Properties
    
    private var muscleColor: Color { theme.primaryColor }
    private var fatColor: Color { theme.warningColor }
    private var waterColor: Color { theme.infoColor }
    private var boneColor: Color { theme.textTertiary }
    
    private var compositionSegments: [(startAngle: CGFloat, percentage: CGFloat, color: Color)] {
        var segments: [(startAngle: CGFloat, percentage: CGFloat, color: Color)] = []
        var currentAngle: CGFloat = 0
        
        let items = [
            (data.muscle / 100, muscleColor),
            (data.fat / 100, fatColor),
            (data.water / 100, waterColor),
            (data.bone / 100, boneColor)
        ]
        
        for (percentage, color) in items {
            segments.append((startAngle: currentAngle, percentage: percentage, color: color))
            currentAngle += percentage
        }
        
        return segments
    }
    
    private var horizontalSegments: [(label: String, percentage: CGFloat, color: Color)] {
        [
            ("Muscle", data.muscle / 100, muscleColor),
            ("Fat", data.fat / 100, fatColor),
            ("Water", data.water / 100, waterColor),
            ("Bone", data.bone / 100, boneColor)
        ]
    }
    
    private var legendItems: [(label: String, percentage: CGFloat, color: Color)] {
        [
            ("Muscle", data.muscle / 100, muscleColor),
            ("Body Fat", data.fat / 100, fatColor),
            ("Water", data.water / 100, waterColor),
            ("Bone", data.bone / 100, boneColor)
        ]
    }
}

// MARK: - Preview
#Preview {
    ScrollView {
        VStack(spacing: 32) {
            BodyCompositionView(
                data: BodyCompositionData(
                    muscle: 48.2,
                    fat: 15.8,
                    water: 58.5,
                    bone: 16.1
                ),
                style: .detailed
            )
            
            BodyCompositionView(
                data: BodyCompositionData(
                    muscle: 45.0,
                    fat: 18.5,
                    water: 55.0,
                    bone: 15.0
                ),
                style: .horizontal
            )
            
            BodyCompositionView(
                data: BodyCompositionData(
                    muscle: 42.0,
                    fat: 22.0,
                    water: 52.0,
                    bone: 14.0
                ),
                style: .circular
            )
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
    .theme(FitnessTheme())
}