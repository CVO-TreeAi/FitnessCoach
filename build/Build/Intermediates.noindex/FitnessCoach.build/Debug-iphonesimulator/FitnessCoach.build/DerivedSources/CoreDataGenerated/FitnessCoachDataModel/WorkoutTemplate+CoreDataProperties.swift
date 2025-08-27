//
//  WorkoutTemplate+CoreDataProperties.swift
//  
//
//  Created by AiNMacM2Pro on 8/27/25.
//
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension WorkoutTemplate {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<WorkoutTemplate> {
        return NSFetchRequest<WorkoutTemplate>(entityName: "WorkoutTemplate")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var desc: String?
    @NSManaged public var category: String?
    @NSManaged public var difficulty: String?
    @NSManaged public var estimatedDuration: Int16
    @NSManaged public var caloriesBurned: Int16
    @NSManaged public var isPublic: Bool
    @NSManaged public var tags: [String]?
    @NSManaged public var createdAt: Date?
    @NSManaged public var coach: Coach?
    @NSManaged public var exercises: NSSet?
    @NSManaged public var assignedWorkouts: NSSet?

}

// MARK: Generated accessors for exercises
extension WorkoutTemplate {

    @objc(addExercisesObject:)
    @NSManaged public func addToExercises(_ value: WorkoutExercise)

    @objc(removeExercisesObject:)
    @NSManaged public func removeFromExercises(_ value: WorkoutExercise)

    @objc(addExercises:)
    @NSManaged public func addToExercises(_ values: NSSet)

    @objc(removeExercises:)
    @NSManaged public func removeFromExercises(_ values: NSSet)

}

// MARK: Generated accessors for assignedWorkouts
extension WorkoutTemplate {

    @objc(addAssignedWorkoutsObject:)
    @NSManaged public func addToAssignedWorkouts(_ value: AssignedWorkout)

    @objc(removeAssignedWorkoutsObject:)
    @NSManaged public func removeFromAssignedWorkouts(_ value: AssignedWorkout)

    @objc(addAssignedWorkouts:)
    @NSManaged public func addToAssignedWorkouts(_ values: NSSet)

    @objc(removeAssignedWorkouts:)
    @NSManaged public func removeFromAssignedWorkouts(_ values: NSSet)

}

extension WorkoutTemplate : Identifiable {

}
