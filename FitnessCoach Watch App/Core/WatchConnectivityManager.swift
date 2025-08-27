import Foundation
import WatchConnectivity
import Combine

@MainActor
class WatchConnectivityManager: NSObject, ObservableObject {
    @Published var isConnected = false
    @Published var userStats = WatchUserStats()
    @Published var recentWorkouts: [WatchWorkout] = []
    @Published var lastSync = Date()
    @Published var connectionStatus: ConnectionStatus = .disconnected
    
    private var session: WCSession?
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    enum ConnectionStatus {
        case disconnected
        case connecting
        case connected
        case error(String)
        
        var displayText: String {
            switch self {
            case .disconnected:
                return "Disconnected"
            case .connecting:
                return "Connecting..."
            case .connected:
                return "Connected"
            case .error(let message):
                return "Error: \(message)"
            }
        }
    }
    
    override init() {
        super.init()
        setupWatchConnectivity()
    }
    
    // MARK: - Setup
    
    private func setupWatchConnectivity() {
        guard WCSession.isSupported() else {
            print("WCSession not supported")
            return
        }
        
        session = WCSession.default
        session?.delegate = self
    }
    
    func startSession() {
        guard let session = session else { return }
        
        connectionStatus = .connecting
        session.activate()
    }
    
    // MARK: - Data Synchronization
    
    func syncWithPhone() async {
        guard let session = session, session.isReachable else {
            print("iPhone not reachable")
            return
        }
        
        let message = WatchMessage(type: .requestSync)
        
        do {
            let data = try encoder.encode(message)
            let messageDict = ["message": data]
            
            _ = try await session.sendMessage(messageDict, replyHandler: nil)
            lastSync = Date()
            
        } catch {
            print("Failed to sync with phone: \(error)")
            connectionStatus = .error(error.localizedDescription)
        }
    }
    
    func sendWorkoutData(_ workout: WatchWorkout) {
        guard let session = session, session.isReachable else {
            // Store workout locally for later sync
            storeWorkoutForLaterSync(workout)
            return
        }
        
        do {
            let workoutData = try encoder.encode(workout)
            let message = WatchMessage(type: .workoutSync, data: workoutData)
            let messageData = try encoder.encode(message)
            
            session.sendMessageData(messageData) { replyData in
                Task { @MainActor in
                    print("Workout synced successfully")
                }
            } errorHandler: { error in
                Task { @MainActor in
                    print("Failed to sync workout: \(error)")
                    self.storeWorkoutForLaterSync(workout)
                }
            }
            
        } catch {
            print("Failed to encode workout data: \(error)")
            storeWorkoutForLaterSync(workout)
        }
    }
    
    func sendHeartRateUpdate(_ heartRateReading: WatchHeartRateReading) {
        guard let session = session, session.isReachable else { return }
        
        do {
            let heartRateData = try encoder.encode(heartRateReading)
            let message = WatchMessage(type: .heartRateUpdate, data: heartRateData)
            let messageData = try encoder.encode(message)
            
            session.sendMessageData(messageData, replyHandler: nil) { error in
                print("Failed to send heart rate update: \(error)")
            }
            
        } catch {
            print("Failed to encode heart rate data: \(error)")
        }
    }
    
    // MARK: - Local Storage for Offline Sync
    
    private func storeWorkoutForLaterSync(_ workout: WatchWorkout) {
        let userDefaults = UserDefaults.standard
        var pendingWorkouts = getPendingWorkouts()
        pendingWorkouts.append(workout)
        
        do {
            let data = try encoder.encode(pendingWorkouts)
            userDefaults.set(data, forKey: "pendingWorkouts")
        } catch {
            print("Failed to store pending workout: \(error)")
        }
    }
    
    private func getPendingWorkouts() -> [WatchWorkout] {
        let userDefaults = UserDefaults.standard
        guard let data = userDefaults.data(forKey: "pendingWorkouts") else { return [] }
        
        do {
            return try decoder.decode([WatchWorkout].self, from: data)
        } catch {
            print("Failed to decode pending workouts: \(error)")
            return []
        }
    }
    
    private func clearPendingWorkouts() {
        UserDefaults.standard.removeObject(forKey: "pendingWorkouts")
    }
    
    private func syncPendingWorkouts() {
        let pendingWorkouts = getPendingWorkouts()
        guard !pendingWorkouts.isEmpty else { return }
        
        for workout in pendingWorkouts {
            sendWorkoutData(workout)
        }
        
        // Clear pending workouts after attempting to sync
        clearPendingWorkouts()
    }
    
    // MARK: - Settings Sync
    
