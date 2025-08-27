//
//  Client+CoreDataProperties.swift
//  
//
//  Created by AiNMacM2Pro on 8/27/25.
//
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension Client {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Client> {
        return NSFetchRequest<Client>(entityName: "Client")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var startWeight: Double
    @NSManaged public var goalWeight: Double
    @NSManaged public var startDate: Date?
    @NSManaged public var targetDate: Date?
    @NSManaged public var medicalConditions: [String]?
    @NSManaged public var injuries: [String]?
    @NSManaged public var preferences: [String]?
    @NSManaged public var notes: String?
    @NSManaged public var isActive: Bool
    @NSManaged public var user: User?
    @NSManaged public var coach: Coach?
    @NSManaged public var assignedWorkouts: NSSet?
    @NSManaged public var assignedMealPlans: NSSet?

}

// MARK: Generated accessors for assignedWorkouts
extension Client {

    @objc(addAssignedWorkoutsObject:)
    @NSManaged public func addToAssignedWorkouts(_ value: AssignedWorkout)

    @objc(removeAssignedWorkoutsObject:)
    @NSManaged public func removeFromAssignedWorkouts(_ value: AssignedWorkout)

    @objc(addAssignedWorkouts:)
    @NSManaged public func addToAssignedWorkouts(_ values: NSSet)

    @objc(removeAssignedWorkouts:)
    @NSManaged public func removeFromAssignedWorkouts(_ values: NSSet)

}

// MARK: Generated accessors for assignedMealPlans
extension Client {

    @objc(addAssignedMealPlansObject:)
    @NSManaged public func addToAssignedMealPlans(_ value: AssignedMealPlan)

    @objc(removeAssignedMealPlansObject:)
    @NSManaged public func removeFromAssignedMealPlans(_ value: AssignedMealPlan)

    @objc(addAssignedMealPlans:)
    @NSManaged public func addToAssignedMealPlans(_ values: NSSet)

    @objc(removeAssignedMealPlans:)
    @NSManaged public func removeFromAssignedMealPlans(_ values: NSSet)

}

extension Client : Identifiable {

}
