//
//  Coach+CoreDataProperties.swift
//  
//
//  Created by AiNMacM2Pro on 8/27/25.
//
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension Coach {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Coach> {
        return NSFetchRequest<Coach>(entityName: "Coach")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var businessName: String?
    @NSManaged public var certifications: [String]?
    @NSManaged public var specializations: [String]?
    @NSManaged public var yearsOfExperience: Int16
    @NSManaged public var bio: String?
    @NSManaged public var hourlyRate: Double
    @NSManaged public var createdAt: Date?
    @NSManaged public var user: User?
    @NSManaged public var clients: NSSet?
    @NSManaged public var workoutTemplates: NSSet?
    @NSManaged public var mealPlanTemplates: NSSet?

}

// MARK: Generated accessors for clients
extension Coach {

    @objc(addClientsObject:)
    @NSManaged public func addToClients(_ value: Client)

    @objc(removeClientsObject:)
    @NSManaged public func removeFromClients(_ value: Client)

    @objc(addClients:)
    @NSManaged public func addToClients(_ values: NSSet)

    @objc(removeClients:)
    @NSManaged public func removeFromClients(_ values: NSSet)

}

// MARK: Generated accessors for workoutTemplates
extension Coach {

    @objc(addWorkoutTemplatesObject:)
    @NSManaged public func addToWorkoutTemplates(_ value: WorkoutTemplate)

    @objc(removeWorkoutTemplatesObject:)
    @NSManaged public func removeFromWorkoutTemplates(_ value: WorkoutTemplate)

    @objc(addWorkoutTemplates:)
    @NSManaged public func addToWorkoutTemplates(_ values: NSSet)

    @objc(removeWorkoutTemplates:)
    @NSManaged public func removeFromWorkoutTemplates(_ values: NSSet)

}

// MARK: Generated accessors for mealPlanTemplates
extension Coach {

    @objc(addMealPlanTemplatesObject:)
    @NSManaged public func addToMealPlanTemplates(_ value: MealPlanTemplate)

    @objc(removeMealPlanTemplatesObject:)
    @NSManaged public func removeFromMealPlanTemplates(_ value: MealPlanTemplate)

    @objc(addMealPlanTemplates:)
    @NSManaged public func addToMealPlanTemplates(_ values: NSSet)

    @objc(removeMealPlanTemplates:)
    @NSManaged public func removeFromMealPlanTemplates(_ values: NSSet)

}

extension Coach : Identifiable {

}
