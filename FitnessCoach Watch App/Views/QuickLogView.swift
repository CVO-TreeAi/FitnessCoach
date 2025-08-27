import SwiftUI

struct QuickLogView: View {
    @EnvironmentObject private var dataStore: WatchDataStore
    @EnvironmentObject private var hapticManager: HapticManager
    @EnvironmentObject private var healthKitManager: WatchHealthKitManager
    
    @State private var selectedCategory: QuickLogCategory = .nutrition
    @State private var showingAddEntry = false
    @State private var showingWaterLog = false
    @State private var showingWeightEntry = false
    
    enum QuickLogCategory: String, CaseIterable {
        case nutrition = "nutrition"
        case body = "body"
        case mood = "mood"
        case water = "water"
        
        var title: String {
            switch self {
            case .nutrition: return "Nutrition"
            case .body: return "Body"
            case .mood: return "Mood"
            case .water: return "Water"
            }
        }
        
        var icon: String {
            switch self {
            case .nutrition: return "fork.knife"
            case .body: return "figure.arms.open"
            case .mood: return "face.smiling"
            case .water: return "drop.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .nutrition: return WatchTheme.Colors.protein
            case .body: return WatchTheme.Colors.primary
            case .mood: return WatchTheme.Colors.accent
            case .water: return WatchTheme.Colors.water
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: WatchTheme.Spacing.md) {
                // Header
                headerSection
                
                // Quick Action Buttons
                quickActionsGrid
                
                // Category Selector
                categorySelector
                
                // Category Content
                categoryContent
                
                // Recent Entries
                if !dataStore.quickLogs.isEmpty {
                    recentEntriesSection
                }
            }
            .padding(.horizontal, WatchTheme.Spacing.watchPadding)
        }
        .background(WatchTheme.Colors.background)
        .sheet(isPresented: $showingWaterLog) {
            WaterLogSheet()
        }
        .sheet(isPresented: $showingWeightEntry) {
            WeightEntrySheet()
        }
        .sheet(isPresented: $showingAddEntry) {
            QuickEntrySheet(category: selectedCategory)
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: WatchTheme.Spacing.xs) {
            HStack {
                Text("Quick Log")
                    .font(WatchTheme.Typography.headlineMedium)
                    .foregroundColor(WatchTheme.Colors.textPrimary)
                
                Spacer()
                
                Text(Date().formatted(date: .abbreviated, time: .omitted))
                    .font(WatchTheme.Typography.bodySmall)
                    .foregroundColor(WatchTheme.Colors.textSecondary)
            }
            
            Text("Fast data entry for tracking")
                .font(WatchTheme.Typography.bodySmall)
                .foregroundColor(WatchTheme.Colors.textSecondary)
        }
    }
    
    // MARK: - Quick Actions Grid
    
