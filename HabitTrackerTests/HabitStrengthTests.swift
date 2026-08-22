import Testing
import Foundation
import SwiftData
@testable import HabitTracker

// MARK: - Fixtures

private enum StrengthFixture {
    static let calendar = Calendar.current

    static func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 12) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    /// Builds an unpersisted habit. Unlike the shared `TestData.task`, `createdAt` is
    /// settable: the consistency window is clamped to it, so it changes the score.
    static func task(
        frequency: FrequencyType = .daily,
        n: Int = 1,
        tracking: TrackingMode = .eachCompletion,
        scheduledDays: [Int] = [1, 2, 3, 4, 5, 6, 7],
        createdAt: Date,
        completions: [Date] = []
    ) -> HabitTask {
        let task = HabitTask(
            title: "Test",
            frequencyType: frequency,
            timesPerPeriod: n,
            tracking: tracking,
            scheduledDays: scheduledDays,
            createdAt: createdAt
        )
        for date in completions {
            task.completions.append(TaskCompletion(completedAt: date, task: task))
        }
        return task
    }

    /// `count` consecutive daily completions ending on `endingOn` (inclusive).
    static func consecutiveDays(endingOn endDate: Date, count: Int) -> [Date] {
        (0..<count).compactMap { calendar.date(byAdding: .day, value: -$0, to: endDate) }
    }

    static func container() throws -> ModelContainer {
        try ModelContainer(
            for: HabitTask.self, TaskCompletion.self, Category.self, AppSettings.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }
}

// MARK: - Stage mapping

@Suite("HabitStage")
struct HabitStageTests {
    @Test("Score boundaries map to the PRD stage table")
    func scoreBoundaries() {
        #expect(HabitStage.stage(forScore: 0) == .starting)
        #expect(HabitStage.stage(forScore: 19) == .starting)
        #expect(HabitStage.stage(forScore: 20) == .developing)
        #expect(HabitStage.stage(forScore: 39) == .developing)
        #expect(HabitStage.stage(forScore: 40) == .building)
        #expect(HabitStage.stage(forScore: 59) == .building)
        #expect(HabitStage.stage(forScore: 60) == .strong)
        #expect(HabitStage.stage(forScore: 79) == .strong)
        #expect(HabitStage.stage(forScore: 80) == .established)
        #expect(HabitStage.stage(forScore: 94) == .established)
        #expect(HabitStage.stage(forScore: 95) == .mastering)
        #expect(HabitStage.stage(forScore: 100) == .mastering)
    }

    @Test("Out-of-range scores are clamped rather than crashing")
    func clamping() {
        #expect(HabitStage.stage(forScore: -10) == .starting)
        #expect(HabitStage.stage(forScore: 500) == .mastering)
    }

    @Test("Stages are ordered along the formation path")
    func ordering() {
        #expect(HabitStage.allCases == [
            .starting, .developing, .building, .strong, .established, .mastering,
        ])
        #expect(HabitStage.allCases == HabitStage.allCases.sorted())
        #expect(HabitStage.starting < HabitStage.mastering)
        #expect(max(HabitStage.building, .strong) == .strong)
    }

    @Test("Badge is hidden at Starting and prominent from Strong")
    func badgeRules() {
        #expect(!HabitStage.starting.showsDashboardBadge)
        #expect(HabitStage.developing.showsDashboardBadge)
        #expect(!HabitStage.building.isProminentBadge)
        #expect(HabitStage.strong.isProminentBadge)
        #expect(HabitStage.mastering.isProminentBadge)
    }

    @Test("Every stage has copy and a distinct symbol")
    func presentation() {
        let symbols = HabitStage.allCases.map(\.sfSymbolName)
        #expect(Set(symbols).count == HabitStage.allCases.count)
        for stage in HabitStage.allCases {
            #expect(!stage.displayName.isEmpty)
            #expect(!StageCelebrationCopy.forStage(stage).title.isEmpty)
            #expect(!StageCelebrationCopy.forStage(stage).body.isEmpty)
        }
    }
}

// MARK: - Formula

@Suite("HabitStrengthService formula")
struct HabitStrengthFormulaTests {
    private let cal = Calendar.current

