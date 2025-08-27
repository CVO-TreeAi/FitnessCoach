import SwiftUI
import Foundation

struct WatchTheme {
    // MARK: - Color Palette
    
    struct Colors {
        // Primary Colors
        static let primary = Color.orange
        static let primaryDark = Color(red: 0.8, green: 0.4, blue: 0.0)
        static let primaryLight = Color(red: 1.0, green: 0.7, blue: 0.3)
        
        // Secondary Colors
        static let secondary = Color.blue
        static let secondaryDark = Color(red: 0.0, green: 0.3, blue: 0.7)
        static let secondaryLight = Color(red: 0.3, green: 0.6, blue: 1.0)
        
        // Accent Colors
        static let accent = Color.green
        static let success = Color.green
        static let warning = Color.yellow
        static let error = Color.red
        static let info = Color.blue
        
        // Background Colors
        static let background = Color.black
        static let surface = Color(red: 0.1, green: 0.1, blue: 0.1)
        static let cardBackground = Color(red: 0.15, green: 0.15, blue: 0.15)
        static let elevatedSurface = Color(red: 0.2, green: 0.2, blue: 0.2)
        
        // Text Colors
        static let textPrimary = Color.white
        static let textSecondary = Color(red: 0.8, green: 0.8, blue: 0.8)
        static let textTertiary = Color(red: 0.6, green: 0.6, blue: 0.6)
        static let textOnPrimary = Color.white
        
        // Border Colors
        static let border = Color(red: 0.3, green: 0.3, blue: 0.3)
        static let borderLight = Color(red: 0.4, green: 0.4, blue: 0.4)
        
        // Health & Fitness Specific Colors
        static let heartRate = Color.red
        static let calories = Color.orange
        static let steps = Color.green
        static let activeCalories = Color.pink
        static let water = Color.cyan
        static let protein = Color.purple
        static let carbs = Color.yellow
        static let fats = Color.brown
        
        // Activity Ring Colors (matching Apple's design)
        static let moveRing = Color.pink
        static let exerciseRing = Color.green
        static let standRing = Color.cyan
        
        // Workout Intensity Colors
        static let lowIntensity = Color.green
        static let moderateIntensity = Color.yellow
        static let highIntensity = Color.orange
        static let maximumIntensity = Color.red
        
        // Progress Colors
        static let progressTrack = Color(red: 0.25, green: 0.25, blue: 0.25)
        static let progressFill = primary
        
        // Complication Colors
        static let complicationTint = primary
        static let complicationBackground = surface
    }
    
    // MARK: - Typography
    
    struct Typography {
        // Display Text (Large numbers, titles)
        static let displayLarge = Font.system(size: 34, weight: .bold, design: .rounded)
        static let displayMedium = Font.system(size: 28, weight: .bold, design: .rounded)
        static let displaySmall = Font.system(size: 24, weight: .bold, design: .rounded)
        
        // Headlines
        static let headlineLarge = Font.system(size: 22, weight: .semibold)
        static let headlineMedium = Font.system(size: 18, weight: .semibold)
        static let headlineSmall = Font.system(size: 16, weight: .semibold)
        
        // Body Text
        static let bodyLarge = Font.system(size: 16, weight: .regular)
        static let bodyMedium = Font.system(size: 14, weight: .regular)
        static let bodySmall = Font.system(size: 12, weight: .regular)
        
        // Labels
        static let labelLarge = Font.system(size: 14, weight: .medium)
        static let labelMedium = Font.system(size: 12, weight: .medium)
        static let labelSmall = Font.system(size: 10, weight: .medium)
        
        // Captions
        static let caption = Font.system(size: 10, weight: .regular)
        static let captionEmphasis = Font.system(size: 10, weight: .medium)
        
        // Special Typography
        static let timer = Font.system(size: 40, weight: .bold, design: .rounded).monospacedDigit()
        static let metric = Font.system(size: 24, weight: .bold, design: .rounded).monospacedDigit()
        static let metricUnit = Font.system(size: 14, weight: .medium)
        
        // Watch-specific sizes
        static let complicationLarge = Font.system(size: 16, weight: .bold, design: .rounded)
        static let complicationMedium = Font.system(size: 14, weight: .bold, design: .rounded)
        static let complicationSmall = Font.system(size: 12, weight: .bold, design: .rounded)
    }
    
    // MARK: - Spacing
    
    struct Spacing {
        static let xxxs: CGFloat = 2
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
        
        // Watch-specific spacing
        static let watchPadding: CGFloat = 8
        static let watchMargin: CGFloat = 16
        static let complicationPadding: CGFloat = 4
        static let buttonSpacing: CGFloat = 12
    }
    
    // MARK: - Corner Radius
    
    struct CornerRadius {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        
        // Watch-specific radius
        static let watchButton: CGFloat = 8
        static let watchCard: CGFloat = 12
        static let complication: CGFloat = 6
    }
    
    // MARK: - Shadow
    
    struct Shadow {
        static let light = ShadowStyle(
            color: Colors.background.opacity(0.1),
            radius: 2,
            x: 0,
            y: 1
        )
        
        static let medium = ShadowStyle(
            color: Colors.background.opacity(0.2),
            radius: 4,
            x: 0,
            y: 2
        )
        
        static let heavy = ShadowStyle(
            color: Colors.background.opacity(0.3),
            radius: 8,
            x: 0,
            y: 4
        )
    }
    
    // MARK: - Animation
    
    struct Animation {
        static let fast = SwiftUI.Animation.easeInOut(duration: 0.2)
        static let medium = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.5)
        
