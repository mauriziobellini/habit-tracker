import Foundation

// MARK: - MeasurementDuration

/// The time period over which a task's goal is evaluated.
enum MeasurementDuration: String, Codable, CaseIterable, Identifiable {
    case daily   = "daily"
    case weekly  = "weekly"
    case monthly = "monthly"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .daily:   return NSLocalizedString("Daily", comment: "")
        case .weekly:  return NSLocalizedString("Weekly", comment: "")
        case .monthly: return NSLocalizedString("Monthly", comment: "")
        }
    }
}

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
enum FrequencyType: String, Codable, CaseIterable, Identifiable {
    case daily        = "daily"
    case specificDays = "specificDays"
    case everyWeek    = "everyWeek"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .daily:        return NSLocalizedString("Every Day", comment: "")
        case .specificDays: return NSLocalizedString("Specific Days", comment: "")
        case .everyWeek:    return NSLocalizedString("Every Week", comment: "")
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