    /// The worked example from PRD §7: N=40 and 24 of the last 28 days should
    /// produce 73. This is the anchor test — if the constants or the rounding ever
    /// drift, this is what catches it.
    @Test("PRD worked example: N=40, 24/28 consistency -> 73")
    func prdWorkedExample() {
        let reference = StrengthFixture.date(2026, 2, 11)

        // 24 completions inside the 28-day window (Jan 15 - Feb 11).
        var completions = StrengthFixture.consecutiveDays(
            endingOn: StrengthFixture.date(2026, 2, 7), count: 24
        )
        // 16 more before the window, for 40 credited completions in total.
        completions += StrengthFixture.consecutiveDays(
            endingOn: StrengthFixture.date(2025, 12, 16), count: 16
        )

        let task = StrengthFixture.task(
            createdAt: StrengthFixture.date(2025, 11, 1),
            completions: completions
        )

        let strength = HabitStrengthService.strength(
            for: task, on: reference, calendar: cal, weekStartDay: 1
        )

        #expect(strength.totalCompletions == 40)
        #expect(abs(strength.consistency - 24.0 / 28.0) < 0.0001)
        #expect(abs(strength.repetition - (1 - exp(-1.0))) < 0.0001)
        #expect(strength.score == 73)
        #expect(strength.stage == .strong)
    }

    @Test("A habit with no completions scores zero and stays in Starting")
    func emptyHistory() {
        let task = StrengthFixture.task(createdAt: StrengthFixture.date(2026, 1, 1))
        let strength = HabitStrengthService.strength(
            for: task, on: StrengthFixture.date(2026, 2, 11), calendar: cal
        )
        #expect(strength.score == 0)
        #expect(strength.stage == .starting)
        #expect(!strength.isEligible)
    }

    @Test("A perfect long history approaches but never exceeds 100")
    func perfectHistoryIsBounded() {
        let reference = StrengthFixture.date(2026, 2, 11)
        let task = StrengthFixture.task(
            createdAt: StrengthFixture.date(2024, 1, 1),
            completions: StrengthFixture.consecutiveDays(endingOn: reference, count: 600)
        )
        let strength = HabitStrengthService.strength(
            for: task, on: reference, calendar: cal
        )
        #expect(strength.score == 100)
        #expect(strength.consistency == 1.0)
        #expect(strength.stage == .mastering)
    }

    @Test("Backfilled extra completions cannot push consistency above 1")
    func consistencyIsCapped() {
        let reference = StrengthFixture.date(2026, 2, 11)
        // Two completions a day on a once-a-day habit — possible via the calendar
        // editor, which is exactly why the cap exists.
        var completions = StrengthFixture.consecutiveDays(endingOn: reference, count: 40)
        completions += StrengthFixture.consecutiveDays(endingOn: reference, count: 40)

        let task = StrengthFixture.task(
            frequency: .weekly,
            n: 1,
            tracking: .eachCompletion,
            createdAt: StrengthFixture.date(2025, 6, 1),
            completions: completions
        )
        let strength = HabitStrengthService.strength(for: task, on: reference, calendar: cal)
        #expect(strength.consistency == 1.0)
        #expect(strength.score <= 100)
    }

    @Test("N counts credited completions, so a 3x-daily habit is not three times faster")
    func creditedNotRawRepetitions() {
        let reference = StrengthFixture.date(2026, 2, 11)
        let days = StrengthFixture.consecutiveDays(endingOn: reference, count: 10)
        // Three completions on each of ten days: daily habits are forced to
        // periodComplete, so that is ten repetitions, not thirty.
        let completions = days.flatMap { day in
            [8, 12, 18].compactMap {
                Calendar.current.date(bySettingHour: $0, minute: 0, second: 0, of: day)
            }
        }
        let task = StrengthFixture.task(
            frequency: .daily,
            n: 3,
            createdAt: StrengthFixture.date(2026, 1, 1),
            completions: completions
        )
        let strength = HabitStrengthService.strength(for: task, on: reference, calendar: cal)
        #expect(strength.totalCompletions == 10)
    }
}

