import SwiftUI

public struct DefaultTheme: ThemeProtocol {
    // Primary Colors
    public var primaryColor: Color = Color(red: 0.0, green: 0.48, blue: 1.0)
    public var primaryVariant: Color = Color(red: 0.0, green: 0.4, blue: 0.9)
    public var secondaryColor: Color = Color(red: 0.0, green: 0.78, blue: 0.36)
    public var secondaryVariant: Color = Color(red: 0.0, green: 0.6, blue: 0.28)
    
    // Background Colors
    public var backgroundColor: Color = Color(.systemBackground)
    public var surfaceColor: Color = Color(.secondarySystemBackground)
    public var cardColor: Color = Color(.tertiarySystemBackground)
    public var overlayColor: Color = Color.black.opacity(0.4)
    
    // Semantic Colors
    public var errorColor: Color = Color(.systemRed)
    public var errorVariant: Color = Color(red: 0.8, green: 0.2, blue: 0.2)
    public var successColor: Color = Color(.systemGreen)
    public var successVariant: Color = Color(red: 0.2, green: 0.7, blue: 0.2)
    public var warningColor: Color = Color(.systemOrange)
    public var warningVariant: Color = Color(red: 0.9, green: 0.6, blue: 0.1)
    public var infoColor: Color = Color(.systemBlue)
    public var infoVariant: Color = Color(red: 0.2, green: 0.6, blue: 0.9)
    
    // Text Colors
    public var textPrimary: Color = Color(.label)
    public var textSecondary: Color = Color(.secondaryLabel)
    public var textTertiary: Color = Color(.tertiaryLabel)
    public var textOnPrimary: Color = Color.white
    public var textOnSecondary: Color = Color.white
    public var textDisabled: Color = Color(.quaternaryLabel)
    
    // Interactive Colors
    public var interactivePrimary: Color = Color(red: 0.0, green: 0.48, blue: 1.0)
    public var interactiveSecondary: Color = Color(.systemGray6)
    public var interactiveDisabled: Color = Color(.systemGray4)
    public var focusColor: Color = Color.accentColor
    
    // Component Systems
    public var gradients: ThemeGradients = ThemeGradients()
    public var typography: ThemeTypography = ThemeTypography()
    public var spacing: ThemeSpacing = ThemeSpacing()
    public var cornerRadius: ThemeCornerRadius = ThemeCornerRadius()
    public var shadows: ThemeShadows = ThemeShadows()
    public var animations: ThemeAnimations = ThemeAnimations()
    public var layout: ThemeLayout = ThemeLayout()
    
    public init() {}
}

public struct FitnessTheme: ThemeProtocol {
    // Primary Colors - Energy and motivation focused
    public var primaryColor: Color = Color(red: 1.0, green: 0.27, blue: 0.0) // Energy orange
    public var primaryVariant: Color = Color(red: 0.9, green: 0.35, blue: 0.1)
    public var secondaryColor: Color = Color(red: 0.0, green: 0.6, blue: 0.8) // Athletic blue
    public var secondaryVariant: Color = Color(red: 0.1, green: 0.5, blue: 0.7)
    
    // Background Colors
    public var backgroundColor: Color = Color(.systemBackground)
    public var surfaceColor: Color = Color(.secondarySystemBackground)
    public var cardColor: Color = Color(.tertiarySystemBackground)
    public var overlayColor: Color = Color.black.opacity(0.6)
    
    // Semantic Colors - High contrast for motivation
    public var errorColor: Color = Color(red: 0.9, green: 0.2, blue: 0.2)
    public var errorVariant: Color = Color(red: 0.8, green: 0.3, blue: 0.3)
    public var successColor: Color = Color(red: 0.2, green: 0.8, blue: 0.2) // Achievement green
    public var successVariant: Color = Color(red: 0.3, green: 0.7, blue: 0.3)
    public var warningColor: Color = Color(red: 1.0, green: 0.6, blue: 0.0)
    public var warningVariant: Color = Color(red: 0.9, green: 0.7, blue: 0.2)
    public var infoColor: Color = Color(red: 0.2, green: 0.7, blue: 1.0)
    public var infoVariant: Color = Color(red: 0.3, green: 0.6, blue: 0.9)
    
    // Text Colors
    public var textPrimary: Color = Color(.label)
    public var textSecondary: Color = Color(.secondaryLabel)
    public var textTertiary: Color = Color(.tertiaryLabel)
    public var textOnPrimary: Color = Color.white
    public var textOnSecondary: Color = Color.white
    public var textDisabled: Color = Color(.quaternaryLabel)
    
