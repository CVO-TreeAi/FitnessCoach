import SwiftUI

// MARK: - Shimmer Effect
public struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0
    private let duration: Double
    private let bounce: Bool
    private let delay: Double
    
    public init(duration: Double = 1.5, bounce: Bool = false, delay: Double = 0) {
        self.duration = duration
        self.bounce = bounce
        self.delay = delay
    }
    
    public func body(content: Content) -> some View {
        content
            .overlay(
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                .clear,
                                .white.opacity(0.6),
                                .clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .rotationEffect(.degrees(30))
                    .offset(x: phase)
                    .clipped()
            )
            .onAppear {
                withAnimation(
                    .linear(duration: duration)
                    .repeatForever(autoreverses: bounce)
                    .delay(delay)
                ) {
                    phase = 400
                }
            }
    }
}

public extension View {
    func shimmer(duration: Double = 1.5, bounce: Bool = false, delay: Double = 0) -> some View {
        modifier(ShimmerEffect(duration: duration, bounce: bounce, delay: delay))
    }
}

// MARK: - Shimmer Loading Views
public struct ShimmerLoadingView: View {
    public enum ShimmerStyle {
        case card
        case list
        case grid
        case profile
        case chart
        case workout
        case nutrition
    }
    
    private let style: ShimmerStyle
    private let count: Int
    
    @Environment(\.theme) private var theme
    
    public init(style: ShimmerStyle, count: Int = 3) {
        self.style = style
        self.count = count
    }
    
    public var body: some View {
        Group {
            switch style {
            case .card:
                cardShimmer
            case .list:
                listShimmer
            case .grid:
                gridShimmer
            case .profile:
                profileShimmer
            case .chart:
                chartShimmer
            case .workout:
                workoutShimmer
            case .nutrition:
                nutritionShimmer
            }
        }
    }
    
    // MARK: - Card Shimmer
    private var cardShimmer: some View {
        VStack(spacing: theme.spacing.md) {
            ForEach(0..<count, id: \.self) { index in
                VStack(alignment: .leading, spacing: theme.spacing.sm) {
                    // Header
                    HStack {
                        RoundedRectangle(cornerRadius: theme.cornerRadius.sm)
                            .fill(theme.surfaceColor)
                            .frame(width: 60, height: 20)
                            .shimmer(delay: Double(index) * 0.1)
                        
                        Spacer()
                        
                        Circle()
                            .fill(theme.surfaceColor)
                            .frame(width: 16, height: 16)
                            .shimmer(delay: Double(index) * 0.1 + 0.2)
                    }
                    
                    // Main content
                    RoundedRectangle(cornerRadius: theme.cornerRadius.sm)
                        .fill(theme.surfaceColor)
                        .frame(height: 120)
                        .shimmer(delay: Double(index) * 0.1 + 0.3)
                    
                    // Footer
                    HStack {
                        RoundedRectangle(cornerRadius: theme.cornerRadius.sm)
                            .fill(theme.surfaceColor)
                            .frame(width: 80, height: 16)
                            .shimmer(delay: Double(index) * 0.1 + 0.4)
                        
                        Spacer()
                        
                        RoundedRectangle(cornerRadius: theme.cornerRadius.sm)
                            .fill(theme.surfaceColor)
                            .frame(width: 40, height: 16)
                            .shimmer(delay: Double(index) * 0.1 + 0.5)
                    }
                }
                .padding(theme.spacing.md)
                .background(theme.cardColor)
                .cornerRadius(theme.cornerRadius.card)
            }
        }
    }
    
    // MARK: - List Shimmer
    private var listShimmer: some View {
        VStack(spacing: theme.spacing.sm) {
            ForEach(0..<count, id: \.self) { index in
                HStack(spacing: theme.spacing.sm) {
                    Circle()
                        .fill(theme.surfaceColor)
                        .frame(width: 44, height: 44)
                        .shimmer(delay: Double(index) * 0.05)
                    
                    VStack(alignment: .leading, spacing: theme.spacing.xs) {
                        RoundedRectangle(cornerRadius: theme.cornerRadius.xs)
                            .fill(theme.surfaceColor)
                            .frame(height: 16)
                            .shimmer(delay: Double(index) * 0.05 + 0.1)
                        
                        RoundedRectangle(cornerRadius: theme.cornerRadius.xs)
                            .fill(theme.surfaceColor)
                            .frame(width: 120, height: 12)
                            .shimmer(delay: Double(index) * 0.05 + 0.2)
                    }
                    
                    Spacer()
                    
                    RoundedRectangle(cornerRadius: theme.cornerRadius.xs)
                        .fill(theme.surfaceColor)
                        .frame(width: 30, height: 12)
                        .shimmer(delay: Double(index) * 0.05 + 0.3)
                }
                .padding(.horizontal, theme.spacing.md)
                .padding(.vertical, theme.spacing.sm)
            }
        }
    }
    