// MARK: - Eligibility

@Suite("HabitStrength eligibility")
struct HabitStrengthEligibilityTests {
    private let cal = Calendar.current

    @Test("Below three completions the habit is ineligible and pinned to Starting")
    func belowThreshold() {
        let reference = StrengthFixture.date(2026, 2, 11)
        for count in 0...2 {
            let task = StrengthFixture.task(
                createdAt: StrengthFixture.date(2026, 2, 1),
                completions: StrengthFixture.consecutiveDays(endingOn: reference, count: count)
            )
            let strength = HabitStrengthService.strength(for: task, on: reference, calendar: cal)
            #expect(!strength.isEligible)
            #expect(strength.stage == .starting)
        }
    }

    @Test("The third completion makes the habit eligible")
    func atThreshold() {
        let reference = StrengthFixture.date(2026, 2, 11)
        let task = StrengthFixture.task(
            createdAt: StrengthFixture.date(2026, 2, 1),
            completions: StrengthFixture.consecutiveDays(endingOn: reference, count: 3)
        )
        let strength = HabitStrengthService.strength(for: task, on: reference, calendar: cal)
        #expect(strength.isEligible)
        #expect(strength.totalCompletions == 3)
    }

    @Test("Completions backfilled onto days before the habit was created still count")
    func backfillBeforeCreationCounts() {
        // `ManageCompletionsView` accepts any past day, so this is reachable for a
        // habit created today whose history was filled in afterwards.
        let reference = StrengthFixture.date(2026, 2, 11)
        let task = StrengthFixture.task(
            createdAt: reference,
            completions: StrengthFixture.consecutiveDays(
                endingOn: StrengthFixture.date(2026, 2, 5), count: 4
            )
        )

        let strength = HabitStrengthService.strength(for: task, on: reference, calendar: cal)
        #expect(strength.totalCompletions == 4)
        #expect(strength.isEligible)
    }

    @Test("History start is the earlier of creation and the first completion")
    func historyStartPrecedesCreation() {
        let created = StrengthFixture.date(2026, 2, 11)
        let backfilled = StrengthFixture.date(2026, 2, 2)
        let task = StrengthFixture.task(createdAt: created, completions: [backfilled])

        #expect(task.historyStart(calendar: cal) == cal.startOfDay(for: backfilled))

        let untouched = StrengthFixture.task(createdAt: created)
        #expect(untouched.historyStart(calendar: cal) == cal.startOfDay(for: created))
    }
}

// MARK: - Consistency window

@Suite("Consistency window")
struct ConsistencyWindowTests {
    private let cal = Calendar.current

    @Test("A daily habit uses a 28-day window")
    func dailyWindowIs28Days() {
        let task = StrengthFixture.task(createdAt: StrengthFixture.date(2025, 1, 1))
        let window = HabitStrengthService.consistencyWindow(
            for: task, endingOn: StrengthFixture.date(2026, 2, 11), calendar: cal
        )
        let days = cal.dateComponents([.day], from: window.start, to: window.end).day
        #expect(days == 27) // 28 inclusive calendar days
        #expect(cal.startOfDay(for: window.start) == StrengthFixture.date(2026, 1, 15, hour: 0))
    }

    @Test("A monthly habit widens the window to three periods")
    func monthlyWindowWidensToThreePeriods() {
        let task = StrengthFixture.task(
            frequency: .monthly, n: 1, createdAt: StrengthFixture.date(2024, 1, 1)
        )
        let window = HabitStrengthService.consistencyWindow(
            for: task, endingOn: StrengthFixture.date(2026, 2, 11), calendar: cal
        )
        // Three monthly periods back from February is the start of December.
        #expect(window.start == StrengthFixture.date(2025, 12, 1, hour: 0))
    }

    @Test("The window never reaches back before the habit existed")
    func windowClampsToCreatedAt() {
        let created = StrengthFixture.date(2026, 2, 8)
        let task = StrengthFixture.task(createdAt: created)
        let window = HabitStrengthService.consistencyWindow(
            for: task, endingOn: StrengthFixture.date(2026, 2, 11), calendar: cal
        )
        #expect(window.start == cal.startOfDay(for: created))
    }

