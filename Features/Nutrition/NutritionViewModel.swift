import Foundation
import Combine
import SwiftUI

@MainActor
public class NutritionViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published public var selectedDate = Date()
    @Published public var nutritionEntries: [NutritionEntryModel] = []
    @Published public var commonFoods: [CommonFood] = []
    @Published public var waterIntake: Double = 0
    @Published public var isLoading = false
    @Published public var errorMessage: String?
    
    // Navigation states
    @Published public var showFoodSearch = false
    @Published public var showFoodDatabase = false
    @Published public var showMealPlanner = false
    @Published public var showMacroCalculator = false
    @Published public var showRecipeBuilder = false
    @Published public var selectedMealType: MealType = .breakfast
    
    // Goals
    @Published public var calorieGoal: Double = 2200
    @Published public var proteinGoal: Double = 140
    @Published public var carbsGoal: Double = 275
    @Published public var fatGoal: Double = 73
    @Published public var waterGoal: Double = 8
    
    // MARK: - Computed Properties
    
    public var totalCalories: Double {
        nutritionEntries.reduce(0) { $0 + $1.calories }
    }
    
    public var totalProtein: Double {
        nutritionEntries.reduce(0) { $0 + $1.protein }
    }
    
    public var totalCarbs: Double {
        nutritionEntries.reduce(0) { $0 + $1.carbs }
    }
    
    public var totalFat: Double {
        nutritionEntries.reduce(0) { $0 + $1.fat }
    }
    
    public var calorieProgress: Double {
        guard calorieGoal > 0 else { return 0 }
        return totalCalories / calorieGoal
    }
    
    public var canGoToNextDay: Bool {
        !Calendar.current.isDateInToday(selectedDate)
    }
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    public init() {
        loadCommonFoods()
        setupObservers()
    }
    
    // MARK: - Public Methods
    
    public func loadData() async {
        isLoading = true
        defer { isLoading = false }
        
        // Load nutrition entries for selected date
        await loadNutritionEntries()
        
        // Load water intake
        loadWaterIntake()
        
        // Load user goals
        loadUserGoals()
    }
    
    public func refresh() async {
        await loadData()
    }
    
    public func previousDay() {
        selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
        Task {
            await loadData()
        }
    }
    
    public func nextDay() {
        guard canGoToNextDay else { return }
        selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
        Task {
            await loadData()
        }
    }
    
    public func entriesForMeal(_ mealType: MealType) -> [NutritionEntryModel] {
        nutritionEntries.filter { $0.mealType == mealType }
    }
    
    public func caloriesForMeal(_ mealType: MealType) -> Double {
        entriesForMeal(mealType).reduce(0) { $0 + $1.calories }
    }
    
    public func addFoodEntry(food: FoodModel, quantity: Double, mealType: MealType) {
        let multiplier = quantity / food.servingSize
        
        let entry = NutritionEntryModel(
            foodName: food.name,
            brand: food.brand,
            quantity: quantity,
            unit: food.servingUnit,
            calories: food.caloriesPerServing * multiplier,
            protein: food.proteinPerServing * multiplier,
            carbs: food.carbsPerServing * multiplier,
            fat: food.fatPerServing * multiplier,
            fiber: food.fiberPerServing != nil ? food.fiberPerServing! * multiplier : nil,
            sugar: food.sugarPerServing != nil ? food.sugarPerServing! * multiplier : nil,
            sodium: food.sodiumPerServing != nil ? food.sodiumPerServing! * multiplier : nil,
            mealType: mealType,
            date: selectedDate
        )
        
        nutritionEntries.append(entry)
        saveNutritionEntry(entry)
    }
    
    public func editEntry(_ entry: NutritionEntryModel) {
        // Open edit sheet for the entry
        // This would typically show a modal to edit quantity
    }
    
    public func deleteEntry(_ entry: NutritionEntryModel) {
        nutritionEntries.removeAll { $0.id == entry.id }
        deleteNutritionEntry(entry)
    }
    
    public func quickAddFood(_ food: CommonFood) {
        let entry = NutritionEntryModel(
            foodName: food.name,
            quantity: 1,
            unit: food.servingSize,
            calories: food.calories,
            protein: food.protein,
            carbs: food.carbs,
            fat: food.fat,
            mealType: selectedMealType,
            date: selectedDate
        )
        
        nutritionEntries.append(entry)
        saveNutritionEntry(entry)
    }
    
    public func toggleWaterCup(_ index: Int) {
        if index < Int(waterIntake) {
            waterIntake = Double(index)
        } else {
            waterIntake = Double(index + 1)
        }
        saveWaterIntake()
    }
    
    public func addWaterCup() {
        waterIntake = min(waterIntake + 1, 16)
        saveWaterIntake()
    }
    
    public func removeWaterCup() {
        waterIntake = max(waterIntake - 1, 0)
        saveWaterIntake()
    }
    
    // MARK: - Private Methods
    
    private func setupObservers() {
        // Observe date changes
        $selectedDate
            .sink { [weak self] _ in
                Task {
                    await self?.loadData()
                }
            }
            .store(in: &cancellables)
    }
    
    private func loadNutritionEntries() async {
        // Simulate loading from Core Data/API
        // In real app, this would fetch from CoreDataManager
        
        // Sample data for demonstration
        if Calendar.current.isDateInToday(selectedDate) {
            nutritionEntries = [
                NutritionEntryModel(
                    foodName: "Oatmeal",
                    quantity: 1,
                    unit: "cup",
                    calories: 150,
                    protein: 5,
                    carbs: 27,
                    fat: 3,
                    fiber: 4,
                    mealType: .breakfast,
                    date: selectedDate
                ),
                NutritionEntryModel(
                    foodName: "Banana",
                    quantity: 1,
                    unit: "medium",
                    calories: 105,
                    protein: 1.3,
                    carbs: 27,
                    fat: 0.4,
                    fiber: 3.1,
                    mealType: .breakfast,
                    date: selectedDate
                ),
                NutritionEntryModel(
                    foodName: "Grilled Chicken Breast",
                    quantity: 6,
                    unit: "oz",
                    calories: 276,
                    protein: 51,
                    carbs: 0,
                    fat: 6,
                    mealType: .lunch,
                    date: selectedDate
                )
            ]
        } else {
            nutritionEntries = []
        }
    }
    
    private func loadWaterIntake() {
        // Load from UserDefaults or Core Data
        waterIntake = UserDefaults.standard.double(forKey: "waterIntake_\(dateKey)")
        if waterIntake == 0 && Calendar.current.isDateInToday(selectedDate) {
            waterIntake = 3 // Default starting value
        }
    }
    
    private func saveWaterIntake() {
        UserDefaults.standard.set(waterIntake, forKey: "waterIntake_\(dateKey)")
    }
    
    private func loadUserGoals() {
        // Load from user profile or settings
        // These would typically come from the user's profile
        calorieGoal = UserDefaults.standard.double(forKey: "calorieGoal")
        if calorieGoal == 0 {
            calorieGoal = 2200 // Default
        }
        
        proteinGoal = UserDefaults.standard.double(forKey: "proteinGoal")
        if proteinGoal == 0 {
            proteinGoal = 140 // Default
        }
        
        carbsGoal = UserDefaults.standard.double(forKey: "carbsGoal")
        if carbsGoal == 0 {
            carbsGoal = 275 // Default
        }
        
        fatGoal = UserDefaults.standard.double(forKey: "fatGoal")
        if fatGoal == 0 {
            fatGoal = 73 // Default
        }
        
        waterGoal = UserDefaults.standard.double(forKey: "waterGoal")
        if waterGoal == 0 {
            waterGoal = 8 // Default
        }
    }
    
    private func loadCommonFoods() {
        // Load user's common foods or defaults
        commonFoods = [
            CommonFood(
                name: "Apple",
                calories: 95,
                protein: 0.5,
                carbs: 25,
                fat: 0.3,
                servingSize: "1 medium"
            ),
            CommonFood(
                name: "Protein Bar",
                calories: 200,
                protein: 20,
                carbs: 22,
                fat: 7,
                servingSize: "1 bar"
            ),
            CommonFood(
                name: "Greek Yogurt",
                calories: 100,
                protein: 17,
                carbs: 6,
                fat: 0.7,
                servingSize: "1 cup"
            ),
            CommonFood(
                name: "Almonds",
                calories: 164,
                protein: 6,
                carbs: 6,
                fat: 14,
                servingSize: "1 oz"
            ),
            CommonFood(
                name: "Protein Shake",
                calories: 160,
                protein: 30,
                carbs: 8,
                fat: 3,
                servingSize: "1 scoop"
            )
        ]
    }
    
    private func saveNutritionEntry(_ entry: NutritionEntryModel) {
        // Save to Core Data
        // In real app, this would use CoreDataManager
    }
    
    private func deleteNutritionEntry(_ entry: NutritionEntryModel) {
        // Delete from Core Data
        // In real app, this would use CoreDataManager
    }
    
    private var dateKey: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy_MM_dd"
        return formatter.string(from: selectedDate)
    }
}

