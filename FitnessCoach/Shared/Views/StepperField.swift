import SwiftUI

// MARK: - Custom Stepper Field
public struct StepperField: View {
    public enum StepperStyle {
        case compact
        case expanded
        case circular
        case inline
    }
    
    private let title: String
    private let value: Binding<Double>
    private let range: ClosedRange<Double>
    private let step: Double
    private let style: StepperStyle
    private let unit: String?
    private let formatter: NumberFormatter?
    private let hapticFeedback: Bool
    
    @Environment(\.theme) private var theme
    @State private var isPressed = false
    @State private var pressedButton: PressedButton? = nil
    
    private enum PressedButton {
        case increment, decrement
    }
    
    public init(
        title: String,
        value: Binding<Double>,
        in range: ClosedRange<Double> = 0...100,
        step: Double = 1,
        style: StepperStyle = .compact,
        unit: String? = nil,
        formatter: NumberFormatter? = nil,
        hapticFeedback: Bool = true
    ) {
        self.title = title
        self.value = value
        self.range = range
        self.step = step
        self.style = style
        self.unit = unit
        self.formatter = formatter
        self.hapticFeedback = hapticFeedback
    }
    
    public var body: some View {
        Group {
            switch style {
            case .compact:
                compactStepper
            case .expanded:
                expandedStepper
            case .circular:
                circularStepper
            case .inline:
                inlineStepper
            }
        }
    }
    
    // MARK: - Compact Stepper
    
    private var compactStepper: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            Text(title)
                .font(theme.typography.labelMedium)
                .foregroundColor(theme.textSecondary)
            
