import Foundation

struct HabitCategory: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var icon: String       // SF Symbol name
    var colorName: String  // key into OrbitTheme.color(for:)
    var sortOrder: Int

    init(name: String, icon: String, colorName: String, sortOrder: Int = 0) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.colorName = colorName
        self.sortOrder = sortOrder
    }

    static let defaults: [HabitCategory] = [
        HabitCategory(name: "Health", icon: "heart.fill", colorName: "green", sortOrder: 0),
        HabitCategory(name: "Mind", icon: "brain.head.profile", colorName: "purple", sortOrder: 1),
        HabitCategory(name: "Productivity", icon: "bolt.fill", colorName: "yellow", sortOrder: 2),
        HabitCategory(name: "Creative", icon: "paintbrush.fill", colorName: "orange", sortOrder: 3),
        HabitCategory(name: "Social", icon: "person.2.fill", colorName: "blue", sortOrder: 4),
    ]
}
