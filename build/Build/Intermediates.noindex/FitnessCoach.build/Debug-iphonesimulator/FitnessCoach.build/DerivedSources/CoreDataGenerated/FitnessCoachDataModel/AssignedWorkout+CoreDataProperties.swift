//
//  AssignedWorkout+CoreDataProperties.swift
//  
//
//  Created by AiNMacM2Pro on 8/27/25.
//
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension AssignedWorkout {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<AssignedWorkout> {
        return NSFetchRequest<AssignedWorkout>(entityName: "AssignedWorkout")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var assignedDate: Date?
    @NSManaged public var scheduledDate: Date?
    @NSManaged public var status: String?
    @NSManaged public var notes: String?
    @NSManaged public var client: Client?
    @NSManaged public var workoutTemplate: WorkoutTemplate?
    @NSManaged public var workoutSession: WorkoutSession?

}

extension AssignedWorkout : Identifiable {

}
