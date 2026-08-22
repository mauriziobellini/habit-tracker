import SwiftUI
import SwiftData

/// The habit summary bottom sheet — "Version A: Hero ring" (PRD - Habit strength §9).
///
/// Replaces the tap-to-menu confirmation dialog. Strength is the primary message;
/// identity, stage, consistency and actions follow underneath.
struct HabitSummarySheetView: View {
    let task: HabitTask
    let strength: HabitStrength
    let weekStartDay: Int
    let onAction: (Action) -> Void

    /// What the user chose in the sheet. The parent performs it *after* dismissal,
    /// so two sheets never contend for presentation.
    enum Action {
        case stats
        case edit
        case remove
        case manageCompletions
    }

    private var accentColor: Color {
        TaskColor.from(token: task.colorToken).color
    }

    /// Measured heights of the two halves of the sheet, which together drive the
    /// single content-sized detent.
    @State private var contentHeight: CGFloat = 0
    @State private var actionsHeight: CGFloat = 0

    /// Used until the first layout pass reports real heights. Only has to be in the
    /// right neighbourhood; it is replaced before the sheet finishes animating in.
    private static let estimatedHeight: CGFloat = 540

    /// One detent sized to the content, rather than `[.medium, .large]`: medium cut
    /// the consistency grid in half, and large left a screenful of empty space below
    /// it. With a single detent there is nothing to expand to — the sheet opens at
    /// exactly the height it needs.
    private var sheetHeight: CGFloat {
        guard contentHeight > 0, actionsHeight > 0 else { return Self.estimatedHeight }
        return contentHeight + actionsHeight
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 22) {
                    heroRing
                    identityRow
                    StageLabelView(stage: strength.stage, accentColor: accentColor)
                    consistencySection
                }
                .padding(.horizontal, 20)
                // Clears the drag indicator and gives the ring room to breathe.
                .padding(.top, 44)
                .padding(.bottom, 20)
                .onHeightChange { contentHeight = $0 }
            }
            // Not on the enclosing VStack: an identifier set on a container is pushed
            // down onto descendant elements, which would overwrite the action pills'
            // own identifiers and make them unreachable from the UI tests.
            .accessibilityIdentifier("habitSummarySheet")
            // The sheet is sized to fit, so scrolling is a fallback for large
            // accessibility text only — no rubber-banding when everything is visible.
            .scrollBounceBehavior(.basedOnSize)

            // Outside the ScrollView so they stay put if that fallback scrolling does
            // kick in: these are the only actions the sheet offers.
            actionPills
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 20)
                .background(.bar)
                .onHeightChange { actionsHeight = $0 }
        }
        .presentationDetents([.height(sheetHeight)])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Consistency

    private var consistencySection: some View {
        VStack(spacing: 12) {
            HabitDailyGridView(
                task: task,
                weekStartDay: weekStartDay,
                onTap: { onAction(.manageCompletions) }
            )

            // The grid itself is tappable, but nothing about it says so. This spells
            // out the affordance and gives the action a reliable hit target.
            Button {
                onAction(.manageCompletions)
            } label: {
                Text("Manage Completions")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(accentColor)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("habitSummary_manageCompletionsButton")
        }
    }

    // MARK: - Hero ring

    private static let ringSize: CGFloat = 150
    private static let ringLineWidth: CGFloat = 13

    private var heroRing: some View {
        ZStack {
            Circle()
                .stroke(
                    strength.isEligible ? accentColor.opacity(0.15) : Color(.systemFill),
                    lineWidth: Self.ringLineWidth
                )
                .frame(width: Self.ringSize, height: Self.ringSize)

            if strength.isEligible {
                Circle()
                    .trim(from: 0, to: CGFloat(strength.score) / 100)
                    .stroke(
                        accentColor,
                        style: StrokeStyle(lineWidth: Self.ringLineWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: Self.ringSize, height: Self.ringSize)
            }

            ringCenter
                .frame(width: Self.ringSize - Self.ringLineWidth * 3)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(ringAccessibilityLabel)
        .accessibilityIdentifier("habitSummary_strengthRing")
    }

    @ViewBuilder
    private var ringCenter: some View {
        if strength.isEligible {
            VStack(spacing: 2) {
                Text("Habit strength")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Text("\(strength.score)")
                    .font(.system(size: 46, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.primary)
            }
        } else {
            // No number and a grey ring: a 0% arc would read as failure rather
            // than as "not measured yet" (PRD §9 empty state).
            Text("Habit strength will be shown after 3 completions")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var ringAccessibilityLabel: String {
        guard strength.isEligible else {
            return String(localized: "Habit strength will be shown after 3 completions")
        }
        let format = NSLocalizedString("Habit strength, %lld", comment: "")
        return String(format: format, strength.score)
    }

    // MARK: - Identity

    private var identityRow: some View {
        HStack(spacing: 10) {
            if let iconName = task.iconName {
                Image(systemName: iconName)
                    .font(.title3)
                    .foregroundStyle(accentColor)
                    .symbolRenderingMode(.hierarchical)
            } else {
                Text(task.initialsDisplay)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(accentColor)
            }

            Text(task.title)
                .font(.title3.weight(.semibold))
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Actions

    private var actionPills: some View {
        HStack(spacing: 10) {
            actionPill(
                title: String(localized: "Stats"),
                systemImage: "chart.bar.fill",
                identifier: "habitSummary_statsButton"
            ) { onAction(.stats) }

            actionPill(
                title: String(localized: "Edit"),
                systemImage: "pencil",
                identifier: "habitSummary_editButton"
            ) { onAction(.edit) }

            actionPill(
                title: String(localized: "Remove"),
                systemImage: "trash",
                identifier: "habitSummary_removeButton",
                isDestructive: true
            ) { onAction(.remove) }
        }
    }

    private func actionPill(
        title: String,
        systemImage: String,
        identifier: String,
        isDestructive: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.subheadline.weight(.semibold))
                Text(title)
                    .font(.caption.weight(.medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(isDestructive ? Color.red : Color.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(identifier)
    }
}

// MARK: - Height measurement

private extension View {
    /// Reports this view's laid-out height whenever it changes.
    ///
    /// Measured on a background rather than with `.fixedSize`, so reading the height
    /// cannot feed back into the layout that produced it.
    func onHeightChange(_ action: @escaping (CGFloat) -> Void) -> some View {
        background {
            GeometryReader { proxy in
                Color.clear
                    .onChange(of: proxy.size.height, initial: true) { _, height in
                        action(height)
                    }
            }
        }
    }
}
