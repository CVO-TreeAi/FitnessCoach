import SwiftUI

public struct ThemedButton: View {
    public enum ButtonStyle {
        case primary
        case secondary
        case outline
        case destructive
        case ghost
    }
    
    public enum ButtonSize {
        case small
        case medium
        case large
        
        var height: CGFloat {
            switch self {
            case .small: return 32
            case .medium: return 44
            case .large: return 56
            }
        }
        
        var horizontalPadding: CGFloat {
            switch self {
            case .small: return 12
            case .medium: return 16
            case .large: return 24
            }
        }
        
        func font(theme: any ThemeProtocol) -> Font {
            switch self {
            case .small: return theme.typography.bodySmall
            case .medium: return theme.typography.bodyMedium
            case .large: return theme.typography.bodyLarge
            }
        }
    }
    
    private let title: String
    private let style: ButtonStyle
    private let size: ButtonSize
    private let action: () -> Void
    private let isEnabled: Bool
    
    @Environment(\.theme) private var theme
    
    public init(
        _ title: String,
        style: ButtonStyle = .primary,
        size: ButtonSize = .medium,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.size = size
        self.isEnabled = isEnabled
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            HStack {
                Spacer()
                Text(title)
                    .font(size.font(theme: theme))
                    .fontWeight(.semibold)
                Spacer()
            }
            .frame(height: size.height)
            .padding(.horizontal, size.horizontalPadding)
            .background(backgroundColor)
            .foregroundColor(textColor)
            .cornerRadius(theme.cornerRadius.button)
            .overlay(
                RoundedRectangle(cornerRadius: theme.cornerRadius.button)
                    .stroke(borderColor, lineWidth: style == .outline ? 2 : 0)
            )
        }
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1.0 : 0.6)
    }
    
    private var backgroundColor: Color {
        switch style {
        case .primary:
            return theme.primaryColor
        case .secondary:
            return theme.secondaryColor
        case .outline:
            return Color.clear
        case .destructive:
            return theme.errorColor
        case .ghost:
            return Color.clear
        }
    }
    
    private var textColor: Color {
        switch style {
        case .primary, .secondary, .destructive:
            return Color.white
        case .outline:
            return theme.primaryColor
        case .ghost:
            return theme.textPrimary
        }
    }
    
    private var borderColor: Color {
        switch style {
        case .outline:
            return theme.primaryColor
        default:
            return Color.clear
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        ThemedButton("Primary Button", style: .primary) {}
        ThemedButton("Secondary Button", style: .secondary) {}
        ThemedButton("Outline Button", style: .outline) {}
        ThemedButton("Destructive Button", style: .destructive) {}
        ThemedButton("Ghost Button", style: .ghost) {}
        
        HStack {
            ThemedButton("Small", style: .primary, size: .small) {}
            ThemedButton("Medium", style: .primary, size: .medium) {}
            ThemedButton("Large", style: .primary, size: .large) {}
        }
    }
    .padding()
    .theme(DefaultTheme())
}