    /// The regression this clamp exists for: a young habit judged against 28
    /// opportunities that never existed could never leave Starting.
    @Test("A four-day-old habit completed every day scores full consistency")
    func youngHabitIsNotPunished() {
        let reference = StrengthFixture.date(2026, 2, 11)
        let task = StrengthFixture.task(
            createdAt: StrengthFixture.date(2026, 2, 8),
            completions: StrengthFixture.consecutiveDays(endingOn: reference, count: 4)
        )
        let strength = HabitStrengthService.strength(for: task, on: reference, calendar: cal)
        #expect(strength.consistency == 1.0)
    }
}

// MARK: - Projections

@Suite("HabitStrength projections")
struct HabitStrengthProjectionTests {
    private let cal = Calendar.current

    @Test("Projecting a completion never lowers the score, and inserts nothing")
    func completionProjectionIsPureAndMonotonic() {
        let reference = StrengthFixture.date(2026, 2, 11)
        let task = StrengthFixture.task(
            createdAt: StrengthFixture.date(2026, 1, 1),
            completions: StrengthFixture.consecutiveDays(
                endingOn: StrengthFixture.date(2026, 2, 10), count: 20
            )
        )
        let before = task.completions.count
        let current = HabitStrengthService.strength(for: task, on: reference, calendar: cal)
        let projected = HabitStrengthService.projectedStrength(
            for: task, assumingCompletionOn: reference, calendar: cal
        )

        #expect(projected.score >= current.score)
        #expect(projected.totalCompletions == current.totalCompletions + 1)
        #expect(task.completions.count == before)
    }

    @Test("A period already at quota projects no change")
    func completedPeriodProjectsNoChange() {
        let reference = StrengthFixture.date(2026, 2, 11)
        var completions = StrengthFixture.consecutiveDays(
            endingOn: StrengthFixture.date(2026, 2, 10), count: 20
        )
        completions.append(reference) // today is already done
        let task = StrengthFixture.task(
            createdAt: StrengthFixture.date(2026, 1, 1), completions: completions
        )

        let current = HabitStrengthService.strength(for: task, on: reference, calendar: cal)
        let projected = HabitStrengthService.projectedStrength(
            for: task, assumingCompletionOn: reference, calendar: cal
        )
        #expect(projected == current)
    }

    @Test("A partial periodComplete period earns credit only on the closing completion")
    func periodCompleteCreditsOnlyOnQuota() {
        let reference = StrengthFixture.date(2026, 2, 11)
        // Weekly quota of 3 with 1 done: the next completion should not credit yet.
        let task = StrengthFixture.task(
            frequency: .weekly,
            n: 3,
            tracking: .periodComplete,
            createdAt: StrengthFixture.date(2025, 6, 1),
            completions: [StrengthFixture.date(2026, 2, 9)]
        )
        let current = HabitStrengthService.strength(for: task, on: reference, calendar: cal)
        let afterOne = HabitStrengthService.projectedStrength(
            for: task, assumingCompletionOn: reference, calendar: cal
        )
        #expect(afterOne.totalCompletions == current.totalCompletions)

        // With 2 of 3 done, the next completion closes the period and credits 1.
        task.completions.append(
            TaskCompletion(completedAt: StrengthFixture.date(2026, 2, 10), task: task)
        )
        let closing = HabitStrengthService.projectedStrength(
            for: task, assumingCompletionOn: reference, calendar: cal
        )
        #expect(closing.totalCompletions == current.totalCompletions + 1)
    }

    @Test("Projecting a miss never raises the score")
    func missProjectionIsMonotonic() {
        let reference = StrengthFixture.date(2026, 2, 11)
        let task = StrengthFixture.task(
            createdAt: StrengthFixture.date(2025, 12, 1),
            completions: StrengthFixture.consecutiveDays(endingOn: reference, count: 40)
        )
        let current = HabitStrengthService.strength(for: task, on: reference, calendar: cal)
        let tomorrow = cal.date(byAdding: .day, value: 1, to: reference)!
        let afterMiss = HabitStrengthService.projectedStrengthAssumingMiss(
            for: task, on: tomorrow, calendar: cal
        )
        #expect(afterMiss.score <= current.score)
    }
}

