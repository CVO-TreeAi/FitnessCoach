import SwiftUI
import Charts

struct CompleteNutritionView: View {
    @EnvironmentObject private var dataManager: FitnessDataManager
    @Environment(\.theme) private var theme
    
    @State private var selectedDate = Date()
    @State private var showingFoodSearch = false
    @State private var showingMealPlanner = false
    @State private var selectedMealType: MealEntry.MealType?
    
    private let calendar = Calendar.current
    
    // Computed properties for today's nutrition data
    private var todaysMeals: [MealEntry] {
        dataManager.mealEntries.filter { 
            calendar.isDate($0.consumedAt, inSameDayAs: selectedDate)
        }
    }
    
    private var todaysCalories: Double {
        todaysMeals.reduce(0) { $0 + $1.nutritionFacts.calories }
    }
    
    private var todaysProtein: Double {
        todaysMeals.reduce(0) { $0 + $1.nutritionFacts.protein }
    }
    
    private var todaysCarbs: Double {
        todaysMeals.reduce(0) { $0 + $1.nutritionFacts.carbs }
    }
    
    private var todaysFat: Double {
        todaysMeals.reduce(0) { $0 + $1.nutritionFacts.fat }
    }
    
    private var waterIntake: Double {
        dataManager.waterEntries.filter { 
            calendar.isDate($0.timestamp, inSameDayAs: selectedDate)
        }.reduce(0) { $0 + $1.amount }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Date Selector
                    dateSelector
                    
                    // Daily Summary Card
                    dailySummaryCard
                    
                    // Macro Breakdown Chart
                    macroBreakdownCard
                    
                    // Water Tracking
                    waterTrackingCard
                    
                    // Meals Section
                    mealsSection
                    
                    // Quick Add Section
                    quickAddSection
                }
                .padding(.horizontal)
                .padding(.bottom, 100)
            }
            .navigationTitle("Nutrition")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button {
                        showingMealPlanner = true
                    } label: {
                        Image(systemName: "calendar")
                    }
                    
                    Button {
                        showingFoodSearch = true
                    } label: {
                        Image(systemName: "plus.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showingFoodSearch) {
            FoodSearchView(selectedDate: selectedDate)
        }
        .sheet(isPresented: $showingMealPlanner) {
            MealPlannerView()
        }
        .sheet(item: $selectedMealType) { mealType in
            MealDetailView(mealType: mealType, date: selectedDate)
        }
    }
    
    // MARK: - Date Selector
    private var dateSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(getWeekDays(), id: \.self) { date in
                    DateSelectorButton(
                        date: date,
                        isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                        hasData: hasNutritionData(for: date)
                    ) {
                        selectedDate = date
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Daily Summary Card
    private var dailySummaryCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Daily Summary")
                        .font(.headline)
                        .foregroundColor(theme.textPrimary)
                    
                    Text(formatDate(selectedDate))
                        .font(.subheadline)
                        .foregroundColor(theme.textSecondary)
                }
                
                Spacer()
                
                Text("\(Int(todaysCalories))/\(Int(dataManager.dashboardStats.calorieGoal)) cal")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(theme.primaryColor)
            }
            
            // Calorie Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(theme.surfaceColor)
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(calorieProgressColor)
                        .frame(width: geometry.size.width * min(calorieProgress, 1.0), height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)
            
            // Quick Stats
            HStack(spacing: 20) {
                NutritionStatItem(
                    title: "Protein",
                    current: todaysProtein,
                    goal: 140,
                    unit: "g",
                    color: .blue
                )
                
                NutritionStatItem(
                    title: "Carbs",
                    current: todaysCarbs,
                    goal: 275,
                    unit: "g",
                    color: .orange
                )
                
                NutritionStatItem(
                    title: "Fat",
                    current: todaysFat,
                    goal: 73,
                    unit: "g",
                    color: .purple
                )
            }
        }
        .padding()
        .background(theme.surfaceColor)
        .cornerRadius(16)
    }
    
    // MARK: - Macro Breakdown Chart
    private var macroBreakdownCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Macro Breakdown")
                .font(.headline)
                .foregroundColor(theme.textPrimary)
            
            if todaysCalories > 0 {
                HStack(spacing: 20) {
                    // Pie Chart
                    MacroPieChart(
                        protein: todaysProtein,
                        carbs: todaysCarbs,
                        fat: todaysFat
                    )
                    .frame(width: 120, height: 120)
                    
                    // Legend
                    VStack(alignment: .leading, spacing: 8) {
                        MacroLegendItem(
                            color: .blue,
                            title: "Protein",
                            grams: todaysProtein,
                            percentage: (todaysProtein * 4) / todaysCalories * 100
                        )
                        
                        MacroLegendItem(
                            color: .orange,
                            title: "Carbs",
                            grams: todaysCarbs,
                            percentage: (todaysCarbs * 4) / todaysCalories * 100
                        )
                        
                        MacroLegendItem(
                            color: .purple,
                            title: "Fat",
                            grams: todaysFat,
                            percentage: (todaysFat * 9) / todaysCalories * 100
                        )
                    }
                }
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "chart.pie")
                        .font(.title)
                        .foregroundColor(theme.textTertiary)
                    
                    Text("No meals logged yet")
                        .font(.subheadline)
                        .foregroundColor(theme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            }
        }
        .padding()
        .background(theme.surfaceColor)
        .cornerRadius(16)
    }
    
    // MARK: - Water Tracking Card
    private var waterTrackingCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Water Intake")
                    .font(.headline)
                    .foregroundColor(theme.textPrimary)
                
                Spacer()
                
                Text("\(Int(waterIntake / 8)) / 8 cups")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
            }
            
            // Water Cups Visual
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(0..<8) { index in
                    WaterCupButton(
                        index: index,
                        isFilled: Double(index) < (waterIntake / 8)
                    ) {
                        addWaterCup()
                    }
                }
            }
            
            Button("Add Custom Amount") {
                // Show water entry sheet
            }
            .font(.subheadline)
            .foregroundColor(theme.primaryColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(theme.primaryColor.opacity(0.1))
            .cornerRadius(8)
        }
        .padding()
        .background(theme.surfaceColor)
        .cornerRadius(16)
    }
    
    // MARK: - Meals Section
    private var mealsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Meals")
                .font(.headline)
                .foregroundColor(theme.textPrimary)
            
            VStack(spacing: 12) {
                ForEach(MealEntry.MealType.allCases, id: \.self) { mealType in
                    MealCard(
                        mealType: mealType,
                        entries: getMealsForType(mealType),
                        onTap: {
                            selectedMealType = mealType
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Quick Add Section
    private var quickAddSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Add")
                .font(.headline)
                .foregroundColor(theme.textPrimary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                QuickAddButton(
                    title: "Search Foods",
                    icon: "magnifyingglass",
                    color: .blue
                ) {
                    showingFoodSearch = true
                }
                
                QuickAddButton(
                    title: "Scan Barcode",
                    icon: "barcode.viewfinder",
                    color: .green
                ) {
                    // Implement barcode scanning
                }
                
                QuickAddButton(
                    title: "Recent Foods",
                    icon: "clock",
                    color: .orange
                ) {
                    // Show recent foods
                }
                
                QuickAddButton(
                    title: "My Recipes",
                    icon: "book.fill",
                    color: .purple
                ) {
                    // Show recipes
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    private func getWeekDays() -> [Date] {
        let today = Date()
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        
        return (0..<7).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek)
        }
    }
    
    private func hasNutritionData(for date: Date) -> Bool {
        return dataManager.mealEntries.contains { 
            calendar.isDate($0.consumedAt, inSameDayAs: date)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            formatter.dateFormat = "EEEE, MMM d"
            return formatter.string(from: date)
        }
    }
    
    private var calorieProgress: Double {
        return todaysCalories / dataManager.dashboardStats.calorieGoal
    }
    
    private var calorieProgressColor: Color {
        if calorieProgress < 0.8 { return .red }
        else if calorieProgress < 1.0 { return .orange }
        else if calorieProgress < 1.2 { return .green }
        else { return .red }
    }
    
    private func getMealsForType(_ mealType: MealEntry.MealType) -> [MealEntry] {
        return todaysMeals.filter { $0.mealType == mealType }
    }
    
    private func addWaterCup() {
        dataManager.logWater(amount: 8, date: selectedDate) // 8 oz per cup
    }
}

// MARK: - Supporting Views

struct DateSelectorButton: View {
    let date: Date
    let isSelected: Bool
    let hasData: Bool
    let action: () -> Void
    
    @Environment(\.theme) private var theme
    
    private var dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter
    }()
    
    private var numberFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }()
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(dayFormatter.string(from: date))
                    .font(.caption)
                    .foregroundColor(isSelected ? .white : theme.textSecondary)
                
                Text(numberFormatter.string(from: date))
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : theme.textPrimary)
                
                Circle()
                    .fill(hasData ? theme.primaryColor : Color.clear)
                    .frame(width: 4, height: 4)
            }
            .frame(width: 50, height: 70)
            .background(isSelected ? theme.primaryColor : Color.clear)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct NutritionStatItem: View {
    let title: String
    let current: Double
    let goal: Double
    let unit: String
    let color: Color
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(theme.textSecondary)
            
            VStack(spacing: 2) {
                Text("\(Int(current))")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(theme.textPrimary)
                
                Text("/ \(Int(goal)) \(unit)")
                    .font(.caption2)
                    .foregroundColor(theme.textTertiary)
            }
            
            ProgressView(value: current / goal)
                .progressViewStyle(LinearProgressViewStyle(tint: color))
                .scaleEffect(x: 1, y: 0.8, anchor: .center)
        }
        .frame(maxWidth: .infinity)
    }
}

