//
//  AssignedMealPlan+CoreDataProperties.swift
//  
//
//  Created by AiNMacM2Pro on 8/27/25.
//
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension AssignedMealPlan {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<AssignedMealPlan> {
        return NSFetchRequest<AssignedMealPlan>(entityName: "AssignedMealPlan")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var assignedDate: Date?
    @NSManaged public var startDate: Date?
    @NSManaged public var endDate: Date?
    @NSManaged public var status: String?
    @NSManaged public var notes: String?
    @NSManaged public var client: Client?
    @NSManaged public var mealPlanTemplate: MealPlanTemplate?

}

extension AssignedMealPlan : Identifiable {

}
