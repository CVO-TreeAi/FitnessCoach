import SwiftUI

public protocol ThemeProtocol {
    // Primary Colors
    var primaryColor: Color { get }
    var primaryVariant: Color { get }
    var secondaryColor: Color { get }
    var secondaryVariant: Color { get }
    
    // Background Colors
    var backgroundColor: Color { get }
    var surfaceColor: Color { get }
    var cardColor: Color { get }
    var overlayColor: Color { get }
    
    // Semantic Colors
    var errorColor: Color { get }
    var errorVariant: Color { get }
    var successColor: Color { get }
    var successVariant: Color { get }
    var warningColor: Color { get }
    var warningVariant: Color { get }
    var infoColor: Color { get }
    var infoVariant: Color { get }
    
    // Text Colors
    var textPrimary: Color { get }
    var textSecondary: Color { get }
    var textTertiary: Color { get }
    var textOnPrimary: Color { get }
    var textOnSecondary: Color { get }
    var textDisabled: Color { get }
    
    // Interactive Colors
    var interactivePrimary: Color { get }
    var interactiveSecondary: Color { get }
    var interactiveDisabled: Color { get }
    var focusColor: Color { get }
    
    // Gradient Colors
    var gradients: ThemeGradients { get }
    
    // Typography
    var typography: ThemeTypography { get }
    
    // Spacing
    var spacing: ThemeSpacing { get }
    
    // Corner Radius
    var cornerRadius: ThemeCornerRadius { get }
    
    // Shadows
    var shadows: ThemeShadows { get }
    
    // Animations
    var animations: ThemeAnimations { get }
    
    // Layout
    var layout: ThemeLayout { get }
}

// MARK: - Gradients
public struct ThemeGradients {
    public let primary: LinearGradient
    public let secondary: LinearGradient
    public let success: LinearGradient
    public let warning: LinearGradient
    public let error: LinearGradient
    public let surface: LinearGradient
    public let glassmorphism: LinearGradient
    
