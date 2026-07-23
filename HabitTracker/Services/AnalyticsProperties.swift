import Foundation

/// Builders for the structural, non-identifying analytics properties described in the
/// Measurement PRD §9. These deliberately never include habit titles, reward text,
/// category names, notification copy, or any user-typed string.
enum AnalyticsBucket {
    /// `times_per_period` intensity bucket: "1" / "2" / "3" / "4_plus".
    static func timesPerPeriod(_ value: Int) -> String {
        switch value {
        case ..<2: return "1"
        case 2: return "2"
        case 3: return "3"
        default: return "4_plus"
        }
    }

    /// Habit-count bucket: "0" / "1" / "2" / "3_plus".
    /// Used for `habit_count_before` (add tap) and `habit_count_after` (create).
    static func habitCount(_ value: Int) -> String {
        switch value {
        case ..<1: return "0"
        case 1: return "1"
        case 2: return "2"
        default: return "3_plus"
        }
    }

    /// Streak bucket for `reward_unlocked`: "2" / "3_5" / "6_10" / "11_plus".
    static func streak(_ value: Int) -> String {
        switch value {
        case ..<3: return "2"
        case 3...5: return "3_5"
        case 6...10: return "6_10"
        default: return "11_plus"
        }
    }
}

extension FrequencyType {
    /// Frequency value for analytics, mapping the legacy `everyWeek` case to `weekly`
    /// so PostHog breakdowns only ever see the selectable frequencies (PRD §9).
    var analyticsValue: String {
        self == .everyWeek ? FrequencyType.weekly.rawValue : rawValue
    }
}

extension HabitTask {
    /// Structural habit-shape properties reused across `habit_created`, `habit_completed`,
    /// and `habit_edited` so PostHog breakdowns stay consistent (PRD §9). Contains no PII
    /// and no free-text habit content.
    var analyticsStructuralProperties: [String: String] {
        [
            "frequency": frequencyType.analyticsValue,
            "tracking": tracking.rawValue,
            "goal_type": goalType.rawValue,
            "times_per_period": AnalyticsBucket.timesPerPeriod(timesPerPeriod),
            "has_notification": String(notificationEnabled),
            "has_reward": String(rewardEnabled),
            "is_preset": String(isPreset),
        ]
    }
}
