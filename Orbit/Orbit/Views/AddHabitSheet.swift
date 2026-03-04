import SwiftUI

struct AddHabitSheet: View {
    @EnvironmentObject var store: HabitStore
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var selectedIcon = "figure.run"
    @State private var selectedColor = "green"
    @State private var targetDays = 7

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
                        .font(.system(size: 20))
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
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.secondary)
                        TextField("e.g. Exercise, Read, Meditate...", text: $name)
                            .textFieldStyle(.plain)
                            .font(.system(size: 15))
                            .padding(10)
                            .background(Color.gray.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                    }

                    // Icon picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Icon")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.secondary)

                        LazyVGrid(columns: columns, spacing: 8) {
                            ForEach(OrbitTheme.habitIcons, id: \.self) { icon in
                                Button {
                                    selectedIcon = icon
                                } label: {
                                    Image(systemName: icon)
                                        .font(.system(size: 16))
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
                            .font(.system(size: 13, weight: .semibold))
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
                            .font(.system(size: 13, weight: .semibold))
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

                    // Preview
                    if !name.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Preview")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.secondary)

                            HStack(spacing: 10) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(OrbitTheme.color(for: selectedColor).opacity(0.15))
                                        .frame(width: 36, height: 36)
                                    Image(systemName: selectedIcon)
                                        .font(.system(size: 15))
                                        .foregroundStyle(OrbitTheme.color(for: selectedColor))
                                }
                                Text(name)
                                    .font(.system(size: 14, weight: .semibold))
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
                        targetDaysPerWeek: targetDays
                    )
                    store.addHabit(habit)
                    dismiss()
                } label: {
                    Text("Launch Orbit")
                        .font(.system(size: 13, weight: .semibold))
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
        .frame(width: 420, height: 560)
    }
}
