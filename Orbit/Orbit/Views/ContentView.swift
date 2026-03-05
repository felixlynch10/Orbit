import SwiftUI

enum NavItem: String, Hashable, CaseIterable {
    case today = "Today"
    case routines = "Routines"
    case trends = "Trends"
    case weekly = "This Week"
    case allHabits = "All Habits"

    var icon: String {
        switch self {
        case .today:       return "sun.max.fill"
        case .routines:    return "list.bullet.rectangle"
        case .trends:      return "chart.line.uptrend.xyaxis"
        case .weekly:      return "calendar"
        case .allHabits:   return "square.grid.2x2.fill"
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var store: HabitStore
    @State private var selection: NavItem? = .today
    @State private var showingAddSheet = false
    @FocusState private var isOrbitalFocused: Bool

    private enum KeyDirection { case up, down, left, right, space }

    private func handleKey(_ dir: KeyDirection) -> KeyPress.Result {
        let cats = store.sortedCategories
        guard !cats.isEmpty else { return .ignored }

        let anim = Animation.spring(response: 0.5, dampingFraction: 0.8)

        switch dir {
        case .down:
            if store.selectedCategoryIndex == nil {
                // Solar system → select first planet
                withAnimation(anim) {
                    store.selectedCategoryIndex = 0
                    store.selectedMoonIndex = nil
                    let cat = cats[0]
                    store.orbitalFocus = .category(cat.id)
                }
            } else if store.selectedMoonIndex == nil {
                // Planet level → select first moon
                let cat = cats[store.selectedCategoryIndex!]
                let moons = store.habitsForCategory(cat.id)
                guard !moons.isEmpty else { return .handled }
                withAnimation(anim) {
                    store.selectedMoonIndex = 0
                    store.selectedPlanetId = cat.id
                    store.orbitalFocus = .habit(moons[0].id)
                }
            }
            // Moon level → no-op

        case .up:
            if store.selectedMoonIndex != nil {
                // Moon → back to planet
                let catIdx = store.selectedCategoryIndex!
                let cat = cats[catIdx]
                withAnimation(anim) {
                    store.selectedMoonIndex = nil
                    store.orbitalFocus = .category(cat.id)
                }
            } else if store.selectedCategoryIndex != nil {
                // Planet → back to solar system
                withAnimation(anim) {
                    store.selectedCategoryIndex = nil
                    store.selectedPlanetId = nil
                    store.orbitalFocus = .solarSystem
                }
            }
            // Solar system → no-op

        case .left:
            if let moonIdx = store.selectedMoonIndex {
                let cat = cats[store.selectedCategoryIndex!]
                let moons = store.habitsForCategory(cat.id)
                guard !moons.isEmpty else { return .handled }
                let newIdx = (moonIdx - 1 + moons.count) % moons.count
                withAnimation(anim) {
                    store.selectedMoonIndex = newIdx
                    store.orbitalFocus = .habit(moons[newIdx].id)
                }
            } else if let catIdx = store.selectedCategoryIndex {
                let newIdx = (catIdx - 1 + cats.count) % cats.count
                withAnimation(anim) {
                    store.selectedCategoryIndex = newIdx
                    store.orbitalFocus = .category(cats[newIdx].id)
                }
            }

        case .right:
            if let moonIdx = store.selectedMoonIndex {
                let cat = cats[store.selectedCategoryIndex!]
                let moons = store.habitsForCategory(cat.id)
                guard !moons.isEmpty else { return .handled }
                let newIdx = (moonIdx + 1) % moons.count
                withAnimation(anim) {
                    store.selectedMoonIndex = newIdx
                    store.orbitalFocus = .habit(moons[newIdx].id)
                }
            } else if let catIdx = store.selectedCategoryIndex {
                let newIdx = (catIdx + 1) % cats.count
                withAnimation(anim) {
                    store.selectedCategoryIndex = newIdx
                    store.orbitalFocus = .category(cats[newIdx].id)
                }
            }

        case .space:
            // Only at moon level — toggle habit completion
            guard let catIdx = store.selectedCategoryIndex,
                  let moonIdx = store.selectedMoonIndex else { return .ignored }
            let cat = cats[catIdx]
            let moons = store.habitsForCategory(cat.id)
            guard moonIdx < moons.count else { return .handled }
            store.toggleHabit(id: moons[moonIdx].id, on: store.selectedDate)
        }

        return .handled
    }

    var body: some View {
        NavigationSplitView {
            SidebarView(selection: $selection, showingAddSheet: $showingAddSheet)
        } detail: {
            GeometryReader { geo in
                VStack(spacing: 0) {
                    ZStack {
                        OrbitalSystemView(
                            habits: store.habits,
                            categories: store.categories,
                            routines: store.routines,
                            selectedDate: store.selectedDate,
                            completionRate: store.todayCompletionRate,
                            focus: store.orbitalFocus,
                            frameSnapshot: $store.orbitalFrameSnapshot
                        )

                        OrbitalIconOverlay()

                        OrbitalInfoPanel()

                    }
                    .frame(height: max(240, geo.size.height * 0.42))
                    .clipShape(RoundedRectangle(cornerRadius: OrbitTheme.cardRadius))
                    .padding(.horizontal, 30)
                    .padding(.top, 16)

                    Group {
                    switch selection {
                    case .today:
                        if let catId = store.selectedPlanetId {
                            CategoryDetailView(categoryId: catId)
                                .transition(.move(edge: .trailing).combined(with: .opacity))
                        } else {
                            DashboardView(showingAddSheet: $showingAddSheet)
                                .transition(.move(edge: .leading).combined(with: .opacity))
                        }
                    case .routines:
                        RoutineListView()
                    case .trends:
                        TrendChartsView()
                    case .weekly:
                        WeeklyGridView()
                    case .allHabits:
                        AllHabitsView(showingAddSheet: $showingAddSheet)
                    case .none:
                        DashboardView(showingAddSheet: $showingAddSheet)
                    }
                    }
                }
            }
            .focusable()
            .focused($isOrbitalFocused)
            .focusEffectDisabled()
            .onAppear { isOrbitalFocused = true }
            .onKeyPress(.downArrow) { handleKey(.down) }
            .onKeyPress(.upArrow) { handleKey(.up) }
            .onKeyPress(.leftArrow) { handleKey(.left) }
            .onKeyPress(.rightArrow) { handleKey(.right) }
            .onKeyPress(.space) { handleKey(.space) }
            .onChange(of: selection) { _, newValue in
                store.selectedPlanetId = nil
                store.selectedCategoryIndex = nil
                store.selectedMoonIndex = nil
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    switch newValue {
                    case .today, .allHabits, .none:
                        store.orbitalFocus = .solarSystem
                    case .routines:
                        store.orbitalFocus = .routines
                    case .trends:
                        store.orbitalFocus = .trends()
                    case .weekly:
                        store.orbitalFocus = .weekly
                    }
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
                                    .font(OrbitTheme.mono(14))
                                Text(habit.name)
                                    .font(OrbitTheme.mono(15, weight: .semibold))
                                    .lineLimit(1)
                                Spacer()
                                Text("\(Int(habit.completionRate(days: 7) * 100))%")
                                    .font(OrbitTheme.mono(13))
                                    .foregroundStyle(OrbitTheme.color(for: habit.colorName))
                            }

                            VStack(spacing: OrbitTheme.gridSpacing) {
                                HStack(spacing: OrbitTheme.gridSpacing) {
                                    ForEach(dayLabels, id: \.self) { label in
                                        Text(label)
                                            .font(OrbitTheme.mono(9, weight: .medium))
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
                                .font(OrbitTheme.mono(22))
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
                        .font(OrbitTheme.mono(16))
                        .foregroundStyle(OrbitTheme.color(for: habit.colorName))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(habit.name)
                        .font(OrbitTheme.mono(15, weight: .semibold))
                        .lineLimit(1)
                    Text("\(habit.targetDaysPerWeek)x per week")
                        .font(OrbitTheme.mono(12))
                        .lineLimit(1)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button(role: .destructive) {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        store.deleteHabit(id: habit.id)
                    }
                } label: {
                    Image(systemName: "trash")
                        .font(OrbitTheme.mono(12))
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
                .font(OrbitTheme.mono(10))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(Color.gray.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
    }
}
