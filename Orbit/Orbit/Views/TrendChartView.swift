import SwiftUI

// MARK: - Trend Charts Page

struct TrendChartsView: View {
    @EnvironmentObject var store: HabitStore

    @State private var selectedRange: TrendRange = .thirtyDays
    @State private var selectedHabitId: UUID? = nil  // nil = overall

    var body: some View {
        ZStack {
            HalftoneBackgroundView(opacity: 0.04).ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Trends")
                        .font(OrbitTheme.mono(26))

                    // Range picker
                    HStack(spacing: 8) {
                        ForEach(TrendRange.allCases, id: \.self) { range in
                            let isSelected = selectedRange == range
                            Button {
                                withAnimation { selectedRange = range }
                            } label: {
                                Text(range.label)
                                    .font(.system(size: 12, weight: .medium))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 6)
                                    .background(
                                        isSelected
                                            ? OrbitTheme.accent.opacity(0.2)
                                            : Color.gray.opacity(0.08),
                                        in: Capsule()
                                    )
                                    .foregroundStyle(isSelected ? OrbitTheme.accent : .secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // Habit filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            habitFilterButton(label: "Overall", id: nil, color: OrbitTheme.accent)
                            ForEach(store.habits) { habit in
                                habitFilterButton(
                                    label: habit.name,
                                    id: habit.id,
                                    color: OrbitTheme.color(for: habit.colorName)
                                )
                            }
                        }
                    }

                    // Main chart
                    TrendLineChart(
                        dataPoints: chartData(),
                        color: chartColor(),
                        range: selectedRange
                    )
                    .frame(height: 220)
                    .padding(OrbitTheme.cardPadding)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: OrbitTheme.cardRadius))

                    // Per-category breakdown
                    if selectedHabitId == nil {
                        Text("By Category")
                            .font(OrbitTheme.mono(18))

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 280), spacing: 14)], spacing: 14) {
                            ForEach(store.categories.sorted(by: { $0.sortOrder < $1.sortOrder })) { cat in
                                let catHabits = store.habits(in: cat)
                                if !catHabits.isEmpty {
                                    VStack(alignment: .leading, spacing: 10) {
                                        HStack(spacing: 6) {
                                            Image(systemName: cat.icon)
                                                .font(.system(size: 12))
                                                .foregroundStyle(OrbitTheme.color(for: cat.colorName))
                                            Text(cat.name)
                                                .font(.system(size: 14, weight: .semibold))
                                        }

                                        TrendLineChart(
                                            dataPoints: categoryData(catHabits),
                                            color: OrbitTheme.color(for: cat.colorName),
                                            range: selectedRange
                                        )
                                        .frame(height: 120)
                                    }
                                    .padding(OrbitTheme.cardPadding)
                                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: OrbitTheme.cardRadius))
                                }
                            }
                        }
                    }

                    // Stats summary
                    summaryStats
                }
                .padding(30)
            }
            .scrollIndicators(.hidden)
        }
        .background(Color(.windowBackgroundColor))
    }

    private func habitFilterButton(label: String, id: UUID?, color: Color) -> some View {
        let isSelected = selectedHabitId == id
        return Button {
            withAnimation { selectedHabitId = id }
        } label: {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    isSelected ? color.opacity(0.2) : Color.gray.opacity(0.08),
                    in: Capsule()
                )
                .foregroundStyle(isSelected ? color : .secondary)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Data

    private func chartData() -> [Double] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let days = selectedRange.days

        return (0..<days).reversed().map { offset in
            let date = calendar.date(byAdding: .day, value: -offset, to: today)!
            if let habitId = selectedHabitId {
                guard let habit = store.habits.first(where: { $0.id == habitId }) else { return 0 }
                return habit.isCompleted(on: date) ? 1.0 : 0.0
            } else {
                let total = store.habits.count
                guard total > 0 else { return 0 }
                let done = store.habits.filter { $0.isCompleted(on: date) }.count
                return Double(done) / Double(total)
            }
        }
    }

    private func categoryData(_ habits: [Habit]) -> [Double] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let days = selectedRange.days

        return (0..<days).reversed().map { offset in
            let date = calendar.date(byAdding: .day, value: -offset, to: today)!
            guard !habits.isEmpty else { return 0 }
            let done = habits.filter { $0.isCompleted(on: date) }.count
            return Double(done) / Double(habits.count)
        }
    }

    private func chartColor() -> Color {
        if let id = selectedHabitId, let h = store.habits.first(where: { $0.id == id }) {
            return OrbitTheme.color(for: h.colorName)
        }
        return OrbitTheme.accent
    }

    // MARK: - Summary

    private var summaryStats: some View {
        let data = chartData()
        let avg = data.isEmpty ? 0 : data.reduce(0, +) / Double(data.count)
        let best = data.max() ?? 0
        let recent7 = data.suffix(7)
        let recent7Avg = recent7.isEmpty ? 0 : recent7.reduce(0, +) / Double(recent7.count)

        return HStack(spacing: 14) {
            StatCardView(
                icon: "chart.line.uptrend.xyaxis",
                title: "Average",
                value: "\(Int(avg * 100))%",
                unit: "over \(selectedRange.label)",
                color: chartColor()
            )
            StatCardView(
                icon: "arrow.up.right",
                title: "Best Day",
                value: "\(Int(best * 100))%",
                unit: "completion",
                color: OrbitTheme.solar
            )
            StatCardView(
                icon: "calendar",
                title: "Last 7 Days",
                value: "\(Int(recent7Avg * 100))%",
                unit: "average",
                color: OrbitTheme.ice
            )
        }
    }
}

