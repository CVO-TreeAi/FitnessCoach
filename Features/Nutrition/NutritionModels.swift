import Foundation
import SwiftUI

// MARK: - Nutrition Entry Model
public struct NutritionEntryModel: Identifiable {
    public let id: String
    public let foodName: String
    public let brand: String?
    public let quantity: Double
    public let unit: String
    public let calories: Double
    public let protein: Double
    public let carbs: Double
    public let fat: Double
    public let fiber: Double?
    public let sugar: Double?
    public let sodium: Double?
    public let mealType: MealType
    public let date: Date
    public let notes: String?
    
    public init(
        id: String = UUID().uuidString,
        foodName: String,
        brand: String? = nil,
        quantity: Double,
        unit: String,
        calories: Double,
        protein: Double,
        carbs: Double,
        fat: Double,
        fiber: Double? = nil,
        sugar: Double? = nil,
        sodium: Double? = nil,
        mealType: MealType,
        date: Date = Date(),
        notes: String? = nil
    ) {
        self.id = id
        self.foodName = foodName
        self.brand = brand
        self.quantity = quantity
        self.unit = unit
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.fiber = fiber
        self.sugar = sugar
        self.sodium = sodium
        self.mealType = mealType
        self.date = date
        self.notes = notes
    }
}

// MARK: - Food Model
public struct FoodModel: Identifiable {
    public let id: String
    public let name: String
    public let brand: String?
    public let barcode: String?
    public let servingSize: Double
    public let servingUnit: String
    public let caloriesPerServing: Double
    public let proteinPerServing: Double
    public let carbsPerServing: Double
    public let fatPerServing: Double
    public let fiberPerServing: Double?
    public let sugarPerServing: Double?
    public let sodiumPerServing: Double?
    public let category: FoodCategory
    public let isCustom: Bool
    public let isFavorite: Bool
    
    public init(
        id: String = UUID().uuidString,
        name: String,
        brand: String? = nil,
        barcode: String? = nil,
        servingSize: Double,
        servingUnit: String,
        caloriesPerServing: Double,
        proteinPerServing: Double,
        carbsPerServing: Double,
        fatPerServing: Double,
        fiberPerServing: Double? = nil,
        sugarPerServing: Double? = nil,
        sodiumPerServing: Double? = nil,
        category: FoodCategory = .other,
        isCustom: Bool = false,
        isFavorite: Bool = false
    ) {
        self.id = id
        self.name = name
        self.brand = brand
        self.barcode = barcode
        self.servingSize = servingSize
        self.servingUnit = servingUnit
        self.caloriesPerServing = caloriesPerServing
        self.proteinPerServing = proteinPerServing
        self.carbsPerServing = carbsPerServing
        self.fatPerServing = fatPerServing
        self.fiberPerServing = fiberPerServing
        self.sugarPerServing = sugarPerServing
        self.sodiumPerServing = sodiumPerServing
        self.category = category
        self.isCustom = isCustom
        self.isFavorite = isFavorite
    }
}

// MARK: - Common Food (for quick add)
public struct CommonFood: Identifiable {
    public let id: String
    public let name: String
    public let calories: Double
    public let protein: Double
    public let carbs: Double
    public let fat: Double
    public let servingSize: String
    
    public init(
        id: String = UUID().uuidString,
        name: String,
        calories: Double,
        protein: Double,
        carbs: Double,
        fat: Double,
        servingSize: String
    ) {
        self.id = id
        self.name = name
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.servingSize = servingSize
    }
}

// MARK: - Recipe Model
public struct RecipeModel: Identifiable {
    public let id: String
    public let name: String
    public let description: String?
    public let ingredients: [RecipeIngredient]
    public let instructions: [String]
    public let servings: Int
    public let prepTime: Int // minutes
    public let cookTime: Int // minutes
    public let category: RecipeCategory
    public let tags: [String]
    public let imageUrl: String?
    public let nutritionPerServing: NutritionInfo
    public let createdBy: String?
    public let isFavorite: Bool
    
    public init(
        id: String = UUID().uuidString,
        name: String,
        description: String? = nil,
        ingredients: [RecipeIngredient],
        instructions: [String],
        servings: Int,
        prepTime: Int,
        cookTime: Int,
        category: RecipeCategory,
        tags: [String] = [],
        imageUrl: String? = nil,
        nutritionPerServing: NutritionInfo,
        createdBy: String? = nil,
        isFavorite: Bool = false
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.ingredients = ingredients
        self.instructions = instructions
        self.servings = servings
        self.prepTime = prepTime
        self.cookTime = cookTime
        self.category = category
        self.tags = tags
        self.imageUrl = imageUrl
        self.nutritionPerServing = nutritionPerServing
        self.createdBy = createdBy
        self.isFavorite = isFavorite
    }
}

// MARK: - Recipe Ingredient
public struct RecipeIngredient: Identifiable {
    public let id: String
    public let foodId: String
    public let foodName: String
    public let quantity: Double
    public let unit: String
    public let notes: String?
    
