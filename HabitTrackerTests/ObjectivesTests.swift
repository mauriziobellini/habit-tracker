import Testing
import Foundation
import SwiftData
import SwiftUI
@testable import HabitTracker

// MARK: - Fakes

private final class AnalyticsSpy: AnalyticsService {
    private(set) var events: [(event: AnalyticsEvent, properties: [String: Any])] = []

    func track(_ event: AnalyticsEvent, properties: [String: Any]) {
        events.append((event, properties))
    }

    func properties(of event: AnalyticsEvent) -> [[String: Any]] {
        events.filter { $0.event == event }.map(\.properties)
    }

    var allValues: [String] {
        events.flatMap { $0.properties.values.map { "\($0)" } }
    }
}

private final class FakeBackend: ObjectiveModelBackend {
    struct Batch {
        var snapshots: [ResearchSnapshot]
        var error: Error?
    }

    var approve = true
    var judgeError: Error?
    var batches: [Batch] = []
    private(set) var judgePrompts: [String] = []
    private(set) var researchPrompts: [String] = []

    func prewarm() {}
    func reset() {}

    func judge(_ prompt: String) async throws -> Bool {
        judgePrompts.append(prompt)
        if let judgeError { throw judgeError }
        return approve
    }

    func research(_ prompt: String) -> AsyncThrowingStream<ResearchSnapshot, Error> {
        researchPrompts.append(prompt)
        let index = researchPrompts.count - 1
        let batch = index < batches.count ? batches[index] : Batch(snapshots: [])
        return AsyncThrowingStream { continuation in
            for snapshot in batch.snapshots { continuation.yield(snapshot) }
            if let error = batch.error {
                continuation.finish(throwing: error)
            } else {
                continuation.finish()
            }
        }
    }
}

private final class FakeGenerator: ObjectiveSuggestionGenerating {
    var events: [ObjectiveStreamEvent] = []
    var error: Error?
    /// When set, the stream stays open until the test finishes it.
    var holdsStream = false
    private(set) var requests: [ObjectiveRequest] = []
    private(set) var prewarmCount = 0
    private(set) var resetCount = 0
    private(set) var openContinuation: AsyncThrowingStream<ObjectiveStreamEvent, Error>.Continuation?

    func prewarm() { prewarmCount += 1 }
    func reset() { resetCount += 1 }

    func run(_ request: ObjectiveRequest) -> AsyncThrowingStream<ObjectiveStreamEvent, Error> {
        requests.append(request)
        let events = events
        let error = error
        let holds = holdsStream
        return AsyncThrowingStream { continuation in
            for event in events { continuation.yield(event) }
            if holds {
                self.openContinuation = continuation
            } else if let error {
                continuation.finish(throwing: error)
            } else {
                continuation.finish()
            }
        }
    }
}

// MARK: - Fixtures

private enum Fixture {
    static func draft(
        _ title: String?,
        frequency: String? = "daily",
        times: Int? = 1,
        goal: String? = "time",
        value: Double? = 20,
        icon: String? = "book.fill",
        summary: String? = "Short and simple."
    ) -> ResearchHabitDraft {
        ResearchHabitDraft(
            title: title, summary: summary, frequency: frequency, timesPerPeriod: times,
            goalType: goal, goalValue: value, iconName: icon
        )
    }

    /// Snapshots as the model streams them: criteria first, then one more habit each time.
    static func streamed(_ drafts: [ResearchHabitDraft], criteria: String = "Practice beats talent.") -> [ResearchSnapshot] {
        var snapshots = [ResearchSnapshot(criteria: criteria)]
        for count in 1...max(drafts.count, 1) where count <= drafts.count {
            snapshots.append(ResearchSnapshot(criteria: criteria, habits: Array(drafts.prefix(count))))
        }
        return snapshots
    }

    static func drafts(_ titles: [String]) -> [ResearchHabitDraft] {
        titles.map { draft($0) }
    }

    static func proposal(
        _ title: String = "Practice scales",
        frequency: FrequencyType = .daily,
        times: Int = 1,
        goalType: GoalType = .time,
        goalValue: Double? = 20,
        icon: String = "pianokeys"
    ) -> HabitProposal {
        HabitProposal(
            title: title, summary: "Ten minutes a day.", frequency: frequency,
            timesPerPeriod: times, goalType: goalType, goalValue: goalValue, iconName: icon
        )
    }

    static let promptStrings: [String: String] = [
        "prompt.objective": "O: %@",
        "prompt.refinement": "R: %@",
        "prompt.refine": "REFINE",
        "prompt.more": "MORE",
        "prompt.exclude": "X: %@",
        "prompt.units": "U: %@",
    ]

    static let promptBuilder = ObjectivePromptBuilder(localized: { promptStrings[$0] ?? $0 })

    static func service(_ backend: FakeBackend, blocklist: [String] = ["skip meals"]) -> ObjectiveSuggestionService {
        ObjectiveSuggestionService(backend: backend, promptBuilder: promptBuilder, blocklist: { blocklist })
    }

    static func collect(
        _ stream: AsyncThrowingStream<ObjectiveStreamEvent, Error>
    ) async -> (events: [ObjectiveStreamEvent], error: Error?) {
        var events: [ObjectiveStreamEvent] = []
        do {
            for try await event in stream { events.append(event) }
            return (events, nil)
        } catch {
            return (events, error)
        }
    }

