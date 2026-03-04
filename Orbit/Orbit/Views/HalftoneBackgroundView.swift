import SwiftUI

/// Static halftone dot-grid background with mouse trail effect.
/// Dots near the cursor grow larger and brighter, leaving a fading trail.
struct HalftoneBackgroundView: View {
    var opacity: Double = 0.05
    var cellSize: CGFloat = 8.0

    struct TrailPoint {
        let position: CGPoint
        let time: Double
    }

    @State private var trail: [TrailPoint] = []
    @State private var isHovering = false

    private let trailDuration: Double = 0.8
    private let trailRadius: CGFloat = 45

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 15.0)) { timeline in
            let now = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                let cols = Int(size.width / cellSize)
                let rows = Int(size.height / cellSize)
                let offsetX = (size.width - CGFloat(cols) * cellSize) / 2
                let offsetY = (size.height - CGFloat(rows) * cellSize) / 2
                let liveTrail = trail.filter { now - $0.time < trailDuration }
                let hasTrail = !liveTrail.isEmpty

                for row in 0..<rows {
                    for col in 0..<cols {
                        let ox = offsetX + CGFloat(col) * cellSize
                        let oy = offsetY + CGFloat(row) * cellSize
                        let cx = ox + cellSize / 2
                        let cy = oy + cellSize / 2

                        var influence: CGFloat = 0
                        if hasTrail {
                            for tp in liveTrail {
                                let age = now - tp.time
                                let dist = hypot(cx - tp.position.x, cy - tp.position.y)
                                if dist < trailRadius {
                                    let s = (1.0 - dist / trailRadius) * (1.0 - CGFloat(age / trailDuration))
                                    influence = max(influence, s)
                                }
                            }
                        }

                        // Trail makes dots larger (darkness) and brighter (opacity)
                        let darkness: CGFloat = 0.35 + influence * 0.55
                        let alpha = opacity + Double(influence) * 0.12

                        HalftoneRenderer.drawDot(
                            in: &context,
                            cellOrigin: CGPoint(x: ox, y: oy),
                            cellSize: cellSize,
                            darkness: darkness,
                            color: OrbitTheme.accent.opacity(alpha)
                        )
                    }
                }
            }
        }
        .onContinuousHover { phase in
            switch phase {
            case .active(let loc):
                isHovering = true
                let now = Date().timeIntervalSinceReferenceDate
                // Only sample when cursor moved enough
                if trail.isEmpty || hypot(loc.x - trail.last!.position.x, loc.y - trail.last!.position.y) > cellSize * 0.5 {
                    trail.append(TrailPoint(position: loc, time: now))
                }
                // Trim expired points
                trail = trail.filter { now - $0.time < trailDuration }
            case .ended:
                isHovering = false
                let dur = trailDuration
                DispatchQueue.main.asyncAfter(deadline: .now() + dur + 0.1) {
                    if !isHovering { trail.removeAll() }
                }
            }
        }
    }
}
