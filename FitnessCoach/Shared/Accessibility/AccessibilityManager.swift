import SwiftUI
import UIKit

// MARK: - Accessibility Manager
public class AccessibilityManager: ObservableObject {
    public static let shared = AccessibilityManager()
    
    @Published public var isVoiceOverEnabled = UIAccessibility.isVoiceOverRunning
    @Published public var isSwitchControlEnabled = UIAccessibility.isSwitchControlRunning
    @Published public var isReduceMotionEnabled = UIAccessibility.isReduceMotionEnabled
    @Published public var isReduceTransparencyEnabled = UIAccessibility.isReduceTransparencyEnabled
    @Published public var isDarkerSystemColorsEnabled = UIAccessibility.isDarkerSystemColorsEnabled
    @Published public var isBoldTextEnabled = UIAccessibility.isBoldTextEnabled
    @Published public var isButtonShapesEnabled = UIAccessibility.isButtonShapesEnabled
    @Published public var isOnOffSwitchLabelsEnabled = UIAccessibility.isOnOffSwitchLabelsEnabled
    @Published public var preferredContentSizeCategory = UIApplication.shared.preferredContentSizeCategory
    
    private init() {
        setupAccessibilityNotifications()
    }
    
    private func setupAccessibilityNotifications() {
        NotificationCenter.default.addObserver(
            forName: UIAccessibility.voiceOverStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.isVoiceOverEnabled = UIAccessibility.isVoiceOverRunning
        }
        
        NotificationCenter.default.addObserver(
            forName: UIAccessibility.switchControlStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.isSwitchControlEnabled = UIAccessibility.isSwitchControlRunning
        }
        
        NotificationCenter.default.addObserver(
            forName: UIAccessibility.reduceMotionStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.isReduceMotionEnabled = UIAccessibility.isReduceMotionEnabled
        }
        
        NotificationCenter.default.addObserver(
            forName: UIAccessibility.reduceTransparencyStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.isReduceTransparencyEnabled = UIAccessibility.isReduceTransparencyEnabled
        }
        
        NotificationCenter.default.addObserver(
            forName: UIAccessibility.darkerSystemColorsStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.isDarkerSystemColorsEnabled = UIAccessibility.isDarkerSystemColorsEnabled
        }
        
        NotificationCenter.default.addObserver(
            forName: UIAccessibility.boldTextStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.isBoldTextEnabled = UIAccessibility.isBoldTextEnabled
        }
        
        NotificationCenter.default.addObserver(
            forName: UIAccessibility.buttonShapesEnabledStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.isButtonShapesEnabled = UIAccessibility.isButtonShapesEnabled
        }
        
        NotificationCenter.default.addObserver(
            forName: UIAccessibility.onOffSwitchLabelsDidChangeNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.isOnOffSwitchLabelsEnabled = UIAccessibility.isOnOffSwitchLabelsEnabled
        }
        
        NotificationCenter.default.addObserver(
            forName: UIContentSizeCategory.didChangeNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.preferredContentSizeCategory = UIApplication.shared.preferredContentSizeCategory
        }
    }
    
    // MARK: - Helper Methods
    
    public func shouldReduceMotion() -> Bool {
        isReduceMotionEnabled
    }
    
    public func shouldReduceTransparency() -> Bool {
        isReduceTransparencyEnabled
    }
    
    public func shouldUseBoldText() -> Bool {
        isBoldTextEnabled
    }
    
    public func shouldShowButtonShapes() -> Bool {
        isButtonShapesEnabled
    }
    
    public func isLargeContentSizeCategory() -> Bool {
        preferredContentSizeCategory.isAccessibilityCategory
    }
    
    public func contrastRatio(foreground: UIColor, background: UIColor) -> CGFloat {
        let foregroundLuminance = foreground.luminance()
        let backgroundLuminance = background.luminance()
        
        let lighter = max(foregroundLuminance, backgroundLuminance)
        let darker = min(foregroundLuminance, backgroundLuminance)
        
        return (lighter + 0.05) / (darker + 0.05)
    }
    
    public func meetsWCAGAAStandard(foreground: UIColor, background: UIColor) -> Bool {
        return contrastRatio(foreground: foreground, background: background) >= 4.5
    }
    
    public func meetsWCAGAAAStandard(foreground: UIColor, background: UIColor) -> Bool {
        return contrastRatio(foreground: foreground, background: background) >= 7.0
    }
}

// MARK: - UIColor Extension for Accessibility
private extension UIColor {
    func luminance() -> CGFloat {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        func adjust(colorComponent: CGFloat) -> CGFloat {
            return (colorComponent <= 0.03928) ? (colorComponent / 12.92) : pow((colorComponent + 0.055) / 1.055, 2.4)
        }
        
        return 0.2126 * adjust(colorComponent: red) + 0.7152 * adjust(colorComponent: green) + 0.0722 * adjust(colorComponent: blue)
    }
}

