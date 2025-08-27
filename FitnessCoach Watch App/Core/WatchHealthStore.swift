import Foundation
import HealthKit
import Combine

@MainActor
class WatchHealthKitManager: ObservableObject {
    @Published var isAuthorized = false
    @Published var heartRate: Double = 0
    @Published var activeEnergyBurned: Double = 0
    @Published var totalEnergyBurned: Double = 0
    @Published var distanceWalkingRunning: Double = 0
    @Published var stepCount: Int = 0
    @Published var currentWorkoutSession: HKWorkoutSession?
    @Published var workoutBuilder: HKLiveWorkoutBuilder?
    @Published var isWorkoutActive = false
    @Published var authorizationStatus: AuthorizationStatus = .notRequested
    
    private let healthStore = HKHealthStore()
    private var heartRateQuery: HKAnchoredObjectQuery?
    private var activeEnergyQuery: HKAnchoredObjectQuery?
    private var workoutSessionDelegate: WorkoutSessionDelegate?
    private var cancellables = Set<AnyCancellable>()
    
    enum AuthorizationStatus {
        case notRequested
        case requesting
        case authorized
        case denied
        case notAvailable
        
        var displayText: String {
            switch self {
            case .notRequested:
                return "Not Requested"
            case .requesting:
                return "Requesting..."
            case .authorized:
                return "Authorized"
            case .denied:
                return "Access Denied"
            case .notAvailable:
                return "Not Available"
            }
        }
    }
    
    init() {
        checkHealthKitAvailability()
    }
    
    // MARK: - Authorization
    
    private func checkHealthKitAvailability() {
        guard HKHealthStore.isHealthDataAvailable() else {
            authorizationStatus = .notAvailable
            return
        }
        
        // Check current authorization status
        checkAuthorizationStatus()
    }
    
    private func checkAuthorizationStatus() {
        let readTypes = Set([
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .basalEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .bodyMass)!,
            HKObjectType.quantityType(forIdentifier: .height)!
        ])
        
        let hasAuthorization = readTypes.allSatisfy { type in
            healthStore.authorizationStatus(for: type) == .sharingAuthorized
        }
        
