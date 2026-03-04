import SwiftUI

/// Renders a planet as a grid of dots in the halftone / pixel-art style from the reference images.
struct PixelPlanetView: View {
    var gridSize: Int = 20
    var dotSize: CGFloat = 5
    var spacing: CGFloat = 2
    var baseColor: Color = OrbitTheme.accent
    var phase: Double = 0 // rotation phase 0..1

    var body: some View {
        let totalSize = CGFloat(gridSize) * (dotSize + spacing)
        let center = CGFloat(gridSize) / 2.0
        let radius = CGFloat(gridSize) / 2.0 - 1

        Canvas { context, size in
            for row in 0..<gridSize {
                for col in 0..<gridSize {
                    let dx = CGFloat(col) - center + 0.5
                    let dy = CGFloat(row) - center + 0.5
                    let dist = sqrt(dx * dx + dy * dy)

                    guard dist <= radius else { continue }

                    // Sphere shading: light from upper-left, shifted by phase
                    let nx = dx / radius
                    let ny = dy / radius
                    let rotatedNx = nx * cos(phase * .pi * 2) - sqrt(max(0, 1 - nx*nx - ny*ny)) * sin(phase * .pi * 2)
                    let lightX: CGFloat = -0.4
                    let lightY: CGFloat = -0.5
                    let dot = max(0, rotatedNx * lightX + ny * lightY + 0.5)
                    let brightness = 0.25 + dot * 0.75

                    // "Band" pattern for planet texture
                    let bandFreq = 5.0 + phase * 2
                    let band = sin(Double(dy) * bandFreq / Double(radius) + phase * .pi * 4) * 0.15

                    let alpha = min(1.0, brightness + band)

                    let x = CGFloat(col) * (dotSize + spacing) + (size.width - totalSize) / 2
                    let y = CGFloat(row) * (dotSize + spacing) + (size.height - totalSize) / 2

                    let rect = CGRect(x: x, y: y, width: dotSize, height: dotSize)
                    context.fill(
                        RoundedRectangle(cornerRadius: dotSize * 0.2).path(in: rect),
                        with: .color(baseColor.opacity(alpha))
                    )
                }
            }
        }
        .frame(width: totalSize, height: totalSize)
    }
}

/// A small orbiting system for the header
struct SolarSystemView: View {
    @State private var phase: Double = 0

    var body: some View {
        ZStack {
            // Orbit rings (dotted)
            ForEach([50.0, 80.0, 110.0], id: \.self) { radius in
                Circle()
                    .stroke(Color.white.opacity(0.06), style: StrokeStyle(lineWidth: 1, dash: [3, 6]))
                    .frame(width: radius * 2, height: radius * 2)
            }

            // Central planet
            PixelPlanetView(gridSize: 16, dotSize: 4, spacing: 1.5, baseColor: OrbitTheme.accent, phase: phase)

            // Orbiting moons
            OrbitingDot(radius: 50, speed: 1.0, size: 6, color: OrbitTheme.ice, phase: phase)
            OrbitingDot(radius: 80, speed: 0.6, size: 8, color: OrbitTheme.mars, phase: phase + 0.3)
            OrbitingDot(radius: 110, speed: 0.35, size: 5, color: OrbitTheme.solar, phase: phase + 0.7)
        }
        .onAppear {
            withAnimation(.linear(duration: 30).repeatForever(autoreverses: false)) {
                phase = 1.0
            }
        }
    }
}

struct OrbitingDot: View {
    let radius: CGFloat
    let speed: Double
    let size: CGFloat
    let color: Color
    let phase: Double

    var body: some View {
        let angle = phase * speed * .pi * 2
        let x = cos(angle) * radius
        let y = sin(angle) * radius * 0.35 // flatten for perspective

        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .shadow(color: color.opacity(0.5), radius: 4)
            .offset(x: x, y: y)
    }
}

/// Scattered pixel stars background
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
