import SwiftUI

// MARK: - Food Search View
struct FoodSearchView: View {
    let selectedDate: Date
    
    @EnvironmentObject private var dataManager: FitnessDataManager
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.theme) private var theme
    
    @State private var searchText = ""
    @State private var selectedCategory: Food.FoodCategory?
    @State private var showingFilters = false
    @State private var selectedFood: Food?
    @State private var selectedMealType: MealEntry.MealType = .breakfast
    
    var filteredFoods: [Food] {
        dataManager.searchFoods(searchText, category: selectedCategory)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Meal Type Selector
                mealTypeSelector
                
                // Search Bar
                searchBar
                
                // Category Filter
                if selectedCategory != nil {
                    activeFiltersBar
                }
                
                // Foods List
                if filteredFoods.isEmpty {
                    emptySearchState
                } else {
                    foodsList
                }
            }
            .navigationTitle("Add Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Filter") {
                        showingFilters = true
                    }
                }
            }
        }
        .sheet(isPresented: $showingFilters) {
            FoodFiltersSheet(selectedCategory: $selectedCategory)
        }
        .sheet(item: $selectedFood) { food in
            FoodDetailSheet(
                food: food,
                mealType: selectedMealType,
                date: selectedDate
            )
        }
    }
    
    private var mealTypeSelector: some View {
        Picker("Meal Type", selection: $selectedMealType) {
            ForEach(MealEntry.MealType.allCases, id: \.self) { mealType in
                Text(mealType.rawValue).tag(mealType)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding()
        .background(theme.backgroundColor)
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(theme.textTertiary)
            
            TextField("Search foods...", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
                .submitLabel(.search)
        }
        .padding()
        .background(theme.surfaceColor)
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private var activeFiltersBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if let category = selectedCategory {
                    FilterChip(title: category.rawValue) {
                        selectedCategory = nil
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
    
    private var foodsList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(filteredFoods, id: \.id) { food in
                    FoodSearchResultCard(food: food) {
                        selectedFood = food
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
    }
    
    private var emptySearchState: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(theme.textTertiary)
            
            Text("No Foods Found")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(theme.textPrimary)
            
            Text(searchText.isEmpty ? "Start typing to search foods" : "Try a different search term")
                .font(.subheadline)
                .foregroundColor(theme.textSecondary)
                .multilineTextAlignment(.center)
            
            if !searchText.isEmpty {
                Button("Clear Search") {
                    searchText = ""
                    selectedCategory = nil
                }
                .font(.subheadline)
                .foregroundColor(theme.primaryColor)
                .padding()
                .background(theme.primaryColor.opacity(0.1))
                .cornerRadius(12)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct FoodSearchResultCard: View {
    let food: Food
    let action: () -> Void
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Food Category Icon
                RoundedRectangle(cornerRadius: 8)
                    .fill(categoryColor.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: categoryIcon)
                            .foregroundColor(categoryColor)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(food.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(theme.textPrimary)
                        .multilineTextAlignment(.leading)
                    
                    HStack(spacing: 8) {
                        if let brand = food.brand {
                            Text(brand)
                                .font(.caption)
                                .foregroundColor(theme.textSecondary)
                        }
                        
                        if food.isVerified {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    Text("\(Int(food.nutritionPer100g.calories)) cal per 100g")
                        .font(.caption)
                        .foregroundColor(theme.textTertiary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(food.nutritionPer100g.protein))g")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                    
                    Text("protein")
                        .font(.caption2)
                        .foregroundColor(theme.textTertiary)
                }
                
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(theme.primaryColor)
            }
            .padding()
            .background(theme.surfaceColor)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var categoryColor: Color {
        switch food.category {
        case .meat, .fish: return .red
        case .vegetables: return .green
        case .fruits: return .orange
        case .grains: return .brown
        case .dairy: return .blue
        case .nuts: return .purple
        default: return .gray
        }
    }
    
    private var categoryIcon: String {
        switch food.category {
        case .meat: return "fork.knife"
        case .fish: return "fish"
        case .vegetables: return "leaf"
        case .fruits: return "applelogo"
        case .grains: return "grain"
        case .dairy: return "drop"
        case .nuts: return "circle"
        case .beverages: return "cup.and.saucer"
        case .snacks: return "star"
        case .condiments: return "drop.triangle"
        case .supplements: return "pills"
        }
    }
}

// MARK: - Food Filters Sheet
struct FoodFiltersSheet: View {
    @Binding var selectedCategory: Food.FoodCategory?
    
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.theme) private var theme
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Food Category")
                            .font(.headline)
                            .foregroundColor(theme.textPrimary)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            ForEach(Food.FoodCategory.allCases, id: \.self) { category in
                                CategoryFilterButton(
                                    category: category,
                                    isSelected: selectedCategory == category
                                ) {
                                    selectedCategory = selectedCategory == category ? nil : category
                                }
                            }
                        }
                    }
                    
                    Button("Clear All Filters") {
                        selectedCategory = nil
                    }
                    .font(.subheadline)
                    .foregroundColor(theme.primaryColor)
                    .padding()
                    .background(theme.primaryColor.opacity(0.1))
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

struct CategoryFilterButton: View {
    let category: Food.FoodCategory
    let isSelected: Bool
    let action: () -> Void
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        Button(action: action) {
            Text(category.rawValue)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : theme.textPrimary)
                .frame(maxWidth: .infinity)
                .padding()
                .background(isSelected ? theme.primaryColor : theme.surfaceColor)
                .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Food Detail Sheet
struct FoodDetailSheet: View {
    let food: Food
    let mealType: MealEntry.MealType
    let date: Date
    
    @EnvironmentObject private var dataManager: FitnessDataManager
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.theme) private var theme
    
    @State private var quantity: String = "100"
    @State private var notes: String = ""
    
    private var quantityDouble: Double {
        Double(quantity) ?? 100
    }
    
    private var adjustedNutrition: NutritionFacts {
        let multiplier = quantityDouble / 100.0
        let nutrition = food.nutritionPer100g
        return NutritionFacts(
            calories: nutrition.calories * multiplier,
            protein: nutrition.protein * multiplier,
            carbs: nutrition.carbs * multiplier,
            fat: nutrition.fat * multiplier,
            fiber: nutrition.fiber * multiplier,
            sugar: nutrition.sugar * multiplier,
            sodium: nutrition.sodium * multiplier,
            cholesterol: nutrition.cholesterol * multiplier,
            vitaminA: nutrition.vitaminA.map { $0 * multiplier },
            vitaminC: nutrition.vitaminC.map { $0 * multiplier },
            calcium: nutrition.calcium.map { $0 * multiplier },
            iron: nutrition.iron.map { $0 * multiplier }
        )
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Food Header
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(food.name)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(theme.textPrimary)
                                
                                if let brand = food.brand {
                                    Text(brand)
                                        .font(.subheadline)
                                        .foregroundColor(theme.textSecondary)
                                }
                                
                                HStack(spacing: 8) {
                                    Text(food.category.rawValue)
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(theme.primaryColor.opacity(0.1))
                                        .cornerRadius(8)
                                    
                                    if food.isVerified {
                                        HStack(spacing: 2) {
                                            Image(systemName: "checkmark.seal.fill")
                                                .font(.caption)
                                            Text("Verified")
                                                .font(.caption)
                                        }
                                        .foregroundColor(.blue)
                                    }
                                }
                            }
                            
                            Spacer()
                        }
                    }
                    
                    // Quantity Input
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Quantity")
                            .font(.headline)
                            .foregroundColor(theme.textPrimary)
                        
                        HStack {
                            TextField("Quantity", text: $quantity)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(width: 100)
                            
                            Text("grams")
                                .font(.subheadline)
                                .foregroundColor(theme.textSecondary)
                            
                            Spacer()
                            
                            // Quick quantity buttons
                            HStack(spacing: 8) {
                                ForEach([50, 100, 150, 200], id: \.self) { amount in
                                    Button("\(amount)g") {
                                        quantity = "\(amount)"
                                    }
                                    .font(.caption)
                                    .foregroundColor(quantity == "\(amount)" ? .white : theme.primaryColor)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(quantity == "\(amount)" ? theme.primaryColor : theme.primaryColor.opacity(0.1))
                                    .cornerRadius(8)
                                }
                            }
                        }
                    }
                    
                    // Nutrition Facts
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Nutrition Facts")
                            .font(.headline)
                            .foregroundColor(theme.textPrimary)
                        
                        VStack(spacing: 0) {
                            // Calories (prominent)
                            HStack {
                                Text("Calories")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(theme.textPrimary)
                                
                                Spacer()
                                
                                Text("\(Int(adjustedNutrition.calories))")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(theme.primaryColor)
                            }
                            .padding()
                            .background(theme.surfaceColor)
                            .cornerRadius(12)
                            
                            Divider()
                                .padding(.vertical, 8)
                            
                            // Macros
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 12) {
                                NutritionFactRow(
                                    title: "Protein",
                                    value: adjustedNutrition.protein,
                                    unit: "g",
                                    color: .blue
                                )
                                
                                NutritionFactRow(
                                    title: "Carbs",
                                    value: adjustedNutrition.carbs,
                                    unit: "g",
                                    color: .orange
                                )
                                
                                NutritionFactRow(
                                    title: "Fat",
                                    value: adjustedNutrition.fat,
                                    unit: "g",
                                    color: .purple
                                )
                                
                                NutritionFactRow(
                                    title: "Fiber",
                                    value: adjustedNutrition.fiber,
                                    unit: "g",
                                    color: .green
                                )
                                
                                if adjustedNutrition.sugar > 0 {
                                    NutritionFactRow(
                                        title: "Sugar",
                                        value: adjustedNutrition.sugar,
                                        unit: "g",
                                        color: .red
                                    )
                                }
                                
                                if adjustedNutrition.sodium > 0 {
                                    NutritionFactRow(
                                        title: "Sodium",
                                        value: adjustedNutrition.sodium,
                                        unit: "mg",
                                        color: .yellow
                                    )
                                }
                            }
                        }
                        .padding()
                        .background(theme.surfaceColor)
                        .cornerRadius(16)
                    }
                    
                    // Notes
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes (optional)")
                            .font(.headline)
                            .foregroundColor(theme.textPrimary)
                        
                        TextField("Add any notes about this food...", text: $notes)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    // Add Button
                    Button("Add to \(mealType.rawValue)") {
                        dataManager.logMeal(food, quantity: quantityDouble, mealType: mealType, date: date)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(quantity.isEmpty ? Color.gray : theme.primaryColor)
                    .cornerRadius(12)
                    .disabled(quantity.isEmpty)
                }
                .padding()
            }
            .navigationTitle("Food Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

struct NutritionFactRow: View {
    let title: String
    let value: Double
    let unit: String
    let color: Color
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(theme.textSecondary)
            
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(String(format: "%.1f", value))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.textPrimary)
                
                Text(unit)
                    .font(.caption)
                    .foregroundColor(theme.textTertiary)
            }
            
            Rectangle()
                .fill(color.opacity(0.3))
                .frame(height: 2)
                .cornerRadius(1)
        }
        .padding(8)
        .background(color.opacity(0.05))
        .cornerRadius(8)
    }
}

