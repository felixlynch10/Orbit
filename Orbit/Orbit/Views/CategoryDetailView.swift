import SwiftUI

/// Shows details for a selected category planet — header, stats, and its habit cards.
/// Displayed in the bottom panel when a planet is click-selected in the orbital view.
struct CategoryDetailView: View {
    @EnvironmentObject var store: HabitStore
    let categoryId: UUID

    private var category: HabitCategory? {
        store.categories.first { $0.id == categoryId }
    }

    private var categoryHabits: [Habit] {
        store.habits.filter { $0.categoryId == categoryId }
    }

    private var completedCount: Int {
        categoryHabits.filter { $0.isCompleted(on: store.selectedDate) }.count
    }

    private var completionPercent: Int {
        guard !categoryHabits.isEmpty else { return 0 }
        return Int(Double(completedCount) / Double(categoryHabits.count) * 100)
    }

    private var weeklyAvgPercent: Int {
        guard !categoryHabits.isEmpty else { return 0 }
        let sum = categoryHabits.map { $0.completionRate(days: 7) }.reduce(0, +)
        return Int(sum / Double(categoryHabits.count) * 100)
    }

    private var bestStreak: Int {
        categoryHabits.map { $0.currentStreak() }.max() ?? 0
    }

    private var catColor: Color {
        guard let cat = category else { return .primary }
        return OrbitTheme.color(for: cat.colorName)
    }

    var body: some View {
        ZStack {
            HalftoneBackgroundView(opacity: 0.04).ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerSection
                    statsSection
                    habitsSection
                }
                .padding(30)
            }
            .scrollIndicators(.hidden)
        }
        .background(Color(.windowBackgroundColor))
    }

    // MARK: - Sections

    @ViewBuilder
    private var headerSection: some View {
        HStack(spacing: 14) {
            if let cat = category {
                ZStack {
                    Circle()
                        .fill(catColor.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: cat.icon)
                        .font(OrbitTheme.mono(20))
                        .foregroundStyle(catColor)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(cat.name)
                        .font(OrbitTheme.mono(22, weight: .bold))
                    let count = categoryHabits.count
                    Text("\(count) habit\(count == 1 ? "" : "s")")
                        .font(OrbitTheme.mono(13))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(spacing: 2) {
                Text("\(completionPercent)%")
                    .font(OrbitTheme.mono(20, weight: .bold))
                    .foregroundStyle(catColor)
                Text("today")
                    .font(OrbitTheme.mono(11))
                    .foregroundStyle(.secondary)
            }

            Button {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    store.selectedPlanetId = nil
                    store.orbitalFocus = .solarSystem
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(OrbitTheme.mono(18))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private var statsSection: some View {
        HStack(spacing: 12) {
            StatPill(label: "Completed", value: "\(completedCount)/\(categoryHabits.count)")
            StatPill(label: "7-day avg", value: "\(weeklyAvgPercent)%")
            StatPill(label: "Best streak", value: "\(bestStreak)d")
        }
    }

    @ViewBuilder
    private var habitsSection: some View {
        VStack(spacing: 10) {
            ForEach(categoryHabits) { habit in
                HabitCardView(
                    habit: habit,
                    returnFocus: .planetDetail(categoryId)
                )
            }
        }

        if categoryHabits.isEmpty {
            VStack(spacing: 8) {
                Image(systemName: "moon.stars")
                    .font(OrbitTheme.mono(28))
                    .foregroundStyle(.tertiary)
                Text("No habits in this category")
                    .font(OrbitTheme.mono(14))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 30)
        }
    }
}
