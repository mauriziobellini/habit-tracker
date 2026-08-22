import Foundation
import SwiftData

@Model
final class HabitTask {
    var id: UUID
    var title: String
    var iconName: String?
    var isPreset: Bool
    var presetIdentifier: String?
    var goalType: GoalType
    var goalValue: Double?
    var goalUnit: String?
    var frequencyType: FrequencyType

    /// Target completions per period (the quota `N`). For `specificDays` the
    /// effective target is derived from `scheduledDays` (see `PeriodService`).
    /// Renamed from the legacy `timesPerDay` field; `originalName` lets SwiftData
    /// preserve existing values during lightweight migration.
    @Attribute(originalName: "timesPerDay") var timesPerPeriod: Int

    /// Backing storage for `tracking`. Stored as an optional so rows created
    /// before this feature existed (which have no value for this column) decode
    /// as `nil` instead of crashing on a force-cast of `Optional<Any>` to
    /// `TrackingMode` in the getter. Access via the non-optional `tracking`.
    private var trackingRaw: TrackingMode?

    /// Statistics crediting mode for multi-completion weekly/monthly/specific-days
    /// habits. Daily multi-task habits ignore this (always `periodComplete`).
    /// Falls back to `.eachCompletion` for legacy rows with no stored value.
    var tracking: TrackingMode {
        get { trackingRaw ?? .eachCompletion }
        set { trackingRaw = newValue }
    }

    var scheduledDays: [Int]
    var notificationEnabled: Bool
    var notificationTime: Date?
    var colorToken: String
    var sortOrder: Int
    var createdAt: Date
    var updatedAt: Date

    // Reward configuration
    var rewardEnabled: Bool
    var rewardStreakCount: Int
    var rewardText: String?

    // MARK: Habit strength bookkeeping

    // The Habit Strength score and stage are *derived* from completions and are
    // never stored — storing them would leave stale values behind whenever past
    // completions are edited in `ManageCompletionsView`. The fields below persist
    // only what is needed to detect change over time.
    //
    // Both enum-typed fields use the same optional-backing pattern as
    // `trackingRaw` above: a non-optional stored enum crashes on a force-cast of
    // `Optional<Any>` for rows created before the column existed.

    /// Backing storage for `lastObservedStage`.
    private var lastObservedStageRaw: HabitStage?

    /// Backing storage for `lastCelebratedStage`.
    private var lastCelebratedStageRaw: HabitStage?

    /// Stage at the last daily evaluation — the baseline for telling an advance
    /// from a reversion. Stays optional at the accessor level too: `nil` means
    /// "never evaluated", which is meaningfully different from `.starting`.
    var lastObservedStage: HabitStage? {
        get { lastObservedStageRaw }
        set { lastObservedStageRaw = newValue }
    }

    /// Highest stage already celebrated. A high-water mark that never decreases,
    /// so a score oscillating across a boundary cannot re-trigger the pop-up.
    var lastCelebratedStage: HabitStage? {
        get { lastCelebratedStageRaw }
        set { lastCelebratedStageRaw = newValue }
    }

    /// Cooldown guard against repeated celebrations.
    var lastCelebratedAt: Date?

    /// Last daily evaluation timestamp — makes the evaluator idempotent per day.
    var strengthEvaluatedAt: Date?

    var category: Category?

    @Relationship(deleteRule: .cascade, inverse: \TaskCompletion.task)
    var completions: [TaskCompletion] = []