    public init(
        id: String = UUID().uuidString,
        foodId: String,
        foodName: String,
        quantity: Double,
        unit: String,
        notes: String? = nil
    ) {
        self.id = id
        self.foodId = foodId
        self.foodName = foodName
        self.quantity = quantity
        self.unit = unit
        self.notes = notes
    }
}

// MARK: - Nutrition Info
public struct NutritionInfo {
    public let calories: Double
    public let protein: Double
    public let carbs: Double
    public let fat: Double
    public let fiber: Double?
    public let sugar: Double?
    public let sodium: Double?
    
    public init(
        calories: Double,
        protein: Double,
        carbs: Double,
        fat: Double,
        fiber: Double? = nil,
        sugar: Double? = nil,
        sodium: Double? = nil
    ) {
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.fiber = fiber
        self.sugar = sugar
        self.sodium = sodium
    }
}

// MARK: - Meal Plan
public struct MealPlan: Identifiable {
    public let id: String
    public let name: String
    public let description: String?
    public let startDate: Date
    public let endDate: Date
    public let dailyMeals: [DailyMealPlan]
    public let targetCalories: Double
    public let targetProtein: Double
    public let targetCarbs: Double
    public let targetFat: Double
    public let createdBy: String?
    
    public init(
        id: String = UUID().uuidString,
        name: String,
        description: String? = nil,
        startDate: Date,
        endDate: Date,
        dailyMeals: [DailyMealPlan],
        targetCalories: Double,
        targetProtein: Double,
        targetCarbs: Double,
        targetFat: Double,
        createdBy: String? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.startDate = startDate
        self.endDate = endDate
        self.dailyMeals = dailyMeals
        self.targetCalories = targetCalories
        self.targetProtein = targetProtein
        self.targetCarbs = targetCarbs
        self.targetFat = targetFat
        self.createdBy = createdBy
    }
}

// MARK: - Daily Meal Plan
public struct DailyMealPlan: Identifiable {
    public let id: String
    public let date: Date
    public let breakfast: [PlannedMeal]
    public let lunch: [PlannedMeal]
    public let dinner: [PlannedMeal]
    public let snacks: [PlannedMeal]
    
    public init(
        id: String = UUID().uuidString,
        date: Date,
        breakfast: [PlannedMeal] = [],
        lunch: [PlannedMeal] = [],
        dinner: [PlannedMeal] = [],
        snacks: [PlannedMeal] = []
    ) {
        self.id = id
        self.date = date
        self.breakfast = breakfast
        self.lunch = lunch
        self.dinner = dinner
        self.snacks = snacks
    }
}

// MARK: - Planned Meal
public struct PlannedMeal: Identifiable {
    public let id: String
    public let foodId: String?
    public let recipeId: String?
    public let name: String
    public let quantity: Double
    public let unit: String
    public let nutritionInfo: NutritionInfo
    
    public init(
        id: String = UUID().uuidString,
        foodId: String? = nil,
        recipeId: String? = nil,
        name: String,
        quantity: Double,
        unit: String,
        nutritionInfo: NutritionInfo
    ) {
        self.id = id
        self.foodId = foodId
        self.recipeId = recipeId
        self.name = name
        self.quantity = quantity
        self.unit = unit
        self.nutritionInfo = nutritionInfo
    }
}

// MARK: - Food Category
public enum FoodCategory: String, CaseIterable {
    case protein = "Protein"
    case vegetables = "Vegetables"
    case fruits = "Fruits"
    case grains = "Grains"
    case dairy = "Dairy"
    case fats = "Fats & Oils"
    case beverages = "Beverages"
    case snacks = "Snacks"
    case condiments = "Condiments"
    case supplements = "Supplements"
    case other = "Other"
    
    public var icon: String {
        switch self {
        case .protein: return "fish"
        case .vegetables: return "carrot"
        case .fruits: return "apple.logo"
        case .grains: return "leaf"
        case .dairy: return "drop.fill"
        case .fats: return "drop.circle"
        case .beverages: return "cup.and.saucer"
        case .snacks: return "bag"
        case .condiments: return "bottle"
        case .supplements: return "pills"
        case .other: return "questionmark.circle"
        }
    }
}

// MARK: - Recipe Category
public enum RecipeCategory: String, CaseIterable {
    case breakfast = "Breakfast"
    case lunch = "Lunch"
    case dinner = "Dinner"
    case snack = "Snack"
    case dessert = "Dessert"
    case smoothie = "Smoothie"
    case salad = "Salad"
    case soup = "Soup"
    case mealPrep = "Meal Prep"
    
    public var icon: String {
        switch self {
        case .breakfast: return "sunrise"
        case .lunch: return "sun.max"
        case .dinner: return "sunset"
        case .snack: return "leaf"
        case .dessert: return "birthday.cake"
        case .smoothie: return "cup.and.saucer.fill"
        case .salad: return "leaf.arrow.circlepath"
        case .soup: return "flame"
        case .mealPrep: return "tray.full"
        }
    }
}