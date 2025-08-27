import Foundation

public enum UserRole: String, CaseIterable, Codable {
    case dev = "dev"
    case admin = "admin"
    case user = "user"
    
    public var displayName: String {
        switch self {
        case .dev:
            return "Developer"
        case .admin:
            return "Coach/Admin"
        case .user:
            return "Client"
        }
    }
    
    public var permissions: [Permission] {
        switch self {
        case .dev:
            return Permission.allCases
        case .admin:
            return [.manageClients, .createPrograms, .viewAnalytics, .manageNutrition, .trackProgress]
        case .user:
            return [.trackProgress, .viewPrograms, .logWorkouts, .logNutrition]
        }
    }
}

public enum Permission: String, CaseIterable, Codable {
    case manageClients = "manage_clients"
    case createPrograms = "create_programs"
    case viewAnalytics = "view_analytics"
    case manageNutrition = "manage_nutrition"
    case trackProgress = "track_progress"
    case viewPrograms = "view_programs"
    case logWorkouts = "log_workouts"
    case logNutrition = "log_nutrition"
    case systemAccess = "system_access"
    case debugMode = "debug_mode"
}