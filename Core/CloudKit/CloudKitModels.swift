import Foundation
import CloudKit
import CoreData

// MARK: - User CloudKit Model
extension User: CloudKitModel {
    public static var recordType: String { "User" }
    
    public func toCKRecord() -> CKRecord {
        let recordID = CKRecord.ID(recordName: id?.uuidString ?? UUID().uuidString)
        let record = CKRecord(recordType: Self.recordType, recordID: recordID)
        
        record["userIdentifier"] = userIdentifier
        record["email"] = email
        record["firstName"] = firstName
        record["lastName"] = lastName
        record["role"] = role
        record["dateOfBirth"] = dateOfBirth
        record["height"] = height
        record["gender"] = gender
        record["activityLevel"] = activityLevel
        
        // Encode arrays as JSON data
        if let fitnessGoals = fitnessGoals {
            let jsonData = try? JSONSerialization.data(withJSONObject: fitnessGoals)
            record["fitnessGoals"] = jsonData
        }
        
        record["createdAt"] = createdAt
        record["updatedAt"] = updatedAt
        record["isActive"] = isActive
        
        return record
    }
    
    public static func fromCKRecord(_ record: CKRecord) -> User? {
        let context = CoreDataManager.shared.context
        let user = User(context: context)
        
        guard let recordName = record.recordID.recordName,
              let id = UUID(uuidString: recordName) else { return nil }
        
        user.id = id
        user.userIdentifier = record["userIdentifier"] as? String ?? ""
        user.email = record["email"] as? String ?? ""
        user.firstName = record["firstName"] as? String ?? ""
        user.lastName = record["lastName"] as? String ?? ""
        user.role = record["role"] as? String ?? "user"
        user.dateOfBirth = record["dateOfBirth"] as? Date
        user.height = record["height"] as? Double ?? 0
        user.gender = record["gender"] as? String
        user.activityLevel = record["activityLevel"] as? String
        
        // Decode JSON data for arrays
        if let fitnessGoalsData = record["fitnessGoals"] as? Data,
           let fitnessGoals = try? JSONSerialization.jsonObject(with: fitnessGoalsData) as? [String] {
            user.fitnessGoals = fitnessGoals
        }
        
        user.createdAt = record["createdAt"] as? Date ?? Date()
        user.updatedAt = record["updatedAt"] as? Date ?? Date()
        user.isActive = record["isActive"] as? Bool ?? true
        
        return user
    }
}

// MARK: - Coach CloudKit Model
extension Coach: CloudKitModel {
    public static var recordType: String { "Coach" }
    
    public func toCKRecord() -> CKRecord {
        let recordID = CKRecord.ID(recordName: id?.uuidString ?? UUID().uuidString)
        let record = CKRecord(recordType: Self.recordType, recordID: recordID)
        
        record["businessName"] = businessName
        record["yearsOfExperience"] = yearsOfExperience
        record["bio"] = bio
        record["hourlyRate"] = hourlyRate
        record["createdAt"] = createdAt
        
        // Encode arrays as JSON data
        if let certifications = certifications {
            let jsonData = try? JSONSerialization.data(withJSONObject: certifications)
            record["certifications"] = jsonData
        }
        
        if let specializations = specializations {
            let jsonData = try? JSONSerialization.data(withJSONObject: specializations)
            record["specializations"] = jsonData
        }
        
        // Reference to User
        if let userID = user?.id?.uuidString {
            record["userReference"] = CKRecord.Reference(recordID: CKRecord.ID(recordName: userID), action: .deleteSelf)
        }
        
        return record
    }
    
