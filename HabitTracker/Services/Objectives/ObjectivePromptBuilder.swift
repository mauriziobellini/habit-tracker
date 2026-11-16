import Foundation

/// Model instructions and prompt fragments, localized in `ObjectivePrompts.strings` and
/// versioned with the app (PRD - objectives §10.3). Resolved through `Bundle.main`, so
/// the in-app language override applies.
enum ObjectivePromptStrings {
    static let table = "ObjectivePrompts"

    static let keys = [
        "policing.instructions",
        "research.instructions",
        "prompt.objective",
        "prompt.refinement",
        "prompt.refine",
        "prompt.more",
        "prompt.exclude",
        "prompt.units",
        "evaluator.blocklist",
    ]

    static func localized(_ key: String) -> String {
        Bundle.main.localizedString(forKey: key, value: nil, table: table)
    }

    static func englishBlocklist() -> [String] {
        guard let path = Bundle.main.path(forResource: table, ofType: "strings", inDirectory: "en.lproj"),
              let contents = NSDictionary(contentsOfFile: path) as? [String: String],
              let list = contents["evaluator.blocklist"]
        else { return [] }
        return splitList(list)
    }

    /// The current language's blocklist plus the English one, since users mix languages.
    static func blocklist() -> [String] {
        Array(Set(splitList(localized("evaluator.blocklist")) + englishBlocklist()))
    }

    static func splitList(_ list: String) -> [String] {
        list.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && $0 != "evaluator.blocklist" }
    }
}

/// Builds the user prompts for the policing and research steps. Refine, Generate more and
/// retries each run in a fresh session seeded with everything they need: the objective,
/// all refinements and the titles already proposed.
struct ObjectivePromptBuilder {
    static let maxInputLength = 200
    static let maxTitlesInPrompt = 20
    static let maxTitlesInCompactPrompt = 10
    static let maxRefinementsInCompactPrompt = 2

    var localized: (String) -> String = ObjectivePromptStrings.localized

    func policingPrompt(for request: ObjectiveRequest) -> String {
        var lines = [format("prompt.objective", Self.clip(request.objective))]
        lines += request.refinements.map { format("prompt.refinement", Self.clip($0)) }
        return lines.joined(separator: "\n")
    }

    /// - Parameters:
    ///   - excluding: titles the model must not propose again.
    ///   - asksForDifferentHabits: set for Generate more and for the evaluator retry.
    ///   - compact: shorter seed used after the context window overflowed.
    func researchPrompt(
        for request: ObjectiveRequest,
        excluding titles: [String],
        asksForDifferentHabits: Bool = false,
        compact: Bool = false
    ) -> String {
        var lines = [format("prompt.objective", Self.clip(request.objective))]

        let refinements = compact
            ? Array(request.refinements.suffix(Self.maxRefinementsInCompactPrompt))
            : request.refinements
        lines += refinements.map { format("prompt.refinement", Self.clip($0)) }

        if request.mode == .refine {
            lines.append(localized("prompt.refine"))
        }
        if request.mode == .more || asksForDifferentHabits {
            lines.append(localized("prompt.more"))
        }

        let cap = compact ? Self.maxTitlesInCompactPrompt : Self.maxTitlesInPrompt
        let recentTitles = titles.suffix(cap)
        if !recentTitles.isEmpty {
            lines.append(format("prompt.exclude", recentTitles.joined(separator: ", ")))
        }

        lines.append(format("prompt.units", Self.unitsDescription(for: request.measurementSystem)))
        return lines.joined(separator: "\n")
    }

    static func clip(_ text: String) -> String {
        String(text.trimmingCharacters(in: .whitespacesAndNewlines).prefix(maxInputLength))
    }

    /// Tells the model which unit each goal amount is expressed in, so the number it
    /// returns matches the unit the app attaches (see `ObjectiveUnitPolicy`).
    static func unitsDescription(for system: MeasurementSystem) -> String {
        GoalType.allCases
            .filter { $0 != .none }
            .compactMap { type in
                ObjectiveUnitPolicy.unit(for: type, system: system).map { "\(type.rawValue) = \($0)" }
            }
            .joined(separator: ", ")
    }

    private func format(_ key: String, _ argument: String) -> String {
        String(format: localized(key), argument)
    }
}
