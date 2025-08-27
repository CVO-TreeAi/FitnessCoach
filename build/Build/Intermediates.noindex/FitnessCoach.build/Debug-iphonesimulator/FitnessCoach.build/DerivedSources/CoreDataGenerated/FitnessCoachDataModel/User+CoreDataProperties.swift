//
//  User+CoreDataProperties.swift
//  
//
//  Created by AiNMacM2Pro on 8/27/25.
//
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension User {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<User> {
        return NSFetchRequest<User>(entityName: "User")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var userIdentifier: String?
    @NSManaged public var email: String?
    @NSManaged public var firstName: String?
    @NSManaged public var lastName: String?
    @NSManaged public var role: String?
    @NSManaged public var dateOfBirth: Date?
    @NSManaged public var height: Double
    @NSManaged public var gender: String?
    @NSManaged public var activityLevel: String?
    @NSManaged public var fitnessGoals: [String]?
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var isActive: Bool
    @NSManaged public var coachProfile: Coach?
    @NSManaged public var clientProfile: Client?
    @NSManaged public var workoutSessions: NSSet?
    @NSManaged public var nutritionEntries: NSSet?
    @NSManaged public var progressEntries: NSSet?
    @NSManaged public var goals: NSSet?

}

// MARK: Generated accessors for workoutSessions
extension User {

    @objc(addWorkoutSessionsObject:)
    @NSManaged public func addToWorkoutSessions(_ value: WorkoutSession)

    @objc(removeWorkoutSessionsObject:)
    @NSManaged public func removeFromWorkoutSessions(_ value: WorkoutSession)

    @objc(addWorkoutSessions:)
    @NSManaged public func addToWorkoutSessions(_ values: NSSet)

    @objc(removeWorkoutSessions:)
    @NSManaged public func removeFromWorkoutSessions(_ values: NSSet)

}

// MARK: Generated accessors for nutritionEntries
extension User {

    @objc(addNutritionEntriesObject:)
    @NSManaged public func addToNutritionEntries(_ value: NutritionEntry)

    @objc(removeNutritionEntriesObject:)
    @NSManaged public func removeFromNutritionEntries(_ value: NutritionEntry)

    @objc(addNutritionEntries:)
    @NSManaged public func addToNutritionEntries(_ values: NSSet)

    @objc(removeNutritionEntries:)
    @NSManaged public func removeFromNutritionEntries(_ values: NSSet)

}

// MARK: Generated accessors for progressEntries
extension User {

    @objc(addProgressEntriesObject:)
    @NSManaged public func addToProgressEntries(_ value: ProgressEntry)

    @objc(removeProgressEntriesObject:)
    @NSManaged public func removeFromProgressEntries(_ value: ProgressEntry)

    @objc(addProgressEntries:)
    @NSManaged public func addToProgressEntries(_ values: NSSet)

    @objc(removeProgressEntries:)
    @NSManaged public func removeFromProgressEntries(_ values: NSSet)

}

// MARK: Generated accessors for goals
extension User {

    @objc(addGoalsObject:)
    @NSManaged public func addToGoals(_ value: Goal)

    @objc(removeGoalsObject:)
    @NSManaged public func removeFromGoals(_ value: Goal)

    @objc(addGoals:)
    @NSManaged public func addToGoals(_ values: NSSet)

    @objc(removeGoals:)
    @NSManaged public func removeFromGoals(_ values: NSSet)

}

extension User : Identifiable {

}
