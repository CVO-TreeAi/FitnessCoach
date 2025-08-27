import SwiftUI
import Foundation

// MARK: - Localization Manager
public class LocalizationManager: ObservableObject {
    public static let shared = LocalizationManager()
    
    @Published public var currentLanguage: Language = .english
    @Published public var isRightToLeft: Bool = false
    
    public enum Language: String, CaseIterable, Identifiable {
        case english = "en"
        case spanish = "es"
        case french = "fr"
        case german = "de"
        case italian = "it"
        case portuguese = "pt"
        case chinese = "zh"
        case japanese = "ja"
        case korean = "ko"
        case arabic = "ar"
        case hebrew = "he"
        case russian = "ru"
        
        public var id: String { rawValue }
        
        public var displayName: String {
            switch self {
            case .english: return "English"
            case .spanish: return "Español"
            case .french: return "Français"
            case .german: return "Deutsch"
            case .italian: return "Italiano"
            case .portuguese: return "Português"
            case .chinese: return "中文"
            case .japanese: return "日本語"
            case .korean: return "한국어"
            case .arabic: return "العربية"
            case .hebrew: return "עברית"
            case .russian: return "Русский"
            }
        }
        
        public var nativeName: String {
            switch self {
            case .english: return "English"
            case .spanish: return "Español"
            case .french: return "Français"
            case .german: return "Deutsch"
            case .italian: return "Italiano"
            case .portuguese: return "Português"
            case .chinese: return "中文"
            case .japanese: return "日本語"
            case .korean: return "한국어"
            case .arabic: return "العربية"
            case .hebrew: return "עברית"
            case .russian: return "Русский"
            }
        }
        
        public var isRightToLeft: Bool {
            switch self {
            case .arabic, .hebrew: return true
            default: return false
            }
        }
        
        public var locale: Locale {
            Locale(identifier: rawValue)
        }
    }
    
    private var localizedStrings: [String: String] = [:]
    
    private init() {
        loadCurrentLanguage()
        setupNotifications()
    }
    