    func syncSettings(_ settings: WatchSettings) {
        guard let session = session else { return }
        
        do {
            let settingsData = try encoder.encode(settings)
            let context = ["settings": settingsData]
            
            try session.updateApplicationContext(context)
            
        } catch {
            print("Failed to sync settings: \(error)")
        }
    }
    
    // MARK: - Complication Updates
    
    func updateComplications(with data: ComplicationData) {
        guard let session = session else { return }
        
        do {
            let complicationData = try encoder.encode(data)
            let userInfo = ["complicationData": complicationData]
            
            session.transferUserInfo(userInfo)
            
        } catch {
            print("Failed to update complications: \(error)")
        }
    }
    
    // MARK: - Message Handling
    
    private func handleMessage(_ messageData: Data) {
        do {
            let message = try decoder.decode(WatchMessage.self, from: messageData)
            
            switch message.type {
            case .statsUpdate:
                if let data = message.data {
                    let stats = try decoder.decode(WatchUserStats.self, from: data)
                    userStats = stats
                    lastSync = Date()
                }
                
            case .workoutSync:
                if let data = message.data {
                    let workouts = try decoder.decode([WatchWorkout].self, from: data)
                    recentWorkouts = workouts
                }
                
            case .complicationUpdate:
                if let data = message.data {
                    let complicationData = try decoder.decode(ComplicationData.self, from: data)
                    updateWatchComplications(with: complicationData)
                }
                
            default:
                print("Unhandled message type: \(message.type)")
            }
            
        } catch {
            print("Failed to handle message: \(error)")
        }
    }
    
    private func updateWatchComplications(with data: ComplicationData) {
        // This would update complications if we had access to ClockKit
        // For now, we'll store the data for access by complications
        do {
            let data = try encoder.encode(data)
            UserDefaults.standard.set(data, forKey: "complicationData")
        } catch {
            print("Failed to store complication data: \(error)")
        }
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            if let error = error {
                self.connectionStatus = .error(error.localizedDescription)
                self.isConnected = false
            } else {
                switch activationState {
                case .activated:
                    self.connectionStatus = .connected
                    self.isConnected = session.isPaired && session.isWatchAppInstalled
                    
                    // Sync pending workouts when connection is established
                    self.syncPendingWorkouts()
                    
                case .inactive:
                    self.connectionStatus = .disconnected
                    self.isConnected = false
                    
                case .notActivated:
                    self.connectionStatus = .disconnected
                    self.isConnected = false
                    
                @unknown default:
                    self.connectionStatus = .disconnected
                    self.isConnected = false
                }
            }
        }
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isConnected = session.isReachable
            
            if session.isReachable {
                self.connectionStatus = .connected
                // Attempt to sync when reachability is restored
                Task {
                    await self.syncWithPhone()
                }
            } else {
                self.connectionStatus = .disconnected
            }
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        guard let messageData = message["message"] as? Data else { return }
        
        DispatchQueue.main.async {
            self.handleMessage(messageData)
        }
        
        // Send acknowledgment
        replyHandler(["status": "received"])
    }
    
    func session(_ session: WCSession, didReceiveMessageData messageData: Data, replyHandler: @escaping (Data) -> Void) {
        DispatchQueue.main.async {
            self.handleMessage(messageData)
        }
        
        // Send acknowledgment
        let response = "received".data(using: .utf8) ?? Data()
        replyHandler(response)
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        guard let settingsData = applicationContext["settings"] as? Data else { return }
        
        do {
            let settings = try decoder.decode(WatchSettings.self, from: settingsData)
            // Apply settings to watch app
            applySettings(settings)
        } catch {
            print("Failed to decode settings: \(error)")
        }
    }
    
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        // Handle user info updates
        if let complicationData = userInfo["complicationData"] as? Data {
            do {
                let data = try decoder.decode(ComplicationData.self, from: complicationData)
                updateWatchComplications(with: data)
            } catch {
                print("Failed to decode complication data: \(error)")
            }
        }
    }
    
    private func applySettings(_ settings: WatchSettings) {
        // Apply watch-specific settings
        UserDefaults.standard.set(settings.enableHapticFeedback, forKey: "enableHapticFeedback")
        UserDefaults.standard.set(settings.autoStartWorkouts, forKey: "autoStartWorkouts")
        UserDefaults.standard.set(settings.showHeartRateAlerts, forKey: "showHeartRateAlerts")
        
        do {
            let settingsData = try encoder.encode(settings)
            UserDefaults.standard.set(settingsData, forKey: "watchSettings")
        } catch {
            print("Failed to store watch settings: \(error)")
        }
    }
}