// MARK: - Accessibility Modifiers
public extension View {
    func accessibleButton(
        label: String,
        hint: String? = nil,
        traits: AccessibilityTraits = []
    ) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits([.isButton] + traits)
    }
    
    func accessibleHeader(
        level: AccessibilityHeadingLevel = .h2
    ) -> some View {
        self
            .accessibilityAddTraits(.isHeader)
            .accessibilityHeading(level)
    }
    
    func accessibleValue(
        _ value: String,
        increasesBy: String? = nil,
        decreasesBy: String? = nil
    ) -> some View {
        var view = self.accessibilityValue(value)
        
        if let increasesBy = increasesBy {
            view = view.accessibilityAdjustableAction(.increment) {
                // Action handled by parent view
            }
        }
        
        if let decreasesBy = decreasesBy {
            view = view.accessibilityAdjustableAction(.decrement) {
                // Action handled by parent view
            }
        }
        
        return view
    }
    
    func accessibleChart(
        title: String,
        summary: String,
        details: String? = nil
    ) -> some View {
        self
            .accessibilityLabel(title)
            .accessibilityValue(summary)
            .accessibilityHint(details ?? "Chart data")
            .accessibilityAddTraits(.isImage)
    }
    
    func accessibleProgress(
        value: Double,
        total: Double,
        label: String,
        format: String = "%.0f"
    ) -> some View {
        let percentage = (value / total) * 100
        let progressDescription = String(format: format + " percent complete", percentage)
        
        return self
            .accessibilityLabel(label)
            .accessibilityValue(progressDescription)
            .accessibilityAddTraits(.updatesFrequently)
    }
    
    func accessibleStepper(
        value: Double,
        label: String,
        unit: String? = nil,
        step: Double = 1
    ) -> some View {
        let valueString = unit != nil ? "\(value) \(unit!)" : "\(value)"
        
        return self
            .accessibilityLabel(label)
            .accessibilityValue(valueString)
            .accessibilityAddTraits(.adjustable)
            .accessibilityAdjustableAction(.increment) {
                // Handle increment
            }
            .accessibilityAdjustableAction(.decrement) {
                // Handle decrement
            }
    }
    
    func accessibleList(
        label: String,
        itemCount: Int? = nil
    ) -> some View {
        var accessibilityLabel = label
        if let count = itemCount {
            accessibilityLabel += ". \(count) items"
        }
        
        return self
            .accessibilityLabel(accessibilityLabel)
            .accessibilityAddTraits(.isList)
    }
    
    func accessibleCard(
        title: String,
        content: String? = nil,
        actions: [String] = []
    ) -> some View {
        var fullLabel = title
        if let content = content {
            fullLabel += ". \(content)"
        }
        if !actions.isEmpty {
            fullLabel += ". Actions available: \(actions.joined(separator: ", "))"
        }
        
        return self
            .accessibilityLabel(fullLabel)
            .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Accessibility-Aware Theme
public struct AccessibleTheme: ThemeProtocol {
    private let baseTheme: any ThemeProtocol
    private let accessibilityManager = AccessibilityManager.shared
    
    public init(baseTheme: any ThemeProtocol) {
        self.baseTheme = baseTheme
    }
    
    // Enhanced colors for better contrast
    public var primaryColor: Color {
        if accessibilityManager.isDarkerSystemColorsEnabled {
            return baseTheme.primaryColor.opacity(0.9)
        }
        return baseTheme.primaryColor
    }
    
    public var primaryVariant: Color { baseTheme.primaryVariant }
    public var secondaryColor: Color { baseTheme.secondaryColor }
    public var secondaryVariant: Color { baseTheme.secondaryVariant }
    
    public var backgroundColor: Color { baseTheme.backgroundColor }
    public var surfaceColor: Color { baseTheme.surfaceColor }
    public var cardColor: Color { baseTheme.cardColor }
    public var overlayColor: Color {
        if accessibilityManager.shouldReduceTransparency() {
            return Color.black.opacity(0.8)
        }
        return baseTheme.overlayColor
    }
    
    public var errorColor: Color { baseTheme.errorColor }
    public var errorVariant: Color { baseTheme.errorVariant }
    public var successColor: Color { baseTheme.successColor }
    public var successVariant: Color { baseTheme.successVariant }
    public var warningColor: Color { baseTheme.warningColor }
    public var warningVariant: Color { baseTheme.warningVariant }
    public var infoColor: Color { baseTheme.infoColor }
    public var infoVariant: Color { baseTheme.infoVariant }
    
    public var textPrimary: Color { baseTheme.textPrimary }
    public var textSecondary: Color { baseTheme.textSecondary }
    public var textTertiary: Color { baseTheme.textTertiary }
    public var textOnPrimary: Color { baseTheme.textOnPrimary }
    public var textOnSecondary: Color { baseTheme.textOnSecondary }
    public var textDisabled: Color { baseTheme.textDisabled }
    
    public var interactivePrimary: Color { baseTheme.interactivePrimary }
    public var interactiveSecondary: Color { baseTheme.interactiveSecondary }
    public var interactiveDisabled: Color { baseTheme.interactiveDisabled }
    public var focusColor: Color { baseTheme.focusColor }
    
    public var gradients: ThemeGradients {
        if accessibilityManager.shouldReduceTransparency() {
            // Return solid colors instead of gradients
            return ThemeGradients(
                primary: LinearGradient(colors: [primaryColor], startPoint: .leading, endPoint: .trailing),
                secondary: LinearGradient(colors: [secondaryColor], startPoint: .leading, endPoint: .trailing)
            )
        }
        return baseTheme.gradients
    }
    
    public var typography: ThemeTypography {
        if accessibilityManager.shouldUseBoldText() {
            return ThemeTypography(
                displayLarge: baseTheme.typography.displayLarge.bold(),
                displayMedium: baseTheme.typography.displayMedium.bold(),
                displaySmall: baseTheme.typography.displaySmall.bold(),
                headlineLarge: baseTheme.typography.headlineLarge.bold(),
                headlineMedium: baseTheme.typography.headlineMedium.bold(),
                headlineSmall: baseTheme.typography.headlineSmall.bold(),
                titleLarge: baseTheme.typography.titleLarge.bold(),
                titleMedium: baseTheme.typography.titleMedium.bold(),
                titleSmall: baseTheme.typography.titleSmall.bold(),
                bodyLarge: baseTheme.typography.bodyLarge.bold(),
                bodyMedium: baseTheme.typography.bodyMedium.bold(),
                bodySmall: baseTheme.typography.bodySmall.bold(),
                labelLarge: baseTheme.typography.labelLarge.bold(),
                labelMedium: baseTheme.typography.labelMedium.bold(),
                labelSmall: baseTheme.typography.labelSmall.bold()
            )
        }
        return baseTheme.typography
    }
    
    public var spacing: ThemeSpacing { baseTheme.spacing }
    
    public var cornerRadius: ThemeCornerRadius {
        if accessibilityManager.shouldShowButtonShapes() {
            return ThemeCornerRadius()
        }
        return baseTheme.cornerRadius
    }
    
    public var shadows: ThemeShadows {
        if accessibilityManager.shouldReduceTransparency() {
            // Reduce shadow opacity
            return ThemeShadows()
        }
        return baseTheme.shadows
    }
    
    public var animations: ThemeAnimations {
        if accessibilityManager.shouldReduceMotion() {
            return ThemeAnimations()
        }
        return baseTheme.animations
    }
    
    public var layout: ThemeLayout { baseTheme.layout }
}

// MARK: - Accessibility Environment Key
private struct AccessibilityManagerKey: EnvironmentKey {
    static let defaultValue = AccessibilityManager.shared
}

public extension EnvironmentValues {
    var accessibilityManager: AccessibilityManager {
        get { self[AccessibilityManagerKey.self] }
        set { self[AccessibilityManagerKey.self] = newValue }
    }
}

// MARK: - SwiftUI Integration
public extension View {
    func accessibilityAware() -> some View {
        self.environment(\.accessibilityManager, AccessibilityManager.shared)
    }
    
    func adaptiveMotion<T: View>(
        @ViewBuilder reducedMotion: () -> T,
        @ViewBuilder fullMotion: () -> T
    ) -> some View {
        Group {
            if AccessibilityManager.shared.shouldReduceMotion() {
                reducedMotion()
            } else {
                fullMotion()
            }
        }
    }
    
    func adaptiveTransparency(opacity: Double) -> some View {
        self.opacity(AccessibilityManager.shared.shouldReduceTransparency() ? 1.0 : opacity)
    }
}

// MARK: - Accessibility Testing Helper
public struct AccessibilityTester {
    public static func validateContrast(
        foreground: Color,
        background: Color,
        level: WCAGLevel = .AA
    ) -> AccessibilityTestResult {
        let fgUIColor = UIColor(foreground)
        let bgUIColor = UIColor(background)
        let ratio = AccessibilityManager.shared.contrastRatio(foreground: fgUIColor, background: bgUIColor)
        
        let meetsStandard = switch level {
        case .AA:
            ratio >= 4.5
        case .AAA:
            ratio >= 7.0
        }
        
        return AccessibilityTestResult(
            passes: meetsStandard,
            contrastRatio: ratio,
            level: level,
            recommendation: meetsStandard ? nil : "Increase contrast between foreground and background colors"
        )
    }
    
    public enum WCAGLevel {
        case AA, AAA
    }
    
    public struct AccessibilityTestResult {
        public let passes: Bool
        public let contrastRatio: CGFloat
        public let level: WCAGLevel
        public let recommendation: String?
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        Text("Accessibility Demo")
            .font(.largeTitle)
            .accessibleHeader(level: .h1)
        
        Button("Accessible Button") {}
            .accessibleButton(
                label: "Save progress",
                hint: "Saves your current workout data"
            )
        
        HStack {
            Text("Progress:")
            ProgressView(value: 0.7)
                .accessibleProgress(
                    value: 70,
                    total: 100,
                    label: "Workout progress"
                )
        }
        
        VStack {
            Text("Weight")
            HStack {
                Button("-") {}
                Text("70 kg")
                Button("+") {}
            }
        }
        .accessibleStepper(
            value: 70,
            label: "Weight stepper",
            unit: "kilograms"
        )
    }
    .padding()
    .accessibilityAware()
}