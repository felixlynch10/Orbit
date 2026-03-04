import SwiftUI

struct HabitCardView: View {
    @EnvironmentObject var store: HabitStore
    let habit: Habit

    private let calendar = Calendar.current

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

            // Info
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

            Spacer()

            // Mini 7-day dots
            HStack(spacing: 3) {
                ForEach(lastSevenDays, id: \.self) { date in
                    let done = habit.isCompleted(on: date)
                    let isSelected = calendar.isDate(date, inSameDayAs: store.selectedDate)
                    RoundedRectangle(cornerRadius: 2.5)
                        .fill(done ? color : Color.gray.opacity(0.15))
                        .frame(width: 10, height: 10)
                        .overlay(
                            isSelected
                                ? RoundedRectangle(cornerRadius: 2.5)
                                    .stroke(color.opacity(0.5), lineWidth: 1)
                                : nil
                        )
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
            .onHover { hovering in
                // Just visual hint
            }
        }
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: OrbitTheme.cardRadius))
    }
}