// MARK: - Meal Detail View
struct MealDetailView: View {
    let mealType: MealEntry.MealType
    let date: Date
    
    @EnvironmentObject private var dataManager: FitnessDataManager
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.theme) private var theme
    
    @State private var showingFoodSearch = false
    
    private var mealEntries: [MealEntry] {
        dataManager.mealEntries.filter { entry in
            entry.mealType == mealType &&
            Calendar.current.isDate(entry.consumedAt, inSameDayAs: date)
        }
    }
    
    private var totalCalories: Double {
        mealEntries.reduce(0) { $0 + $1.nutritionFacts.calories }
    }
    
    private var totalProtein: Double {
        mealEntries.reduce(0) { $0 + $1.nutritionFacts.protein }
    }
    
    private var totalCarbs: Double {
        mealEntries.reduce(0) { $0 + $1.nutritionFacts.carbs }
    }
    
    private var totalFat: Double {
        mealEntries.reduce(0) { $0 + $1.nutritionFacts.fat }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Summary Header
                if !mealEntries.isEmpty {
                    mealSummaryHeader
                }
                
                // Food List
                if mealEntries.isEmpty {
                    emptyMealState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(mealEntries, id: \.id) { entry in
                                MealEntryCard(entry: entry) {
                                    // Handle delete
                                    deleteMealEntry(entry)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle(mealType.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add Food") {
                        showingFoodSearch = true
                    }
                }
            }
        }
        .sheet(isPresented: $showingFoodSearch) {
            FoodSearchView(selectedDate: date)
        }
    }
    
    private var mealSummaryHeader: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Total: \(Int(totalCalories)) calories")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(theme.primaryColor)
                
                Spacer()
                
                Text("\(mealEntries.count) item\(mealEntries.count == 1 ? "" : "s")")
                    .font(.subheadline)
                    .foregroundColor(theme.textSecondary)
            }
            
            HStack(spacing: 20) {
                MacroSummaryItem(title: "Protein", value: totalProtein, unit: "g", color: .blue)
                MacroSummaryItem(title: "Carbs", value: totalCarbs, unit: "g", color: .orange)
                MacroSummaryItem(title: "Fat", value: totalFat, unit: "g", color: .purple)
            }
        }
        .padding()
        .background(theme.surfaceColor)
    }
    
    private var emptyMealState: some View {
        VStack(spacing: 20) {
            Image(systemName: mealType.icon)
                .font(.system(size: 60))
                .foregroundColor(mealType.color.opacity(0.5))
            
            VStack(spacing: 8) {
                Text("No \(mealType.rawValue) Logged")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(theme.textPrimary)
                
                Text("Add your first food to start tracking this meal")
                    .font(.subheadline)
                    .foregroundColor(theme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("Add Food") {
                showingFoodSearch = true
            }
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .background(mealType.color)
            .cornerRadius(12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private func deleteMealEntry(_ entry: MealEntry) {
        if let index = dataManager.mealEntries.firstIndex(where: { $0.id == entry.id }) {
            dataManager.mealEntries.remove(at: index)
        }
    }
}

struct MacroSummaryItem: View {
    let title: String
    let value: Double
    let unit: String
    let color: Color
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(theme.textSecondary)
            
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(String(format: "%.0f", value))
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(theme.textPrimary)
                
                Text(unit)
                    .font(.caption2)
                    .foregroundColor(theme.textTertiary)
            }
            
            Rectangle()
                .fill(color)
                .frame(height: 2)
                .cornerRadius(1)
        }
        .frame(maxWidth: .infinity)
    }
}

struct MealEntryCard: View {
    let entry: MealEntry
    let onDelete: () -> Void
    
    @Environment(\.theme) private var theme
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.foodName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(theme.textPrimary)
                
                Text("\(Int(entry.quantity))g")
                    .font(.caption)
                    .foregroundColor(theme.textSecondary)
                
                HStack(spacing: 12) {
                    Text("P: \(Int(entry.nutritionFacts.protein))g")
                        .font(.caption2)
                        .foregroundColor(.blue)
                    
                    Text("C: \(Int(entry.nutritionFacts.carbs))g")
                        .font(.caption2)
                        .foregroundColor(.orange)
                    
                    Text("F: \(Int(entry.nutritionFacts.fat))g")
                        .font(.caption2)
                        .foregroundColor(.purple)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(entry.nutritionFacts.calories))")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(theme.primaryColor)
                
                Text("calories")
                    .font(.caption2)
                    .foregroundColor(theme.textSecondary)
            }
            
            Button {
                showingDeleteConfirmation = true
            } label: {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundColor(.red)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
        .background(theme.surfaceColor)
        .cornerRadius(12)
        .confirmationDialog(
            "Remove \(entry.foodName)?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Remove", role: .destructive) {
                onDelete()
            }
            Button("Cancel", role: .cancel) { }
        }
    }
}

// MARK: - Meal Planner View
struct MealPlannerView: View {
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.theme) private var theme
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Meal Planner")
                    .font(.title)
                    .padding()
                
                Text("Coming Soon!")
                    .font(.headline)
                    .foregroundColor(theme.textSecondary)
                
                Spacer()
            }
            .navigationTitle("Meal Planner")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    FoodSearchView(selectedDate: Date())
        .environmentObject(FitnessDataManager.shared)
        .environmentObject(ThemeManager())
        .theme(FitnessTheme())
}