// MARK: - Cache

@Suite("HabitStrengthCache")
@MainActor
struct HabitStrengthCacheTests {
    @Test("Repeated reads for the same day are memoised")
    func memoises() {
        let cache = HabitStrengthCache()
        let reference = StrengthFixture.date(2026, 2, 11)
        let task = StrengthFixture.task(
            createdAt: StrengthFixture.date(2026, 1, 1),
            completions: StrengthFixture.consecutiveDays(endingOn: reference, count: 10)
        )

        let first = cache.strength(for: task, on: reference)
        #expect(cache.entryCount == 1)
        let second = cache.strength(for: task, on: reference)
        #expect(cache.entryCount == 1)
        #expect(first == second)
    }

    @Test("Invalidating one habit leaves the others cached")
    func invalidateIsScoped() {
        let cache = HabitStrengthCache()
        let reference = StrengthFixture.date(2026, 2, 11)
        let created = StrengthFixture.date(2026, 1, 1)
        let a = StrengthFixture.task(createdAt: created)
        let b = StrengthFixture.task(createdAt: created)

        _ = cache.strength(for: a, on: reference)
        _ = cache.strength(for: b, on: reference)
        #expect(cache.entryCount == 2)

        cache.invalidate(taskID: a.id)
        #expect(cache.entryCount == 1)
    }

    @Test("Invalidation bumps the generation so views recompute")
    func generationChanges() {
        let cache = HabitStrengthCache()
        let task = StrengthFixture.task(createdAt: StrengthFixture.date(2026, 1, 1))
        _ = cache.strength(for: task, on: StrengthFixture.date(2026, 2, 11))

        let before = cache.generation
        cache.invalidate(taskID: task.id)
        #expect(cache.generation > before)

        cache.invalidateAll()
        #expect(cache.entryCount == 0)
    }

    @Test("A new completion changes the cached value only after invalidation")
    func staleUntilInvalidated() {
        let cache = HabitStrengthCache()
        let reference = StrengthFixture.date(2026, 2, 11)
        let task = StrengthFixture.task(
            createdAt: StrengthFixture.date(2026, 1, 1),
            completions: StrengthFixture.consecutiveDays(
                endingOn: StrengthFixture.date(2026, 2, 10), count: 10
            )
        )
        let before = cache.strength(for: task, on: reference)

        task.completions.append(TaskCompletion(completedAt: reference, task: task))
        #expect(cache.strength(for: task, on: reference) == before)

        cache.invalidate(taskID: task.id)
        #expect(cache.strength(for: task, on: reference).totalCompletions == before.totalCompletions + 1)
    }
}

// MARK: - Stage evaluator

@Suite("HabitStageEvaluator")
@MainActor
struct HabitStageEvaluatorTests {

    @Test("A habit at its recorded stage produces no transition")
    func noTransitionWhenStable() throws {
        let container = try StrengthFixture.container()
        let context = container.mainContext
        let cache = HabitStrengthCache()
        let now = Date.now

        let task = StrengthFixture.task(
            createdAt: StrengthFixture.date(2026, 1, 1),
            completions: StrengthFixture.consecutiveDays(endingOn: now, count: 12)
        )
        context.insert(task)

        let stage = cache.strength(for: task, on: now, weekStartDay: 1).stage
        task.lastObservedStage = stage
        task.lastCelebratedStage = stage

        let transitions = HabitStageEvaluator.evaluate(
            tasks: [task], context: context, cache: cache, weekStartDay: 1, now: now
        )
        #expect(transitions.isEmpty)
    }

