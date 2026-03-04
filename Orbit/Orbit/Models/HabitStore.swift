import Foundation
import SwiftUI

class HabitStore: ObservableObject {
    @Published var habits: [Habit] = []
    @Published var selectedDate: Date = Date()

    private let saveURL: URL = {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Orbit", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("habits.json")
    }()

    init() {
        load()
        if habits.isEmpty {
            seedDefaults()
        }
    }

    // MARK: - Persistence

    func save() {
        if let data = try? JSONEncoder().encode(habits) {
            try? data.write(to: saveURL, options: .atomic)
        }
    }

    func load() {
        guard let data = try? Data(contentsOf: saveURL),
              let decoded = try? JSONDecoder().decode([Habit].self, from: data) else { return }
        habits = decoded
    }

    // MARK: - Actions

    func addHabit(_ habit: Habit) {
        withAnimation(.easeInOut(duration: 0.3)) {
            habits.append(habit)
        }
        save()
    }

    func deleteHabit(id: UUID) {
        withAnimation(.easeInOut(duration: 0.25)) {
            habits.removeAll { $0.id == id }
        }
        save()
    }

    func toggleHabit(id: UUID, on date: Date) {
        guard let idx = habits.firstIndex(where: { $0.id == id }) else { return }
        habits[idx].toggle(on: date)
        save()
    }

    // MARK: - Computed

    var todayCompletionRate: Double {
        guard !habits.isEmpty else { return 0 }
        let completed = habits.filter { $0.isCompleted(on: selectedDate) }.count
        return Double(completed) / Double(habits.count)
    }

    var todayCompletedCount: Int {
        habits.filter { $0.isCompleted(on: selectedDate) }.count
    }

    var bestStreak: Int {
        habits.map { $0.currentStreak() }.max() ?? 0
    }

    var weeklyRate: Double {
        guard !habits.isEmpty else { return 0 }
        return habits.map { $0.completionRate(days: 7) }.reduce(0, +) / Double(habits.count)
    }

    // MARK: - Seed

    private func seedDefaults() {
        let defaults: [(String, String, String)] = [
            ("Exercise", "figure.run", "green"),
            ("Read", "book.fill", "blue"),
            ("Meditate", "brain.head.profile", "purple"),
            ("Hydrate", "drop.fill", "blue"),
            ("Journal", "pencil.line", "orange"),
        ]
        for (name, icon, color) in defaults {
            habits.append(Habit(name: name, icon: icon, colorName: color))
        }
        save()
    }
}
