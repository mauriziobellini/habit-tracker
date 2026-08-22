import Foundation
import SwiftData

/// One-time, on-device data normalization run at launch.
///
/// SwiftData lightweight migration handles the schema changes themselves (renaming
/// `timesPerDay` → `timesPerPeriod`, adding `tracking`, dropping
/// `measurementDuration`, adding the habit-strength columns). What needs code is
/// the behavioural migrations:
///
/// 1. Rewriting the legacy `everyWeek` frequency onto `weekly` (PRD Migration §2–§5).
/// 2. Seeding habit-strength stage bookkeeping so existing habits do not fire a
///    barrage of celebrations on first launch after the update
///    (PRD - Habit strength §10.5).
///
/// Idempotent, and never touches `TaskCompletion` rows.
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

        // Must run after the frequency rewrite above: the frequency determines how
        // completions are credited, and therefore the stage that gets seeded.
        didChange = seedHabitStrengthIfNeeded(tasks: tasks, context: context) || didChange

        if didChange {
            try? context.save()
        }
    }

    /// Seeds the stage bookkeeping for habits that predate Habit Strength.
    ///
    /// Without this, a user whose habit is already Established would open the app
    /// after updating and be told they had just reached Developing — or be walked
    /// through every stage in turn. Establishing the baseline silently means the
    /// next genuine transition is the first one they see.
    ///
    /// - Returns: whether anything was modified.
    @MainActor
    private static func seedHabitStrengthIfNeeded(
        tasks: [HabitTask],
        context: ModelContext
    ) -> Bool {
        let settings = AppSettings.shared(in: context)
        guard !settings.hasSeededHabitStrength else { return false }

        // One calendar for the whole batch: this runs synchronously at launch.
        let calendar = Calendar.current
        let now = Date.now

        for task in tasks {
            let stage = HabitStrengthService.strength(
                for: task,
                on: now,
                calendar: calendar,
                weekStartDay: settings.weekStartDay
            ).stage

            task.lastObservedStage = stage
            // Treated as already celebrated so the backfill fires nothing.
            task.lastCelebratedStage = stage
            task.strengthEvaluatedAt = now
            // lastCelebratedAt stays nil — no celebration has actually been shown.
        }

        settings.hasSeededHabitStrength = true
        return true
    }
}
