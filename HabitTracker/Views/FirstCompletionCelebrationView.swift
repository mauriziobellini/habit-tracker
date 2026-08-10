import SwiftUI

/// Shown once, right after the user's very first habit completion
/// (Experiment - Opt out notifications).
///
/// When the completed habit has no reminder, the celebration doubles as the return cue: it
/// offers a one-tap opt-in with a time picker, since users who leave the first session without
/// a reminder rarely come back on day 2.
struct FirstCompletionCelebrationView: View {
    let offersReminderOptIn: Bool
    let onEnableReminder: (Date) -> Void
    let onDismiss: () -> Void

    @State private var reminderTime: Date = Calendar.current.date(
        from: DateComponents(hour: 9, minute: 0)
    ) ?? .now
    @State private var confettiPieces: [ConfettiPiece] = []
    @State private var showContent = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let confettiColors: [Color] = [
        .red, .orange, .yellow, .green, .blue, .purple, .pink, .mint, .cyan, .indigo
    ]

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            if !reduceMotion {
                ForEach(confettiPieces) { piece in
                    ConfettiParticleView(piece: piece)
                }
            }

            VStack(spacing: 20) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.green)

                Text("Congratulations on your first completion!")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                if offersReminderOptIn {
                    reminderOptIn
                } else {
                    Text("Keep it going — we'll remind you at your chosen time.")
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.9))
                        .multilineTextAlignment(.center)

                    dismissButton(title: String(localized: "Awesome!"), prominent: true)
                }
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
        .accessibilityAddTraits(.isModal)
    }

    @ViewBuilder
    private var reminderOptIn: some View {
        Text("People who turn on reminders complete their habits 40% more often.")
            .font(.body)
            .foregroundStyle(.white.opacity(0.9))
            .multilineTextAlignment(.center)

        DatePicker(
            "Time",
            selection: $reminderTime,
            displayedComponents: .hourAndMinute
        )
        .datePickerStyle(.compact)
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12).fill(.white.opacity(0.15))
        )

        Button {
            onEnableReminder(reminderTime)
        } label: {
            Text("Turn on reminders")
                .font(.headline)
                .foregroundStyle(.black)
                .padding(.horizontal, 32)
                .padding(.vertical, 14)
                .background(Capsule().fill(.white))
        }
        .accessibilityIdentifier("firstCompletionEnableRemindersButton")

        dismissButton(title: String(localized: "Not now"), prominent: false)
    }

    private func dismissButton(title: String, prominent: Bool) -> some View {
        Button {
            onDismiss()
        } label: {
            Text(title)
                .font(prominent ? .headline : .subheadline)
                .foregroundStyle(prominent ? .black : .white.opacity(0.8))
                .padding(.horizontal, prominent ? 48 : 24)
                .padding(.vertical, prominent ? 14 : 8)
                .background {
                    if prominent {
                        Capsule().fill(.white)
                    }
                }
        }
        .accessibilityIdentifier("firstCompletionDismissButton")
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
