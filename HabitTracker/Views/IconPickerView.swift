import SwiftUI

/// Grid-based SF Symbol icon picker for task configuration.
struct IconPickerView: View {
    @Binding var selectedIcon: String?
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    /// Curated subset of SF Symbols suitable for habit tasks.
    private static let availableIcons: [String] = [
        // Fitness
        "figure.walk", "figure.run", "bicycle", "figure.pool.swim",
        "figure.strengthtraining.functional", "figure.strengthtraining.traditional",
        "dumbbell.fill", "figure.yoga", "figure.hiking", "figure.dance",
        "sportscourt.fill", "tennisball.fill", "soccerball", "basketball.fill",
        // Health
        "brain.head.profile", "heart.fill", "lungs.fill", "pill.fill",
        "cross.case.fill", "bed.double.fill", "sun.max.fill", "moon.fill",
        "drop.fill", "flame.fill", "leaf.fill", "cup.and.saucer.fill",
        "fork.knife", "mouth.fill", "hands.sparkles.fill", "hand.raised.fill",
        "nosign", "eye.fill", "ear.fill",
        // Social
        "phone.fill", "phone.arrow.up.right.fill", "person.2.fill",
        "person.3.fill", "bubble.left.and.bubble.right.fill",
        "message.fill", "envelope.fill", "hand.wave.fill",
        // Learning
        "book.fill", "book.closed.fill", "character.book.closed.fill",
        "graduationcap.fill", "pencil.and.outline", "doc.text.fill",
        "pianokeys", "guitars.fill", "paintbrush.fill", "theatermasks.fill",
        // Animals
        "dog.fill", "cat.fill", "hare.fill", "tortoise.fill", "bird.fill",
        // Objects & misc
        "star.fill", "bolt.fill", "flag.fill", "bell.fill",
        "clock.fill", "calendar", "mappin.circle.fill",
        "house.fill", "briefcase.fill", "cart.fill",
        "camera.fill", "gamecontroller.fill", "headphones",
        "music.note", "gift.fill", "lightbulb.fill",
        "wrench.fill", "hammer.fill", "paintpalette.fill",
        "airplane", "car.fill", "tram.fill",
    ]

    private var filteredIcons: [String] {
        if searchText.isEmpty { return Self.availableIcons }
        return Self.availableIcons.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 6)

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    // "None" option: use initials
                    Button {
                        selectedIcon = nil
                        dismiss()
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(selectedIcon == nil
                                      ? Color.accentColor.opacity(0.2)
                                      : Color(.secondarySystemBackground))
                                .frame(height: 52)

                            Text("AB")
                                .font(.headline)
                                .foregroundStyle(.primary)
                        }
                    }

                    ForEach(filteredIcons, id: \.self) { icon in
                        Button {
                            selectedIcon = icon
                            dismiss()
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(selectedIcon == icon
                                          ? Color.accentColor.opacity(0.2)
                                          : Color(.secondarySystemBackground))
                                    .frame(height: 52)

                                Image(systemName: icon)
                                    .font(.title3)
                                    .foregroundStyle(selectedIcon == icon ? Color.accentColor : Color.primary)
                            }
                        }
                    }
                }
                .padding(16)
            }
            .searchable(text: $searchText, prompt: "Search icons")
            .navigationTitle("Choose Icon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