struct MacroPieChart: View {
    let protein: Double
    let carbs: Double
    let fat: Double
    
    private var totalCalories: Double {
        protein * 4 + carbs * 4 + fat * 9
    }
    
    private var proteinPercentage: Double {
        guard totalCalories > 0 else { return 0 }
        return (protein * 4) / totalCalories
    }
    
    private var carbsPercentage: Double {
        guard totalCalories > 0 else { return 0 }
        return (carbs * 4) / totalCalories
    }
    
    private var fatPercentage: Double {
        guard totalCalories > 0 else { return 0 }
        return (fat * 9) / totalCalories
    }
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.purple.opacity(0.3))
            
            Circle()
                .trim(from: 0, to: fatPercentage)
                .stroke(Color.purple, lineWidth: 20)
                .rotationEffect(.degrees(-90))
            
            Circle()
                .trim(from: fatPercentage, to: fatPercentage + carbsPercentage)
                .stroke(Color.orange, lineWidth: 20)
                .rotationEffect(.degrees(-90))
            
            Circle()
                .trim(from: fatPercentage + carbsPercentage, to: 1.0)
                .stroke(Color.blue, lineWidth: 20)
                .rotationEffect(.degrees(-90))
        }
    }
}

struct MacroLegendItem: View {
    let color: Color
    let title: String
    let grams: Double
    let percentage: Double
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            
            Text(title)
                .font(.caption)
                .foregroundColor(theme.textPrimary)
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(grams))g")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(theme.textPrimary)
                
                Text("\(Int(percentage))%")
                    .font(.caption2)
                    .foregroundColor(theme.textSecondary)
            }
        }
    }
}