    public static func fromCKRecord(_ record: CKRecord) -> Coach? {
        let context = CoreDataManager.shared.context
        let coach = Coach(context: context)
        
        guard let recordName = record.recordID.recordName,
              let id = UUID(uuidString: recordName) else { return nil }
        
        coach.id = id
        coach.businessName = record["businessName"] as? String
        coach.yearsOfExperience = record["yearsOfExperience"] as? Int16 ?? 0
        coach.bio = record["bio"] as? String
        coach.hourlyRate = record["hourlyRate"] as? Double ?? 0
        coach.createdAt = record["createdAt"] as? Date ?? Date()
        
        // Decode JSON data for arrays
        if let certificationsData = record["certifications"] as? Data,
           let certifications = try? JSONSerialization.jsonObject(with: certificationsData) as? [String] {
            coach.certifications = certifications
        }
        
        if let specializationsData = record["specializations"] as? Data,
           let specializations = try? JSONSerialization.jsonObject(with: specializationsData) as? [String] {
            coach.specializations = specializations
        }
        
        return coach
    }
}

// MARK: - Client CloudKit Model
extension Client: CloudKitModel {
    public static var recordType: String { "Client" }
    
    public func toCKRecord() -> CKRecord {
        let recordID = CKRecord.ID(recordName: id?.uuidString ?? UUID().uuidString)
        let record = CKRecord(recordType: Self.recordType, recordID: recordID)
        
        record["startWeight"] = startWeight
        record["goalWeight"] = goalWeight
        record["startDate"] = startDate
        record["targetDate"] = targetDate
        record["notes"] = notes
        record["isActive"] = isActive
        
        // Encode arrays as JSON data
        if let medicalConditions = medicalConditions {
            let jsonData = try? JSONSerialization.data(withJSONObject: medicalConditions)
            record["medicalConditions"] = jsonData
        }
        
        if let injuries = injuries {
            let jsonData = try? JSONSerialization.data(withJSONObject: injuries)
            record["injuries"] = jsonData
        }
        
        if let preferences = preferences {
            let jsonData = try? JSONSerialization.data(withJSONObject: preferences)
            record["preferences"] = jsonData
        }
        
        // References
        if let userID = user?.id?.uuidString {
            record["userReference"] = CKRecord.Reference(recordID: CKRecord.ID(recordName: userID), action: .deleteSelf)
        }
        
        if let coachID = coach?.id?.uuidString {
            record["coachReference"] = CKRecord.Reference(recordID: CKRecord.ID(recordName: coachID), action: .nullify)
        }
        
        return record
    }
    
    public static func fromCKRecord(_ record: CKRecord) -> Client? {
        let context = CoreDataManager.shared.context
        let client = Client(context: context)
        
        guard let recordName = record.recordID.recordName,
              let id = UUID(uuidString: recordName) else { return nil }
        
        client.id = id
        client.startWeight = record["startWeight"] as? Double ?? 0
        client.goalWeight = record["goalWeight"] as? Double ?? 0
        client.startDate = record["startDate"] as? Date ?? Date()
        client.targetDate = record["targetDate"] as? Date
        client.notes = record["notes"] as? String
        client.isActive = record["isActive"] as? Bool ?? true
        
        // Decode JSON data for arrays
        if let medicalConditionsData = record["medicalConditions"] as? Data,
           let medicalConditions = try? JSONSerialization.jsonObject(with: medicalConditionsData) as? [String] {
            client.medicalConditions = medicalConditions
        }
        
        if let injuriesData = record["injuries"] as? Data,
           let injuries = try? JSONSerialization.jsonObject(with: injuriesData) as? [String] {
            client.injuries = injuries
        }
        
        if let preferencesData = record["preferences"] as? Data,
           let preferences = try? JSONSerialization.jsonObject(with: preferencesData) as? [String] {
            client.preferences = preferences
        }
        
        return client
    }
}

// MARK: - Exercise CloudKit Model
extension Exercise: CloudKitModel {
    public static var recordType: String { "Exercise" }
    
