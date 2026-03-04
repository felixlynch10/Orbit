import Foundation
import SwiftUI

class HabitStore: ObservableObject {
    @Published var habits: [Habit] = []
    @Published var categories: [HabitCategory] = []
    @Published var routines: [Routine] = []
    @Published var selectedDate: Date = Date()

    private let dir: URL = {
        let d = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Orbit", isDirectory: true)
        try? FileManager.default.createDirectory(at: d, withIntermediateDirectories: true)
        return d
    }()

    private var habitsURL: URL { dir.appendingPathComponent("habits.json") }
    private var categoriesURL: URL { dir.appendingPathComponent("categories.json") }
    private var routinesURL: URL { dir.appendingPathComponent("routines.json") }

    init() {
        loadCategories()
        load()
        loadRoutines()
        if categories.isEmpty {
            seedDefaultCategories()
        }
        if habits.isEmpty {
            seedDefaults()
        }
        migrateUncategorizedHabits()
    }

    // MARK: - Persistence

    func save() {
        if let data = try? JSONEncoder().encode(habits) {
            try? data.write(to: habitsURL, options: .atomic)
        }
    }

    func load() {
        guard let data = try? Data(contentsOf: habitsURL),
              let decoded = try? JSONDecoder().decode([Habit].self, from: data) else { return }
        habits = decoded
    }

    func saveCategories() {
        if let data = try? JSONEncoder().encode(categories) {
            try? data.write(to: categoriesURL, options: .atomic)
        }
    }

    func loadCategories() {
        guard let data = try? Data(contentsOf: categoriesURL),
              let decoded = try? JSONDecoder().decode([HabitCategory].self, from: data) else { return }
        categories = decoded
    }

    // MARK: - HabitCategory Actions

    func addHabitCategory(_ category: HabitCategory) {
        withAnimation(.easeInOut(duration: 0.3)) {
            categories.append(category)
        }
        saveCategories()
    }

    func deleteHabitCategory(id: UUID) {
        // Move habits in this category to uncategorized
        for i in habits.indices where habits[i].categoryId == id {
            habits[i].categoryId = nil
        }
        withAnimation(.easeInOut(duration: 0.25)) {
            categories.removeAll { $0.id == id }
        }
        save()
        saveCategories()
    }

    func category(for habit: Habit) -> HabitCategory? {
        guard let catId = habit.categoryId else { return nil }
        return categories.first { $0.id == catId }
    }

    func habits(in category: HabitCategory) -> [Habit] {
        habits.filter { $0.categoryId == category.id }
    }

    var uncategorizedHabits: [Habit] {
        habits.filter { $0.categoryId == nil }
    }

    // MARK: - Routine Persistence

    func saveRoutines() {
        if let data = try? JSONEncoder().encode(routines) {
            try? data.write(to: routinesURL, options: .atomic)
        }
    }

    func loadRoutines() {
        guard let data = try? Data(contentsOf: routinesURL),
              let decoded = try? JSONDecoder().decode([Routine].self, from: data) else { return }
        routines = decoded
    }

    // MARK: - Routine Actions

    func addRoutine(_ routine: Routine) {
        withAnimation(.easeInOut(duration: 0.3)) {
            routines.append(routine)
        }
        saveRoutines()
    }

    func deleteRoutine(id: UUID) {
        withAnimation(.easeInOut(duration: 0.25)) {
            routines.removeAll { $0.id == id }
        }
        saveRoutines()
    }

    func toggleRoutineStep(routineId: UUID, stepId: UUID, on date: Date) {
        guard let ri = routines.firstIndex(where: { $0.id == routineId }),
              let si = routines[ri].steps.firstIndex(where: { $0.id == stepId }) else { return }
        routines[ri].steps[si].toggle(on: date)
        // If step is linked to a habit, toggle that too
        if let habitId = routines[ri].steps[si].habitId {
            let wasCompleted = routines[ri].steps[si].isCompleted(on: date)
            if let hi = habits.firstIndex(where: { $0.id == habitId }) {
                let habitDone = habits[hi].isCompleted(on: date)
                if wasCompleted != habitDone {
                    habits[hi].toggle(on: date)
                    save()
                }
            }
        }
        saveRoutines()
    }

