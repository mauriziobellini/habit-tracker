import SwiftUI

/// A suggested habit in the proposal list (PRD - objectives §8.3).
struct ObjectiveProposalCard: View {
    let proposal: HabitProposal
    let index: Int
    let measurementSystem: MeasurementSystem
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: proposal.iconName)
                    .font(.title3)
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color.accentColor.opacity(0.12)))

                VStack(alignment: .leading, spacing: 4) {
                    Text(proposal.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    if !proposal.summary.isEmpty {
                        Text(proposal.summary)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Text(configSummary)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color.accentColor)
                }
                .multilineTextAlignment(.leading)

                Spacer(minLength: 0)

                if proposal.isAdded {
                    Label("Added", systemImage: "checkmark.circle.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.green)
                        .labelStyle(.titleAndIcon)
                } else {
                    Image(systemName: "plus.circle")
                        .font(.title3)
                        .foregroundStyle(Color.accentColor)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            )
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(proposal.isAdded)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(proposal.isAdded ? Text(verbatim: "") : Text("Double tap to review and add"))
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier(proposal.isAdded ? "objectiveCardAdded_\(index)" : "objectiveCard_\(index)")
    }

    private var configSummary: String {
        proposal.configSummary(measurementSystem: measurementSystem)
    }

    private var accessibilityLabel: String {
        var parts = [proposal.title, configSummary]
        if proposal.isAdded { parts.append(NSLocalizedString("Added", comment: "")) }
        return parts.joined(separator: ", ")
    }
}

/// Placeholder card shown while a habit is being generated.
struct ObjectiveSkeletonCard: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var dimmed = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .frame(width: 44, height: 44)
            VStack(alignment: .leading, spacing: 8) {
                Capsule().frame(width: 140, height: 14)
                Capsule().frame(maxWidth: .infinity).frame(height: 10)
                Capsule().frame(width: 90, height: 10)
            }
            Spacer(minLength: 0)
        }
        .foregroundStyle(Color(.tertiarySystemFill))
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .opacity(dimmed ? 0.45 : 1)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                dimmed = true
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Generating suggestions"))
        .accessibilityIdentifier("objectiveSkeleton")
    }
}
