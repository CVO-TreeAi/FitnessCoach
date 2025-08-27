import Foundation
import CoreLocation
import Combine

@MainActor
class WatchLocationManager: NSObject, ObservableObject {
    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isLocationServicesEnabled = false
    @Published var locationError: LocationError?
    @Published var isTrackingRoute = false
    @Published var routeLocations: [CLLocation] = []
    @Published var currentSpeed: Double = 0 // m/s
    @Published var totalDistance: Double = 0 // meters
    @Published var currentAltitude: Double = 0 // meters
    @Published var accuracy: Double = 0 // meters
    
    private let locationManager = CLLocationManager()
    private var workoutStartTime: Date?
    private var lastLocation: CLLocation?
    private var cancellables = Set<AnyCancellable>()
    
    // Location tracking settings
    private let desiredAccuracy: CLLocationAccuracy = kCLLocationAccuracyBest
    private let distanceFilter: CLLocationDistance = 5.0 // 5 meters
    
    enum LocationError: Error, LocalizedError {
        case notAuthorized
        case notAvailable
        case accuracyTooLow
        case trackingFailed
        
        var errorDescription: String? {
            switch self {
            case .notAuthorized:
                return "Location access not authorized"
            case .notAvailable:
                return "Location services not available"
            case .accuracyTooLow:
                return "Location accuracy too low"
            case .trackingFailed:
                return "Location tracking failed"
            }
        }
    }
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    // MARK: - Setup
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = desiredAccuracy
        locationManager.distanceFilter = distanceFilter
        
        isLocationServicesEnabled = CLLocationManager.locationServicesEnabled()
        authorizationStatus = locationManager.authorizationStatus
    }
    
    // MARK: - Authorization
    
    func requestLocationPermission() {
        guard isLocationServicesEnabled else {
            locationError = .notAvailable
            return
        }
        
        switch authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            locationError = .notAuthorized
        case .authorizedWhenInUse, .authorizedAlways:
            // Already authorized
            break
        @unknown default:
            break
        }
    }
    
    // MARK: - Location Tracking
    
    func startLocationUpdates() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            locationError = .notAuthorized
            return
        }
        
        locationManager.startUpdatingLocation()
        locationError = nil
    }
    
    func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
    }
    
    // MARK: - Route Tracking
    
    func startRouteTracking() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            locationError = .notAuthorized
            return
        }
        
        isTrackingRoute = true
        routeLocations = []
        totalDistance = 0
        workoutStartTime = Date()
        lastLocation = nil
        
        // Start location updates with higher accuracy for route tracking
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 3.0 // More precise for route tracking
        locationManager.startUpdatingLocation()
        
        locationError = nil
    }
    
    func stopRouteTracking() {
        isTrackingRoute = false
        locationManager.stopUpdatingLocation()
        
        // Reset to normal accuracy settings
        locationManager.desiredAccuracy = desiredAccuracy
        locationManager.distanceFilter = distanceFilter
    }
    
    func pauseRouteTracking() {
        if isTrackingRoute {
            locationManager.stopUpdatingLocation()
        }
    }
    
    func resumeRouteTracking() {
        if isTrackingRoute {
            locationManager.startUpdatingLocation()
        }
    }
    
    // MARK: - Data Processing
    
    private func processNewLocation(_ location: CLLocation) {
        currentLocation = location
        accuracy = location.horizontalAccuracy
        currentAltitude = location.altitude
        
        // Calculate speed (smoothed)
        if let lastLoc = lastLocation {
            let timeInterval = location.timestamp.timeIntervalSince(lastLoc.timestamp)
            if timeInterval > 0 {
                let distance = location.distance(from: lastLoc)
                let instantSpeed = distance / timeInterval
                
                // Smooth the speed calculation to reduce GPS noise
                currentSpeed = (currentSpeed * 0.7) + (instantSpeed * 0.3)
            }
        }
        
        // Add to route if tracking
        if isTrackingRoute {
            addLocationToRoute(location)
        }
        
        lastLocation = location
    }
    
    private func addLocationToRoute(_ location: CLLocation) {
        // Only add locations with reasonable accuracy
        guard location.horizontalAccuracy <= 20 else {
            return
        }
        
        // If this is the first location or it's far enough from the last one
        if let lastRouteLocation = routeLocations.last {
            let distance = location.distance(from: lastRouteLocation)
            
            // Only add if moved at least 3 meters
            if distance >= 3.0 {
                routeLocations.append(location)
                totalDistance += distance
            }
        } else {
            // First location
            routeLocations.append(location)
        }
    }
    
    // MARK: - Route Data
    
    func getCurrentPace() -> Double? {
        guard currentSpeed > 0 else { return nil }
        
        // Return pace in minutes per mile
        let metersPerSecondToMilesPerHour = currentSpeed * 2.237
        guard metersPerSecondToMilesPerHour > 0 else { return nil }
        
        return 60.0 / metersPerSecondToMilesPerHour // minutes per mile
    }
    
    func getAveragePace() -> Double? {
        guard let startTime = workoutStartTime,
              totalDistance > 0 else { return nil }
        
        let elapsedTime = Date().timeIntervalSince(startTime) / 60.0 // minutes
        let totalMiles = totalDistance * 0.000621371 // meters to miles
        
        guard totalMiles > 0 else { return nil }
        
        return elapsedTime / totalMiles // minutes per mile
    }
    
    func getTotalDistanceInMiles() -> Double {
        return totalDistance * 0.000621371 // meters to miles
    }
    
    func getTotalDistanceInKilometers() -> Double {
        return totalDistance / 1000.0 // meters to kilometers
    }
    
    func getRouteElevationGain() -> Double {
        guard routeLocations.count > 1 else { return 0 }
        
        var elevationGain: Double = 0
        var previousAltitude = routeLocations.first?.altitude ?? 0
        
        for location in routeLocations.dropFirst() {
            let altitudeDiff = location.altitude - previousAltitude
            if altitudeDiff > 0 {
                elevationGain += altitudeDiff
            }
            previousAltitude = location.altitude
        }
        
        return elevationGain
    }
    
    func getRouteData() -> RouteData? {
        guard !routeLocations.isEmpty,
              let startTime = workoutStartTime else { return nil }
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        return RouteData(
            locations: routeLocations,
            startTime: startTime,
            endTime: endTime,
            duration: duration,
            totalDistance: totalDistance,
            elevationGain: getRouteElevationGain(),
            averagePace: getAveragePace()
        )
    }
    
    // MARK: - Location Services Status
    
    var locationServicesStatusText: String {
        switch authorizationStatus {
        case .notDetermined:
            return "Not Requested"
        case .restricted:
            return "Restricted"
        case .denied:
            return "Denied"
        case .authorizedAlways:
            return "Always Authorized"
        case .authorizedWhenInUse:
            return "When In Use"
        @unknown default:
            return "Unknown"
        }
    }
    
    var isLocationAuthorized: Bool {
        authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }
    
    // MARK: - Utility Methods
    
    func resetRouteData() {
        routeLocations = []
        totalDistance = 0
        workoutStartTime = nil
        lastLocation = nil
        currentSpeed = 0
    }
    
    func getLocationDescription() -> String {
        guard let location = currentLocation else {
            return "Location unavailable"
        }
        
        return String(format: "%.6f, %.6f (±%.0fm)", 
                     location.coordinate.latitude,
                     location.coordinate.longitude,
                     location.horizontalAccuracy)
    }
}

