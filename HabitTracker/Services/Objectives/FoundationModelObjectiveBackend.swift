#if canImport(FoundationModels)
import Foundation
import FoundationModels

// MARK: - Generation schema
//
// Kept small, with short property names: the schema is part of every request and counts
// against the on-device model's 4,096-token context. Property order matters: generation
// follows declaration order, so `criteria` streams first and habits complete one by one.

@available(iOS 26, *)
@Generable
struct ObjectivePolicyVerdict {
    @Guide(description: "True only if the request is an appropriate self-improvement goal")
    var approved: Bool
}

@available(iOS 26, *)
@Generable
enum GenFrequency: CaseIterable {
    case daily, weekly, monthly

    var frequency: FrequencyType {
        switch self {
        case .daily:   return .daily
        case .weekly:  return .weekly
        case .monthly: return .monthly
        }
    }
}

/// Mirrors `HabitProposal.suggestedGoalTypes`, in the same order.
@available(iOS 26, *)
@Generable
enum GenGoal: CaseIterable {
    case none, repetitions, time, distance

    var goalType: GoalType {
        switch self {
        case .none:        return .none
        case .repetitions: return .repetitions
        case .time:        return .time
        case .distance:    return .distance
        }
    }
}

/// Mirrors `HabitProposal.allowedIconNames`, in the same order.
@available(iOS 26, *)
@Generable
enum GenIcon: CaseIterable {
    case walk, run, bike, gym, yoga
    case mind, heart, sleep, sun, night
    case water, food, nature, book, language
    case study, writing, piano, guitar, music
    case art, call, friends, greet, home
    case work, clock, idea, star

    var symbolName: String {
        let index = GenIcon.allCases.firstIndex(of: self) ?? 0
        let names = HabitProposal.allowedIconNames
        return index < names.count ? names[index] : HabitProposal.fallbackIconName
    }
}

@available(iOS 26, *)
@Generable
struct GenHabit {
    @Guide(description: "Short habit name, 2 to 5 words")
    var title: String
    @Guide(description: "One short sentence on how to do it")
    var summary: String
    var frequency: GenFrequency
    @Guide(description: "Times per period", .range(1...10))
    var times: Int
    var goal: GenGoal
    @Guide(description: "Goal amount in the stated unit. Leave empty when goal is none")
    var amount: Double?
    var icon: GenIcon
}

@available(iOS 26, *)
@Generable
struct GenHabitBatch {
    @Guide(description: "One sentence on the criteria used to pick these habits")
    var criteria: String
    @Guide(description: "Three to five habits", .count(3...5))
    var habits: [GenHabit]
}

// MARK: - Backend

/// Runs the policing and research steps on Apple's on-device foundation model. Nothing
/// leaves the device, and nothing here is logged.
@available(iOS 26, *)
final class FoundationModelObjectiveBackend: ObjectiveModelBackend {
    private var prewarmedSession: LanguageModelSession?

    private func makeResearchSession() -> LanguageModelSession {
        LanguageModelSession(instructions: ObjectivePromptStrings.localized("research.instructions"))
    }

    func prewarm() {
        let session = makeResearchSession()
        session.prewarm()
        prewarmedSession = session
    }

    func judge(_ prompt: String) async throws -> Bool {
        let session = LanguageModelSession(
            instructions: ObjectivePromptStrings.localized("policing.instructions")
        )
        do {
            let response = try await session.respond(to: prompt, generating: ObjectivePolicyVerdict.self)
            return response.content.approved
        } catch {
            throw Self.map(error)
        }
    }

    func research(_ prompt: String) -> AsyncThrowingStream<ResearchSnapshot, Error> {
        let session = prewarmedSession ?? makeResearchSession()
        prewarmedSession = nil
        return AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let stream = session.streamResponse(to: prompt, generating: GenHabitBatch.self)
                    for try await snapshot in stream {
                        continuation.yield(Self.snapshot(from: snapshot.content))
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: Self.map(error))
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    func reset() {
        prewarmedSession = nil
    }

    static func map(_ error: Error) -> Error {
        if error is CancellationError { return error }
        guard let generationError = error as? LanguageModelSession.GenerationError else {
            return ObjectiveBackendError.unavailable
        }
        switch generationError {
        case .guardrailViolation:        return ObjectiveBackendError.guardrailViolation
        case .refusal:                   return ObjectiveBackendError.refusal
        case .exceededContextWindowSize: return ObjectiveBackendError.contextWindowExceeded
        default:                         return ObjectiveBackendError.unavailable
        }
    }

    private static func snapshot(from partial: GenHabitBatch.PartiallyGenerated) -> ResearchSnapshot {
        ResearchSnapshot(
            criteria: partial.criteria,
            habits: (partial.habits ?? []).map { habit in
                ResearchHabitDraft(
                    title: habit.title,
                    summary: habit.summary,
                    frequency: habit.frequency.map { $0.frequency.rawValue },
                    timesPerPeriod: habit.times,
                    goalType: habit.goal.map { $0.goalType.rawValue },
                    goalValue: habit.amount ?? nil,
                    iconName: habit.icon.map(\.symbolName)
                )
            }
        )
    }
}
#endif