    static func lproj(_ language: String, table: String) throws -> [String: String] {
        let path = try #require(
            Bundle.main.path(forResource: table, ofType: "strings", inDirectory: "\(language).lproj"),
            "missing \(table).strings for \(language)"
        )
        return try #require(NSDictionary(contentsOfFile: path) as? [String: String])
    }

    static let languages = ["en", "es", "fr", "de", "it", "nl", "pt-PT"]
}

private extension Array where Element == ObjectiveStreamEvent {
    var proposals: [HabitProposal] {
        compactMap { if case .proposal(let p) = $0 { return p } else { return nil } }
    }
    var stats: ObjectiveRunStats? {
        for case .finished(let stats) in self { return stats }
        return nil
    }
}

@MainActor
private func waitUntil(_ condition: () -> Bool, timeout: Duration = .seconds(2)) async throws {
    let deadline = ContinuousClock.now + timeout
    while !condition() {
        guard ContinuousClock.now < deadline else { return }
        try await Task.sleep(for: .milliseconds(5))
    }
}

// MARK: - Availability gate

@Suite("Objectives availability gate")
struct ObjectiveAvailabilityTests {
    @Test("Any objectives launch argument forces the gate on")
    func objectivesArgumentForcesOn() {
        for argument in ["--uitesting-objectives", "--uitesting-objectives-reject", "--uitesting-objectives-partial"] {
            #expect(ObjectiveAvailabilityFactory.make(arguments: ["--uitesting", argument]).isAvailable())
        }
    }

    @Test("Other UI-test runs force the gate off so existing flows stay deterministic")
    func uiTestingForcesOff() {
        #expect(!ObjectiveAvailabilityFactory.make(arguments: ["--uitesting"]).isAvailable())
        #expect(!ObjectiveAvailabilityFactory.make(arguments: ["--uitesting-premium"]).isAvailable())
    }

    @Test("Production uses the live checker")
    func productionUsesLiveChecker() {
        #expect(ObjectiveAvailabilityFactory.make(arguments: []) is LiveObjectiveAvailability)
    }

    @Test("The live checker asks the model about the app's language")
    func liveCheckerUsesInjectedLocale() {
        let italianOnly: (Locale) -> Bool = { $0.language.languageCode?.identifier == "it" }
        #expect(LiveObjectiveAvailability(locale: { Locale(identifier: "it") }, modelIsAvailable: italianOnly).isAvailable())
        #expect(!LiveObjectiveAvailability(locale: { Locale(identifier: "nl") }, modelIsAvailable: italianOnly).isAvailable())
    }

    @Test("Without an injected checker the feature is hidden")
    func environmentDefaultIsOff() {
        #expect(!EnvironmentValues().objectiveAvailability.isAvailable())
        #expect(EnvironmentValues().makeObjectiveGenerator() == nil)
    }

    @Test("The generator factory picks the stub only for UI-test scenarios")
    func generatorFactory() {
        #expect(StubObjectiveBackend.Scenario(arguments: ["--uitesting-objectives"]) == .success)
        #expect(StubObjectiveBackend.Scenario(arguments: ["--uitesting-objectives-reject"]) == .reject)
        #expect(StubObjectiveBackend.Scenario(arguments: ["--uitesting-objectives-error"]) == .error)
        #expect(StubObjectiveBackend.Scenario(arguments: ["--uitesting-objectives-partial"]) == .partial)
        #expect(StubObjectiveBackend.Scenario(arguments: ["--uitesting"]) == nil)
        #expect(ObjectiveSuggestionFactory.make(arguments: ["--uitesting-objectives"]) != nil)
    }
}

// MARK: - Domain

@Suite("Objectives domain")
struct ObjectiveDomainTests {
    @Test("A proposal pre-fills the habit configurator")
    func applyProposalFillsFields() {
        let vm = TaskConfigurationViewModel(mode: .create)
        vm.applyProposal(Fixture.proposal(frequency: .weekly, times: 3, goalType: .distance, goalValue: 5), measurementSystem: .imperial)
        #expect(vm.title == "Practice scales")
        #expect(vm.iconName == "pianokeys")
        #expect(vm.frequencyType == .weekly)
        #expect(vm.timesPerPeriod == 3)
        #expect(vm.goalType == .distance)
        #expect(vm.goalValue == 5)
        #expect(vm.goalUnit == "mi")
        #expect(!vm.isPreset)
        #expect(vm.presetIdentifier == nil)
        #expect(vm.creationSource == .objective)
    }

    @Test("A proposal without a goal leaves value and unit empty, and times are clamped")
    func applyProposalWithoutGoal() {
        let vm = TaskConfigurationViewModel(mode: .create)
        vm.applyProposal(Fixture.proposal(frequency: .weekly, times: 12, goalType: .none, goalValue: 4), measurementSystem: .metric)
        #expect(vm.goalType == .none)
        #expect(vm.goalValue == nil)
        #expect(vm.goalUnit == nil)
        #expect(vm.timesPerPeriod == 7)
    }

