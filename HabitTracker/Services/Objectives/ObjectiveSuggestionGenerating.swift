import Foundation
import SwiftUI

// MARK: - Requests and results

enum ObjectiveRequestMode: String, Equatable {
    case initial
    case refine
    case more
}

struct ObjectiveRequest: Equatable {
    var objective: String
    var refinements: [String] = []
    /// Titles already shown in this configurator session, so new batches never repeat them.
    var proposedTitles: [String] = []
    var mode: ObjectiveRequestMode = .initial
    var measurementSystem: MeasurementSystem = .metric
}

struct ObjectiveRunStats: Equatable {
    var proposalsCount: Int
    var droppedCount: Int
    var retryUsed: Bool
    var timeToFirstCardMs: Int?
    var totalDurationMs: Int
}

enum ObjectiveStreamEvent: Equatable {
    case criteria(String)
    case proposal(HabitProposal)
    case finished(ObjectiveRunStats)
}

/// The two outcomes the UI distinguishes (PRD - objectives §8.6).
enum ObjectiveFailure: Error, Equatable {
    /// Policing rejection, Apple guardrail violation or model refusal.
    case rejected
    /// Anything else: generation failed, model unavailable, rate limited, no valid habits.
    case generic
}

/// Generates habit proposals for an objective. Sessions live only inside the generator
/// and are discarded by `reset()` (PRD - objectives §8.3 "Session management").
protocol ObjectiveSuggestionGenerating: AnyObject {
    func prewarm()
    func run(_ request: ObjectiveRequest) -> AsyncThrowingStream<ObjectiveStreamEvent, Error>
    func reset()
}

// MARK: - Model backend

/// A habit as streamed by the model. Every field is optional because partially generated
/// snapshots fill in one property at a time.
struct ResearchHabitDraft: Equatable {
    var title: String?
    var summary: String?
    /// `daily`, `weekly` or `monthly`.
    var frequency: String?
    var timesPerPeriod: Int?
    /// A `GoalType` raw value.
    var goalType: String?
    var goalValue: Double?
    var iconName: String?
}

struct ResearchSnapshot: Equatable {
    var criteria: String?
    var habits: [ResearchHabitDraft] = []
}

enum ObjectiveBackendError: Error, Equatable {
    case guardrailViolation
    case refusal
    case contextWindowExceeded
    case unavailable
}

/// The thin layer over the language model, kept separate so the pipeline can be tested
/// without Apple Intelligence and driven by a stub in UI tests.
protocol ObjectiveModelBackend: AnyObject {
    func prewarm()
    /// Policing step: whether the request is an appropriate self-improvement objective.
    func judge(_ prompt: String) async throws -> Bool
    /// Research step: streams snapshots of a batch of 3–5 habits. Each call runs in a
    /// fresh session, except that the first call after `prewarm()` reuses the warm one.
    func research(_ prompt: String) -> AsyncThrowingStream<ResearchSnapshot, Error>
    func reset()
}

extension HabitProposal {
    /// Maps a finished draft to a proposal, or `nil` when a required field is missing or
    /// holds a value the app does not support.
    init?(draft: ResearchHabitDraft) {
        guard let title = draft.title,
              let rawFrequency = draft.frequency,
              let frequency = FrequencyType(rawValue: rawFrequency),
              HabitProposal.suggestedFrequencies.contains(frequency)
        else { return nil }
        let goalType = draft.goalType.flatMap(GoalType.init(rawValue:)) ?? .none
        self.init(
            title: title,
            summary: draft.summary ?? "",
            frequency: frequency,
            timesPerPeriod: draft.timesPerPeriod ?? 1,
            goalType: goalType,
            goalValue: draft.goalValue,
            iconName: draft.iconName ?? HabitProposal.fallbackIconName
        )
    }
}

// MARK: - Factory and environment

enum ObjectiveSuggestionFactory {
    static func make(arguments: [String] = ProcessInfo.processInfo.arguments) -> ObjectiveSuggestionGenerating? {
        if let scenario = StubObjectiveBackend.Scenario(arguments: arguments) {
            return ObjectiveSuggestionService(backend: StubObjectiveBackend(scenario: scenario))
        }
        #if canImport(FoundationModels)
        if #available(iOS 26, *) {
            return ObjectiveSuggestionService(backend: FoundationModelObjectiveBackend())
        }
        #endif
        return nil
    }
}

private struct ObjectiveSuggestionFactoryKey: EnvironmentKey {
    static let defaultValue: () -> ObjectiveSuggestionGenerating? = { nil }
}

extension EnvironmentValues {
    /// Builds a new generator per configurator presentation, so no session outlives it.
    var makeObjectiveGenerator: () -> ObjectiveSuggestionGenerating? {
        get { self[ObjectiveSuggestionFactoryKey.self] }
        set { self[ObjectiveSuggestionFactoryKey.self] = newValue }
    }
}
