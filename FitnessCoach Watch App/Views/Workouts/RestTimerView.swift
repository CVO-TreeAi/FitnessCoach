import SwiftUI

struct RestTimerView: View {
    @EnvironmentObject private var hapticManager: HapticManager
    @StateObject private var timer = RestTimerManager()
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedDuration: TimeInterval = 90 // Default 90 seconds
    @State private var customDuration: TimeInterval = 60
    @State private var showingCustomTimer = false
    @State private var animationScale: CGFloat = 1.0
    
    private let commonDurations: [TimeInterval] = [30, 60, 90, 120, 180, 300] // seconds
    
    var body: some View {
        ScrollView {
            VStack(spacing: WatchTheme.Spacing.lg) {
                // Header
                headerSection
                
                if timer.isRunning {
                    // Active Timer Display
                    activeTimerSection
                } else {
                    // Timer Selection
                    timerSelectionSection
                }
            }
            .padding(.horizontal, WatchTheme.Spacing.watchPadding)
        }
        .background(WatchTheme.Colors.background)
        .onReceive(timer.$timeRemaining) { timeRemaining in
            handleTimerUpdate(timeRemaining)
        }
        .onChange(of: timer.isCompleted) { isCompleted in
            if isCompleted {
                timerCompleted()
            }
        }
        .sheet(isPresented: $showingCustomTimer) {
            CustomTimerSheet(duration: $customDuration) {
                selectedDuration = customDuration
                startTimer()
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: WatchTheme.Spacing.xs) {
            HStack {
                Button("Done") {
                    dismiss()
                }
                .font(WatchTheme.Typography.labelMedium)
                .foregroundColor(WatchTheme.Colors.primary)
                
                Spacer()
                
                Text("Rest Timer")
                    .font(WatchTheme.Typography.headlineMedium)
                    .foregroundColor(WatchTheme.Colors.textPrimary)
                
                Spacer()
                
                if timer.isRunning {
                    Button("Stop") {
                        stopTimer()
                    }
                    .font(WatchTheme.Typography.labelMedium)
                    .foregroundColor(WatchTheme.Colors.error)
                } else {
                    // Invisible button for spacing
                    Button("") { }
                        .opacity(0)
                        .disabled(true)
                }
            }
        }
    }
    
    // MARK: - Active Timer Section
    
    private var activeTimerSection: some View {
        VStack(spacing: WatchTheme.Spacing.xl) {
            // Progress Ring
            ZStack {
                // Background circle
                Circle()
                    .stroke(WatchTheme.Colors.surface, lineWidth: 8)
                    .frame(width: 120, height: 120)
                
                // Progress circle
                Circle()
                    .trim(from: 0, to: timer.progress)
                    .stroke(timerColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(WatchTheme.Animation.medium, value: timer.progress)
                
                // Time display
                VStack(spacing: 2) {
                    Text(formatTime(timer.timeRemaining))
                        .font(WatchTheme.Typography.timer)
                        .foregroundColor(timerColor)
                        .monospacedDigit()
                        .scaleEffect(animationScale)
                    
                    Text("remaining")
                        .font(WatchTheme.Typography.caption)
                        .foregroundColor(WatchTheme.Colors.textSecondary)
                }
            }
            
            // Timer Controls
            timerControlsSection
            
            // Quick Actions
            quickActionsSection
        }
    }
    
    // MARK: - Timer Selection Section
    
    private var timerSelectionSection: some View {
        VStack(spacing: WatchTheme.Spacing.lg) {
            // Duration Selection Grid
            VStack(alignment: .leading, spacing: WatchTheme.Spacing.sm) {
                Text("Select Rest Duration")
                    .font(WatchTheme.Typography.labelLarge)
                    .foregroundColor(WatchTheme.Colors.textPrimary)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: WatchTheme.Spacing.sm) {
                    ForEach(commonDurations, id: \.self) { duration in
                        durationButton(duration: duration)
                    }
                    
                    // Custom duration button
                    customDurationButton
                }
            }
            
            // Selected duration display
            selectedDurationDisplay
            
            // Start button
            startButton
        }
    }
    
    private func durationButton(duration: TimeInterval) -> some View {
        Button {
            hapticManager.playSelectionHaptic()
            selectedDuration = duration
        } label: {
            VStack(spacing: 4) {
                Text(formatDurationLabel(duration))
                    .font(WatchTheme.Typography.labelMedium)
                    .foregroundColor(selectedDuration == duration ? WatchTheme.Colors.textOnPrimary : WatchTheme.Colors.textPrimary)
                
                Text(formatDurationUnit(duration))
                    .font(WatchTheme.Typography.caption)
                    .foregroundColor(selectedDuration == duration ? WatchTheme.Colors.textOnPrimary.opacity(0.8) : WatchTheme.Colors.textSecondary)
            }
            .padding(.vertical, WatchTheme.Spacing.sm)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PlainButtonStyle())
        .background(
            RoundedRectangle(cornerRadius: WatchTheme.CornerRadius.watchButton)
                .fill(selectedDuration == duration ? WatchTheme.Colors.primary : WatchTheme.Colors.cardBackground)
        )
    }
    
    private var customDurationButton: some View {
        Button {
            hapticManager.playSelectionHaptic()
            showingCustomTimer = true
        } label: {
            VStack(spacing: 4) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 16))
                    .foregroundColor(WatchTheme.Colors.textPrimary)
                
                Text("Custom")
                    .font(WatchTheme.Typography.caption)
                    .foregroundColor(WatchTheme.Colors.textSecondary)
            }
            .padding(.vertical, WatchTheme.Spacing.sm)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PlainButtonStyle())
        .background(
            RoundedRectangle(cornerRadius: WatchTheme.CornerRadius.watchButton)
                .fill(WatchTheme.Colors.cardBackground)
        )
    }
    
    private var selectedDurationDisplay: some View {
        VStack(spacing: WatchTheme.Spacing.xs) {
            Text("Selected Duration")
                .font(WatchTheme.Typography.caption)
                .foregroundColor(WatchTheme.Colors.textSecondary)
            
            Text(formatTime(selectedDuration))
                .font(WatchTheme.Typography.displayMedium)
                .foregroundColor(WatchTheme.Colors.primary)
                .monospacedDigit()
        }
        .padding(WatchTheme.Spacing.md)
        .watchCard()
    }
    
    private var startButton: some View {
        Button {
            startTimer()
        } label: {
            HStack {
                Image(systemName: "play.fill")
                Text("Start Rest Timer")
            }
        }
        .buttonStyle(WatchTheme.Components.primaryButtonStyle())
    }
    
    // MARK: - Timer Controls Section
    
    private var timerControlsSection: some View {
        HStack(spacing: WatchTheme.Spacing.lg) {
            // Pause/Resume Button
            Button {
                if timer.isPaused {
                    resumeTimer()
                } else {
                    pauseTimer()
                }
            } label: {
                Image(systemName: timer.isPaused ? "play.fill" : "pause.fill")
                    .font(.system(size: 20))
                    .foregroundColor(WatchTheme.Colors.primary)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Add Time Button
            Button {
                addTime()
            } label: {
                VStack(spacing: 2) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 20))
                        .foregroundColor(WatchTheme.Colors.secondary)
                    
                    Text("+30s")
                        .font(WatchTheme.Typography.caption)
                        .foregroundColor(WatchTheme.Colors.textSecondary)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // Subtract Time Button
            Button {
                subtractTime()
            } label: {
                VStack(spacing: 2) {
                    Image(systemName: "minus.circle")
                        .font(.system(size: 20))
                        .foregroundColor(WatchTheme.Colors.textSecondary)
                    
                    Text("-15s")
                        .font(WatchTheme.Typography.caption)
                        .foregroundColor(WatchTheme.Colors.textSecondary)
                }
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(timer.timeRemaining <= 15)
        }
    }
    
    // MARK: - Quick Actions Section
    
    private var quickActionsSection: some View {
        VStack(spacing: WatchTheme.Spacing.sm) {
            Text("Quick Actions")
                .font(WatchTheme.Typography.labelMedium)
                .foregroundColor(WatchTheme.Colors.textSecondary)
            
            HStack(spacing: WatchTheme.Spacing.sm) {
                Button("Skip Rest") {
                    skipRest()
                }
                .buttonStyle(WatchTheme.Components.secondaryButtonStyle())
                
                Button("Next Set") {
                    nextSet()
                }
                .buttonStyle(WatchTheme.Components.primaryButtonStyle())
            }
        }
    }
    
    // MARK: - Timer Actions
    
    private func startTimer() {
        hapticManager.playButtonPressHaptic()
        timer.start(duration: selectedDuration)
    }
    
    private func pauseTimer() {
        hapticManager.playButtonPressHaptic()
        timer.pause()
    }
    
    private func resumeTimer() {
        hapticManager.playButtonPressHaptic()
        timer.resume()
    }
    
    private func stopTimer() {
        hapticManager.playButtonPressHaptic()
        timer.stop()
    }
    
    private func addTime() {
        hapticManager.playSelectionHaptic()
        timer.addTime(30) // Add 30 seconds
    }
    
    private func subtractTime() {
        hapticManager.playSelectionHaptic()
        timer.subtractTime(15) // Subtract 15 seconds
    }
    
    private func skipRest() {
        hapticManager.playButtonPressHaptic()
        timer.stop()
        dismiss()
    }
    
    private func nextSet() {
        hapticManager.playWorkoutHaptic(.setComplete)
        timer.stop()
        dismiss()
    }
    
    // MARK: - Timer Event Handlers
    
    private func handleTimerUpdate(_ timeRemaining: TimeInterval) {
        // Handle countdown haptics
        if timeRemaining <= 5 && timeRemaining > 0 && timeRemaining.truncatingRemainder(dividingBy: 1) == 0 {
            hapticManager.playWorkoutHaptic(.countdownTick)
            
            // Animation pulse for final countdown
            withAnimation(.easeInOut(duration: 0.1)) {
                animationScale = 1.1
            }
            withAnimation(.easeInOut(duration: 0.1).delay(0.1)) {
                animationScale = 1.0
            }
        }
        
        // Warning at 30 seconds
        if timeRemaining == 30 {
            hapticManager.playWorkoutHaptic(.heartRateAlert)
        }
        
        // Warning at 10 seconds
        if timeRemaining == 10 {
            hapticManager.playWorkoutHaptic(.heartRateAlert)
        }
    }
    
    private func timerCompleted() {
        hapticManager.playWorkoutHaptic(.restTimerEnd)
        
        // Animation for completion
        withAnimation(.easeInOut(duration: 0.3)) {
            animationScale = 1.2
        }
        withAnimation(.easeInOut(duration: 0.3).delay(0.3)) {
            animationScale = 1.0
        }
    }
    
    // MARK: - Helper Properties
    
    private var timerColor: Color {
        let remaining = timer.timeRemaining
        if remaining <= 10 {
            return WatchTheme.Colors.error
        } else if remaining <= 30 {
            return WatchTheme.Colors.warning
        } else {
            return WatchTheme.Colors.primary
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval / 60)
        let seconds = Int(timeInterval.truncatingRemainder(dividingBy: 60))
        
        if minutes > 0 {
            return String(format: "%d:%02d", minutes, seconds)
        } else {
            return String(format: "%02d", seconds)
        }
    }
    
    private func formatDurationLabel(_ duration: TimeInterval) -> String {
        let minutes = Int(duration / 60)
        let seconds = Int(duration.truncatingRemainder(dividingBy: 60))
        
        if minutes > 0 && seconds > 0 {
            return "\(minutes):\(String(format: "%02d", seconds))"
        } else if minutes > 0 {
            return "\(minutes)"
        } else {
            return "\(seconds)"
        }
    }
    
    private func formatDurationUnit(_ duration: TimeInterval) -> String {
        let minutes = Int(duration / 60)
        return minutes > 0 ? "min" : "sec"
    }
}

