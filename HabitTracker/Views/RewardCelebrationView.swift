import SwiftUI

/// Full-screen celebration overlay shown when the user reaches a reward streak.
/// Features animated confetti particles and the reward message.
struct RewardCelebrationView: View {
    let habit: CelebrationHabit
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

                CelebrationHabitBadge(habit: habit)

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
        .accessibilityLabel(
            Text(habit.name)
                + Text(verbatim: ". ")
                + Text("Congratulations! You can now reward yourself with: \(rewardText)")
        )
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

// MARK: - Habit Identity

/// The habit a celebration is about, snapshotted for the overlay.
///
/// Celebrations used to show only stage or reward copy, which left the user guessing
/// which habit earned it once more than one habit is on the dashboard.
struct CelebrationHabit {
    let name: String
    let iconName: String?
    let initials: String
    let accentColor: Color

    init(task: HabitTask) {
        self.name = task.title
        self.iconName = task.iconName
        self.initials = task.initialsDisplay
        self.accentColor = TaskColor.from(token: task.colorToken).color
    }

    init(name: String, iconName: String?, initials: String, accentColor: Color) {
        self.name = name
        self.iconName = iconName
        self.initials = initials
        self.accentColor = accentColor
    }
}

/// Icon-and-name pill naming the habit a celebration refers to. Mirrors the icon
/// fallback used on the dashboard circles: SF Symbol when set, initials otherwise.
struct CelebrationHabitBadge: View {
    let habit: CelebrationHabit

    var body: some View {
        HStack(spacing: 8) {
            Group {
                if let iconName = habit.iconName {
                    Image(systemName: iconName)
                        .font(.system(size: 17, weight: .medium))
                } else {
                    Text(habit.initials)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                }
            }
            // Full-strength accent on the dimmed backdrop: the palette is tuned to stay
            // vibrant against dark, and a tinted plate behind it washed the glyph out.
            .foregroundStyle(habit.accentColor)
            .fixedSize()

            Text(habit.name)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .lineLimit(2)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Capsule().fill(.white.opacity(0.15)))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(habit.name))
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
