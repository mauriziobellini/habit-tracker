import SwiftUI

/// Full-screen celebration overlay shown when the user reaches a reward streak.
/// Features animated confetti particles and the reward message.
struct RewardCelebrationView: View {
    let rewardText: String
    let onDismiss: () -> Void

    @State private var confettiPieces: [ConfettiPiece] = []
    @State private var showContent = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let confettiColors: [Color] = [
        .red, .orange, .yellow, .green, .blue, .purple, .pink, .mint, .cyan, .indigo
    ]

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            // Confetti layer
            if !reduceMotion {
                ForEach(confettiPieces) { piece in
                    ConfettiParticleView(piece: piece)
                }
            }

            // Content card
            VStack(spacing: 24) {
                Image(systemName: "party.popper.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.yellow)

                Text("Congratulations!")
                    .font(.title.weight(.bold))
                    .foregroundStyle(.white)

                Text("You can now reward yourself with:")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.9))

                Text(rewardText)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)

                Button {
                    onDismiss()
                } label: {
                    Text("Awesome!")
                        .font(.headline)
                        .foregroundStyle(.black)
                        .padding(.horizontal, 48)
                        .padding(.vertical, 14)
                        .background(Capsule().fill(.white))
                }
                .padding(.top, 8)
            }
            .padding(32)
            .scaleEffect(showContent ? 1 : 0.5)
            .opacity(showContent ? 1 : 0)
        }
        .onAppear {
            generateConfetti()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showContent = true
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Congratulations! You can now reward yourself with: \(rewardText)")
        .accessibilityAddTraits(.isModal)
    }

    private func generateConfetti() {
        guard !reduceMotion else { return }
        confettiPieces = (0..<60).map { _ in
            ConfettiPiece(
                color: confettiColors.randomElement()!,
                startX: CGFloat.random(in: 0...1),
                startY: CGFloat.random(in: -0.3...0),
                endY: CGFloat.random(in: 1.0...1.5),
                rotation: Double.random(in: 0...360),
                endRotation: Double.random(in: 360...720),
                size: CGFloat.random(in: 6...12),
                duration: Double.random(in: 2.0...4.0),
                delay: Double.random(in: 0...0.8),
                shape: ConfettiShape.allCases.randomElement()!
            )
        }
    }
}

// MARK: - Confetti Data

enum ConfettiShape: CaseIterable {
    case circle, rectangle, triangle
}

struct ConfettiPiece: Identifiable {
    let id = UUID()
    let color: Color
    let startX: CGFloat
    let startY: CGFloat
    let endY: CGFloat
    let rotation: Double
    let endRotation: Double
    let size: CGFloat
    let duration: Double
    let delay: Double
    let shape: ConfettiShape
}

// MARK: - Confetti Particle View

struct ConfettiParticleView: View {
    let piece: ConfettiPiece

    @State private var animate = false

    var body: some View {
        GeometryReader { geo in
            confettiView
                .frame(width: piece.size, height: piece.size * (piece.shape == .rectangle ? 1.5 : 1))
                .rotationEffect(.degrees(animate ? piece.endRotation : piece.rotation))
                .position(
                    x: piece.startX * geo.size.width,
                    y: animate ? piece.endY * geo.size.height : piece.startY * geo.size.height
                )
                .opacity(animate ? 0 : 1)
                .onAppear {
                    withAnimation(
                        .easeOut(duration: piece.duration)
                        .delay(piece.delay)
                    ) {
                        animate = true
                    }
                }
        }
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private var confettiView: some View {
        switch piece.shape {
        case .circle:
            Circle().fill(piece.color)
        case .rectangle:
            RoundedRectangle(cornerRadius: 2).fill(piece.color)
        case .triangle:
            Triangle().fill(piece.color)
        }
    }
}

// MARK: - Triangle Shape

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.closeSubpath()
        }
    }
}