// MARK: - Placeholder Views (These would be separate files in a real app)

public struct FoodSearchView: View {
    let onSelect: (FoodModel, Double) -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    
    public var body: some View {
        NavigationView {
            Text("Food Search View")
                .navigationTitle("Search Foods")
                .navigationBarItems(trailing: Button("Cancel") { dismiss() })
        }
    }
}

public struct FoodDatabaseView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    
    public var body: some View {
        NavigationView {
            Text("Food Database View")
                .navigationTitle("Food Database")
                .navigationBarItems(trailing: Button("Done") { dismiss() })
        }
    }
}

public struct MealPlannerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    
    public var body: some View {
        NavigationView {
            Text("Meal Planner View")
                .navigationTitle("Meal Planner")
                .navigationBarItems(trailing: Button("Done") { dismiss() })
        }
    }
}

public struct MacroCalculatorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    
    public var body: some View {
        NavigationView {
            Text("Macro Calculator View")
                .navigationTitle("Macro Calculator")
                .navigationBarItems(trailing: Button("Done") { dismiss() })
        }
    }
}

public struct RecipeBuilderView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    
    public var body: some View {
        NavigationView {
            Text("Recipe Builder View")
                .navigationTitle("Recipe Builder")
                .navigationBarItems(trailing: Button("Done") { dismiss() })
        }
    }
}