// MARK: - CLLocationManagerDelegate

extension WatchLocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // Filter out old or inaccurate locations
        let locationAge = -location.timestamp.timeIntervalSinceNow
        if locationAge > 5.0 {
            return // Location is more than 5 seconds old
        }
        
        if location.horizontalAccuracy < 0 {
            return // Invalid location
        }
        
        if location.horizontalAccuracy > 50 {
            locationError = .accuracyTooLow
            return
        }
        
        processNewLocation(location)
        locationError = nil
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error)")
        
        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                locationError = .notAuthorized
            case .locationUnknown:
                locationError = .trackingFailed
            default:
                locationError = .trackingFailed
            }
        } else {
            locationError = .trackingFailed
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        authorizationStatus = status
        
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            locationError = nil
        case .denied, .restricted:
            locationError = .notAuthorized
            stopLocationUpdates()
        case .notDetermined:
            break
        @unknown default:
            break
        }
    }
    
    func locationManagerDidPauseLocationUpdates(_ manager: CLLocationManager) {
        print("Location updates paused")
    }
    
    func locationManagerDidResumeLocationUpdates(_ manager: CLLocationManager) {
        print("Location updates resumed")
    }
}

// MARK: - Supporting Types

struct RouteData {
    let locations: [CLLocation]
    let startTime: Date
    let endTime: Date
    let duration: TimeInterval
    let totalDistance: Double // meters
    let elevationGain: Double // meters
    let averagePace: Double? // minutes per mile
    
    var totalDistanceMiles: Double {
        totalDistance * 0.000621371
    }
    
    var totalDistanceKilometers: Double {
        totalDistance / 1000.0
    }
    
    var elevationGainFeet: Double {
        elevationGain * 3.28084
    }
    
    var durationMinutes: Double {
        duration / 60.0
    }
    
    var averageSpeed: Double? {
        guard duration > 0 else { return nil }
        return totalDistance / duration // m/s
    }
    
    var averageSpeedMPH: Double? {
        guard let avgSpeed = averageSpeed else { return nil }
        return avgSpeed * 2.237 // m/s to mph
    }
    
    var averageSpeedKPH: Double? {
        guard let avgSpeed = averageSpeed else { return nil }
        return avgSpeed * 3.6 // m/s to kph
    }
}