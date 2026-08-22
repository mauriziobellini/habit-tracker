import Foundation
import SwiftData

/// Detects habit stage advances and reversions (PRD - Habit strength §8).
///
/// There is no `BGAppRefreshTask` in this project and iOS will not reliably run
/// code at a fixed time, so evaluation is opportunistic: on app foreground and
/// immediately after a completion is recorded.
///
/// This type only *reports* transitions. Presenting the celebration, scheduling
/// notifications and emitting analytics are the caller's job.
@MainActor
enum HabitStageEvaluator {

    /// A stage change observed for one habit.
    struct Transition: Identifiable {
        let task: HabitTask
        let from: HabitStage
        let to: HabitStage
        /// Whether the celebration pop-up may be shown for this transition.
        let isCelebratable: Bool

        var id: UUID { task.id }
        var isAdvance: Bool { to > from }
    }

    /// How long after a celebration another one is suppressed. Guards against a
    /// score hovering on a boundary and celebrating twice in one session.
    private static let celebrationCooldown: TimeInterval = 12 * 60 * 60

    /// Evaluates `tasks` and records the new stage on each.
    ///
    /// - Parameter force: re-evaluate even if the habit was already evaluated
    ///   today. Used on the post-completion path, where the whole point is that
    ///   today's data just changed.
    /// - Returns: every stage change detected, in `tasks` order.
    static func evaluate(
        tasks: [HabitTask],
        context: ModelContext,
        cache: HabitStrengthCache,
        weekStartDay: Int,
        now: Date = .now,
        force: Bool = false
    ) -> [Transition] {
        let calendar = Calendar.current
        var transitions: [Transition] = []
        var didChange = false

        for task in tasks {
            if !force,
               let evaluatedAt = task.strengthEvaluatedAt,
               calendar.isDate(evaluatedAt, inSameDayAs: now) {
                continue
            }

            let current = cache.strength(for: task, on: now, weekStartDay: weekStartDay).stage

            // A nil baseline means this habit has never been evaluated. The upgrade
            // backfill should have set one; seeding silently here is the defensive
            // path for habits created outside that flow.
            if let previous = task.lastObservedStage,
               let from = origin(for: task, previous: previous, current: current) {
                transitions.append(
                    Transition(
                        task: task,
                        from: from,
                        to: current,
                        isCelebratable: isCelebratable(
                            task: task, from: from, to: current, now: now
                        )
                    )
                )
            }

            task.lastObservedStage = current
            task.strengthEvaluatedAt = now
            didChange = true
        }

        if didChange {
            try? context.save()
        }
        return transitions
    }

    /// Records that a transition's celebration has been shown.
    ///
    /// `lastCelebratedStage` is a high-water mark and never decreases, so a habit
    /// that slips back and climbs again does not re-celebrate ground it has
    /// already covered.
    static func markCelebrated(
        _ transition: Transition,
        context: ModelContext,
        now: Date = .now
    ) {
        let task = transition.task
        if let highest = task.lastCelebratedStage {
            task.lastCelebratedStage = max(highest, transition.to)
        } else {
            task.lastCelebratedStage = transition.to
        }
        task.lastCelebratedAt = now
        try? context.save()
    }

    /// The stage a transition should be reported as coming *from*, or `nil` if there
    /// is nothing to report.
    ///
    /// Normally that is the previously observed stage. The second branch is a
    /// catch-up: if the habit advanced on an earlier pass but the celebration never
    /// actually reached the screen — the app was killed while it sat in the queue,
    /// or another celebration had the screen — then `lastObservedStage` already
    /// matches the current stage and a plain comparison would conclude nothing
    /// happened. Comparing against the celebrated high-water mark instead means the
    /// advance is re-offered until it is genuinely shown.
    private static func origin(
        for task: HabitTask,
        previous: HabitStage,
        current: HabitStage
    ) -> HabitStage? {
        if current != previous { return previous }

        let celebrated = task.lastCelebratedStage ?? .starting
        return current > celebrated ? celebrated : nil
    }

    private static func isCelebratable(
        task: HabitTask,
        from: HabitStage,
        to: HabitStage,
        now: Date
    ) -> Bool {
        guard to > from else { return false }
        guard to > (task.lastCelebratedStage ?? .starting) else { return false }
        if let celebratedAt = task.lastCelebratedAt,
           now.timeIntervalSince(celebratedAt) < celebrationCooldown {
            return false
        }
        return true
    }
}
