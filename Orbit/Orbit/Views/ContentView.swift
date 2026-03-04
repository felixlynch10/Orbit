import SwiftUI

enum NavItem: String, Hashable, CaseIterable {
    case today = "Today"
    case weekly = "This Week"
    case allHabits = "All Habits"
    case modelViewer = "Planet Lab"

    var icon: String {
        switch self {
        case .today:       return "sun.max.fill"
        case .weekly:      return "calendar"
        case .allHabits:   return "square.grid.2x2.fill"
        case .modelViewer: return "globe.americas.fill"
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var store: HabitStore
    @State private var selection: NavItem? = .today
    @State private var showingAddSheet = false

    var body: some View {
        NavigationSplitView {
            SidebarView(selection: $selection, showingAddSheet: $showingAddSheet)
        } detail: {
            Group {
                switch selection {
                case .today:
                    DashboardView(showingAddSheet: $showingAddSheet)
                case .weekly:
                    WeeklyGridView()
                case .allHabits:
                    AllHabitsView(showingAddSheet: $showingAddSheet)
                case .modelViewer:
                    ModelViewerPage()
                case .none:
                    DashboardView(showingAddSheet: $showingAddSheet)
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddHabitSheet()
                .environmentObject(store)
        }
    }
}

// MARK: - Model Viewer Page

struct ModelViewerPage: View {
    var body: some View {
        ZStack {
            StarsBackgroundView().opacity(0.4).ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Planet Lab")
                    .font(.system(size: 28, weight: .bold))
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("Drop a 3D model (.obj, .usdz, .scn, .dae) to render it in pixel art style. Drag to rotate, pinch to zoom.")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HalftoneModelView(gridResolution: 64, dotColor: OrbitTheme.accent)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: OrbitTheme.cardRadius))
            }
            .padding(30)
        }
        .background(Color(.windowBackgroundColor))
    }
}

// MARK: - Weekly Grid View

struct WeeklyGridView: View {
    @EnvironmentObject var store: HabitStore

    private let calendar = Calendar.current
    private let dayLabels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    private var weeksToShow: Int { 5 }

    private func datesForGrid() -> [[Date]] {
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today)
        let mondayOffset = (weekday + 5) % 7
        let thisMonday = calendar.date(byAdding: .day, value: -mondayOffset, to: today)!
        let startMonday = calendar.date(byAdding: .weekOfYear, value: -(weeksToShow - 1), to: thisMonday)!

        var weeks: [[Date]] = []
        for w in 0..<weeksToShow {
            var week: [Date] = []
            for d in 0..<7 {
                let date = calendar.date(byAdding: .day, value: w * 7 + d, to: startMonday)!
                week.append(date)
            }
            weeks.append(week)
        }
        return weeks
    }

    var body: some View {
        ZStack {
            StarsBackgroundView().opacity(0.3).ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Weekly Overview")
                        .font(.system(size: 28, weight: .bold))
                        .padding(.bottom, 4)

                    ForEach(store.habits) { habit in
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 8) {
                                Image(systemName: habit.icon)
                                    .foregroundStyle(OrbitTheme.color(for: habit.colorName))
                                    .font(.system(size: 14))
                                Text(habit.name)
                                    .font(.system(size: 15, weight: .semibold))
                                Spacer()
                                Text("\(Int(habit.completionRate(days: 7) * 100))%")
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundStyle(OrbitTheme.color(for: habit.colorName))
                            }

                            VStack(spacing: OrbitTheme.gridSpacing) {
                                HStack(spacing: OrbitTheme.gridSpacing) {
                                    ForEach(dayLabels, id: \.self) { label in
                                        Text(label)
                                            .font(.system(size: 9, weight: .medium))
                                            .foregroundStyle(.secondary)
                                            .frame(width: OrbitTheme.gridCellSize, height: 14)
                                    }
                                }

                                ForEach(Array(datesForGrid().enumerated()), id: \.offset) { _, week in
                                    HStack(spacing: OrbitTheme.gridSpacing) {
                                        ForEach(week, id: \.self) { date in
                                            let completed = habit.isCompleted(on: date)
                                            let isFuture = date > calendar.startOfDay(for: Date())
                                            RoundedRectangle(cornerRadius: 3)
                                                .fill(
                                                    isFuture
                                                        ? Color.gray.opacity(0.06)
                                                        : completed
                                                            ? OrbitTheme.color(for: habit.colorName)
                                                            : Color.gray.opacity(0.12)
                                                )
                                                .frame(width: OrbitTheme.gridCellSize, height: OrbitTheme.gridCellSize)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(OrbitTheme.cardPadding)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: OrbitTheme.cardRadius))
                    }
                }
                .padding(30)
            }
        }
        .background(Color(.windowBackgroundColor))
    }
}

// MARK: - All Habits View

struct AllHabitsView: View {
    @EnvironmentObject var store: HabitStore
    @Binding var showingAddSheet: Bool

    var body: some View {
        ZStack {
            StarsBackgroundView().opacity(0.3).ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    HStack {
                        Text("All Habits")
                            .font(.system(size: 28, weight: .bold))
                        Spacer()
                        Button {
                            showingAddSheet = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(OrbitTheme.accent)
                        }
                        .buttonStyle(.plain)
                    }

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 260), spacing: 16)], spacing: 16) {
                        ForEach(store.habits) { habit in
                            HabitDetailCard(habit: habit)
                        }
                    }
                }
                .padding(30)
            }
        }
        .background(Color(.windowBackgroundColor))
    }
}

struct HabitDetailCard: View {
    @EnvironmentObject var store: HabitStore
    let habit: Habit

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                ZStack {
                    Circle()
                        .fill(OrbitTheme.color(for: habit.colorName).opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: habit.icon)
                        .font(.system(size: 16))
                        .foregroundStyle(OrbitTheme.color(for: habit.colorName))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(habit.name)
                        .font(.system(size: 15, weight: .semibold))
                    Text("\(habit.targetDaysPerWeek)x per week")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button(role: .destructive) {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        store.deleteHabit(id: habit.id)
                    }
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 12) {
                StatPill(label: "Streak", value: "\(habit.currentStreak())d")
                StatPill(label: "7-day", value: "\(Int(habit.completionRate(days: 7) * 100))%")
                StatPill(label: "30-day", value: "\(Int(habit.completionRate(days: 30) * 100))%")
            }
        }
        .padding(OrbitTheme.cardPadding)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: OrbitTheme.cardRadius))
    }
}

struct StatPill: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(Color.gray.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
    }
}
