import SwiftUI

struct HabitCardView: View {
    @EnvironmentObject var store: HabitStore
    let habit: Habit

    private let calendar = Calendar.current
    @State private var showDetail = false

    private var isCompleted: Bool {
        habit.isCompleted(on: store.selectedDate)
    }

    private var color: Color {
        OrbitTheme.color(for: habit.colorName)
    }

    // Last 7 days for the mini-grid
    private var lastSevenDays: [Date] {
        let today = calendar.startOfDay(for: store.selectedDate)
        return (0..<7).reversed().map { calendar.date(byAdding: .day, value: -$0, to: today)! }
    }

    var body: some View {
        HStack(spacing: 14) {
            // Checkbox
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                    store.toggleHabit(id: habit.id, on: store.selectedDate)
                }
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isCompleted ? color : color.opacity(0.08))
                        .frame(width: 36, height: 36)

                    if isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                            .transition(.scale.combined(with: .opacity))
                    } else {
                        Image(systemName: habit.icon)
                            .font(.system(size: 15))
                            .foregroundStyle(color)
                    }
                }
            }
            .buttonStyle(.plain)

            // Info — clickable to show detail
            Button {
                showDetail = true
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text(habit.name)
                        .font(.system(size: 14, weight: .semibold))
                        .strikethrough(isCompleted, color: .secondary)
                        .foregroundStyle(isCompleted ? .secondary : .primary)

                    HStack(spacing: 4) {
                        if habit.currentStreak() > 0 {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 9))
                                .foregroundStyle(OrbitTheme.mars)
                            Text("\(habit.currentStreak())d streak")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        } else {
                            Text("Start your streak!")
                                .font(.system(size: 11))
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Spacer()

            // Mini 7-day halftone dots
            HStack(spacing: 3) {
                ForEach(lastSevenDays, id: \.self) { date in
                    let done = habit.isCompleted(on: date)
                    let isSelected = calendar.isDate(date, inSameDayAs: store.selectedDate)
                    Canvas { context, size in
                        let cellSize = min(size.width, size.height)
                        let darkness: CGFloat = done ? 0.8 : 0.15
                        let bgColor: Color = done ? color.opacity(0.2) : Color.gray.opacity(0.06)

                        // Background
                        context.fill(
                            RoundedRectangle(cornerRadius: 2.5).path(in: CGRect(origin: .zero, size: size)),
                            with: .color(bgColor)
                        )

                        // Centered dot
                        let dotSize = HalftoneRenderer.dotSize(darkness: darkness, cellSize: cellSize)
                        let cr = dotSize * HalftoneRenderer.cornerRadiusFraction
                        let dotRect = CGRect(
                            x: (size.width - dotSize) / 2,
                            y: (size.height - dotSize) / 2,
                            width: dotSize,
                            height: dotSize
                        )
                        context.fill(
                            RoundedRectangle(cornerRadius: cr).path(in: dotRect),
                            with: .color(done ? HalftoneRenderer.dotColor : HalftoneRenderer.dotColor.opacity(0.3))
                        )

                        // Selection border
                        if isSelected {
                            context.stroke(
                                RoundedRectangle(cornerRadius: 2.5).path(in: CGRect(origin: .zero, size: size).insetBy(dx: 0.5, dy: 0.5)),
                                with: .color(color.opacity(0.5)),
                                lineWidth: 1
                            )
                        }
                    }
                    .frame(width: 10, height: 10)
                }
            }

            // Weekly completion ring
            MiniRingView(
                progress: habit.completionRate(days: 7),
                color: color
            )

            // Delete button
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    store.deleteHabit(id: habit.id)
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.tertiary)
                    .frame(width: 20, height: 20)
                    .background(Color.gray.opacity(0.08), in: Circle())
            }
            .buttonStyle(.plain)
            .opacity(0.5)
        }
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: OrbitTheme.cardRadius))
        .onHover { hovering in
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                store.orbitalFocus = hovering ? .habit(habit.id) : .solarSystem
            }
        }
        .popover(isPresented: $showDetail, arrowEdge: .bottom) {
            HabitDetailPopover(habit: habit)
                .environmentObject(store)
        }
    }
}

// MARK: - Habit Detail Popover

struct HabitDetailPopover: View {
    @EnvironmentObject var store: HabitStore
    let habit: Habit

    private var color: Color {
        OrbitTheme.color(for: habit.colorName)
    }

    private var category: HabitCategory? {
        store.category(for: habit)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(color.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: habit.icon)
                        .font(.system(size: 20))
                        .foregroundStyle(color)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(habit.name)
                        .font(.system(size: 17, weight: .bold))
                    if let cat = category {
                        HStack(spacing: 4) {
                            Image(systemName: cat.icon)
                                .font(.system(size: 10))
                            Text(cat.name)
                                .font(.system(size: 12))
                        }
                        .foregroundStyle(.secondary)
                    }
                }
            }

            Divider().opacity(0.3)

            // Stats grid
            HStack(spacing: 20) {
                statItem(label: "Current Streak", value: "\(habit.currentStreak())d", icon: "flame.fill", tint: OrbitTheme.mars)
                statItem(label: "7-Day Rate", value: "\(Int(habit.completionRate(days: 7) * 100))%", icon: "chart.bar.fill", tint: color)
                statItem(label: "30-Day Rate", value: "\(Int(habit.completionRate(days: 30) * 100))%", icon: "chart.line.uptrend.xyaxis", tint: OrbitTheme.ice)
            }

            // Progress ring
            HStack {
                Spacer()
                ProgressRingView(
                    progress: habit.completionRate(days: 7),
                    lineWidth: 8,
                    size: 80,
                    accentColor: color
                )
                Spacer()
            }

            Divider().opacity(0.3)

            // Details
            VStack(alignment: .leading, spacing: 8) {
                detailRow(label: "Target", value: "\(habit.targetDaysPerWeek)x per week")
                detailRow(label: "Total completions", value: "\(habit.completions.filter { $0.value }.count)")
                detailRow(label: "Created", value: formatDate(habit.createdAt))
                detailRow(label: "Schedule", value: scheduleSummary())
            }

            // Per-habit heatmap
            HeatmapView(habit: habit)
        }
        .padding(20)
        .frame(width: 340)
    }

    private func statItem(label: String, value: String, icon: String, tint: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(tint)
            Text(value)
                .font(OrbitTheme.mono(16))
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: .medium))
        }
    }

    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: date)
    }

    private func scheduleSummary() -> String {
        if habit.scheduledDays.count == 7 { return "Every day" }
        let weekdays: Set<Int> = [2, 3, 4, 5, 6]
        let weekends: Set<Int> = [1, 7]
        if habit.scheduledDays == weekdays { return "Weekdays" }
        if habit.scheduledDays == weekends { return "Weekends" }
        let labels = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        let days = habit.scheduledDays.sorted().map { labels[$0 - 1] }
        return days.joined(separator: ", ")
    }
}
