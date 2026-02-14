import Foundation
import SwiftData

@Model
final class HabitTask {
    var id: UUID
    var title: String
    var iconName: String?
    var isPreset: Bool
    var presetIdentifier: String?
    var measurementDuration: MeasurementDuration
    var goalType: GoalType
    var goalValue: Double?
    var goalUnit: String?
    var frequencyType: FrequencyType
    var timesPerDay: Int
    var scheduledDays: [Int]
    var notificationEnabled: Bool
    var notificationTime: Date?
    var colorToken: String
    var sortOrder: Int
    var createdAt: Date
    var updatedAt: Date

    var category: Category?

    @Relationship(deleteRule: .cascade, inverse: \TaskCompletion.task)
    var completions: [TaskCompletion] = []

    init(
        id: UUID = UUID(),
        title: String,
        iconName: String? = nil,
        isPreset: Bool = false,
        presetIdentifier: String? = nil,
        measurementDuration: MeasurementDuration = .daily,
        goalType: GoalType = .none,
        goalValue: Double? = nil,
        goalUnit: String? = nil,
        frequencyType: FrequencyType = .daily,
        timesPerDay: Int = 1,
        scheduledDays: [Int] = [1, 2, 3, 4, 5, 6, 7],
        notificationEnabled: Bool = false,
        notificationTime: Date? = nil,
        colorToken: String = "blue",
        sortOrder: Int = 0,
        category: Category? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.iconName = iconName
        self.isPreset = isPreset
        self.presetIdentifier = presetIdentifier
        self.measurementDuration = measurementDuration
        self.goalType = goalType
        self.goalValue = goalValue
        self.goalUnit = goalUnit
        self.frequencyType = frequencyType
        self.timesPerDay = timesPerDay
        self.scheduledDays = scheduledDays
        self.notificationEnabled = notificationEnabled
        self.notificationTime = notificationTime
        self.colorToken = colorToken
        self.sortOrder = sortOrder
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
        case .daily:
            return true
        case .specificDays:
            return scheduledDays.contains(weekday)
        }
    }

    /// Returns completions for a specific calendar day.
    func completions(on date: Date, calendar: Calendar = .current) -> [TaskCompletion] {
        completions.filter { calendar.isDate($0.completedAt, inSameDayAs: date) }
    }

    /// Whether the task is completed for a given date based on `timesPerDay`.
    func isCompleted(on date: Date, calendar: Calendar = .current) -> Bool {
        completions(on: date, calendar: calendar).count >= timesPerDay
    }

    /// Current streak: consecutive completed periods counting backwards from today.
    func currentStreak(calendar: Calendar = .current) -> Int {
        let today = calendar.startOfDay(for: .now)
        var streak = 0
        var checkDate = today

        while true {
            let dayCompletions = completions(on: checkDate, calendar: calendar)
            let weekday = calendar.isoWeekday(for: checkDate)

            if !isScheduled(forWeekday: weekday) {
                // Skip unscheduled days — don't break the streak
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
                continue
            }

            if dayCompletions.count >= timesPerDay {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else if calendar.isDateInToday(checkDate) {
                // Today is allowed to be incomplete without breaking streak
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else {
                break
            }
        }

        return streak
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
