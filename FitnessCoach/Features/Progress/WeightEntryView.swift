import SwiftUI

struct WeightEntryView: View {
    @ObservedObject var viewModel: ProgressTrackingViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    
    @State private var weight: String = ""
    @State private var selectedDate = Date()
    @State private var isLoading = false
    
    private var weightValue: Double? {
        Double(weight)
    }
    
    private var isValidWeight: Bool {
        guard let value = weightValue else { return false }
        return value > 50 && value < 1000
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: theme.spacing.lg) {
                    // Header Info
                    ThemedCard {
                        HStack {
                            Image(systemName: "scalemass.fill")
                                .font(.title2)
                                .foregroundColor(theme.primaryColor)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Record Weight")
                                    .font(theme.titleSmallFont)
                                    .foregroundColor(theme.textPrimary)
                                
                                Text("Track your weight progress over time")
                                    .font(theme.bodySmallFont)
                                    .foregroundColor(theme.textSecondary)
                            }
                            
                            Spacer()
                        }
                    }
                    
                    // Weight Input
                    ThemedCard {
                        VStack(alignment: .leading, spacing: theme.spacing.md) {
                            Text("Weight Entry")
                                .font(theme.titleSmallFont)
                                .foregroundColor(theme.textPrimary)
                            
                            HStack {
                                TextField("Enter weight", text: $weight)
                                    .keyboardType(.decimalPad)
                                    .font(theme.titleMediumFont)
                                    .foregroundColor(theme.textPrimary)
                                    .multilineTextAlignment(.center)
                                    .padding()
                                    .background(theme.backgroundColor)
                                    .cornerRadius(theme.cornerRadius.medium)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: theme.cornerRadius.medium)
                                            .stroke(isValidWeight ? theme.successColor : theme.textTertiary.opacity(0.3), lineWidth: 2)
                                    )
                                
                                Text("lbs")
                                    .font(theme.bodyLargeFont)
                                    .foregroundColor(theme.textSecondary)
                                    .padding(.leading, theme.spacing.sm)
                            }
                            
                            if !weight.isEmpty && !isValidWeight {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(theme.warningColor)
                                    Text("Please enter a weight between 50-1000 lbs")
                                        .font(theme.bodySmallFont)
                                        .foregroundColor(theme.warningColor)
                                    Spacer()
                                }
                            }
                        }
                    }
                    
                    // Date Selection
                    ThemedCard {
                        VStack(alignment: .leading, spacing: theme.spacing.md) {
                            Text("Date")
                                .font(theme.titleSmallFont)
                                .foregroundColor(theme.textPrimary)
                            
                            DatePicker(
                                "Select Date",
                                selection: $selectedDate,
                                in: ...Date(),
                                displayedComponents: [.date]
                            )
                            .datePickerStyle(CompactDatePickerStyle())
                        }
                    }
                    
                    Spacer(minLength: 80)
                }
                .padding(theme.spacing.md)
            }
            .navigationTitle("Add Weight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveWeight()
                    }
                    .disabled(!isValidWeight || isLoading)
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func saveWeight() {
        guard let weightValue = weightValue, isValidWeight else { return }
        
        isLoading = true
        viewModel.addWeightEntry(weight: weightValue, date: selectedDate)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isLoading = false
            dismiss()
        }
    }
}

#Preview {
    WeightEntryView(viewModel: ProgressTrackingViewModel())
        .theme(FitnessTheme())
}