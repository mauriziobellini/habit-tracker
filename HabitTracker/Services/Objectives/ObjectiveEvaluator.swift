import Foundation

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
        } else if let value = proposal.goalValue, value > 0 {
            let maxValue = maxGoalValue(for: proposal.goalType, system: measurementSystem)
            if value > maxValue {
                proposal.goalValue = maxValue
                corrected = true
            }
        } else {
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

        if isBlocked("\(title) \(summary)", blocklist: blocklist) {
            return .dropped(.blocked)
        }

        return corrected ? .corrected(proposal) : .accepted(proposal)
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
