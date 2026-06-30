import Foundation

// MARK: - ListState

/// What a habit's circle shows right now in the task list (PRD §3 state machine).
enum ListState: String {
    /// Not rendered (specific-days habit, today not scheduled).
    case hidden
    /// Visible, no completions yet this period.
    case incomplete
    /// Some but not all completions this period (multi-completion habits only).
    case partial
    /// Quota reached for this period.
    case complete
}

// MARK: - PeriodProgress

/// Snapshot of a habit's progress within its current period.
struct PeriodProgress: Equatable {
    let periodStart: Date
    let periodEnd: Date
    /// Completions counted in the current period (`C`).
    let current: Int
    /// Target completions for the period (`N`).
    let target: Int
    /// Whether the habit is scheduled to appear today (only relevant for specific days).
    let isScheduledToday: Bool

    /// Whether a counter badge should be shown (multi-completion profiles only).
    var showsCounter: Bool { target > 1 }

    /// Current list state derived from `C`, `N` and visibility.
    var listState: ListState {
        if !isScheduledToday { return .hidden }
        if current >= target { return .complete }
        if current > 0 { return .partial }
        return .incomplete
    }

    var isComplete: Bool { current >= target }
}

// MARK: - PeriodService

/// Shared completion engine. Every UI surface (task list, manage completions,
/// stats, streaks) calls these functions — none re-implement counting (PRD §13).
enum PeriodService {

    // MARK: Effective frequency / target

    /// Maps the legacy `everyWeek` value onto `weekly` for all period math.
    static func effectiveFrequency(for task: HabitTask) -> FrequencyType {
        task.frequencyType == .everyWeek ? .weekly : task.frequencyType
    }

    /// The per-period target `N`. For specific days this is the number of
    /// scheduled weekdays; otherwise the stored `timesPerPeriod`.
    static func target(for task: HabitTask) -> Int {
        switch effectiveFrequency(for: task) {
        case .specificDays:
            return max(1, task.scheduledDays.count)
        default:
            return max(1, task.timesPerPeriod)
        }
    }

    /// Whether the engine should treat this habit as `periodComplete` for stats.
    /// Daily multi-task habits are always forced to `periodComplete` (PRD §6).
    static func effectiveTracking(for task: HabitTask) -> TrackingMode {
        if effectiveFrequency(for: task) == .daily {
            return .periodComplete
        }
        return task.tracking
    }

    // MARK: Period boundaries

    /// Start/end of the period containing `date` for the given task.
    /// The interval is half-open: `start <= completedAt < end`.
    static func periodBounds(
        for task: HabitTask,
        on date: Date,
        calendar: Calendar = .current,
        weekStartDay: Int = 1
    ) -> (start: Date, end: Date) {
        switch effectiveFrequency(for: task) {
        case .daily:
            let start = calendar.startOfDay(for: date)
            let end = calendar.date(byAdding: .day, value: 1, to: start)!
            return (start, end)

        case .weekly, .specificDays, .everyWeek:
            let start = weekStart(for: date, calendar: calendar, weekStartDay: weekStartDay)
            let end = calendar.date(byAdding: .day, value: 7, to: start)!
            return (start, end)

        case .monthly:
            let comps = calendar.dateComponents([.year, .month], from: date)
            let start = calendar.date(from: comps)!
            let end = calendar.date(byAdding: .month, value: 1, to: start)!
            return (start, end)
        }
    }

    /// Start of the week (at midnight) containing `date`, honoring `weekStartDay`
    /// (ISO 1=Mon ... 7=Sun).
    static func weekStart(
        for date: Date,
        calendar: Calendar = .current,
        weekStartDay: Int = 1
    ) -> Date {
        let dayStart = calendar.startOfDay(for: date)
        let currentWeekday = calendar.isoWeekday(for: dayStart)
        let daysSinceWeekStart = (currentWeekday - weekStartDay + 7) % 7
        return calendar.date(byAdding: .day, value: -daysSinceWeekStart, to: dayStart)!
    }

    // MARK: Progress

