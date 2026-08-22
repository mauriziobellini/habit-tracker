import Foundation

/// Computes the Habit Strength score and stage (PRD - Habit strength §7).
///
/// `HS = 100 * (0.55R + 0.45C)` where `R = 1 - e^(-N/40)` and `C` is recent
/// consistency. The scaling factor of 40 puts a habit near 80 at 60 repetitions,
/// approximating Lally's median of ~66 days to reach high automaticity.
///
/// Counting is delegated entirely to `StatisticsService` / `PeriodService` so this
/// service agrees with streaks and the stats screen for every frequency and
/// tracking mode.
enum HabitStrengthService {

    /// Repetitions at which `R` reaches ~63%. See the type doc for the rationale.
    private static let repetitionScale = 40.0

    /// Minimum credited completions before a score is shown (PRD §8).
    static let eligibilityThreshold = 3

    /// Shortest consistency window, in days.
    private static let minimumWindowDays = 28

    /// Minimum number of periods in the consistency window. A 28-day window holds
    /// only one or two monthly periods, which collapses `C` to a near-binary
    /// 0 / 0.5 / 1 and makes the score jump around; widening to three periods
    /// gives monthly habits roughly a 90-day window (PRD §10.7c).
    private static let minimumWindowPeriods = 3

    // MARK: - Public API

    /// Current strength for `task` as of `date`.
    static func strength(
        for task: HabitTask,
        on date: Date = .now,
        calendar: Calendar = .current,
        weekStartDay: Int = 1
    ) -> HabitStrength {
        strength(from: terms(for: task, on: date, calendar: calendar, weekStartDay: weekStartDay))
    }

    /// Strength as it *would* be if the user completed `task` on `date`.
    ///
    /// Pure: nothing is inserted into the model context. The extra completion is
    /// applied as an analytic credit delta rather than by synthesising rows, so
    /// the counting engine stays the single source of truth.
    static func projectedStrength(
        for task: HabitTask,
        assumingCompletionOn date: Date,
        calendar: Calendar = .current,
        weekStartDay: Int = 1
    ) -> HabitStrength {
        var projected = terms(for: task, on: date, calendar: calendar, weekStartDay: weekStartDay)

        // A period already at quota (or a habit not scheduled today) cannot accept
        // another completion from the task list, so the projection is a no-op.
        guard PeriodService.canAcceptCompletion(
            for: task, on: date, calendar: calendar, weekStartDay: weekStartDay
        ) else {
            return strength(from: projected)
        }

        let credit = creditForOneMoreCompletion(
            for: task, on: date, calendar: calendar, weekStartDay: weekStartDay
        )
        projected.totalCompletions += credit
        // The window ends on `date`, so the same credit lands in the numerator.
        projected.windowCompletions += credit
        return strength(from: projected)
    }

    /// Strength as it would be if `date` passed without a completion.
    ///
    /// A miss creates no rows, so this is simply the strength evaluated on `date`:
    /// that day's opportunity is counted in the consistency denominator while the
    /// numerator stays put. Kept as a named entry point so the notification
    /// scheduler reads as the two symmetrical cases it is testing.
    static func projectedStrengthAssumingMiss(
        for task: HabitTask,
        on date: Date,
        calendar: Calendar = .current,
        weekStartDay: Int = 1
    ) -> HabitStrength {
        strength(for: task, on: date, calendar: calendar, weekStartDay: weekStartDay)
    }

    /// The window over which recent consistency `C` is measured: at least 28 days,
    /// widened to cover at least three of the habit's periods, and never reaching
    /// back before the habit's history begins.
    ///
    /// That clamp matters — without it a five-day-old daily habit would be judged
    /// against 28 opportunities, 23 of which never existed, and could never climb
    /// out of Starting.
    static func consistencyWindow(
        for task: HabitTask,
        endingOn date: Date,
        calendar: Calendar = .current,
        weekStartDay: Int = 1
    ) -> (start: Date, end: Date) {
        let dayStart = calendar.startOfDay(for: date)
        let end = endOfDay(for: date, calendar: calendar)

        let byDays = calendar.date(
            byAdding: .day, value: -(minimumWindowDays - 1), to: dayStart
        ) ?? dayStart

        var byPeriods = PeriodService.periodBounds(
            for: task, on: dayStart, calendar: calendar, weekStartDay: weekStartDay
        ).start
        for _ in 1..<minimumWindowPeriods {
            let previousDay = calendar.date(byAdding: .day, value: -1, to: byPeriods) ?? byPeriods
            byPeriods = PeriodService.periodBounds(
                for: task, on: previousDay, calendar: calendar, weekStartDay: weekStartDay
            ).start
        }

        let widest = min(byDays, byPeriods)
        let start = max(widest, task.historyStart(calendar: calendar))
        // A habit created later today would otherwise produce an inverted window.
        return (min(start, end), end)
    }

