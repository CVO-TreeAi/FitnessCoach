import SwiftUI

// MARK: - Weight Entry View
struct WeightEntryView: View {
    @EnvironmentObject private var dataManager: FitnessDataManager
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.theme) private var theme
    
    @State private var weight: String = ""
    @State private var bodyFatPercentage: String = ""
    @State private var muscleMass: String = ""
    @State private var notes: String = ""
    @State private var selectedDate = Date()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    
                    dateSection
                    
                    weightSection
                    
                    additionalMeasurementsSection
                    
                    notesSection
                    
                    saveButton
                }
                .padding()
            }
            .navigationTitle("Log Weight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .onAppear {
            // Pre-fill with last weight
            if let lastEntry = dataManager.weightEntries.last {
                weight = String(format: "%.1f", lastEntry.weight)
                if let bodyFat = lastEntry.bodyFatPercentage {
                    bodyFatPercentage = String(format: "%.1f", bodyFat)
                }
                if let muscle = lastEntry.muscleMass {
                    muscleMass = String(format: "%.1f", muscle)
                }
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "scalemass.fill")
                .font(.system(size: 50))
                .foregroundColor(theme.primaryColor)
            
            Text("Track Your Progress")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(theme.textPrimary)
            
            Text("Regular weigh-ins help track your fitness journey")
                .font(.subheadline)
                .foregroundColor(theme.textSecondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var dateSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Date")
                .font(.headline)
                .foregroundColor(theme.textPrimary)
            
            DatePicker("Entry Date", selection: $selectedDate, displayedComponents: [.date])
                .datePickerStyle(CompactDatePickerStyle())
                .accentColor(theme.primaryColor)
        }
        .padding()
        .background(theme.surfaceColor)
        .cornerRadius(16)
    }
    
    private var weightSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Weight")
                .font(.headline)
                .foregroundColor(theme.textPrimary)
            
            HStack {
                TextField("Enter weight", text: $weight)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.title2)
                
                Text("lbs")
                    .font(.title2)
                    .foregroundColor(theme.textSecondary)
            }
            
            // Quick weight buttons
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(generateQuickWeights(), id: \.self) { quickWeight in
                        Button("\(Int(quickWeight))") {
                            weight = String(format: "%.0f", quickWeight)
                        }
                        .font(.subheadline)
                        .foregroundColor(weight == String(format: "%.0f", quickWeight) ? .white : theme.primaryColor)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(weight == String(format: "%.0f", quickWeight) ? theme.primaryColor : theme.primaryColor.opacity(0.1))
                        .cornerRadius(20)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding()
        .background(theme.surfaceColor)
        .cornerRadius(16)
    }
    
    private var additionalMeasurementsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Additional Measurements (Optional)")
                .font(.headline)
                .foregroundColor(theme.textPrimary)
            
            VStack(spacing: 12) {
                HStack {
                    Text("Body Fat %")
                        .font(.subheadline)
                        .foregroundColor(theme.textPrimary)
                        .frame(width: 100, alignment: .leading)
                    
                    TextField("e.g. 15.5", text: $bodyFatPercentage)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                HStack {
                    Text("Muscle Mass")
                        .font(.subheadline)
                        .foregroundColor(theme.textPrimary)
                        .frame(width: 100, alignment: .leading)
                    
                    TextField("lbs", text: $muscleMass)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
            }
        }
        .padding()
        .background(theme.surfaceColor)
        .cornerRadius(16)
    }
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes (Optional)")
                .font(.headline)
                .foregroundColor(theme.textPrimary)
            
            TextField("How are you feeling? Any observations?", text: $notes, axis: .vertical)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .lineLimit(3, reservesSpace: true)
        }
        .padding()
        .background(theme.surfaceColor)
        .cornerRadius(16)
    }
    
    private var saveButton: some View {
        Button("Save Weight Entry") {
            saveEntry()
        }
        .font(.headline)
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .padding()
        .background(weight.isEmpty ? Color.gray : theme.primaryColor)
        .cornerRadius(16)
        .disabled(weight.isEmpty)
    }
    
    private func generateQuickWeights() -> [Double] {
        // Generate weights around the last entry or common range
        let lastWeight = dataManager.weightEntries.last?.weight ?? 180
        let baseWeights = [lastWeight - 5, lastWeight - 2, lastWeight, lastWeight + 2, lastWeight + 5]
        return baseWeights.filter { $0 > 0 }
    }
    
    private func saveEntry() {
        guard let weightValue = Double(weight) else { return }
        
        let bodyFat = Double(bodyFatPercentage)
        let muscle = Double(muscleMass)
        
        let entry = WeightEntry(
            id: UUID(),
            weight: weightValue,
            bodyFatPercentage: bodyFat,
            muscleMass: muscle,
            date: selectedDate,
            notes: notes.isEmpty ? nil : notes
        )
        
        dataManager.weightEntries.append(entry)
        dataManager.weightEntries.sort { $0.date < $1.date }
        
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Body Measurement Entry View
struct BodyMeasurementEntryView: View {
    @EnvironmentObject private var dataManager: FitnessDataManager
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.theme) private var theme
    
    @State private var selectedDate = Date()
    @State private var chest: String = ""
    @State private var waist: String = ""
    @State private var hips: String = ""
    @State private var biceps: String = ""
    @State private var thighs: String = ""
    @State private var neck: String = ""
    @State private var shoulders: String = ""
    @State private var forearms: String = ""
    @State private var calves: String = ""
    @State private var notes: String = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    
                    dateSection
                    
                    measurementsSection
                    
                    notesSection
                    
                    saveButton
                }
                .padding()
            }
            .navigationTitle("Body Measurements")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .onAppear {
            // Pre-fill with last measurements
            if let lastMeasurement = dataManager.bodyMeasurements.last {
                if let value = lastMeasurement.chest { chest = String(format: "%.1f", value) }
                if let value = lastMeasurement.waist { waist = String(format: "%.1f", value) }
                if let value = lastMeasurement.hips { hips = String(format: "%.1f", value) }
                if let value = lastMeasurement.biceps { biceps = String(format: "%.1f", value) }
                if let value = lastMeasurement.thighs { thighs = String(format: "%.1f", value) }
                if let value = lastMeasurement.neck { neck = String(format: "%.1f", value) }
                if let value = lastMeasurement.shoulders { shoulders = String(format: "%.1f", value) }
                if let value = lastMeasurement.forearms { forearms = String(format: "%.1f", value) }
                if let value = lastMeasurement.calves { calves = String(format: "%.1f", value) }
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "figure.arms.open")
                .font(.system(size: 50))
                .foregroundColor(theme.primaryColor)
            
            Text("Body Measurements")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(theme.textPrimary)
            
            Text("Track your body composition changes")
                .font(.subheadline)
                .foregroundColor(theme.textSecondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var dateSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Date")
                .font(.headline)
                .foregroundColor(theme.textPrimary)
            
            DatePicker("Measurement Date", selection: $selectedDate, displayedComponents: [.date])
                .datePickerStyle(CompactDatePickerStyle())
                .accentColor(theme.primaryColor)
        }
        .padding()
        .background(theme.surfaceColor)
        .cornerRadius(16)
    }
    
    private var measurementsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Measurements (inches)")
                .font(.headline)
                .foregroundColor(theme.textPrimary)
            
            VStack(spacing: 12) {
                MeasurementRow(title: "Chest", value: $chest)
                MeasurementRow(title: "Waist", value: $waist)
                MeasurementRow(title: "Hips", value: $hips)
                MeasurementRow(title: "Biceps", value: $biceps)
                MeasurementRow(title: "Thighs", value: $thighs)
                MeasurementRow(title: "Neck", value: $neck)
                MeasurementRow(title: "Shoulders", value: $shoulders)
                MeasurementRow(title: "Forearms", value: $forearms)
                MeasurementRow(title: "Calves", value: $calves)
            }
        }
        .padding()
        .background(theme.surfaceColor)
        .cornerRadius(16)
    }
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes (Optional)")
                .font(.headline)
                .foregroundColor(theme.textPrimary)
            
            TextField("Any observations or notes?", text: $notes, axis: .vertical)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .lineLimit(3, reservesSpace: true)
        }
        .padding()
        .background(theme.surfaceColor)
        .cornerRadius(16)
    }
    
    private var saveButton: some View {
        Button("Save Measurements") {
            saveMeasurements()
        }
        .font(.headline)
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .padding()
        .background(hasAnyMeasurement ? theme.primaryColor : Color.gray)
        .cornerRadius(16)
        .disabled(!hasAnyMeasurement)
    }
    
    private var hasAnyMeasurement: Bool {
        !chest.isEmpty || !waist.isEmpty || !hips.isEmpty || !biceps.isEmpty ||
        !thighs.isEmpty || !neck.isEmpty || !shoulders.isEmpty || !forearms.isEmpty || !calves.isEmpty
    }
    
    private func saveMeasurements() {
        let measurement = BodyMeasurement(
            id: UUID(),
            date: selectedDate,
            chest: Double(chest),
            waist: Double(waist),
            hips: Double(hips),
            biceps: Double(biceps),
            thighs: Double(thighs),
            neck: Double(neck),
            shoulders: Double(shoulders),
            forearms: Double(forearms),
            calves: Double(calves),
            notes: notes.isEmpty ? nil : notes
        )
        
        dataManager.logBodyMeasurement(measurement)
        presentationMode.wrappedValue.dismiss()
    }
}

