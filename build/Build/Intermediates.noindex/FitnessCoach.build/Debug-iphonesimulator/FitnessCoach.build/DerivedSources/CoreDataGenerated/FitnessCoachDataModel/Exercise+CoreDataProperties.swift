//
//  Exercise+CoreDataProperties.swift
//  
//
//  Created by AiNMacM2Pro on 8/27/25.
//
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension Exercise {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Exercise> {
        return NSFetchRequest<Exercise>(entityName: "Exercise")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var category: String?
    @NSManaged public var muscleGroups: [String]?
    @NSManaged public var equipment: [String]?
    @NSManaged public var instructions: String?
    @NSManaged public var difficulty: String?
    @NSManaged public var videoURL: String?
    @NSManaged public var imageURL: String?
    @NSManaged public var isCustom: Bool
    @NSManaged public var createdAt: Date?
    @NSManaged public var workoutExercises: NSSet?

}

// MARK: Generated accessors for workoutExercises
extension Exercise {

    @objc(addWorkoutExercisesObject:)
    @NSManaged public func addToWorkoutExercises(_ value: WorkoutExercise)

    @objc(removeWorkoutExercisesObject:)
    @NSManaged public func removeFromWorkoutExercises(_ value: WorkoutExercise)

    @objc(addWorkoutExercises:)
    @NSManaged public func addToWorkoutExercises(_ values: NSSet)

    @objc(removeWorkoutExercises:)
    @NSManaged public func removeFromWorkoutExercises(_ values: NSSet)

}

extension Exercise : Identifiable {

}
