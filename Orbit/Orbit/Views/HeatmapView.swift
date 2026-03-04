import SwiftUI

struct HeatmapView: View {
    @EnvironmentObject var store: HabitStore
    let habit: Habit?  // nil = overall

    private let calendar = Calendar.current
    private let cellSize: CGFloat = 14
    private let spacing: CGFloat = 3
    private let weeksToShow = 16

    private var title: String {
        habit?.name ?? "All Habits"
    }

    private var color: Color {
        if let h = habit {
            return OrbitTheme.color(for: h.colorName)
        }
        return OrbitTheme.accent
    }

    // Generate grid: columns = weeks, rows = days of week (Mon-Sun)
    private func gridData() -> [[Date?]] {
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today)
        // Find this week's Monday (weekday 2 = Monday)
        let mondayOffset = (weekday + 5) % 7
        let thisMonday = calendar.date(byAdding: .day, value: -mondayOffset, to: today)!
        let startMonday = calendar.date(byAdding: .weekOfYear, value: -(weeksToShow - 1), to: thisMonday)!

        var weeks: [[Date?]] = []
        for w in 0..<weeksToShow {
            var week: [Date?] = []
            for d in 0..<7 {
                let date = calendar.date(byAdding: .day, value: w * 7 + d, to: startMonday)!
                if date > today {
                    week.append(nil)
                } else {
                    week.append(date)
                }
            }
            weeks.append(week)
        }
        return weeks
    }

    private func completionValue(for date: Date) -> Double {
        if let h = habit {
            return h.isCompleted(on: date) ? 1.0 : 0.0
        } else {
            let total = store.habits.count
            guard total > 0 else { return 0 }
            let done = store.habits.filter { $0.isCompleted(on: date) }.count
            return Double(done) / Double(total)
        }
    }

    private let dayLabels = ["M", "", "W", "", "F", "", ""]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                // Month labels
                Text(monthRange())
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }

            HStack(alignment: .top, spacing: spacing) {
                // Day labels
                VStack(spacing: spacing) {
                    ForEach(0..<7, id: \.self) { row in
                        Text(dayLabels[row])
                            .font(.system(size: 8))
                            .foregroundStyle(.tertiary)
                            .frame(width: 12, height: cellSize)
                    }
                }

                let grid = gridData()
                ForEach(0..<grid.count, id: \.self) { weekIdx in
                    VStack(spacing: spacing) {
                        ForEach(0..<7, id: \.self) { dayIdx in
                            if let date = grid[weekIdx][dayIdx] {
                                let value = completionValue(for: date)
                                heatmapCell(value: value, date: date)
                            } else {
                                RoundedRectangle(cornerRadius: 2.5)
                                    .fill(Color.clear)
                                    .frame(width: cellSize, height: cellSize)
                            }
                        }
                    }
                }
            }
        }
        .padding(OrbitTheme.cardPadding)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: OrbitTheme.cardRadius))
    }

    private func heatmapCell(value: Double, date: Date) -> some View {
        Canvas { context, size in
            let cellSz = min(size.width, size.height)

            // Background
            let bgDarkness = 0.05 + value * 0.2
            let bgRect = CGRect(origin: .zero, size: size)
            context.fill(
                RoundedRectangle(cornerRadius: 2.5).path(in: bgRect),
                with: .color(value > 0 ? color.opacity(bgDarkness) : Color.gray.opacity(0.06))
            )

            // Halftone dot
            let darkness = 0.1 + value * 0.75
            let dotSize = HalftoneRenderer.dotSize(darkness: darkness, cellSize: cellSz)
            let cr = dotSize * HalftoneRenderer.cornerRadiusFraction
            let dotRect = CGRect(
                x: (size.width - dotSize) / 2,
                y: (size.height - dotSize) / 2,
                width: dotSize,
                height: dotSize
            )
            let dotColor = value > 0 ? HalftoneRenderer.dotColor : HalftoneRenderer.dotColor.opacity(0.2)
            context.fill(
                RoundedRectangle(cornerRadius: cr).path(in: dotRect),
                with: .color(dotColor)
            )
        }
        .frame(width: cellSize, height: cellSize)
    }

    private func monthRange() -> String {
        let today = Date()
        let start = calendar.date(byAdding: .weekOfYear, value: -(weeksToShow - 1), to: today)!
        let f = DateFormatter()
        f.dateFormat = "MMM"
        let startMonth = f.string(from: start)
        let endMonth = f.string(from: today)
        if startMonth == endMonth { return endMonth }
        return "\(startMonth) – \(endMonth)"
    }
}
