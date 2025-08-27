import Foundation
import HealthKit
import WatchKit
import Combine

@MainActor
class WorkoutManager: NSObject, ObservableObject {
    @Published var currentSession: WorkoutSession?
    @Published var heartRate: Double = 0
    @Published var calories: Double = 0
    @Published var elapsedTime: TimeInterval = 0
    @Published var isWorkoutActive = false
    @Published var workoutState: WorkoutState = .inactive
    
    private var healthStore: HKHealthStore
    private var workoutSession: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?
    private var timer: Timer?
    
    enum WorkoutState {
        case inactive
        case preparing
        case active
        case paused
        case ended
    }
    
    override init() {
        self.healthStore = HKHealthStore()
        super.init()
    }
    
    // MARK: - Workout Session Management
    
    func startWorkout(type: HKWorkoutActivityType, name: String) {
        guard workoutState == .inactive else { return }
        
        let workoutId = UUID()
        currentSession = WorkoutSession(workoutId: workoutId, activityType: type)
        
        workoutState = .preparing
        
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = type
        configuration.locationType = .indoor
        
        do {
            workoutSession = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            workoutSession?.delegate = self
            
            builder = workoutSession?.associatedWorkoutBuilder()
            builder?.delegate = self
            
            // Enable automatic data collection
            builder?.dataSource = HKLiveWorkoutDataSource(
                healthStore: healthStore,
                workoutConfiguration: configuration
            )
            
            // Start the session
            workoutSession?.startActivity(with: Date())
            
            // Provide haptic feedback
            WKInterfaceDevice.current().play(.start)
            
            // Start timer for elapsed time
            startTimer()
            
            isWorkoutActive = true
            workoutState = .active
            
        } catch {
            print("Failed to start workout: \(error)")
            workoutState = .inactive
        }
    }
    
    func pauseWorkout() {
        guard workoutState == .active else { return }
        
        workoutSession?.pause()
        stopTimer()
        workoutState = .paused
        
        WKInterfaceDevice.current().play(.click)
    }
    
    func resumeWorkout() {
        guard workoutState == .paused else { return }
        
        workoutSession?.resume()
        startTimer()
        workoutState = .active
        
        WKInterfaceDevice.current().play(.click)
    }
    
    func endWorkout() {
        guard isWorkoutActive else { return }
        
        workoutSession?.end()
        stopTimer()
        
        // End the current session
        currentSession?.end()
        
        workoutState = .ended
        isWorkoutActive = false
        
        WKInterfaceDevice.current().play(.stop)
        
        // Save workout data
        if let session = currentSession {
            saveWorkoutSession(session)
        }
    }
    
    // MARK: - Timer Management
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                self.elapsedTime += 1
                self.currentSession?.duration = self.elapsedTime
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    // MARK: - Data Saving
    
    private func saveWorkoutSession(_ session: WorkoutSession) {
        Task {
            do {
                let workout = HKWorkout(
                    activityType: session.hkActivityType,
                    start: session.startTime,
                    end: session.endTime ?? Date(),
                    duration: session.duration,
                    totalEnergyBurned: HKQuantity(unit: .kilocalorie(), doubleValue: session.caloriesBurned),
                    totalDistance: nil,
                    metadata: [
                        HKMetadataKeyWorkoutBrandName: "FitnessCoach",
                        "SessionId": session.id.uuidString
                    ]
                )
                
                try await healthStore.save(workout)
                print("Workout saved successfully")
                
            } catch {
                print("Failed to save workout: \(error)")
            }
        }
    }
    
    // MARK: - Heart Rate Monitoring
    
    func addHeartRateReading(_ heartRate: Double) {
        let reading = WatchHeartRateReading(
            heartRate: heartRate,
            workoutId: currentSession?.workoutId
        )
        
        currentSession?.addHeartRateReading(reading)
        self.heartRate = heartRate
        
        // Provide haptic feedback for heart rate zones
        provideHeartRateZoneFeedback(heartRate)
    }
    
    private func provideHeartRateZoneFeedback(_ heartRate: Double) {
        // Estimated max heart rate (220 - age), using 180 as default
        let maxHeartRate: Double = 180
        let percentage = heartRate / maxHeartRate
        
        switch percentage {
        case 0.9...:
            // Very High Intensity Zone
            WKInterfaceDevice.current().play(.failure)
        case 0.8..<0.9:
            // High Intensity Zone
            WKInterfaceDevice.current().play(.notification)
        case 0.7..<0.8:
            // Moderate Intensity Zone
            WKInterfaceDevice.current().play(.success)
        default:
            // Low Intensity Zone - no feedback
            break
        }
    }
    
    // MARK: - Workout Presets
    
    func getWorkoutPresets() -> [WorkoutPreset] {
        return [
            WorkoutPreset(
                name: "Strength Training",
                activityType: .traditionalStrengthTraining,
                icon: "dumbbell",
                color: .orange
            ),
            WorkoutPreset(
                name: "HIIT",
                activityType: .highIntensityIntervalTraining,
                icon: "flame",
                color: .red
            ),
            WorkoutPreset(
                name: "Cardio",
                activityType: .other,
                icon: "heart",
                color: .pink
            ),
            WorkoutPreset(
                name: "Yoga",
                activityType: .yoga,
                icon: "leaf",
                color: .green
            ),
            WorkoutPreset(
                name: "Running",
                activityType: .running,
                icon: "figure.run",
                color: .blue
            ),
            WorkoutPreset(
                name: "Cycling",
                activityType: .cycling,
                icon: "bicycle",
                color: .purple
            )
        ]
    }
}

// MARK: - HKWorkoutSessionDelegate

extension WorkoutManager: HKWorkoutSessionDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        DispatchQueue.main.async {
            switch toState {
            case .running:
                self.workoutState = .active
            case .paused:
                self.workoutState = .paused
            case .ended:
                self.workoutState = .ended
                self.isWorkoutActive = false
            default:
                break
            }
        }
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("Workout session failed: \(error)")
        DispatchQueue.main.async {
            self.workoutState = .inactive
            self.isWorkoutActive = false
        }
    }
}

// MARK: - HKLiveWorkoutBuilderDelegate

extension WorkoutManager: HKLiveWorkoutBuilderDelegate {
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType else { continue }
            
            let statistics = workoutBuilder.statistics(for: quantityType)
            
            DispatchQueue.main.async {
                self.updateForStatistics(statistics)
            }
        }
    }
    
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
        // Handle workout events if needed
    }
    
    private func updateForStatistics(_ statistics: HKStatistics?) {
        guard let statistics = statistics else { return }
        
        switch statistics.quantityType {
        case HKQuantityType.quantityType(forIdentifier: .heartRate):
            if let heartRateUnit = HKUnit.count().unitDivided(by: .minute()),
               let heartRate = statistics.mostRecentQuantity()?.doubleValue(for: heartRateUnit) {
                addHeartRateReading(heartRate)
            }
            
        case HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned):
            if let calorieUnit = HKUnit.kilocalorie(),
               let calories = statistics.sumQuantity()?.doubleValue(for: calorieUnit) {
                self.calories = calories
                currentSession?.caloriesBurned = calories
            }
            
        default:
            break
        }
    }
}

// MARK: - Supporting Types

struct WorkoutPreset {
    let name: String
    let activityType: HKWorkoutActivityType
    let icon: String
    let color: Color
}

import SwiftUI

extension Color {
    static let orange = Color.orange
    static let red = Color.red
    static let pink = Color.pink
    static let green = Color.green
    static let blue = Color.blue
    static let purple = Color.purple
}