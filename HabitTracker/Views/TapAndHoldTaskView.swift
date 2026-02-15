import SwiftUI
import SwiftData

/// Wraps a `TaskCircleView` with the tap-and-hold completion gesture (FR-1).
///
/// - Press and hold for 2 seconds → ring fills, completion recorded, haptic fires.
/// - Release early → ring smoothly retracts to zero.
/// - Single tap → triggers `onSingleTap` (for task menu).
/// - VoiceOver → single activation completes the task immediately.
/// - Reduce Motion → instant fill instead of animation.
struct TapAndHoldTaskView: View {
    let task: HabitTask
    let isCompleted: Bool
    let circleSize: CGFloat
    let onSingleTap: () -> Void
    let onCompleted: () -> Void

    @State private var progress: CGFloat = 0
    @State private var isHolding = false
    @State private var holdTimer: Timer?
    @State private var showCompletionBurst = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Hold duration in seconds.
    private let holdDuration: TimeInterval = 2.0
    /// Timer tick interval for smooth animation.
    private let tickInterval: TimeInterval = 1.0 / 60.0

    private var accentColor: Color {
        TaskColor.from(token: task.colorToken).color
    }

    var body: some View {
        TaskCircleView(
            task: task,
            isCompleted: isCompleted || showCompletionBurst,
            circleSize: circleSize
        )
        .scaleEffect(showCompletionBurst ? 1.15 : 1.0)
        .overlay(alignment: .top) {
            // Progress ring overlay (only while holding and not yet completed)
            if !isCompleted && progress > 0 {
                CompletionRingView(
                    progress: progress,
                    color: accentColor,
                    lineWidth: 4,
                    size: circleSize + 4
                )
                .frame(width: circleSize + 4, height: circleSize + 4)
                .offset(y: -2) // center ring over the task circle
            }
        }
        .animation(reduceMotion ? nil : .easeOut(duration: 0.3), value: showCompletionBurst)
        .gesture(holdGesture)
        .simultaneousGesture(tapGesture)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(task.title), \(isCompleted ? "completed" : "not completed")")
        .accessibilityHint(isCompleted ? "Already completed" : "Double tap to open menu, or double tap and hold to complete")
        .accessibilityAction(.default) {
            // VoiceOver single activation → complete immediately
            if !isCompleted {
                completeTask()
            }
        }
    }

    // MARK: - Gestures

    /// Single tap for menu
    private var tapGesture: some Gesture {
        TapGesture()
            .onEnded {
                if !isHolding {
                    onSingleTap()
                }
            }
    }

    /// Long press → hold → track progress
    private var holdGesture: some Gesture {
        LongPressGesture(minimumDuration: 0.15)
            .onChanged { _ in
                // Finger is down
            }
            .onEnded { _ in
                guard !isCompleted else { return }
                startHold()
            }
            .sequenced(before:
                DragGesture(minimumDistance: 0)
                    .onEnded { _ in
                        cancelHold()
                    }
            )
    }

    // MARK: - Hold Logic

    private func startHold() {
        guard !isHolding else { return }
        isHolding = true
        progress = 0

        if reduceMotion {
            // Instant completion for Reduce Motion
            completeTask()
            return
        }

        let increment = CGFloat(tickInterval / holdDuration)

        holdTimer = Timer.scheduledTimer(withTimeInterval: tickInterval, repeats: true) { timer in
            progress += increment

            if progress >= 1.0 {
                progress = 1.0
                timer.invalidate()
                holdTimer = nil
                completeTask()
            }
        }
    }

    private func cancelHold() {
        guard isHolding else { return }
        isHolding = false
        holdTimer?.invalidate()
        holdTimer = nil

        if progress < 1.0 {
            // Smooth retraction
            if reduceMotion {
                progress = 0
            } else {
                withAnimation(.easeOut(duration: 0.3)) {
                    progress = 0
                }
            }
        }
    }

    private func completeTask() {
        isHolding = false
        holdTimer?.invalidate()
        holdTimer = nil
        progress = 0

        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        // Completion burst animation
        showCompletionBurst = true

        if !reduceMotion {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                showCompletionBurst = false
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                showCompletionBurst = false
            }
        }

        // VoiceOver announcement
        UIAccessibility.post(
            notification: .announcement,
            argument: "\(task.title) completed"
        )

        onCompleted()
    }
}
