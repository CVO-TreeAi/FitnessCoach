import Foundation
import CoreData

@MainActor
class DataSeeder {
    static let shared = DataSeeder()
    private let coreDataManager = CoreDataManager.shared
    
    private init() {}
    
    func seedInitialData() {
        // Check if data already exists
        let context = coreDataManager.context
        
        // Check for existing food items
        let foodRequest = NSFetchRequest<NSManagedObject>(entityName: "FoodItem")
        foodRequest.fetchLimit = 1
        
        do {
            let count = try context.count(for: foodRequest)
            if count > 0 {
                print("Data already seeded")
                return
            }
        } catch {
            print("Error checking for existing data: \(error)")
        }
        
        // Seed data
        seedFoodDatabase()
        seedExerciseDatabase()
        
        // Save all changes
        coreDataManager.save()
        print("✅ Sample data seeded successfully!")
    }
    
    // MARK: - Food Database Seeding
    
    private func seedFoodDatabase() {
        let context = coreDataManager.context
        
        let sampleFoods = [
            ("Chicken Breast", "Protein", 30.0, 0.0, 3.6, 165.0),
            ("Brown Rice", "Grains", 2.6, 22.9, 0.9, 112.0),
            ("Avocado", "Fats", 2.0, 8.5, 14.7, 160.0),
            ("Broccoli", "Vegetables", 2.8, 7.0, 0.4, 34.0),
            ("Salmon", "Protein", 22.0, 0.0, 12.4, 206.0),
            ("Greek Yogurt", "Dairy", 10.0, 3.6, 0.4, 59.0),
            ("Banana", "Fruits", 1.1, 22.8, 0.3, 89.0),
            ("Almonds", "Nuts", 21.2, 21.7, 49.4, 579.0),
            ("Sweet Potato", "Vegetables", 1.6, 20.1, 0.1, 86.0),
            ("Eggs", "Protein", 13.0, 1.1, 11.0, 155.0)
        ]
        
        for (name, category, protein, carbs, fat, calories) in sampleFoods {
            guard let entity = NSEntityDescription.entity(forEntityName: "FoodItem", in: context) else {
                print("FoodItem entity not found in Core Data model")
                continue
            }
            
            let foodItem = NSManagedObject(entity: entity, insertInto: context)
            foodItem.setValue(UUID(), forKey: "id")
            foodItem.setValue(name, forKey: "name")
            foodItem.setValue(category, forKey: "category")
            foodItem.setValue(protein, forKey: "protein")
            foodItem.setValue(carbs, forKey: "carbohydrates")
            foodItem.setValue(fat, forKey: "fat")
            foodItem.setValue(calories, forKey: "calories")
            foodItem.setValue("100g", forKey: "servingSize")
            foodItem.setValue(Date(), forKey: "createdAt")
            foodItem.setValue(Date(), forKey: "updatedAt")
        }
        
        print("✅ Food database seeded with \(sampleFoods.count) items")
    }
    
    // MARK: - Exercise Database Seeding
    
    private func seedExerciseDatabase() {
        let context = coreDataManager.context
        
        let sampleExercises = [
            ("Push-ups", "Strength", "Chest", 1, nil),
            ("Squats", "Strength", "Legs", 2, nil),
            ("Running", "Cardio", "Full Body", 1, nil),
            ("Plank", "Core", "Core", 1, nil),
            ("Deadlift", "Strength", "Back", 3, "Barbell"),
            ("Bench Press", "Strength", "Chest", 2, "Barbell"),
            ("Pull-ups", "Strength", "Back", 3, "Pull-up Bar"),
            ("Lunges", "Strength", "Legs", 2, nil),
            ("Bicep Curls", "Strength", "Arms", 1, "Dumbbells"),
            ("Burpees", "HIIT", "Full Body", 3, nil)
        ]
        
        for (name, category, muscleGroup, difficulty, equipment) in sampleExercises {
            guard let entity = NSEntityDescription.entity(forEntityName: "Exercise", in: context) else {
                print("Exercise entity not found in Core Data model")
                continue
            }
            
            let exercise = NSManagedObject(entity: entity, insertInto: context)
            exercise.setValue(UUID(), forKey: "id")
            exercise.setValue(name, forKey: "name")
            exercise.setValue(category, forKey: "category")
            exercise.setValue(muscleGroup, forKey: "muscleGroup")
            exercise.setValue(Int16(difficulty), forKey: "difficulty")
            exercise.setValue(equipment, forKey: "equipment")
            exercise.setValue(Date(), forKey: "createdAt")
            exercise.setValue(Date(), forKey: "updatedAt")
        }
        
        print("✅ Exercise database seeded with \(sampleExercises.count) items")
    }
    
    // MARK: - Helper Methods
    
    func clearAllData() {
        let entityNames = ["FoodItem", "Exercise", "User", "WorkoutSession", "NutritionEntry", "ProgressEntry", "Goal"]
        
        for entityName in entityNames {
            coreDataManager.deleteAll(entityName: entityName)
        }
        
        print("All data cleared")
    }
    
    func resetAndReseed() {
        clearAllData()
        seedInitialData()
    }
}