            HStack(spacing: theme.spacing.sm) {
                stepperButton(
                    icon: "minus",
                    isEnabled: value.wrappedValue > range.lowerBound,
                    action: { decrementValue() },
                    buttonType: .decrement
                )
                
                Spacer()
                
                valueDisplay
                
                Spacer()
                
                stepperButton(
                    icon: "plus",
                    isEnabled: value.wrappedValue < range.upperBound,
                    action: { incrementValue() },
                    buttonType: .increment
                )
            }
            .padding(.horizontal, theme.spacing.sm)
            .padding(.vertical, theme.spacing.xs)
            .background(theme.surfaceColor)
            .cornerRadius(theme.cornerRadius.md)
        }
    }
    
    // MARK: - Expanded Stepper
    
    private var expandedStepper: some View {
        VStack(spacing: theme.spacing.md) {
            HStack {
                Text(title)
                    .font(theme.typography.headlineSmall)
                    .foregroundColor(theme.textPrimary)
                
                Spacer()
                
                valueDisplay
            }
            
            HStack(spacing: theme.spacing.lg) {
                stepperButton(
                    icon: "minus.circle.fill",
                    isEnabled: value.wrappedValue > range.lowerBound,
                    action: { decrementValue() },
                    buttonType: .decrement,
                    size: .large
                )
                
                // Progress indicator
                ProgressView(value: (value.wrappedValue - range.lowerBound) / (range.upperBound - range.lowerBound))
                    .tint(theme.primaryColor)
                    .frame(height: 8)
                    .scaleEffect(y: 1.5)
                
                stepperButton(
                    icon: "plus.circle.fill",
                    isEnabled: value.wrappedValue < range.upperBound,
                    action: { incrementValue() },
                    buttonType: .increment,
                    size: .large
                )
            }
            
            // Range labels
            HStack {
                Text("\(range.lowerBound, specifier: "%.0f")")
                    .font(theme.typography.labelSmall)
                    .foregroundColor(theme.textTertiary)
                
                Spacer()
                
                Text("\(range.upperBound, specifier: "%.0f")")
                    .font(theme.typography.labelSmall)
                    .foregroundColor(theme.textTertiary)
            }
        }
        .padding(theme.spacing.md)
        .background(theme.cardColor)
        .cornerRadius(theme.cornerRadius.card)
    }
    
    // MARK: - Circular Stepper
    
    private var circularStepper: some View {
        VStack(spacing: theme.spacing.md) {
            Text(title)
                .font(theme.typography.headlineSmall)
                .foregroundColor(theme.textPrimary)
            
            ZStack {
                // Background circle
                Circle()
                    .stroke(theme.surfaceColor, lineWidth: 8)
                    .frame(width: 120, height: 120)
                
                // Progress circle
                Circle()
                    .trim(from: 0, to: (value.wrappedValue - range.lowerBound) / (range.upperBound - range.lowerBound))
                    .stroke(
                        LinearGradient(
                            colors: [theme.primaryColor, theme.primaryColor.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(theme.animations.springNormal, value: value.wrappedValue)
                
                // Center value
                valueDisplay
                
                // Stepper buttons
                VStack {
                    stepperButton(
                        icon: "plus",
                        isEnabled: value.wrappedValue < range.upperBound,
                        action: { incrementValue() },
                        buttonType: .increment,
                        size: .small
                    )
                    .offset(y: -40)
                    
                    Spacer()
                    
                    stepperButton(
                        icon: "minus",
                        isEnabled: value.wrappedValue > range.lowerBound,
                        action: { decrementValue() },
                        buttonType: .decrement,
                        size: .small
                    )
                    .offset(y: 40)
                }
                .frame(width: 120, height: 120)
            }
        }
        .frame(width: 160, height: 200)
    }
    
    // MARK: - Inline Stepper
    
    private var inlineStepper: some View {
        HStack(spacing: theme.spacing.sm) {
            Text(title)
                .font(theme.typography.bodyMedium)
                .foregroundColor(theme.textPrimary)
            
            Spacer()
            
            HStack(spacing: theme.spacing.xs) {
                stepperButton(
                    icon: "minus.circle",
                    isEnabled: value.wrappedValue > range.lowerBound,
                    action: { decrementValue() },
                    buttonType: .decrement,
                    size: .small
                )
                
                valueDisplay
                
                stepperButton(
                    icon: "plus.circle",
                    isEnabled: value.wrappedValue < range.upperBound,
                    action: { incrementValue() },
                    buttonType: .increment,
                    size: .small
                )
            }
        }
        .padding(.vertical, theme.spacing.sm)
    }
    
    // MARK: - Helper Views
    
    private var valueDisplay: some View {
        HStack(spacing: 2) {
            Text(formattedValue)
                .font(theme.typography.titleMedium)
                .foregroundColor(theme.textPrimary)
                .fontWeight(.semibold)
                .contentTransition(.numericText())
                .animation(theme.animations.springFast, value: value.wrappedValue)
            
            if let unit = unit {
                Text(unit)
                    .font(theme.typography.labelMedium)
                    .foregroundColor(theme.textSecondary)
            }
        }
    }
    
    private func stepperButton(
        icon: String,
        isEnabled: Bool,
        action: @escaping () -> Void,
        buttonType: PressedButton,
        size: ButtonSize = .normal
    ) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(size.iconFont)
                .foregroundColor(isEnabled ? buttonColor(for: buttonType) : theme.textDisabled)
                .frame(width: size.dimension, height: size.dimension)
                .background(
                    Circle()
                        .fill(isEnabled ? buttonBackgroundColor(for: buttonType) : theme.interactiveDisabled)
                )
                .scaleEffect(pressedButton == buttonType ? 0.9 : 1.0)
                .animation(theme.animations.buttonPress, value: pressedButton)
        }
        .disabled(!isEnabled)
        .onLongPressGesture(minimumDuration: 0.1, maximumDistance: 50) {
            // Long press completed
        } onPressingChanged: { pressing in
            if pressing {
                pressedButton = buttonType
                if hapticFeedback {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                }
            } else {
                pressedButton = nil
            }
        }
    }
    
    private enum ButtonSize {
        case small, normal, large
        
        var dimension: CGFloat {
            switch self {
            case .small: return 28
            case .normal: return 36
            case .large: return 48
            }
        }
        
        var iconFont: Font {
            switch self {
            case .small: return .caption
            case .normal: return .body
            case .large: return .title2
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private var formattedValue: String {
        if let formatter = formatter {
            return formatter.string(from: NSNumber(value: value.wrappedValue)) ?? "\(value.wrappedValue)"
        }
        
        // Default formatting based on step size
        if step >= 1 {
            return "\(Int(value.wrappedValue))"
        } else if step >= 0.1 {
            return String(format: "%.1f", value.wrappedValue)
        } else {
            return String(format: "%.2f", value.wrappedValue)
        }
    }
    
    private func incrementValue() {
        let newValue = min(value.wrappedValue + step, range.upperBound)
        value.wrappedValue = newValue
        
        if hapticFeedback {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        }
    }
    
    private func decrementValue() {
        let newValue = max(value.wrappedValue - step, range.lowerBound)
        value.wrappedValue = newValue
        
        if hapticFeedback {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        }
    }
    
    private func buttonColor(for buttonType: PressedButton) -> Color {
        switch buttonType {
        case .increment:
            return theme.primaryColor
        case .decrement:
            return theme.errorColor
        }
    }
    
    private func buttonBackgroundColor(for buttonType: PressedButton) -> Color {
        switch buttonType {
        case .increment:
            return theme.primaryColor.opacity(0.1)
        case .decrement:
            return theme.errorColor.opacity(0.1)
        }
    }
}

// MARK: - Multi-Value Stepper
public struct MultiValueStepper: View {
    public struct StepperValue: Identifiable {
        public let id = UUID()
        public let title: String
        public let binding: Binding<Double>
        public let range: ClosedRange<Double>
        public let step: Double
        public let unit: String?
        public let color: Color
        
        public init(
            title: String,
            binding: Binding<Double>,
            range: ClosedRange<Double> = 0...100,
            step: Double = 1,
            unit: String? = nil,
            color: Color = .blue
        ) {
            self.title = title
            self.binding = binding
            self.range = range
            self.step = step
            self.unit = unit
            self.color = color
        }
    }
    
    private let values: [StepperValue]
    private let title: String?
    
    @Environment(\.theme) private var theme
    
    public init(title: String? = nil, values: [StepperValue]) {
        self.title = title
        self.values = values
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            if let title = title {
                Text(title)
                    .font(theme.typography.headlineMedium)
                    .foregroundColor(theme.textPrimary)
            }
            
            VStack(spacing: theme.spacing.sm) {
                ForEach(values) { value in
                    StepperField(
                        title: value.title,
                        value: value.binding,
                        in: value.range,
                        step: value.step,
                        style: .inline,
                        unit: value.unit
                    )
                }
            }
        }
        .padding(theme.spacing.md)
        .background(theme.cardColor)
        .cornerRadius(theme.cornerRadius.card)
    }
}

// MARK: - Fitness-Specific Steppers
public struct WeightStepper: View {
    @Binding private var weight: Double
    private let unit: WeightUnit
    
    public enum WeightUnit: String, CaseIterable {
        case kg = "kg"
        case lbs = "lbs"
        
        var step: Double {
            switch self {
            case .kg: return 0.5
            case .lbs: return 1.0
            }
        }
        
        var range: ClosedRange<Double> {
            switch self {
            case .kg: return 1...300
            case .lbs: return 1...700
            }
        }
    }
    
    public init(weight: Binding<Double>, unit: WeightUnit = .kg) {
        self._weight = weight
        self.unit = unit
    }
    
    public var body: some View {
        StepperField(
            title: "Weight",
            value: $weight,
            in: unit.range,
            step: unit.step,
            style: .expanded,
            unit: unit.rawValue
        )
    }
}

public struct RepsStepper: View {
    @Binding private var reps: Int
    private let title: String
    
    public init(title: String = "Reps", reps: Binding<Int>) {
        self.title = title
        self._reps = reps
    }
    
    private var repsDouble: Binding<Double> {
        Binding(
            get: { Double(reps) },
            set: { reps = Int($0) }
        )
    }
    
    public var body: some View {
        StepperField(
            title: title,
            value: repsDouble,
            in: 1...100,
            step: 1,
            style: .compact
        )
    }
}

public struct TimeStepper: View {
    @Binding private var seconds: Int
    private let title: String
    
    public init(title: String = "Duration", seconds: Binding<Int>) {
        self.title = title
        self._seconds = seconds
    }
    
    @Environment(\.theme) private var theme
    
    public var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            Text(title)
                .font(theme.typography.labelMedium)
                .foregroundColor(theme.textSecondary)
            
            HStack(spacing: theme.spacing.md) {
                // Minutes
                StepperField(
                    title: "Min",
                    value: Binding(
                        get: { Double(seconds / 60) },
                        set: { seconds = Int($0) * 60 + (seconds % 60) }
                    ),
                    in: 0...60,
                    step: 1,
                    style: .compact,
                    unit: "m"
                )
                
                // Seconds
                StepperField(
                    title: "Sec",
                    value: Binding(
                        get: { Double(seconds % 60) },
                        set: { seconds = (seconds / 60) * 60 + Int($0) }
                    ),
                    in: 0...59,
                    step: 1,
                    style: .compact,
                    unit: "s"
                )
            }
        }
    }
}

