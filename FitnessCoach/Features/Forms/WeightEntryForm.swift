import SwiftUI

struct WeightEntryForm: View {
    @Binding var isPresented: Bool
    let onSave: (Double) -> Void
    
    @State private var weightString = ""
    @State private var selectedUnit = "lbs"
    @FocusState private var isFocused: Bool
    @Environment(\.theme) private var theme
    
    private var weightValue: Double? {
        Double(weightString)
    }
    
    private var isValid: Bool {
        guard let weight = weightValue else { return false }
        return weight > 0 && weight < 1000
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: theme.spacing.xl) {
                Text("Enter Your Weight")
                    .font(theme.typography.titleLarge)
                    .foregroundColor(theme.textPrimary)
                
                VStack(spacing: theme.spacing.md) {
                    HStack {
                        TextField("0", text: $weightString)
                            .keyboardType(.decimalPad)
                            .font(.system(size: 48, weight: .bold))
                            .multilineTextAlignment(.center)
                            .focused($isFocused)
                        
                        Text(selectedUnit)
                            .font(theme.typography.titleMedium)
                            .foregroundColor(theme.textSecondary)
                    }
                    .padding()
                    .background(theme.surfaceColor)
                    .cornerRadius(theme.cornerRadius.medium)
                    
                    Picker("Unit", selection: $selectedUnit) {
                        Text("lbs").tag("lbs")
                        Text("kg").tag("kg")
                    }
                    .pickerStyle(.segmented)
                }
                
                if let weight = weightValue {
                    Text("Previous: 185 lbs")
                        .font(theme.typography.bodyMedium)
                        .foregroundColor(theme.textSecondary)
                    
                    let change = weight - 185
                    if change != 0 {
                        HStack {
                            Image(systemName: change > 0 ? "arrow.up" : "arrow.down")
                            Text("\(abs(change), specifier: "%.1f") \(selectedUnit)")
                        }
                        .foregroundColor(change > 0 ? .red : .green)
                        .font(theme.typography.bodySmall)
                    }
                }
                
                Spacer()
                
                HStack(spacing: theme.spacing.md) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .foregroundColor(theme.textSecondary)
                    .padding(.horizontal, theme.spacing.xl)
                    .padding(.vertical, theme.spacing.md)
                    .background(theme.surfaceColor)
                    .cornerRadius(theme.cornerRadius.medium)
                    
                    Button("Save") {
                        if let weight = weightValue {
                            let finalWeight = selectedUnit == "kg" ? weight * 2.20462 : weight
                            onSave(finalWeight)
                            isPresented = false
                        }
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, theme.spacing.xl)
                    .padding(.vertical, theme.spacing.md)
                    .background(isValid ? theme.primaryColor : theme.textTertiary)
                    .cornerRadius(theme.cornerRadius.medium)
                    .disabled(!isValid)
                }
            }
            .padding()
            .navigationBarHidden(true)
        }
        .onAppear {
            isFocused = true
        }
    }
}