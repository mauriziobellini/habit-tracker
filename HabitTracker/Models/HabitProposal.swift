import Foundation

/// A habit suggested from an objective. Lives only in memory while the objectives
/// configurator is open; nothing is persisted until the user saves it in the task
/// configurator (PRD - objectives §8.3).
struct HabitProposal: Identifiable, Equatable {
    let id: UUID
    var title: String
    var summary: String
    /// Only `.daily`, `.weekly` or `.monthly` — the model never proposes specific days.
    var frequency: FrequencyType
    var timesPerPeriod: Int
    var goalType: GoalType
    var goalValue: Double?
    var iconName: String
    var isAdded: Bool = false

    init(
        id: UUID = UUID(),
        title: String,
        summary: String,
        frequency: FrequencyType,
        timesPerPeriod: Int,
        goalType: GoalType,
        goalValue: Double?,
        iconName: String,
        isAdded: Bool = false
    ) {
        self.id = id
        self.title = title
        self.summary = summary
        self.frequency = frequency
        self.timesPerPeriod = timesPerPeriod
        self.goalType = goalType
        self.goalValue = goalValue
        self.iconName = iconName
        self.isAdded = isAdded
    }

    static let suggestedFrequencies: [FrequencyType] = [.daily, .weekly, .monthly]

    static let fallbackIconName = "star.fill"

    /// The icons the model may pick from. Kept short because every case is part of the
    /// generation schema, which counts against the on-device model's 4,096-token context.
    static let allowedIconNames: [String] = [
        "figure.walk", "figure.run", "bicycle", "dumbbell.fill", "figure.yoga",
        "brain.head.profile", "heart.fill", "bed.double.fill", "sun.max.fill", "moon.fill",
        "drop.fill", "fork.knife", "leaf.fill", "book.fill", "character.book.closed.fill",
        "graduationcap.fill", "pencil.and.outline", "pianokeys", "guitars.fill", "music.note",
        "paintbrush.fill", "phone.fill", "person.2.fill", "hand.wave.fill", "house.fill",
        "briefcase.fill", "clock.fill", "lightbulb.fill", "star.fill",
    ]

    /// Frequency, times and goal as one line, built from structured fields rather than
    /// model text, e.g. "Weekly · 3 times · 30 min".
    func configSummary(measurementSystem: MeasurementSystem) -> String {
        var parts = [frequency.displayName]
        if timesPerPeriod > 1 {
            parts.append(String(format: NSLocalizedString("%lld times", comment: ""), timesPerPeriod))
        }
        if goalType != .none, let value = goalValue,
           let unit = ObjectiveUnitPolicy.unit(for: goalType, system: measurementSystem) {
            parts.append("\(Self.format(value)) \(unit)")
        }
        return parts.joined(separator: " · ")
    }

    private static func format(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(value))
            : value.formatted(.number.precision(.fractionLength(0...1)))
    }
}

/// Picks the unit for a suggested goal. The model only produces a number; the unit comes
/// from here so it always matches the user's measurement system, and the instructions tell
/// the model which unit each number is expressed in.
enum ObjectiveUnitPolicy {
    static func unit(for goalType: GoalType, system: MeasurementSystem) -> String? {
        switch goalType {
        case .none:        return nil
        case .repetitions: return "times"
        case .time:        return "min"
        case .cups:        return "cups"
        case .calories:    return "kcal"
        case .distance:    return system == .metric ? "km" : "mi"
        case .weight:      return system == .metric ? "kg" : "lb"
        case .capacity:    return system == .metric ? "L" : "fl oz"
        }
    }
}

/// Where a new habit came from, reported as `habit_created.source`.
enum HabitCreationSource: String {
    case manual
    case preset
    case objective
}
