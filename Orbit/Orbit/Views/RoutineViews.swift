import SwiftUI

// MARK: - Routine List

struct RoutineListView: View {
    @EnvironmentObject var store: HabitStore
    @State private var showingAddSheet = false

    var body: some View {
        ZStack {
            HalftoneBackgroundView(opacity: 0.04).ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    HStack {
                        Text("Routines")
                            .font(OrbitTheme.mono(26))
                        Spacer()
                        Button {
                            showingAddSheet = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "plus")
                                    .font(.system(size: 11, weight: .bold))
                                Text("New Routine")
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(OrbitTheme.accent.opacity(0.15), in: Capsule())
                            .foregroundStyle(OrbitTheme.accent)
                        }
                        .buttonStyle(.plain)
                    }

                    if store.routines.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "list.bullet.rectangle")
                                .font(.system(size: 36))
                                .foregroundStyle(.tertiary)
                            Text("No routines yet")
                                .font(.system(size: 15))
                                .foregroundStyle(.secondary)
                            Text("Create a morning or night routine to build consistent sequences.")
                                .font(.system(size: 13))
                                .foregroundStyle(.tertiary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        // Today's routines
                        let scheduled = store.scheduledRoutines
                        if !scheduled.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Today")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.secondary)
                                ForEach(scheduled) { routine in
                                    RoutineCardView(routine: routine)
                                }
                            }
                        }

                        // All routines
                        let notScheduled = store.routines.filter { !$0.isScheduled(on: store.selectedDate) }
                        if !notScheduled.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Other Routines")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.secondary)
                                ForEach(notScheduled) { routine in
                                    RoutineCardView(routine: routine)
                                }
                            }
                        }
                    }
                }
                .padding(30)
            }
            .scrollIndicators(.hidden)
        }
        .background(Color(.windowBackgroundColor))
        .sheet(isPresented: $showingAddSheet) {
            AddRoutineSheet()
                .environmentObject(store)
        }
    }
}

// MARK: - Routine Card

struct RoutineCardView: View {
    @EnvironmentObject var store: HabitStore
    let routine: Routine

    private var progress: Double {
        routine.progress(on: store.selectedDate)
    }

    private var color: Color {
        OrbitTheme.color(for: routine.colorName)
    }

    @State private var isExpanded = false
    @State private var showFocusMode = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(color.opacity(0.15))
                            .frame(width: 36, height: 36)
                        Image(systemName: routine.icon)
                            .font(.system(size: 15))
                            .foregroundStyle(color)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(routine.name)
                            .font(.system(size: 15, weight: .semibold))
                        HStack(spacing: 8) {
                            Text(routine.type.rawValue)
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                            if let est = routine.totalEstimate {
                                Text("~\(est) min")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.tertiary)
                            }
                            Text("\(routine.completedStepCount(on: store.selectedDate))/\(routine.steps.count) steps")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    MiniRingView(progress: progress, color: color)

                    Button {
                        showFocusMode = true
                    } label: {
                        Image(systemName: "play.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(color)
                            .frame(width: 26, height: 26)
                            .background(color.opacity(0.12), in: Circle())
                    }
                    .buttonStyle(.plain)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(14)

            // Progress bar
            GeometryReader { geo in
                RoundedRectangle(cornerRadius: 1)
                    .fill(color.opacity(0.15))
                    .frame(height: 2)
                    .overlay(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 1)
                            .fill(color)
                            .frame(width: geo.size.width * progress)
                            .animation(.easeInOut(duration: 0.3), value: progress)
                    }
            }
            .frame(height: 2)

            // Expanded step checklist
            if isExpanded {
                VStack(spacing: 0) {
                    ForEach(routine.steps.sorted(by: { $0.sortOrder < $1.sortOrder })) { step in
                        RoutineStepRow(routine: routine, step: step)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 10)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: OrbitTheme.cardRadius))
        .sheet(isPresented: $showFocusMode) {
            FocusModeView(routineId: routine.id, isPresented: $showFocusMode)
                .environmentObject(store)
                .frame(minWidth: 600, minHeight: 400)
        }
    }
}

// MARK: - Step Row

