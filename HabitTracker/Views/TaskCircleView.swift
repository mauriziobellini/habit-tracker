import SwiftUI

/// Displays a single task as a circle with icon/initials and title underneath.
/// Reused in the task list grid and onboarding tutorial.
///
/// When a `PeriodProgress` is supplied, the circle reflects the multi-completion
/// states from PRD §10 (partial highlight + `C/N` counter badge). Without it the
/// circle falls back to the simple completed / not-completed appearance used by
/// the onboarding tutorial.
struct TaskCircleView: View {
    let task: HabitTask
    let isCompleted: Bool

    /// Size of the circle (diameter).
    var circleSize: CGFloat = 80

    /// Optional period progress driving the multi-completion visuals.
    var progress: PeriodProgress? = nil

    private var accentColor: Color {
        TaskColor.from(token: task.colorToken).color
    }

    /// Resolved visual state.
    private var state: ListState {
        if let progress { return progress.listState }
        return isCompleted ? .complete : .incomplete
    }

    private var showsCounter: Bool {
        progress?.showsCounter ?? false
    }

    private var isFull: Bool { state == .complete }
    private var isPartial: Bool { state == .partial }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Background circle
                Circle()
                    .fill(isFull ? Color.white : accentColor.opacity(0.15))
                    .frame(width: circleSize, height: circleSize)

                // Border ring — thicker/solid accent when partial or complete.
                Circle()
                    .strokeBorder(
                        isFull ? accentColor.opacity(0.3) : accentColor,
                        lineWidth: isFull ? 2 : (isPartial ? 5 : 3)
                    )
                    .frame(width: circleSize, height: circleSize)

                centerContent
            }
            .overlay(alignment: .bottomTrailing) {
                if showsCounter, let progress {
                    counterBadge(current: progress.current, target: progress.target)
                }
            }

            Text(task.title)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: circleSize + 20)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityIdentifier("taskCircle_\(task.id.uuidString)")
        .accessibilityIgnoresInvertColors(true)
    }

    // MARK: - Center content

    @ViewBuilder
    private var centerContent: some View {
        if isFull {
            Image(systemName: "checkmark")
                .font(.system(size: circleSize * 0.3, weight: .bold))
                .foregroundStyle(accentColor)
        } else if isPartial {
            // Partial: a check mark appears but the circle is not fully filled.
            Image(systemName: "checkmark")
                .font(.system(size: circleSize * 0.28, weight: .semibold))
                .foregroundStyle(accentColor)
        } else if let iconName = task.iconName {
            Image(systemName: iconName)
                .font(.system(size: circleSize * 0.35))
                .foregroundStyle(accentColor)
                .symbolRenderingMode(.hierarchical)
        } else {
            Text(task.initialsDisplay)
                .font(.system(size: circleSize * 0.28, weight: .semibold, design: .rounded))
                .foregroundStyle(accentColor)
        }
    }

    // MARK: - Counter badge (PRD §10)

    private func counterBadge(current: Int, target: Int) -> some View {
        let diameter = max(22, circleSize * 0.32)
        return Text("\(current)/\(target)")
            .font(.system(size: diameter * 0.42, weight: .bold, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(Color(.systemBackground))
            .padding(.horizontal, diameter * 0.18)
            .frame(minWidth: diameter, minHeight: diameter)
            .background(
                Capsule().fill(Color.primary)
            )
            .overlay(
                Capsule().strokeBorder(Color(.systemBackground), lineWidth: 1.5)
            )
            .offset(x: diameter * 0.30, y: diameter * 0.30)
            .accessibilityHidden(true)
    }

    // MARK: - Accessibility

    private var accessibilityLabel: String {
        if let progress, progress.showsCounter {
            let format = NSLocalizedString("%@, %lld of %lld completed this period", comment: "")
            return String(format: format, task.title, progress.current, progress.target)
        }
        let status = isFull
            ? String(localized: "completed")
            : String(localized: "not completed")
        return "\(task.title), \(status)"
    }
}
