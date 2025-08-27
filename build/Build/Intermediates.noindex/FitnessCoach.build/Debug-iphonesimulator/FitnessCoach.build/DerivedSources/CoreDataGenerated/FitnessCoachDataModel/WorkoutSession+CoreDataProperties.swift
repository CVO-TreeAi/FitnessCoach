//
//  WorkoutSession+CoreDataProperties.swift
//  
//
//  Created by AiNMacM2Pro on 8/27/25.
//
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension WorkoutSession {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<WorkoutSession> {
        return NSFetchRequest<WorkoutSession>(entityName: "WorkoutSession")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var startTime: Date?
    @NSManaged public var endTime: Date?
    @NSManaged public var status: String?
    @NSManaged public var totalDuration: Int16
    @NSManaged public var caloriesBurned: Int16
    @NSManaged public var notes: String?
    @NSManaged public var rating: Int16
    @NSManaged public var user: User?
    @NSManaged public var assignedWorkout: AssignedWorkout?
    @NSManaged public var exercises: NSSet?

}

// MARK: Generated accessors for exercises
extension WorkoutSession {

    @objc(addExercisesObject:)
    @NSManaged public func addToExercises(_ value: WorkoutExercise)

    @objc(removeExercisesObject:)
    @NSManaged public func removeFromExercises(_ value: WorkoutExercise)

    @objc(addExercises:)
    @NSManaged public func addToExercises(_ values: NSSet)

    @objc(removeExercises:)
    @NSManaged public func removeFromExercises(_ values: NSSet)

}

extension WorkoutSession : Identifiable {

}
