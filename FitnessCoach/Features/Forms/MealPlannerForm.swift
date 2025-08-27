import SwiftUI

struct MealPlannerForm: View {
    @Binding var isPresented: Bool
    @State private var selectedDay = "Monday"
    @State private var meals: [String: [(meal: String, food: String, calories: Int)]] = [:]
    @State private var showingAddMeal = false
    @Environment(\.theme) private var theme
    
    let weekDays = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    let mealTimes = ["Breakfast", "Lunch", "Dinner", "Snack"]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Day selector
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: theme.spacing.sm) {
                        ForEach(weekDays, id: \.self) { day in
                            Button {
                                selectedDay = day
                            } label: {
                                VStack(spacing: 4) {
                                    Text(String(day.prefix(3)))
                                        .font(theme.typography.bodySmall)
                                    
                                    Circle()
                                        .fill(mealsForDay(day).isEmpty ? theme.textTertiary : theme.successColor)
                                        .frame(width: 8, height: 8)
                                }
                                .foregroundColor(selectedDay == day ? .white : theme.textPrimary)
                                .frame(width: 60, height: 60)
                                .background(
                                    selectedDay == day ?
                                    theme.primaryColor : theme.surfaceColor
                                )
                                .cornerRadius(theme.cornerRadius.medium)
                            }
                        }
                    }
                    .padding()
                }
                
                ScrollView {
                    VStack(spacing: theme.spacing.lg) {
                        // Day overview
                        VStack(spacing: theme.spacing.sm) {
                            HStack {
                                Text(selectedDay)
                                    .font(theme.typography.titleMedium)
                                    .foregroundColor(theme.textPrimary)
                                
                                Spacer()
                                
                                Text("\(totalCalories(for: selectedDay)) cal")
                                    .font(theme.typography.bodyMedium)
                                    .foregroundColor(theme.primaryColor)
                            }
                            
                            if mealsForDay(selectedDay).isEmpty {
                                VStack(spacing: theme.spacing.md) {
                                    Image(systemName: "calendar.badge.plus")
                                        .font(.system(size: 40))
                                        .foregroundColor(theme.textTertiary)
                                    
                                    Text("No meals planned")
                                        .font(theme.typography.bodyMedium)
                                        .foregroundColor(theme.textSecondary)
                                    
                                    Button {
                                        showingAddMeal = true
                                    } label: {
                                        Text("Add Meal")
                                            .font(theme.typography.bodySmall)
                                            .foregroundColor(theme.primaryColor)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(theme.spacing.xl)
                                .background(theme.surfaceColor)
                                .cornerRadius(theme.cornerRadius.medium)
                            } else {
                                ForEach(mealTimes, id: \.self) { mealTime in
                                    let mealsForTime = mealsForDay(selectedDay).filter { $0.meal == mealTime }
                                    if !mealsForTime.isEmpty {
                                        VStack(alignment: .leading, spacing: theme.spacing.sm) {
                                            HStack {
                                                Text(mealTime)
                                                    .font(theme.typography.bodyMedium)
                                                    .fontWeight(.medium)
                                                    .foregroundColor(theme.textPrimary)
                                                
                                                Spacer()
                                                
                                                Text("\(mealsForTime.reduce(0) { $0 + $1.calories }) cal")
                                                    .font(theme.typography.bodySmall)
                                                    .foregroundColor(theme.textSecondary)
                                            }
                                            
                                            ForEach(Array(mealsForTime.enumerated()), id: \.offset) { _, meal in
                                                HStack {
                                                    Text(meal.food)
                                                        .font(theme.typography.bodySmall)
                                                        .foregroundColor(theme.textPrimary)
                                                    
                                                    Spacer()
                                                    
                                                    Text("\(meal.calories) cal")
                                                        .font(theme.typography.bodySmall)
                                                        .foregroundColor(theme.textSecondary)
                                                }
                                                .padding(.vertical, 4)
                                            }
                                        }
                                        .padding()
                                        .background(theme.surfaceColor)
                                        .cornerRadius(theme.cornerRadius.medium)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Weekly summary
                        VStack(alignment: .leading, spacing: theme.spacing.md) {
                            Text("Weekly Summary")
                                .font(theme.typography.titleMedium)
                                .foregroundColor(theme.textPrimary)
                            
                            VStack(spacing: theme.spacing.sm) {
                                HStack {
                                    Text("Total Meals Planned")
                                        .font(theme.typography.bodyMedium)
                                        .foregroundColor(theme.textSecondary)
                                    Spacer()
                                    Text("\(totalMealsPlanned)")
                                        .font(theme.typography.bodyMedium)
                                        .fontWeight(.medium)
                                        .foregroundColor(theme.textPrimary)
                                }
                                
                                HStack {
                                    Text("Average Daily Calories")
                                        .font(theme.typography.bodyMedium)
                                        .foregroundColor(theme.textSecondary)
                                    Spacer()
                                    Text("\(averageDailyCalories)")
                                        .font(theme.typography.bodyMedium)
                                        .fontWeight(.medium)
                                        .foregroundColor(theme.primaryColor)
                                }
                                
                                HStack {
                                    Text("Days Planned")
                                        .font(theme.typography.bodyMedium)
                                        .foregroundColor(theme.textSecondary)
                                    Spacer()
                                    Text("\(daysWithMeals)/7")
                                        .font(theme.typography.bodyMedium)
                                        .fontWeight(.medium)
                                        .foregroundColor(theme.textPrimary)
                                }
                            }
                            .padding()
                            .background(theme.surfaceColor)
                            .cornerRadius(theme.cornerRadius.medium)
                        }
                        .padding(.horizontal)
                        
                        // Add meal button
                        Button {
                            showingAddMeal = true
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add Meal to \(selectedDay)")
                            }
                            .font(theme.typography.bodyMedium)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(theme.primaryColor)
                            .cornerRadius(theme.cornerRadius.medium)
                        }
                        .padding(.horizontal)
                        
                        // Save plan button
                        Button {
                            // Save meal plan logic
                            isPresented = false
                        } label: {
                            Text("Save Meal Plan")
                                .font(theme.typography.bodyMedium)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(theme.successColor)
                                .cornerRadius(theme.cornerRadius.medium)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Meal Planner")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
            .sheet(isPresented: $showingAddMeal) {
                AddMealSheet(isPresented: $showingAddMeal, day: selectedDay) { meal, food, calories in
                    if meals[selectedDay] == nil {
                        meals[selectedDay] = []
                    }
                    meals[selectedDay]?.append((meal: meal, food: food, calories: calories))
                }
            }
        }
    }
    
    private func mealsForDay(_ day: String) -> [(meal: String, food: String, calories: Int)] {
        return meals[day] ?? []
    }
    
    private func totalCalories(for day: String) -> Int {
        return mealsForDay(day).reduce(0) { $0 + $1.calories }
    }
    
    private var totalMealsPlanned: Int {
        return meals.values.reduce(0) { $0 + $1.count }
    }
    
    private var daysWithMeals: Int {
        return meals.filter { !$0.value.isEmpty }.count
    }
    
    private var averageDailyCalories: Int {
        guard daysWithMeals > 0 else { return 0 }
        let totalCalories = meals.values.flatMap { $0 }.reduce(0) { $0 + $1.calories }
        return totalCalories / daysWithMeals
    }
}

struct AddMealSheet: View {
    @Binding var isPresented: Bool
    let day: String
    let onSave: (String, String, Int) -> Void
    
    @State private var mealType = "Breakfast"
    @State private var foodName = ""
    @State private var calories = ""
    @Environment(\.theme) private var theme
    
    let mealTypes = ["Breakfast", "Lunch", "Dinner", "Snack"]
    let quickAddFoods = [
        ("Oatmeal Bowl", 320),
        ("Chicken Salad", 450),
        ("Protein Shake", 200),
        ("Rice & Veggies", 380),
        ("Greek Yogurt", 150),
        ("Turkey Sandwich", 420)
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: theme.spacing.lg) {
                // Meal type
                VStack(alignment: .leading, spacing: theme.spacing.sm) {
                    Text("Meal Type")
                        .font(theme.typography.titleMedium)
                        .foregroundColor(theme.textPrimary)
                    
                    HStack(spacing: theme.spacing.sm) {
                        ForEach(mealTypes, id: \.self) { type in
                            Button {
                                mealType = type
                            } label: {
                                Text(type)
                                    .font(theme.typography.bodySmall)
                                    .foregroundColor(mealType == type ? .white : theme.textPrimary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        mealType == type ?
                                        theme.primaryColor : theme.surfaceColor
                                    )
                                    .cornerRadius(theme.cornerRadius.small)
                            }
                        }
                    }
                }
                
                // Food name
                VStack(alignment: .leading, spacing: theme.spacing.sm) {
                    Text("Food")
                        .font(theme.typography.titleMedium)
                        .foregroundColor(theme.textPrimary)
                    
                    TextField("Enter food name", text: $foodName)
                        .font(theme.typography.bodyMedium)
                        .padding()
                        .background(theme.surfaceColor)
                        .cornerRadius(theme.cornerRadius.medium)
                }
                
                // Calories
                VStack(alignment: .leading, spacing: theme.spacing.sm) {
                    Text("Calories")
                        .font(theme.typography.titleMedium)
                        .foregroundColor(theme.textPrimary)
                    
                    TextField("Enter calories", text: $calories)
                        .keyboardType(.numberPad)
                        .font(theme.typography.bodyMedium)
                        .padding()
                        .background(theme.surfaceColor)
                        .cornerRadius(theme.cornerRadius.medium)
                }
                
                // Quick add options
                VStack(alignment: .leading, spacing: theme.spacing.sm) {
                    Text("Quick Add")
                        .font(theme.typography.bodyMedium)
                        .foregroundColor(theme.textSecondary)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: theme.spacing.sm) {
                        ForEach(quickAddFoods, id: \.0) { food, cal in
                            Button {
                                foodName = food
                                calories = "\(cal)"
                            } label: {
                                VStack(spacing: 4) {
                                    Text(food)
                                        .font(theme.typography.bodySmall)
                                        .foregroundColor(theme.textPrimary)
                                    Text("\(cal) cal")
                                        .font(theme.typography.bodySmall)
                                        .foregroundColor(theme.textSecondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(theme.surfaceColor)
                                .cornerRadius(theme.cornerRadius.small)
                            }
                        }
                    }
                }
                
                Spacer()
                
                // Add button
                Button {
                    if !foodName.isEmpty, let cal = Int(calories) {
                        onSave(mealType, foodName, cal)
                        isPresented = false
                    }
                } label: {
                    Text("Add to \(day)")
                        .font(theme.typography.bodyMedium)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(!foodName.isEmpty && !calories.isEmpty ? theme.primaryColor : theme.textTertiary)
                        .cornerRadius(theme.cornerRadius.medium)
                }
                .disabled(foodName.isEmpty || calories.isEmpty)
            }
            .padding()
            .navigationTitle("Add Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }
}