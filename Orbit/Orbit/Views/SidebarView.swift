import SwiftUI

struct SidebarView: View {
    @EnvironmentObject var store: HabitStore
    @Binding var selection: NavItem?
    @Binding var showingAddSheet: Bool

    var body: some View {
        List(selection: $selection) {
            Section {
                ForEach(NavItem.allCases, id: \.self) { item in
                    Label(item.rawValue, systemImage: item.icon)
                        .font(OrbitTheme.mono(13, weight: .medium))
                        .tag(item)
                }
            } header: {
                Text("Mission Control")
                    .font(OrbitTheme.mono(15))
            }

            ForEach(store.categories.sorted(by: { $0.sortOrder < $1.sortOrder })) { category in
                let catHabits = store.habits(in: category)
                if !catHabits.isEmpty {
                    Section {
                        ForEach(catHabits) { habit in
                            sidebarHabitRow(habit)
                                .onHover { hovering in
                                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                        store.orbitalFocus = hovering ? .habit(habit.id) : .solarSystem
                                    }
                                }
                        }
                    } header: {
                        HStack(spacing: 6) {
                            Image(systemName: category.icon)
                                .font(OrbitTheme.mono(13, weight: .semibold))
                                .foregroundStyle(OrbitTheme.color(for: category.colorName))
                            Text(category.name)
                                .font(OrbitTheme.mono(15))
                        }
                        .onHover { hovering in
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                store.orbitalFocus = hovering ? .category(category.id) : .solarSystem
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .safeAreaInset(edge: .bottom) {
            Button {
                showingAddSheet = true
            } label: {
                Label("New Orbit", systemImage: "plus.circle.fill")
                    .font(OrbitTheme.mono(13, weight: .semibold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.plain)
            .foregroundStyle(OrbitTheme.accent)
        }
    }

    private func sidebarHabitRow(_ habit: Habit) -> some View {
        HStack(spacing: 8) {
            Image(systemName: habit.icon)
                .font(OrbitTheme.mono(13, weight: .medium))
                .foregroundStyle(OrbitTheme.color(for: habit.colorName))
                .frame(width: 18)
            Text(habit.name)
                .font(OrbitTheme.mono(13, weight: .medium))
                .lineLimit(1)

            Spacer()

            if habit.isCompleted(on: store.selectedDate) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(OrbitTheme.color(for: habit.colorName))
                    .font(OrbitTheme.mono(12, weight: .medium))
            }
        }
        .tag(NavItem.today)
    }
}
