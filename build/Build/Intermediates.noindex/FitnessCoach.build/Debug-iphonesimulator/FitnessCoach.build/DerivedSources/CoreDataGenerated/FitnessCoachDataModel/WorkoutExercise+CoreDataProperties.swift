//
//  WorkoutExercise+CoreDataProperties.swift
//  
//
//  Created by AiNMacM2Pro on 8/27/25.
//
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension WorkoutExercise {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<WorkoutExercise> {
        return NSFetchRequest<WorkoutExercise>(entityName: "WorkoutExercise")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var orderIndex: Int16
    @NSManaged public var sets: Int16
    @NSManaged public var reps: Int16
    @NSManaged public var weight: Double
    @NSManaged public var duration: Int16
    @NSManaged public var distance: Double
    @NSManaged public var restTime: Int16
    @NSManaged public var notes: String?
    @NSManaged public var exercise: Exercise?
    @NSManaged public var workoutTemplate: WorkoutTemplate?
    @NSManaged public var workoutSession: WorkoutSession?

}

extension WorkoutExercise : Identifiable {

}