    func moveRoutineStep(routineId: UUID, from source: IndexSet, to destination: Int) {
        guard let ri = routines.firstIndex(where: { $0.id == routineId }) else { return }
        routines[ri].steps.move(fromOffsets: source, toOffset: destination)
        for i in routines[ri].steps.indices {
            routines[ri].steps[i].sortOrder = i
        }
        saveRoutines()
    }

    var scheduledRoutines: [Routine] {
        routines.filter { $0.isScheduled(on: selectedDate) }
    }

    // MARK: - Habit Actions

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

    var scheduledHabits: [Habit] {
        habits.filter { $0.isScheduled(on: selectedDate) }
    }

    var todayCompletionRate: Double {
        let scheduled = scheduledHabits
        guard !scheduled.isEmpty else { return 0 }
        let completed = scheduled.filter { $0.isCompleted(on: selectedDate) }.count
        return Double(completed) / Double(scheduled.count)
    }

    var todayCompletedCount: Int {
        scheduledHabits.filter { $0.isCompleted(on: selectedDate) }.count
    }

    var bestStreak: Int {
        habits.map { $0.currentStreak() }.max() ?? 0
    }

    var weeklyRate: Double {
        guard !habits.isEmpty else { return 0 }
        return habits.map { $0.completionRate(days: 7) }.reduce(0, +) / Double(habits.count)
    }

    var orbitHealthScore: Int {
        let scheduled = scheduledHabits
        guard !scheduled.isEmpty else { return 0 }

        // 60% weight: today's completion rate
        let completionPart = todayCompletionRate * 60

        // 30% weight: active streaks (avg streak across scheduled habits, capped at 30 days)
        let avgStreak = scheduled.map { Double($0.currentStreak()) }.reduce(0, +) / Double(scheduled.count)
        let streakPart = min(avgStreak / 30.0, 1.0) * 30

        // 10% weight: weekly consistency
        let weeklyPart = weeklyRate * 10

        return min(Int(completionPart + streakPart + weeklyPart), 100)
    }

    func completionRate(for category: HabitCategory) -> Double {
        let catHabits = habits(in: category)
        guard !catHabits.isEmpty else { return 0 }
        let completed = catHabits.filter { $0.isCompleted(on: selectedDate) }.count
        return Double(completed) / Double(catHabits.count)
    }

    // MARK: - Seed

    private func seedDefaultCategories() {
        categories = HabitCategory.defaults
        saveCategories()
    }

    private func seedDefaults() {
        let healthId = categories.first { $0.name == "Health" }?.id
        let mindId = categories.first { $0.name == "Mind" }?.id
        let productivityId = categories.first { $0.name == "Productivity" }?.id

        let defaults: [(String, String, String, UUID?)] = [
            ("Exercise", "figure.run", "green", healthId),
            ("Read", "book.fill", "blue", mindId),
            ("Meditate", "brain.head.profile", "purple", mindId),
            ("Hydrate", "drop.fill", "blue", healthId),
            ("Journal", "pencil.line", "orange", productivityId),
        ]
        for (name, icon, color, catId) in defaults {
            habits.append(Habit(name: name, icon: icon, colorName: color, categoryId: catId))
        }
        save()
    }

    private func migrateUncategorizedHabits() {
        // Assign existing uncategorized habits to a sensible default
        guard !categories.isEmpty else { return }
        let defaultCat = categories.first!
        var changed = false
        for i in habits.indices where habits[i].categoryId == nil {
            habits[i].categoryId = defaultCat.id
            changed = true
        }
        if changed { save() }
    }
}