    @Test("habit_created reports the creation source")
    @MainActor
    func habitCreatedSource() throws {
        let container = try ModelContainer(
            for: Category.self, HabitTask.self, TaskCompletion.self, AppSettings.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let cases: [(source: String, configure: (TaskConfigurationViewModel) -> Void)] = [
            ("manual", { $0.title = "Walk" }),
            ("preset", {
                $0.applyPreset(PresetTask(id: "p", name: "Read", iconName: "book.fill", categoryName: "Health",
                                          goalType: .time, defaultUnit: "min", defaultGoalValue: 10), categories: [])
            }),
            ("objective", { $0.applyProposal(Fixture.proposal(), measurementSystem: .metric) }),
        ]
        for (source, configure) in cases {
            let spy = AnalyticsSpy()
            let vm = TaskConfigurationViewModel(mode: .create)
            configure(vm)
            // Reminders schedule asynchronously and would outlive this in-memory store.
            vm.notificationEnabled = false
            vm.save(context: context, categories: [], analytics: spy)
            let created = try #require(spy.properties(of: .habitCreated).first)
            #expect(created["source"] as? String == source)
        }
    }

    @Test("Units follow the measurement system and never come from the model")
    func unitPolicy() {
        #expect(ObjectiveUnitPolicy.unit(for: .none, system: .metric) == nil)
        #expect(ObjectiveUnitPolicy.unit(for: .time, system: .imperial) == "min")
        #expect(ObjectiveUnitPolicy.unit(for: .distance, system: .metric) == "km")
        #expect(ObjectiveUnitPolicy.unit(for: .distance, system: .imperial) == "mi")
        #expect(ObjectiveUnitPolicy.unit(for: .weight, system: .imperial) == "lb")
        #expect(ObjectiveUnitPolicy.unit(for: .capacity, system: .metric) == "L")
        for goalType in GoalType.allCases where goalType != .none {
            #expect(ObjectiveUnitPolicy.unit(for: goalType, system: .metric) != nil)
        }
    }

    @Test("The configuration line shows times only above one, and the goal with its unit")
    func configSummary() {
        let weekly = Fixture.proposal(frequency: .weekly, times: 3, goalType: .time, goalValue: 30)
            .configSummary(measurementSystem: .metric)
        #expect(weekly.components(separatedBy: " · ").count == 3)
        #expect(weekly.hasSuffix("30 min"))
        #expect(weekly.contains("3"))

        let daily = Fixture.proposal(times: 1, goalType: .none, goalValue: nil)
            .configSummary(measurementSystem: .metric)
        #expect(!daily.contains(" · "))

        let fractional = Fixture.proposal(goalType: .distance, goalValue: 2.5)
            .configSummary(measurementSystem: .imperial)
        #expect(fractional.hasSuffix("mi"))
    }

    @Test("Twelve presets with unique ids, all localized")
    func presetCatalog() throws {
        let presets = ObjectivePresetCatalog.all
        #expect(presets.count == 12)
        #expect(Set(presets.map(\.id)).count == presets.count)
        for language in Fixture.languages {
            let strings = try Fixture.lproj(language, table: "Localizable")
            for preset in presets {
                #expect(strings[preset.title] != nil, "\(language) is missing \(preset.title)")
            }
        }
    }

    @Test("Every allowed icon is a real SF Symbol and the schema enum mirrors the list")
    func icons() {
        let names = HabitProposal.allowedIconNames
        #expect(Set(names).count == names.count)
        #expect(names.contains(HabitProposal.fallbackIconName))
        for name in names {
            #expect(UIImage(systemName: name) != nil, "\(name) is not an SF Symbol")
        }
        #if canImport(FoundationModels)
        if #available(iOS 26, *) {
            #expect(GenIcon.allCases.count == names.count)
            #expect(GenIcon.allCases.map(\.symbolName) == names)
        }
        #endif
    }

    @Test("Drafts map to proposals only with a title and a suggested frequency")
    func draftMapping() {
        #expect(HabitProposal(draft: Fixture.draft("Read")) != nil)
        #expect(HabitProposal(draft: Fixture.draft(nil)) == nil)
        #expect(HabitProposal(draft: Fixture.draft("Read", frequency: "yearly")) == nil)
        #expect(HabitProposal(draft: Fixture.draft("Read", frequency: "specificDays")) == nil)
        #expect(HabitProposal(draft: Fixture.draft("Read", frequency: nil)) == nil)

        let unknownGoal = HabitProposal(draft: Fixture.draft("Read", goal: "pages"))
        #expect(unknownGoal?.goalType == GoalType.none)
        let noIcon = HabitProposal(draft: Fixture.draft("Read", icon: nil))
        #expect(noIcon?.iconName == HabitProposal.fallbackIconName)
    }
}

// MARK: - Prompts

@Suite("Objectives prompts")
struct ObjectivePromptTests {
    private let request = ObjectiveRequest(objective: "  Learn piano  ", refinements: ["I have 10 minutes"])

    @Test("Policing prompt carries the objective and every refinement")
    func policingPrompt() {
        let prompt = Fixture.promptBuilder.policingPrompt(for: request)
        #expect(prompt == "O: Learn piano\nR: I have 10 minutes")
    }

    @Test("Input is clipped to 200 characters")
    func clipping() {
        let long = String(repeating: "a", count: 500)
        let prompt = Fixture.promptBuilder.policingPrompt(for: ObjectiveRequest(objective: long))
        #expect(prompt == "O: " + String(repeating: "a", count: 200))
    }

    @Test("Initial research prompt has no refine, more or exclusion lines")
    func initialResearchPrompt() {
        let prompt = Fixture.promptBuilder.researchPrompt(for: request, excluding: [])
        #expect(prompt.contains("O: Learn piano"))
        #expect(prompt.contains("R: I have 10 minutes"))
        #expect(!prompt.contains("REFINE"))
        #expect(!prompt.contains("MORE"))
        #expect(!prompt.contains("X: "))
        #expect(prompt.contains("distance = km"))
        #expect(prompt.contains("time = min"))
    }

