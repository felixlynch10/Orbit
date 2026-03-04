import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var store: HabitStore
    @Binding var showingAddSheet: Bool

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:  return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default:      return "Late night"
        }
    }

    private var dateString: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMM d"
        return f.string(from: store.selectedDate)
    }

    private var isToday: Bool {
        Calendar.current.isDateInToday(store.selectedDate)
    }

    var body: some View {
        ZStack {
            HalftoneBackgroundView(opacity: 0.05)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    headerSection
                    statsSection
                    if !store.scheduledRoutines.isEmpty {
                        routinesSection
                    }
                    heatmapSection
                    habitsSection
                }
                .padding(30)
            }
            .scrollIndicators(.hidden)
        }
        .background(Color(.windowBackgroundColor))
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(greeting)
                        .font(.system(size: 28, weight: .bold))

                    HStack(spacing: 12) {
                        Text(dateString)
                            .font(.system(size: 15))
                            .foregroundStyle(.secondary)

                        if !isToday {
                            Button("Back to Today") {
                                withAnimation { store.selectedDate = Date() }
                            }
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(OrbitTheme.accent)
                            .buttonStyle(.plain)
                        }
                    }

                    // Date navigation
                    HStack(spacing: 6) {
                        Button {
                            withAnimation {
                                store.selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: store.selectedDate)!
                            }
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 11, weight: .semibold))
                                .frame(width: 24, height: 24)
                                .background(Color.gray.opacity(0.1), in: Circle())
                        }
                        .buttonStyle(.plain)

                        Button {
                            withAnimation {
                                store.selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: store.selectedDate)!
                            }
                        } label: {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .semibold))
                                .frame(width: 24, height: 24)
                                .background(Color.gray.opacity(0.1), in: Circle())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 4)
                }

                Spacer()
            }

        }
    }

    // MARK: - Stats

    private var statsSection: some View {
        HStack(spacing: 16) {
            // Progress ring card
            VStack(spacing: 10) {
                ProgressRingView(
                    progress: store.todayCompletionRate,
                    lineWidth: 7,
                    size: 58
                )

                VStack(spacing: 1) {
                    Text("Today")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, OrbitTheme.cardPadding)
            .padding(.vertical, 24)
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: OrbitTheme.cardRadius)
                        .fill(.ultraThinMaterial)
                    // Halftone accent banner at top
                    VStack {
                        HalftoneBannerView(color: OrbitTheme.accent)
                        Spacer()
                    }
                    .clipShape(RoundedRectangle(cornerRadius: OrbitTheme.cardRadius))
                }
            }

            StatCardView(
                icon: "flame.fill",
                title: "Best Streak",
                value: "\(store.bestStreak)",
                unit: "days",
                color: OrbitTheme.mars
            )

            StatCardView(
                icon: "waveform.path.ecg",
                title: "Orbit Health",
                value: "\(store.orbitHealthScore)",
                unit: "/ 100",
                color: OrbitTheme.ice
            )

            StatCardView(
                icon: "checkmark.seal.fill",
                title: "Done Today",
                value: "\(store.todayCompletedCount)/\(store.scheduledHabits.count)",
                unit: "habits",
                color: OrbitTheme.accent
            )
        }
    }

    // MARK: - Routines

    private var routinesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Routines")
                .font(OrbitTheme.mono(20))

            ForEach(store.scheduledRoutines) { routine in
                RoutineCardView(routine: routine)
            }
        }
    }

    // MARK: - Heatmap

    private var heatmapSection: some View {
        HeatmapView(habit: nil)
    }

    // MARK: - Habits

    private var habitsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Habits")
                    .font(OrbitTheme.mono(20))

                Spacer()

                Button {
                    showingAddSheet = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .bold))
                        Text("Add")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(OrbitTheme.accent.opacity(0.15), in: Capsule())
                    .foregroundStyle(OrbitTheme.accent)
                }
                .buttonStyle(.plain)
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 280), spacing: 14)], spacing: 14) {
                ForEach(store.scheduledHabits) { habit in
                    HabitCardView(habit: habit)
                }
            }
        }
    }
}

// MARK: - Halftone Accent Banner

/// A thin 6pt halftone dot banner for stat cards.
struct HalftoneBannerView: View {
    let color: Color

    var body: some View {
        Canvas { context, size in
            // Banner background
            let rect = CGRect(origin: .zero, size: size)
            context.fill(
                Rectangle().path(in: rect),
                with: .color(color.opacity(0.25))
            )

            // Halftone dots — denser in center, fading toward edges
            let cellSize: CGFloat = 5.0
            let cols = Int(size.width / cellSize)
            let rows = Int(size.height / cellSize)

            for row in 0..<rows {
                for col in 0..<cols {
                    let x = CGFloat(col) * cellSize + cellSize / 2
                    let centerDist = abs(x - size.width / 2) / (size.width / 2)
                    let darkness = 0.6 * (1.0 - centerDist * 0.7)
                    HalftoneRenderer.drawDot(
                        in: &context,
                        cellOrigin: CGPoint(x: CGFloat(col) * cellSize, y: CGFloat(row) * cellSize),
                        cellSize: cellSize,
                        darkness: darkness,
                        color: HalftoneRenderer.dotColor.opacity(0.6)
                    )
                }
            }
        }
        .frame(height: 6)
    }
}

// MARK: - Stat Card

struct StatCardView: View {
    let icon: String
    let title: String
    let value: String
    let unit: String
    let color: Color

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(color)

            Text(value)
                .font(OrbitTheme.mono(24))
                .contentTransition(.numericText())

            VStack(spacing: 1) {
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                Text(unit)
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, OrbitTheme.cardPadding)
        .padding(.vertical, 24)
        .background {
            ZStack {
                RoundedRectangle(cornerRadius: OrbitTheme.cardRadius)
                    .fill(.ultraThinMaterial)
                // Halftone accent banner at top
                VStack {
                    HalftoneBannerView(color: color)
                    Spacer()
                }
                .clipShape(RoundedRectangle(cornerRadius: OrbitTheme.cardRadius))
            }
        }
    }
}
