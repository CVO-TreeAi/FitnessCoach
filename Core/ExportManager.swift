import Foundation
import UIKit
import PDFKit
import HealthKit
import CoreData
import UniformTypeIdentifiers
import OSLog

/// Comprehensive data export manager for PDF reports, CSV logs, and Health app integration
@MainActor
public final class ExportManager: NSObject, ObservableObject {
    
    static let shared = ExportManager()
    
    // MARK: - Properties
    private let logger = Logger(subsystem: "FitnessCoach", category: "ExportManager")
    
    @Published public var isExporting: Bool = false
    @Published public var exportProgress: Double = 0.0
    @Published public var lastExportDate: Date?
    
    private let coreDataManager = CoreDataManager.shared
    private let healthKitManager = HealthKitManager.shared
    
    // Export formats
    public enum ExportFormat {
        case pdf
        case csv
        case json
        case healthKit
    }
    
    public enum ExportType {
        case workoutPlan
        case nutritionLog
        case progressReport
        case fullDataExport
        case weeklyReport
        case monthlyReport
        case customDateRange(from: Date, to: Date)
    }
    
    // MARK: - Initialization
    override private init() {
        super.init()
    }
    
    // MARK: - PDF Export
    
    /// Exports workout plan as PDF
    public func exportWorkoutPlan(_ template: WorkoutTemplate, format: ExportFormat = .pdf) async throws -> URL {
        logger.info("Exporting workout plan: \(template.name ?? "Unknown")")
        
        isExporting = true
        exportProgress = 0.0
        
        defer {
            Task { @MainActor in
                self.isExporting = false
                self.exportProgress = 0.0
                self.lastExportDate = Date()
            }
        }
        
        switch format {
        case .pdf:
            return try await createWorkoutPlanPDF(template)
        case .json:
            return try await exportWorkoutPlanAsJSON(template)
        default:
            throw ExportError.unsupportedFormat
        }
    }
    
    private func createWorkoutPlanPDF(_ template: WorkoutTemplate) async throws -> URL {
        await updateProgress(0.2)
        
        let pageSize = CGRect(x: 0, y: 0, width: 612, height: 792) // Letter size
        let renderer = UIGraphicsPDFRenderer(bounds: pageSize)
        
        let data = renderer.pdfData { context in
            context.beginPage()
            
            var yPosition: CGFloat = 50
            
            // Title
            yPosition = drawTitle(template.name ?? "Workout Plan", at: yPosition, in: pageSize)
            
            // Metadata
            yPosition = drawMetadata(template, at: yPosition, in: pageSize)
            
            // Exercises
            let exercises = template.exercises?.allObjects as? [WorkoutExercise] ?? []
            yPosition = drawExercises(exercises.sorted { $0.orderIndex < $1.orderIndex }, 
                                    at: yPosition, in: pageSize, context: context)
            
            // Footer
            drawFooter(in: pageSize)
        }
        
        await updateProgress(0.8)
        
        let url = try saveToDocuments(data: data, filename: "\(template.name ?? "workout")_plan.pdf")
        
        await updateProgress(1.0)
        return url
    }
    
    /// Exports nutrition log as PDF
    public func exportNutritionLog(from startDate: Date, to endDate: Date, format: ExportFormat = .pdf) async throws -> URL {
        logger.info("Exporting nutrition log from \(startDate) to \(endDate)")
        
        isExporting = true
        exportProgress = 0.0
        
        defer {
            Task { @MainActor in
                self.isExporting = false
                self.exportProgress = 0.0
                self.lastExportDate = Date()
            }
        }
        
        switch format {
        case .pdf:
            return try await createNutritionLogPDF(from: startDate, to: endDate)
        case .csv:
            return try await exportNutritionLogAsCSV(from: startDate, to: endDate)
        case .json:
            return try await exportNutritionLogAsJSON(from: startDate, to: endDate)
        default:
            throw ExportError.unsupportedFormat
        }
    }
    