struct MeasurementRow: View {
    let title: String
    @Binding var value: String
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(theme.textPrimary)
                .frame(width: 80, alignment: .leading)
            
            TextField("0.0", text: $value)
                .keyboardType(.decimalPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Text("in")
                .font(.subheadline)
                .foregroundColor(theme.textSecondary)
                .frame(width: 20)
        }
    }
}

// MARK: - Goal Creation View
struct GoalCreationView: View {
    @EnvironmentObject private var dataManager: FitnessDataManager
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.theme) private var theme
    
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var category: Goal.GoalCategory = .weight
    @State private var goalType: Goal.GoalType = .decrease
    @State private var targetValue: String = ""
    @State private var unit: String = "lbs"
    @State private var targetDate: Date = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()
    @State private var notes: String = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    
                    goalBasicsSection
                    
                    goalDetailsSection
                    
                    targetSection
                    
                    notesSection
                    
                    createButton
                }
                .padding()
            }
            .navigationTitle("Create Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "target")
                .font(.system(size: 50))
                .foregroundColor(theme.primaryColor)
            
            Text("Set a New Goal")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(theme.textPrimary)
            
            Text("Define what you want to achieve")
                .font(.subheadline)
                .foregroundColor(theme.textSecondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var goalBasicsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Goal Basics")
                .font(.headline)
                .foregroundColor(theme.textPrimary)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Title")
                    .font(.subheadline)
                    .foregroundColor(theme.textPrimary)
                
                TextField("e.g., Lose 10 pounds", text: $title)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Description (Optional)")
                    .font(.subheadline)
                    .foregroundColor(theme.textPrimary)
                
                TextField("More details about your goal", text: $description, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .lineLimit(2, reservesSpace: true)
            }
        }
        .padding()
        .background(theme.surfaceColor)
        .cornerRadius(16)
    }
    
    private var goalDetailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Goal Details")
                .font(.headline)
                .foregroundColor(theme.textPrimary)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Category")
                    .font(.subheadline)
                    .foregroundColor(theme.textPrimary)
                
                Picker("Category", selection: $category) {
                    ForEach(Goal.GoalCategory.allCases, id: \.self) { cat in
                        Text(cat.rawValue).tag(cat)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .onChange(of: category) { newCategory in
                    updateUnitForCategory(newCategory)
                    updateGoalTypeForCategory(newCategory)
                }
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Goal Type")
                    .font(.subheadline)
                    .foregroundColor(theme.textPrimary)
                
                Picker("Type", selection: $goalType) {
                    ForEach(Goal.GoalType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
        }
        .padding()
        .background(theme.surfaceColor)
        .cornerRadius(16)
    }
    
    private var targetSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Target")
                .font(.headline)
                .foregroundColor(theme.textPrimary)
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Target Value")
                        .font(.subheadline)
                        .foregroundColor(theme.textPrimary)
                    
                    TextField("Value", text: $targetValue)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Unit")
                        .font(.subheadline)
                        .foregroundColor(theme.textPrimary)
                    
                    TextField("Unit", text: $unit)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 80)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Target Date")
                    .font(.subheadline)
                    .foregroundColor(theme.textPrimary)
                
                DatePicker("Target Date", selection: $targetDate, in: Date()..., displayedComponents: [.date])
                    .datePickerStyle(CompactDatePickerStyle())
                    .accentColor(theme.primaryColor)
            }
        }
        .padding()
        .background(theme.surfaceColor)
        .cornerRadius(16)
    }
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes (Optional)")
                .font(.headline)
                .foregroundColor(theme.textPrimary)
            
            TextField("Any additional notes or motivation?", text: $notes, axis: .vertical)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .lineLimit(3, reservesSpace: true)
        }
        .padding()
        .background(theme.surfaceColor)
        .cornerRadius(16)
    }
    
    private var createButton: some View {
        Button("Create Goal") {
            createGoal()
        }
        .font(.headline)
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .padding()
        .background((title.isEmpty || targetValue.isEmpty) ? Color.gray : theme.primaryColor)
        .cornerRadius(16)
        .disabled(title.isEmpty || targetValue.isEmpty)
    }
    
    private func updateUnitForCategory(_ category: Goal.GoalCategory) {
        switch category {
        case .weight:
            unit = "lbs"
        case .strength:
            unit = "lbs"
        case .endurance:
            unit = "minutes"
        case .nutrition:
            unit = "calories"
        case .habit:
            unit = "days"
        case .body:
            unit = "%"
        }
    }
    
    private func updateGoalTypeForCategory(_ category: Goal.GoalCategory) {
        switch category {
        case .weight, .body:
            goalType = .decrease
        case .strength, .endurance, .habit:
            goalType = .increase
        case .nutrition:
            goalType = .achieve
        }
    }
    
    private func createGoal() {
        guard let target = Double(targetValue) else { return }
        
        let goal = Goal(
            id: UUID(),
            title: title,
            description: description.isEmpty ? title : description,
            category: category,
            type: goalType,
            targetValue: target,
            currentValue: getCurrentValueForCategory(),
            unit: unit,
            targetDate: targetDate,
            createdAt: Date(),
            completedAt: nil,
            isActive: true,
            notes: notes.isEmpty ? nil : notes
        )
        
        dataManager.addGoal(goal)
        presentationMode.wrappedValue.dismiss()
    }
    
    private func getCurrentValueForCategory() -> Double {
        switch category {
        case .weight:
            return dataManager.weightEntries.last?.weight ?? 185.0
        case .strength:
            return 0.0 // Will be updated as workouts are completed
        case .endurance:
            return 0.0
        case .nutrition:
            return 0.0
        case .habit:
            return 0.0
        case .body:
            return dataManager.weightEntries.last?.bodyFatPercentage ?? 20.0
        }
    }
}