// MARK: - Preview
#Preview {
    ScrollView {
        VStack(spacing: 32) {
            Text("Stepper Field Components")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Group {
                StepperField(
                    title: "Compact Stepper",
                    value: .constant(5),
                    in: 0...10,
                    step: 0.5,
                    style: .compact,
                    unit: "kg"
                )
                
                StepperField(
                    title: "Expanded Stepper",
                    value: .constant(25),
                    in: 0...100,
                    step: 5,
                    style: .expanded,
                    unit: "%"
                )
                
                StepperField(
                    title: "Circular Stepper",
                    value: .constant(75),
                    in: 0...100,
                    step: 1,
                    style: .circular,
                    unit: "bpm"
                )
            }
            
            Group {
                MultiValueStepper(
                    title: "Workout Settings",
                    values: [
                        MultiValueStepper.StepperValue(
                            title: "Sets",
                            binding: .constant(3),
                            range: 1...10,
                            step: 1,
                            color: .blue
                        ),
                        MultiValueStepper.StepperValue(
                            title: "Reps",
                            binding: .constant(12),
                            range: 1...50,
                            step: 1,
                            color: .green
                        ),
                        MultiValueStepper.StepperValue(
                            title: "Rest",
                            binding: .constant(60),
                            range: 15...300,
                            step: 15,
                            unit: "sec",
                            color: .orange
                        )
                    ]
                )
                
                WeightStepper(weight: .constant(70.5), unit: .kg)
                
                TimeStepper(seconds: .constant(180))
            }
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
    .theme(FitnessTheme())
}