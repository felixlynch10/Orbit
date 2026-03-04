import SwiftUI

enum NavItem: String, Hashable, CaseIterable {
    case today = "Today"
    case weekly = "This Week"
    case allHabits = "All Habits"

    var icon: String {
        switch self {
        case .today:       return "sun.max.fill"
        case .weekly:      return "calendar"
        case .allHabits:   return "square.grid.2x2.fill"
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
            HalftoneBackgroundView(opacity: 0.04).ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Weekly Overview")
                        .font(OrbitTheme.mono(26))
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
                                    .font(OrbitTheme.mono(13))
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
                                            HalftoneGridCell(
                                                habit: habit,
                                                date: date,
                                                isFuture: date > calendar.startOfDay(for: Date())
                                            )
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
            .scrollIndicators(.hidden)
        }
        .background(Color(.windowBackgroundColor))
    }
}

/// Single halftone micro-cell for the weekly grid.
/// Each cell is one "halftone dot" — colored background with a centered rounded-square dot.
struct HalftoneGridCell: View {
    let habit: Habit
    let date: Date
    let isFuture: Bool

    private var completed: Bool { habit.isCompleted(on: date) }

    var body: some View {
        Canvas { context, size in
            let cellSize = min(size.width, size.height)

            // Background square
            let bgColor: Color
            let darkness: CGFloat

            if isFuture {
                bgColor = Color.gray.opacity(0.04)
                darkness = 0.1
            } else if completed {
                bgColor = OrbitTheme.color(for: habit.colorName).opacity(0.2)
                darkness = 0.8
            } else {
                bgColor = OrbitTheme.void.opacity(0.3)
                darkness = 0.2
            }

            let bgRect = CGRect(origin: .zero, size: size)
            context.fill(
                RoundedRectangle(cornerRadius: 3).path(in: bgRect),
                with: .color(bgColor)
            )

            // Centered halftone dot
            let dotSize = HalftoneRenderer.dotSize(darkness: darkness, cellSize: cellSize)
            let cornerRadius = dotSize * HalftoneRenderer.cornerRadiusFraction
            let dotRect = CGRect(
                x: (size.width - dotSize) / 2,
                y: (size.height - dotSize) / 2,
                width: dotSize,
                height: dotSize
            )
            let dotColor: Color = completed
                ? HalftoneRenderer.dotColor
                : HalftoneRenderer.dotColor.opacity(0.4)
            context.fill(
                RoundedRectangle(cornerRadius: cornerRadius).path(in: dotRect),
                with: .color(dotColor)
            )
        }
        .frame(width: OrbitTheme.gridCellSize, height: OrbitTheme.gridCellSize)
    }
}

// MARK: - All Habits View

struct AllHabitsView: View {
    @EnvironmentObject var store: HabitStore
    @Binding var showingAddSheet: Bool

    var body: some View {
        ZStack {
            HalftoneBackgroundView(opacity: 0.04).ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    HStack {
                        Text("All Habits")
                            .font(OrbitTheme.mono(26))
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
            .scrollIndicators(.hidden)
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
                .font(OrbitTheme.mono(14))
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(Color.gray.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
    }
}
