import SwiftUI

enum AddHabitOption: String {
    case habit
    case objective
}

/// Shown from "+" only when objectives are available (PRD - objectives §8.2).
struct AddHabitOptionsSheet: View {
    let onSelect: (AddHabitOption) -> Void

    var body: some View {
        VStack(spacing: 12) {
            row(
                option: .habit,
                title: "Add habit",
                subtitle: "Create a single custom habit",
                icon: AnyView(ringIcon),
                identifier: "addOption_habit"
            )
            row(
                option: .objective,
                title: "Add from objective",
                subtitle: "Get habit suggestions to reach an objective",
                // Not Apple's Apple Intelligence logo, which apps may not use.
                icon: AnyView(symbolIcon("sparkles")),
                identifier: "addOption_objective"
            )
        }
        .padding(.horizontal, 16)
        .padding(.top, 24)
        .padding(.bottom, 16)
        .presentationDetents([.height(220), .medium])
        .presentationDragIndicator(.visible)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("addOptionsSheet")
    }

    private func row(
        option: AddHabitOption,
        title: LocalizedStringKey,
        subtitle: LocalizedStringKey,
        icon: AnyView,
        identifier: String
    ) -> some View {
        Button {
            onSelect(option)
        } label: {
            HStack(spacing: 16) {
                icon
                    .frame(width: 44, height: 44)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
            .padding(12)
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            )
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(identifier)
    }

    /// Echoes the app's ring motif.
    private var ringIcon: some View {
        ZStack {
            Circle()
                .stroke(Color.accentColor.opacity(0.25), lineWidth: 5)
            Circle()
                .trim(from: 0, to: 0.75)
                .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .padding(8)
        .accessibilityHidden(true)
    }

    private func symbolIcon(_ name: String) -> some View {
        Image(systemName: name)
            .font(.title2)
            .foregroundStyle(Color.accentColor)
            .accessibilityHidden(true)
    }
}