struct RoutineStepRow: View {
    @EnvironmentObject var store: HabitStore
    let routine: Routine
    let step: RoutineStep

    private var isCompleted: Bool {
        step.isCompleted(on: store.selectedDate)
    }

    private var color: Color {
        OrbitTheme.color(for: routine.colorName)
    }

    var body: some View {
        HStack(spacing: 10) {
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                    store.toggleRoutineStep(routineId: routine.id, stepId: step.id, on: store.selectedDate)
                }
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isCompleted ? color : color.opacity(0.08))
                        .frame(width: 24, height: 24)
                    if isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(step.name)
                    .font(.system(size: 13, weight: .medium))
                    .strikethrough(isCompleted, color: .secondary)
                    .foregroundStyle(isCompleted ? .secondary : .primary)

                if step.habitId != nil {
                    Text("Linked habit")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            if let est = step.timeEstimate {
                Text("\(est)m")
                    .font(OrbitTheme.mono(11))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Add Routine Sheet

struct AddRoutineSheet: View {
    @EnvironmentObject var store: HabitStore
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var routineType: RoutineType = .morning
    @State private var selectedColor = "green"
    @State private var scheduledDays: Set<Int> = Set(2...6) // weekdays by default
    @State private var steps: [StepDraft] = []
    @State private var newStepName = ""
    @State private var newStepTime = ""

    struct StepDraft: Identifiable {
        let id = UUID()
        var name: String
        var habitId: UUID?
        var timeEstimate: Int?
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("New Routine")
                    .font(OrbitTheme.mono(18))
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
            }
            .padding(20)

            Divider().opacity(0.3)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Name")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.secondary)
                        TextField("e.g. Morning Routine", text: $name)
                            .textFieldStyle(.plain)
                            .font(.system(size: 15))
                            .padding(10)
                            .background(Color.gray.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                    }

                    // Type
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Type")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.secondary)
                        HStack(spacing: 8) {
                            ForEach(RoutineType.allCases, id: \.self) { type in
                                let isSelected = routineType == type
                                Button {
                                    routineType = type
                                } label: {
                                    HStack(spacing: 5) {
                                        Image(systemName: type.icon)
                                            .font(.system(size: 11))
                                        Text(type.rawValue)
                                            .font(.system(size: 12, weight: .medium))
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 7)
                                    .background(
                                        isSelected
                                            ? OrbitTheme.color(for: selectedColor).opacity(0.2)
                                            : Color.gray.opacity(0.08),
                                        in: Capsule()
                                    )
                                    .foregroundStyle(
                                        isSelected
                                            ? OrbitTheme.color(for: selectedColor)
                                            : .secondary
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Color
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Color")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.secondary)
                        HStack(spacing: 10) {
                            ForEach(OrbitTheme.habitColors, id: \.self) { colorName in
                                let c = OrbitTheme.color(for: colorName)
                                Button {
                                    selectedColor = colorName
                                } label: {
                                    Circle()
                                        .fill(c)
                                        .frame(width: 26, height: 26)
                                        .overlay(
                                            selectedColor == colorName
                                                ? Circle().stroke(Color.white.opacity(0.8), lineWidth: 2)
                                                    .frame(width: 32, height: 32)
                                                : nil
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Schedule
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Schedule")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.secondary)
                        HStack(spacing: 6) {
                            let dayLabels = ["S", "M", "T", "W", "T", "F", "S"]
                            ForEach(1...7, id: \.self) { weekday in
                                let isOn = scheduledDays.contains(weekday)
                                Button {
                                    if isOn && scheduledDays.count > 1 {
                                        scheduledDays.remove(weekday)
                                    } else {
                                        scheduledDays.insert(weekday)
                                    }
                                } label: {
                                    Text(dayLabels[weekday - 1])
                                        .font(.system(size: 12, weight: .semibold))
                                        .frame(width: 30, height: 30)
                                        .background(
                                            isOn
                                                ? OrbitTheme.color(for: selectedColor).opacity(0.2)
                                                : Color.gray.opacity(0.08),
                                            in: RoundedRectangle(cornerRadius: 8)
                                        )
                                        .foregroundStyle(
                                            isOn
                                                ? OrbitTheme.color(for: selectedColor)
                                                : .secondary.opacity(0.5)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Steps
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Steps")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.secondary)

                        let totalEst = steps.compactMap(\.timeEstimate).reduce(0, +)
                        if totalEst > 0 {
                            Text("Total: ~\(totalEst) min")
                                .font(.system(size: 12))
                                .foregroundStyle(.tertiary)
                        }

                        ForEach(Array(steps.enumerated()), id: \.element.id) { idx, step in
                            HStack(spacing: 8) {
                                Text("\(idx + 1).")
                                    .font(OrbitTheme.mono(12))
                                    .foregroundStyle(.tertiary)
                                    .frame(width: 20)
                                Text(step.name)
                                    .font(.system(size: 13))
                                if step.habitId != nil {
                                    Image(systemName: "link")
                                        .font(.system(size: 9))
                                        .foregroundStyle(.tertiary)
                                }
                                Spacer()
                                if let est = step.timeEstimate {
                                    Text("\(est)m")
                                        .font(OrbitTheme.mono(11))
                                        .foregroundStyle(.tertiary)
                                }
                                Button {
                                    steps.remove(at: idx)
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundStyle(.tertiary)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .background(Color.gray.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
                        }

                        // Add step input
                        HStack(spacing: 8) {
                            TextField("Add a step...", text: $newStepName)
                                .textFieldStyle(.plain)
                                .font(.system(size: 13))
                                .onSubmit { addStep() }

                            TextField("min", text: $newStepTime)
                                .textFieldStyle(.plain)
                                .font(OrbitTheme.mono(12))
                                .frame(width: 36)
                                .multilineTextAlignment(.center)
                                .onSubmit { addStep() }

                            Button {
                                addStep()
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundStyle(OrbitTheme.color(for: selectedColor))
                            }
                            .buttonStyle(.plain)
                            .disabled(newStepName.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                        .padding(10)
                        .background(Color.gray.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))

                        // Link existing habits
                        if !store.habits.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Or link a habit:")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.tertiary)
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 6) {
                                        ForEach(store.habits) { habit in
                                            let alreadyAdded = steps.contains { $0.habitId == habit.id }
                                            Button {
                                                steps.append(StepDraft(name: habit.name, habitId: habit.id))
                                            } label: {
                                                HStack(spacing: 4) {
                                                    Image(systemName: habit.icon)
                                                        .font(.system(size: 10))
                                                    Text(habit.name)
                                                        .font(.system(size: 11))
                                                }
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 5)
                                                .background(Color.gray.opacity(0.08), in: Capsule())
                                                .foregroundStyle(alreadyAdded ? .tertiary : .secondary)
                                            }
                                            .buttonStyle(.plain)
                                            .disabled(alreadyAdded)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(20)
            }
            .scrollIndicators(.hidden)

            Divider().opacity(0.3)

            // Actions
            HStack {
                Button("Cancel") { dismiss() }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)

                Spacer()

                Button {
                    let routineSteps = steps.enumerated().map { idx, draft in
                        RoutineStep(name: draft.name, habitId: draft.habitId, timeEstimate: draft.timeEstimate, sortOrder: idx)
                    }
                    let routine = Routine(
                        name: name,
                        type: routineType,
                        colorName: selectedColor,
                        steps: routineSteps,
                        scheduledDays: scheduledDays
                    )
                    store.addRoutine(routine)
                    dismiss()
                } label: {
                    Text("Create Routine")
                        .font(.system(size: 13, weight: .semibold))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(OrbitTheme.accent, in: Capsule())
                        .foregroundStyle(.black)
                }
                .buttonStyle(.plain)
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || steps.isEmpty)
                .opacity(name.trimmingCharacters(in: .whitespaces).isEmpty || steps.isEmpty ? 0.4 : 1)
            }
            .padding(20)
        }
        .frame(width: 460, height: 600)
    }

    private func addStep() {
        let trimmed = newStepName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let time = Int(newStepTime.trimmingCharacters(in: .whitespaces))
        steps.append(StepDraft(name: trimmed, timeEstimate: time))
        newStepName = ""
        newStepTime = ""
    }
}
