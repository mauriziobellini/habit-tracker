import Foundation

/// Runs the objectives pipeline (PRD - objectives §8.3): policing → streamed research →
/// local evaluator → one retry when fewer than three habits survive. Accepted habits are
/// emitted one by one as soon as each finishes generating.
final class ObjectiveSuggestionService: ObjectiveSuggestionGenerating {
    static let targetCount = 3
    static let maxCount = 5

    private let backend: ObjectiveModelBackend
    private let promptBuilder: ObjectivePromptBuilder
    private let blocklist: () -> [String]

    init(
        backend: ObjectiveModelBackend,
        promptBuilder: ObjectivePromptBuilder = ObjectivePromptBuilder(),
        blocklist: @escaping () -> [String] = ObjectivePromptStrings.blocklist
    ) {
        self.backend = backend
        self.promptBuilder = promptBuilder
        self.blocklist = blocklist
    }

    func prewarm() {
        backend.prewarm()
    }

    func reset() {
        backend.reset()
    }

    func run(_ request: ObjectiveRequest) -> AsyncThrowingStream<ObjectiveStreamEvent, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let stats = try await self.execute(request) { continuation.yield($0) }
                    continuation.yield(.finished(stats))
                    continuation.finish()
                } catch is CancellationError {
                    continuation.finish()
                } catch {
                    if Task.isCancelled {
                        continuation.finish()
                    } else {
                        continuation.finish(throwing: Self.failure(for: error))
                    }
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    static func failure(for error: Error) -> ObjectiveFailure {
        if let failure = error as? ObjectiveFailure { return failure }
        switch error as? ObjectiveBackendError {
        case .guardrailViolation?, .refusal?: return .rejected
        default: return .generic
        }
    }

    // MARK: - Pipeline

    private final class RunState {
        var accepted: [HabitProposal] = []
        var dropped = 0
        var firstCardAt: ContinuousClock.Instant?
        var criteriaSent = false
        var reseeded = false
    }

    private func execute(
        _ request: ObjectiveRequest,
        emit: @escaping (ObjectiveStreamEvent) -> Void
    ) async throws -> ObjectiveRunStats {
        let clock = ContinuousClock()
        let start = clock.now
        let blocklist = blocklist()

        let approved = try await backend.judge(promptBuilder.policingPrompt(for: request))
        try Task.checkCancellation()
        guard approved else { throw ObjectiveFailure.rejected }

        let state = RunState()
        try await researchPass(
            request: request,
            excluding: request.proposedTitles,
            asksForDifferentHabits: false,
            state: state,
            blocklist: blocklist,
            clock: clock,
            emit: emit
        )

        var retryUsed = false
        if state.accepted.count < Self.targetCount {
            retryUsed = true
            try Task.checkCancellation()
            try await researchPass(
                request: request,
                excluding: request.proposedTitles + state.accepted.map(\.title),
                asksForDifferentHabits: true,
                state: state,
                blocklist: blocklist,
                clock: clock,
                emit: emit
            )
        }

        guard !state.accepted.isEmpty else { throw ObjectiveFailure.generic }

        return ObjectiveRunStats(
            proposalsCount: state.accepted.count,
            droppedCount: state.dropped,
            retryUsed: retryUsed,
            timeToFirstCardMs: state.firstCardAt.map { Self.milliseconds(start.duration(to: $0)) },
            totalDurationMs: Self.milliseconds(start.duration(to: clock.now))
        )
    }

    /// One research call. A context-window overflow is retried once with a compact seed;
    /// that re-seed does not count as the evaluator retry (PRD - objectives §10.5).
    private func researchPass(
        request: ObjectiveRequest,
        excluding titles: [String],
        asksForDifferentHabits: Bool,
        state: RunState,
        blocklist: [String],
        clock: ContinuousClock,
        emit: @escaping (ObjectiveStreamEvent) -> Void
    ) async throws {
        let prompt = promptBuilder.researchPrompt(
            for: request, excluding: titles, asksForDifferentHabits: asksForDifferentHabits
        )
        do {
            try await consume(backend.research(prompt), request: request, state: state,
                              blocklist: blocklist, clock: clock, emit: emit)
        } catch ObjectiveBackendError.contextWindowExceeded where !state.reseeded {
            state.reseeded = true
            let compactPrompt = promptBuilder.researchPrompt(
                for: request,
                excluding: titles + state.accepted.map(\.title),
                asksForDifferentHabits: asksForDifferentHabits,
                compact: true
            )
            try await consume(backend.research(compactPrompt), request: request, state: state,
                              blocklist: blocklist, clock: clock, emit: emit)
        }
    }

    /// Snapshots stream in declaration order: `criteria` first, then habits one at a time.
    /// A habit is finished once the next one has started, or when the stream ends.
    private func consume(
        _ stream: AsyncThrowingStream<ResearchSnapshot, Error>,
        request: ObjectiveRequest,
        state: RunState,
        blocklist: [String],
        clock: ContinuousClock,
        emit: @escaping (ObjectiveStreamEvent) -> Void
    ) async throws {
        var processed = 0
        var last: ResearchSnapshot?

        func sendCriteria(_ criteria: String?) {
            guard !state.criteriaSent, let criteria else { return }
            let trimmed = criteria.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return }
            state.criteriaSent = true
            emit(.criteria(trimmed))
        }

        func handle(_ draft: ResearchHabitDraft) {
            guard state.accepted.count < Self.maxCount else { return }
            guard let proposal = HabitProposal(draft: draft) else {
                state.dropped += 1
                return
            }
            let result = ObjectiveEvaluator.evaluate(
                proposal,
                alreadyProposedTitles: request.proposedTitles + state.accepted.map(\.title),
                blocklist: blocklist,
                measurementSystem: request.measurementSystem
            )
            guard let accepted = result.proposal else {
                state.dropped += 1
                return
            }
            state.accepted.append(accepted)
            if state.firstCardAt == nil { state.firstCardAt = clock.now }
            emit(.proposal(accepted))
        }

        for try await snapshot in stream {
            try Task.checkCancellation()
            last = snapshot
            if !snapshot.habits.isEmpty { sendCriteria(snapshot.criteria) }
            while processed < snapshot.habits.count - 1 {
                handle(snapshot.habits[processed])
                processed += 1
            }
        }

        guard let last else { return }
        sendCriteria(last.criteria)
        while processed < last.habits.count {
            handle(last.habits[processed])
            processed += 1
        }
    }

    private static func milliseconds(_ duration: Duration) -> Int {
        let parts = duration.components
        return Int(parts.seconds * 1000 + parts.attoseconds / 1_000_000_000_000_000)
    }
}
