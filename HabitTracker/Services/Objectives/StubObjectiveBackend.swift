import Foundation

/// Deterministic stand-in for the on-device model, used only by UI tests through the
/// `--uitesting-objectives*` launch arguments. The real pipeline (evaluator, retry,
/// streaming) still runs on top of it.
final class StubObjectiveBackend: ObjectiveModelBackend {
    enum Scenario: Equatable {
        /// 4 habits on the first batch, 3 on each later batch.
        case success
        /// The policing step rejects every request.
        case reject
        /// Research fails with a generic error.
        case error
        /// 2 habits, and an empty retry.
        case partial

        init?(arguments: [String]) {
            if arguments.contains("--uitesting-objectives-reject") {
                self = .reject
            } else if arguments.contains("--uitesting-objectives-error") {
                self = .error
            } else if arguments.contains("--uitesting-objectives-partial") {
                self = .partial
            } else if arguments.contains("--uitesting-objectives") {
                self = .success
            } else {
                return nil
            }
        }
    }

    static let titles = [
        "Practice scales", "Play one full song", "Learn a new chord", "Listen to a new artist",
        "Record yourself playing", "Study music theory", "Warm up your fingers", "Play with a metronome",
        "Learn a riff", "Jam with a friend",
    ]

    private let scenario: Scenario
    private let stepDelay: Duration
    private var researchCalls = 0
    private var issuedTitles = 0

    init(scenario: Scenario, stepDelay: Duration = .milliseconds(150)) {
        self.scenario = scenario
        self.stepDelay = stepDelay
    }

    func prewarm() {}

    func reset() {}

    func judge(_ prompt: String) async throws -> Bool {
        try await Task.sleep(for: stepDelay)
        return scenario != .reject
    }

    func research(_ prompt: String) -> AsyncThrowingStream<ResearchSnapshot, Error> {
        researchCalls += 1
        let count: Int
        switch scenario {
        case .success: count = researchCalls == 1 ? 4 : 3
        case .partial: count = researchCalls == 1 ? 2 : 0
        case .reject, .error: count = 0
        }
        let habits = (0..<count).map { _ in nextHabit() }
        let failing = scenario == .error
        let delay = stepDelay

        return AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    try await Task.sleep(for: delay)
                    if failing { throw ObjectiveBackendError.unavailable }
                    var snapshot = ResearchSnapshot(criteria: "Small, regular practice builds skill fastest.")
                    continuation.yield(snapshot)
                    for habit in habits {
                        try await Task.sleep(for: delay)
                        snapshot.habits.append(habit)
                        continuation.yield(snapshot)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private func nextHabit() -> ResearchHabitDraft {
        let index = issuedTitles
        issuedTitles += 1
        let base = Self.titles[index % Self.titles.count]
        let title = index < Self.titles.count ? base : "\(base) \(index / Self.titles.count + 1)"
        let frequencies = ["daily", "weekly", "monthly"]
        return ResearchHabitDraft(
            title: title,
            summary: "A short, focused session.",
            frequency: frequencies[index % frequencies.count],
            timesPerPeriod: index % 3 == 1 ? 3 : 1,
            goalType: index % 2 == 0 ? "time" : "none",
            goalValue: index % 2 == 0 ? 20 : nil,
            iconName: "pianokeys"
        )
    }
}
