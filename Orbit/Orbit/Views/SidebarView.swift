import SwiftUI

struct SidebarView: View {
    @EnvironmentObject var store: HabitStore
    @Binding var selection: NavItem?
    @Binding var showingAddSheet: Bool

    var body: some View {
        List(selection: $selection) {
            Section("Mission Control") {
                ForEach(NavItem.allCases, id: \.self) { item in
                    Label(item.rawValue, systemImage: item.icon)
                        .tag(item)
                }
            }

            Section("Orbits") {
                ForEach(store.habits) { habit in
                    HStack(spacing: 8) {
                        Image(systemName: habit.icon)
                            .foregroundStyle(OrbitTheme.color(for: habit.colorName))
                            .frame(width: 18)
                        Text(habit.name)
                            .lineLimit(1)

                        Spacer()

                        if habit.isCompleted(on: store.selectedDate) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(OrbitTheme.color(for: habit.colorName))
                                .font(.system(size: 12))
                        }
                    }
                    .tag(NavItem.today)
                }
            }
        }
        .listStyle(.sidebar)
        .safeAreaInset(edge: .bottom) {
            Button {
                showingAddSheet = true
            } label: {
                Label("New Orbit", systemImage: "plus.circle.fill")
                    .font(.system(size: 13, weight: .medium))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.plain)
            .foregroundStyle(OrbitTheme.accent)
        }
    }
}