    // MARK: - Grid Shimmer
    private var gridShimmer: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible()), count: 2),
            spacing: theme.spacing.md
        ) {
            ForEach(0..<count * 2, id: \.self) { index in
                VStack(alignment: .leading, spacing: theme.spacing.sm) {
                    RoundedRectangle(cornerRadius: theme.cornerRadius.sm)
                        .fill(theme.surfaceColor)
                        .aspectRatio(1.5, contentMode: .fit)
                        .shimmer(delay: Double(index) * 0.1)
                    
                    RoundedRectangle(cornerRadius: theme.cornerRadius.xs)
                        .fill(theme.surfaceColor)
                        .frame(height: 16)
                        .shimmer(delay: Double(index) * 0.1 + 0.2)
                    
                    RoundedRectangle(cornerRadius: theme.cornerRadius.xs)
                        .fill(theme.surfaceColor)
                        .frame(width: 80, height: 12)
                        .shimmer(delay: Double(index) * 0.1 + 0.3)
                }
                .padding(theme.spacing.sm)
                .background(theme.cardColor)
                .cornerRadius(theme.cornerRadius.card)
            }
        }
        .padding(.horizontal, theme.spacing.md)
    }
    
    // MARK: - Profile Shimmer
    private var profileShimmer: some View {
        VStack(spacing: theme.spacing.lg) {
            // Profile header
            VStack(spacing: theme.spacing.md) {
                Circle()
                    .fill(theme.surfaceColor)
                    .frame(width: 80, height: 80)
                    .shimmer()
                
                VStack(spacing: theme.spacing.xs) {
                    RoundedRectangle(cornerRadius: theme.cornerRadius.sm)
                        .fill(theme.surfaceColor)
                        .frame(width: 120, height: 20)
                        .shimmer(delay: 0.2)
                    
                    RoundedRectangle(cornerRadius: theme.cornerRadius.sm)
                        .fill(theme.surfaceColor)
                        .frame(width: 80, height: 16)
                        .shimmer(delay: 0.3)
                }
            }
            
            // Stats row
            HStack {
                ForEach(0..<3, id: \.self) { index in
                    VStack(spacing: theme.spacing.xs) {
                        RoundedRectangle(cornerRadius: theme.cornerRadius.sm)
                            .fill(theme.surfaceColor)
                            .frame(width: 40, height: 24)
                            .shimmer(delay: Double(index) * 0.1 + 0.4)
                        
                        RoundedRectangle(cornerRadius: theme.cornerRadius.sm)
                            .fill(theme.surfaceColor)
                            .frame(width: 60, height: 12)
                            .shimmer(delay: Double(index) * 0.1 + 0.5)
                    }
                    
                    if index < 2 { Spacer() }
                }
            }
            
            // Action buttons
            HStack {
                RoundedRectangle(cornerRadius: theme.cornerRadius.button)
                    .fill(theme.surfaceColor)
                    .frame(height: 44)
                    .shimmer(delay: 0.8)
                
                RoundedRectangle(cornerRadius: theme.cornerRadius.button)
                    .fill(theme.surfaceColor)
                    .frame(width: 60, height: 44)
                    .shimmer(delay: 0.9)
            }
        }
        .padding(theme.spacing.lg)
        .background(theme.cardColor)
        .cornerRadius(theme.cornerRadius.card)
    }
    
    // MARK: - Chart Shimmer
    private var chartShimmer: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            // Chart header
            HStack {
                RoundedRectangle(cornerRadius: theme.cornerRadius.sm)
                    .fill(theme.surfaceColor)
                    .frame(width: 100, height: 20)
                    .shimmer()
                
                Spacer()
                
                RoundedRectangle(cornerRadius: theme.cornerRadius.sm)
                    .fill(theme.surfaceColor)
                    .frame(width: 60, height: 16)
                    .shimmer(delay: 0.1)
            }
            
            // Chart area
            VStack(spacing: theme.spacing.xs) {
                HStack(alignment: .bottom, spacing: 4) {
                    ForEach(0..<12, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(theme.surfaceColor)
                            .frame(height: CGFloat.random(in: 40...120))
                            .shimmer(delay: Double(index) * 0.05 + 0.2)
                    }
                }
                
                // X-axis labels
                HStack {
                    ForEach(0..<5, id: \.self) { index in
                        RoundedRectangle(cornerRadius: theme.cornerRadius.xs)
                            .fill(theme.surfaceColor)
                            .frame(width: 20, height: 12)
                            .shimmer(delay: Double(index) * 0.1 + 0.8)
                        
                        if index < 4 { Spacer() }
                    }
                }
            }
            
            // Legend
            HStack {
                ForEach(0..<3, id: \.self) { index in
                    HStack(spacing: theme.spacing.xs) {
                        Circle()
                            .fill(theme.surfaceColor)
                            .frame(width: 8, height: 8)
                            .shimmer(delay: Double(index) * 0.1 + 1.0)
                        
                        RoundedRectangle(cornerRadius: theme.cornerRadius.xs)
                            .fill(theme.surfaceColor)
                            .frame(width: 40, height: 12)
                            .shimmer(delay: Double(index) * 0.1 + 1.1)
                    }
                    
                    if index < 2 { Spacer() }
                }
            }
        }
        .padding(theme.spacing.md)
        .background(theme.cardColor)
        .cornerRadius(theme.cornerRadius.card)
    }
    
    // MARK: - Workout Shimmer
    private var workoutShimmer: some View {
        VStack(spacing: theme.spacing.md) {
            ForEach(0..<count, id: \.self) { index in
                HStack(spacing: theme.spacing.sm) {
                    // Exercise icon
                    RoundedRectangle(cornerRadius: theme.cornerRadius.sm)
                        .fill(theme.surfaceColor)
                        .frame(width: 50, height: 50)
                        .shimmer(delay: Double(index) * 0.1)
                    
                    VStack(alignment: .leading, spacing: theme.spacing.xs) {
                        // Exercise name
                        RoundedRectangle(cornerRadius: theme.cornerRadius.xs)
                            .fill(theme.surfaceColor)
                            .frame(height: 18)
                            .shimmer(delay: Double(index) * 0.1 + 0.1)
                        
                        // Sets and reps
                        HStack {
                            RoundedRectangle(cornerRadius: theme.cornerRadius.xs)
                                .fill(theme.surfaceColor)
                                .frame(width: 60, height: 14)
                                .shimmer(delay: Double(index) * 0.1 + 0.2)
                            
                            RoundedRectangle(cornerRadius: theme.cornerRadius.xs)
                                .fill(theme.surfaceColor)
                                .frame(width: 40, height: 14)
                                .shimmer(delay: Double(index) * 0.1 + 0.3)
                            
                            Spacer()
                        }
                    }
                    
                    Spacer()
                    
                    // Weight/Duration
                    VStack(alignment: .trailing, spacing: theme.spacing.xs) {
                        RoundedRectangle(cornerRadius: theme.cornerRadius.xs)
                            .fill(theme.surfaceColor)
                            .frame(width: 40, height: 16)
                            .shimmer(delay: Double(index) * 0.1 + 0.4)
                        
                        RoundedRectangle(cornerRadius: theme.cornerRadius.xs)
                            .fill(theme.surfaceColor)
                            .frame(width: 30, height: 12)
                            .shimmer(delay: Double(index) * 0.1 + 0.5)
                    }
                }
                .padding(theme.spacing.sm)
                .background(theme.surfaceColor.opacity(0.3))
                .cornerRadius(theme.cornerRadius.sm)
            }
        }
        .padding(theme.spacing.md)
        .background(theme.cardColor)
        .cornerRadius(theme.cornerRadius.card)
    }
    
    // MARK: - Nutrition Shimmer
    private var nutritionShimmer: some View {
        VStack(spacing: theme.spacing.lg) {
            // Nutrition summary
            HStack {
                ForEach(0..<3, id: \.self) { index in
                    VStack(spacing: theme.spacing.xs) {
                        Circle()
                            .fill(theme.surfaceColor)
                            .frame(width: 60, height: 60)
                            .shimmer(delay: Double(index) * 0.1)
                        
                        RoundedRectangle(cornerRadius: theme.cornerRadius.xs)
                            .fill(theme.surfaceColor)
                            .frame(width: 50, height: 12)
                            .shimmer(delay: Double(index) * 0.1 + 0.2)
                        
                        RoundedRectangle(cornerRadius: theme.cornerRadius.xs)
                            .fill(theme.surfaceColor)
                            .frame(width: 30, height: 16)
                            .shimmer(delay: Double(index) * 0.1 + 0.3)
                    }
                    
                    if index < 2 { Spacer() }
                }
            }
            
            Divider()
            
            // Meal items
            VStack(spacing: theme.spacing.sm) {
                ForEach(0..<4, id: \.self) { index in
                    HStack(spacing: theme.spacing.sm) {
                        RoundedRectangle(cornerRadius: theme.cornerRadius.sm)
                            .fill(theme.surfaceColor)
                            .frame(width: 40, height: 40)
                            .shimmer(delay: Double(index) * 0.05 + 0.5)
                        
                        VStack(alignment: .leading, spacing: theme.spacing.xs) {
                            RoundedRectangle(cornerRadius: theme.cornerRadius.xs)
                                .fill(theme.surfaceColor)
                                .frame(height: 16)
                                .shimmer(delay: Double(index) * 0.05 + 0.6)
                            
                            RoundedRectangle(cornerRadius: theme.cornerRadius.xs)
                                .fill(theme.surfaceColor)
                                .frame(width: 80, height: 12)
                                .shimmer(delay: Double(index) * 0.05 + 0.7)
                        }
                        
                        Spacer()
                        
                        RoundedRectangle(cornerRadius: theme.cornerRadius.xs)
                            .fill(theme.surfaceColor)
                            .frame(width: 40, height: 16)
                            .shimmer(delay: Double(index) * 0.05 + 0.8)
                    }
                }
            }
        }
        .padding(theme.spacing.md)
        .background(theme.cardColor)
        .cornerRadius(theme.cornerRadius.card)
    }
}