    // Interactive Colors
    public var interactivePrimary: Color = Color(red: 1.0, green: 0.27, blue: 0.0)
    public var interactiveSecondary: Color = Color(.systemGray5)
    public var interactiveDisabled: Color = Color(.systemGray3)
    public var focusColor: Color = Color(red: 1.0, green: 0.4, blue: 0.1)
    
    // Component Systems with fitness-focused customizations
    public var gradients: ThemeGradients = ThemeGradients(
        primary: LinearGradient(
            colors: [Color(red: 1.0, green: 0.27, blue: 0.0), Color(red: 1.0, green: 0.4, blue: 0.1)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        secondary: LinearGradient(
            colors: [Color(red: 0.0, green: 0.6, blue: 0.8), Color(red: 0.1, green: 0.7, blue: 0.9)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
    
    public var typography: ThemeTypography = ThemeTypography(
        displayLarge: .system(.largeTitle, design: .rounded, weight: .black),
        displayMedium: .system(.title, design: .rounded, weight: .heavy),
        displaySmall: .system(.title2, design: .rounded, weight: .bold),
        headlineLarge: .system(.title2, design: .rounded, weight: .bold),
        headlineMedium: .system(.title3, design: .rounded, weight: .semibold),
        headlineSmall: .system(.headline, design: .rounded, weight: .semibold)
    )
    
    public var spacing: ThemeSpacing = ThemeSpacing()
    public var cornerRadius: ThemeCornerRadius = ThemeCornerRadius()
    public var shadows: ThemeShadows = ThemeShadows()
    public var animations: ThemeAnimations = ThemeAnimations()
    public var layout: ThemeLayout = ThemeLayout()
    
    public init() {}
}

// MARK: - Dark Theme
public struct DarkFitnessTheme: ThemeProtocol {
    // Primary Colors - Optimized for dark mode
    public var primaryColor: Color = Color(red: 1.0, green: 0.4, blue: 0.1)
    public var primaryVariant: Color = Color(red: 0.9, green: 0.5, blue: 0.2)
    public var secondaryColor: Color = Color(red: 0.2, green: 0.7, blue: 0.9)
    public var secondaryVariant: Color = Color(red: 0.3, green: 0.6, blue: 0.8)
    
    // Background Colors - Rich darks
    public var backgroundColor: Color = Color(.systemBackground)
    public var surfaceColor: Color = Color(.secondarySystemBackground)
    public var cardColor: Color = Color(.tertiarySystemBackground)
    public var overlayColor: Color = Color.black.opacity(0.8)
    
    // Semantic Colors
    public var errorColor: Color = Color(red: 1.0, green: 0.3, blue: 0.3)
    public var errorVariant: Color = Color(red: 0.9, green: 0.4, blue: 0.4)
    public var successColor: Color = Color(red: 0.3, green: 0.9, blue: 0.3)
    public var successVariant: Color = Color(red: 0.4, green: 0.8, blue: 0.4)
    public var warningColor: Color = Color(red: 1.0, green: 0.7, blue: 0.2)
    public var warningVariant: Color = Color(red: 0.9, green: 0.8, blue: 0.3)
    public var infoColor: Color = Color(red: 0.4, green: 0.8, blue: 1.0)
    public var infoVariant: Color = Color(red: 0.5, green: 0.7, blue: 0.9)
    
    // Text Colors
    public var textPrimary: Color = Color(.label)
    public var textSecondary: Color = Color(.secondaryLabel)
    public var textTertiary: Color = Color(.tertiaryLabel)
    public var textOnPrimary: Color = Color.black
    public var textOnSecondary: Color = Color.white
    public var textDisabled: Color = Color(.quaternaryLabel)
    
    // Interactive Colors
    public var interactivePrimary: Color = Color(red: 1.0, green: 0.4, blue: 0.1)
    public var interactiveSecondary: Color = Color(.systemGray6)
    public var interactiveDisabled: Color = Color(.systemGray4)
    public var focusColor: Color = Color(red: 1.0, green: 0.5, blue: 0.2)
    
    // Component Systems
    public var gradients: ThemeGradients = ThemeGradients()
    public var typography: ThemeTypography = ThemeTypography()
    public var spacing: ThemeSpacing = ThemeSpacing()
    public var cornerRadius: ThemeCornerRadius = ThemeCornerRadius()
    public var shadows: ThemeShadows = ThemeShadows()
    public var animations: ThemeAnimations = ThemeAnimations()
    public var layout: ThemeLayout = ThemeLayout()
    
    public init() {}
}