    init(
        id: UUID = UUID(),
        title: String,
        iconName: String? = nil,
        isPreset: Bool = false,
        presetIdentifier: String? = nil,
        goalType: GoalType = .none,
        goalValue: Double? = nil,
        goalUnit: String? = nil,
        frequencyType: FrequencyType = .daily,
        timesPerPeriod: Int = 1,
        tracking: TrackingMode = .eachCompletion,
        scheduledDays: [Int] = [1, 2, 3, 4, 5, 6, 7],
        notificationEnabled: Bool = false,
        notificationTime: Date? = nil,
        colorToken: String = "blue",
        sortOrder: Int = 0,
        rewardEnabled: Bool = false,
        rewardStreakCount: Int = 2,
        rewardText: String? = nil,
        category: Category? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.iconName = iconName
        self.isPreset = isPreset
        self.presetIdentifier = presetIdentifier
        self.goalType = goalType
        self.goalValue = goalValue
        self.goalUnit = goalUnit
        self.frequencyType = frequencyType
        self.timesPerPeriod = timesPerPeriod
        self.trackingRaw = tracking
        self.scheduledDays = scheduledDays
        self.notificationEnabled = notificationEnabled
        self.notificationTime = notificationTime
        self.colorToken = colorToken
        self.sortOrder = sortOrder
        self.rewardEnabled = rewardEnabled
        self.rewardStreakCount = rewardStreakCount
        self.rewardText = rewardText
        self.category = category
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        // Not exposed as init parameters: a freshly created habit has never been
        // evaluated, and every call site would otherwise have to pass nil.
        self.lastObservedStageRaw = nil
        self.lastCelebratedStageRaw = nil
        self.lastCelebratedAt = nil
        self.strengthEvaluatedAt = nil
    }
}

// MARK: - Computed Properties

extension HabitTask {
    /// Returns the display text when no icon is set: first two initials of the title.
    var initialsDisplay: String {
        let words = title.split(separator: " ")
        if words.count >= 2 {
            return String(words[0].prefix(1) + words[1].prefix(1)).uppercased()
        }
        return String(title.prefix(2)).uppercased()
    }

    /// Whether this task is scheduled for a given weekday (1=Monday ... 7=Sunday).
    func isScheduled(forWeekday weekday: Int) -> Bool {
        switch frequencyType {
        case .daily, .weekly, .monthly, .everyWeek:
            return true // weekly/monthly are visible every day; tracked per period
        case .specificDays:
            return scheduledDays.contains(weekday)
        }
    }

    /// Returns completions for a specific calendar day.
    func completions(on date: Date, calendar: Calendar = .current) -> [TaskCompletion] {
        completions.filter { calendar.isDate($0.completedAt, inSameDayAs: date) }
    }

    /// Start of the day from which this habit has tracked history.
    ///
    /// Usually `createdAt`, but `ManageCompletionsView` accepts *any* past day, so a
    /// habit can hold completions from before it was created. Bounding history at
    /// `createdAt` would hide those rows from the counting engine — a habit could be
    /// backfilled well past the strength eligibility threshold and still report
    /// having no completions at all.
    func historyStart(calendar: Calendar = .current) -> Date {
        let created = calendar.startOfDay(for: createdAt)
        guard let earliest = completions.map(\.completedAt).min() else { return created }
        return min(created, calendar.startOfDay(for: earliest))
    }

    /// Whether the task's per-day quota is reached on a given date.
    /// Only meaningful for daily habits; for weekly/monthly use `PeriodService`.
    func isCompleted(on date: Date, calendar: Calendar = .current) -> Bool {
        completions(on: date, calendar: calendar).count >= timesPerPeriod
    }

    /// Current streak under the period-based rules (PRD "Streak logic").
    /// Delegates to the shared completion engine so every surface agrees.
    func currentStreak(calendar: Calendar = .current, weekStartDay: Int = 1) -> Int {
        PeriodService.currentStreak(
            for: self,
            on: .now,
            calendar: calendar,
            weekStartDay: weekStartDay
        )
    }
}

// MARK: - Calendar Helper

extension Calendar {
    /// Returns ISO 8601 weekday: 1=Monday ... 7=Sunday.
    func isoWeekday(for date: Date) -> Int {
        let weekday = component(.weekday, from: date) // 1=Sun, 2=Mon ... 7=Sat
        return weekday == 1 ? 7 : weekday - 1
    }
}
