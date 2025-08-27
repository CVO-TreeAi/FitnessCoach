import SwiftUI

public struct NutritionView: View {
    @StateObject private var viewModel = NutritionViewModel()
    @EnvironmentObject private var authManager: AuthenticationManager
    @Environment(\.theme) private var theme
    
    public var body: some View {
        NavigationView {
            ZStack {
                theme.backgroundColor.ignoresSafeArea()
                
                if viewModel.isLoading {
                    LoadingView(message: "Loading nutrition data...")
                } else {
                    ScrollView {
                        LazyVStack(spacing: theme.spacing.lg) {
                            // Date selector
                            dateSelector
                            
                            // Daily summary
                            dailySummarySection
                            
                            // Macro breakdown
                            macroBreakdownSection
                            
                            // Meals
                            mealsSection
                            
                            // Water intake
                            waterIntakeSection
                            
                            // Quick add foods
                            quickAddSection
                        }
                        .padding(.horizontal, theme.spacing.lg)
                        .padding(.bottom, theme.spacing.xl)
                    }
                    .refreshable {
                        await viewModel.refresh()
                    }
                }
                
                // Floating action button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        
                        Button {
                            viewModel.showFoodSearch = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 56, height: 56)
                                .background(theme.primaryColor)
                                .clipShape(Circle())
                                .shadow(radius: 4)
                        }
                        .padding(.trailing, theme.spacing.lg)
                        .padding(.bottom, theme.spacing.xl)
                    }
                }
            }
            .navigationTitle("Nutrition")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Food Database") {
                            viewModel.showFoodDatabase = true
                        }
                        
                        Button("Meal Planner") {
                            viewModel.showMealPlanner = true
                        }
                        
                        Button("Macro Calculator") {
                            viewModel.showMacroCalculator = true
                        }
                        
                        if authManager.hasPermission(.createPrograms) {
                            Button("Recipe Builder") {
                                viewModel.showRecipeBuilder = true
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(theme.primaryColor)
                    }
                }
            }
        }
        .sheet(isPresented: $viewModel.showFoodSearch) {
            FoodSearchView { food, quantity in
                viewModel.addFoodEntry(food: food, quantity: quantity, mealType: viewModel.selectedMealType)
            }
        }
        .sheet(isPresented: $viewModel.showFoodDatabase) {
            FoodDatabaseView()
        }
        .sheet(isPresented: $viewModel.showMealPlanner) {
            MealPlannerView()
        }
        .sheet(isPresented: $viewModel.showMacroCalculator) {
            MacroCalculatorView()
        }
        .sheet(isPresented: $viewModel.showRecipeBuilder) {
            RecipeBuilderView()
        }
        .onAppear {
            Task {
                await viewModel.loadData()
            }
        }
    }
    
    // MARK: - Date Selector
    
    private var dateSelector: some View {
        HStack {
            Button {
                viewModel.previousDay()
            } label: {
                Image(systemName: "chevron.left")
                    .foregroundColor(theme.primaryColor)
            }
            
            Spacer()
            
            Text(formattedDate(viewModel.selectedDate))
                .font(theme.titleMediumFont)
                .foregroundColor(theme.textPrimary)
            
            Spacer()
            
            Button {
                viewModel.nextDay()
            } label: {
                Image(systemName: "chevron.right")
                    .foregroundColor(viewModel.canGoToNextDay ? theme.primaryColor : theme.textTertiary)
            }
            .disabled(!viewModel.canGoToNextDay)
        }
        .padding(.vertical, theme.spacing.sm)
    }
    
    // MARK: - Daily Summary Section
    
    private var dailySummarySection: some View {
        ThemedCard {
            VStack(spacing: theme.spacing.lg) {
                HStack {
                    Text("Daily Summary")
                        .font(theme.titleMediumFont)
                        .foregroundColor(theme.textPrimary)
                    
                    Spacer()
                    
                    Text("\(Int(viewModel.totalCalories))/\(Int(viewModel.calorieGoal)) cal")
                        .font(theme.bodyMediumFont)
                        .foregroundColor(theme.primaryColor)
                }
                
                // Calorie progress bar
                ProgressView(value: viewModel.calorieProgress)
                    .progressViewStyle(.linear)
                    .tint(progressColor(for: viewModel.calorieProgress))
                    .background(theme.surfaceColor)
                
                // Macro summary
                HStack(spacing: theme.spacing.xl) {
                    MacroSummaryItem(
                        name: "Protein",
                        current: viewModel.totalProtein,
                        goal: viewModel.proteinGoal,
                        unit: "g",
                        color: .blue
                    )
                    
                    MacroSummaryItem(
                        name: "Carbs",
                        current: viewModel.totalCarbs,
                        goal: viewModel.carbsGoal,
                        unit: "g",
                        color: .green
                    )
                    
                    MacroSummaryItem(
                        name: "Fat",
                        current: viewModel.totalFat,
                        goal: viewModel.fatGoal,
                        unit: "g",
                        color: .orange
                    )
                }
            }
        }
    }
    
    // MARK: - Macro Breakdown Section
    
    private var macroBreakdownSection: some View {
        MacroChart(
            protein: viewModel.totalProtein,
            carbs: viewModel.totalCarbs,
            fat: viewModel.totalFat,
            title: "Macro Breakdown"
        )
    }
    
    // MARK: - Meals Section
    
    private var mealsSection: some View {
        VStack(spacing: theme.spacing.md) {
            ForEach(MealType.allCases, id: \.self) { mealType in
                MealCard(
                    mealType: mealType,
                    entries: viewModel.entriesForMeal(mealType),
                    totalCalories: viewModel.caloriesForMeal(mealType),
                    onAddFood: {
                        viewModel.selectedMealType = mealType
                        viewModel.showFoodSearch = true
                    },
                    onEditEntry: { entry in
                        viewModel.editEntry(entry)
                    },
                    onDeleteEntry: { entry in
                        viewModel.deleteEntry(entry)
                    }
                )
            }
        }
    }
    
    // MARK: - Water Intake Section
    
    private var waterIntakeSection: some View {
        ThemedCard {
            VStack(spacing: theme.spacing.md) {
                HStack {
                    Text("Water Intake")
                        .font(theme.titleMediumFont)
                        .foregroundColor(theme.textPrimary)
                    
                    Spacer()
                    
                    Text("\(Int(viewModel.waterIntake))/\(Int(viewModel.waterGoal)) cups")
                        .font(theme.bodyMediumFont)
                        .foregroundColor(theme.primaryColor)
                }
                
                // Water progress
                HStack {
                    ForEach(0..<8) { index in
                        Button {
                            viewModel.toggleWaterCup(index)
                        } label: {
                            Image(systemName: "drop.fill")
                                .font(.title2)
                                .foregroundColor(index < Int(viewModel.waterIntake) ? .blue : theme.textTertiary)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                HStack(spacing: theme.spacing.md) {
                    ThemedButton("Add Cup", style: .secondary, size: .small) {
                        viewModel.addWaterCup()
                    }
                    
                    if viewModel.waterIntake > 0 {
                        ThemedButton("Remove Cup", style: .secondary, size: .small) {
                            viewModel.removeWaterCup()
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Quick Add Section
    
    private var quickAddSection: some View {
        ThemedCard {
            VStack(alignment: .leading, spacing: theme.spacing.md) {
                Text("Quick Add")
                    .font(theme.titleMediumFont)
                    .foregroundColor(theme.textPrimary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: theme.spacing.md) {
                        ForEach(viewModel.commonFoods) { food in
                            QuickAddFoodCard(food: food) {
                                viewModel.quickAddFood(food)
                            }
                        }
                    }
                    .padding(.horizontal, theme.spacing.lg)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(date) {
            return "Today"
        } else if Calendar.current.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            formatter.dateFormat = "MMM d, yyyy"
            return formatter.string(from: date)
        }
    }
    
    private func progressColor(for progress: Double) -> Color {
        switch progress {
        case 0..<0.5: return .red
        case 0.5..<0.8: return .orange
        case 0.8..<1.2: return .green
        default: return .red
        }
    }
}

// MARK: - Supporting Views

private struct MacroSummaryItem: View {
    let name: String
    let current: Double
    let goal: Double
    let unit: String
    let color: Color
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(spacing: theme.spacing.xs) {
            Text(name)
                .font(theme.bodySmallFont)
                .foregroundColor(theme.textSecondary)
            
            Text("\(Int(current))\(unit)")
                .font(theme.titleSmallFont)
                .foregroundColor(theme.textPrimary)
            
            Text("\(Int(goal)) goal")
                .font(.caption2)
                .foregroundColor(theme.textTertiary)
            
            ProgressView(value: current / goal)
                .progressViewStyle(.linear)
                .tint(color)
                .frame(height: 4)
        }
    }
}

private struct MealCard: View {
    let mealType: MealType
    let entries: [NutritionEntryModel]
    let totalCalories: Double
    let onAddFood: () -> Void
    let onEditEntry: (NutritionEntryModel) -> Void
    let onDeleteEntry: (NutritionEntryModel) -> Void
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        ThemedCard {
            VStack(spacing: theme.spacing.md) {
                HStack {
                    Text(mealType.displayName)
                        .font(theme.titleMediumFont)
                        .foregroundColor(theme.textPrimary)
                    
                    Spacer()
                    
                    Text("\(Int(totalCalories)) cal")
                        .font(theme.bodyMediumFont)
                        .foregroundColor(theme.primaryColor)
                    
                    Button {
                        onAddFood()
                    } label: {
                        Image(systemName: "plus.circle")
                            .foregroundColor(theme.primaryColor)
                    }
                }
                
                if entries.isEmpty {
                    InlineEmptyStateView(
                        message: "No foods added for \(mealType.displayName.lowercased())",
                        iconName: "fork.knife"
                    )
                    .frame(height: 60)
                } else {
                    VStack(spacing: theme.spacing.sm) {
                        ForEach(entries) { entry in
                            NutritionEntryRow(
                                entry: entry,
                                onEdit: { onEditEntry(entry) },
                                onDelete: { onDeleteEntry(entry) }
                            )
                        }
                    }
                }
            }
        }
    }
}

private struct NutritionEntryRow: View {
    let entry: NutritionEntryModel
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                Text(entry.foodName)
                    .font(theme.bodyMediumFont)
                    .foregroundColor(theme.textPrimary)
                
                Text("\(formatQuantity(entry.quantity)) \(entry.unit)")
                    .font(theme.bodySmallFont)
                    .foregroundColor(theme.textSecondary)
            }
            
            Spacer()
            
            Text("\(Int(entry.calories)) cal")
                .font(theme.bodyMediumFont)
                .foregroundColor(theme.primaryColor)
            
            Menu {
                Button("Edit") {
                    onEdit()
                }
                Button("Delete", role: .destructive) {
                    onDelete()
                }
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundColor(theme.textSecondary)
            }
        }
        .padding(.vertical, theme.spacing.xs)
    }
    
    private func formatQuantity(_ quantity: Double) -> String {
        if quantity.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", quantity)
        } else {
            return String(format: "%.1f", quantity)
        }
    }
}

private struct QuickAddFoodCard: View {
    let food: CommonFood
    let onAdd: () -> Void
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        Button(action: onAdd) {
            VStack(spacing: theme.spacing.sm) {
                Text(food.name)
                    .font(theme.bodySmallFont)
                    .foregroundColor(theme.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text("\(Int(food.calories)) cal")
                    .font(theme.bodySmallFont)
                    .foregroundColor(theme.primaryColor)
            }
            .frame(width: 80, height: 60)
            .background(theme.surfaceColor)
            .cornerRadius(theme.cornerRadius.medium)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Supporting Types

public enum MealType: String, CaseIterable {
    case breakfast = "breakfast"
    case lunch = "lunch"
    case dinner = "dinner"
    case snacks = "snacks"
    
    public var displayName: String {
        switch self {
        case .breakfast: return "Breakfast"
        case .lunch: return "Lunch"
        case .dinner: return "Dinner"
        case .snacks: return "Snacks"
        }
    }
    
    public var icon: String {
        switch self {
        case .breakfast: return "sunrise"
        case .lunch: return "sun.max"
        case .dinner: return "sunset"
        case .snacks: return "leaf"
        }
    }
}

// MARK: - Preview

#Preview {
    NutritionView()
        .environmentObject(AuthenticationManager())
        .theme(FitnessTheme())
}