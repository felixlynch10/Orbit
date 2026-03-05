import SwiftUI

/// Static halftone dot-grid background.
struct HalftoneBackgroundView: View {
    var opacity: Double = 0.05
    var cellSize: CGFloat = 8.0

    var body: some View {
        Canvas { context, size in
            let cols = Int(size.width / cellSize)
            let rows = Int(size.height / cellSize)
            let offsetX = (size.width - CGFloat(cols) * cellSize) / 2
            let offsetY = (size.height - CGFloat(rows) * cellSize) / 2

            for row in 0..<rows {
                for col in 0..<cols {
                    let ox = offsetX + CGFloat(col) * cellSize
                    let oy = offsetY + CGFloat(row) * cellSize

                    HalftoneRenderer.drawDot(
                        in: &context,
                        cellOrigin: CGPoint(x: ox, y: oy),
                        cellSize: cellSize,
                        darkness: 0.35,
                        color: OrbitTheme.accent.opacity(opacity)
                    )
                }
            }
        }
    }
}
