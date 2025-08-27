import SwiftUI

// MARK: - Quick Workout View
struct QuickWorkoutView: View {
    @EnvironmentObject private var dataManager: FitnessDataManager
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.theme) private var theme
    
    @State private var selectedTemplate: WorkoutTemplate?
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                Text("Choose a Quick Workout")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)
                
                ForEach(dataManager.workoutTemplates.filter { $0.estimatedDuration <= 45 }, id: \.id) { template in
                    WorkoutTemplateCard(template: template) {
                        selectedTemplate = template
                        dataManager.startWorkout(template: template)
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Quick Workout")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
}

struct WorkoutTemplateCard: View {
    let template: WorkoutTemplate
    let action: () -> Void
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(template.name)
                            .font(.headline)
                            .foregroundColor(theme.textPrimary)
                            .multilineTextAlignment(.leading)
                        
                        Text(template.description)
                            .font(.subheadline)
                            .foregroundColor(theme.textSecondary)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "play.circle.fill")
                        .font(.title)
                        .foregroundColor(theme.primaryColor)
                }
                
                HStack(spacing: 16) {
                    Label("\(template.estimatedDuration)m", systemImage: "clock")
                    Label(template.difficulty.rawValue, systemImage: "gauge")
                    Label("\(template.exercises.count) exercises", systemImage: "list.number")
                }
                .font(.caption)
                .foregroundColor(theme.textTertiary)
            }
            .padding()
            .background(theme.surfaceColor)
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Quick Meal Logger View
struct QuickMealLoggerView: View {
    @EnvironmentObject private var dataManager: FitnessDataManager
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.theme) private var theme
    
    @State private var searchText = ""
    @State private var selectedMealType: MealEntry.MealType = .snack
    @State private var quantity: String = "100"
    @State private var selectedFood: Food?
    
    var filteredFoods: [Food] {
        if searchText.isEmpty {
            return Array(dataManager.searchFoods("").prefix(10))
        } else {
            return dataManager.searchFoods(searchText)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 16) {
                Text("Log a Meal")
                    .font(.title2)
                    .fontWeight(.bold)
                
                // Meal Type Picker
                Picker("Meal Type", selection: $selectedMealType) {
                    ForEach(MealEntry.MealType.allCases, id: \.self) { mealType in
                        Label(mealType.rawValue, systemImage: mealType.icon)
                            .tag(mealType)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(theme.textTertiary)
                    
                    TextField("Search foods...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding()
                .background(theme.surfaceColor)
                .cornerRadius(12)
            }
            .padding()
            
            // Food List
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(filteredFoods, id: \.id) { food in
                        FoodRowCard(food: food) {
                            selectedFood = food
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .navigationTitle("Quick Meal")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
        .sheet(item: $selectedFood) { food in
            FoodQuantitySheet(
                food: food,
                mealType: selectedMealType,
                onSave: { food, quantity, mealType in
                    dataManager.logMeal(food, quantity: quantity, mealType: mealType)
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

struct FoodRowCard: View {
    let food: Food
    let action: () -> Void
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(food.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(theme.textPrimary)
                    
                    if let brand = food.brand {
                        Text(brand)
                            .font(.caption)
                            .foregroundColor(theme.textSecondary)
                    }
                    
                    Text("\(Int(food.nutritionPer100g.calories)) cal per 100g")
                        .font(.caption)
                        .foregroundColor(theme.textTertiary)
                }
                
                Spacer()
                
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(theme.primaryColor)
            }
            .padding()
            .background(theme.surfaceColor)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct FoodQuantitySheet: View {
    let food: Food
    let mealType: MealEntry.MealType
    let onSave: (Food, Double, MealEntry.MealType) -> Void
    
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.theme) private var theme
    @State private var quantity: String = "100"
    
    private var quantityDouble: Double {
        Double(quantity) ?? 100
    }
    
    private var adjustedNutrition: NutritionFacts {
        let multiplier = quantityDouble / 100.0
        let nutrition = food.nutritionPer100g
        return NutritionFacts(
            calories: nutrition.calories * multiplier,
            protein: nutrition.protein * multiplier,
            carbs: nutrition.carbs * multiplier,
            fat: nutrition.fat * multiplier,
            fiber: nutrition.fiber * multiplier,
            sugar: nutrition.sugar * multiplier,
            sodium: nutrition.sodium * multiplier,
            cholesterol: nutrition.cholesterol * multiplier
        )
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Food Info
                VStack(alignment: .leading, spacing: 8) {
                    Text(food.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if let brand = food.brand {
                        Text(brand)
                            .font(.subheadline)
                            .foregroundColor(theme.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Quantity Input
                VStack(alignment: .leading, spacing: 12) {
                    Text("Quantity (grams)")
                        .font(.headline)
                    
                    TextField("Quantity", text: $quantity)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.title2)
                }
                
                // Nutrition Preview
                VStack(alignment: .leading, spacing: 16) {
                    Text("Nutrition Facts")
                        .font(.headline)
                    
                    NutritionGrid(nutrition: adjustedNutrition)
                }
                .padding()
                .background(theme.surfaceColor)
                .cornerRadius(16)
                
                Spacer()
                
                // Save Button
                Button("Add to \(mealType.rawValue)") {
                    onSave(food, quantityDouble, mealType)
                    presentationMode.wrappedValue.dismiss()
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(theme.primaryColor)
                .cornerRadius(12)
            }
            .padding()
            .navigationTitle("Add Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

struct NutritionGrid: View {
    let nutrition: NutritionFacts
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            NutritionItemView(label: "Calories", value: "\(Int(nutrition.calories))", unit: "cal")
            NutritionItemView(label: "Protein", value: String(format: "%.1f", nutrition.protein), unit: "g")
            NutritionItemView(label: "Carbs", value: String(format: "%.1f", nutrition.carbs), unit: "g")
            NutritionItemView(label: "Fat", value: String(format: "%.1f", nutrition.fat), unit: "g")
        }
    }
}

struct NutritionItemView: View {
    let label: String
    let value: String
    let unit: String
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(theme.textSecondary)
            
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.textPrimary)
                
                Text(unit)
                    .font(.caption)
                    .foregroundColor(theme.textTertiary)
            }
        }
    }
}

// MARK: - Quick Weight Entry View
struct QuickWeightEntryView: View {
    @EnvironmentObject private var dataManager: FitnessDataManager
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.theme) private var theme
    
    @State private var weightText = ""
    @State private var bodyFatText = ""
    @State private var notes = ""
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Track Your Weight")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top)
            
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Weight (lbs)")
                        .font(.headline)
                    
                    TextField("Enter weight", text: $weightText)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.title2)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Body Fat % (optional)")
                        .font(.headline)
                    
                    TextField("Enter body fat percentage", text: $bodyFatText)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notes (optional)")
                        .font(.headline)
                    
                    TextField("Any additional notes...", text: $notes)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
            }
            
            Spacer()
            
            Button("Save Weight Entry") {
                if let weight = Double(weightText) {
                    let bodyFat = Double(bodyFatText)
                    dataManager.logWeight(weight, bodyFatPercentage: bodyFat)
                    presentationMode.wrappedValue.dismiss()
                }
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(weightText.isEmpty ? Color.gray : theme.primaryColor)
            .cornerRadius(12)
            .disabled(weightText.isEmpty)
        }
        .padding()
        .navigationTitle("Weight Entry")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
        .onAppear {
            // Pre-fill with last weight if available
            if let lastWeight = dataManager.weightEntries.last?.weight {
                weightText = String(format: "%.1f", lastWeight)
            }
        }
    }
}

// MARK: - Quick Water Entry View
struct QuickWaterEntryView: View {
    @EnvironmentObject private var dataManager: FitnessDataManager
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.theme) private var theme
    
    @State private var selectedAmount: Double = 8 // oz
    private let waterAmounts: [Double] = [4, 8, 12, 16, 20, 24, 32]
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Add Water Intake")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top)
            
            Text("How much water did you drink?")
                .font(.subheadline)
                .foregroundColor(theme.textSecondary)
            
            // Water amount picker
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(waterAmounts, id: \.self) { amount in
                    WaterAmountButton(
                        amount: amount,
                        isSelected: selectedAmount == amount
                    ) {
                        selectedAmount = amount
                    }
                }
            }
            
            // Custom amount
            VStack(alignment: .leading, spacing: 8) {
                Text("Custom Amount (oz)")
                    .font(.headline)
                
                HStack {
                    TextField("Amount", value: $selectedAmount, format: .number)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Text("oz")
                        .foregroundColor(theme.textSecondary)
                }
            }
            
            Spacer()
            
            Button("Add Water") {
                dataManager.logWater(amount: selectedAmount)
                presentationMode.wrappedValue.dismiss()
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(theme.primaryColor)
            .cornerRadius(12)
        }
        .padding()
        .navigationTitle("Water Intake")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
}

struct WaterAmountButton: View {
    let amount: Double
    let isSelected: Bool
    let action: () -> Void
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: "drop.fill")
                    .font(.title)
                    .foregroundColor(isSelected ? .white : .blue)
                
                Text("\(Int(amount)) oz")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : theme.textPrimary)
            }
            .frame(height: 80)
            .frame(maxWidth: .infinity)
            .background(isSelected ? theme.primaryColor : theme.surfaceColor)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Quick Goal Setting View
