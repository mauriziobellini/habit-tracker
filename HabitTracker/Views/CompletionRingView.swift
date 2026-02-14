import SwiftUI

/// The animated ring-fill overlay used for the tap-and-hold gesture (FR-1).
/// Shows a circular progress stroke that fills over 2 seconds.
struct CompletionRingView: View {
    let progress: CGFloat   // 0.0 ... 1.0
    let color: Color
    let lineWidth: CGFloat
    let size: CGFloat

    var body: some View {
        Circle()
            .trim(from: 0, to: progress)
            .stroke(
                color,
                style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
            )
            .rotationEffect(.degrees(-90))
            .frame(width: size, height: size)
    }
}