    @Test("An advance is reported, celebratable, and recorded on the habit")
    func advanceIsReported() throws {
        let container = try StrengthFixture.container()
        let context = container.mainContext
        let cache = HabitStrengthCache()
        let now = Date.now

        let task = StrengthFixture.task(
            createdAt: StrengthFixture.date(2026, 1, 1),
            completions: StrengthFixture.consecutiveDays(endingOn: now, count: 12)
        )
        context.insert(task)
        task.lastObservedStage = .starting
        task.lastCelebratedStage = .starting

        let transitions = HabitStageEvaluator.evaluate(
            tasks: [task], context: context, cache: cache, weekStartDay: 1, now: now
        )

        #expect(transitions.count == 1)
        let transition = try #require(transitions.first)
        #expect(transition.isAdvance)
        #expect(transition.isCelebratable)
        #expect(task.lastObservedStage == transition.to)
        #expect(task.strengthEvaluatedAt != nil)
    }

    @Test("A reversion is reported but never celebrated")
    func reversionIsNotCelebratable() throws {
        let container = try StrengthFixture.container()
        let context = container.mainContext
        let cache = HabitStrengthCache()
        let now = Date.now

        let task = StrengthFixture.task(createdAt: StrengthFixture.date(2026, 1, 1))
        context.insert(task)
        task.lastObservedStage = .strong
        task.lastCelebratedStage = .strong

        let transitions = HabitStageEvaluator.evaluate(
            tasks: [task], context: context, cache: cache, weekStartDay: 1, now: now
        )

        let transition = try #require(transitions.first)
        #expect(!transition.isAdvance)
        #expect(!transition.isCelebratable)
    }

    @Test("Evaluation is idempotent within a day unless forced")
    func idempotentPerDay() throws {
        let container = try StrengthFixture.container()
        let context = container.mainContext
        let cache = HabitStrengthCache()
        let now = Date.now

        let task = StrengthFixture.task(
            createdAt: StrengthFixture.date(2026, 1, 1),
            completions: StrengthFixture.consecutiveDays(endingOn: now, count: 12)
        )
        context.insert(task)
        task.lastObservedStage = .starting
        task.lastCelebratedStage = .starting

        #expect(HabitStageEvaluator.evaluate(
            tasks: [task], context: context, cache: cache, weekStartDay: 1, now: now
        ).count == 1)

        // Second pass on the same day: already evaluated, nothing to report.
        task.lastObservedStage = .starting
        #expect(HabitStageEvaluator.evaluate(
            tasks: [task], context: context, cache: cache, weekStartDay: 1, now: now
        ).isEmpty)

        // Forced, as after a completion: re-evaluated regardless.
        #expect(HabitStageEvaluator.evaluate(
            tasks: [task], context: context, cache: cache, weekStartDay: 1, now: now, force: true
        ).count == 1)
    }

    @Test("An advance that was never celebrated is re-offered")
    func uncelebratedAdvanceIsReoffered() throws {
        let container = try StrengthFixture.container()
        let context = container.mainContext
        let cache = HabitStrengthCache()
        let now = Date.now

        let task = StrengthFixture.task(
            createdAt: StrengthFixture.date(2026, 1, 1),
            completions: StrengthFixture.consecutiveDays(endingOn: now, count: 12)
        )
        context.insert(task)

        let stage = cache.strength(for: task, on: now, weekStartDay: 1).stage
        #expect(stage > .starting)
        // Observed already caught up, but the celebration never reached the screen.
        task.lastObservedStage = stage
        task.lastCelebratedStage = .starting

        let transitions = HabitStageEvaluator.evaluate(
            tasks: [task], context: context, cache: cache, weekStartDay: 1, now: now
        )
        let transition = try #require(transitions.first)
        #expect(transition.to == stage)
        #expect(transition.isCelebratable)
    }

    @Test("Celebrating raises the high-water mark and suppresses a repeat")
    func celebrationIsRecordedOnce() throws {
        let container = try StrengthFixture.container()
        let context = container.mainContext
        let cache = HabitStrengthCache()
        let now = Date.now

        let task = StrengthFixture.task(
            createdAt: StrengthFixture.date(2026, 1, 1),
            completions: StrengthFixture.consecutiveDays(endingOn: now, count: 12)
        )
        context.insert(task)
        task.lastObservedStage = .starting
        task.lastCelebratedStage = .starting

        let transition = try #require(HabitStageEvaluator.evaluate(
            tasks: [task], context: context, cache: cache, weekStartDay: 1, now: now
        ).first)
        HabitStageEvaluator.markCelebrated(transition, context: context, now: now)

        #expect(task.lastCelebratedStage == transition.to)
        #expect(task.lastCelebratedAt != nil)

        // The same advance offered again is no longer celebratable.
        task.lastObservedStage = transition.from
        let repeated = try #require(HabitStageEvaluator.evaluate(
            tasks: [task], context: context, cache: cache, weekStartDay: 1, now: now, force: true
        ).first)
        #expect(!repeated.isCelebratable)
    }

    @Test("The high-water mark never decreases")
    func highWaterMarkOnlyRises() throws {
        let container = try StrengthFixture.container()
        let context = container.mainContext
        let task = StrengthFixture.task(createdAt: StrengthFixture.date(2026, 1, 1))
        context.insert(task)
        task.lastCelebratedStage = .established

        let downward = HabitStageEvaluator.Transition(
            task: task, from: .established, to: .building, isCelebratable: false
        )
        HabitStageEvaluator.markCelebrated(downward, context: context)
        #expect(task.lastCelebratedStage == .established)
    }
}

