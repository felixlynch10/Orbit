import Foundation

enum OrbitalFocus: Equatable {
    case solarSystem                    // default — all planets orbiting
    case category(UUID)                 // zoom into one category planet, show its habit moons
    case habit(UUID)                    // zoom further into a single habit moon
    case planetDetail(UUID)             // click-locked zoom into a planet (sticky, survives hover-end)
    case routines                       // show routine "orbital paths" connecting linked habits
    case trends(habitId: UUID? = nil)   // pulse/highlight based on trend data
    case weekly                         // dim non-scheduled habits, highlight scheduled ones
}
