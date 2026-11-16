import Foundation
import Observation

/// State for the objectives configurator (PRD - objectives §8.3): the objective, refine
/// history, proposals and their added state, loading and errors. Nothing here is
/// persisted; the generator's model sessions are discarded when the configurator closes
/// or the user starts a new search.
@Observable
@MainActor
final class ObjectivesViewModel {
    enum Phase: Equatable {
        case idle
        case generating
        case results
        case rejected
        case failed
    }

    static let maxInputLength = ObjectivePromptBuilder.maxInputLength
    /// Placeholder cards shown while waiting for the first habits of a batch.
    static let skeletonTarget = ObjectiveSuggestionService.targetCount

    var inputText = "" {
        didSet { if inputText.count > Self.maxInputLength { inputText = String(inputText.prefix(Self.maxInputLength)) } }
    }
    var refineText = "" {
        didSet { if refineText.count > Self.maxInputLength { refineText = String(refineText.prefix(Self.maxInputLength)) } }
    }

    private(set) var submittedObjective: String?
    private(set) var refinements: [String] = []
    private(set) var criteria: String?
    private(set) var proposals: [HabitProposal] = []
    private(set) var phase: Phase = .idle
    private(set) var lastMode: ObjectiveRequestMode = .initial

    private let generator: ObjectiveSuggestionGenerating
    private let analytics: AnalyticsService
    private let isPremium: () -> Bool
    private let measurementSystem: () -> MeasurementSystem

    private var task: Task<Void, Never>?
    private var arrivedInBatch = 0
    private var lastRun: (mode: ObjectiveRequestMode, inputType: String, presetID: String?)?

    init(
        generator: ObjectiveSuggestionGenerating,
        analytics: AnalyticsService = NoOpAnalyticsService(),
        isPremium: @escaping () -> Bool = { false },
        measurementSystem: @escaping () -> MeasurementSystem = { .metric }
    ) {
        self.generator = generator
        self.analytics = analytics
        self.isPremium = isPremium
        self.measurementSystem = measurementSystem
    }

    // MARK: - Derived state

    var hasSubmitted: Bool { submittedObjective != nil }
    var isGenerating: Bool { phase == .generating }
    var canSubmit: Bool { !inputText.trimmed.isEmpty && !isGenerating }
    var canRefine: Bool { !refineText.trimmed.isEmpty && !isGenerating }
    var canGenerateMore: Bool { hasSubmitted && !isGenerating }
    var showsNewSearch: Bool { !proposals.isEmpty }
    var addedCount: Int { proposals.filter(\.isAdded).count }

    var skeletonCount: Int {
        guard isGenerating else { return 0 }
        return max(1, Self.skeletonTarget - arrivedInBatch)
    }

    // MARK: - Intents

    func onAppear() {
        generator.prewarm()
    }

    func onDisappear() {
        cancelRunning()
        generator.reset()
    }

    func submit() {
        guard canSubmit else { return }
        startNewObjective(inputText.trimmed, inputType: "free_text", presetID: nil)
    }

    /// A preset tap goes straight to generation (PRD - objectives §8.3).
    func submitPreset(_ preset: ObjectivePreset) {
        guard !isGenerating else { return }
        inputText = preset.localizedTitle
        startNewObjective(preset.localizedTitle, inputType: "preset", presetID: preset.id)
    }

    func refine() {
        guard canRefine, hasSubmitted else { return }
        refinements.append(refineText.trimmed)
        refineText = ""
        start(mode: .refine, inputType: "free_text", presetID: nil)
    }

    func generateMore() {
        guard canGenerateMore else { return }
        start(mode: .more, inputType: lastRun?.inputType ?? "free_text", presetID: lastRun?.presetID)
    }

    func retry() {
        guard let lastRun, !isGenerating else { return }
        if lastRun.mode == .initial, !hasSubmitted { return }
        start(mode: lastRun.mode, inputType: lastRun.inputType, presetID: lastRun.presetID)
    }

