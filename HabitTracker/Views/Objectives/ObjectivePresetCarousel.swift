import SwiftUI

/// Horizontal, self-scrolling row of objective presets in an infinite loop
/// (PRD - objectives §8.3). Auto-scroll stops under Reduce Motion, with VoiceOver, and
/// once the user drags the row; it then behaves as a normal scroll view.
struct ObjectivePresetCarousel: View {
    let presets: [ObjectivePreset]
    var isEnabled = true
    let onSelect: (ObjectivePreset) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled
    @State private var rowSize: CGSize = .zero
    @State private var startDate = Date.now
    @State private var userTookOver = false

    /// Points per second.
    static let speed: CGFloat = 28
    static let spacing: CGFloat = 8

    static func autoScrolls(reduceMotion: Bool, voiceOverEnabled: Bool, userTookOver: Bool) -> Bool {
        !reduceMotion && !voiceOverEnabled && !userTookOver
    }

    /// Offset of the looping row after `elapsed` seconds. `loopWidth` is one copy of the
    /// row plus the gap before the next copy, so the wrap is seamless.
    static func wrappedOffset(elapsed: TimeInterval, speed: CGFloat, loopWidth: CGFloat) -> CGFloat {
        guard loopWidth > 0, elapsed > 0 else { return 0 }
        return -CGFloat((elapsed * Double(speed)).truncatingRemainder(dividingBy: Double(loopWidth)))
    }

    var body: some View {
        Group {
            if Self.autoScrolls(reduceMotion: reduceMotion, voiceOverEnabled: voiceOverEnabled, userTookOver: userTookOver) {
                autoScrollingRow
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    pills(accessible: true)
                        .padding(.horizontal, 16)
                }
            }
        }
        .disabled(!isEnabled)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("objectivePresetCarousel")
    }

    private var autoScrollingRow: some View {
        TimelineView(.animation) { context in
            let offset = Self.wrappedOffset(
                elapsed: context.date.timeIntervalSince(startDate),
                speed: Self.speed,
                loopWidth: rowSize.width + Self.spacing
            )
            // The row is far wider than the screen; the overlay pins it to the leading
            // edge, where a plain container would center it.
            Color.clear
                .overlay(alignment: .leading) {
                    HStack(spacing: Self.spacing) {
                        pills(accessible: true)
                            .onGeometryChange(for: CGSize.self) { $0.size } action: { rowSize = $0 }
                        // The second copy only fills the gap while the first wraps around.
                        pills(accessible: false)
                            .accessibilityHidden(true)
                    }
                    .fixedSize()
                    .padding(.leading, 16)
                    .offset(x: offset)
                }
        }
        .frame(height: max(rowSize.height, 44))
        .clipped()
        .simultaneousGesture(
            DragGesture(minimumDistance: 12).onChanged { _ in userTookOver = true }
        )
    }

    private func pills(accessible: Bool) -> some View {
        HStack(spacing: Self.spacing) {
            ForEach(presets) { preset in
                Button {
                    onSelect(preset)
                } label: {
                    Text(preset.localizedTitle)
                        .font(.subheadline.weight(.medium))
                        .lineLimit(1)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .frame(minHeight: 44)
                        .background(Capsule().fill(Color(.secondarySystemBackground)))
                        .foregroundStyle(.primary)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier(accessible ? "objectivePreset_\(preset.id)" : "")
            }
        }
    }
}
