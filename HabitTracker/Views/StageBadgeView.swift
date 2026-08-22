import SwiftUI

/// The habit stage glyph (PRD - Habit strength §8 iconography).
///
/// Styled as a sibling of the freemium lock badge in `TapAndHoldTaskView` so the
/// two corner badges read as one family. From Strong upward the badge is larger
/// and tinted with the habit colour; earlier stages stay deliberately quiet.
///
/// Decorative by default: the stage name is announced by the surrounding element,
/// either the stage row's label or the habit circle's accessibility label.
struct StageBadgeView: View {
    let stage: HabitStage
    let accentColor: Color

    /// Glyph size. Defaults to the dashboard badge size.
    var size: CGFloat = 11

    private var isProminent: Bool { stage.isProminentBadge }

    var body: some View {
        Image(systemName: stage.sfSymbolName)
            .font(.system(size: isProminent ? size * 1.2 : size, weight: .bold))
            .foregroundStyle(isProminent ? Color.white : Color(.systemBackground))
            .padding(isProminent ? 5 : 4)
            .background(
                Circle().fill(isProminent ? accentColor : Color.secondary)
            )
            .overlay(
                Circle().strokeBorder(Color(.systemBackground), lineWidth: 1.5)
            )
            .accessibilityHidden(true)
    }
}

/// The stage row used inside the habit summary sheet: icon immediately to the left
/// of the localized stage name (PRD §9).
struct StageLabelView: View {
    let stage: HabitStage
    let accentColor: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: stage.sfSymbolName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(stage.isProminentBadge ? accentColor : Color.secondary)
            Text(stage.displayName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(stage.displayName)
        .accessibilityIdentifier("habitSummary_stageLabel")
    }
}
