//
//  FoodItem+CoreDataProperties.swift
//  
//
//  Created by AiNMacM2Pro on 8/27/25.
//
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension FoodItem {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<FoodItem> {
        return NSFetchRequest<FoodItem>(entityName: "FoodItem")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var brand: String?
    @NSManaged public var category: String?
    @NSManaged public var barcode: String?
    @NSManaged public var caloriesPer100g: Double
    @NSManaged public var proteinPer100g: Double
    @NSManaged public var carbsPer100g: Double
    @NSManaged public var fatPer100g: Double
    @NSManaged public var fiberPer100g: Double
    @NSManaged public var sugarPer100g: Double
    @NSManaged public var sodiumPer100g: Double
    @NSManaged public var servingSize: Double
    @NSManaged public var servingUnit: String?
    @NSManaged public var isVerified: Bool
    @NSManaged public var isCustom: Bool
    @NSManaged public var createdAt: Date?
    @NSManaged public var nutritionEntries: NSSet?
    @NSManaged public var mealPlanItems: NSSet?

}

// MARK: Generated accessors for nutritionEntries
extension FoodItem {

    @objc(addNutritionEntriesObject:)
    @NSManaged public func addToNutritionEntries(_ value: NutritionEntry)

    @objc(removeNutritionEntriesObject:)
    @NSManaged public func removeFromNutritionEntries(_ value: NutritionEntry)

    @objc(addNutritionEntries:)
    @NSManaged public func addToNutritionEntries(_ values: NSSet)

    @objc(removeNutritionEntries:)
    @NSManaged public func removeFromNutritionEntries(_ values: NSSet)

}

// MARK: Generated accessors for mealPlanItems
extension FoodItem {

    @objc(addMealPlanItemsObject:)
    @NSManaged public func addToMealPlanItems(_ value: MealPlanItem)

    @objc(removeMealPlanItemsObject:)
    @NSManaged public func removeFromMealPlanItems(_ value: MealPlanItem)

    @objc(addMealPlanItems:)
    @NSManaged public func addToMealPlanItems(_ values: NSSet)

    @objc(removeMealPlanItems:)
    @NSManaged public func removeFromMealPlanItems(_ values: NSSet)

}

extension FoodItem : Identifiable {

}