    public init(
        primary: LinearGradient = LinearGradient(
            colors: [Color(red: 1.0, green: 0.27, blue: 0.0), Color(red: 1.0, green: 0.4, blue: 0.1)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        secondary: LinearGradient = LinearGradient(
            colors: [Color(red: 0.0, green: 0.6, blue: 0.8), Color(red: 0.1, green: 0.7, blue: 0.9)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        success: LinearGradient = LinearGradient(
            colors: [Color(red: 0.2, green: 0.8, blue: 0.2), Color(red: 0.3, green: 0.9, blue: 0.3)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        warning: LinearGradient = LinearGradient(
            colors: [Color.orange, Color.yellow],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        error: LinearGradient = LinearGradient(
            colors: [Color.red, Color.pink],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        surface: LinearGradient = LinearGradient(
            colors: [Color.white.opacity(0.1), Color.white.opacity(0.05)],
            startPoint: .top,
            endPoint: .bottom
        ),
        glassmorphism: LinearGradient = LinearGradient(
            colors: [Color.white.opacity(0.25), Color.white.opacity(0.1)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    ) {
        self.primary = primary
        self.secondary = secondary
        self.success = success
        self.warning = warning
        self.error = error
        self.surface = surface
        self.glassmorphism = glassmorphism
    }
}

// MARK: - Typography
public struct ThemeTypography {
    // Display
    public let displayLarge: Font
    public let displayMedium: Font
    public let displaySmall: Font
    
    // Headlines
    public let headlineLarge: Font
    public let headlineMedium: Font
    public let headlineSmall: Font
    
    // Titles
    public let titleLarge: Font
    public let titleMedium: Font
    public let titleSmall: Font
    
    // Body
    public let bodyLarge: Font
    public let bodyMedium: Font
    public let bodySmall: Font
    
    // Labels
    public let labelLarge: Font
    public let labelMedium: Font
    public let labelSmall: Font
    
    public init(
        displayLarge: Font = .system(.largeTitle, design: .rounded, weight: .black),
        displayMedium: Font = .system(.title, design: .rounded, weight: .bold),
        displaySmall: Font = .system(.title2, design: .rounded, weight: .bold),
        headlineLarge: Font = .system(.title2, design: .rounded, weight: .semibold),
        headlineMedium: Font = .system(.title3, design: .rounded, weight: .semibold),
        headlineSmall: Font = .system(.headline, design: .rounded, weight: .medium),
        titleLarge: Font = .system(.headline, design: .rounded, weight: .medium),
        titleMedium: Font = .system(.subheadline, design: .rounded, weight: .medium),
        titleSmall: Font = .system(.callout, design: .rounded, weight: .medium),
        bodyLarge: Font = .system(.body, design: .rounded),
        bodyMedium: Font = .system(.callout, design: .rounded),
        bodySmall: Font = .system(.caption, design: .rounded),
        labelLarge: Font = .system(.caption, design: .rounded, weight: .semibold),
        labelMedium: Font = .system(.caption2, design: .rounded, weight: .medium),
        labelSmall: Font = .system(.caption2, design: .rounded, weight: .regular)
    ) {
        self.displayLarge = displayLarge
        self.displayMedium = displayMedium
        self.displaySmall = displaySmall
        self.headlineLarge = headlineLarge
        self.headlineMedium = headlineMedium
        self.headlineSmall = headlineSmall
        self.titleLarge = titleLarge
        self.titleMedium = titleMedium
        self.titleSmall = titleSmall
        self.bodyLarge = bodyLarge
        self.bodyMedium = bodyMedium
        self.bodySmall = bodySmall
        self.labelLarge = labelLarge
        self.labelMedium = labelMedium
        self.labelSmall = labelSmall
    }
}

// MARK: - Spacing
public struct ThemeSpacing {
    public let xxs: CGFloat = 2
    public let xs: CGFloat = 4
    public let sm: CGFloat = 8
    public let md: CGFloat = 16
    public let lg: CGFloat = 24
    public let xl: CGFloat = 32
    public let xxl: CGFloat = 48
    public let xxxl: CGFloat = 64
    
    // Component specific spacing
    public let cardPadding: CGFloat = 16
    public let sectionPadding: CGFloat = 24
    public let screenPadding: CGFloat = 20
    
    public init() {}
}

// MARK: - Corner Radius
public struct ThemeCornerRadius {
    public let none: CGFloat = 0
    public let xs: CGFloat = 4
    public let sm: CGFloat = 8
    public let small: CGFloat = 8  // Alias for sm
    public let md: CGFloat = 12
    public let medium: CGFloat = 12  // Alias for md
    public let lg: CGFloat = 16
    public let xl: CGFloat = 20
    public let xxl: CGFloat = 28
    public let round: CGFloat = 50
    
    // Component specific radius
    public let button: CGFloat = 12
    public let card: CGFloat = 16
    public let modal: CGFloat = 20
    public let pill: CGFloat = 50
    
    public init() {}
}

// MARK: - Shadows
public struct ThemeShadows {
    public let none: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) = (Color.clear, 0, 0, 0)
    public let xs: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) = (Color.black.opacity(0.1), 1, 0, 1)
    public let sm: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) = (Color.black.opacity(0.1), 2, 0, 1)
    public let md: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) = (Color.black.opacity(0.1), 4, 0, 2)
    public let medium: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) = (Color.black.opacity(0.1), 4, 0, 2)  // Alias for md
    public let lg: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) = (Color.black.opacity(0.15), 8, 0, 4)
    public let xl: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) = (Color.black.opacity(0.2), 16, 0, 8)
    public let xxl: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) = (Color.black.opacity(0.25), 24, 0, 12)
    
    public init() {}
}

// MARK: - Animations
public struct ThemeAnimations {
    // Durations
    public let fast: Double = 0.15
    public let normal: Double = 0.25
    public let slow: Double = 0.4
    
    // Spring animations
    public let springFast: Animation = .spring(response: 0.3, dampingFraction: 0.7, blendDuration: 0)
    public let springNormal: Animation = .spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0)
    public let springSlow: Animation = .spring(response: 0.7, dampingFraction: 0.9, blendDuration: 0)
    
    // Easing animations
    public let easeIn: Animation = .easeIn(duration: 0.25)
    public let easeOut: Animation = .easeOut(duration: 0.25)
    public let easeInOut: Animation = .easeInOut(duration: 0.25)
    
    // Interactive animations
    public let buttonPress: Animation = .spring(response: 0.2, dampingFraction: 0.6, blendDuration: 0)
    public let cardAppear: Animation = .spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0)
    public let slideIn: Animation = .easeOut(duration: 0.3)
    public let fadeIn: Animation = .easeIn(duration: 0.2)
    
    public init() {}
}

// MARK: - Layout
public struct ThemeLayout {
    // Breakpoints
    public let compact: CGFloat = 320
    public let regular: CGFloat = 414
    public let large: CGFloat = 768
    
    // Grid
    public let gridColumns: Int = 12
    public let gridGutter: CGFloat = 16
    
    // Component dimensions
    public let buttonHeight: (small: CGFloat, medium: CGFloat, large: CGFloat) = (32, 44, 56)
    public let inputHeight: CGFloat = 48
    public let cardMinHeight: CGFloat = 120
    public let tabBarHeight: CGFloat = 84
    public let navigationBarHeight: CGFloat = 44
    
    // Safe areas
    public let bottomSafeAreaBuffer: CGFloat = 16
    
    public init() {}
}

// MARK: - Theme Protocol Extensions for Convenience
public extension ThemeProtocol {
    // Shadow color convenience accessor
    var shadowColor: Color { Color.black.opacity(0.1) }
    
    // Typography convenience accessors
    var titleSmallFont: Font { typography.titleSmall }
    var bodySmallFont: Font { typography.bodySmall }
    var bodyMediumFont: Font { typography.bodyMedium }
    var titleLargeFont: Font { typography.titleLarge }
    var titleMediumFont: Font { typography.titleMedium }
    var headlineSmallFont: Font { typography.headlineSmall }
    var headlineMediumFont: Font { typography.headlineMedium }
    var headlineLargeFont: Font { typography.headlineLarge }
    var labelSmallFont: Font { typography.labelSmall }
    var labelMediumFont: Font { typography.labelMedium }
    var labelLargeFont: Font { typography.labelLarge }
    var bodyLargeFont: Font { typography.bodyLarge }
    var displaySmallFont: Font { typography.displaySmall }
    var displayMediumFont: Font { typography.displayMedium }
    var displayLargeFont: Font { typography.displayLarge }
}