import SwiftUI

/// Halftone dot-matrix orbital system: each habit is a planet orbiting a central sun.
/// Uses a uniform grid of rounded-square dots where dot SIZE encodes darkness.
struct OrbitalSystemView: View {
    let habits: [Habit]
    let selectedDate: Date
    let completionRate: Double

    // Grid constants
    private let cellSize: CGFloat = 6.5
    private let bgDarkness: CGFloat = 0.12

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate

                // 1. Fill background with chartreuse
                context.fill(
                    Rectangle().path(in: CGRect(origin: .zero, size: size)),
                    with: .color(OrbitTheme.accent)
                )

                let cols = Int(size.width / cellSize)
                let rows = Int(size.height / cellSize)
                let offsetX = (size.width - CGFloat(cols) * cellSize) / 2
                let offsetY = (size.height - CGFloat(rows) * cellSize) / 2

                let centerX = size.width / 2
                let centerY = size.height / 2
                let viewRadius = min(size.width, size.height) / 2

                // Sun parameters
                let sunRadius: CGFloat = 7 * cellSize
                let sunPulse = 1.0 + 0.08 * sin(time * 1.5) * (0.5 + completionRate * 0.5)
                let effectiveSunRadius = sunRadius * sunPulse

                // Precompute planet positions
                struct PlanetInfo {
                    let x: CGFloat
                    let y: CGFloat
                    let radius: CGFloat
                    let orbitRadius: CGFloat
                    let completedToday: Bool
                }

                let habitCount = habits.count
                var planets: [PlanetInfo] = []

                for (i, habit) in habits.enumerated() {
                    let orbitFraction = CGFloat(i + 1) / CGFloat(habitCount + 1)
                    let orbitRadius = viewRadius * (0.25 + orbitFraction * 0.55)

                    // Kepler-ish speed: inner orbits faster
                    let speed = 0.3 / sqrt(Double(orbitFraction))
                    let baseAngle = Double(i) * (2.0 * .pi / Double(max(habitCount, 1)))
                    let angle = baseAngle + time * speed

                    let px = centerX + CGFloat(cos(angle)) * orbitRadius
                    let py = centerY + CGFloat(sin(angle)) * orbitRadius

                    let rate = CGFloat(habit.completionRate(days: 7))
                    let planetRadius = (4 + rate * 4) * cellSize

                    let completedToday = habit.isCompleted(on: selectedDate)

                    planets.append(PlanetInfo(
                        x: px, y: py,
                        radius: planetRadius,
                        orbitRadius: orbitRadius,
                        completedToday: completedToday
                    ))
                }

                // 2. Loop every grid cell
                for row in 0..<rows {
                    for col in 0..<cols {
                        let x = offsetX + CGFloat(col) * cellSize + cellSize / 2
                        let y = offsetY + CGFloat(row) * cellSize + cellSize / 2

                        var darkness: CGFloat = bgDarkness

                        // Orbit rings — subtle
                        for planet in planets {
                            let distToCenter = hypot(x - centerX, y - centerY)
                            let ringDelta = abs(distToCenter - planet.orbitRadius)
                            if ringDelta < cellSize * 1.2 {
                                let ringStrength = 1.0 - ringDelta / (cellSize * 1.2)
                                darkness = max(darkness, 0.15 * ringStrength + bgDarkness)
                            }
                        }

                        // Sun SDF with sphere shading
                        let sunDist = hypot(x - centerX, y - centerY)
                        if sunDist < effectiveSunRadius {
                            let nx = (x - centerX) / effectiveSunRadius
                            let ny = (y - centerY) / effectiveSunRadius
                            let nz = sqrt(max(0, 1 - nx * nx - ny * ny))
                            let light = max(0, -0.4 * nx - 0.5 * ny + 0.6 * nz)
                            let sunDarkness = 0.5 + light * 0.4
                            darkness = max(darkness, sunDarkness * (1.0 - sunDist / effectiveSunRadius * 0.2))
                        }

                        // Planet SDFs with sphere shading
                        for planet in planets {
                            let dist = hypot(x - planet.x, y - planet.y)

                            // Glow ring for completed habits
                            if planet.completedToday && dist < planet.radius * 1.5 && dist > planet.radius {
                                let glowT = (dist - planet.radius) / (planet.radius * 0.5)
                                let glowDarkness = 0.25 * (1.0 - glowT)
                                darkness = max(darkness, glowDarkness)
                            }

                            if dist < planet.radius {
                                let nx = (x - planet.x) / planet.radius
                                let ny = (y - planet.y) / planet.radius
                                let nz = sqrt(max(0, 1 - nx * nx - ny * ny))
                                let light = max(0, -0.4 * nx - 0.5 * ny + 0.6 * nz)
                                let planetDarkness = 0.4 + light * 0.5
                                let edgeFade = 1.0 - pow(dist / planet.radius, 3)
                                darkness = max(darkness, planetDarkness * edgeFade)
                            }
                        }

                        darkness = min(darkness, 1.0)

                        // Use HalftoneRenderer to draw each dot
                        let cellOrigin = CGPoint(
                            x: offsetX + CGFloat(col) * cellSize,
                            y: offsetY + CGFloat(row) * cellSize
                        )
                        HalftoneRenderer.drawDot(
                            in: &context,
                            cellOrigin: cellOrigin,
                            cellSize: cellSize,
                            darkness: darkness
                        )
                    }
                }
            }
        }
    }
}

/// Scattered pixel stars background (kept for reference, no longer used on main pages)
struct StarsBackgroundView: View {
    let starCount = 60

    var body: some View {
        Canvas { context, size in
            var rng = StableRNG(seed: 42)
            for _ in 0..<starCount {
                let x = CGFloat.random(in: 0..<size.width, using: &rng)
                let y = CGFloat.random(in: 0..<size.height, using: &rng)
                let s = CGFloat.random(in: 1.5...3.0, using: &rng)
                let alpha = Double.random(in: 0.15...0.4, using: &rng)
                let rect = CGRect(x: x, y: y, width: s, height: s)
                context.fill(
                    RoundedRectangle(cornerRadius: 0.5).path(in: rect),
                    with: .color(.white.opacity(alpha))
                )
            }
        }
    }
}

// Stable RNG so stars don't move on redraw
struct StableRNG: RandomNumberGenerator {
    var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}