    public func toCKRecord() -> CKRecord {
        let recordID = CKRecord.ID(recordName: id?.uuidString ?? UUID().uuidString)
        let record = CKRecord(recordType: Self.recordType, recordID: recordID)
        
        record["name"] = name
        record["category"] = category
        record["instructions"] = instructions
        record["difficulty"] = difficulty
        record["videoURL"] = videoURL
        record["imageURL"] = imageURL
        record["isCustom"] = isCustom
        record["createdAt"] = createdAt
        
        // Encode arrays as JSON data
        if let muscleGroups = muscleGroups {
            let jsonData = try? JSONSerialization.data(withJSONObject: muscleGroups)
            record["muscleGroups"] = jsonData
        }
        
        if let equipment = equipment {
            let jsonData = try? JSONSerialization.data(withJSONObject: equipment)
            record["equipment"] = jsonData
        }
        
        return record
    }
    
    public static func fromCKRecord(_ record: CKRecord) -> Exercise? {
        let context = CoreDataManager.shared.context
        let exercise = Exercise(context: context)
        
        guard let recordName = record.recordID.recordName,
              let id = UUID(uuidString: recordName) else { return nil }
        
        exercise.id = id
        exercise.name = record["name"] as? String ?? ""
        exercise.category = record["category"] as? String ?? ""
        exercise.instructions = record["instructions"] as? String
        exercise.difficulty = record["difficulty"] as? String ?? ""
        exercise.videoURL = record["videoURL"] as? String
        exercise.imageURL = record["imageURL"] as? String
        exercise.isCustom = record["isCustom"] as? Bool ?? false
        exercise.createdAt = record["createdAt"] as? Date ?? Date()
        
        // Decode JSON data for arrays
        if let muscleGroupsData = record["muscleGroups"] as? Data,
           let muscleGroups = try? JSONSerialization.jsonObject(with: muscleGroupsData) as? [String] {
            exercise.muscleGroups = muscleGroups
        }
        
        if let equipmentData = record["equipment"] as? Data,
           let equipment = try? JSONSerialization.jsonObject(with: equipmentData) as? [String] {
            exercise.equipment = equipment
        }
        
        return exercise
    }
}

// MARK: - WorkoutTemplate CloudKit Model
extension WorkoutTemplate: CloudKitModel {
    public static var recordType: String { "WorkoutTemplate" }
    
    public func toCKRecord() -> CKRecord {
        let recordID = CKRecord.ID(recordName: id?.uuidString ?? UUID().uuidString)
        let record = CKRecord(recordType: Self.recordType, recordID: recordID)
        
        record["name"] = name
        record["desc"] = desc
        record["category"] = category
        record["difficulty"] = difficulty
        record["estimatedDuration"] = estimatedDuration
        record["caloriesBurned"] = caloriesBurned
        record["isPublic"] = isPublic
        record["createdAt"] = createdAt
        
        // Encode arrays as JSON data
        if let tags = tags {
            let jsonData = try? JSONSerialization.data(withJSONObject: tags)
            record["tags"] = jsonData
        }
        
        // Reference to Coach
        if let coachID = coach?.id?.uuidString {
            record["coachReference"] = CKRecord.Reference(recordID: CKRecord.ID(recordName: coachID), action: .nullify)
        }
        
        return record
    }
    
    public static func fromCKRecord(_ record: CKRecord) -> WorkoutTemplate? {
        let context = CoreDataManager.shared.context
        let template = WorkoutTemplate(context: context)
        
        guard let recordName = record.recordID.recordName,
              let id = UUID(uuidString: recordName) else { return nil }
        
        template.id = id
        template.name = record["name"] as? String ?? ""
        template.desc = record["desc"] as? String
        template.category = record["category"] as? String ?? ""
        template.difficulty = record["difficulty"] as? String ?? ""
        template.estimatedDuration = record["estimatedDuration"] as? Int16 ?? 0
        template.caloriesBurned = record["caloriesBurned"] as? Int16 ?? 0
        template.isPublic = record["isPublic"] as? Bool ?? false
        template.createdAt = record["createdAt"] as? Date ?? Date()
        
        // Decode JSON data for arrays
        if let tagsData = record["tags"] as? Data,
           let tags = try? JSONSerialization.jsonObject(with: tagsData) as? [String] {
            template.tags = tags
        }
        
        return template
    }
}

