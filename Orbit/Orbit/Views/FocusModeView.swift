import SwiftUI

struct FocusModeView: View {
    @EnvironmentObject var store: HabitStore
    let routineId: UUID
    @Binding var isPresented: Bool

    @State private var currentStepIndex = 0
    @State private var elapsedSeconds = 0
    @State private var timerActive = true
    @State private var showCompletion = false

    private var routine: Routine? {
        store.routines.first { $0.id == routineId }
    }

    private var sortedSteps: [RoutineStep] {
        routine?.steps.sorted(by: { $0.sortOrder < $1.sortOrder }) ?? []
    }

    private var currentStep: RoutineStep? {
        guard currentStepIndex < sortedSteps.count else { return nil }
        return sortedSteps[currentStepIndex]
    }

    private var nextStep: RoutineStep? {
        guard currentStepIndex + 1 < sortedSteps.count else { return nil }
        return sortedSteps[currentStepIndex + 1]
    }

    private var color: Color {
        OrbitTheme.color(for: routine?.colorName ?? "green")
    }

    private var progress: Double {
        guard !sortedSteps.isEmpty else { return 0 }
        return Double(currentStepIndex) / Double(sortedSteps.count)
    }

    private var timerString: String {
        let m = elapsedSeconds / 60
        let s = elapsedSeconds % 60
        return String(format: "%d:%02d", m, s)
    }

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.85)
                .ignoresSafeArea()

            HalftoneBackgroundView(opacity: 0.03)
                .ignoresSafeArea()

            if showCompletion {
                completionView
            } else if let step = currentStep {
                VStack(spacing: 0) {
                    // Top bar
                    topBar

                    Spacer()

                    // Current step
                    stepContent(step: step)

                    Spacer()

                    // Next step preview + controls
                    bottomSection
                }
                .padding(40)
            }
        }
        .onReceive(timer) { _ in
            if timerActive && !showCompletion {
                elapsedSeconds += 1
            }
        }
        .onAppear {
            // Skip to first incomplete step
            skipToNextIncomplete()
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(routine?.name ?? "Routine")
                    .font(OrbitTheme.mono(14))
                    .foregroundStyle(.white.opacity(0.5))
                Text("Step \(currentStepIndex + 1) of \(sortedSteps.count)")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.3))
            }

            Spacer()

            // Timer
            Text(timerString)
                .font(OrbitTheme.mono(28))
                .foregroundStyle(.white.opacity(0.6))
                .contentTransition(.numericText())

            Spacer()

            Button {
                isPresented = false
            } label: {
                Text("Exit")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.1), in: Capsule())
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Step Content

    private func stepContent(step: RoutineStep) -> some View {
        VStack(spacing: 24) {
            // Progress ring
            ZStack {
                Circle()
                    .stroke(color.opacity(0.15), lineWidth: 6)
                    .frame(width: 120, height: 120)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.4), value: progress)

                // Step number
                Text("\(currentStepIndex + 1)")
                    .font(OrbitTheme.mono(36))
                    .foregroundStyle(color)
            }

            // Step name
            Text(step.name)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            // Time estimate
            if let est = step.timeEstimate {
                Text("~\(est) min")
                    .font(.system(size: 15))
                    .foregroundStyle(.white.opacity(0.4))
            }

            // Complete button
            Button {
                completeCurrentStep()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                    Text("Complete Step")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundStyle(.black)
                .padding(.horizontal, 32)
                .padding(.vertical, 14)
                .background(color, in: Capsule())
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.return, modifiers: [])
        }
    }

    // MARK: - Bottom

    private var bottomSection: some View {
        VStack(spacing: 16) {
            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white.opacity(0.08))
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color)
                        .frame(width: geo.size.width * progress)
                        .animation(.easeInOut(duration: 0.4), value: progress)
                }
            }
            .frame(height: 4)

            // Next step preview
            if let next = nextStep {
                HStack(spacing: 8) {
                    Text("Next:")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.3))
                    Text(next.name)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))
                    if let est = next.timeEstimate {
                        Text("(\(est)m)")
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.2))
                    }
                    Spacer()
                }
            }

            // Skip / Back controls
            HStack(spacing: 16) {
                if currentStepIndex > 0 {
                    Button {
                        withAnimation { currentStepIndex -= 1 }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 10, weight: .semibold))
                            Text("Back")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundStyle(.white.opacity(0.3))
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                Button {
                    skipStep()
                } label: {
                    HStack(spacing: 4) {
                        Text("Skip")
                            .font(.system(size: 12, weight: .medium))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundStyle(.white.opacity(0.3))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Completion

    private var completionView: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 64))
                .foregroundStyle(color)

            Text("Routine Complete!")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.white)

            Text("\(sortedSteps.count) steps in \(timerString)")
                .font(.system(size: 16))
                .foregroundStyle(.white.opacity(0.5))

            Button {
                isPresented = false
            } label: {
                Text("Done")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(color, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .transition(.scale.combined(with: .opacity))
    }

    // MARK: - Actions

    private func completeCurrentStep() {
        guard let step = currentStep, let routine = routine else { return }

        // Mark step as completed
        if !step.isCompleted(on: store.selectedDate) {
            store.toggleRoutineStep(routineId: routine.id, stepId: step.id, on: store.selectedDate)
        }

        advanceToNext()
    }

    private func skipStep() {
        advanceToNext()
    }

    private func advanceToNext() {
        if currentStepIndex + 1 < sortedSteps.count {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                currentStepIndex += 1
            }
        } else {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                timerActive = false
                showCompletion = true
            }
        }
    }

    private func skipToNextIncomplete() {
        for (i, step) in sortedSteps.enumerated() {
            if !step.isCompleted(on: store.selectedDate) {
                currentStepIndex = i
                return
            }
        }
        // All complete already
        currentStepIndex = 0
    }
}
