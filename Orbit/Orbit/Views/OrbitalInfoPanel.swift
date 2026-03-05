import SwiftUI

/// Small halftone-styled info card shown in the bottom-left of the orbital view
/// based on keyboard-driven selection state.
struct OrbitalInfoPanel: View {
    @EnvironmentObject var store: HabitStore

    var body: some View {
        VStack {
            Spacer()
            HStack {
                panelContent
                Spacer()
            }
        }
        .padding(12)
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private var panelContent: some View {
        let cats = store.sortedCategories
        if let catIdx = store.selectedCategoryIndex, catIdx < cats.count {
            let cat = cats[catIdx]
            let catHabits = store.habitsForCategory(cat.id)
            if let moonIdx = store.selectedMoonIndex, moonIdx < catHabits.count {
                moonPanel(habit: catHabits[moonIdx])
            } else {
                planetPanel(cat: cat)
            }
        } else {
            sunPanel
        }
    }

    private func planetPanel(cat: HabitCategory) -> some View {
        let catHabits = store.habits.filter { $0.categoryId == cat.id }
        let completed = catHabits.filter { $0.isCompleted(on: store.selectedDate) }.count
        let color = OrbitTheme.color(for: cat.colorName)

        return HStack(spacing: 10) {
            Image(systemName: cat.icon)
                .font(OrbitTheme.mono(16))
                .foregroundStyle(color)
            VStack(alignment: .leading, spacing: 2) {
                Text(cat.name)
                    .font(OrbitTheme.mono(13, weight: .semibold))
                Text("\(completed)/\(catHabits.count) done")
                    .font(OrbitTheme.mono(11))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
        .transition(.opacity.combined(with: .scale(scale: 0.9)))
    }

    private func moonPanel(habit: Habit) -> some View {
        let color = OrbitTheme.color(for: habit.colorName)
        let done = habit.isCompleted(on: store.selectedDate)

        return HStack(spacing: 10) {
            Image(systemName: habit.icon)
                .font(OrbitTheme.mono(14))
                .foregroundStyle(color)
            VStack(alignment: .leading, spacing: 2) {
                Text(habit.name)
                    .font(OrbitTheme.mono(13, weight: .semibold))
                HStack(spacing: 6) {
                    Text(done ? "Done" : "Not done")
                        .font(OrbitTheme.mono(11))
                        .foregroundStyle(done ? color : .secondary)
                    if habit.currentStreak() > 0 {
                        Text("\(habit.currentStreak())d streak")
                            .font(OrbitTheme.mono(11))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
        .transition(.opacity.combined(with: .scale(scale: 0.9)))
    }

    private var sunPanel: some View {
        let score = store.orbitHealthScore

        return HStack(spacing: 10) {
            Image(systemName: "sun.max.fill")
                .font(OrbitTheme.mono(16))
                .foregroundStyle(OrbitTheme.solar)
            VStack(alignment: .leading, spacing: 2) {
                Text("Orbit Health")
                    .font(OrbitTheme.mono(13, weight: .semibold))
                Text("\(score)% — \(store.todayCompletedCount)/\(store.scheduledHabits.count) today")
                    .font(OrbitTheme.mono(11))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
        .transition(.opacity.combined(with: .scale(scale: 0.9)))
    }
}
