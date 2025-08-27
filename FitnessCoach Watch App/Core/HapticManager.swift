import Foundation
import WatchKit

@MainActor
class HapticManager: ObservableObject {
    @Published var isHapticEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isHapticEnabled, forKey: "enableHapticFeedback")
        }
    }
    
    private let device = WKInterfaceDevice.current()
    
    // Haptic feedback types
    enum HapticType {
        case notification(NotificationFeedbackType)
        case impact(ImpactFeedbackType)
        case click
        case directionalUp
        case directionalDown
        case success
        case failure
        case retry
        
        enum NotificationFeedbackType {
            case success
            case warning
            case failure
        }
        
        enum ImpactFeedbackType {
            case light
            case medium
            case heavy
        }
    }
    
    // Workout-specific haptic patterns
    enum WorkoutHaptic {
        case workoutStart
        case workoutEnd
        case exerciseComplete
        case restTimerEnd
        case heartRateAlert
        case goalAchieved
        case newPersonalRecord
        case countdownTick
        case setComplete
    }
    
    init() {
        self.isHapticEnabled = UserDefaults.standard.bool(forKey: "enableHapticFeedback")
        
        // Set default to true if not previously set
        if UserDefaults.standard.object(forKey: "enableHapticFeedback") == nil {
            self.isHapticEnabled = true
        }
    }
    
    // MARK: - Basic Haptic Methods
    
    func play(_ hapticType: HapticType) {
        guard isHapticEnabled else { return }
        
        switch hapticType {
        case .notification(let type):
            playNotificationHaptic(type)
        case .impact(let type):
            playImpactHaptic(type)
        case .click:
            device.play(.click)
        case .directionalUp:
            device.play(.directionalUp)
        case .directionalDown:
            device.play(.directionalDown)
        case .success:
            device.play(.success)
        case .failure:
            device.play(.failure)
        case .retry:
            device.play(.retry)
        }
    }
    
    private func playNotificationHaptic(_ type: HapticType.NotificationFeedbackType) {
        switch type {
        case .success:
            device.play(.notification)
        case .warning:
            device.play(.notification)
        case .failure:
            device.play(.notification)
        }
    }
    
    private func playImpactHaptic(_ type: HapticType.ImpactFeedbackType) {
        switch type {
        case .light:
            device.play(.click)
        case .medium:
            device.play(.click)
        case .heavy:
            device.play(.click)
        }
    }
    
    // MARK: - Workout-Specific Haptics
    
    func playWorkoutHaptic(_ workoutHaptic: WorkoutHaptic) {
        guard isHapticEnabled else { return }
        
        switch workoutHaptic {
        case .workoutStart:
            // Three quick taps to signal workout start
            playHapticSequence([.success, .success, .success], intervals: [0, 0.1, 0.2])
            
        case .workoutEnd:
            // Two long pulses to signal workout end
            playHapticSequence([.success, .success], intervals: [0, 0.5])
            
        case .exerciseComplete:
            play(.notification(.success))
            
        case .restTimerEnd:
            // Urgent double tap
            playHapticSequence([.failure, .failure], intervals: [0, 0.1])
            
        case .heartRateAlert:
            play(.notification(.warning))
            
        case .goalAchieved:
            // Celebration pattern - multiple success haptics
            playHapticSequence([.success, .success, .success, .success], intervals: [0, 0.1, 0.2, 0.4])
            
        case .newPersonalRecord:
            // Extended celebration pattern
            playHapticSequence([
                .success, .success, .success, .success, .success
            ], intervals: [0, 0.1, 0.2, 0.4, 0.6])
            
        case .countdownTick:
            play(.click)
            
        case .setComplete:
            play(.impact(.medium))
        }
    }
    
    // MARK: - Complex Haptic Patterns
    
    private func playHapticSequence(_ haptics: [WKHapticType], intervals: [TimeInterval]) {
        guard haptics.count == intervals.count else { return }
        
        for (index, haptic) in haptics.enumerated() {
            let interval = intervals[index]
            
            if interval == 0 {
                device.play(haptic)
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + interval) {
                    self.device.play(haptic)
                }
            }
        }
    }
    
    // MARK: - Context-Specific Methods
    
    func playMenuNavigationHaptic() {
        play(.click)
    }
    
    func playValueChangeHaptic() {
        play(.directionalUp)
    }
    
    func playErrorHaptic() {
        play(.failure)
    }
    
    func playSuccessHaptic() {
        play(.success)
    }
    
    func playSelectionHaptic() {
        play(.impact(.light))
    }
    
    func playButtonPressHaptic() {
        play(.impact(.medium))
    }
    
    // MARK: - Timer-Related Haptics
    
    func playCountdownSequence(from seconds: Int) {
        guard isHapticEnabled, seconds > 0 else { return }
        
        for i in 0..<seconds {
            let delay = TimeInterval(i)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                if i == seconds - 1 {
                    // Final countdown tick is more emphatic
                    self.play(.impact(.heavy))
                } else {
                    self.play(.click)
                }
            }
        }
    }
    
    func playRestTimerPattern(timeRemaining: TimeInterval) {
        // Different haptic patterns based on time remaining
        if timeRemaining <= 5 && timeRemaining > 0 {
            // Final countdown
            let remaining = Int(ceil(timeRemaining))
            playCountdownSequence(from: remaining)
        } else if timeRemaining == 30 {
            // 30 second warning
            play(.notification(.warning))
        } else if timeRemaining == 10 {
            // 10 second warning
            playHapticSequence([.click, .click], intervals: [0, 0.1])
        }
    }
    
    // MARK: - Achievement Haptics
    
    func playAchievementUnlocked() {
        // Special pattern for achievement unlocks
        let pattern: [WKHapticType] = [.success, .success, .notification, .success]
        let intervals: [TimeInterval] = [0, 0.1, 0.3, 0.5]
        playHapticSequence(pattern, intervals: intervals)
    }
    
    func playStreakMilestone(_ streak: Int) {
        // Escalating celebration based on streak length
        let celebrationLength = min(streak / 5 + 2, 6) // Max 6 haptics
        let haptics = Array(repeating: WKHapticType.success, count: celebrationLength)
        let intervals = (0..<celebrationLength).map { TimeInterval($0) * 0.1 }
        playHapticSequence(haptics, intervals: intervals)
    }
    
    // MARK: - Digital Crown Haptics
    
    func playDigitalCrownTick() {
        play(.directionalUp)
    }
    
    func playDigitalCrownBoundary() {
        play(.impact(.heavy))
    }
    
    // MARK: - Settings
    
    func testHaptic() {
        playWorkoutHaptic(.goalAchieved)
    }
    
    func enableHaptics() {
        isHapticEnabled = true
    }
    
    func disableHaptics() {
        isHapticEnabled = false
    }
}