    private func loadCurrentLanguage() {
        if let savedLanguage = UserDefaults.standard.string(forKey: "selectedLanguage"),
           let language = Language(rawValue: savedLanguage) {
            setLanguage(language)
        } else {
            // Use system language if available, otherwise default to English
            let systemLanguage = Locale.current.language.languageCode?.identifier ?? "en"
            let language = Language(rawValue: systemLanguage) ?? .english
            setLanguage(language)
        }
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            forName: NSLocale.currentLocaleDidChangeNotification,
            object: nil,
            queue: .main
        ) { _ in
            // Handle system locale changes if needed
        }
    }
    
    public func setLanguage(_ language: Language) {
        currentLanguage = language
        isRightToLeft = language.isRightToLeft
        UserDefaults.standard.set(language.rawValue, forKey: "selectedLanguage")
        loadLocalizedStrings(for: language)
    }
    
    private func loadLocalizedStrings(for language: Language) {
        // In a real app, you would load from localization files
        // For now, we'll use a sample dictionary
        localizedStrings = getLocalizedStrings(for: language)
    }
    
    public func localized(_ key: String, arguments: [CVarArg] = []) -> String {
        let format = localizedStrings[key] ?? key
        
        if arguments.isEmpty {
            return format
        } else {
            return String(format: format, arguments: arguments)
        }
    }
    
    // MARK: - Fitness-Specific Localization Helpers
    
    public func localizedWorkoutType(_ type: String) -> String {
        return localized("workout_type_\(type.lowercased())")
    }
    
    public func localizedExercise(_ exercise: String) -> String {
        return localized("exercise_\(exercise.lowercased().replacingOccurrences(of: " ", with: "_"))")
    }
    
    public func localizedMetric(_ metric: String, value: Double, unit: String? = nil) -> String {
        let baseKey = "metric_\(metric.lowercased())"
        let localizedMetric = localized(baseKey)
        
        if let unit = unit {
            let unitKey = "unit_\(unit.lowercased())"
            let localizedUnit = localized(unitKey)
            return "\(localizedMetric): \(formatNumber(value)) \(localizedUnit)"
        } else {
            return "\(localizedMetric): \(formatNumber(value))"
        }
    }
    
    public func localizedDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60
        
        if hours > 0 {
            return localized("duration_hours_minutes_seconds", arguments: [hours, minutes, secs])
        } else if minutes > 0 {
            return localized("duration_minutes_seconds", arguments: [minutes, secs])
        } else {
            return localized("duration_seconds", arguments: [secs])
        }
    }
    
    public func localizedDate(_ date: Date, style: DateFormatter.Style = .medium) -> String {
        let formatter = DateFormatter()
        formatter.locale = currentLanguage.locale
        formatter.dateStyle = style
        return formatter.string(from: date)
    }
    
    public func localizedTime(_ date: Date, style: DateFormatter.Style = .short) -> String {
        let formatter = DateFormatter()
        formatter.locale = currentLanguage.locale
        formatter.timeStyle = style
        return formatter.string(from: date)
    }
    
    public func formatNumber(_ number: Double, style: NumberFormatter.Style = .decimal) -> String {
        let formatter = NumberFormatter()
        formatter.locale = currentLanguage.locale
        formatter.numberStyle = style
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
    
    public func formatWeight(_ weight: Double, unit: WeightUnit = .kg) -> String {
        let formattedWeight = formatNumber(weight, style: .decimal)
        let unitString = localized("unit_\(unit.rawValue)")
        return "\(formattedWeight) \(unitString)"
    }
    
    public enum WeightUnit: String {
        case kg = "kg"
        case lbs = "lbs"
    }
    
    // MARK: - Sample Localized Strings
    
    private func getLocalizedStrings(for language: Language) -> [String: String] {
        switch language {
        case .english:
            return englishStrings
        case .spanish:
            return spanishStrings
        case .french:
            return frenchStrings
        case .german:
            return germanStrings
        case .arabic:
            return arabicStrings
        default:
            return englishStrings // Fallback
        }
    }
    
    private var englishStrings: [String: String] = [
        // Common
        "hello": "Hello",
        "welcome": "Welcome",
        "save": "Save",
        "cancel": "Cancel",
        "continue": "Continue",
        "done": "Done",
        "edit": "Edit",
        "delete": "Delete",
        "add": "Add",
        "remove": "Remove",
        
        // Navigation
        "home": "Home",
        "workouts": "Workouts",
        "progress": "Progress",
        "nutrition": "Nutrition",
        "profile": "Profile",
        "settings": "Settings",
        
        // Workouts
        "workout_type_strength": "Strength Training",
        "workout_type_cardio": "Cardio",
        "workout_type_yoga": "Yoga",
        "workout_type_hiit": "HIIT",
        "workout_type_running": "Running",
        "workout_type_cycling": "Cycling",
        "workout_type_swimming": "Swimming",
        
        // Exercises
        "exercise_push_up": "Push-up",
        "exercise_squat": "Squat",
        "exercise_deadlift": "Deadlift",
        "exercise_bench_press": "Bench Press",
        "exercise_pull_up": "Pull-up",
        "exercise_plank": "Plank",
        
        // Metrics
        "metric_weight": "Weight",
        "metric_height": "Height",
        "metric_body_fat": "Body Fat",
        "metric_muscle_mass": "Muscle Mass",
        "metric_calories": "Calories",
        "metric_duration": "Duration",
        "metric_distance": "Distance",
        "metric_speed": "Speed",
        "metric_heart_rate": "Heart Rate",
        
        // Units
        "unit_kg": "kg",
        "unit_lbs": "lbs",
        "unit_cm": "cm",
        "unit_ft": "ft",
        "unit_in": "in",
        "unit_cal": "cal",
        "unit_kcal": "kcal",
        "unit_min": "min",
        "unit_sec": "sec",
        "unit_km": "km",
        "unit_mi": "mi",
        "unit_mph": "mph",
        "unit_kph": "km/h",
        "unit_bpm": "bpm",
        "unit_percent": "%",
        
        // Duration formatting
        "duration_hours_minutes_seconds": "%d:%02d:%02d",
        "duration_minutes_seconds": "%d:%02d",
        "duration_seconds": "%d sec",
        
        // Progress
        "goal_achieved": "Goal Achieved!",
        "workout_complete": "Workout Complete",
        "new_personal_record": "New Personal Record!",
        "streak_maintained": "Streak Maintained",
        
        // Accessibility
        "accessibility_button": "Button",
        "accessibility_chart": "Chart",
        "accessibility_progress": "Progress",
        "accessibility_stepper": "Stepper"
    ]
    
    private var spanishStrings: [String: String] = [
        // Common
        "hello": "Hola",
        "welcome": "Bienvenido",
        "save": "Guardar",
        "cancel": "Cancelar",
        "continue": "Continuar",
        "done": "Hecho",
        "edit": "Editar",
        "delete": "Eliminar",
        "add": "Añadir",
        "remove": "Quitar",
        
        // Navigation
        "home": "Inicio",
        "workouts": "Entrenamientos",
        "progress": "Progreso",
        "nutrition": "Nutrición",
        "profile": "Perfil",
        "settings": "Configuración",
        
        // Workouts
        "workout_type_strength": "Entrenamiento de Fuerza",
        "workout_type_cardio": "Cardio",
        "workout_type_yoga": "Yoga",
        "workout_type_hiit": "HIIT",
        "workout_type_running": "Correr",
        "workout_type_cycling": "Ciclismo",
        "workout_type_swimming": "Natación",
        
        // Metrics
        "metric_weight": "Peso",
        "metric_height": "Altura",
        "metric_body_fat": "Grasa Corporal",
        "metric_muscle_mass": "Masa Muscular",
        "metric_calories": "Calorías",
        "metric_duration": "Duración",
        
        // Units
        "unit_kg": "kg",
        "unit_lbs": "lbs",
        "unit_cal": "cal",
        "unit_min": "min",
        "unit_sec": "seg",
        
        // Progress
        "goal_achieved": "¡Meta Alcanzada!",
        "workout_complete": "Entrenamiento Completo",
        "new_personal_record": "¡Nuevo Récord Personal!"
    ]
    
    private var frenchStrings: [String: String] = [
        // Common
        "hello": "Bonjour",
        "welcome": "Bienvenue",
        "save": "Enregistrer",
        "cancel": "Annuler",
        "continue": "Continuer",
        "done": "Terminé",
        
        // Navigation
        "home": "Accueil",
        "workouts": "Entraînements",
        "progress": "Progrès",
        "nutrition": "Nutrition",
        "profile": "Profil",
        "settings": "Paramètres",
        
        // Workouts
        "workout_type_strength": "Musculation",
        "workout_type_cardio": "Cardio",
        "workout_type_yoga": "Yoga",
        
        // Metrics
        "metric_weight": "Poids",
        "metric_height": "Taille",
        "metric_calories": "Calories",
        
        // Progress
        "goal_achieved": "Objectif Atteint!",
        "workout_complete": "Entraînement Terminé"
    ]
    
    private var germanStrings: [String: String] = [
        // Common
        "hello": "Hallo",
        "welcome": "Willkommen",
        "save": "Speichern",
        "cancel": "Abbrechen",
        "continue": "Weiter",
        "done": "Fertig",
        
        // Navigation
        "home": "Startseite",
        "workouts": "Training",
        "progress": "Fortschritt",
        "nutrition": "Ernährung",
        "profile": "Profil",
        "settings": "Einstellungen",
        
        // Workouts
        "workout_type_strength": "Krafttraining",
        "workout_type_cardio": "Ausdauer",
        "workout_type_yoga": "Yoga",
        
        // Progress
        "goal_achieved": "Ziel Erreicht!",
        "workout_complete": "Training Abgeschlossen"
    ]
    
    private var arabicStrings: [String: String] = [
        // Common
        "hello": "مرحبا",
        "welcome": "أهلا وسهلا",
        "save": "حفظ",
        "cancel": "إلغاء",
        "continue": "متابعة",
        "done": "تم",
        
        // Navigation
        "home": "الرئيسية",
        "workouts": "التمارين",
        "progress": "التقدم",
        "nutrition": "التغذية",
        "profile": "الملف الشخصي",
        "settings": "الإعدادات",
        
        // Progress
        "goal_achieved": "تم تحقيق الهدف!",
        "workout_complete": "اكتمل التمرين"
    ]
}

