import Foundation

struct Habit: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var icon: String          // SF Symbol name
    var colorName: String     // key into OrbitTheme.color(for:)
    var completions: [String: Bool]  // "yyyy-MM-dd" -> true
    var createdAt: Date
    var targetDaysPerWeek: Int

    init(name: String, icon: String = "circle.fill", colorName: String = "green", targetDaysPerWeek: Int = 7) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.colorName = colorName
        self.completions = [:]
        self.createdAt = Date()
        self.targetDaysPerWeek = targetDaysPerWeek
    }

    // MARK: - Helpers

    private static let dateFmt: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    static func key(for date: Date) -> String {
        dateFmt.string(from: date)
    }

    func isCompleted(on date: Date) -> Bool {
        completions[Self.key(for: date)] == true
    }

    mutating func toggle(on date: Date) {
        let k = Self.key(for: date)
        completions[k] = !(completions[k] ?? false)
    }

    func currentStreak(from reference: Date = Date()) -> Int {
        let cal = Calendar.current
        var streak = 0
        var day = cal.startOfDay(for: reference)

        if !isCompleted(on: day) {
            day = cal.date(byAdding: .day, value: -1, to: day)!
        }

        while isCompleted(on: day) {
            streak += 1
            day = cal.date(byAdding: .day, value: -1, to: day)!
        }
        return streak
    }

    func completionRate(days: Int = 7) -> Double {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        var completed = 0
        for i in 0..<days {
            let day = cal.date(byAdding: .day, value: -i, to: today)!
            if isCompleted(on: day) { completed += 1 }
        }
        return Double(completed) / Double(max(days, 1))
    }
}
