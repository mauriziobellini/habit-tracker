import Foundation
import SwiftData

/// Seeds the database with initial data on first launch.
enum SeedDataService {
    /// Inserts the four preset categories if the database is empty.
    @MainActor
    static func seedIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<Category>()
        let existingCount = (try? context.fetchCount(descriptor)) ?? 0

        guard existingCount == 0 else { return }

        let presets: [(name: String, order: Int)] = [
            ("Health",   0),
            ("Fitness",  1),
            ("Learning", 2),
            ("Social",   3),
        ]

        for preset in presets {
            let category = Category(
                name: preset.name,
                isPreset: true,
                sortOrder: preset.order
            )
            context.insert(category)
        }
    }
}