// MARK: - Shimmer Modifier for any View
public struct ShimmerableView<Content: View>: View {
    private let content: Content
    private let isLoading: Bool
    
    public init(isLoading: Bool, @ViewBuilder content: () -> Content) {
        self.isLoading = isLoading
        self.content = content()
    }
    
    public var body: some View {
        content
            .opacity(isLoading ? 0 : 1)
            .overlay(
                Group {
                    if isLoading {
                        content
                            .foregroundColor(.clear)
                            .background(Color(.systemGray5))
                            .shimmer()
                    }
                }
            )
            .animation(.easeInOut(duration: 0.3), value: isLoading)
    }
}

public extension View {
    func shimmerLoading(_ isLoading: Bool) -> some View {
        ShimmerableView(isLoading: isLoading) {
            self
        }
    }
}

// MARK: - Preview
#Preview {
    ScrollView {
        VStack(spacing: 32) {
            Text("Shimmer Loading States")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Group {
                Text("Card Shimmer")
                    .font(.headline)
                ShimmerLoadingView(style: .card, count: 2)
                
                Text("List Shimmer")
                    .font(.headline)
                ShimmerLoadingView(style: .list, count: 5)
                
                Text("Grid Shimmer")
                    .font(.headline)
                ShimmerLoadingView(style: .grid, count: 2)
            }
            
            Group {
                Text("Profile Shimmer")
                    .font(.headline)
                ShimmerLoadingView(style: .profile)
                
                Text("Chart Shimmer")
                    .font(.headline)
                ShimmerLoadingView(style: .chart)
                
                Text("Workout Shimmer")
                    .font(.headline)
                ShimmerLoadingView(style: .workout, count: 3)
            }
            
            Group {
                Text("Nutrition Shimmer")
                    .font(.headline)
                ShimmerLoadingView(style: .nutrition)
                
                Text("Custom Shimmer Example")
                    .font(.headline)
                
                VStack(spacing: 16) {
                    Text("Loading content...")
                        .shimmerLoading(true)
                    
                    Text("Loaded content!")
                        .shimmerLoading(false)
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(12)
            }
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
    .theme(FitnessTheme())
}