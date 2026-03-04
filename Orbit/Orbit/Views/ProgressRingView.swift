import SwiftUI

struct ProgressRingView: View {
    let progress: Double
    let lineWidth: CGFloat
    let size: CGFloat
    var accentColor: Color = OrbitTheme.accent

    @State private var animatedProgress: Double = 0

    var body: some View {
        ZStack {
            Circle()
                .stroke(accentColor.opacity(0.12), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [accentColor.opacity(0.5), accentColor]),
                        center: .center,
                        startAngle: .degrees(-5),
                        endAngle: .degrees(360 * animatedProgress - 5)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: accentColor.opacity(0.3), radius: 6)

            VStack(spacing: 2) {
                Text("\(Int(animatedProgress * 100))%")
                    .font(.system(size: size * 0.24, weight: .bold, design: .rounded))
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
        ZStack {
            Circle()
                .stroke(color.opacity(0.12), lineWidth: 3)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .frame(width: 24, height: 24)
    }
}
