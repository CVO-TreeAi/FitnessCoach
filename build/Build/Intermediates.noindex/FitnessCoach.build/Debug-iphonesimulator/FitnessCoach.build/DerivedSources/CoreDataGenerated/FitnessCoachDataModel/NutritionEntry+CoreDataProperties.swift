//
//  NutritionEntry+CoreDataProperties.swift
//  
//
//  Created by AiNMacM2Pro on 8/27/25.
//
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension NutritionEntry {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<NutritionEntry> {
        return NSFetchRequest<NutritionEntry>(entityName: "NutritionEntry")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var date: Date?
    @NSManaged public var mealType: String?
    @NSManaged public var quantity: Double
    @NSManaged public var unit: String?
    @NSManaged public var calories: Double
    @NSManaged public var protein: Double
    @NSManaged public var carbs: Double
    @NSManaged public var fat: Double
    @NSManaged public var fiber: Double
    @NSManaged public var sugar: Double
    @NSManaged public var sodium: Double
    @NSManaged public var notes: String?
    @NSManaged public var user: User?
    @NSManaged public var foodItem: FoodItem?

}

extension NutritionEntry : Identifiable {

}