// MARK: - Localization Extensions
public extension String {
    func localized(arguments: [CVarArg] = []) -> String {
        LocalizationManager.shared.localized(self, arguments: arguments)
    }
    
    var localized: String {
        LocalizationManager.shared.localized(self)
    }
}

// MARK: - SwiftUI Integration
public struct LocalizedText: View {
    private let key: String
    private let arguments: [CVarArg]
    
    public init(_ key: String, arguments: CVarArg...) {
        self.key = key
        self.arguments = arguments
    }
    
    public var body: some View {
        Text(LocalizationManager.shared.localized(key, arguments: arguments))
    }
}

// MARK: - Environment Key
private struct LocalizationManagerKey: EnvironmentKey {
    static let defaultValue = LocalizationManager.shared
}

public extension EnvironmentValues {
    var localizationManager: LocalizationManager {
        get { self[LocalizationManagerKey.self] }
        set { self[LocalizationManagerKey.self] = newValue }
    }
}

// MARK: - View Extensions
public extension View {
    func localizationAware() -> some View {
        self
            .environment(\.localizationManager, LocalizationManager.shared)
            .environment(\.layoutDirection, LocalizationManager.shared.isRightToLeft ? .rightToLeft : .leftToRight)
    }
    
    func rightToLeftAware() -> some View {
        self.flipsForRightToLeftLayoutDirection(true)
    }
}