    @Test("Refine, Generate more and the retry each add their instruction")
    func modeLines() {
        var refine = request
        refine.mode = .refine
        #expect(Fixture.promptBuilder.researchPrompt(for: refine, excluding: []).contains("REFINE"))

        var more = request
        more.mode = .more
        #expect(Fixture.promptBuilder.researchPrompt(for: more, excluding: []).contains("MORE"))

        #expect(Fixture.promptBuilder.researchPrompt(for: request, excluding: [], asksForDifferentHabits: true).contains("MORE"))
    }

    @Test("Imperial users get imperial units in the prompt")
    func imperialUnits() {
        var imperial = request
        imperial.measurementSystem = .imperial
        let prompt = Fixture.promptBuilder.researchPrompt(for: imperial, excluding: [])
        #expect(prompt.contains("distance = mi"))
        #expect(prompt.contains("weight = lb"))
    }

    @Test("Exclusions keep the most recent titles, fewer in the compact prompt")
    func exclusionCaps() {
        let titles = (1...30).map { "T\($0)" }
        let full = Fixture.promptBuilder.researchPrompt(for: request, excluding: titles)
        #expect(full.contains("X: T11, T12"))
        #expect(!full.contains("T10,"))

        var many = request
        many.refinements = ["one", "two", "three"]
        let compact = Fixture.promptBuilder.researchPrompt(for: many, excluding: titles, compact: true)
        #expect(compact.contains("X: T21, T22"))
        #expect(!compact.contains("T20,"))
        #expect(!compact.contains("R: one"))
        #expect(compact.contains("R: two"))
        #expect(compact.contains("R: three"))
    }

    @Test("Every language ships every prompt key, with one placeholder in each template")
    func promptStringsParity() throws {
        for language in Fixture.languages {
            let strings = try Fixture.lproj(language, table: ObjectivePromptStrings.table)
            #expect(Set(strings.keys) == Set(ObjectivePromptStrings.keys), "\(language) prompt keys differ")
            for key in ["prompt.objective", "prompt.refinement", "prompt.exclude", "prompt.units"] {
                let template = try #require(strings[key])
                #expect(template.components(separatedBy: "%@").count == 2, "\(language) \(key)")
            }
            #expect(!ObjectivePromptStrings.splitList(strings["evaluator.blocklist"] ?? "").isEmpty)
        }
    }

    @Test("Blocklists split on commas and ignore blanks")
    func splitList() {
        #expect(ObjectivePromptStrings.splitList(" a, b c ,, d ") == ["a", "b c", "d"])
        #expect(!ObjectivePromptStrings.englishBlocklist().isEmpty)
    }
}

// MARK: - Evaluator

@Suite("Objectives evaluator")
struct ObjectiveEvaluatorTests {
    private func evaluate(
        _ proposal: HabitProposal,
        titles: [String] = [],
        blocklist: [String] = ["skip meals", "meth"]
    ) -> ObjectiveEvaluator.Result {
        ObjectiveEvaluator.evaluate(proposal, alreadyProposedTitles: titles, blocklist: blocklist)
    }

    @Test("A valid proposal passes unchanged")
    func accepted() {
        let proposal = Fixture.proposal()
        #expect(evaluate(proposal) == .accepted(proposal))
    }

    @Test("A blank title is dropped")
    func blankTitle() {
        #expect(evaluate(Fixture.proposal("   ")) == .dropped(.missingTitle))
    }

    @Test("Frequencies the model may not suggest are dropped")
    func unsupportedFrequency() {
        #expect(evaluate(Fixture.proposal(frequency: .specificDays)) == .dropped(.unsupportedFrequency))
    }

    @Test("Long titles are cut at a word boundary")
    func longTitle() throws {
        let result = evaluate(Fixture.proposal("Practice the major and minor scales slowly every single morning"))
        let title = try #require(result.proposal?.title)
        #expect(title.count <= ObjectiveEvaluator.maxTitleLength)
        #expect(!title.hasSuffix(" "))
        #expect("Practice the major and minor scales slowly every single morning".hasPrefix(title))
        if case .corrected = result {} else { Issue.record("expected a corrected result") }
    }

    @Test("Times per period are clamped to the frequency's range")
    func timesClamped() {
        #expect(evaluate(Fixture.proposal(frequency: .weekly, times: 9)).proposal?.timesPerPeriod == 7)
        #expect(evaluate(Fixture.proposal(times: 0)).proposal?.timesPerPeriod == 1)
    }

    @Test("Goal values are made consistent with the goal type")
    func goalRules() {
        let noGoal = evaluate(Fixture.proposal(goalType: .none, goalValue: 3)).proposal
        #expect(noGoal?.goalValue == nil)

        let zero = evaluate(Fixture.proposal(goalType: .time, goalValue: 0)).proposal
        #expect(zero?.goalType == GoalType.none)
        #expect(zero?.goalValue == nil)

        let missing = evaluate(Fixture.proposal(goalType: .repetitions, goalValue: nil)).proposal
        #expect(missing?.goalType == GoalType.none)

        let huge = evaluate(Fixture.proposal(goalType: .time, goalValue: 5000)).proposal
        #expect(huge?.goalValue == 600)
    }

    @Test("Unknown icons fall back to the default")
    func unknownIcon() {
        #expect(evaluate(Fixture.proposal(icon: "not.a.symbol")).proposal?.iconName == HabitProposal.fallbackIconName)
    }