    private func createNutritionLogPDF(from startDate: Date, to endDate: Date) async throws -> URL {
        await updateProgress(0.1)
        
        let entries = try await fetchNutritionEntries(from: startDate, to: endDate)
        
        await updateProgress(0.3)
        
        let pageSize = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: pageSize)
        
        let data = renderer.pdfData { context in
            context.beginPage()
            
            var yPosition: CGFloat = 50
            
            // Title
            yPosition = drawTitle("Nutrition Log", at: yPosition, in: pageSize)
            
            // Date range
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            yPosition = drawSubtitle("From \(formatter.string(from: startDate)) to \(formatter.string(from: endDate))", 
                                   at: yPosition, in: pageSize)
            
            yPosition += 20
            
            // Group entries by date
            let groupedEntries = Dictionary(grouping: entries) { entry in
                Calendar.current.startOfDay(for: entry.date ?? Date())
            }
            
            let sortedDates = groupedEntries.keys.sorted()
            
            for (index, date) in sortedDates.enumerated() {
                if yPosition > pageSize.height - 100 {
                    context.beginPage()
                    yPosition = 50
                }
                
                let dayEntries = groupedEntries[date] ?? []
                yPosition = drawDailyNutrition(date: date, entries: dayEntries, at: yPosition, in: pageSize)
                
                await updateProgress(0.3 + (Double(index) / Double(sortedDates.count)) * 0.5)
            }
            
            drawFooter(in: pageSize)
        }
        
        await updateProgress(0.9)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let filename = "nutrition_log_\(formatter.string(from: startDate))_to_\(formatter.string(from: endDate)).pdf"
        
        let url = try saveToDocuments(data: data, filename: filename)
        
