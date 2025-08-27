//
//  MealPlanTemplate+CoreDataProperties.swift
//  
//
//  Created by AiNMacM2Pro on 8/27/25.
//
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension MealPlanTemplate {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MealPlanTemplate> {
        return NSFetchRequest<MealPlanTemplate>(entityName: "MealPlanTemplate")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var desc: String?
    @NSManaged public var goal: String?
    @NSManaged public var targetCalories: Int16
    @NSManaged public var targetProtein: Int16
    @NSManaged public var targetCarbs: Int16
    @NSManaged public var targetFat: Int16
    @NSManaged public var duration: Int16
    @NSManaged public var isPublic: Bool
    @NSManaged public var tags: [String]?
    @NSManaged public var createdAt: Date?
    @NSManaged public var coach: Coach?
    @NSManaged public var meals: NSSet?
    @NSManaged public var assignedMealPlans: NSSet?

}

// MARK: Generated accessors for meals
extension MealPlanTemplate {

    @objc(addMealsObject:)
    @NSManaged public func addToMeals(_ value: MealPlanItem)

    @objc(removeMealsObject:)
    @NSManaged public func removeFromMeals(_ value: MealPlanItem)

    @objc(addMeals:)
    @NSManaged public func addToMeals(_ values: NSSet)

    @objc(removeMeals:)
    @NSManaged public func removeFromMeals(_ values: NSSet)

}

// MARK: Generated accessors for assignedMealPlans
extension MealPlanTemplate {

    @objc(addAssignedMealPlansObject:)
    @NSManaged public func addToAssignedMealPlans(_ value: AssignedMealPlan)

    @objc(removeAssignedMealPlansObject:)
    @NSManaged public func removeFromAssignedMealPlans(_ value: AssignedMealPlan)

    @objc(addAssignedMealPlans:)
    @NSManaged public func addToAssignedMealPlans(_ values: NSSet)

    @objc(removeAssignedMealPlans:)
    @NSManaged public func removeFromAssignedMealPlans(_ values: NSSet)

}

extension MealPlanTemplate : Identifiable {

}