    @Test("Duplicates are detected ignoring case and accents")
    func duplicates() {
        #expect(evaluate(Fixture.proposal("Café run"), titles: ["cafe RUN "]) == .dropped(.duplicate))
    }

    @Test("Blocklisted words drop the habit, but only as whole words")
    func blocklist() {
        #expect(evaluate(Fixture.proposal("Skip meals on Fridays")) == .dropped(.blocked))
        #expect(evaluate(Fixture.proposal("Learn a new method")).proposal != nil)
    }
}

// MARK: - Suggestion service

@Suite("Objectives suggestion service")
struct ObjectiveSuggestionServiceTests {
    private let request = ObjectiveRequest(objective: "Learn piano")

    @Test("Happy path streams criteria first, then each habit")
    func happyPath() async {
        let backend = FakeBackend()
        backend.batches = [.init(snapshots: Fixture.streamed(Fixture.drafts(["A one", "B two", "C three", "D four"])))]

        let (events, error) = await Fixture.collect(Fixture.service(backend).run(request))
        #expect(error == nil)
        #expect(events.first == .criteria("Practice beats talent."))
        #expect(events.proposals.map(\.title) == ["A one", "B two", "C three", "D four"])
        let stats = events.stats
        #expect(stats?.proposalsCount == 4)
        #expect(stats?.droppedCount == 0)
        #expect(stats?.retryUsed == false)
        #expect(stats?.timeToFirstCardMs != nil)
        #expect(backend.researchPrompts.count == 1)
        #expect(backend.judgePrompts == ["O: Learn piano"])
    }

    @Test("A habit is only emitted once it has finished generating")
    func partialSnapshots() async {
        let backend = FakeBackend()
        backend.batches = [.init(snapshots: [
            ResearchSnapshot(criteria: "C", habits: [Fixture.draft("Pra", frequency: nil)]),
            ResearchSnapshot(criteria: "C", habits: [Fixture.draft("Practice", frequency: nil)]),
            ResearchSnapshot(criteria: "C", habits: [Fixture.draft("Practice scales"), Fixture.draft("Li")]),
            ResearchSnapshot(criteria: "C", habits: [Fixture.draft("Practice scales"), Fixture.draft("Listen"), Fixture.draft("Play")]),
        ])]

        let (events, _) = await Fixture.collect(Fixture.service(backend).run(request))
        #expect(events.proposals.map(\.title) == ["Practice scales", "Listen", "Play"])
    }

    @Test("A policing rejection stops before research")
    func policingRejects() async {
        let backend = FakeBackend()
        backend.approve = false
        let (events, error) = await Fixture.collect(Fixture.service(backend).run(request))
        #expect(error as? ObjectiveFailure == .rejected)
        #expect(events.isEmpty)
        #expect(backend.researchPrompts.isEmpty)
    }

    @Test("Guardrail violations and refusals count as rejections; other errors are generic")
    func errorMapping() async {
        let cases: [(ObjectiveBackendError, ObjectiveFailure)] = [
            (.guardrailViolation, .rejected),
            (.refusal, .rejected),
            (.unavailable, .generic),
        ]
        for (backendError, expected) in cases {
            let backend = FakeBackend()
            backend.batches = [.init(snapshots: [], error: backendError)]
            let (_, error) = await Fixture.collect(Fixture.service(backend).run(request))
            #expect(error as? ObjectiveFailure == expected)
        }

        let judgeFails = FakeBackend()
        judgeFails.judgeError = ObjectiveBackendError.guardrailViolation
        let (_, error) = await Fixture.collect(Fixture.service(judgeFails).run(request))
        #expect(error as? ObjectiveFailure == .rejected)
    }

    @Test("Fewer than three habits triggers one retry asking for different habits")
    func retry() async {
        let backend = FakeBackend()
        backend.batches = [
            .init(snapshots: Fixture.streamed(Fixture.drafts(["A one", "B two"]))),
            .init(snapshots: Fixture.streamed(Fixture.drafts(["C three", "D four"]))),
        ]
        let (events, error) = await Fixture.collect(Fixture.service(backend).run(request))
        #expect(error == nil)
        #expect(events.proposals.count == 4)
        #expect(events.stats?.retryUsed == true)
        #expect(backend.researchPrompts.count == 2)
        #expect(backend.researchPrompts[1].contains("MORE"))
        #expect(backend.researchPrompts[1].contains("X: A one, B two"))
    }

    @Test("Short results are kept after the retry; nothing at all is an error")
    func retryOutcomes() async {
        let short = FakeBackend()
        short.batches = [.init(snapshots: Fixture.streamed(Fixture.drafts(["A one", "B two"])))]
        let (events, error) = await Fixture.collect(Fixture.service(short).run(request))
        #expect(error == nil)
        #expect(events.stats?.proposalsCount == 2)

        let empty = FakeBackend()
        let (_, emptyError) = await Fixture.collect(Fixture.service(empty).run(request))
        #expect(emptyError as? ObjectiveFailure == .generic)
        #expect(empty.researchPrompts.count == 2)
    }

    @Test("Dropped habits are counted and earlier titles are excluded")
    func dropsAndExclusions() async {
        var seeded = request
        seeded.proposedTitles = ["Practice scales"]
        let backend = FakeBackend()
        backend.batches = [.init(snapshots: Fixture.streamed([
            Fixture.draft("practice SCALES"),
            Fixture.draft("Skip meals at night"),
            Fixture.draft("Yearly recital", frequency: "yearly"),
            Fixture.draft("A one"), Fixture.draft("B two"), Fixture.draft("C three"),
        ]))]
        let (events, _) = await Fixture.collect(Fixture.service(backend).run(seeded))
        #expect(events.proposals.map(\.title) == ["A one", "B two", "C three"])
        #expect(events.stats?.droppedCount == 3)
        #expect(backend.researchPrompts[0].contains("X: Practice scales"))
    }