// MARK: - Custom Timer Sheet

struct CustomTimerSheet: View {
    @Binding var duration: TimeInterval
    let onStart: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var hapticManager: HapticManager
    
    @State private var minutes: Int = 1
    @State private var seconds: Int = 0
    
    var body: some View {
        VStack(spacing: WatchTheme.Spacing.lg) {
            Text("Custom Timer")
                .font(WatchTheme.Typography.headlineMedium)
                .foregroundColor(WatchTheme.Colors.textPrimary)
            
            // Time Pickers
            HStack(spacing: WatchTheme.Spacing.md) {
                // Minutes
                VStack {
                    Text(String(minutes))
                        .font(WatchTheme.Typography.displaySmall)
                        .foregroundColor(WatchTheme.Colors.primary)
                        .monospacedDigit()
                    
                    Text("min")
                        .font(WatchTheme.Typography.caption)
                        .foregroundColor(WatchTheme.Colors.textSecondary)
                }
                .focusable()
                .digitalCrownRotation($minutes, from: 0, through: 59, by: 1, sensitivity: .medium)
                .onTapGesture {
                    hapticManager.playDigitalCrownTick()
                }
                
                Text(":")
                    .font(WatchTheme.Typography.displaySmall)
                    .foregroundColor(WatchTheme.Colors.textSecondary)
                
                // Seconds
                VStack {
                    Text(String(format: "%02d", seconds))
                        .font(WatchTheme.Typography.displaySmall)
                        .foregroundColor(WatchTheme.Colors.secondary)
                        .monospacedDigit()
                    
                    Text("sec")
                        .font(WatchTheme.Typography.caption)
                        .foregroundColor(WatchTheme.Colors.textSecondary)
                }
                .focusable()
                .digitalCrownRotation($seconds, from: 0, through: 59, by: 5, sensitivity: .medium)
                .onTapGesture {
                    hapticManager.playDigitalCrownTick()
                }
            }
            
            // Action Buttons
            HStack(spacing: WatchTheme.Spacing.md) {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(WatchTheme.Components.secondaryButtonStyle())
                
                Button("Start") {
                    duration = TimeInterval(minutes * 60 + seconds)
                    hapticManager.playSuccessHaptic()
                    dismiss()
                    onStart()
                }
                .buttonStyle(WatchTheme.Components.primaryButtonStyle())
                .disabled(minutes == 0 && seconds == 0)
            }
        }
        .padding(WatchTheme.Spacing.lg)
        .background(WatchTheme.Colors.background)
        .onAppear {
            minutes = Int(duration / 60)
            seconds = Int(duration.truncatingRemainder(dividingBy: 60))
        }
    }
}

