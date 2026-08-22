import Foundation

// MARK: - GoalType

/// What the user is measuring for this task.
enum GoalType: String, Codable, CaseIterable, Identifiable {
    case none        = "none"
    case repetitions = "repetitions"
    case time        = "time"
    case cups        = "cups"
    case calories    = "calories"
    case distance    = "distance"
    case weight      = "weight"
    case capacity    = "capacity"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .none:        return NSLocalizedString("No Goal", comment: "")
        case .repetitions: return NSLocalizedString("Repetitions", comment: "")
        case .time:        return NSLocalizedString("Time", comment: "")
        case .cups:        return NSLocalizedString("Cups", comment: "")
        case .calories:    return NSLocalizedString("Calories", comment: "")
        case .distance:    return NSLocalizedString("Distance", comment: "")
        case .weight:      return NSLocalizedString("Weight", comment: "")
        case .capacity:    return NSLocalizedString("Capacity", comment: "")
        }
    }

    /// Default unit options for this goal type (system-agnostic fallback).
    var defaultUnits: [String] {
        units(for: .metric)
    }

    /// Unit options for this goal type according to the selected measurement system.
    func units(for system: MeasurementSystem) -> [String] {
        switch self {
        case .none:        return []
        case .repetitions: return ["times"]
        case .time:        return ["sec", "min", "hr"]
        case .cups:        return ["cups"]
        case .calories:    return ["kcal"]
        case .distance:
            switch system {
            case .metric:   return ["m", "km"]
            case .us:       return ["ft", "mi"]
            case .imperial: return ["ft", "mi"]
            }
        case .weight:
            switch system {
            case .metric:   return ["g", "kg"]
            case .us:       return ["oz", "lb"]
            case .imperial: return ["oz", "st", "lb"]
            }
        case .capacity:
            switch system {
            case .metric:   return ["mL", "L"]
            case .us:       return ["fl oz", "gal"]
            case .imperial: return ["fl oz", "pt"]
            }
        }
    }

    /// The primary default unit for this goal type.
    var primaryUnit: String? {
        defaultUnits.first
    }

    /// The primary unit for a given measurement system.
    func primaryUnit(for system: MeasurementSystem) -> String? {
        units(for: system).first
    }
}

// MARK: - FrequencyType

/// How often the task recurs.
///
/// `everyWeek` is a **legacy** case retained only so existing stored records
/// (created before the weekly/monthly counter feature) can still be decoded.
/// `MigrationService` rewrites those rows to `.weekly` at launch, and the
/// configuration UI never offers it (see `selectableCases`).
enum FrequencyType: String, Codable, CaseIterable, Identifiable {
    case daily        = "daily"
    case weekly       = "weekly"
    case monthly      = "monthly"
    case specificDays = "specificDays"
    /// Legacy value from earlier app versions — equivalent to `.weekly`.
    case everyWeek    = "everyWeek"

    var id: String { rawValue }

    /// Cases offered to the user in the configuration UI (legacy values excluded).
    static var selectableCases: [FrequencyType] {
        [.daily, .weekly, .monthly, .specificDays]
    }

    var displayName: String {
        switch self {
        case .daily:        return NSLocalizedString("Every Day", comment: "")
        case .weekly:       return NSLocalizedString("Weekly", comment: "")
        case .monthly:      return NSLocalizedString("Monthly", comment: "")
        case .specificDays: return NSLocalizedString("Specific Days", comment: "")
        case .everyWeek:    return NSLocalizedString("Weekly", comment: "")
        }
    }
}

// MARK: - TrackingMode

/// How completions are credited to statistics for multi-completion habits.
///
/// Applies to `weekly` / `monthly` / `specificDays`. Daily multi-task habits are
/// always treated as `periodComplete` and do not expose this choice (PRD §9).
enum TrackingMode: String, Codable, CaseIterable, Identifiable {
    /// Every individual completion is credited (default).
    case eachCompletion = "eachCompletion"
    /// Credit is given only when the whole period quota is reached.
    case periodComplete = "periodComplete"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .eachCompletion: return NSLocalizedString("Count every completion", comment: "")
        case .periodComplete: return NSLocalizedString("Count when period completed", comment: "")
        }
    }
}

// MARK: - Weekday

/// ISO 8601 weekday identifiers (1=Monday ... 7=Sunday).
enum Weekday: Int, Codable, CaseIterable, Identifiable {
    case monday    = 1
    case tuesday   = 2
    case wednesday = 3
    case thursday  = 4
    case friday    = 5
    case saturday  = 6
    case sunday    = 7

    var id: Int { rawValue }