// MARK: - Migration backfill

@Suite("Habit strength migration backfill")
@MainActor
struct HabitStrengthMigrationTests {

    @Test("Existing habits are seeded at their current stage, with nothing to celebrate")
    func seedsSilently() throws {
        let container = try StrengthFixture.container()
        let context = container.mainContext
        let now = Date.now

        let task = StrengthFixture.task(
            createdAt: StrengthFixture.date(2025, 1, 1),
            completions: StrengthFixture.consecutiveDays(endingOn: now, count: 120)
        )
        context.insert(task)

        MigrationService.normalizeIfNeeded(context: context)

        let expected = HabitStrengthService.strength(for: task, on: now, weekStartDay: 1).stage
        #expect(expected > .starting) // otherwise the test proves nothing
        #expect(task.lastObservedStage == expected)
        #expect(task.lastCelebratedStage == expected)
        #expect(task.strengthEvaluatedAt != nil)
        // No celebration was actually shown, so this stays unset.
        #expect(task.lastCelebratedAt == nil)
        #expect(AppSettings.shared(in: context).hasSeededHabitStrength)
    }

    /// The regression the backfill exists to prevent: an existing user opening the
    /// app after the update must not be walked through every stage at once.
    @Test("No celebrations fire on the first evaluation after backfill")
    func noCelebrationStormAfterUpgrade() throws {
        let container = try StrengthFixture.container()
        let context = container.mainContext
        let cache = HabitStrengthCache()
        let now = Date.now

        for _ in 0..<3 {
            context.insert(StrengthFixture.task(
                createdAt: StrengthFixture.date(2025, 1, 1),
                completions: StrengthFixture.consecutiveDays(endingOn: now, count: 200)
            ))
        }

        MigrationService.normalizeIfNeeded(context: context)

        let tasks = try context.fetch(FetchDescriptor<HabitTask>())
        let transitions = HabitStageEvaluator.evaluate(
            tasks: tasks, context: context, cache: cache, weekStartDay: 1, now: now, force: true
        )
        #expect(transitions.isEmpty)
    }

    @Test("Backfill runs once: later habits are not retro-seeded")
    func runsOnce() throws {
        let container = try StrengthFixture.container()
        let context = container.mainContext

        context.insert(StrengthFixture.task(createdAt: StrengthFixture.date(2025, 1, 1)))
        MigrationService.normalizeIfNeeded(context: context)

        let newcomer = StrengthFixture.task(createdAt: .now)
        context.insert(newcomer)
        MigrationService.normalizeIfNeeded(context: context)

        // A habit created after the backfill is left alone, so its first genuine
        // advance is still celebrated.
        #expect(newcomer.lastObservedStage == nil)
        #expect(newcomer.lastCelebratedStage == nil)
    }
}

// MARK: - Notification identifiers

@Suite("Strength notification identifiers")
struct StrengthNotificationIdentifierTests {
    @Test("A habit ID round-trips through a strength identifier")
    func roundTrip() {
        let id = UUID()
        for kind in NotificationService.StrengthNotificationKind.allCases {
            let identifier = "strength-\(id.uuidString)-\(kind.rawValue)"
            #expect(NotificationService.taskID(fromStrengthIdentifier: identifier) == id)
        }
    }