    private var quickActionsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: WatchTheme.Spacing.sm) {
            
            // Water Button
            quickActionButton(
                title: "Water",
                subtitle: "\(String(format: "%.0f", dataStore.getTodayWaterIntake())) fl oz",
                icon: "drop.fill",
                color: WatchTheme.Colors.water
            ) {
                showingWaterLog = true
            }
            
            // Weight Button
            quickActionButton(
                title: "Weight",
                subtitle: weightSubtitle,
                icon: "scalemass.fill",
                color: WatchTheme.Colors.primary
            ) {
                showingWeightEntry = true
            }
            
            // Calories Button
            quickActionButton(
                title: "Calories",
                subtitle: "\(dataStore.userStats.caloriesToday) cal",
                icon: "flame.fill",
                color: WatchTheme.Colors.calories
            ) {
                selectedCategory = .nutrition
                showingAddEntry = true
            }
            
            // Mood Button
            quickActionButton(
                title: "Mood",
                subtitle: "Log feeling",
                icon: "face.smiling",
                color: WatchTheme.Colors.accent
            ) {
                selectedCategory = .mood
                showingAddEntry = true
            }
        }
    }
    
    private func quickActionButton(
        title: String,
        subtitle: String,
        icon: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: {
            hapticManager.playSelectionHaptic()
            action()
        }) {
            VStack(alignment: .leading, spacing: WatchTheme.Spacing.xs) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(color)
                    
                    Spacer()
                }
                
                Text(title)
                    .font(WatchTheme.Typography.labelLarge)
                    .foregroundColor(WatchTheme.Colors.textPrimary)
                    .lineLimit(1)
                
                Text(subtitle)
                    .font(WatchTheme.Typography.caption)
                    .foregroundColor(WatchTheme.Colors.textSecondary)
                    .lineLimit(1)
            }
            .padding(WatchTheme.Spacing.sm)
            .frame(minHeight: 60)
        }
        .buttonStyle(PlainButtonStyle())
        .background(
            RoundedRectangle(cornerRadius: WatchTheme.CornerRadius.watchCard)
                .fill(WatchTheme.Colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: WatchTheme.CornerRadius.watchCard)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Category Selector
    
    private var categorySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: WatchTheme.Spacing.sm) {
                ForEach(QuickLogCategory.allCases, id: \.self) { category in
                    categoryTab(category)
                }
            }
            .padding(.horizontal, WatchTheme.Spacing.watchPadding)
        }
    }
    
    private func categoryTab(_ category: QuickLogCategory) -> some View {
        Button {
            hapticManager.playSelectionHaptic()
            selectedCategory = category
        } label: {
            HStack(spacing: WatchTheme.Spacing.xs) {
                Image(systemName: category.icon)
                    .font(.system(size: 12))
                
                Text(category.title)
                    .font(WatchTheme.Typography.labelMedium)
            }
            .padding(.horizontal, WatchTheme.Spacing.sm)
            .padding(.vertical, WatchTheme.Spacing.xs)
            .foregroundColor(
                selectedCategory == category ? WatchTheme.Colors.textOnPrimary : WatchTheme.Colors.textSecondary
            )
            .background(
                RoundedRectangle(cornerRadius: WatchTheme.CornerRadius.sm)
                    .fill(
                        selectedCategory == category ? category.color : Color.clear
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Category Content
    
    private var categoryContent: some View {
        VStack(alignment: .leading, spacing: WatchTheme.Spacing.md) {
            HStack {
                Text(selectedCategory.title)
                    .font(WatchTheme.Typography.labelLarge)
                    .foregroundColor(WatchTheme.Colors.textPrimary)
                
                Spacer()
                
                Button("Add") {
                    hapticManager.playButtonPressHaptic()
                    showingAddEntry = true
                }
                .font(WatchTheme.Typography.labelMedium)
                .foregroundColor(selectedCategory.color)
            }
            
            categorySpecificContent
        }
        .padding(WatchTheme.Spacing.sm)
        .watchCard()
    }
    
    private var categorySpecificContent: some View {
        Group {
            switch selectedCategory {
            case .nutrition:
                nutritionContent
            case .body:
                bodyContent
            case .mood:
                moodContent
            case .water:
                waterContent
            }
        }
    }
    
    // MARK: - Category Specific Content
    
    private var nutritionContent: some View {
        VStack(alignment: .leading, spacing: WatchTheme.Spacing.sm) {
            nutritionQuickButton("Protein", icon: "fish.fill", type: .protein)
            nutritionQuickButton("Carbs", icon: "leaf.fill", type: .carbs)
            nutritionQuickButton("Fats", icon: "drop.fill", type: .fats)
        }
    }
    
    private func nutritionQuickButton(_ title: String, icon: String, type: QuickLogType) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(nutritionColor(for: type))
                .frame(width: 20)
            
            Text(title)
                .font(WatchTheme.Typography.bodySmall)
                .foregroundColor(WatchTheme.Colors.textPrimary)
            
            Spacer()
            
            Text(getTodayTotal(for: type))
                .font(WatchTheme.Typography.bodySmall)
                .foregroundColor(WatchTheme.Colors.textSecondary)
            
            Text("g")
                .font(WatchTheme.Typography.caption)
                .foregroundColor(WatchTheme.Colors.textTertiary)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            hapticManager.playSelectionHaptic()
            // Could open specific entry sheet for this macro
        }
    }
    
    private var bodyContent: some View {
        VStack(alignment: .leading, spacing: WatchTheme.Spacing.sm) {
            if let latestWeight = dataStore.getLatestBodyMetric(.weight) {
                metricRow("Weight", value: String(format: "%.1f", latestWeight.value), unit: "lbs", date: latestWeight.timestamp)
            } else {
                Text("No body metrics logged")
                    .font(WatchTheme.Typography.bodySmall)
                    .foregroundColor(WatchTheme.Colors.textSecondary)
            }
        }
    }
    
    private var moodContent: some View {
        VStack(alignment: .leading, spacing: WatchTheme.Spacing.sm) {
            moodQuickButton("Energy", icon: "bolt.fill")
            moodQuickButton("Sleep", icon: "moon.fill")
            moodQuickButton("Stress", icon: "cloud.fill")
        }
    }
    
    private func moodQuickButton(_ title: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(WatchTheme.Colors.accent)
                .frame(width: 20)
            
            Text(title)
                .font(WatchTheme.Typography.bodySmall)
                .foregroundColor(WatchTheme.Colors.textPrimary)
            
            Spacer()
            
            Text("Rate")
                .font(WatchTheme.Typography.caption)
                .foregroundColor(WatchTheme.Colors.textSecondary)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            hapticManager.playSelectionHaptic()
            // Could open rating picker
        }
    }
    
    private var waterContent: some View {
        VStack(alignment: .leading, spacing: WatchTheme.Spacing.sm) {
            HStack {
                Text("Today's Intake")
                    .font(WatchTheme.Typography.bodySmall)
                    .foregroundColor(WatchTheme.Colors.textPrimary)
                
                Spacer()
                
                Text(String(format: "%.0f fl oz", dataStore.getTodayWaterIntake()))
                    .font(WatchTheme.Typography.bodyMedium)
                    .foregroundColor(WatchTheme.Colors.water)
            }
            
            // Water goal progress
            if let goal = dataStore.getGoalProgress(.water) {
                ProgressView(value: goal.progressPercentage)
                    .progressViewStyle(LinearProgressViewStyle(tint: WatchTheme.Colors.water))
                    .frame(height: 4)
            }
        }
    }
    
    // MARK: - Recent Entries Section
    
    private var recentEntriesSection: some View {
        VStack(alignment: .leading, spacing: WatchTheme.Spacing.sm) {
            Text("Recent Entries")
                .font(WatchTheme.Typography.labelLarge)
                .foregroundColor(WatchTheme.Colors.textPrimary)
            
            LazyVStack(spacing: WatchTheme.Spacing.xs) {
                ForEach(Array(todayQuickLogs.prefix(3)), id: \.id) { entry in
                    recentEntryRow(entry)
                }
            }
        }
        .padding(WatchTheme.Spacing.sm)
        .watchCard()
    }
    
    private func recentEntryRow(_ entry: QuickLogEntry) -> some View {
        HStack {
            Image(systemName: quickLogIcon(for: entry.type))
                .font(.system(size: 10))
                .foregroundColor(quickLogColor(for: entry.type))
                .frame(width: 16)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(entry.type.displayName)
                    .font(WatchTheme.Typography.bodySmall)
                    .foregroundColor(WatchTheme.Colors.textPrimary)
                
                if let note = entry.note {
                    Text(note)
                        .font(WatchTheme.Typography.caption)
                        .foregroundColor(WatchTheme.Colors.textSecondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text("\(String(format: "%.0f", entry.value))\(entry.type.unit)")
                    .font(WatchTheme.Typography.bodySmall)
                    .foregroundColor(WatchTheme.Colors.textPrimary)
                
                Text(entry.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(WatchTheme.Typography.caption)
                    .foregroundColor(WatchTheme.Colors.textTertiary)
            }
        }
        .padding(.vertical, 2)
    }
    
    private func metricRow(_ title: String, value: String, unit: String, date: Date) -> some View {
        HStack {
            Text(title)
                .font(WatchTheme.Typography.bodySmall)
                .foregroundColor(WatchTheme.Colors.textPrimary)
            
            Spacer()
            
            Text("\(value) \(unit)")
                .font(WatchTheme.Typography.bodySmall)
                .foregroundColor(WatchTheme.Colors.textSecondary)
            
            Text(formatRelativeTime(date))
                .font(WatchTheme.Typography.caption)
                .foregroundColor(WatchTheme.Colors.textTertiary)
        }
    }
    
    // MARK: - Helper Properties and Methods
    
    private var weightSubtitle: String {
        if let weight = dataStore.getLatestBodyMetric(.weight) {
            return String(format: "%.1f lbs", weight.value)
        }
        return "Not logged"
    }
    
    private var todayQuickLogs: [QuickLogEntry] {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay) ?? Date()
        
        return dataStore.quickLogs
            .filter { $0.timestamp >= startOfDay && $0.timestamp < endOfDay }
            .sorted { $0.timestamp > $1.timestamp }
    }
    
    private func getTodayTotal(for type: QuickLogType) -> String {
        let total = todayQuickLogs
            .filter { $0.type == type }
            .reduce(0) { $0 + $1.value }
        return String(format: "%.0f", total)
    }
    
    private func nutritionColor(for type: QuickLogType) -> Color {
        switch type {
        case .protein: return WatchTheme.Colors.protein
        case .carbs: return WatchTheme.Colors.carbs
        case .fats: return WatchTheme.Colors.fats
        default: return WatchTheme.Colors.textSecondary
        }
    }
    
    private func quickLogIcon(for type: QuickLogType) -> String {
        switch type {
        case .calories: return "flame.fill"
        case .protein: return "fish.fill"
        case .carbs: return "leaf.fill"
        case .fats: return "drop.fill"
        case .mood: return "face.smiling"
        case .energy: return "bolt.fill"
        }
    }
    
    private func quickLogColor(for type: QuickLogType) -> Color {
        switch type {
        case .calories: return WatchTheme.Colors.calories
        case .protein: return WatchTheme.Colors.protein
        case .carbs: return WatchTheme.Colors.carbs
        case .fats: return WatchTheme.Colors.fats
        case .mood: return WatchTheme.Colors.accent
        case .energy: return WatchTheme.Colors.accent
        }
    }
    
    private func formatRelativeTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Entry Sheets

struct WaterLogSheet: View {
    @EnvironmentObject private var dataStore: WatchDataStore
    @EnvironmentObject private var hapticManager: HapticManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedAmount: Double = 8.0
    
    private let commonAmounts: [Double] = [4, 8, 12, 16, 20, 32]
    
    var body: some View {
        VStack(spacing: WatchTheme.Spacing.md) {
            Text("Log Water")
                .font(WatchTheme.Typography.headlineSmall)
                .foregroundColor(WatchTheme.Colors.textPrimary)
            
            // Amount picker
            Picker("Amount", selection: $selectedAmount) {
                ForEach(commonAmounts, id: \.self) { amount in
                    Text("\(String(format: "%.0f", amount)) fl oz")
                        .tag(amount)
                }
            }
            .pickerStyle(.wheel)
            
            HStack(spacing: WatchTheme.Spacing.md) {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(WatchTheme.Components.secondaryButtonStyle())
                
                Button("Log") {
                    hapticManager.playSuccessHaptic()
                    dataStore.addWaterEntry(selectedAmount)
                    dismiss()
                }
                .buttonStyle(WatchTheme.Components.primaryButtonStyle())
            }
        }
        .padding(WatchTheme.Spacing.md)
        .background(WatchTheme.Colors.background)
    }
}

struct WeightEntrySheet: View {
    @EnvironmentObject private var dataStore: WatchDataStore
    @EnvironmentObject private var healthKitManager: WatchHealthKitManager
    @EnvironmentObject private var hapticManager: HapticManager
    @Environment(\.dismiss) private var dismiss
    @State private var weight: Double = 150.0
    
    var body: some View {
        VStack(spacing: WatchTheme.Spacing.md) {
            Text("Log Weight")
                .font(WatchTheme.Typography.headlineSmall)
                .foregroundColor(WatchTheme.Colors.textPrimary)
            
            // Weight input using Digital Crown
            VStack {
                Text(String(format: "%.1f", weight))
                    .font(WatchTheme.Typography.displayMedium)
                    .foregroundColor(WatchTheme.Colors.primary)
                
                Text("lbs")
                    .font(WatchTheme.Typography.bodySmall)
                    .foregroundColor(WatchTheme.Colors.textSecondary)
            }
            .focusable()
            .digitalCrownRotation($weight, from: 50, through: 400, by: 0.1, sensitivity: .medium)
            
            HStack(spacing: WatchTheme.Spacing.md) {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(WatchTheme.Components.secondaryButtonStyle())
                
                Button("Save") {
                    saveWeight()
                }
                .buttonStyle(WatchTheme.Components.primaryButtonStyle())
            }
        }
        .padding(WatchTheme.Spacing.md)
        .background(WatchTheme.Colors.background)
        .onAppear {
            // Load current weight if available
            if let currentWeight = dataStore.getLatestBodyMetric(.weight)?.value {
                weight = currentWeight
            }
        }
    }
    
    private func saveWeight() {
        hapticManager.playSuccessHaptic()
        dataStore.addBodyMetric(.weight, value: weight, unit: "lbs")
        
        // Also save to HealthKit if authorized
        Task {
            do {
                try await healthKitManager.saveBodyWeight(weight)
            } catch {
                print("Failed to save weight to HealthKit: \(error)")
            }
        }
        
        dismiss()
    }
}

struct QuickEntrySheet: View {
    let category: QuickLogView.QuickLogCategory
    @EnvironmentObject private var dataStore: WatchDataStore
    @EnvironmentObject private var hapticManager: HapticManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedType: QuickLogType = .calories
    @State private var value: Double = 0
    @State private var note: String = ""
    
    var body: some View {
        VStack(spacing: WatchTheme.Spacing.md) {
            Text("Quick Entry")
                .font(WatchTheme.Typography.headlineSmall)
                .foregroundColor(WatchTheme.Colors.textPrimary)
            
            // Type picker based on category
            Picker("Type", selection: $selectedType) {
                ForEach(typesForCategory, id: \.self) { type in
                    Text(type.displayName).tag(type)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 60)
            
            // Value input
            VStack {
                Text(String(format: "%.0f", value))
                    .font(WatchTheme.Typography.displayMedium)
                    .foregroundColor(category.color)
                
                Text(selectedType.unit)
                    .font(WatchTheme.Typography.bodySmall)
                    .foregroundColor(WatchTheme.Colors.textSecondary)
            }
            .focusable()
            .digitalCrownRotation($value, from: 0, through: valueRange.upperBound, by: valueIncrement, sensitivity: .medium)
            
            HStack(spacing: WatchTheme.Spacing.md) {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(WatchTheme.Components.secondaryButtonStyle())
                
                Button("Log") {
                    logEntry()
                }
                .buttonStyle(WatchTheme.Components.primaryButtonStyle())
                .disabled(value == 0)
            }
        }
        .padding(WatchTheme.Spacing.md)
        .background(WatchTheme.Colors.background)
        .onAppear {
            selectedType = typesForCategory.first ?? .calories
        }
    }
    
    private var typesForCategory: [QuickLogType] {
        switch category {
        case .nutrition:
            return [.calories, .protein, .carbs, .fats]
        case .mood:
            return [.mood, .energy]
        case .body, .water:
            return [.calories] // Fallback
        }
    }
    
    private var valueRange: ClosedRange<Double> {
        switch selectedType {
        case .calories:
            return 0...2000
        case .protein, .carbs, .fats:
            return 0...200
        case .mood, .energy:
            return 1...10
        }
    }
    
    private var valueIncrement: Double {
        switch selectedType {
        case .calories:
            return 10
        case .protein, .carbs, .fats:
            return 1
        case .mood, .energy:
            return 1
        }
    }
    
    private func logEntry() {
        hapticManager.playSuccessHaptic()
        dataStore.addQuickLog(selectedType, value: value, note: note.isEmpty ? nil : note)
        dismiss()
    }
}

#Preview("Quick Log") {
    QuickLogView()
        .environmentObject(WatchDataStore())
        .environmentObject(HapticManager())
        .environmentObject(WatchHealthKitManager())
}

#Preview("Water Log Sheet") {
    WaterLogSheet()
        .environmentObject(WatchDataStore())
        .environmentObject(HapticManager())
}