// MARK: - Language Selection View
public struct LanguageSelectionView: View {
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            List {
                ForEach(LocalizationManager.Language.allCases) { language in
                    HStack {
                        VStack(alignment: .leading, spacing: theme.spacing.xs) {
                            Text(language.displayName)
                                .font(theme.typography.bodyMedium)
                                .foregroundColor(theme.textPrimary)
                            
                            Text(language.nativeName)
                                .font(theme.typography.bodySmall)
                                .foregroundColor(theme.textSecondary)
                        }
                        
                        Spacer()
                        
                        if localizationManager.currentLanguage == language {
                            Image(systemName: "checkmark")
                                .foregroundColor(theme.primaryColor)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        localizationManager.setLanguage(language)
                    }
                    .accessibleButton(
                        label: "Select \(language.displayName)",
                        hint: localizationManager.currentLanguage == language ? "Currently selected" : "Tap to select this language"
                    )
                }
            }
            .navigationTitle("Language")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("done".localized) {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Localized Formatter Helper
public struct LocalizedFormatter {
    private let localizationManager = LocalizationManager.shared
    
    public init() {}
    
    public func weight(_ value: Double, unit: LocalizationManager.WeightUnit = .kg) -> String {
        return localizationManager.formatWeight(value, unit: unit)
    }
    
    public func duration(_ seconds: Int) -> String {
        return localizationManager.localizedDuration(seconds)
    }
    
    public func date(_ date: Date, style: DateFormatter.Style = .medium) -> String {
        return localizationManager.localizedDate(date, style: style)
    }
    
    public func number(_ value: Double, style: NumberFormatter.Style = .decimal) -> String {
        return localizationManager.formatNumber(value, style: style)
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        LocalizedText("welcome")
            .font(.largeTitle)
        
        LocalizedText("hello")
            .font(.title2)
        
        HStack {
            LocalizedText("workouts")
            Spacer()
            LocalizedText("progress")
        }
        
        Button("Change Language") {
            // Demo language switching
            let current = LocalizationManager.shared.currentLanguage
            let languages = LocalizationManager.Language.allCases
            if let currentIndex = languages.firstIndex(of: current) {
                let nextIndex = (currentIndex + 1) % languages.count
                LocalizationManager.shared.setLanguage(languages[nextIndex])
            }
        }
        
        Text("Formatted: \(LocalizedFormatter().weight(70.5, unit: .kg))")
        Text("Duration: \(LocalizedFormatter().duration(3665))")
    }
    .padding()
    .localizationAware()
    .theme(FitnessTheme())
}