struct QuickGoalSettingView: View {
    @EnvironmentObject private var dataManager: FitnessDataManager
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.theme) private var theme
    
    @State private var title = ""
    @State private var description = ""
    @State private var selectedCategory: Goal.GoalCategory = .weight
    @State private var selectedType: Goal.GoalType = .decrease
    @State private var targetValue = ""
    @State private var unit = "lbs"
    @State private var selectedTimeframe: Int = 1 // months
    
    private let timeframes = [1, 2, 3, 6, 12]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Set a New Goal")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)
                
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Goal Title")
                            .font(.headline)
                        
                        TextField("e.g., Lose 10 pounds", text: $title)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.headline)
                        
                        TextField("Optional description...", text: $description)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Category")
                            .font(.headline)
                        
                        Picker("Category", selection: $selectedCategory) {
                            ForEach(Goal.GoalCategory.allCases, id: \.self) { category in
                                Text(category.rawValue).tag(category)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Type")
                                .font(.headline)
                            
                            Picker("Type", selection: $selectedType) {
                                ForEach(Goal.GoalType.allCases, id: \.self) { type in
                                    Text(type.rawValue).tag(type)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Target Value")
                                .font(.headline)
                            
                            HStack {
                                TextField("Value", text: $targetValue)
                                    .keyboardType(.decimalPad)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                
                                TextField("Unit", text: $unit)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .frame(width: 60)
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Timeframe")
                            .font(.headline)
                        
                        Picker("Timeframe", selection: $selectedTimeframe) {
                            ForEach(timeframes, id: \.self) { months in
                                Text("\(months) month\(months > 1 ? "s" : "")")
                                    .tag(months)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                }
                
                Button("Create Goal") {
                    createGoal()
                    presentationMode.wrappedValue.dismiss()
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(title.isEmpty || targetValue.isEmpty ? Color.gray : theme.primaryColor)
                .cornerRadius(12)
                .disabled(title.isEmpty || targetValue.isEmpty)
            }
            .padding()
        }
        .navigationTitle("New Goal")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
    
    private func createGoal() {
        guard let target = Double(targetValue) else { return }
        
        let targetDate = Calendar.current.date(byAdding: .month, value: selectedTimeframe, to: Date()) ?? Date()
        
        let goal = Goal(
            id: UUID(),
            title: title,
            description: description.isEmpty ? title : description,
            category: selectedCategory,
            type: selectedType,
            targetValue: target,
            currentValue: getCurrentValue(),
            unit: unit,
            targetDate: targetDate,
            createdAt: Date(),
            completedAt: nil,
            isActive: true,
            notes: nil
        )
        
        dataManager.addGoal(goal)
    }
    
    private func getCurrentValue() -> Double {
        // Set reasonable defaults based on category
        switch selectedCategory {
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

#Preview {
    QuickWorkoutView()
        .environmentObject(FitnessDataManager.shared)
        .environmentObject(ThemeManager())
        .theme(FitnessTheme())
}