    // MARK: - Formula

    /// The three counting terms the formula needs. Isolated so the current value
    /// and both projections share one implementation of the arithmetic and cannot
    /// drift apart.
    private struct Terms {
        var totalCompletions: Int
        var windowCompletions: Int
        var windowExpected: Int
    }

    private static func terms(
        for task: HabitTask,
        on date: Date,
        calendar: Calendar,
        weekStartDay: Int
    ) -> Terms {
        let end = endOfDay(for: date, calendar: calendar)

        // N counts credited completions, not raw rows, so a daily habit with a
        // quota of 3 earns one repetition per day rather than reaching automaticity
        // three times faster than a once-a-day habit (PRD §10.7a).
        let total = StatisticsService.completionCount(
            for: task,
            from: task.historyStart(calendar: calendar),
            to: end,
            weekStartDay: weekStartDay,
            calendar: calendar
        )

        let window = consistencyWindow(
            for: task, endingOn: date, calendar: calendar, weekStartDay: weekStartDay
        )

        return Terms(
            totalCompletions: total,
            windowCompletions: StatisticsService.completionCount(
                for: task, from: window.start, to: window.end,
                weekStartDay: weekStartDay, calendar: calendar
            ),
            windowExpected: StatisticsService.expectedCompletions(
                for: task, from: window.start, to: window.end,
                weekStartDay: weekStartDay, calendar: calendar
            )
        )
    }

    private static func strength(from terms: Terms) -> HabitStrength {
        let n = max(0, terms.totalCompletions)
        let repetition = 1 - exp(-Double(n) / repetitionScale)

        let consistency: Double
        if terms.windowExpected > 0 {
            // Capped at 1: backfilled completions can exceed the period quota.
            consistency = min(1.0, Double(terms.windowCompletions) / Double(terms.windowExpected))
        } else {
            consistency = 0
        }

        let raw = 100 * (0.55 * repetition + 0.45 * consistency)
        let score = min(100, max(0, Int(raw.rounded(.toNearestOrAwayFromZero))))
        let isEligible = n >= eligibilityThreshold

        return HabitStrength(
            score: score,
            // Below the eligibility threshold the habit stays in Starting whatever
            // the arithmetic says, so the stage never contradicts a hidden score.
            stage: isEligible ? HabitStage.stage(forScore: score) : .starting,
            repetition: repetition,
            consistency: consistency,
            totalCompletions: n,
            isEligible: isEligible
        )
    }

    // MARK: - Helpers

    /// Credit that one further completion on `date` would earn, under the task's
    /// effective tracking mode.
    private static func creditForOneMoreCompletion(
        for task: HabitTask,
        on date: Date,
        calendar: Calendar,
        weekStartDay: Int
    ) -> Int {
        switch PeriodService.effectiveTracking(for: task) {
        case .eachCompletion:
            return 1
        case .periodComplete:
            let raw = PeriodService.completionCount(
                for: task, on: date, calendar: calendar, weekStartDay: weekStartDay
            )
            return (raw + 1) >= PeriodService.target(for: task) ? 1 : 0
        }
    }

    /// Last instant of `date`'s calendar day. `StatisticsService` treats range ends
    /// inclusively, so a plain `startOfDay` would drop the same day's completions.
    private static func endOfDay(for date: Date, calendar: Calendar) -> Date {
        let start = calendar.startOfDay(for: date)
        let next = calendar.date(byAdding: .day, value: 1, to: start) ?? start
        return next.addingTimeInterval(-1)
    }
}
