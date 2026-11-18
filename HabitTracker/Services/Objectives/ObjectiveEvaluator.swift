import Foundation

/// Fixed checks on what the user typed, run before the policing model, which a small
/// on-device model cannot be relied on to enforce. Lose or gain weight requests are
/// rejected; getting fit or in better shape is fine.
struct ObjectiveRequestScreen: Equatable {
    /// Words or phrases that reject a request on their own, e.g. "weight loss", "dimagrire".
    var blocklist: [String]
    /// A request is rejected when it contains one of these together with a weight term,
    /// e.g. "lose 5 kg" or "put on weight".
    var weightActions: [String]
    var weightTerms: [String]

    func rejects(_ text: String) -> Bool {
        // Digits are dropped so "5kg" still reads as "kg".
        let words = text.replacingOccurrences(of: "[0-9]+", with: " ", options: .regularExpression)
        if ObjectiveEvaluator.isBlocked(words, blocklist: blocklist) { return true }
        return ObjectiveEvaluator.isBlocked(words, blocklist: weightActions)
            && ObjectiveEvaluator.isBlocked(words, blocklist: weightTerms)
    }
}

/// App-side checks on every generated habit before it reaches the UI (PRD - objectives
/// §8.3 "Evaluator step"). The generation schema already constrains most values; this is
/// the safety net. Never logs titles or summaries.
enum ObjectiveEvaluator {
    enum DropReason: Equatable {
        case missingTitle
        case unsupportedFrequency
        case duplicate
        case blocked
    }

    enum Result: Equatable {
        case accepted(HabitProposal)
        case corrected(HabitProposal)
        case dropped(DropReason)

        var proposal: HabitProposal? {
            switch self {
            case .accepted(let p), .corrected(let p): return p
            case .dropped: return nil
            }
        }
    }

    static let maxTitleLength = 40
    static let maxSummaryLength = 120

    static func evaluate(
        _ input: HabitProposal,
        alreadyProposedTitles: [String],
        blocklist: [String],
        measurementSystem: MeasurementSystem = .metric
    ) -> Result {
        var proposal = input
        var corrected = false

        let title = truncate(proposal.title.trimmingCharacters(in: .whitespacesAndNewlines), to: maxTitleLength)
        guard !title.isEmpty else { return .dropped(.missingTitle) }
        if title != proposal.title { corrected = true }
        proposal.title = title

        let summary = truncate(proposal.summary.trimmingCharacters(in: .whitespacesAndNewlines), to: maxSummaryLength)
        if summary != proposal.summary { corrected = true }
        proposal.summary = summary

        guard HabitProposal.suggestedFrequencies.contains(proposal.frequency) else {
            return .dropped(.unsupportedFrequency)
        }

        let range = TaskConfigurationViewModel.timesPerPeriodRange(for: proposal.frequency)
        let times = min(max(proposal.timesPerPeriod, range.lowerBound), range.upperBound)
        if times != proposal.timesPerPeriod {
            proposal.timesPerPeriod = times
            corrected = true
        }

        if proposal.goalType == .none {
            if proposal.goalValue != nil {
                proposal.goalValue = nil
                corrected = true
            }
        } else if !hasValidGoal(proposal, system: measurementSystem) {
            proposal.goalType = .none
            proposal.goalValue = nil
            corrected = true
        }

        if !HabitProposal.allowedIconNames.contains(proposal.iconName) {
            proposal.iconName = HabitProposal.fallbackIconName
            corrected = true
        }

        let key = normalized(title)
        if alreadyProposedTitles.contains(where: { normalized($0) == key }) {
            return .dropped(.duplicate)
        }

        let text = "\(title) \(summary)"
        if isBlocked(text, blocklist: blocklist) || mentionsIntakeAmount(text) {
            return .dropped(.blocked)
        }

        return corrected ? .corrected(proposal) : .accepted(proposal)
    }

    /// An out-of-range amount is never clamped: a clamped amount looks deliberate but
    /// means nothing, so the goal is removed instead.
    private static func hasValidGoal(_ proposal: HabitProposal, system: MeasurementSystem) -> Bool {
        guard HabitProposal.suggestedGoalTypes.contains(proposal.goalType),
              let value = proposal.goalValue, value > 0
        else { return false }
        return value <= maxGoalValue(for: proposal.goalType, system: system)
    }

    static func maxGoalValue(for goalType: GoalType, system: MeasurementSystem) -> Double {
        let metric = system == .metric
        switch goalType {
        case .none:        return 0
        case .time:        return 600
        case .repetitions: return 500
        case .cups:        return 20
        case .calories:    return 5000
        case .distance:    return metric ? 100 : 60
        case .weight:      return metric ? 200 : 440
        case .capacity:    return metric ? 10 : 340
        }
    }

    /// A number followed by a volume, energy or mass unit, e.g. "2 L", "500ml", "1,5 l".
    /// Kept out of the word lists because a lone "l" would match French elisions like "l'eau".
    private static let intakeAmount = try! NSRegularExpression(
        pattern: #"\d+([.,]\d+)?\s*(l|cl|dl|ml|oz|kcal|cal|g)\b"#,
        options: .caseInsensitive
    )

    static func mentionsIntakeAmount(_ text: String) -> Bool {
        intakeAmount.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) != nil
    }

    /// Case- and diacritic-insensitive comparison key.
    static func normalized(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
    }

    /// Whole-word (or whole-phrase) match, so a term never matches inside another word.
    static func isBlocked(_ text: String, blocklist: [String]) -> Bool {
        let haystack = " \(wordsOnly(text)) "
        return blocklist.contains { term in
            let needle = wordsOnly(term)
            return !needle.isEmpty && haystack.contains(" \(needle) ")
        }
    }

    private static func wordsOnly(_ text: String) -> String {
        normalized(text)
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    /// Truncates at a word boundary when possible.
    private static func truncate(_ text: String, to length: Int) -> String {
        guard text.count > length else { return text }
        let prefix = String(text.prefix(length))
        if let lastSpace = prefix.lastIndex(of: " "), lastSpace > prefix.startIndex {
            return String(prefix[..<lastSpace]).trimmingCharacters(in: .whitespaces)
        }
        return prefix
    }
}