    @Test("No more than five habits per batch")
    func cappedAtFive() async {
        let backend = FakeBackend()
        backend.batches = [.init(snapshots: Fixture.streamed(Fixture.drafts((1...7).map { "Habit \($0)" })))]
        let (events, _) = await Fixture.collect(Fixture.service(backend).run(request))
        #expect(events.proposals.count == ObjectiveSuggestionService.maxCount)
    }

    @Test("A context overflow re-seeds once with a compact prompt, without using the retry")
    func contextOverflow() async {
        let backend = FakeBackend()
        backend.batches = [
            .init(snapshots: [], error: ObjectiveBackendError.contextWindowExceeded),
            .init(snapshots: Fixture.streamed(Fixture.drafts(["A one", "B two", "C three"]))),
        ]
        let (events, error) = await Fixture.collect(Fixture.service(backend).run(request))
        #expect(error == nil)
        #expect(events.proposals.count == 3)
        #expect(events.stats?.retryUsed == false)
        #expect(backend.researchPrompts.count == 2)

        let twice = FakeBackend()
        twice.batches = [
            .init(snapshots: [], error: ObjectiveBackendError.contextWindowExceeded),
            .init(snapshots: [], error: ObjectiveBackendError.contextWindowExceeded),
        ]
        let (_, twiceError) = await Fixture.collect(Fixture.service(twice).run(request))
        #expect(twiceError as? ObjectiveFailure == .generic)
    }
}

// MARK: - View model

@Suite("Objectives view model")
@MainActor
struct ObjectivesViewModelTests {
    private func makeViewModel(
        _ generator: FakeGenerator,
        analytics: AnalyticsSpy = AnalyticsSpy()
    ) -> ObjectivesViewModel {
        ObjectivesViewModel(generator: generator, analytics: analytics, isPremium: { true }, measurementSystem: { .imperial })
    }

    private func finish(_ vm: ObjectivesViewModel) async throws {
        try await waitUntil { !vm.isGenerating }
    }

    private static let stats = ObjectiveRunStats(proposalsCount: 3, droppedCount: 1, retryUsed: false, timeToFirstCardMs: 40, totalDurationMs: 90)

    private static func successEvents(_ titles: [String] = ["A one", "B two", "C three"]) -> [ObjectiveStreamEvent] {
        [.criteria("Consistency first.")] + titles.map { .proposal(Fixture.proposal($0)) } + [.finished(stats)]
    }

    @Test("Submitting shows proposals and reports the search without any text")
    func submitSuccess() async throws {
        let generator = FakeGenerator()
        generator.events = Self.successEvents()
        let analytics = AnalyticsSpy()
        let vm = makeViewModel(generator, analytics: analytics)

        vm.inputText = "Learn the piano secretly"
        vm.submit()
        #expect(vm.isGenerating)
        try await finish(vm)

        #expect(vm.phase == .results)
        #expect(vm.submittedObjective == "Learn the piano secretly")
        #expect(vm.criteria == "Consistency first.")
        #expect(vm.proposals.map(\.title) == ["A one", "B two", "C three"])
        #expect(generator.requests.first?.mode == .initial)
        #expect(generator.requests.first?.measurementSystem == .imperial)

        let submitted = try #require(analytics.properties(of: .objectiveSearchSubmitted).first)
        #expect(submitted["input_type"] as? String == "free_text")
        #expect(submitted["mode"] as? String == "initial")
        #expect(submitted["is_premium"] as? String == "true")
        #expect(submitted["preset_id"] == nil)

        let completed = try #require(analytics.properties(of: .objectiveSearchCompleted).first)
        #expect(completed["outcome"] as? String == "success")
        #expect(completed["proposals_count"] as? Int == 3)
        #expect(completed["dropped_count"] as? Int == 1)
        #expect(completed["time_to_first_card_ms"] as? Int == 40)

        // Privacy: no objective, refinement or habit text ever reaches analytics.
        for value in analytics.allValues {
            #expect(!value.contains("piano"))
            #expect(!["A one", "B two", "C three", "Consistency first."].contains(value))
        }
    }

    @Test("Blank input cannot be submitted and input is capped at 200 characters")
    func inputRules() {
        let vm = makeViewModel(FakeGenerator())
        vm.inputText = "   \n "
        #expect(!vm.canSubmit)
        vm.submit()
        #expect(!vm.hasSubmitted)

        vm.inputText = String(repeating: "x", count: 250)
        #expect(vm.inputText.count == 200)
        vm.refineText = String(repeating: "y", count: 250)
        #expect(vm.refineText.count == 200)
    }

    @Test("A preset starts generation straight away and reports its id")
    func preset() async throws {
        let generator = FakeGenerator()
        generator.events = Self.successEvents()
        let analytics = AnalyticsSpy()
        let vm = makeViewModel(generator, analytics: analytics)
        let preset = try #require(ObjectivePresetCatalog.all.first)

        vm.submitPreset(preset)
        try await finish(vm)

        #expect(vm.inputText == preset.localizedTitle)
        #expect(generator.requests.first?.objective == preset.localizedTitle)
        let submitted = try #require(analytics.properties(of: .objectiveSearchSubmitted).first)
        #expect(submitted["input_type"] as? String == "preset")
        #expect(submitted["preset_id"] as? String == preset.id)
    }