// MARK: - Rest Timer Manager

class RestTimerManager: ObservableObject {
    @Published var timeRemaining: TimeInterval = 0
    @Published var isRunning = false
    @Published var isPaused = false
    @Published var isCompleted = false
    @Published var progress: CGFloat = 0
    
    private var timer: Timer?
    private var originalDuration: TimeInterval = 0
    
    func start(duration: TimeInterval) {
        self.originalDuration = duration
        self.timeRemaining = duration
        self.isRunning = true
        self.isPaused = false
        self.isCompleted = false
        self.progress = 1.0
        
        startInternalTimer()
    }
    
    func pause() {
        isPaused = true
        timer?.invalidate()
        timer = nil
    }
    
    func resume() {
        guard isRunning && !isCompleted else { return }
        isPaused = false
        startInternalTimer()
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
        
        isRunning = false
        isPaused = false
        isCompleted = false
        timeRemaining = 0
        progress = 0
    }
    
    func addTime(_ seconds: TimeInterval) {
        timeRemaining += seconds
        originalDuration += seconds
        updateProgress()
    }
    
    func subtractTime(_ seconds: TimeInterval) {
        timeRemaining = max(0, timeRemaining - seconds)
        if timeRemaining == 0 {
            complete()
        } else {
            updateProgress()
        }
    }
    
    private func startInternalTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.tick()
            }
        }
    }
    
    private func tick() {
        guard timeRemaining > 0 else {
            complete()
            return
        }
        
        timeRemaining -= 1
        updateProgress()
    }
    
    private func complete() {
        timer?.invalidate()
        timer = nil
        
        isCompleted = true
        isRunning = false
        isPaused = false
        progress = 0
    }
    
    private func updateProgress() {
        guard originalDuration > 0 else { return }
        progress = CGFloat(timeRemaining / originalDuration)
    }
}

#Preview("Rest Timer - Selection") {
    RestTimerView()
        .environmentObject(HapticManager())
}

#Preview("Rest Timer - Active") {
    let view = RestTimerView()
    // Would set up active timer state for preview
    return view
        .environmentObject(HapticManager())
}

#Preview("Custom Timer Sheet") {
    CustomTimerSheet(duration: .constant(90)) {
        print("Timer started")
    }
    .environmentObject(HapticManager())
}