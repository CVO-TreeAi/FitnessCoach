//
//  MealPlanItem+CoreDataProperties.swift
//  
//
//  Created by AiNMacM2Pro on 8/27/25.
//
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension MealPlanItem {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MealPlanItem> {
        return NSFetchRequest<MealPlanItem>(entityName: "MealPlanItem")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var day: Int16
    @NSManaged public var mealType: String?
    @NSManaged public var quantity: Double
    @NSManaged public var unit: String?
    @NSManaged public var orderIndex: Int16
    @NSManaged public var mealPlanTemplate: MealPlanTemplate?
    @NSManaged public var foodItem: FoodItem?

}

extension MealPlanItem : Identifiable {

}
