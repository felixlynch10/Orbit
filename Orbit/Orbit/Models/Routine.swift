import Foundation

enum RoutineType: String, Codable, CaseIterable {
    case morning = "Morning"
    case night = "Night"
    case custom = "Custom"

    var icon: String {
        switch self {
        case .morning: return "sunrise.fill"
        case .night:   return "moon.stars.fill"
        case .custom:  return "list.bullet"
        }
    }
}

struct RoutineStep: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var habitId: UUID?       // nil = routine-only step
    var timeEstimate: Int?   // minutes
    var sortOrder: Int
    var completions: [String: Bool]  // "yyyy-MM-dd" -> true

    init(name: String, habitId: UUID? = nil, timeEstimate: Int? = nil, sortOrder: Int = 0) {
        self.id = UUID()
        self.name = name
        self.habitId = habitId
        self.timeEstimate = timeEstimate
        self.sortOrder = sortOrder
        self.completions = [:]
    }

    func isCompleted(on date: Date) -> Bool {
        completions[Habit.key(for: date)] == true
    }

    mutating func toggle(on date: Date) {
        let k = Habit.key(for: date)
        completions[k] = !(completions[k] ?? false)
    }
}

struct Routine: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var type: RoutineType
    var icon: String
    var colorName: String
    var steps: [RoutineStep]
    var scheduledDays: Set<Int>  // 1=Sun ... 7=Sat
    var createdAt: Date

    init(name: String, type: RoutineType = .custom, icon: String? = nil, colorName: String = "green", steps: [RoutineStep] = [], scheduledDays: Set<Int>? = nil) {
        self.id = UUID()
        self.name = name
        self.type = type
        self.icon = icon ?? type.icon
        self.colorName = colorName
        self.steps = steps
        self.scheduledDays = scheduledDays ?? Set(1...7)
        self.createdAt = Date()
    }

    var totalEstimate: Int? {
        let estimates = steps.compactMap { $0.timeEstimate }
        return estimates.isEmpty ? nil : estimates.reduce(0, +)
    }

    func completedStepCount(on date: Date) -> Int {
        steps.filter { $0.isCompleted(on: date) }.count
    }

    func progress(on date: Date) -> Double {
        guard !steps.isEmpty else { return 0 }
        return Double(completedStepCount(on: date)) / Double(steps.count)
    }

    func isScheduled(on date: Date) -> Bool {
        let weekday = Calendar.current.component(.weekday, from: date)
        return scheduledDays.contains(weekday)
    }
}
