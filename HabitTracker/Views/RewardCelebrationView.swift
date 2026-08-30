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

    var body: some View {
        ZStack {
            CelebrationBackdrop(accentColor: habit.accentColor, onTap: onDismiss)

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
                    .foregroundStyle(.orange)

                Text("Congratulations!")
                    .font(.title.weight(.bold))
                    .foregroundStyle(.primary)

                CelebrationHabitBadge(habit: habit)

                Text("You can now reward yourself with:")
                    .font(.body)
                    .foregroundStyle(.secondary)

                Text(rewardText)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)

                Button {
                    onDismiss()
                } label: {
                    Text("Awesome!")
                        .celebrationProminentLabel(horizontalPadding: 48)
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
                color: ConfettiPiece.palette.randomElement()!,
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

// MARK: - Celebration Chrome

/// Opaque full-screen backdrop shared by every celebration overlay.
///
/// The celebrations used to sit on a 60% black scrim, which left the dashboard
/// grid showing through and pulled the copy close to the backdrop luminance —
/// unreadable in dark mode, muddy in light mode. An opaque semantic surface with a
/// soft accent wash keeps every label at full contrast in both appearances
/// (UX principles §4 and §8).
struct CelebrationBackdrop: View {
    let accentColor: Color
    let onTap: () -> Void

    var body: some View {
        ZStack {
            Color(.systemBackground)

            LinearGradient(
                colors: [accentColor.opacity(0.28), accentColor.opacity(0.06), .clear],
                startPoint: .top,
                endPoint: .center
            )
        }
        .ignoresSafeArea()
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }
}

extension View {
    /// Prominent capsule CTA. The inverted fill (primary plate, background-colored
    /// label) guarantees the contrast ratio in both appearances without hardcoding
    /// black or white.
    func celebrationProminentLabel(horizontalPadding: CGFloat = 32) -> some View {
        font(.headline)
            .foregroundStyle(Color(.systemBackground))
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, 14)
            .background(Capsule().fill(Color.primary))
    }

    /// Low-emphasis text CTA sitting directly on the backdrop.
    func celebrationSecondaryLabel() -> some View {
        font(.subheadline)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 24)
            .padding(.vertical, 8)
    }

    /// Neutral plate behind inline controls (the reminder time picker).
    func celebrationFieldBackground() -> some View {
        padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12).fill(Color(.tertiarySystemFill))
            )
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
            // Full-strength accent: the palette adapts per appearance already, and a
            // tinted plate behind the glyph washed it out.
            .foregroundStyle(habit.accentColor)
            .fixedSize()

            Text(habit.name)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(2)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Capsule().fill(Color(.tertiarySystemFill)))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(habit.name))
    }
}

// MARK: - Confetti Data

enum ConfettiShape: CaseIterable {
    case circle, rectangle, triangle
}

struct ConfettiPiece: Identifiable {
    /// Shared by every celebration. Pale tones (yellow, mint, cyan) are left out:
    /// they all but vanish against the light-appearance backdrop, and the particles
    /// already fade as they fall.
    static let palette: [Color] = [
        .red, .orange, .green, .teal, .blue, .indigo, .purple, .pink
    ]

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
