import SwiftUI

// MARK: - Loading Views

public struct LoadingView: View {
    let message: String
    
    @Environment(\.theme) private var theme
    
    public init(message: String = "Loading...") {
        self.message = message
    }
    
    public var body: some View {
        VStack(spacing: theme.spacing.lg) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(theme.primaryColor)
            
            Text(message)
                .font(theme.bodyLargeFont)
                .foregroundColor(theme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.backgroundColor)
    }
}

public struct InlineLoadingView: View {
    let message: String
    
    @Environment(\.theme) private var theme
    
    public init(message: String = "Loading...") {
        self.message = message
    }
    
    public var body: some View {
        HStack(spacing: theme.spacing.md) {
            ProgressView()
                .scaleEffect(0.8)
                .tint(theme.primaryColor)
            
            Text(message)
                .font(theme.bodyMediumFont)
                .foregroundColor(theme.textSecondary)
        }
        .padding(theme.spacing.md)
    }
}

public struct PullToRefreshLoadingView: View {
    @Environment(\.theme) private var theme
    
    public var body: some View {
        HStack {
            Spacer()
            VStack(spacing: theme.spacing.sm) {
                ProgressView()
                    .scaleEffect(0.8)
                    .tint(theme.primaryColor)
                Text("Refreshing...")
                    .font(theme.bodySmallFont)
                    .foregroundColor(theme.textSecondary)
            }
            Spacer()
        }
        .padding(theme.spacing.md)
    }
}

// MARK: - Empty State Views

public struct EmptyStateView: View {
    let title: String
    let message: String
    let iconName: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    @Environment(\.theme) private var theme
    
    public init(
        title: String,
        message: String,
        iconName: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.iconName = iconName
        self.actionTitle = actionTitle
        self.action = action
    }
    
    public var body: some View {
        VStack(spacing: theme.spacing.xl) {
            Spacer()
            
            VStack(spacing: theme.spacing.lg) {
                Image(systemName: iconName)
                    .font(.system(size: 64))
                    .foregroundColor(theme.textTertiary)
                
                VStack(spacing: theme.spacing.sm) {
                    Text(title)
                        .font(theme.titleLargeFont)
                        .foregroundColor(theme.textPrimary)
                        .multilineTextAlignment(.center)
                    
                    Text(message)
                        .font(theme.bodyMediumFont)
                        .foregroundColor(theme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                
                if let actionTitle = actionTitle, let action = action {
                    ThemedButton(actionTitle, style: .primary, size: .medium) {
                        action()
                    }
                    .padding(.top, theme.spacing.md)
                }
            }
            .padding(.horizontal, theme.spacing.xl)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.backgroundColor)
    }
}

public struct InlineEmptyStateView: View {
    let message: String
    let iconName: String
    
    @Environment(\.theme) private var theme
    
    public init(message: String, iconName: String) {
        self.message = message
        self.iconName = iconName
    }
    
    public var body: some View {
        VStack(spacing: theme.spacing.md) {
            Image(systemName: iconName)
                .font(.title2)
                .foregroundColor(theme.textTertiary)
            
            Text(message)
                .font(theme.bodyMediumFont)
                .foregroundColor(theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(theme.spacing.xl)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Error Views

public struct ErrorView: View {
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    @Environment(\.theme) private var theme
    
    public init(
        title: String = "Something went wrong",
        message: String,
        actionTitle: String? = "Try Again",
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }
    
    public var body: some View {
        VStack(spacing: theme.spacing.xl) {
            Spacer()
            
            VStack(spacing: theme.spacing.lg) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 64))
                    .foregroundColor(theme.errorColor)
                
                VStack(spacing: theme.spacing.sm) {
                    Text(title)
                        .font(theme.titleLargeFont)
                        .foregroundColor(theme.textPrimary)
                        .multilineTextAlignment(.center)
                    
                    Text(message)
                        .font(theme.bodyMediumFont)
                        .foregroundColor(theme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                
                if let actionTitle = actionTitle, let action = action {
                    ThemedButton(actionTitle, style: .primary, size: .medium) {
                        action()
                    }
                    .padding(.top, theme.spacing.md)
                }
            }
            .padding(.horizontal, theme.spacing.xl)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.backgroundColor)
    }
}

public struct InlineErrorView: View {
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    @Environment(\.theme) private var theme
    
    public init(
        message: String,
        actionTitle: String? = "Try Again",
        action: (() -> Void)? = nil
    ) {
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }
    
    public var body: some View {
        VStack(spacing: theme.spacing.md) {
            HStack(spacing: theme.spacing.sm) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(theme.errorColor)
                
                Text(message)
                    .font(theme.bodyMediumFont)
                    .foregroundColor(theme.textSecondary)
                
                Spacer()
            }
            
            if let actionTitle = actionTitle, let action = action {
                HStack {
                    Spacer()
                    ThemedButton(actionTitle, style: .secondary, size: .small) {
                        action()
                    }
                }
            }
        }
        .padding(theme.spacing.md)
        .background(theme.errorColor.opacity(0.1))
        .cornerRadius(theme.cornerRadius.medium)
    }
}

// MARK: - Content Availability States

public enum ContentState<T> {
    case loading
    case loaded(T)
    case empty
    case error(String)
}

public struct ContentStateView<T, Content: View>: View {
    let state: ContentState<T>
    let content: (T) -> Content
    let emptyTitle: String
    let emptyMessage: String
    let emptyIcon: String
    let onRetry: (() -> Void)?
    
    @Environment(\.theme) private var theme
    
    public init(
        state: ContentState<T>,
        emptyTitle: String = "No Data",
        emptyMessage: String = "No data available",
        emptyIcon: String = "tray",
        onRetry: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (T) -> Content
    ) {
        self.state = state
        self.emptyTitle = emptyTitle
        self.emptyMessage = emptyMessage
        self.emptyIcon = emptyIcon
        self.onRetry = onRetry
        self.content = content
    }
    
    public var body: some View {
        switch state {
        case .loading:
            LoadingView()
            
        case .loaded(let data):
            content(data)
            
        case .empty:
            EmptyStateView(
                title: emptyTitle,
                message: emptyMessage,
                iconName: emptyIcon
            )
            
        case .error(let message):
            ErrorView(
                message: message,
                action: onRetry
            )
        }
    }
}

// MARK: - Previews

#Preview("Loading States") {
    VStack(spacing: 20) {
        LoadingView()
            .frame(height: 200)
        
        InlineLoadingView()
        
        PullToRefreshLoadingView()
    }
    .theme(FitnessTheme())
}

#Preview("Empty States") {
    VStack(spacing: 20) {
        EmptyStateView(
            title: "No Workouts",
            message: "Create your first workout to get started with your fitness journey.",
            iconName: "figure.strengthtraining.traditional",
            actionTitle: "Create Workout"
        ) {
            print("Create workout tapped")
        }
        .frame(height: 300)
        
        InlineEmptyStateView(
            message: "No exercises added yet",
            iconName: "dumbbell"
        )
    }
    .theme(FitnessTheme())
}

#Preview("Error States") {
    VStack(spacing: 20) {
        ErrorView(
            message: "Unable to load data. Please check your internet connection and try again."
        ) {
            print("Retry tapped")
        }
        .frame(height: 300)
        
        InlineErrorView(
            message: "Failed to save changes"
        ) {
            print("Retry tapped")
        }
    }
    .theme(FitnessTheme())
}