        await updateProgress(1.0)
        return url
    }
    
    /// Exports progress report as PDF
    public func exportProgressReport(from startDate: Date, to endDate: Date, format: ExportFormat = .pdf) async throws -> URL {
        logger.info("Exporting progress report from \(startDate) to \(endDate)")
        
        isExporting = true
        exportProgress = 0.0
        
        defer {
            Task { @MainActor in
                self.isExporting = false
                self.exportProgress = 0.0
                self.lastExportDate = Date()
            }
        }
        
        switch format {
        case .pdf:
            return try await createProgressReportPDF(from: startDate, to: endDate)
        case .csv:
            return try await exportProgressAsCSV(from: startDate, to: endDate)
        default:
            throw ExportError.unsupportedFormat
        }
    }
    
    private func createProgressReportPDF(from startDate: Date, to endDate: Date) async throws -> URL {
        await updateProgress(0.1)
        
        let progressEntries = try await fetchProgressEntries(from: startDate, to: endDate)
        let workoutSessions = try await fetchWorkoutSessions(from: startDate, to: endDate)
        
        await updateProgress(0.3)
        
        let pageSize = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: pageSize)
        
        let data = renderer.pdfData { context in
            context.beginPage()
            
            var yPosition: CGFloat = 50
            
            // Title
            yPosition = drawTitle("Progress Report", at: yPosition, in: pageSize)
            
            // Date range
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            yPosition = drawSubtitle("From \(formatter.string(from: startDate)) to \(formatter.string(from: endDate))", 
                                   at: yPosition, in: pageSize)
            
            yPosition += 30
            
            // Summary statistics
            yPosition = drawProgressSummary(progressEntries: progressEntries, workoutSessions: workoutSessions, 
                                          at: yPosition, in: pageSize)
            
            // Weight progress chart (simplified)
            yPosition = drawWeightProgressChart(progressEntries, at: yPosition, in: pageSize)
            
            // Workout summary
            yPosition = drawWorkoutSummary(workoutSessions, at: yPosition, in: pageSize, context: context)
            
            drawFooter(in: pageSize)
        }
        
        await updateProgress(0.9)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let filename = "progress_report_\(formatter.string(from: startDate))_to_\(formatter.string(from: endDate)).pdf"
        
        let url = try saveToDocuments(data: data, filename: filename)
        
        await updateProgress(1.0)
        return url
    }
    
    // MARK: - CSV Export
    
    private func exportNutritionLogAsCSV(from startDate: Date, to endDate: Date) async throws -> URL {
        let entries = try await fetchNutritionEntries(from: startDate, to: endDate)
        
        var csvContent = "Date,Meal Type,Food Item,Quantity,Unit,Calories,Protein,Carbs,Fat,Fiber,Sugar,Sodium,Notes\n"
        
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        
        for entry in entries {
            let row = [
                formatter.string(from: entry.date ?? Date()),
                entry.mealType ?? "",
                entry.foodItem?.name ?? "",
                String(entry.quantity),
                entry.unit ?? "",
                String(entry.calories),
                String(entry.protein),
                String(entry.carbs),
                String(entry.fat),
                String(entry.fiber),
                String(entry.sugar),
                String(entry.sodium),
                entry.notes?.replacingOccurrences(of: ",", with: ";") ?? ""
            ].joined(separator: ",")
            
            csvContent += row + "\n"
        }
        
        let data = csvContent.data(using: .utf8)!
        
        let formatter2 = DateFormatter()
        formatter2.dateFormat = "yyyy-MM-dd"
        let filename = "nutrition_log_\(formatter2.string(from: startDate))_to_\(formatter2.string(from: endDate)).csv"
        
        return try saveToDocuments(data: data, filename: filename)
    }
    
    private func exportProgressAsCSV(from startDate: Date, to endDate: Date) async throws -> URL {
        let entries = try await fetchProgressEntries(from: startDate, to: endDate)
        
        var csvContent = "Date,Type,Weight,Body Fat %,Muscle Mass,Visceral Fat,BMI,Chest,Waist,Hips,Left Arm,Right Arm,Left Thigh,Right Thigh,Notes\n"
        
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        
        for entry in entries {
            let row = [
                formatter.string(from: entry.date ?? Date()),
                entry.type ?? "",
                String(entry.weight),
                String(entry.bodyFatPercentage),
                String(entry.muscleMass),
                String(entry.visceralFat),
                String(entry.bmi),
                String(entry.chest),
                String(entry.waist),
                String(entry.hips),
                String(entry.leftArm),
                String(entry.rightArm),
                String(entry.leftThigh),
                String(entry.rightThigh),
                entry.notes?.replacingOccurrences(of: ",", with: ";") ?? ""
            ].joined(separator: ",")
            
            csvContent += row + "\n"
        }
        
        let data = csvContent.data(using: .utf8)!
        
        let formatter2 = DateFormatter()
        formatter2.dateFormat = "yyyy-MM-dd"
        let filename = "progress_data_\(formatter2.string(from: startDate))_to_\(formatter2.string(from: endDate)).csv"
        
        return try saveToDocuments(data: data, filename: filename)
    }
    
    // MARK: - JSON Export
    
    private func exportWorkoutPlanAsJSON(_ template: WorkoutTemplate) async throws -> URL {
        let exercises = template.exercises?.allObjects as? [WorkoutExercise] ?? []
        
        let workoutData = WorkoutPlanExport(
            id: template.id?.uuidString ?? "",
            name: template.name ?? "",
            description: template.desc ?? "",
            category: template.category ?? "",
            difficulty: template.difficulty ?? "",
            estimatedDuration: Int(template.estimatedDuration),
            caloriesBurned: Int(template.caloriesBurned),
            exercises: exercises.map { exercise in
                ExerciseExport(
                    id: exercise.id?.uuidString ?? "",
                    name: exercise.exercise?.name ?? "",
                    sets: Int(exercise.sets),
                    reps: Int(exercise.reps),
                    weight: exercise.weight,
                    duration: Int(exercise.duration),
                    distance: exercise.distance,
                    restTime: Int(exercise.restTime),
                    notes: exercise.notes
                )
            },
            isPublic: template.isPublic,
            tags: template.tags ?? [],
            createdAt: template.createdAt ?? Date()
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        let data = try encoder.encode(workoutData)
        
        let filename = "\(template.name?.replacingOccurrences(of: " ", with: "_") ?? "workout")_plan.json"
        return try saveToDocuments(data: data, filename: filename)
    }
    
    private func exportNutritionLogAsJSON(from startDate: Date, to endDate: Date) async throws -> URL {
        let entries = try await fetchNutritionEntries(from: startDate, to: endDate)
        
        let nutritionData = NutritionLogExport(
            startDate: startDate,
            endDate: endDate,
            entries: entries.map { entry in
                NutritionEntryExport(
                    id: entry.id?.uuidString ?? "",
                    date: entry.date ?? Date(),
                    mealType: entry.mealType ?? "",
                    foodItem: entry.foodItem?.name ?? "",
                    quantity: entry.quantity,
                    unit: entry.unit ?? "",
                    calories: entry.calories,
                    protein: entry.protein,
                    carbs: entry.carbs,
                    fat: entry.fat,
                    fiber: entry.fiber,
                    sugar: entry.sugar,
                    sodium: entry.sodium,
                    notes: entry.notes
                )
            }
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        let data = try encoder.encode(nutritionData)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let filename = "nutrition_log_\(formatter.string(from: startDate))_to_\(formatter.string(from: endDate)).json"
        
        return try saveToDocuments(data: data, filename: filename)
    }
    
    // MARK: - Health App Integration
    
    /// Exports data to Health app
    public func exportToHealthApp(dataTypes: Set<HKObjectType>) async throws {
        logger.info("Exporting data to Health app")
        
        guard await healthKitManager.requestAuthorization(for: dataTypes) else {
            throw ExportError.healthKitNotAuthorized
        }
        
        isExporting = true
        exportProgress = 0.0
        
        defer {
            Task { @MainActor in
                self.isExporting = false
                self.exportProgress = 0.0
            }
        }
        
        // Export workouts
        if dataTypes.contains(HKObjectType.workoutType()) {
            try await exportWorkoutsToHealthKit()
            await updateProgress(0.3)
        }
        
        // Export body weight
        if dataTypes.contains(HKObjectType.quantityType(forIdentifier: .bodyMass)!) {
            try await exportWeightToHealthKit()
            await updateProgress(0.6)
        }
        
        // Export body fat percentage
        if dataTypes.contains(HKObjectType.quantityType(forIdentifier: .bodyFatPercentage)!) {
            try await exportBodyFatToHealthKit()
            await updateProgress(0.9)
        }
        
        await updateProgress(1.0)
        logger.info("Health app export completed")
    }
    
    private func exportWorkoutsToHealthKit() async throws {
        let workoutSessions = try await fetchAllWorkoutSessions()
        
        for session in workoutSessions {
            guard let startDate = session.startTime,
                  let endDate = session.endTime else { continue }
            
            let workoutType = mapWorkoutType(session)
            let totalEnergyBurned = HKQuantity(unit: .kilocalorie(), doubleValue: Double(session.caloriesBurned))
            
            let workout = HKWorkout(
                activityType: workoutType,
                start: startDate,
                end: endDate,
                duration: endDate.timeIntervalSince(startDate),
                totalEnergyBurned: totalEnergyBurned,
                totalDistance: nil,
                metadata: [
                    HKMetadataKeyExternalUUID: session.id?.uuidString ?? UUID().uuidString
                ]
            )
            
            try await healthKitManager.save(workout)
        }
    }
    
    private func exportWeightToHealthKit() async throws {
        let progressEntries = try await fetchAllProgressEntries()
        let weightEntries = progressEntries.filter { $0.weight > 0 }
        
        for entry in weightEntries {
            guard let date = entry.date else { continue }
            
            let weightQuantity = HKQuantity(unit: .pound(), doubleValue: entry.weight)
            let weightSample = HKQuantitySample(
                type: HKObjectType.quantityType(forIdentifier: .bodyMass)!,
                quantity: weightQuantity,
                start: date,
                end: date,
                metadata: [
                    HKMetadataKeyExternalUUID: entry.id?.uuidString ?? UUID().uuidString
                ]
            )
            
            try await healthKitManager.save(weightSample)
        }
    }
    
    private func exportBodyFatToHealthKit() async throws {
        let progressEntries = try await fetchAllProgressEntries()
        let bodyFatEntries = progressEntries.filter { $0.bodyFatPercentage > 0 }
        
        for entry in bodyFatEntries {
            guard let date = entry.date else { continue }
            
            let bodyFatQuantity = HKQuantity(unit: .percent(), doubleValue: entry.bodyFatPercentage / 100.0)
            let bodyFatSample = HKQuantitySample(
                type: HKObjectType.quantityType(forIdentifier: .bodyFatPercentage)!,
                quantity: bodyFatQuantity,
                start: date,
                end: date,
                metadata: [
                    HKMetadataKeyExternalUUID: entry.id?.uuidString ?? UUID().uuidString
                ]
            )
            
            try await healthKitManager.save(bodyFatSample)
        }
    }
    
    // MARK: - Share Functionality
    
    /// Creates a share sheet for exporting data
    public func createShareSheet(for url: URL) -> UIActivityViewController {
        let activityViewController = UIActivityViewController(
            activityItems: [url],
            applicationActivities: nil
        )
        
        // Exclude some activities that don't make sense for data files
        activityViewController.excludedActivityTypes = [
            .assignToContact,
            .postToWeibo,
            .postToVimeo,
            .postToTencentWeibo,
            .postToFlickr
        ]
        
        return activityViewController
    }
    
    /// Shares data via email
    public func shareViaEmail(url: URL, recipient: String, subject: String) async throws {
        // Implementation would integrate with email sharing
        logger.info("Sharing via email: \(url.lastPathComponent) to \(recipient)")
    }
    
    /// Shares data via cloud storage
    public func shareViaCloudStorage(url: URL, service: CloudStorageService) async throws {
        // Implementation would integrate with cloud storage services
        logger.info("Sharing via \(service.rawValue): \(url.lastPathComponent)")
    }
    
    // MARK: - Helper Methods
    
    private func updateProgress(_ progress: Double) async {
        await MainActor.run {
            self.exportProgress = progress
        }
    }
    
    private func saveToDocuments(data: Data, filename: String) throws -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let url = documentsPath.appendingPathComponent(filename)
        
        try data.write(to: url)
        return url
    }
    
    // MARK: - Data Fetching
    
    private func fetchNutritionEntries(from startDate: Date, to endDate: Date) async throws -> [NutritionEntry] {
        return try await coreDataManager.context.perform {
            let request = NutritionEntry.fetchRequest()
            request.predicate = NSPredicate(format: "date >= %@ AND date <= %@", startDate as NSDate, endDate as NSDate)
            request.sortDescriptors = [NSSortDescriptor(keyPath: \NutritionEntry.date, ascending: true)]
            
            return try self.coreDataManager.context.fetch(request)
        }
    }
    
    private func fetchProgressEntries(from startDate: Date, to endDate: Date) async throws -> [ProgressEntry] {
        return try await coreDataManager.context.perform {
            let request = ProgressEntry.fetchRequest()
            request.predicate = NSPredicate(format: "date >= %@ AND date <= %@", startDate as NSDate, endDate as NSDate)
            request.sortDescriptors = [NSSortDescriptor(keyPath: \ProgressEntry.date, ascending: true)]
            
            return try self.coreDataManager.context.fetch(request)
        }
    }
    
    private func fetchWorkoutSessions(from startDate: Date, to endDate: Date) async throws -> [WorkoutSession] {
        return try await coreDataManager.context.perform {
            let request = WorkoutSession.fetchRequest()
            request.predicate = NSPredicate(format: "startTime >= %@ AND startTime <= %@", startDate as NSDate, endDate as NSDate)
            request.sortDescriptors = [NSSortDescriptor(keyPath: \WorkoutSession.startTime, ascending: true)]
            
            return try self.coreDataManager.context.fetch(request)
        }
    }
    
    private func fetchAllWorkoutSessions() async throws -> [WorkoutSession] {
        return try await coreDataManager.context.perform {
            let request = WorkoutSession.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(keyPath: \WorkoutSession.startTime, ascending: true)]
            
            return try self.coreDataManager.context.fetch(request)
        }
    }
    
    private func fetchAllProgressEntries() async throws -> [ProgressEntry] {
        return try await coreDataManager.context.perform {
            let request = ProgressEntry.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(keyPath: \ProgressEntry.date, ascending: true)]
            
            return try self.coreDataManager.context.fetch(request)
        }
    }
    
    // MARK: - PDF Drawing Helpers
    
    private func drawTitle(_ title: String, at y: CGFloat, in bounds: CGRect) -> CGFloat {
        let titleFont = UIFont.boldSystemFont(ofSize: 24)
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: UIColor.black
        ]
        
        let titleSize = title.size(withAttributes: titleAttributes)
        let titleRect = CGRect(x: (bounds.width - titleSize.width) / 2, y: y, width: titleSize.width, height: titleSize.height)
        
        title.draw(in: titleRect, withAttributes: titleAttributes)
        
        return y + titleSize.height + 20
    }
    
    private func drawSubtitle(_ subtitle: String, at y: CGFloat, in bounds: CGRect) -> CGFloat {
        let subtitleFont = UIFont.systemFont(ofSize: 16)
        let subtitleAttributes: [NSAttributedString.Key: Any] = [
            .font: subtitleFont,
            .foregroundColor: UIColor.darkGray
        ]
        
        let subtitleSize = subtitle.size(withAttributes: subtitleAttributes)
        let subtitleRect = CGRect(x: (bounds.width - subtitleSize.width) / 2, y: y, width: subtitleSize.width, height: subtitleSize.height)
        
        subtitle.draw(in: subtitleRect, withAttributes: subtitleAttributes)
        
        return y + subtitleSize.height + 10
    }
    
    private func drawMetadata(_ template: WorkoutTemplate, at y: CGFloat, in bounds: CGRect) -> CGFloat {
        let font = UIFont.systemFont(ofSize: 12)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.black
        ]
        
        var currentY = y
        let leftMargin: CGFloat = 50
        
        let metadata = [
            "Category: \(template.category ?? "N/A")",
            "Difficulty: \(template.difficulty ?? "N/A")",
            "Estimated Duration: \(template.estimatedDuration) minutes",
            "Estimated Calories: \(template.caloriesBurned) kcal"
        ]
        
        for item in metadata {
            item.draw(at: CGPoint(x: leftMargin, y: currentY), withAttributes: attributes)
            currentY += 20
        }
        
        return currentY + 20
    }
    
    private func drawExercises(_ exercises: [WorkoutExercise], at y: CGFloat, in bounds: CGRect, context: UIGraphicsPDFRendererContext) -> CGFloat {
        let headerFont = UIFont.boldSystemFont(ofSize: 16)
        let bodyFont = UIFont.systemFont(ofSize: 12)
        
        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: headerFont,
            .foregroundColor: UIColor.black
        ]
        
        let bodyAttributes: [NSAttributedString.Key: Any] = [
            .font: bodyFont,
            .foregroundColor: UIColor.black
        ]
        
        var currentY = y
        let leftMargin: CGFloat = 50
        
        "Exercises:".draw(at: CGPoint(x: leftMargin, y: currentY), withAttributes: headerAttributes)
        currentY += 30
        
        for (index, exercise) in exercises.enumerated() {
            // Check if we need a new page
            if currentY > bounds.height - 150 {
                context.beginPage()
                currentY = 50
            }
            
            let exerciseName = "\(index + 1). \(exercise.exercise?.name ?? "Unknown Exercise")"
            exerciseName.draw(at: CGPoint(x: leftMargin, y: currentY), withAttributes: headerAttributes)
            currentY += 25
            
            let details = "Sets: \(exercise.sets), Reps: \(exercise.reps), Weight: \(exercise.weight) lbs"
            details.draw(at: CGPoint(x: leftMargin + 20, y: currentY), withAttributes: bodyAttributes)
            currentY += 20
            
            if let notes = exercise.notes, !notes.isEmpty {
                let notesText = "Notes: \(notes)"
                notesText.draw(at: CGPoint(x: leftMargin + 20, y: currentY), withAttributes: bodyAttributes)
                currentY += 20
            }
            
            currentY += 10 // Space between exercises
        }
        
        return currentY
    }
    
    private func drawDailyNutrition(date: Date, entries: [NutritionEntry], at y: CGFloat, in bounds: CGRect) -> CGFloat {
        let headerFont = UIFont.boldSystemFont(ofSize: 14)
        let bodyFont = UIFont.systemFont(ofSize: 10)
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        
        var currentY = y
        let leftMargin: CGFloat = 50
        
        // Date header
        formatter.string(from: date).draw(at: CGPoint(x: leftMargin, y: currentY), withAttributes: [
            .font: headerFont,
            .foregroundColor: UIColor.black
        ])
        currentY += 25
        
        // Calculate daily totals
        let totalCalories = entries.reduce(0) { $0 + $1.calories }
        let totalProtein = entries.reduce(0) { $0 + $1.protein }
        let totalCarbs = entries.reduce(0) { $0 + $1.carbs }
        let totalFat = entries.reduce(0) { $0 + $1.fat }
        
        let summary = "Total: \(Int(totalCalories)) cal, \(Int(totalProtein))g protein, \(Int(totalCarbs))g carbs, \(Int(totalFat))g fat"
        summary.draw(at: CGPoint(x: leftMargin + 20, y: currentY), withAttributes: [
            .font: bodyFont,
            .foregroundColor: UIColor.darkGray
        ])
        currentY += 20
        
        return currentY + 15
    }
    
    private func drawProgressSummary(progressEntries: [ProgressEntry], workoutSessions: [WorkoutSession], at y: CGFloat, in bounds: CGRect) -> CGFloat {
        let font = UIFont.systemFont(ofSize: 12)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.black
        ]
        
        var currentY = y
        let leftMargin: CGFloat = 50
        
        // Workout summary
        let totalWorkouts = workoutSessions.count
        let totalCaloriesBurned = workoutSessions.reduce(0) { $0 + Int($1.caloriesBurned) }
        let totalMinutes = workoutSessions.reduce(0) { $0 + Int($1.totalDuration) }
        
        let workoutSummary = [
            "Total Workouts: \(totalWorkouts)",
            "Total Calories Burned: \(totalCaloriesBurned)",
            "Total Workout Time: \(totalMinutes) minutes"
        ]
        
        for item in workoutSummary {
            item.draw(at: CGPoint(x: leftMargin, y: currentY), withAttributes: attributes)
            currentY += 20
        }
        
        // Weight progress
        if let firstEntry = progressEntries.first(where: { $0.weight > 0 }),
           let lastEntry = progressEntries.last(where: { $0.weight > 0 }) {
            let weightChange = lastEntry.weight - firstEntry.weight
            let changeText = weightChange >= 0 ? "+\(String(format: "%.1f", weightChange))" : String(format: "%.1f", weightChange)
            
            "Weight Change: \(changeText) lbs".draw(at: CGPoint(x: leftMargin, y: currentY), withAttributes: attributes)
            currentY += 20
        }
        
        return currentY + 20
    }
    
    private func drawWeightProgressChart(_ entries: [ProgressEntry], at y: CGFloat, in bounds: CGRect) -> CGFloat {
        let chartHeight: CGFloat = 120
        let chartWidth: CGFloat = bounds.width - 100
        let leftMargin: CGFloat = 50
        
        let chartRect = CGRect(x: leftMargin, y: y, width: chartWidth, height: chartHeight)
        
        // Draw chart border
        UIColor.black.setStroke()
        let path = UIBezierPath(rect: chartRect)
        path.lineWidth = 1
        path.stroke()
        
        // Draw simple weight line chart (simplified implementation)
        let weightEntries = entries.filter { $0.weight > 0 }.prefix(30) // Last 30 entries
        guard weightEntries.count > 1 else { return y + chartHeight + 20 }
        
        let weights = weightEntries.map { $0.weight }
        let minWeight = weights.min() ?? 0
        let maxWeight = weights.max() ?? 0
        let weightRange = max(maxWeight - minWeight, 1)
        
        UIColor.blue.setStroke()
        let linePath = UIBezierPath()
        
        for (index, entry) in weightEntries.enumerated() {
            let x = leftMargin + (CGFloat(index) / CGFloat(weightEntries.count - 1)) * chartWidth
            let normalizedWeight = (entry.weight - minWeight) / weightRange
            let yPos = y + chartHeight - (normalizedWeight * chartHeight)
            
            if index == 0 {
                linePath.move(to: CGPoint(x: x, y: yPos))
            } else {
                linePath.addLine(to: CGPoint(x: x, y: yPos))
            }
        }
        
        linePath.lineWidth = 2
        linePath.stroke()
        
        return y + chartHeight + 30
    }
    
    private func drawWorkoutSummary(_ sessions: [WorkoutSession], at y: CGFloat, in bounds: CGRect, context: UIGraphicsPDFRendererContext) -> CGFloat {
        // Group workouts by type/category for summary
        var currentY = y
        
        let font = UIFont.systemFont(ofSize: 12)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.black
        ]
        
        "Recent Workouts:".draw(at: CGPoint(x: 50, y: currentY), withAttributes: [
            .font: UIFont.boldSystemFont(ofSize: 14),
            .foregroundColor: UIColor.black
        ])
        currentY += 25
        
        let recentSessions = sessions.suffix(10) // Last 10 workouts
        
        for session in recentSessions {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            
            let sessionText = "\(formatter.string(from: session.startTime ?? Date())) - \(session.totalDuration) min, \(session.caloriesBurned) cal"
            sessionText.draw(at: CGPoint(x: 70, y: currentY), withAttributes: attributes)
            currentY += 20
        }
        
        return currentY
    }
    
    private func drawFooter(in bounds: CGRect) {
        let footerText = "Generated by FitnessCoach - \(Date().formatted(date: .abbreviated, time: .omitted))"
        let font = UIFont.systemFont(ofSize: 10)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.gray
        ]
        
        let textSize = footerText.size(withAttributes: attributes)
        let footerRect = CGRect(
            x: (bounds.width - textSize.width) / 2,
            y: bounds.height - 30,
            width: textSize.width,
            height: textSize.height
        )
        
        footerText.draw(in: footerRect, withAttributes: attributes)
    }
    
    private func mapWorkoutType(_ session: WorkoutSession) -> HKWorkoutActivityType {
        // Map workout types to HealthKit activity types
        // This is a simplified mapping - you'd want more sophisticated logic
        return .functionalStrengthTraining
    }
}

