import SwiftUI

enum OrbitTheme {
    // Primary accent — chartreuse from reference pixel art
    static let accent = Color(red: 0.76, green: 0.80, blue: 0.23)
    static let accentSoft = accent.opacity(0.15)

    // Space palette
    static let nebula = Color(red: 0.45, green: 0.30, blue: 0.85)
    static let mars = Color(red: 0.90, green: 0.42, blue: 0.30)
    static let ice = Color(red: 0.30, green: 0.82, blue: 0.88)
    static let solar = Color(red: 0.95, green: 0.78, blue: 0.20)
    static let void = Color(red: 0.10, green: 0.10, blue: 0.14)

    // Card style
    static let cardRadius: CGFloat = 14
    static let cardPadding: CGFloat = 16

    // Grid
    static let gridCellSize: CGFloat = 18
    static let gridSpacing: CGFloat = 4

    // Habit accent palette
    static func color(for name: String) -> Color {
        switch name {
        case "green":  return accent
        case "blue":   return ice
        case "purple": return nebula
        case "orange": return mars
        case "yellow": return solar
        case "pink":   return Color(red: 0.92, green: 0.40, blue: 0.62)
        default:       return accent
        }
    }

    static let habitColors = ["green", "blue", "purple", "orange", "yellow", "pink"]

    // Monospaced font helper
    static func mono(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }

    static let habitIcons = [
        "figure.run", "book.fill", "brain.head.profile", "drop.fill",
        "pencil.line", "dumbbell.fill", "heart.fill", "moon.stars.fill",
        "leaf.fill", "cup.and.saucer.fill", "music.note", "paintbrush.fill",
        "graduationcap.fill", "bed.double.fill", "fork.knife", "globe.americas.fill"
    ]
}