// MARK: - Progress Photo View
struct ProgressPhotoView: View {
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.theme) private var theme
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 60))
                    .foregroundColor(theme.primaryColor)
                
                Text("Progress Photos")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(theme.textPrimary)
                
                Text("Coming Soon!")
                    .font(.headline)
                    .foregroundColor(theme.textSecondary)
                
                Text("Progress photo capture and comparison will be available in a future update.")
                    .font(.subheadline)
                    .foregroundColor(theme.textTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Progress Photos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Personal Records View
struct PersonalRecordsView: View {
    @EnvironmentObject private var dataManager: FitnessDataManager
    @Environment(\.theme) private var theme
    
    @State private var selectedRecordType: PersonalRecord.RecordType?
    
    private var filteredRecords: [PersonalRecord] {
        if let recordType = selectedRecordType {
            return dataManager.personalRecords.filter { $0.recordType == recordType }
        }
        return dataManager.personalRecords
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Record Type Filter
                recordTypeFilter
                
                // Records List
                if filteredRecords.isEmpty {
                    emptyRecordsState
                } else {
                    recordsList
                }
            }
            .padding()
        }
        .navigationTitle("Personal Records")
        .navigationBarTitleDisplayMode(.large)
    }
    
    private var recordTypeFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                CategoryFilterButton(
                    title: "All",
                    isSelected: selectedRecordType == nil
                ) {
                    selectedRecordType = nil
                }
                
                ForEach(PersonalRecord.RecordType.allCases, id: \.self) { recordType in
                    CategoryFilterButton(
                        title: recordType.rawValue,
                        isSelected: selectedRecordType == recordType
                    ) {
                        selectedRecordType = selectedRecordType == recordType ? nil : recordType
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var recordsList: some View {
        VStack(spacing: 12) {
            ForEach(filteredRecords.sorted { $0.achievedAt > $1.achievedAt }, id: \.id) { record in
                PersonalRecordCard(record: record)
            }
        }
    }
    
    private var emptyRecordsState: some View {
        VStack(spacing: 16) {
            Image(systemName: "trophy")
                .font(.system(size: 50))
                .foregroundColor(theme.textTertiary)
            
            Text("No Records Yet")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(theme.textPrimary)
            
            Text("Complete workouts and achieve new personal records!")
                .font(.subheadline)
                .foregroundColor(theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 40)
    }
}

struct PersonalRecordCard: View {
    let record: PersonalRecord
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        HStack {
            Image(systemName: "trophy.fill")
                .font(.title2)
                .foregroundColor(.yellow)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(record.exerciseName)
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(theme.textPrimary)
                
                Text(record.recordType.rawValue)
                    .font(.subheadline)
                    .foregroundColor(theme.textSecondary)
                
                Text("Achieved on \(DateFormatter.shortDateFormatter.string(from: record.achievedAt))")
                    .font(.caption)
                    .foregroundColor(theme.textTertiary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(record.value))")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(theme.primaryColor)
                
                Text(record.unit)
                    .font(.caption)
                    .foregroundColor(theme.textSecondary)
            }
        }
        .padding()
        .background(theme.surfaceColor)
        .cornerRadius(16)
    }
}

extension DateFormatter {
    static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
}

#Preview {
    WeightEntryView()
        .environmentObject(FitnessDataManager.shared)
        .environmentObject(ThemeManager())
        .theme(FitnessTheme())
}