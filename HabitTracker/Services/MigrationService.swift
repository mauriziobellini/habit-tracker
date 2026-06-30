import Foundation
import SwiftData

/// One-time, on-device data normalization for the weekly/monthly counter feature.
///
/// SwiftData lightweight migration handles the schema changes (renaming
/// `timesPerDay` → `timesPerPeriod`, adding `tracking`, dropping
/// `measurementDuration`). The only value transformation needed is rewriting the
/// legacy `everyWeek` frequency onto `weekly`. This runs at launch, is idempotent,
/// and never touches `TaskCompletion` rows (PRD Migration §2–§5).
enum MigrationService {
    @MainActor
    static func normalizeIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<HabitTask>()
        guard let tasks = try? context.fetch(descriptor) else { return }

        var didChange = false
        for task in tasks where task.frequencyType == .everyWeek {
            task.frequencyType = .weekly
            // Preserve the previous behavior: legacy weekly habits credit every
            // completion (PRD Migration §3).
            task.tracking = .eachCompletion
            didChange = true
        }

        if didChange {
            try? context.save()
        }
    }
}
