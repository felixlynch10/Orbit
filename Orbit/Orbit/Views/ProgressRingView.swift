import SwiftUI

struct ProgressRingView: View {
    let progress: Double
    let lineWidth: CGFloat
    let size: CGFloat
    var accentColor: Color = OrbitTheme.accent

    @State private var animatedProgress: Double = 0

    var body: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(accentColor.opacity(0.12), lineWidth: lineWidth)

            // Progress arc
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(accentColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))

            // Center text
            Text("\(Int(animatedProgress * 100))%")
                .font(OrbitTheme.mono(size * 0.24))
                .contentTransition(.numericText())
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
        ZStack {
            Circle()
                .stroke(color.opacity(0.12), lineWidth: 2.5)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .frame(width: 24, height: 24)
    }
}
