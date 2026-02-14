import SwiftUI

/// Displays a single task as a circle with icon/initials and title underneath.
/// Reused in the task list grid and onboarding tutorial.
struct TaskCircleView: View {
    let task: HabitTask
    let isCompleted: Bool

    /// Size of the circle (diameter).
    var circleSize: CGFloat = 80

    private var accentColor: Color {
        TaskColor.from(token: task.colorToken).color
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Background circle
                Circle()
                    .fill(isCompleted ? Color.white : accentColor.opacity(0.15))
                    .frame(width: circleSize, height: circleSize)

                // Border ring
                Circle()
                    .strokeBorder(
                        isCompleted ? accentColor.opacity(0.3) : accentColor,
                        lineWidth: isCompleted ? 2 : 3
                    )
                    .frame(width: circleSize, height: circleSize)

                // Icon or initials
                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: circleSize * 0.3, weight: .bold))
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

            Text(task.title)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: circleSize + 20)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(task.title), \(isCompleted ? String(localized: "completed") : String(localized: "not completed"))")
        .accessibilityIdentifier("taskCircle_\(task.id.uuidString)")
        .accessibilityIgnoresInvertColors(true)
    }
}
