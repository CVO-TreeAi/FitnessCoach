import SwiftUI
import Combine

public class ThemeManager: ObservableObject {
    @Published public private(set) var currentTheme: any ThemeProtocol
    
    private let userDefaults = UserDefaults.standard
    private let themeKey = "selectedTheme"
    
    public init() {
        let savedThemeName = userDefaults.string(forKey: themeKey) ?? ThemeName.default.rawValue
        self.currentTheme = Self.theme(for: ThemeName(rawValue: savedThemeName) ?? .default)
    }
    
    public func setTheme(_ themeName: ThemeName) {
        currentTheme = Self.theme(for: themeName)
        userDefaults.set(themeName.rawValue, forKey: themeKey)
    }
    
    private static func theme(for name: ThemeName) -> any ThemeProtocol {
        switch name {
        case .default:
            return DefaultTheme()
        case .fitness:
            return FitnessTheme()
        }
    }
}

public enum ThemeName: String, CaseIterable {
    case `default` = "default"
    case fitness = "fitness"
    
    public var displayName: String {
        switch self {
        case .default:
            return "Default"
        case .fitness:
            return "Fitness"
        }
    }
}

// Environment Key for Theme
private struct ThemeKey: EnvironmentKey {
    static let defaultValue: any ThemeProtocol = DefaultTheme()
}

extension EnvironmentValues {
    public var theme: any ThemeProtocol {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

// View Extension for easy theme access
extension View {
    public func theme(_ theme: any ThemeProtocol) -> some View {
        environment(\.theme, theme)
    }
}