    @Test("A rejected objective returns to the input so the user can rephrase")
    func initialRejection() async throws {
        let generator = FakeGenerator()
        generator.error = ObjectiveFailure.rejected
        let analytics = AnalyticsSpy()
        let vm = makeViewModel(generator, analytics: analytics)

        vm.inputText = "Something bad"
        vm.submit()
        try await finish(vm)

        #expect(vm.phase == .rejected)
        #expect(!vm.hasSubmitted)
        #expect(vm.inputText == "Something bad")
        #expect(analytics.properties(of: .objectiveSearchCompleted).first?["outcome"] as? String == "rejected")
    }

    @Test("A rejected refinement keeps the earlier proposals and is not reused")
    func refineRejection() async throws {
        let generator = FakeGenerator()
        generator.events = Self.successEvents()
        let vm = makeViewModel(generator)
        vm.inputText = "Learn piano"
        vm.submit()
        try await finish(vm)

        generator.events = []
        generator.error = ObjectiveFailure.rejected
        vm.refineText = "bad detail"
        vm.refine()
        try await finish(vm)

        #expect(vm.phase == .rejected)
        #expect(vm.proposals.count == 3)
        #expect(vm.refinements.isEmpty)
        #expect(vm.refineText == "bad detail")
        #expect(generator.requests.last?.refinements == ["bad detail"])
        #expect(generator.requests.last?.mode == .refine)
    }

    @Test("Refine and Generate more are seeded with the history and earlier titles")
    func refineAndMore() async throws {
        let generator = FakeGenerator()
        generator.events = Self.successEvents()
        let analytics = AnalyticsSpy()
        let vm = makeViewModel(generator, analytics: analytics)
        vm.inputText = "Learn piano"
        vm.submit()
        try await finish(vm)

        generator.events = Self.successEvents(["D four", "E five", "F six"])
        vm.refineText = "Only 10 minutes"
        vm.refine()
        try await finish(vm)
        #expect(vm.refinements == ["Only 10 minutes"])
        #expect(vm.refineText.isEmpty)
        #expect(generator.requests[1].proposedTitles == ["A one", "B two", "C three"])
        #expect(generator.requests[1].refinements == ["Only 10 minutes"])

        generator.events = Self.successEvents(["G seven", "H eight", "I nine"])
        vm.generateMore()
        try await finish(vm)
        #expect(generator.requests[2].mode == .more)
        #expect(generator.requests[2].refinements == ["Only 10 minutes"])
        #expect(generator.requests[2].proposedTitles.count == 6)
        #expect(vm.proposals.count == 9)
        #expect(vm.lastMode == .more)
        #expect(analytics.properties(of: .objectiveSearchSubmitted).compactMap { $0["mode"] as? String } == ["initial", "refine", "more"])
    }

    @Test("A generic failure offers a retry of the same request")
    func failureAndRetry() async throws {
        let generator = FakeGenerator()
        generator.error = ObjectiveFailure.generic
        let analytics = AnalyticsSpy()
        let vm = makeViewModel(generator, analytics: analytics)
        vm.inputText = "Learn piano"
        vm.submit()
        try await finish(vm)

        #expect(vm.phase == .failed)
        #expect(vm.hasSubmitted)
        #expect(analytics.properties(of: .objectiveSearchCompleted).first?["outcome"] as? String == "error")

        generator.error = nil
        generator.events = Self.successEvents()
        vm.retry()
        try await finish(vm)
        #expect(vm.phase == .results)
        #expect(generator.requests.count == 2)
        #expect(generator.requests[1].mode == .initial)
    }

    @Test("Skeletons fill the gap to three cards while generating")
    func skeletons() async throws {
        let generator = FakeGenerator()
        generator.holdsStream = true
        let vm = makeViewModel(generator)
        #expect(vm.skeletonCount == 0)

        vm.inputText = "Learn piano"
        vm.submit()
        #expect(vm.skeletonCount == 3)

        try await waitUntil { generator.openContinuation != nil }
        generator.openContinuation?.yield(.proposal(Fixture.proposal("A one")))
        try await waitUntil { vm.proposals.count == 1 }
        #expect(vm.skeletonCount == 2)

        generator.openContinuation?.yield(.proposal(Fixture.proposal("B two")))
        generator.openContinuation?.yield(.proposal(Fixture.proposal("C three")))
        generator.openContinuation?.yield(.proposal(Fixture.proposal("D four")))
        try await waitUntil { vm.proposals.count == 4 }
        #expect(vm.skeletonCount == 1)

        generator.openContinuation?.yield(.finished(Self.stats))
        generator.openContinuation?.finish()
        try await finish(vm)
        #expect(vm.skeletonCount == 0)
    }

    @Test("Added proposals are marked, and New search resets everything")
    func addedAndNewSearch() async throws {
        let generator = FakeGenerator()
        generator.events = Self.successEvents()
        let analytics = AnalyticsSpy()
        let vm = makeViewModel(generator, analytics: analytics)
        vm.onAppear()
        #expect(generator.prewarmCount == 1)

        vm.inputText = "Learn piano"
        vm.submit()
        try await finish(vm)
        #expect(vm.showsNewSearch)

        let first = try #require(vm.proposals.first)
        vm.markAdded(id: first.id)
        #expect(vm.proposals.first?.isAdded == true)
        #expect(vm.addedCount == 1)

        vm.newSearch()
        #expect(!vm.hasSubmitted)
        #expect(vm.proposals.isEmpty)
        #expect(vm.inputText.isEmpty)
        #expect(vm.criteria == nil)
        #expect(vm.phase == .idle)
        #expect(generator.resetCount == 1)
        #expect(analytics.properties(of: .objectiveNewSearchTapped).first?["proposals_added_count"] as? Int == 1)

        vm.onDisappear()
        #expect(generator.resetCount == 2)
    }
}