        // Spring animations
        static let spring = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.8)
        static let bouncy = SwiftUI.Animation.spring(response: 0.6, dampingFraction: 0.6)
        
        // Watch-specific animations
        static let buttonPress = SwiftUI.Animation.easeInOut(duration: 0.1)
        static let pageTransition = SwiftUI.Animation.easeInOut(duration: 0.4)
        static let complicationUpdate = SwiftUI.Animation.easeInOut(duration: 0.3)
    }
    
    // MARK: - Component Styles
    
    struct Components {
        // Button Styles
        static func primaryButtonStyle() -> some ButtonStyle {
            WatchPrimaryButtonStyle()
        }
        
        static func secondaryButtonStyle() -> some ButtonStyle {
            WatchSecondaryButtonStyle()
        }
        
        static func destructiveButtonStyle() -> some ButtonStyle {
            WatchDestructiveButtonStyle()
        }
        
        // Card Styles
        static func cardStyle() -> some ViewModifier {
            WatchCardModifier()
        }
        
        // Metric Display Styles
        static func metricStyle() -> some ViewModifier {
            WatchMetricModifier()
        }
    }
    
    // MARK: - Accessibility
    
    struct Accessibility {
        static let minimumTapTarget: CGFloat = 44
        static let preferredTapTarget: CGFloat = 48
        
        static func accessibilitySize(for size: Font) -> Font {
            // Scale font based on accessibility settings
            return size
        }
    }
}

// MARK: - Custom Button Styles

struct WatchPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(WatchTheme.Typography.labelLarge)
            .foregroundColor(WatchTheme.Colors.textOnPrimary)
            .padding(.horizontal, WatchTheme.Spacing.md)
            .padding(.vertical, WatchTheme.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: WatchTheme.CornerRadius.watchButton)
                    .fill(WatchTheme.Colors.primary)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(WatchTheme.Animation.buttonPress, value: configuration.isPressed)
    }
}

struct WatchSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(WatchTheme.Typography.labelLarge)
            .foregroundColor(WatchTheme.Colors.textPrimary)
            .padding(.horizontal, WatchTheme.Spacing.md)
            .padding(.vertical, WatchTheme.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: WatchTheme.CornerRadius.watchButton)
                    .stroke(WatchTheme.Colors.border, lineWidth: 1)
                    .background(
                        RoundedRectangle(cornerRadius: WatchTheme.CornerRadius.watchButton)
                            .fill(WatchTheme.Colors.surface)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(WatchTheme.Animation.buttonPress, value: configuration.isPressed)
    }
}

struct WatchDestructiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(WatchTheme.Typography.labelLarge)
            .foregroundColor(WatchTheme.Colors.textOnPrimary)
            .padding(.horizontal, WatchTheme.Spacing.md)
            .padding(.vertical, WatchTheme.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: WatchTheme.CornerRadius.watchButton)
                    .fill(WatchTheme.Colors.error)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(WatchTheme.Animation.buttonPress, value: configuration.isPressed)
    }
}

// MARK: - Custom View Modifiers

struct WatchCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: WatchTheme.CornerRadius.watchCard)
                    .fill(WatchTheme.Colors.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: WatchTheme.CornerRadius.watchCard)
                    .stroke(WatchTheme.Colors.border, lineWidth: 0.5)
            )
    }
}

struct WatchMetricModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(WatchTheme.Typography.metric)
            .foregroundColor(WatchTheme.Colors.textPrimary)
    }
}

// MARK: - Helper Extensions

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

extension View {
    func watchCard() -> some View {
        self.modifier(WatchCardModifier())
    }
    
    func watchMetric() -> some View {
        self.modifier(WatchMetricModifier())
    }
}

// MARK: - Preview Helpers

struct WatchThemePreview: View {
    var body: some View {
        ScrollView {
            VStack(spacing: WatchTheme.Spacing.md) {
                // Colors Preview
                VStack {
                    Text("Colors")
                        .font(WatchTheme.Typography.headlineMedium)
                    
                    HStack {
                        Circle()
                            .fill(WatchTheme.Colors.primary)
                            .frame(width: 30, height: 30)
                        Circle()
                            .fill(WatchTheme.Colors.secondary)
                            .frame(width: 30, height: 30)
                        Circle()
                            .fill(WatchTheme.Colors.accent)
                            .frame(width: 30, height: 30)
                        Circle()
                            .fill(WatchTheme.Colors.error)
                            .frame(width: 30, height: 30)
                    }
                }
                .watchCard()
                .padding(WatchTheme.Spacing.md)
                
                // Typography Preview
                VStack {
                    Text("Typography")
                        .font(WatchTheme.Typography.headlineMedium)
                    
                    Text("Display Large")
                        .font(WatchTheme.Typography.displayLarge)
                    
                    Text("Body Medium")
                        .font(WatchTheme.Typography.bodyMedium)
                    
                    Text("Caption")
                        .font(WatchTheme.Typography.caption)
                }
                .watchCard()
                .padding(WatchTheme.Spacing.md)
                
                // Buttons Preview
                VStack {
                    Text("Buttons")
                        .font(WatchTheme.Typography.headlineMedium)
                    
                    Button("Primary") {}
                        .buttonStyle(WatchTheme.Components.primaryButtonStyle())
                    
                    Button("Secondary") {}
                        .buttonStyle(WatchTheme.Components.secondaryButtonStyle())
                    
                    Button("Destructive") {}
                        .buttonStyle(WatchTheme.Components.destructiveButtonStyle())
                }
                .watchCard()
                .padding(WatchTheme.Spacing.md)
            }
        }
        .background(WatchTheme.Colors.background)
    }
}

struct ShadowStyle {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

#Preview {
    WatchThemePreview()
}