// MARK: - WorkoutSession CloudKit Model
extension WorkoutSession: CloudKitModel {
    public static var recordType: String { "WorkoutSession" }
    
    public func toCKRecord() -> CKRecord {
        let recordID = CKRecord.ID(recordName: id?.uuidString ?? UUID().uuidString)
        let record = CKRecord(recordType: Self.recordType, recordID: recordID)
        
        record["startTime"] = startTime
        record["endTime"] = endTime
        record["status"] = status
        record["totalDuration"] = totalDuration
        record["caloriesBurned"] = caloriesBurned
        record["notes"] = notes
        record["rating"] = rating
        
        // Reference to User
        if let userID = user?.id?.uuidString {
            record["userReference"] = CKRecord.Reference(recordID: CKRecord.ID(recordName: userID), action: .deleteSelf)
        }
        
        // Reference to AssignedWorkout
        if let assignedWorkoutID = assignedWorkout?.id?.uuidString {
            record["assignedWorkoutReference"] = CKRecord.Reference(recordID: CKRecord.ID(recordName: assignedWorkoutID), action: .nullify)
        }
        
        return record
    }
    
    public static func fromCKRecord(_ record: CKRecord) -> WorkoutSession? {
        let context = CoreDataManager.shared.context
        let session = WorkoutSession(context: context)
        
        guard let recordName = record.recordID.recordName,
              let id = UUID(uuidString: recordName) else { return nil }
        
        session.id = id
        session.startTime = record["startTime"] as? Date ?? Date()
        session.endTime = record["endTime"] as? Date
        session.status = record["status"] as? String ?? "in_progress"
        session.totalDuration = record["totalDuration"] as? Int16 ?? 0
        session.caloriesBurned = record["caloriesBurned"] as? Int16 ?? 0
        session.notes = record["notes"] as? String
        session.rating = record["rating"] as? Int16 ?? 0
        
        return session
    }
}

// MARK: - NutritionEntry CloudKit Model
extension NutritionEntry: CloudKitModel {
    public static var recordType: String { "NutritionEntry" }
    
    public func toCKRecord() -> CKRecord {
        let recordID = CKRecord.ID(recordName: id?.uuidString ?? UUID().uuidString)
        let record = CKRecord(recordType: Self.recordType, recordID: recordID)
        
        record["date"] = date
        record["mealType"] = mealType
        record["quantity"] = quantity
        record["unit"] = unit
        record["calories"] = calories
        record["protein"] = protein
        record["carbs"] = carbs
        record["fat"] = fat
        record["fiber"] = fiber
        record["sugar"] = sugar
        record["sodium"] = sodium
        record["notes"] = notes
        
        // References
        if let userID = user?.id?.uuidString {
            record["userReference"] = CKRecord.Reference(recordID: CKRecord.ID(recordName: userID), action: .deleteSelf)
        }
        
        if let foodItemID = foodItem?.id?.uuidString {
            record["foodItemReference"] = CKRecord.Reference(recordID: CKRecord.ID(recordName: foodItemID), action: .nullify)
        }
        
        return record
    }
    
    public static func fromCKRecord(_ record: CKRecord) -> NutritionEntry? {
        let context = CoreDataManager.shared.context
        let entry = NutritionEntry(context: context)
        
        guard let recordName = record.recordID.recordName,
              let id = UUID(uuidString: recordName) else { return nil }
        
        entry.id = id
        entry.date = record["date"] as? Date ?? Date()
        entry.mealType = record["mealType"] as? String ?? ""
        entry.quantity = record["quantity"] as? Double ?? 0
        entry.unit = record["unit"] as? String ?? ""
        entry.calories = record["calories"] as? Double ?? 0
        entry.protein = record["protein"] as? Double ?? 0
        entry.carbs = record["carbs"] as? Double ?? 0
        entry.fat = record["fat"] as? Double ?? 0
        entry.fiber = record["fiber"] as? Double ?? 0
        entry.sugar = record["sugar"] as? Double ?? 0
        entry.sodium = record["sodium"] as? Double ?? 0
        entry.notes = record["notes"] as? String
        
        return entry
    }
}

