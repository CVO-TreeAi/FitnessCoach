import SwiftUI

struct GoalSettingForm: View {
    @Binding var isPresented: Bool
    @State private var goalType = "Weight Loss"
    @State private var targetValue = ""
    @State private var targetDate = Date().addingTimeInterval(30 * 24 * 60 * 60)
    @State private var notes = ""
    @Environment(\.theme) private var theme
    
    let goalTypes = [
        ("Weight Loss", "scalemass", "lbs to lose"),
        ("Muscle Gain", "figure.strengthtraining.traditional", "lbs to gain"),
        ("Running Distance", "figure.run", "miles per week"),
        ("Workout Frequency", "calendar", "days per week"),
        ("Calorie Target", "flame.fill", "calories per day"),
        ("Water Intake", "drop.fill", "cups per day")
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: theme.spacing.lg) {
                    // Goal type selection
                    VStack(alignment: .leading, spacing: theme.spacing.md) {
                        Text("Goal Type")
                            .font(theme.typography.titleMedium)
                            .foregroundColor(theme.textPrimary)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: theme.spacing.md) {
                            ForEach(goalTypes, id: \.0) { goal in
                                Button {
                                    goalType = goal.0
                                } label: {
                                    VStack(spacing: theme.spacing.sm) {
                                        Image(systemName: goal.1)
                                            .font(.title2)
                                            .foregroundColor(goalType == goal.0 ? .white : theme.primaryColor)
                                        
                                        Text(goal.0)
                                            .font(theme.typography.bodySmall)
                                            .multilineTextAlignment(.center)
                                    }
                                    .foregroundColor(goalType == goal.0 ? .white : theme.textPrimary)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(
                                        goalType == goal.0 ?
                                        theme.primaryColor : theme.surfaceColor
                                    )
                                    .cornerRadius(theme.cornerRadius.medium)
                                }
                            }
                        }
                    }
                    
                    // Target value
                    VStack(alignment: .leading, spacing: theme.spacing.sm) {
                        Text("Target")
                            .font(theme.typography.titleMedium)
                            .foregroundColor(theme.textPrimary)
                        
                        HStack {
                            TextField("Enter target value", text: $targetValue)
                                .keyboardType(.decimalPad)
                                .font(theme.typography.bodyMedium)
                                .padding()
                                .background(theme.surfaceColor)
                                .cornerRadius(theme.cornerRadius.medium)
                            
                            Text(goalTypes.first(where: { $0.0 == goalType })?.2 ?? "")
                                .font(theme.typography.bodySmall)
                                .foregroundColor(theme.textSecondary)
                        }
                    }
                    
                    // Target date
                    VStack(alignment: .leading, spacing: theme.spacing.sm) {
                        Text("Target Date")
                            .font(theme.typography.titleMedium)
                            .foregroundColor(theme.textPrimary)
                        
                        DatePicker("", selection: $targetDate, in: Date()..., displayedComponents: .date)
                            .datePickerStyle(GraphicalDatePickerStyle())
                            .padding()
                            .background(theme.surfaceColor)
                            .cornerRadius(theme.cornerRadius.medium)
                    }
                    
                    // Notes
                    VStack(alignment: .leading, spacing: theme.spacing.sm) {
                        Text("Notes (Optional)")
                            .font(theme.typography.titleMedium)
                            .foregroundColor(theme.textPrimary)
                        
                        TextEditor(text: $notes)
                            .frame(height: 100)
                            .padding(8)
                            .background(theme.surfaceColor)
                            .cornerRadius(theme.cornerRadius.medium)
                    }
                    
                    // Save button
                    Button {
                        // Save goal logic
                        isPresented = false
                    } label: {
                        Text("Set Goal")
                            .font(theme.typography.bodyMedium)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(theme.primaryColor)
                            .cornerRadius(theme.cornerRadius.medium)
                    }
                }
                .padding()
            }
            .navigationTitle("Set New Goal")
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