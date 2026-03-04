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
            StarsBackgroundView()
                .opacity(0.5)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    headerSection
                    statsSection
                    habitsSection
                }
                .padding(30)
            }
        }
        .background(Color(.windowBackgroundColor))
    }

    // MARK: - Header

    private var headerSection: some View {
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

            // Solar system decoration — drop a 3D model here to replace with pixel art
            ZStack {
                SolarSystemView()
                    .frame(width: 240, height: 240)

                // Small drop zone overlay for 3D model
                HalftoneModelView(compact: true, gridResolution: 36, dotColor: OrbitTheme.accent)
                    .frame(width: 240, height: 240)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .offset(x: 10, y: -10)
        }
    }

    // MARK: - Stats

    private var statsSection: some View {
        HStack(spacing: 16) {
            // Progress ring card
            VStack(spacing: 8) {
                ProgressRingView(
                    progress: store.todayCompletionRate,
                    lineWidth: 10,
                    size: 100
                )
                Text("Today")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(OrbitTheme.cardPadding)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: OrbitTheme.cardRadius))

            StatCardView(
                icon: "flame.fill",
                title: "Best Streak",
                value: "\(store.bestStreak)",
                unit: "days",
                color: OrbitTheme.mars
            )

            StatCardView(
                icon: "chart.line.uptrend.xyaxis",
                title: "Weekly Rate",
                value: "\(Int(store.weeklyRate * 100))%",
                unit: "avg",
                color: OrbitTheme.ice
            )

            StatCardView(
                icon: "checkmark.seal.fill",
                title: "Done Today",
                value: "\(store.todayCompletedCount)/\(store.habits.count)",
                unit: "habits",
                color: OrbitTheme.accent
            )
        }
    }

    // MARK: - Habits

    private var habitsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Habits")
                    .font(.system(size: 20, weight: .bold))

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
                ForEach(store.habits) { habit in
                    HabitCardView(habit: habit)
                }
            }
        }
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
                .font(.system(size: 24, weight: .bold, design: .rounded))
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
        .frame(maxWidth: .infinity)
        .padding(OrbitTheme.cardPadding)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: OrbitTheme.cardRadius))
    }
}
