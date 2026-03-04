import SwiftUI

struct AddHabitSheet: View {
    @EnvironmentObject var store: HabitStore
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var selectedIcon = "figure.run"
    @State private var selectedColor = "green"
    @State private var targetDays = 7
    @State private var selectedCategoryId: UUID?
    @State private var scheduledDays: Set<Int> = Set(1...7)

    private let columns = [GridItem(.adaptive(minimum: 40))]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("New Orbit")
                    .font(OrbitTheme.mono(18))
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(OrbitTheme.mono(20))
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
            }
            .padding(20)

            Divider().opacity(0.3)

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Name")
                            .font(OrbitTheme.mono(13, weight: .semibold))
                            .foregroundStyle(.secondary)
                        TextField("e.g. Exercise, Read, Meditate...", text: $name)
                            .textFieldStyle(.plain)
                            .font(OrbitTheme.mono(14, weight: .medium))
                            .padding(10)
                            .background(Color.gray.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                    }

                    // Category picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Category")
                            .font(OrbitTheme.mono(13, weight: .semibold))
                            .foregroundStyle(.secondary)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(store.categories) { category in
                                    let isSelected = selectedCategoryId == category.id
                                    Button {
                                        selectedCategoryId = category.id
                                        selectedColor = category.colorName
                                    } label: {
                                        HStack(spacing: 5) {
                                            Image(systemName: category.icon)
                                                .font(OrbitTheme.mono(11))
                                            Text(category.name)
                                                .font(OrbitTheme.mono(11, weight: .medium))
                                                .lineLimit(1)
                                                .fixedSize()
                                        }
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 7)
                                        .background(
                                            isSelected
                                                ? OrbitTheme.color(for: category.colorName).opacity(0.2)
                                                : Color.gray.opacity(0.08),
                                            in: Capsule()
                                        )
                                        .foregroundStyle(
                                            isSelected
                                                ? OrbitTheme.color(for: category.colorName)
                                                : .secondary
                                        )
                                        .overlay(
                                            isSelected
                                                ? Capsule().stroke(OrbitTheme.color(for: category.colorName).opacity(0.4), lineWidth: 1.5)
                                                : nil
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }

                    // Icon picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Icon")
                            .font(OrbitTheme.mono(13, weight: .semibold))
                            .foregroundStyle(.secondary)

                        LazyVGrid(columns: columns, spacing: 8) {
                            ForEach(OrbitTheme.habitIcons, id: \.self) { icon in
                                Button {
                                    selectedIcon = icon
                                } label: {
                                    Image(systemName: icon)
                                        .font(OrbitTheme.mono(16))
                                        .frame(width: 40, height: 40)
                                        .background(
                                            selectedIcon == icon
                                                ? OrbitTheme.color(for: selectedColor).opacity(0.2)
                                                : Color.gray.opacity(0.08),
                                            in: RoundedRectangle(cornerRadius: 10)
                                        )
                                        .foregroundStyle(
                                            selectedIcon == icon
                                                ? OrbitTheme.color(for: selectedColor)
                                                : .secondary
                                        )
                                        .overlay(
                                            selectedIcon == icon
                                                ? RoundedRectangle(cornerRadius: 10)
                                                    .stroke(OrbitTheme.color(for: selectedColor).opacity(0.4), lineWidth: 1.5)
                                                : nil
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Color picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Color")
                            .font(OrbitTheme.mono(13, weight: .semibold))
                            .foregroundStyle(.secondary)

                        HStack(spacing: 10) {
                            ForEach(OrbitTheme.habitColors, id: \.self) { colorName in
                                let c = OrbitTheme.color(for: colorName)
                                Button {
                                    selectedColor = colorName
                                } label: {
                                    Circle()
                                        .fill(c)
                                        .frame(width: 30, height: 30)
                                        .overlay(
                                            selectedColor == colorName
                                                ? Circle().stroke(Color.white.opacity(0.8), lineWidth: 2.5)
                                                    .frame(width: 36, height: 36)
                                                : nil
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Target days
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Target: \(targetDays)x per week")
                            .font(OrbitTheme.mono(13, weight: .semibold))
                            .foregroundStyle(.secondary)

                        HStack(spacing: 6) {
                            ForEach(1...7, id: \.self) { day in
                                Button {
                                    targetDays = day
                                } label: {
                                    Text("\(day)")
                                        .font(OrbitTheme.mono(13, weight: .medium))
                                        .frame(width: 34, height: 34)
                                        .background(
                                            day == targetDays
                                                ? OrbitTheme.color(for: selectedColor).opacity(0.2)
                                                : Color.gray.opacity(0.08),
                                            in: RoundedRectangle(cornerRadius: 8)
                                        )
                                        .foregroundStyle(
                                            day == targetDays
                                                ? OrbitTheme.color(for: selectedColor)
                                                : .secondary
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Schedule
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Schedule")
                            .font(OrbitTheme.mono(13, weight: .semibold))
                            .foregroundStyle(.secondary)

                        HStack(spacing: 6) {
                            let dayLabels = ["S", "M", "T", "W", "T", "F", "S"]
                            // weekday values: 1=Sun, 2=Mon, ..., 7=Sat
                            ForEach(1...7, id: \.self) { weekday in
                                let isOn = scheduledDays.contains(weekday)
                                Button {
                                    if isOn && scheduledDays.count > 1 {
                                        scheduledDays.remove(weekday)
                                    } else {
                                        scheduledDays.insert(weekday)
                                    }
                                } label: {
                                    Text(dayLabels[weekday - 1])
                                        .font(OrbitTheme.mono(12, weight: .semibold))
                                        .frame(width: 34, height: 34)
                                        .background(
                                            isOn
                                                ? OrbitTheme.color(for: selectedColor).opacity(0.2)
                                                : Color.gray.opacity(0.08),
                                            in: RoundedRectangle(cornerRadius: 8)
                                        )
                                        .foregroundStyle(
                                            isOn
                                                ? OrbitTheme.color(for: selectedColor)
                                                : .secondary.opacity(0.5)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Preview
                    if !name.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Preview")
                                .font(OrbitTheme.mono(13, weight: .semibold))
                                .foregroundStyle(.secondary)

                            HStack(spacing: 10) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(OrbitTheme.color(for: selectedColor).opacity(0.15))
                                        .frame(width: 36, height: 36)
                                    Image(systemName: selectedIcon)
                                        .font(OrbitTheme.mono(15))
                                        .foregroundStyle(OrbitTheme.color(for: selectedColor))
                                }
                                Text(name)
                                    .font(OrbitTheme.mono(14, weight: .semibold))
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                        }
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }
                .padding(20)
            }

            Divider().opacity(0.3)

            // Action buttons
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)

                Spacer()

                Button {
                    let habit = Habit(
                        name: name,
                        icon: selectedIcon,
                        colorName: selectedColor,
                        targetDaysPerWeek: targetDays,
                        categoryId: selectedCategoryId,
                        scheduledDays: scheduledDays
                    )
                    store.addHabit(habit)
                    dismiss()
                } label: {
                    Text("Launch Orbit")
                        .font(OrbitTheme.mono(13, weight: .semibold))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(OrbitTheme.accent, in: Capsule())
                        .foregroundStyle(.black)
                }
                .buttonStyle(.plain)
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                .opacity(name.trimmingCharacters(in: .whitespaces).isEmpty ? 0.4 : 1)
            }
            .padding(20)
        }
        .frame(width: 420, height: 680)
        .onAppear {
            selectedCategoryId = store.categories.first?.id
        }
    }
}