// MARK: - Range Enum

enum TrendRange: CaseIterable {
    case thirtyDays, sixtyDays, ninetyDays

    var days: Int {
        switch self {
        case .thirtyDays:  return 30
        case .sixtyDays:   return 60
        case .ninetyDays:  return 90
        }
    }

    var label: String {
        switch self {
        case .thirtyDays:  return "30 days"
        case .sixtyDays:   return "60 days"
        case .ninetyDays:  return "90 days"
        }
    }
}

// MARK: - Halftone Line Chart

struct TrendLineChart: View {
    let dataPoints: [Double]
    let color: Color
    let range: TrendRange

    // Smooth data with a rolling average for cleaner lines
    private var smoothed: [Double] {
        let window = max(1, dataPoints.count / 15)
        guard window > 1 else { return dataPoints }
        return dataPoints.indices.map { i in
            let start = max(0, i - window / 2)
            let end = min(dataPoints.count - 1, i + window / 2)
            let slice = dataPoints[start...end]
            return slice.reduce(0, +) / Double(slice.count)
        }
    }

    var body: some View {
        Canvas { context, size in
            let data = smoothed
            guard data.count > 1 else { return }

            let maxVal = max(data.max() ?? 1, 0.01)
            let inset: CGFloat = 2
            let chartW = size.width - inset * 2
            let chartH = size.height - inset * 2

            // Grid lines
            for i in 0...4 {
                let y = inset + chartH * (1.0 - CGFloat(i) / 4.0)
                let line = Path { p in
                    p.move(to: CGPoint(x: inset, y: y))
                    p.addLine(to: CGPoint(x: size.width - inset, y: y))
                }
                context.stroke(line, with: .color(Color.gray.opacity(0.08)), lineWidth: 0.5)
            }

            // Build line path
            func point(at index: Int) -> CGPoint {
                let x = inset + chartW * CGFloat(index) / CGFloat(data.count - 1)
                let y = inset + chartH * (1.0 - CGFloat(data[index]) / CGFloat(maxVal))
                return CGPoint(x: x, y: y)
            }

            let linePath = Path { p in
                p.move(to: point(at: 0))
                for i in 1..<data.count {
                    p.addLine(to: point(at: i))
                }
            }

            // Fill gradient under line
            let fillPath = Path { p in
                p.move(to: CGPoint(x: point(at: 0).x, y: inset + chartH))
                for i in 0..<data.count {
                    p.addLine(to: point(at: i))
                }
                p.addLine(to: CGPoint(x: point(at: data.count - 1).x, y: inset + chartH))
                p.closeSubpath()
            }

            context.fill(
                fillPath,
                with: .linearGradient(
                    Gradient(colors: [color.opacity(0.15), color.opacity(0.02)]),
                    startPoint: CGPoint(x: size.width / 2, y: 0),
                    endPoint: CGPoint(x: size.width / 2, y: size.height)
                )
            )

            // Draw the line
            context.stroke(
                linePath,
                with: .color(color),
                style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
            )

            // Halftone dots along the line at intervals
            let dotInterval = max(1, data.count / 20)
            for i in stride(from: 0, to: data.count, by: dotInterval) {
                let pt = point(at: i)
                let darkness = 0.3 + data[i] * 0.6
                let dotSize = HalftoneRenderer.dotSize(darkness: darkness, cellSize: 10)
                let cr = dotSize * HalftoneRenderer.cornerRadiusFraction
                let dotRect = CGRect(
                    x: pt.x - dotSize / 2,
                    y: pt.y - dotSize / 2,
                    width: dotSize,
                    height: dotSize
                )
                context.fill(
                    RoundedRectangle(cornerRadius: cr).path(in: dotRect),
                    with: .color(HalftoneRenderer.dotColor)
                )
            }

            // End dot (current day)
            let lastPt = point(at: data.count - 1)
            let endDotSize: CGFloat = 6
            context.fill(
                Circle().path(in: CGRect(
                    x: lastPt.x - endDotSize / 2,
                    y: lastPt.y - endDotSize / 2,
                    width: endDotSize,
                    height: endDotSize
                )),
                with: .color(color)
            )
        }
    }
}