// MARK: - FoodItem CloudKit Model
extension FoodItem: CloudKitModel {
    public static var recordType: String { "FoodItem" }
    
    public func toCKRecord() -> CKRecord {
        let recordID = CKRecord.ID(recordName: id?.uuidString ?? UUID().uuidString)
        let record = CKRecord(recordType: Self.recordType, recordID: recordID)
        
        record["name"] = name
        record["brand"] = brand
        record["category"] = category
        record["barcode"] = barcode
        record["caloriesPer100g"] = caloriesPer100g
        record["proteinPer100g"] = proteinPer100g
        record["carbsPer100g"] = carbsPer100g
        record["fatPer100g"] = fatPer100g
        record["fiberPer100g"] = fiberPer100g
        record["sugarPer100g"] = sugarPer100g
        record["sodiumPer100g"] = sodiumPer100g
        record["servingSize"] = servingSize
        record["servingUnit"] = servingUnit
        record["isVerified"] = isVerified
        record["isCustom"] = isCustom
        record["createdAt"] = createdAt
        
        return record
    }
    
    public static func fromCKRecord(_ record: CKRecord) -> FoodItem? {
        let context = CoreDataManager.shared.context
        let foodItem = FoodItem(context: context)
        
        guard let recordName = record.recordID.recordName,
              let id = UUID(uuidString: recordName) else { return nil }
        
        foodItem.id = id
        foodItem.name = record["name"] as? String ?? ""
        foodItem.brand = record["brand"] as? String
        foodItem.category = record["category"] as? String ?? ""
        foodItem.barcode = record["barcode"] as? String
        foodItem.caloriesPer100g = record["caloriesPer100g"] as? Double ?? 0
        foodItem.proteinPer100g = record["proteinPer100g"] as? Double ?? 0
        foodItem.carbsPer100g = record["carbsPer100g"] as? Double ?? 0
        foodItem.fatPer100g = record["fatPer100g"] as? Double ?? 0
        foodItem.fiberPer100g = record["fiberPer100g"] as? Double ?? 0
        foodItem.sugarPer100g = record["sugarPer100g"] as? Double ?? 0
        foodItem.sodiumPer100g = record["sodiumPer100g"] as? Double ?? 0
        foodItem.servingSize = record["servingSize"] as? Double ?? 0
        foodItem.servingUnit = record["servingUnit"] as? String
        foodItem.isVerified = record["isVerified"] as? Bool ?? false
        foodItem.isCustom = record["isCustom"] as? Bool ?? false
        foodItem.createdAt = record["createdAt"] as? Date ?? Date()
        
        return foodItem
    }
}

// MARK: - ProgressEntry CloudKit Model
extension ProgressEntry: CloudKitModel {
    public static var recordType: String { "ProgressEntry" }
    
    public func toCKRecord() -> CKRecord {
        let recordID = CKRecord.ID(recordName: id?.uuidString ?? UUID().uuidString)
        let record = CKRecord(recordType: Self.recordType, recordID: recordID)
        
        record["date"] = date
        record["type"] = type
        record["weight"] = weight
        record["bodyFatPercentage"] = bodyFatPercentage
        record["muscleMass"] = muscleMass
        record["visceralFat"] = visceralFat
        record["bmi"] = bmi
        record["chest"] = chest
        record["waist"] = waist
        record["hips"] = hips
        record["leftArm"] = leftArm
        record["rightArm"] = rightArm
        record["leftThigh"] = leftThigh
        record["rightThigh"] = rightThigh
        record["notes"] = notes
        
        // Encode photo URLs as JSON data
        if let photoURLs = photoURLs {
            let jsonData = try? JSONSerialization.data(withJSONObject: photoURLs)
            record["photoURLs"] = jsonData
        }
        
        // Reference to User
        if let userID = user?.id?.uuidString {
            record["userReference"] = CKRecord.Reference(recordID: CKRecord.ID(recordName: userID), action: .deleteSelf)
        }
        
        return record
    }
    