    /// Number of completions for `task` inside the period containing `date`.
    static func completionCount(
        for task: HabitTask,
        on date: Date,
        calendar: Calendar = .current,
        weekStartDay: Int = 1
    ) -> Int {
        let bounds = periodBounds(for: task, on: date, calendar: calendar, weekStartDay: weekStartDay)
        return task.completions.filter {
            $0.completedAt >= bounds.start && $0.completedAt < bounds.end
        }.count
    }

    /// Full progress snapshot for the current period.
    static func periodProgress(
        for task: HabitTask,
        on date: Date = .now,
        calendar: Calendar = .current,
        weekStartDay: Int = 1
    ) -> PeriodProgress {
        let bounds = periodBounds(for: task, on: date, calendar: calendar, weekStartDay: weekStartDay)
        let current = completionCount(for: task, on: date, calendar: calendar, weekStartDay: weekStartDay)
        let weekday = calendar.isoWeekday(for: date)
        let scheduledToday = task.isScheduled(forWeekday: weekday)
        return PeriodProgress(
            periodStart: bounds.start,
            periodEnd: bounds.end,
            current: current,
            target: target(for: task),
            isScheduledToday: scheduledToday
        )
    }

    /// Whether a new completion may be recorded from the task list.
    /// Blocked when the period is already complete or the habit is hidden today
    /// (over-completion rule — the task list caps at `N`, PRD §3/§4).
    static func canAcceptCompletion(
        for task: HabitTask,
        on date: Date = .now,
        calendar: Calendar = .current,
        weekStartDay: Int = 1
    ) -> Bool {
        let progress = periodProgress(for: task, on: date, calendar: calendar, weekStartDay: weekStartDay)
        switch progress.listState {
        case .hidden, .complete:
            return false
        case .incomplete, .partial:
            return true
        }
    }

    // MARK: Stats credit

    /// Stat credit for a single period given its raw completion count.
    /// - `eachCompletion`: every raw completion counts (including beyond `N`).
    /// - `periodComplete` (and all daily habits): 1 if the quota is reached, else 0.
    static func statCredits(
        for task: HabitTask,
        rawCount: Int
    ) -> Int {
        let n = target(for: task)
        switch effectiveTracking(for: task) {
        case .eachCompletion:
            return rawCount
        case .periodComplete:
            return rawCount >= n ? 1 : 0
        }
    }

    // MARK: Streaks

    /// Period-based current streak (PRD "Streak logic").
    ///
    /// Walks backwards period by period from the period containing `date`:
    /// - `periodComplete` / daily: each fully-completed period adds 1; the current
    ///   period is graced (an incomplete current period neither adds nor breaks).
    /// - `eachCompletion`: each completion in an active period adds 1; a past period
    ///   with zero completions breaks the run.
    static func currentStreak(
        for task: HabitTask,
        on date: Date = .now,
        calendar: Calendar = .current,
        weekStartDay: Int = 1
    ) -> Int {
        let n = target(for: task)
        let tracking = effectiveTracking(for: task)
        let currentBounds = periodBounds(for: task, on: date, calendar: calendar, weekStartDay: weekStartDay)

        var streak = 0
        var periodStart = currentBounds.start
        var isCurrentPeriod = true

        // Guard against runaway loops (e.g. empty histories) — cap the look-back.
        var iterations = 0
        let maxIterations = 1200

        while iterations < maxIterations {
            iterations += 1
            let bounds = periodBounds(for: task, on: periodStart, calendar: calendar, weekStartDay: weekStartDay)
            let count = task.completions.filter {
                $0.completedAt >= bounds.start && $0.completedAt < bounds.end
            }.count

            switch tracking {
            case .periodComplete:
                if count >= n {
                    streak += 1
                } else if isCurrentPeriod {
                    // Grace: current period may still be completed.
                } else {
                    return streak
                }
            case .eachCompletion:
                if count > 0 {
                    streak += count
                } else if isCurrentPeriod {
                    // Grace for the in-progress period.
                } else {
                    return streak
                }
            }

            // Step to the previous period.
            let previousDate = calendar.date(byAdding: .day, value: -1, to: bounds.start)!
            periodStart = periodBounds(for: task, on: previousDate, calendar: calendar, weekStartDay: weekStartDay).start
            isCurrentPeriod = false
        }

        return streak
    }
}
