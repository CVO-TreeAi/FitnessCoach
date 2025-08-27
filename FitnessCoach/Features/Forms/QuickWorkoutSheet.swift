import SwiftUI

struct QuickWorkoutSheet: View {
    @Binding var isPresented: Bool
    @State private var selectedWorkout = "Full Body"
    @State private var duration = 30
    @State private var isStarting = false
    
    @Environment(\.theme) private var theme
    
    let workoutTypes = [
        ("Full Body", "figure.mixed.cardio", "Complete body workout"),
        ("Upper Body", "figure.arms.open", "Chest, back, arms, shoulders"),
        ("Lower Body", "figure.walk", "Legs, glutes, calves"),
        ("Core", "figure.core.training", "Abs and core strength"),
        ("Cardio", "heart.fill", "Cardiovascular endurance"),
        ("HIIT", "bolt.fill", "High intensity intervals")
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: theme.spacing.xl) {
                Text("Quick Workout")
                    .font(theme.typography.titleLarge)
                    .foregroundColor(theme.textPrimary)
                
                // Workout type selection
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: theme.spacing.md) {
                        ForEach(workoutTypes, id: \.0) { workout in
                            Button {
                                selectedWorkout = workout.0
                            } label: {
                                VStack(spacing: theme.spacing.sm) {
                                    Image(systemName: workout.1)
                                        .font(.largeTitle)
                                        .foregroundColor(selectedWorkout == workout.0 ? .white : theme.primaryColor)
                                    
                                    Text(workout.0)
                                        .font(theme.typography.bodyMedium)
                                        .fontWeight(.medium)
                                    
                                    Text(workout.2)
                                        .font(theme.typography.bodySmall)
                                        .multilineTextAlignment(.center)
                                        .lineLimit(2)
                                }
                                .foregroundColor(selectedWorkout == workout.0 ? .white : theme.textPrimary)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    selectedWorkout == workout.0 ?
                                    theme.primaryColor : theme.surfaceColor
                                )
                                .cornerRadius(theme.cornerRadius.medium)
                            }
                        }
                    }
                }
                
                // Duration selector
                VStack(alignment: .leading, spacing: theme.spacing.md) {
                    Text("Duration: \(duration) minutes")
                        .font(theme.typography.bodyMedium)
                        .foregroundColor(theme.textPrimary)
                    
                    Slider(value: Binding(
                        get: { Double(duration) },
                        set: { duration = Int($0) }
                    ), in: 10...60, step: 5)
                    .tint(theme.primaryColor)
                    
                    HStack {
                        Text("10 min")
                            .font(theme.typography.bodySmall)
                            .foregroundColor(theme.textSecondary)
                        Spacer()
                        Text("60 min")
                            .font(theme.typography.bodySmall)
                            .foregroundColor(theme.textSecondary)
                    }
                }
                .padding()
                .background(theme.surfaceColor)
                .cornerRadius(theme.cornerRadius.medium)
                
                Spacer()
                
                // Start button
                Button {
                    isStarting = true
                    // Simulate starting workout
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        isPresented = false
                    }
                } label: {
                    HStack {
                        if isStarting {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "play.fill")
                            Text("Start Workout")
                        }
                    }
                    .font(theme.typography.bodyMedium)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(theme.primaryColor)
                    .cornerRadius(theme.cornerRadius.medium)
                }
                .disabled(isStarting)
                
                Button("Cancel") {
                    isPresented = false
                }
                .foregroundColor(theme.textSecondary)
            }
            .padding()
            .navigationBarHidden(true)
        }
    }
}