    public static func fromCKRecord(_ record: CKRecord) -> ProgressEntry? {
        let context = CoreDataManager.shared.context
        let entry = ProgressEntry(context: context)
        
        guard let recordName = record.recordID.recordName,
              let id = UUID(uuidString: recordName) else { return nil }
        
        entry.id = id
        entry.date = record["date"] as? Date ?? Date()
        entry.type = record["type"] as? String ?? ""
        entry.weight = record["weight"] as? Double ?? 0
        entry.bodyFatPercentage = record["bodyFatPercentage"] as? Double ?? 0
        entry.muscleMass = record["muscleMass"] as? Double ?? 0
        entry.visceralFat = record["visceralFat"] as? Double ?? 0
        entry.bmi = record["bmi"] as? Double ?? 0
        entry.chest = record["chest"] as? Double ?? 0
        entry.waist = record["waist"] as? Double ?? 0
        entry.hips = record["hips"] as? Double ?? 0
        entry.leftArm = record["leftArm"] as? Double ?? 0
        entry.rightArm = record["rightArm"] as? Double ?? 0
        entry.leftThigh = record["leftThigh"] as? Double ?? 0
        entry.rightThigh = record["rightThigh"] as? Double ?? 0
        entry.notes = record["notes"] as? String
        
        // Decode JSON data for photo URLs
        if let photoURLsData = record["photoURLs"] as? Data,
           let photoURLs = try? JSONSerialization.jsonObject(with: photoURLsData) as? [String] {
            entry.photoURLs = photoURLs
        }
        
        return entry
    }
}

// MARK: - Goal CloudKit Model
extension Goal: CloudKitModel {
    public static var recordType: String { "Goal" }
    
    public func toCKRecord() -> CKRecord {
        let recordID = CKRecord.ID(recordName: id?.uuidString ?? UUID().uuidString)
        let record = CKRecord(recordType: Self.recordType, recordID: recordID)
        
        record["title"] = title
        record["desc"] = desc
        record["category"] = category
        record["targetValue"] = targetValue
        record["currentValue"] = currentValue
        record["unit"] = unit
        record["startDate"] = startDate
        record["targetDate"] = targetDate
        record["status"] = status
        record["priority"] = priority
        record["isCompleted"] = isCompleted
        record["completedDate"] = completedDate
        record["createdAt"] = createdAt
        
        // Reference to User
        if let userID = user?.id?.uuidString {
            record["userReference"] = CKRecord.Reference(recordID: CKRecord.ID(recordName: userID), action: .deleteSelf)
        }
        
        return record
    }
    
    public static func fromCKRecord(_ record: CKRecord) -> Goal? {
        let context = CoreDataManager.shared.context
        let goal = Goal(context: context)
        
        guard let recordName = record.recordID.recordName,
              let id = UUID(uuidString: recordName) else { return nil }
        
        goal.id = id
        goal.title = record["title"] as? String ?? ""
        goal.desc = record["desc"] as? String
        goal.category = record["category"] as? String ?? ""
        goal.targetValue = record["targetValue"] as? Double ?? 0
        goal.currentValue = record["currentValue"] as? Double ?? 0
        goal.unit = record["unit"] as? String
        goal.startDate = record["startDate"] as? Date ?? Date()
        goal.targetDate = record["targetDate"] as? Date
        goal.status = record["status"] as? String ?? "active"
        goal.priority = record["priority"] as? String ?? "medium"
        goal.isCompleted = record["isCompleted"] as? Bool ?? false
        goal.completedDate = record["completedDate"] as? Date
        goal.createdAt = record["createdAt"] as? Date ?? Date()
        
        return goal
    }
}

// MARK: - Shared CloudKit Models for Coach-Client Collaboration

