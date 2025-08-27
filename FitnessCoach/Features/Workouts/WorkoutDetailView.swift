import SwiftUI

public struct WorkoutDetailView: View {
    let workoutName: String
    let category: String
    @State private var isStarting = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    
    let exercises = [
        ("Warm-up", "5 min", "Low intensity cardio"),
        ("Push-ups", "3 × 12", "Chest, triceps"),
        ("Squats", "3 × 15", "Legs, glutes"),
        ("Plank", "3 × 45s", "Core"),
        ("Lunges", "3 × 10", "Legs, balance"),
        ("Cool-down", "5 min", "Stretching")
    ]
    
    public init(workoutName: String, category: String) {
        self.workoutName = workoutName
        self.category = category
    }
    
    public var body: some View {
        ScrollView {
            VStack(spacing: theme.spacing.lg) {
                // Header
                VStack(spacing: theme.spacing.md) {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 60))
                        .foregroundColor(theme.primaryColor)
                    
                    Text(workoutName)
                        .font(theme.typography.titleLarge)
                        .foregroundColor(theme.textPrimary)
                    
                    Text(category)
                        .font(theme.typography.bodyMedium)
                        .foregroundColor(theme.textSecondary)
                    
                    HStack(spacing: theme.spacing.xl) {
                        VStack {
                            Text("45")
                                .font(theme.typography.titleMedium)
                                .foregroundColor(theme.textPrimary)
                            Text("minutes")
                                .font(theme.typography.bodySmall)
                                .foregroundColor(theme.textSecondary)
                        }
                        
                        VStack {
                            Text("\(exercises.count)")
                                .font(theme.typography.titleMedium)
                                .foregroundColor(theme.textPrimary)
                            Text("exercises")
                                .font(theme.typography.bodySmall)
                                .foregroundColor(theme.textSecondary)
                        }
                        
                        VStack {
                            Text("320")
                                .font(theme.typography.titleMedium)
                                .foregroundColor(theme.textPrimary)
                            Text("calories")
                                .font(theme.typography.bodySmall)
                                .foregroundColor(theme.textSecondary)
                        }
                    }
                }
                .padding()
                .background(theme.surfaceColor)
                .cornerRadius(theme.cornerRadius.medium)
                
                // Exercises list
                VStack(alignment: .leading, spacing: theme.spacing.md) {
                    Text("Exercises")
                        .font(theme.typography.titleMedium)
                        .foregroundColor(theme.textPrimary)
                    
                    VStack(spacing: theme.spacing.sm) {
                        ForEach(Array(exercises.enumerated()), id: \.offset) { index, exercise in
                            HStack {
                                Circle()
                                    .fill(theme.primaryColor.opacity(0.2))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Text("\(index + 1)")
                                            .font(theme.typography.bodyMedium)
                                            .foregroundColor(theme.primaryColor)
                                    )
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(exercise.0)
                                        .font(theme.typography.bodyMedium)
                                        .foregroundColor(theme.textPrimary)
                                    
                                    HStack {
                                        Text(exercise.1)
                                            .font(theme.typography.bodySmall)
                                            .foregroundColor(theme.primaryColor)
                                        
                                        Text("•")
                                            .foregroundColor(theme.textTertiary)
                                        
                                        Text(exercise.2)
                                            .font(theme.typography.bodySmall)
                                            .foregroundColor(theme.textSecondary)
                                    }
                                }
                                
                                Spacer()
                            }
                            .padding()
                            .background(theme.surfaceColor)
                            .cornerRadius(theme.cornerRadius.medium)
                        }
                    }
                }
                
                // Tips section
                VStack(alignment: .leading, spacing: theme.spacing.md) {
                    Text("Tips")
                        .font(theme.typography.titleMedium)
                        .foregroundColor(theme.textPrimary)
                    
                    VStack(alignment: .leading, spacing: theme.spacing.sm) {
                        Label("Stay hydrated throughout", systemImage: "drop.fill")
                        Label("Focus on proper form", systemImage: "figure.strengthtraining.traditional")
                        Label("Rest between sets", systemImage: "timer")
                        Label("Track your progress", systemImage: "chart.line.uptrend.xyaxis")
                    }
                    .font(theme.typography.bodyMedium)
                    .foregroundColor(theme.textSecondary)
                    .padding()
                    .background(theme.surfaceColor)
                    .cornerRadius(theme.cornerRadius.medium)
                }
                
                // Start button
                Button {
                    isStarting = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        dismiss()
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
            }
            .padding()
        }
        .navigationTitle("Workout Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}