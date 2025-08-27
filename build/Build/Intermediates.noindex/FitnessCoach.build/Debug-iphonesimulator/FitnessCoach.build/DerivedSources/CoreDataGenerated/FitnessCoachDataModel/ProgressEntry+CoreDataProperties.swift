//
//  ProgressEntry+CoreDataProperties.swift
//  
//
//  Created by AiNMacM2Pro on 8/27/25.
//
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension ProgressEntry {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ProgressEntry> {
        return NSFetchRequest<ProgressEntry>(entityName: "ProgressEntry")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var date: Date?
    @NSManaged public var type: String?
    @NSManaged public var weight: Double
    @NSManaged public var bodyFatPercentage: Double
    @NSManaged public var muscleMass: Double
    @NSManaged public var visceralFat: Double
    @NSManaged public var bmi: Double
    @NSManaged public var chest: Double
    @NSManaged public var waist: Double
    @NSManaged public var hips: Double
    @NSManaged public var leftArm: Double
    @NSManaged public var rightArm: Double
    @NSManaged public var leftThigh: Double
    @NSManaged public var rightThigh: Double
    @NSManaged public var notes: String?
    @NSManaged public var photoURLs: [String]?
    @NSManaged public var user: User?

}

extension ProgressEntry : Identifiable {

}