public struct SharedWorkout {
    public let id: UUID
    public let workoutTemplateID: UUID
    public let coachID: UUID
    public let clientID: UUID
    public let assignedDate: Date
    public let scheduledDate: Date?
    public let status: String
    public let notes: String?
    public let completedDate: Date?
    public let feedback: String?
}

extension SharedWorkout: CloudKitModel {
    public static var recordType: String { "SharedWorkout" }
    
    public func toCKRecord() -> CKRecord {
        let recordID = CKRecord.ID(recordName: id.uuidString)
        let record = CKRecord(recordType: Self.recordType, recordID: recordID)
        
        record["workoutTemplateID"] = workoutTemplateID.uuidString
        record["coachID"] = coachID.uuidString
        record["clientID"] = clientID.uuidString
        record["assignedDate"] = assignedDate
        record["scheduledDate"] = scheduledDate
        record["status"] = status
        record["notes"] = notes
        record["completedDate"] = completedDate
        record["feedback"] = feedback
        
        return record
    }
    
    public static func fromCKRecord(_ record: CKRecord) -> SharedWorkout? {
        guard let recordName = record.recordID.recordName,
              let id = UUID(uuidString: recordName),
              let workoutTemplateIDString = record["workoutTemplateID"] as? String,
              let workoutTemplateID = UUID(uuidString: workoutTemplateIDString),
              let coachIDString = record["coachID"] as? String,
              let coachID = UUID(uuidString: coachIDString),
              let clientIDString = record["clientID"] as? String,
              let clientID = UUID(uuidString: clientIDString),
              let assignedDate = record["assignedDate"] as? Date,
              let status = record["status"] as? String else { return nil }
        
        return SharedWorkout(
            id: id,
            workoutTemplateID: workoutTemplateID,
            coachID: coachID,
            clientID: clientID,
            assignedDate: assignedDate,
            scheduledDate: record["scheduledDate"] as? Date,
            status: status,
            notes: record["notes"] as? String,
            completedDate: record["completedDate"] as? Date,
            feedback: record["feedback"] as? String
        )
    }
}

public struct SharedMealPlan {
    public let id: UUID
    public let mealPlanTemplateID: UUID
    public let coachID: UUID
    public let clientID: UUID
    public let assignedDate: Date
    public let startDate: Date
    public let endDate: Date?
    public let status: String
    public let notes: String?
}

extension SharedMealPlan: CloudKitModel {
    public static var recordType: String { "SharedMealPlan" }
    
    public func toCKRecord() -> CKRecord {
        let recordID = CKRecord.ID(recordName: id.uuidString)
        let record = CKRecord(recordType: Self.recordType, recordID: recordID)
        
        record["mealPlanTemplateID"] = mealPlanTemplateID.uuidString
        record["coachID"] = coachID.uuidString
        record["clientID"] = clientID.uuidString
        record["assignedDate"] = assignedDate
        record["startDate"] = startDate
        record["endDate"] = endDate
        record["status"] = status
        record["notes"] = notes
        
        return record
    }
    
    public static func fromCKRecord(_ record: CKRecord) -> SharedMealPlan? {
        guard let recordName = record.recordID.recordName,
              let id = UUID(uuidString: recordName),
              let mealPlanTemplateIDString = record["mealPlanTemplateID"] as? String,
              let mealPlanTemplateID = UUID(uuidString: mealPlanTemplateIDString),
              let coachIDString = record["coachID"] as? String,
              let coachID = UUID(uuidString: coachIDString),
              let clientIDString = record["clientID"] as? String,
              let clientID = UUID(uuidString: clientIDString),
              let assignedDate = record["assignedDate"] as? Date,
              let startDate = record["startDate"] as? Date,
              let status = record["status"] as? String else { return nil }
        
        return SharedMealPlan(
            id: id,
            mealPlanTemplateID: mealPlanTemplateID,
            coachID: coachID,
            clientID: clientID,
            assignedDate: assignedDate,
            startDate: startDate,
            endDate: record["endDate"] as? Date,
            status: status,
            notes: record["notes"] as? String
        )
    }
}