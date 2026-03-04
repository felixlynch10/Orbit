import SwiftUI

struct ProgressRingView: View {
    let progress: Double
    let lineWidth: CGFloat
    let size: CGFloat
    var accentColor: Color = OrbitTheme.accent

    @State private var animatedProgress: Double = 0

    private var dotCellSize: CGFloat { max(lineWidth * 0.9, 6) }

    var body: some View {
        ZStack {
            Canvas { context, canvasSize in
                let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
                let radius = min(canvasSize.width, canvasSize.height) / 2 - lineWidth / 2

                // Number of dots around the ring
                let circumference = 2 * .pi * radius
                let dotCount = max(Int(circumference / dotCellSize), 12)

                for i in 0..<dotCount {
                    let fraction = Double(i) / Double(dotCount)
                    // Start from top (-90 degrees)
                    let angle = fraction * 2 * .pi - .pi / 2

                    let x = center.x + CGFloat(cos(angle)) * radius
                    let y = center.y + CGFloat(sin(angle)) * radius

                    // Determine darkness based on progress
                    let darkness: CGFloat
                    let dotColor: Color

                    if fraction <= animatedProgress {
                        // Completed arc: large dots
                        // Smooth transition near the boundary
                        let distFromEdge = animatedProgress - fraction
                        let edgeFade = min(distFromEdge / 0.05, 1.0)
                        darkness = 0.15 + edgeFade * 0.70
                        dotColor = HalftoneRenderer.dotColor
                    } else {
                        // Remaining arc: small faint dots
                        let distFromEdge = fraction - animatedProgress
                        let edgeFade = min(distFromEdge / 0.05, 1.0)
                        darkness = 0.15 + (1.0 - edgeFade) * 0.30
                        dotColor = HalftoneRenderer.dotColor.opacity(0.4)
                    }

                    let dotSize = HalftoneRenderer.dotSize(darkness: darkness, cellSize: dotCellSize)
                    let cornerRadius = dotSize * HalftoneRenderer.cornerRadiusFraction
                    let rect = CGRect(
                        x: x - dotSize / 2,
                        y: y - dotSize / 2,
                        width: dotSize,
                        height: dotSize
                    )
                    context.fill(
                        RoundedRectangle(cornerRadius: cornerRadius).path(in: rect),
                        with: .color(dotColor)
                    )
                }

                // Faint accent-colored ring stroke behind dots
                let ringRect = CGRect(
                    x: center.x - radius,
                    y: center.y - radius,
                    width: radius * 2,
                    height: radius * 2
                )
                context.stroke(
                    Circle().path(in: ringRect),
                    with: .color(accentColor.opacity(0.08)),
                    lineWidth: lineWidth * 0.3
                )
            }

            // Center text
            VStack(spacing: 2) {
                Text("\(Int(animatedProgress * 100))%")
                    .font(OrbitTheme.mono(size * 0.24))
                    .contentTransition(.numericText())
                Text("complete")
                    .font(.system(size: size * 0.1, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.75)) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                animatedProgress = newValue
            }
        }
    }
}

struct MiniRingView: View {
    let progress: Double
    var color: Color = OrbitTheme.accent

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius: CGFloat = 9
            let dotCell: CGFloat = 4.0
            let dotCount = 14

            // Faint background ring
            let ringRect = CGRect(
                x: center.x - radius,
                y: center.y - radius,
                width: radius * 2,
                height: radius * 2
            )
            context.stroke(
                Circle().path(in: ringRect),
                with: .color(color.opacity(0.08)),
                lineWidth: 1.5
            )

            for i in 0..<dotCount {
                let fraction = Double(i) / Double(dotCount)
                let angle = fraction * 2 * .pi - .pi / 2

                let x = center.x + CGFloat(cos(angle)) * radius
                let y = center.y + CGFloat(sin(angle)) * radius

                let darkness: CGFloat = fraction <= progress ? 0.85 : 0.15
                let dotSize = HalftoneRenderer.dotSize(darkness: darkness, cellSize: dotCell)
                let cornerRadius = dotSize * HalftoneRenderer.cornerRadiusFraction
                let rect = CGRect(
                    x: x - dotSize / 2,
                    y: y - dotSize / 2,
                    width: dotSize,
                    height: dotSize
                )
                context.fill(
                    RoundedRectangle(cornerRadius: cornerRadius).path(in: rect),
                    with: .color(fraction <= progress ? HalftoneRenderer.dotColor : HalftoneRenderer.dotColor.opacity(0.3))
                )
            }
        }
        .frame(width: 24, height: 24)
    }
}
