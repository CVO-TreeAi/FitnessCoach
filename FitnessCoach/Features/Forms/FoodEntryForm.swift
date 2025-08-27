import SwiftUI

struct FoodEntryForm: View {
    @Binding var isPresented: Bool
    let mealType: String
    let onSave: (String, Int) -> Void
    
    @State private var searchText = ""
    @State private var selectedFood: String?
    @State private var servingSize = "1"
    @State private var calories = ""
    @Environment(\.theme) private var theme
    
    let commonFoods = [
        ("Chicken Breast", 165),
        ("Brown Rice", 216),
        ("Broccoli", 55),
        ("Salmon", 208),
        ("Sweet Potato", 103),
        ("Eggs", 155),
        ("Greek Yogurt", 100),
        ("Oatmeal", 158),
        ("Banana", 105),
        ("Apple", 95),
        ("Protein Shake", 160),
        ("Almonds", 164)
    ]
    
    var filteredFoods: [(String, Int)] {
        if searchText.isEmpty {
            return commonFoods
        } else {
            return commonFoods.filter { $0.0.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(theme.textSecondary)
                    
                    TextField("Search foods...", text: $searchText)
                        .font(theme.typography.bodyMedium)
                }
                .padding()
                .background(theme.surfaceColor)
                .cornerRadius(theme.cornerRadius.medium)
                .padding()
                
                // Food list
                ScrollView {
                    LazyVStack(spacing: theme.spacing.sm) {
                        ForEach(filteredFoods, id: \.0) { food, cals in
                            Button {
                                selectedFood = food
                                calories = "\(cals)"
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(food)
                                            .font(theme.typography.bodyMedium)
                                            .foregroundColor(theme.textPrimary)
                                        Text("\(cals) cal per serving")
                                            .font(theme.typography.bodySmall)
                                            .foregroundColor(theme.textSecondary)
                                    }
                                    
                                    Spacer()
                                    
                                    if selectedFood == food {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(theme.primaryColor)
                                    }
                                }
                                .padding()
                                .background(selectedFood == food ? theme.primaryColor.opacity(0.1) : theme.surfaceColor)
                                .cornerRadius(theme.cornerRadius.medium)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Selected food details
                if let selected = selectedFood {
                    VStack(spacing: theme.spacing.md) {
                        HStack {
                            Text("Serving Size")
                                .font(theme.typography.bodyMedium)
                            
                            Spacer()
                            
                            HStack {
                                Button {
                                    if let size = Int(servingSize), size > 1 {
                                        servingSize = "\(size - 1)"
                                    }
                                } label: {
                                    Image(systemName: "minus.circle")
                                        .foregroundColor(theme.primaryColor)
                                }
                                
                                TextField("1", text: $servingSize)
                                    .keyboardType(.numberPad)
                                    .frame(width: 50)
                                    .multilineTextAlignment(.center)
                                    .font(theme.typography.bodyMedium)
                                
                                Button {
                                    if let size = Int(servingSize) {
                                        servingSize = "\(size + 1)"
                                    }
                                } label: {
                                    Image(systemName: "plus.circle")
                                        .foregroundColor(theme.primaryColor)
                                }
                            }
                        }
                        
                        HStack {
                            Text("Total Calories")
                                .font(theme.typography.bodyMedium)
                            Spacer()
                            Text("\(Int(Double(calories) ?? 0) * (Int(servingSize) ?? 1)) cal")
                                .font(theme.typography.titleMedium)
                                .foregroundColor(theme.primaryColor)
                        }
                    }
                    .padding()
                    .background(theme.surfaceColor)
                    .cornerRadius(theme.cornerRadius.medium)
                    .padding()
                }
                
                // Add button
                Button {
                    if let selected = selectedFood,
                       let cals = Int(calories),
                       let serving = Int(servingSize) {
                        onSave(selected, cals * serving)
                        isPresented = false
                    }
                } label: {
                    Text("Add to \(mealType)")
                        .font(theme.typography.bodyMedium)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedFood != nil ? theme.primaryColor : theme.textTertiary)
                        .cornerRadius(theme.cornerRadius.medium)
                }
                .disabled(selectedFood == nil)
                .padding()
            }
            .navigationTitle("Add Food")
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