// MARK: - Entry point

@Suite("Objectives entry point")
@MainActor
struct ObjectivesEntryTests {
    @Test("With objectives available, + opens the options sheet")
    func availableOpensSheet() throws {
        let analytics = AnalyticsSpy()
        let vm = TaskListViewModel()
        vm.handleAddTapped(currentHabitCount: 0, isPremium: false, objectivesAvailable: true, analytics: analytics)
        #expect(vm.showingAddOptions)
        #expect(!vm.showingTaskSelector)
        let tapped = try #require(analytics.properties(of: .addHabitTapped).first)
        #expect(tapped["objectives_available"] as? String == "true")
    }

    @Test("Without objectives, + opens today's selector")
    func unavailableOpensSelector() throws {
        let analytics = AnalyticsSpy()
        let vm = TaskListViewModel()
        vm.handleAddTapped(currentHabitCount: 0, isPremium: false, objectivesAvailable: false, analytics: analytics)
        #expect(vm.showingTaskSelector)
        #expect(!vm.showingAddOptions)
        #expect(analytics.properties(of: .addHabitTapped).first?["objectives_available"] as? String == "false")
    }

    @Test("At the free limit the paywall comes first, then the options sheet after unlocking")
    func paywallFirst() {
        let vm = TaskListViewModel()
        vm.handleAddTapped(currentHabitCount: FreemiumConfig.freeHabitLimit, isPremium: false, objectivesAvailable: true)
        #expect(vm.showingPaywall)
        #expect(!vm.showingAddOptions)

        vm.showingPaywall = false
        vm.premiumUnlocked = true
        vm.handlePaywallDismissed(objectivesAvailable: true)
        #expect(vm.showingAddOptions)
    }

    @Test("The chosen option opens only after the sheet has dismissed")
    func optionAfterDismiss() throws {
        let analytics = AnalyticsSpy()
        let vm = TaskListViewModel()
        vm.showingAddOptions = true

        vm.selectAddOption(.objective, analytics: analytics)
        #expect(!vm.showingAddOptions)
        #expect(!vm.showingObjectives)
        vm.performPendingAddOption()
        #expect(vm.showingObjectives)
        #expect(analytics.properties(of: .objectiveOptionSelected).first?["option"] as? String == "objective")

        vm.showingObjectives = false
        vm.selectAddOption(.habit)
        vm.performPendingAddOption()
        #expect(vm.showingTaskSelector)
        #expect(!vm.showingObjectives)

        vm.showingTaskSelector = false
        vm.performPendingAddOption()
        #expect(!vm.showingTaskSelector)
    }
}

// MARK: - Carousel

@Suite("Objectives preset carousel")
struct ObjectivePresetCarouselTests {
    @Test("Auto-scroll stops for Reduce Motion, VoiceOver and once the user drags")
    func autoScrollRules() {
        #expect(ObjectivePresetCarousel.autoScrolls(reduceMotion: false, voiceOverEnabled: false, userTookOver: false))
        #expect(!ObjectivePresetCarousel.autoScrolls(reduceMotion: true, voiceOverEnabled: false, userTookOver: false))
        #expect(!ObjectivePresetCarousel.autoScrolls(reduceMotion: false, voiceOverEnabled: true, userTookOver: false))
        #expect(!ObjectivePresetCarousel.autoScrolls(reduceMotion: false, voiceOverEnabled: false, userTookOver: true))
    }

    @Test("The loop wraps seamlessly")
    func wrappedOffset() {
        #expect(ObjectivePresetCarousel.wrappedOffset(elapsed: 0, speed: 30, loopWidth: 300) == 0)
        #expect(ObjectivePresetCarousel.wrappedOffset(elapsed: 2, speed: 30, loopWidth: 300) == -60)
        #expect(ObjectivePresetCarousel.wrappedOffset(elapsed: 11, speed: 30, loopWidth: 300) == -30)
        #expect(ObjectivePresetCarousel.wrappedOffset(elapsed: 5, speed: 30, loopWidth: 0) == 0)
    }
}

// MARK: - Localization

@Suite("Objectives localization")
struct ObjectivesLocalizationTests {
    @Test("Objectives UI strings are translated in every language")
    func uiStringsPresent() throws {
        let required = [
            "Add habit", "Create a single custom habit", "Add from objective",
            "Get habit suggestions to reach an objective", "Describe what you want to achieve",
            "I want to...", "Get habits", "Suggestions are generated on your iPhone", "Refine",
            "Generate more", "New search", "Added", "We cannot suggest anything for that request",
            "Something went wrong. Try again.", "Try again", "%lld times",
        ]
        for language in Fixture.languages {
            let strings = try Fixture.lproj(language, table: "Localizable")
            for key in required {
                let value = try #require(strings[key], "\(language) is missing \(key)")
                if language != "en" && key != "Refine" {
                    #expect(value != key, "\(language) leaves \(key) untranslated")
                }
            }
            #expect(strings["%lld times"]?.contains("%lld") == true)
        }
    }
}