struct WaterCupButton: View {
    let index: Int
    let isFilled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: isFilled ? "drop.fill" : "drop")
                .font(.title2)
                .foregroundColor(isFilled ? .blue : .gray)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct MealCard: View {
    let mealType: MealEntry.MealType
    let entries: [MealEntry]
    let onTap: () -> Void
    
    @Environment(\.theme) private var theme
    
    private var totalCalories: Double {
        entries.reduce(0) { $0 + $1.nutritionFacts.calories }
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: mealType.icon)
                            .font(.title3)
                            .foregroundColor(mealType.color)
                        
                        Text(mealType.rawValue)
                            .font(.headline)
                            .fontWeight(.medium)
                            .foregroundColor(theme.textPrimary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(Int(totalCalories)) cal")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(theme.primaryColor)
                        
                        if entries.isEmpty {
                            Text("No items")
                                .font(.caption)
                                .foregroundColor(theme.textTertiary)
                        } else {
                            Text("\(entries.count) item\(entries.count == 1 ? "" : "s")")
                                .font(.caption)
                                .foregroundColor(theme.textSecondary)
                        }
                    }
                }
                
                if !entries.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(Array(entries.prefix(3)), id: \.id) { entry in
                            HStack {
                                Text("• \(entry.foodName)")
                                    .font(.caption)
                                    .foregroundColor(theme.textSecondary)
                                    .lineLimit(1)
                                
                                Spacer()
                                
                                Text("\(Int(entry.nutritionFacts.calories)) cal")
                                    .font(.caption)
                                    .foregroundColor(theme.textTertiary)
                            }
                        }
                        
                        if entries.count > 3 {
                            Text("and \(entries.count - 3) more...")
                                .font(.caption2)
                                .foregroundColor(theme.textTertiary)
                        }
                    }
                }
            }
            .padding()
            .background(theme.surfaceColor)
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct QuickAddButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(theme.textPrimary)
                    .multilineTextAlignment(.center)
            }
            .frame(height: 80)
            .frame(maxWidth: .infinity)
            .background(theme.surfaceColor)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    CompleteNutritionView()
        .environmentObject(FitnessDataManager.shared)
        .environmentObject(ThemeManager())
        .theme(FitnessTheme())
}