    @Test("Reminder and malformed identifiers are rejected")
    func rejectsOtherIdentifiers() {
        let id = UUID()
        #expect(NotificationService.taskID(fromStrengthIdentifier: "task-\(id.uuidString)-day-3") == nil)
        #expect(NotificationService.taskID(fromStrengthIdentifier: "strength-not-a-uuid") == nil)
        #expect(NotificationService.taskID(fromStrengthIdentifier: "") == nil)
    }

    @Test("Both kinds are covered when cancelling")
    func cancellationCoversBothKinds() {
        let identifiers = NotificationService.StrengthNotificationKind.allIdentifiers(for: UUID())
        #expect(identifiers.count == 2)
        #expect(Set(identifiers).count == 2)
    }
}

@Suite("Orphaned notification identifiers")
struct OrphanedNotificationIdentifierTests {
    @Test("Reminder identifiers resolve to their habit for every weekday")
    func reminderIdentifiersResolve() {
        let id = UUID()
        for weekday in 1...7 {
            #expect(NotificationService.taskID(fromIdentifier: "task-\(id.uuidString)-day-\(weekday)") == id)
        }
    }

    @Test("Strength identifiers resolve to their habit")
    func strengthIdentifiersResolve() {
        let id = UUID()
        for kind in NotificationService.StrengthNotificationKind.allCases {
            #expect(NotificationService.taskID(fromIdentifier: "strength-\(id.uuidString)-\(kind.rawValue)") == id)
        }
    }

    /// The sweep deletes whatever it can attribute to a habit, so anything it cannot
    /// parse must come back as `nil` rather than a wrong ID.
    @Test("Foreign and malformed identifiers are left alone")
    func foreignIdentifiersAreIgnored() {
        let id = UUID()
        #expect(NotificationService.taskID(fromIdentifier: "task-\(id.uuidString)-week-3") == nil)
        #expect(NotificationService.taskID(fromIdentifier: "other-\(id.uuidString)-day-3") == nil)
        #expect(NotificationService.taskID(fromIdentifier: "task-not-a-uuid-day-3") == nil)
        #expect(NotificationService.taskID(fromIdentifier: "some-third-party-identifier") == nil)
        #expect(NotificationService.taskID(fromIdentifier: "") == nil)
    }
}

// MARK: - Localization parity

@Suite("Localization")
struct LocalizationParityTests {
    private static let languages = ["en", "es", "fr", "de", "it", "nl", "pt-PT"]

    private func keys(for language: String) throws -> Set<String> {
        let path = try #require(
            Bundle.main.path(
                forResource: "Localizable", ofType: "strings", inDirectory: "\(language).lproj"
            ),
            "missing Localizable.strings for \(language)"
        )
        let contents = try #require(NSDictionary(contentsOfFile: path) as? [String: String])
        return Set(contents.keys)
    }

    /// A missing key silently falls back to showing the raw English source, which is
    /// invisible in English-language testing and obvious to everyone else.
    @Test("Every language defines exactly the English key set")
    func keySetsMatch() throws {
        let english = try keys(for: "en")
        #expect(!english.isEmpty)

        for language in Self.languages where language != "en" {
            let translated = try keys(for: language)
            #expect(english.subtracting(translated).isEmpty, "\(language) is missing keys")
            #expect(translated.subtracting(english).isEmpty, "\(language) has stray keys")
        }
    }

    @Test("Habit strength strings are localized in every language")
    func habitStrengthKeysPresent() throws {
        let required = [
            "Habit strength",
            "Habit strength will be shown after 3 completions",
            "Mark done",
            "Later",
            "Keep going",
            "Your plan",
            "Tap and hold to complete, single tap for details",
            "One check-in today makes you leap to the next stage",
        ] + HabitStage.allCases.map { $0.rawValue.capitalized }

        for language in Self.languages {
            let translated = try keys(for: language)
            for key in required {
                #expect(translated.contains(key), "\(language) is missing \"\(key)\"")
            }
        }
    }
}
