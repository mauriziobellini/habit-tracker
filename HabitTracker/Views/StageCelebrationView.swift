import SwiftUI

/// Celebrates crossing into a new habit stage (PRD - Habit strength §8).
///
/// Matches the presentation of `RewardCelebrationView` and
/// `FirstCompletionCelebrationView`: a full-screen overlay rather than a sheet,
/// with an opaque backdrop, confetti, and a spring entrance. When the habit has no
/// reminder yet, the moment doubles as the opt-in prompt.
struct StageCelebrationView: View {
    let stage: HabitStage
    let habit: CelebrationHabit
    let offersNotificationOptIn: Bool
    let onEnableNotifications: (Date) -> Void
    let onDismiss: () -> Void

    @State private var reminderTime: Date = Calendar.current.date(
        from: DateComponents(hour: 9, minute: 0)
    ) ?? .now
    @State private var confettiPieces: [ConfettiPiece] = []
    @State private var showContent = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var copy: StageCelebrationCopy { StageCelebrationCopy.forStage(stage) }

    var body: some View {
        ZStack {
            CelebrationBackdrop(accentColor: habit.accentColor, onTap: onDismiss)

            if !reduceMotion {
                ForEach(confettiPieces) { piece in
                    ConfettiParticleView(piece: piece)
                }
            }

            VStack(spacing: 20) {
                Image(systemName: stage.sfSymbolName)
                    .font(.system(size: 56))
                    .foregroundStyle(habit.accentColor)

                VStack(spacing: 12) {
                    Text("Congratulations! New stage achieved")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)

                    CelebrationHabitBadge(habit: habit)
                }

                Text(stage.displayName.uppercased())
                    .font(.caption.weight(.bold))
                    .tracking(1.5)
                    .foregroundStyle(.secondary)

                Text(copy.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)

                Text(copy.body)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                if offersNotificationOptIn {
                    notificationOptIn
                } else {
                    dismissButton(title: String(localized: "Keep going"), prominent: true)
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
        .accessibilityIdentifier("stageCelebration")
    }

    @ViewBuilder
    private var notificationOptIn: some View {
        DatePicker(
            "Time",
            selection: $reminderTime,
            displayedComponents: .hourAndMinute
        )
        .datePickerStyle(.compact)
        .celebrationFieldBackground()

        Button {
            onEnableNotifications(reminderTime)
        } label: {
            Text("Turn on reminders")
                .celebrationProminentLabel()
        }
        .accessibilityIdentifier("stageCelebrationEnableRemindersButton")

        dismissButton(title: String(localized: "Not now"), prominent: false)
    }

    private func dismissButton(title: String, prominent: Bool) -> some View {
        Button {
            onDismiss()
        } label: {
            if prominent {
                Text(title).celebrationProminentLabel(horizontalPadding: 48)
            } else {
                Text(title).celebrationSecondaryLabel()
            }
        }
        .accessibilityIdentifier("stageCelebrationDismissButton")
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

// MARK: - Copy

/// The five stage-advance messages (PRD - Habit strength §8).
///
/// Keyed on the *destination* stage, so a score that leaps two boundaries at once
/// produces a single celebration for the highest stage reached rather than walking
/// the user through each one. Deliberately framed as motivational behavioural
/// science, never as a clinical claim (PRD §3 non-goals).
struct StageCelebrationCopy {
    let title: String
    let body: String

    static func forStage(_ stage: HabitStage) -> StageCelebrationCopy {
        switch stage {
        case .developing:
            return StageCelebrationCopy(
                title: NSLocalizedString("Your brain is wiring the cue", comment: ""),
                body: NSLocalizedString(
                    "Repetition is linking this action to its context. The first neural pathway is forming — keep showing up and the association will deepen.",
                    comment: ""
                )
            )
        case .building:
            return StageCelebrationCopy(
                title: NSLocalizedString("Automaticity is taking root", comment: ""),
                body: NSLocalizedString(
                    "Your mind needs less deliberate effort to start. Context cues are beginning to trigger the behavior on their own — consistency locks this in.",
                    comment: ""
                )
            )
        case .strong:
            return StageCelebrationCopy(
                title: NSLocalizedString("Habit control is shifting", comment: ""),
                body: NSLocalizedString(
                    "Goal-directed effort is giving way to habitual control. The behavior is settling into a reliable loop — protect this streak and it will stick.",
                    comment: ""
                )
            )
        case .established:
            return StageCelebrationCopy(
                title: NSLocalizedString("The loop is becoming stable", comment: ""),
                body: NSLocalizedString(
                    "Cue, routine, and reward are aligning with growing automaticity. Missing a day won't erase progress — returning promptly keeps the pathway strong.",
                    comment: ""
                )
            )
        case .mastering:
            return StageCelebrationCopy(
                title: NSLocalizedString("Near-automatic mastery", comment: ""),
                body: NSLocalizedString(
                    "This habit is approaching high automaticity. Your brain retrieves it with little conscious push — continue the rhythm and make it part of who you are.",
                    comment: ""
                )
            )
        case .starting:
            // Unreachable in practice: Starting is the floor, so it is only ever a
            // reversion target, and reversions are never celebrated.
            return StageCelebrationCopy(
                title: NSLocalizedString("Every repetition counts", comment: ""),
                body: NSLocalizedString(
                    "Keep showing up — consistency is what turns an intention into a habit.",
                    comment: ""
                )
            )
        }
    }
}
