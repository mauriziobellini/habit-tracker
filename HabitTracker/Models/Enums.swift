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
        case .daily:   return String(localized: "Daily")
        case .weekly:  return String(localized: "Weekly")
        case .monthly: return String(localized: "Monthly")
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
        case .none:        return String(localized: "No Goal")
        case .repetitions: return String(localized: "Repetitions")
        case .time:        return String(localized: "Time")
        case .cups:        return String(localized: "Cups")
        case .calories:    return String(localized: "Calories")
        case .distance:    return String(localized: "Distance")
        case .weight:      return String(localized: "Weight")
        case .capacity:    return String(localized: "Capacity")
        }
    }

    /// Default unit options for this goal type.
    var defaultUnits: [String] {
        switch self {
        case .none:        return []
        case .repetitions: return ["times"]
        case .time:        return ["sec", "min", "hr"]
        case .cups:        return ["cups"]
        case .calories:    return ["kcal"]
        case .distance:    return ["m", "km", "mi"]
        case .weight:      return ["g", "kg", "lb"]
        case .capacity:    return ["mL", "L"]
        }
    }

    /// The primary default unit for this goal type.
    var primaryUnit: String? {
        defaultUnits.first
    }
}

// MARK: - FrequencyType

/// How often the task recurs.
enum FrequencyType: String, Codable, CaseIterable, Identifiable {
    case daily        = "daily"
    case specificDays = "specificDays"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .daily:        return String(localized: "Every Day")
        case .specificDays: return String(localized: "Specific Days")
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
        case .monday:    return String(localized: "Mon")
        case .tuesday:   return String(localized: "Tue")
        case .wednesday: return String(localized: "Wed")
        case .thursday:  return String(localized: "Thu")
        case .friday:    return String(localized: "Fri")
        case .saturday:  return String(localized: "Sat")
        case .sunday:    return String(localized: "Sun")
        }
    }

    var fullName: String {
        switch self {
        case .monday:    return String(localized: "Monday")
        case .tuesday:   return String(localized: "Tuesday")
        case .wednesday: return String(localized: "Wednesday")
        case .thursday:  return String(localized: "Thursday")
        case .friday:    return String(localized: "Friday")
        case .saturday:  return String(localized: "Saturday")
        case .sunday:    return String(localized: "Sunday")
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
        case .metric:   return String(localized: "Metric (km, kg, L)")
        case .us:       return String(localized: "US Customary (mi, lb, fl oz)")
        case .imperial: return String(localized: "Imperial (mi, st, pt)")
        }
    }
}