        if hasAuthorization {
            authorizationStatus = .authorized
            isAuthorized = true
            startHealthDataCollection()
        }
    }
    
    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }
        
        authorizationStatus = .requesting
        
        let readTypes: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .basalEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .bodyMass)!,
            HKObjectType.quantityType(forIdentifier: .height)!
        ]
        
        let writeTypes: Set<HKSampleType> = [
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .basalEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKObjectType.quantityType(forIdentifier: .bodyMass)!,
            HKObjectType.workoutType()
        ]
        
        do {
            try await healthStore.requestAuthorization(toShare: writeTypes, read: readTypes)
            
            // Check if we got authorization
            let hasReadAuth = readTypes.allSatisfy { type in
                healthStore.authorizationStatus(for: type) == .sharingAuthorized
            }
            
            if hasReadAuth {
                authorizationStatus = .authorized
                isAuthorized = true
                startHealthDataCollection()
            } else {
                authorizationStatus = .denied
                isAuthorized = false
                throw HealthKitError.authorizationDenied
            }
            
        } catch {
            authorizationStatus = .denied
            isAuthorized = false
            throw error
        }
    }
    
    // MARK: - Real-time Health Data Collection
    
    private func startHealthDataCollection() {
        startHeartRateCollection()
        startActiveEnergyCollection()
        fetchTodayStepCount()
        fetchTodayDistance()
    }
    
    private func startHeartRateCollection() {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else { return }
        
        let predicate = HKQuery.predicateForSamples(
            withStart: Date(),
            end: nil,
            options: .strictEndDate
        )
        
        heartRateQuery = HKAnchoredObjectQuery(
            type: heartRateType,
            predicate: predicate,
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { [weak self] query, samples, deletedObjects, anchor, error in
            
            guard let self = self, error == nil else { return }
            
            DispatchQueue.main.async {
                if let heartRateSamples = samples as? [HKQuantitySample],
                   let mostRecent = heartRateSamples.last {
                    self.heartRate = mostRecent.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
                }
            }
        }
        
        heartRateQuery?.updateHandler = { [weak self] query, samples, deletedObjects, anchor, error in
            guard let self = self, error == nil else { return }
            
            DispatchQueue.main.async {
                if let heartRateSamples = samples as? [HKQuantitySample],
                   let mostRecent = heartRateSamples.last {
                    self.heartRate = mostRecent.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
                }
            }
        }
        
        healthStore.execute(heartRateQuery!)
    }
    
    private func startActiveEnergyCollection() {
        guard let activeEnergyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) else { return }
        
        let predicate = HKQuery.predicateForSamples(
            withStart: Calendar.current.startOfDay(for: Date()),
            end: nil,
            options: .strictEndDate
        )
        
        activeEnergyQuery = HKAnchoredObjectQuery(
            type: activeEnergyType,
            predicate: predicate,
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { [weak self] query, samples, deletedObjects, anchor, error in
            
            guard let self = self, error == nil else { return }
            
            DispatchQueue.main.async {
                if let energySamples = samples as? [HKQuantitySample] {
                    let totalEnergy = energySamples.reduce(0.0) { total, sample in
                        total + sample.quantity.doubleValue(for: .kilocalorie())
                    }
                    self.activeEnergyBurned = totalEnergy
                }
            }
        }
        
        activeEnergyQuery?.updateHandler = { [weak self] query, samples, deletedObjects, anchor, error in
            guard let self = self, error == nil else { return }
            
            DispatchQueue.main.async {
                if let energySamples = samples as? [HKQuantitySample] {
                    let totalEnergy = energySamples.reduce(0.0) { total, sample in
                        total + sample.quantity.doubleValue(for: .kilocalorie())
                    }
                    self.activeEnergyBurned = totalEnergy
                }
            }
        }
        
        healthStore.execute(activeEnergyQuery!)
    }
    
    // MARK: - Workout Session Management
    
    func startWorkoutSession(activityType: HKWorkoutActivityType) async throws {
        guard isAuthorized else {
            throw HealthKitError.notAuthorized
        }
        
        // Create workout configuration
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = activityType
        configuration.locationType = .outdoor // Can be changed based on workout type
        
        // Create workout session
        let session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
        
        // Create workout builder
        let builder = session.associatedWorkoutBuilder()
        builder.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: configuration)
        
        // Set up delegates
        workoutSessionDelegate = WorkoutSessionDelegate(healthKitManager: self)
        session.delegate = workoutSessionDelegate
        builder.delegate = workoutSessionDelegate
        
        currentWorkoutSession = session
        workoutBuilder = builder
        
        // Start the session
        session.startActivity(with: Date())
        try await builder.beginCollection(withStart: Date())
        
        isWorkoutActive = true
    }
    
    func endWorkoutSession() async throws {
        guard let session = currentWorkoutSession,
              let builder = workoutBuilder else {
            throw HealthKitError.noActiveWorkout
        }
        
        // End the session
        session.end()
        
        // End data collection
        try await builder.endCollection(withEnd: Date())
        
        // Save the workout
        do {
            let workout = try await builder.finishWorkout()
            print("Workout saved: \(workout)")
        } catch {
            print("Failed to save workout: \(error)")
            throw error
        }
        
        // Reset state
        currentWorkoutSession = nil
        workoutBuilder = nil
        isWorkoutActive = false
    }
    
    func pauseWorkoutSession() throws {
        guard let session = currentWorkoutSession else {
            throw HealthKitError.noActiveWorkout
        }
        
        session.pause()
    }
    
    func resumeWorkoutSession() throws {
        guard let session = currentWorkoutSession else {
            throw HealthKitError.noActiveWorkout
        }
        
        session.resume()
    }
    
    // MARK: - Data Queries
    
    private func fetchTodayStepCount() {
        guard let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) else { return }
        
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: Date(),
            options: .strictEndDate
        )
        
        let query = HKStatisticsQuery(
            quantityType: stepType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { [weak self] query, statistics, error in
            
            guard let self = self, error == nil else { return }
            
            DispatchQueue.main.async {
                if let sum = statistics?.sumQuantity() {
                    self.stepCount = Int(sum.doubleValue(for: .count()))
                }
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchTodayDistance() {
        guard let distanceType = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning) else { return }
        
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: Date(),
            options: .strictEndDate
        )
        
        let query = HKStatisticsQuery(
            quantityType: distanceType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { [weak self] query, statistics, error in
            
            guard let self = self, error == nil else { return }
            
            DispatchQueue.main.async {
                if let sum = statistics?.sumQuantity() {
                    self.distanceWalkingRunning = sum.doubleValue(for: .mile())
                }
            }
        }
        
        healthStore.execute(query)
    }
    
    func fetchLatestBodyWeight() async throws -> Double? {
        guard let weightType = HKObjectType.quantityType(forIdentifier: .bodyMass) else {
            throw HealthKitError.invalidType
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
            
            let query = HKSampleQuery(
                sampleType: weightType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { query, samples, error in
                
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                if let sample = samples?.first as? HKQuantitySample {
                    let weight = sample.quantity.doubleValue(for: .pound())
                    continuation.resume(returning: weight)
                } else {
                    continuation.resume(returning: nil)
                }
            }
            
            healthStore.execute(query)
        }
    }
    
    func saveBodyWeight(_ weight: Double) async throws {
        guard let weightType = HKObjectType.quantityType(forIdentifier: .bodyMass) else {
            throw HealthKitError.invalidType
        }
        
        let quantity = HKQuantity(unit: .pound(), doubleValue: weight)
        let sample = HKQuantitySample(
            type: weightType,
            quantity: quantity,
            start: Date(),
            end: Date()
        )
        
        try await healthStore.save(sample)
    }
    
    // MARK: - Activity Rings Data
    
    func fetchActivityRingsData(for date: Date = Date()) async throws -> ActivityRingsData {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
        
        // Fetch active energy
        let activeEnergy = try await fetchSum(
            for: HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            predicate: predicate,
            unit: .kilocalorie()
        )
        
        // Fetch exercise time (approximated from workout data)
        let exerciseMinutes = try await fetchExerciseMinutes(for: date)
        
        // Fetch stand hours (approximated)
        let standHours = try await fetchStandHours(for: date)
        
        return ActivityRingsData(
            activeEnergy: activeEnergy,
            exerciseMinutes: exerciseMinutes,
            standHours: standHours
        )
    }
    
    private func fetchSum(for type: HKQuantityType, predicate: NSPredicate, unit: HKUnit) async throws -> Double {
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { query, statistics, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let sum = statistics?.sumQuantity() {
                    continuation.resume(returning: sum.doubleValue(for: unit))
                } else {
                    continuation.resume(returning: 0.0)
                }
            }
            healthStore.execute(query)
        }
    }
    
    private func fetchExerciseMinutes(for date: Date) async throws -> Double {
        // This is a simplified version - in a real app you'd want to track actual exercise minutes
        return 0.0
    }
    
    private func fetchStandHours(for date: Date) async throws -> Double {
        // This is a simplified version - in a real app you'd want to track actual stand hours
        return 0.0
    }
    
    // MARK: - Cleanup
    
    deinit {
        heartRateQuery?.stop()
        activeEnergyQuery?.stop()
    }
}

// MARK: - Workout Session Delegate

class WorkoutSessionDelegate: NSObject, HKWorkoutSessionDelegate, HKLiveWorkoutBuilderDelegate {
    weak var healthKitManager: WatchHealthKitManager?
    
    init(healthKitManager: WatchHealthKitManager) {
        self.healthKitManager = healthKitManager
        super.init()
    }
    
    // MARK: - HKWorkoutSessionDelegate
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        Task { @MainActor in
            switch toState {
            case .running:
                print("Workout started")
            case .ended:
                print("Workout ended")
                healthKitManager?.isWorkoutActive = false
            case .paused:
                print("Workout paused")
            default:
                break
            }
        }
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("Workout session failed: \(error)")
        Task { @MainActor in
            healthKitManager?.isWorkoutActive = false
        }
    }
    
    // MARK: - HKLiveWorkoutBuilderDelegate
    
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        // Handle collected workout data
        for type in collectedTypes {
            if type == HKObjectType.quantityType(forIdentifier: .heartRate) {
                let statistics = workoutBuilder.statistics(for: type)
                let heartRate = statistics?.mostRecentQuantity()?.doubleValue(for: HKUnit.count().unitDivided(by: .minute())) ?? 0
                
                Task { @MainActor in
                    healthKitManager?.heartRate = heartRate
                }
            }
        }
    }
    
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
        // Handle workout events
    }
}

// MARK: - Supporting Types

enum HealthKitError: Error, LocalizedError {
    case notAvailable
    case notAuthorized
    case authorizationDenied
    case noActiveWorkout
    case invalidType
    
    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "HealthKit is not available on this device"
        case .notAuthorized:
            return "HealthKit access not authorized"
        case .authorizationDenied:
            return "HealthKit authorization was denied"
        case .noActiveWorkout:
            return "No active workout session"
        case .invalidType:
            return "Invalid HealthKit data type"
        }
    }
}

struct ActivityRingsData {
    let activeEnergy: Double
    let exerciseMinutes: Double
    let standHours: Double
    
    // Activity ring goals (these would typically come from HealthKit or user preferences)
    let activeEnergyGoal: Double = 400.0 // kcal
    let exerciseMinutesGoal: Double = 30.0 // minutes
    let standHoursGoal: Double = 12.0 // hours
    
    var activeEnergyProgress: Double {
        min(activeEnergy / activeEnergyGoal, 1.0)
    }
    
    var exerciseMinutesProgress: Double {
        min(exerciseMinutes / exerciseMinutesGoal, 1.0)
    }
    
    var standHoursProgress: Double {
        min(standHours / standHoursGoal, 1.0)
    }
}