import SwiftUI

/// Static halftone dot-grid background that replaces StarsBackgroundView.
/// Draws a uniform grid of chartreuse dots at very low opacity.
struct HalftoneBackgroundView: View {
    var opacity: Double = 0.05
    var cellSize: CGFloat = 8.0

    var body: some View {
        Canvas { context, size in
            let dotColor = OrbitTheme.accent.opacity(opacity)
            HalftoneRenderer.drawGrid(
                in: &context,
                size: size,
                cellSize: cellSize,
                color: dotColor,
                darknessAt: { _ in 0.5 }
            )
        }
    }
}
