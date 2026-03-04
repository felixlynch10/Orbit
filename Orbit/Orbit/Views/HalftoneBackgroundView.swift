import SwiftUI
import AppKit

/// Tracks mouse position globally within the window, shared across views.
class MouseTracker: ObservableObject {
    struct TrailPoint {
        let position: CGPoint
        let time: Double
    }

    @Published var trail: [TrailPoint] = []
    let trailDuration: Double = 0.8

    private var monitor: Any?

    init() {
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved, .leftMouseDragged, .rightMouseDragged]) { [weak self] event in
            self?.handleMove(event)
            return event
        }
    }

    deinit {
        if let monitor { NSEvent.removeMonitor(monitor) }
    }

    private func handleMove(_ event: NSEvent) {
        guard let window = event.window else { return }
        // Convert to window content coordinates (flipped for SwiftUI)
        let loc = event.locationInWindow
        let flipped = CGPoint(x: loc.x, y: window.contentView?.frame.height ?? 0 - loc.y)

        let now = Date().timeIntervalSinceReferenceDate
        let cellThreshold: CGFloat = 4.0

        if trail.isEmpty || hypot(flipped.x - trail.last!.position.x, flipped.y - trail.last!.position.y) > cellThreshold {
            trail.append(TrailPoint(position: flipped, time: now))
        }
        // Trim expired
        trail = trail.filter { now - $0.time < trailDuration }
    }
}

/// Static halftone dot-grid background with mouse trail effect.
/// Dots near the cursor grow larger and brighter, leaving a fading trail.
/// Uses NSEvent monitoring so it works even behind ScrollViews.
struct HalftoneBackgroundView: View {
    var opacity: Double = 0.05
    var cellSize: CGFloat = 8.0

    @StateObject private var mouseTracker = MouseTracker()

    private let trailRadius: CGFloat = 45

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 15.0)) { timeline in
            let now = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                let cols = Int(size.width / cellSize)
                let rows = Int(size.height / cellSize)
                let offsetX = (size.width - CGFloat(cols) * cellSize) / 2
                let offsetY = (size.height - CGFloat(rows) * cellSize) / 2
                let liveTrail = mouseTracker.trail.filter { now - $0.time < mouseTracker.trailDuration }
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
                                    let s = (1.0 - dist / trailRadius) * (1.0 - CGFloat(age / mouseTracker.trailDuration))
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
    }
}
