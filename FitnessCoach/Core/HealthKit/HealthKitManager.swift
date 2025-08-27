import Foundation
import HealthKit
import Combine

@MainActor
public class HealthKitManager: ObservableObject {
    @Published public var isAuthorized = false
    @Published public var healthStore: HKHealthStore?
    
    public init() {
        if HKHealthStore.isHealthDataAvailable() {
            healthStore = HKHealthStore()
        }
    }
    
    public func requestAuthorization() async throws {
        guard let healthStore = healthStore else {
            throw HealthKitError.notAvailable
        }
        
        let typesToRead: Set<HKObjectType> = [
            HKQuantityType.quantityType(forIdentifier: .bodyMass)!,
            HKQuantityType.quantityType(forIdentifier: .height)!,
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .bloodPressureSystolic)!,
            HKQuantityType.quantityType(forIdentifier: .bloodPressureDiastolic)!,
            HKQuantityType.quantityType(forIdentifier: .bodyFatPercentage)!,
            HKQuantityType.quantityType(forIdentifier: .leanBodyMass)!,
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKQuantityType.quantityType(forIdentifier: .basalEnergyBurned)!,
            HKWorkoutType.workoutType()
        ]
        
        let typesToWrite: Set<HKSampleType> = [
            HKQuantityType.quantityType(forIdentifier: .bodyMass)!,
            HKQuantityType.quantityType(forIdentifier: .bodyFatPercentage)!,
            HKWorkoutType.workoutType()
        ]
        
        try await healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead)
        isAuthorized = true
    }
    
    // MARK: - Weight Management
    public func saveWeight(_ weight: Double, date: Date = Date()) async throws {
        guard let healthStore = healthStore else {
            throw HealthKitError.notAvailable
        }
        
        let weightQuantity = HKQuantity(unit: .pound(), doubleValue: weight)
        let weightSample = HKQuantitySample(
            type: HKQuantityType.quantityType(forIdentifier: .bodyMass)!,
            quantity: weightQuantity,
            start: date,
            end: date
        )
        
        try await healthStore.save(weightSample)
    }
    
    public func fetchLatestWeight() async throws -> Double? {
        guard let healthStore = healthStore else {
            throw HealthKitError.notAvailable
        }
        
        let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass)!
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(
            sampleType: weightType,
            predicate: nil,
            limit: 1,
            sortDescriptors: [sortDescriptor]
        ) { _, samples, error in
            // Handle in completion
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: weightType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let weight = sample.quantity.doubleValue(for: .pound())
                continuation.resume(returning: weight)
            }
            
            healthStore.execute(query)
        }
    }
    
    public func fetchWeightHistory(days: Int = 30) async throws -> [WeightEntry] {
        guard let healthStore = healthStore else {
            throw HealthKitError.notAvailable
        }
        
        let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass)!
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: endDate)!
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: weightType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                let entries = samples?.compactMap { sample -> WeightEntry? in
                    guard let quantitySample = sample as? HKQuantitySample else { return nil }
                    return WeightEntry(
                        date: quantitySample.endDate,
                        weight: quantitySample.quantity.doubleValue(for: .pound())
                    )
                } ?? []
                
                continuation.resume(returning: entries)
            }
            
            healthStore.execute(query)
        }
    }
    
    // MARK: - Workout Management
    public func saveWorkout(_ workout: WorkoutData) async throws {
        guard let healthStore = healthStore else {
            throw HealthKitError.notAvailable
        }
        
        let hkWorkout = HKWorkout(
            activityType: workout.activityType,
            start: workout.startDate,
            end: workout.endDate,
            duration: workout.duration,
            totalEnergyBurned: workout.caloriesBurned.map { HKQuantity(unit: .kilocalorie(), doubleValue: $0) },
            totalDistance: nil,
            metadata: workout.metadata
        )
        
        try await healthStore.save(hkWorkout)
    }
    
    public func fetchRecentWorkouts(limit: Int = 10) async throws -> [HKWorkout] {
        guard let healthStore = healthStore else {
            throw HealthKitError.notAvailable
        }
        
        let workoutType = HKWorkoutType.workoutType()
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: workoutType,
                predicate: nil,
                limit: limit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                let workouts = samples?.compactMap { $0 as? HKWorkout } ?? []
                continuation.resume(returning: workouts)
            }
            
            healthStore.execute(query)
        }
    }
}

// MARK: - Supporting Types
public struct WeightEntry {
    public let date: Date
    public let weight: Double
    
    public init(date: Date, weight: Double) {
        self.date = date
        self.weight = weight
    }
}

public struct WorkoutData {
    public let activityType: HKWorkoutActivityType
    public let startDate: Date
    public let endDate: Date
    public let duration: TimeInterval
    public let caloriesBurned: Double?
    public let metadata: [String: Any]?
    
    public init(
        activityType: HKWorkoutActivityType,
        startDate: Date,
        endDate: Date,
        duration: TimeInterval,
        caloriesBurned: Double? = nil,
        metadata: [String: Any]? = nil
    ) {
        self.activityType = activityType
        self.startDate = startDate
        self.endDate = endDate
        self.duration = duration
        self.caloriesBurned = caloriesBurned
        self.metadata = metadata
    }
}

public enum HealthKitError: Error {
    case notAvailable
    case authorizationDenied
    case dataNotFound
}

extension HealthKitError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "HealthKit is not available on this device"
        case .authorizationDenied:
            return "HealthKit access was denied"
        case .dataNotFound:
            return "Requested health data not found"
        }
    }
}