    var shortName: String {
        switch self {
        case .monday:    return NSLocalizedString("Mon", comment: "")
        case .tuesday:   return NSLocalizedString("Tue", comment: "")
        case .wednesday: return NSLocalizedString("Wed", comment: "")
        case .thursday:  return NSLocalizedString("Thu", comment: "")
        case .friday:    return NSLocalizedString("Fri", comment: "")
        case .saturday:  return NSLocalizedString("Sat", comment: "")
        case .sunday:    return NSLocalizedString("Sun", comment: "")
        }
    }

    var fullName: String {
        switch self {
        case .monday:    return NSLocalizedString("Monday", comment: "")
        case .tuesday:   return NSLocalizedString("Tuesday", comment: "")
        case .wednesday: return NSLocalizedString("Wednesday", comment: "")
        case .thursday:  return NSLocalizedString("Thursday", comment: "")
        case .friday:    return NSLocalizedString("Friday", comment: "")
        case .saturday:  return NSLocalizedString("Saturday", comment: "")
        case .sunday:    return NSLocalizedString("Sunday", comment: "")
        }
    }
}

// MARK: - HabitStage

/// How far along the habit-formation path a habit is, derived from its
/// Habit Strength score (PRD - Habit strength §7).
///
/// The score is never stored — the stage is recomputed from completions on
/// demand. Only the *last observed* stage is persisted, so the daily evaluator
/// can tell an advance from a reversion.
enum HabitStage: String, Codable, CaseIterable, Identifiable, Comparable {
    case starting    = "starting"
    case developing  = "developing"
    case building    = "building"
    case strong      = "strong"
    case established = "established"
    case mastering   = "mastering"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .starting:    return NSLocalizedString("Starting", comment: "")
        case .developing:  return NSLocalizedString("Developing", comment: "")
        case .building:    return NSLocalizedString("Building", comment: "")
        case .strong:      return NSLocalizedString("Strong", comment: "")
        case .established: return NSLocalizedString("Established", comment: "")
        case .mastering:   return NSLocalizedString("Mastering", comment: "")
        }
    }

    // MARK: Ordering

    /// Position along the formation path. Declared explicitly rather than derived
    /// from `allCases.firstIndex(of:)` so comparison stays O(1) — the dashboard
    /// compares stages for every habit on every evaluation.
    private var sortIndex: Int {
        switch self {
        case .starting:    return 0
        case .developing:  return 1
        case .building:    return 2
        case .strong:      return 3
        case .established: return 4
        case .mastering:   return 5
        }
    }

    static func < (lhs: HabitStage, rhs: HabitStage) -> Bool {
        lhs.sortIndex < rhs.sortIndex
    }

    // MARK: Score mapping

    /// Maps a Habit Strength score onto a stage (PRD §7 mapping table).
    /// Scores outside `0...100` are clamped rather than rejected.
    static func stage(forScore score: Int) -> HabitStage {
        switch min(100, max(0, score)) {
        case 0...19:   return .starting
        case 20...39:  return .developing
        case 40...59:  return .building
        case 60...79:  return .strong
        case 80...94:  return .established
        default:       return .mastering
        }
    }

    // MARK: Presentation

    /// One progressive "growth path" SF Symbol family, so the stages read as a
    /// sequence even at badge size (PRD §8 iconography).
    var sfSymbolName: String {
        switch self {
        case .starting:    return "circle.dotted"
        case .developing:  return "leaf"
        case .building:    return "leaf.fill"
        case .strong:      return "flame.fill"
        case .established: return "checkmark.seal.fill"
        case .mastering:   return "crown.fill"
        }
    }

    /// From Strong upward the badge is rendered larger and tinted with the habit
    /// colour; earlier stages stay quieter (PRD §8 display rules).
    var isProminentBadge: Bool {
        self >= .strong
    }

    /// The dashboard ring badge is shown from Developing upward. The bottom sheet
    /// always shows a stage row, including Starting (PRD §8 display rules).
    var showsDashboardBadge: Bool {
        self > .starting
    }
}

// MARK: - MeasurementSystem

/// System of units for display purposes (FR-7).
enum MeasurementSystem: String, Codable, CaseIterable, Identifiable {
    case metric   = "metric"
    case us       = "us"
    case imperial = "imperial"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .metric:   return NSLocalizedString("Metric (km, kg, L)", comment: "")
        case .us:       return NSLocalizedString("US Customary (mi, lb, fl oz)", comment: "")
        case .imperial: return NSLocalizedString("Imperial (mi, st, pt)", comment: "")
        }
    }
}