    /// Back to the configurator's initial state, discarding the model session.
    func newSearch() {
        analytics.track(.objectiveNewSearchTapped, properties: ["proposals_added_count": addedCount])
        cancelRunning()
        generator.reset()
        inputText = ""
        refineText = ""
        submittedObjective = nil
        refinements = []
        criteria = nil
        proposals = []
        phase = .idle
        lastRun = nil
        arrivedInBatch = 0
    }

    func markAdded(id: UUID) {
        guard let index = proposals.firstIndex(where: { $0.id == id }) else { return }
        proposals[index].isAdded = true
    }

    // MARK: - Running

    private func startNewObjective(_ objective: String, inputType: String, presetID: String?) {
        cancelRunning()
        submittedObjective = objective
        refinements = []
        criteria = nil
        proposals = []
        start(mode: .initial, inputType: inputType, presetID: presetID)
    }

    private func start(mode: ObjectiveRequestMode, inputType: String, presetID: String?) {
        guard let objective = submittedObjective else { return }
        cancelRunning()

        lastRun = (mode, inputType, presetID)
        lastMode = mode
        phase = .generating
        arrivedInBatch = 0

        var submitted: [String: Any] = [
            "input_type": inputType,
            "mode": mode.rawValue,
            "is_premium": String(isPremium()),
        ]
        if let presetID { submitted["preset_id"] = presetID }
        analytics.track(.objectiveSearchSubmitted, properties: submitted)

        let request = ObjectiveRequest(
            objective: objective,
            refinements: refinements,
            proposedTitles: proposals.map(\.title),
            mode: mode,
            measurementSystem: measurementSystem()
        )
        let stream = generator.run(request)
        let startedAt = ContinuousClock.now

        task = Task { [weak self] in
            do {
                for try await event in stream {
                    guard let self, !Task.isCancelled else { return }
                    self.handle(event)
                }
            } catch {
                guard let self, !Task.isCancelled else { return }
                self.handleFailure(error, mode: mode, startedAt: startedAt)
            }
        }
    }

    private func handle(_ event: ObjectiveStreamEvent) {
        switch event {
        case .criteria(let text):
            criteria = text
        case .proposal(let proposal):
            proposals.append(proposal)
            arrivedInBatch += 1
        case .finished(let stats):
            phase = .results
            var properties: [String: Any] = [
                "outcome": "success",
                "proposals_count": stats.proposalsCount,
                "dropped_count": stats.droppedCount,
                "retry_used": String(stats.retryUsed),
                "total_duration_ms": stats.totalDurationMs,
            ]
            if let first = stats.timeToFirstCardMs { properties["time_to_first_card_ms"] = first }
            analytics.track(.objectiveSearchCompleted, properties: properties)
        }
    }

    private func handleFailure(_ error: Error, mode: ObjectiveRequestMode, startedAt: ContinuousClock.Instant) {
        let failure = ObjectiveSuggestionService.failure(for: error)
        switch failure {
        case .rejected:
            phase = .rejected
            if mode == .initial, proposals.isEmpty {
                // Back to the input so the user can rephrase.
                submittedObjective = nil
            } else if mode == .refine, let rejected = refinements.popLast() {
                // A rejected refinement must not seed later requests.
                refineText = rejected
            }
        case .generic:
            phase = .failed
        }

        let elapsed = startedAt.duration(to: .now).components
        analytics.track(.objectiveSearchCompleted, properties: [
            "outcome": failure == .rejected ? "rejected" : "error",
            "proposals_count": arrivedInBatch,
            "dropped_count": 0,
            "retry_used": "false",
            "total_duration_ms": Int(elapsed.seconds * 1000 + elapsed.attoseconds / 1_000_000_000_000_000),
        ])
    }

    private func cancelRunning() {
        task?.cancel()
        task = nil
        if phase == .generating {
            phase = proposals.isEmpty ? .idle : .results
        }
    }
}

private extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}