// MARK: - Supporting Types

public enum CloudStorageService: String, CaseIterable {
    case iCloudDrive = "iCloud Drive"
    case dropbox = "Dropbox"
    case googleDrive = "Google Drive"
    case oneDrive = "OneDrive"
}

public enum ExportError: LocalizedError {
    case unsupportedFormat
    case healthKitNotAuthorized
    case exportFailed
    case fileWriteError
    
    public var errorDescription: String? {
        switch self {
        case .unsupportedFormat: return "Unsupported export format"
        case .healthKitNotAuthorized: return "HealthKit access not authorized"
        case .exportFailed: return "Export operation failed"
        case .fileWriteError: return "Failed to write file"
        }
    }
}

// Export data structures
private struct WorkoutPlanExport: Codable {
    let id: String
    let name: String
    let description: String
    let category: String
    let difficulty: String
    let estimatedDuration: Int
    let caloriesBurned: Int
    let exercises: [ExerciseExport]
    let isPublic: Bool
    let tags: [String]
    let createdAt: Date
}

private struct ExerciseExport: Codable {
    let id: String
    let name: String
    let sets: Int
    let reps: Int
    let weight: Double
    let duration: Int
    let distance: Double
    let restTime: Int
    let notes: String?
}

private struct NutritionLogExport: Codable {
    let startDate: Date
    let endDate: Date
    let entries: [NutritionEntryExport]
}

private struct NutritionEntryExport: Codable {
    let id: String
    let date: Date
    let mealType: String
    let foodItem: String
    let quantity: Double
    let unit: String
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let fiber: Double
    let sugar: Double
    let sodium: Double
    let notes: String?
}