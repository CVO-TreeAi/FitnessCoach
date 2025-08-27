//
//  Goal+CoreDataProperties.swift
//  
//
//  Created by AiNMacM2Pro on 8/27/25.
//
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension Goal {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Goal> {
        return NSFetchRequest<Goal>(entityName: "Goal")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var title: String?
    @NSManaged public var desc: String?
    @NSManaged public var category: String?
    @NSManaged public var targetValue: Double
    @NSManaged public var currentValue: Double
    @NSManaged public var unit: String?
    @NSManaged public var startDate: Date?
    @NSManaged public var targetDate: Date?
    @NSManaged public var status: String?
    @NSManaged public var priority: String?
    @NSManaged public var isCompleted: Bool
    @NSManaged public var completedDate: Date?
    @NSManaged public var createdAt: Date?
    @NSManaged public var user: User?

}

extension Goal : Identifiable {

}
