import SwiftUI

/// Shared halftone dot-drawing utility extracted from OrbitalSystemView.
/// Dot SIZE encodes darkness — the defining visual motif of the app.
enum HalftoneRenderer {
    // Default dot color: dark olive on chartreuse
    static let dotColor = Color(red: 0.18, green: 0.20, blue: 0.05)
    static let defaultCellSize: CGFloat = 6.5
    static let minDotFraction: CGFloat = 0.3
    static let maxDotFraction: CGFloat = 0.92
    static let cornerRadiusFraction: CGFloat = 0.2

    /// Computes dot size from darkness (0…1) and cell size.
    static func dotSize(darkness: CGFloat, cellSize: CGFloat = defaultCellSize) -> CGFloat {
        let fraction = minDotFraction + clamp(darkness) * (maxDotFraction - minDotFraction)
        return cellSize * fraction
    }

    /// Draws one rounded-square dot in a Canvas context.
    static func drawDot(
        in context: inout GraphicsContext,
        cellOrigin: CGPoint,
        cellSize: CGFloat,
        darkness: CGFloat,
        color: Color = dotColor
    ) {
        let size = dotSize(darkness: darkness, cellSize: cellSize)
        let cornerRadius = size * cornerRadiusFraction
        let rect = CGRect(
            x: cellOrigin.x + (cellSize - size) / 2,
            y: cellOrigin.y + (cellSize - size) / 2,
            width: size,
            height: size
        )
        context.fill(
            RoundedRectangle(cornerRadius: cornerRadius).path(in: rect),
            with: .color(color)
        )
    }

    /// Fills a region with a uniform dot grid.
    /// `darknessAt` receives the center point of each cell and returns 0…1.
    static func drawGrid(
        in context: inout GraphicsContext,
        size: CGSize,
        cellSize: CGFloat = defaultCellSize,
        color: Color = dotColor,
        darknessAt: (CGPoint) -> CGFloat
    ) {
        let cols = Int(size.width / cellSize)
        let rows = Int(size.height / cellSize)
        let offsetX = (size.width - CGFloat(cols) * cellSize) / 2
        let offsetY = (size.height - CGFloat(rows) * cellSize) / 2

        for row in 0..<rows {
            for col in 0..<cols {
                let originX = offsetX + CGFloat(col) * cellSize
                let originY = offsetY + CGFloat(row) * cellSize
                let center = CGPoint(x: originX + cellSize / 2, y: originY + cellSize / 2)
                let darkness = darknessAt(center)
                drawDot(
                    in: &context,
                    cellOrigin: CGPoint(x: originX, y: originY),
                    cellSize: cellSize,
                    darkness: darkness,
                    color: color
                )
            }
        }
    }

    private static func clamp(_ v: CGFloat) -> CGFloat {
        min(max(v, 0), 1)
    }
}
