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
