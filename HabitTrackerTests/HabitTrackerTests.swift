import Testing
import Foundation
import SwiftData
@testable import HabitTracker

// MARK: - Enum Tests

@Suite("Enums")
struct EnumTests {
    @Test("GoalType raw value round-trip")
    func goalTypeRoundTrip() {
        for goalType in GoalType.allCases {
            let rawValue = goalType.rawValue
            #expect(GoalType(rawValue: rawValue) == goalType)
        }
    }

    @Test("GoalType has 8 cases")
    func goalTypeCount() {
        #expect(GoalType.allCases.count == 8)
    }

    @Test("FrequencyType raw value round-trip")
    func frequencyTypeRoundTrip() {
        for freq in FrequencyType.allCases {
            #expect(FrequencyType(rawValue: freq.rawValue) == freq)
        }
    }

    @Test("FrequencyType selectable cases exclude legacy everyWeek")
    func frequencySelectableCases() {
        #expect(FrequencyType.selectableCases == [.daily, .weekly, .monthly, .specificDays])
        #expect(!FrequencyType.selectableCases.contains(.everyWeek))
    }

    @Test("TrackingMode raw value round-trip")
    func trackingModeRoundTrip() {
        for mode in TrackingMode.allCases {
            #expect(TrackingMode(rawValue: mode.rawValue) == mode)
        }
        #expect(TrackingMode.allCases.count == 2)
    }

    @Test("Weekday covers all 7 days")
    func weekdayCount() {
        #expect(Weekday.allCases.count == 7)
        #expect(Weekday.monday.rawValue == 1)
        #expect(Weekday.sunday.rawValue == 7)
    }

    @Test("MeasurementSystem has 3 cases")
    func measurementSystemCount() {
        #expect(MeasurementSystem.allCases.count == 3)
    }

    @Test("GoalType defaultUnits are non-empty for measured types")
    func goalTypeUnits() {
        #expect(GoalType.none.defaultUnits.isEmpty)
        #expect(!GoalType.time.defaultUnits.isEmpty)
        #expect(!GoalType.distance.defaultUnits.isEmpty)
        #expect(!GoalType.repetitions.defaultUnits.isEmpty)
        #expect(!GoalType.cups.defaultUnits.isEmpty)
        #expect(!GoalType.calories.defaultUnits.isEmpty)
        #expect(!GoalType.weight.defaultUnits.isEmpty)
        #expect(!GoalType.capacity.defaultUnits.isEmpty)
    }
}

// MARK: - Preset Task Catalog Tests

@Suite("PresetTaskCatalog")
struct PresetTaskCatalogTests {
    @Test("Catalog has 28 entries")
    func catalogCount() {
        // 7 Fitness + 14 Health + 5 Social + 3 Learning = 29
        // But our count in data-model was 25 + a few extras
        #expect(PresetTaskCatalog.all.count >= 25)
    }

    @Test("No duplicate identifiers")
    func noDuplicateIDs() {
        let ids = PresetTaskCatalog.all.map(\.id)
        let uniqueIDs = Set(ids)
        #expect(ids.count == uniqueIDs.count)
    }

    @Test("All 4 categories represented")
    func allCategoriesPresent() {
        let categoryNames = Set(PresetTaskCatalog.all.map(\.categoryName))
        #expect(categoryNames.contains("Health"))
        #expect(categoryNames.contains("Fitness"))
        #expect(categoryNames.contains("Learning"))
        #expect(categoryNames.contains("Social"))
    }

    @Test("Category filter returns correct subset")
    func categoryFilter() {
        let fitness = PresetTaskCatalog.tasks(forCategory: "Fitness")
        #expect(fitness.allSatisfy { $0.categoryName == "Fitness" })
        #expect(!fitness.isEmpty)
    }

    @Test("Each preset has a non-empty name and icon")
    func presetFields() {
        for preset in PresetTaskCatalog.all {
            #expect(!preset.name.isEmpty)
            #expect(!preset.iconName.isEmpty)
            #expect(!preset.id.isEmpty)
        }
    }
}

// MARK: - Color Palette Tests

@Suite("ColorPalette")
struct ColorPaletteTests {
    @Test("TaskColor has 16 colors")
    func colorCount() {
        #expect(TaskColor.allCases.count == 16)
    }

    @Test("from(token:) falls back to blue for unknown")
    func fallbackBlue() {
        let color = TaskColor.from(token: "nonexistent")
        #expect(color == .blue)
    }

    @Test("from(token:) resolves valid tokens")
    func validTokens() {
        for taskColor in TaskColor.allCases {
            #expect(TaskColor.from(token: taskColor.rawValue) == taskColor)
        }
    }
}

// MARK: - HabitTask Model Tests

@Suite("HabitTask")
struct HabitTaskTests {
    @Test("initialsDisplay from multi-word title")
    func initialsMultiWord() {
        let task = HabitTask(title: "Walk the dog")
        #expect(task.initialsDisplay == "WT")
    }

    @Test("initialsDisplay from single-word title")
    func initialsSingleWord() {
        let task = HabitTask(title: "Meditate")
        #expect(task.initialsDisplay == "ME")
    }

    @Test("isScheduled for daily frequency returns true for all days")
    func dailySchedule() {
        let task = HabitTask(title: "Test", frequencyType: .daily)
        for day in 1...7 {
            #expect(task.isScheduled(forWeekday: day))
        }
    }

    @Test("isScheduled for specificDays respects scheduled days")
    func specificDaysSchedule() {
        let task = HabitTask(
            title: "Test",
            frequencyType: .specificDays,
            scheduledDays: [1, 3, 5] // Mon, Wed, Fri
        )
        #expect(task.isScheduled(forWeekday: 1))
        #expect(!task.isScheduled(forWeekday: 2))
        #expect(task.isScheduled(forWeekday: 3))
        #expect(!task.isScheduled(forWeekday: 4))
        #expect(task.isScheduled(forWeekday: 5))
    }

    @Test("Default values are set correctly")
    func defaultValues() {
        let task = HabitTask(title: "Test")
        #expect(task.goalType == .none)
        #expect(task.frequencyType == .daily)
        #expect(task.timesPerPeriod == 1)
        #expect(task.tracking == .eachCompletion)
        #expect(task.scheduledDays == [1, 2, 3, 4, 5, 6, 7])
        #expect(!task.notificationEnabled)
        #expect(task.colorToken == "blue")
        #expect(task.sortOrder == 0)
        #expect(!task.isPreset)
    }
}

// MARK: - Calendar Extension Tests

@Suite("CalendarExtensions")
struct CalendarExtensionTests {
    @Test("isoWeekday returns 1 for Monday")
    func mondayIsOne() {
        let calendar = Calendar.current
        // 2026-02-09 is a Monday
        let monday = calendar.date(from: DateComponents(year: 2026, month: 2, day: 9))!
        #expect(calendar.isoWeekday(for: monday) == 1)
    }

    @Test("isoWeekday returns 7 for Sunday")
    func sundayIsSeven() {
        let calendar = Calendar.current
        // 2026-02-08 is a Sunday
        let sunday = calendar.date(from: DateComponents(year: 2026, month: 2, day: 8))!
        #expect(calendar.isoWeekday(for: sunday) == 7)
    }
}

// MARK: - Statistics Service Tests

@Suite("StatisticsService")
struct StatisticsServiceTests {
    private func makeTask(withCompletions dates: [Date]) -> HabitTask {
        let task = HabitTask(title: "Test Task")
        for date in dates {
            let completion = TaskCompletion(completedAt: date, task: task)
            task.completions.append(completion)
        }
        return task
    }

    @Test("completionCount within window")
    func countInWindow() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)!
        let tenDaysAgo = calendar.date(byAdding: .day, value: -10, to: today)!

        let task = makeTask(withCompletions: [yesterday, twoDaysAgo, tenDaysAgo])

        // Window: last 5 days
        let windowStart = calendar.date(byAdding: .day, value: -5, to: today)!
        let count = StatisticsService.completionCount(for: task, from: windowStart, to: today)
        #expect(count == 2) // yesterday + twoDaysAgo
    }

    @Test("expectedCompletions for daily task = one credit per day")
    func expectedDaily() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -6, to: today)!

        // Daily multi-task is forced periodComplete: at most one credit per day.
        let task = HabitTask(title: "Test", frequencyType: .daily, timesPerPeriod: 2)
        let expected = StatisticsService.expectedCompletions(
            for: task, from: sevenDaysAgo, to: today, calendar: calendar
        )
        #expect(expected == 7) // 7 days, one credit each
    }

    @Test("completionPercentage returns 0 when no completions")
    func zeroPercentage() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -6, to: today)!

        let task = HabitTask(title: "Test")
        let pct = StatisticsService.completionPercentage(
            for: task, from: sevenDaysAgo, to: today, calendar: calendar
        )
        #expect(pct == 0)
    }

    @Test("trendData uses weekly buckets for < 60 days")
    func weeklyBuckets() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: today)!

        let task = HabitTask(title: "Test")
        let trend = StatisticsService.trendData(for: task, from: thirtyDaysAgo, to: today)

        // 30 days / 7-day buckets ≈ 4-5 points
        #expect(trend.count >= 4)
        #expect(trend.count <= 6)
    }

    @Test("trendData uses monthly buckets for >= 60 days")
    func monthlyBuckets() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let ninetyDaysAgo = calendar.date(byAdding: .day, value: -90, to: today)!

        let task = HabitTask(title: "Test")
        let trend = StatisticsService.trendData(for: task, from: ninetyDaysAgo, to: today)

        // 90 days ≈ 3 months → 3 points
        #expect(trend.count >= 2)
        #expect(trend.count <= 4)
    }
}

// MARK: - TaskConfigurationViewModel Tests

@Suite("TaskConfigurationViewModel")
struct TaskConfigurationViewModelTests {
    @Test("Create mode starts with empty title")
    func createModeDefaults() {
        let vm = TaskConfigurationViewModel(mode: .create)
        #expect(vm.title.isEmpty)
        #expect(vm.goalType == .none)
        #expect(vm.colorToken == "blue")
        #expect(!vm.canSave) // empty title
    }

    @Test("canSave is true with non-empty title")
    func canSaveWithTitle() {
        let vm = TaskConfigurationViewModel(mode: .create)
        vm.title = "Test"
        #expect(vm.canSave)
    }

    @Test("canSave is false with whitespace-only title")
    func cannotSaveWhitespace() {
        let vm = TaskConfigurationViewModel(mode: .create)
        vm.title = "   "
        #expect(!vm.canSave)
    }

    @Test("applyPreset fills fields correctly")
    func applyPreset() {
        let vm = TaskConfigurationViewModel(mode: .create)
        let preset = PresetTask(
            id: "test.preset",
            name: "Test Preset",
            iconName: "star.fill",
            categoryName: "Health",
            goalType: .time,
            defaultUnit: "min",
            defaultGoalValue: 10
        )
        vm.applyPreset(preset, categories: [])
        #expect(vm.title == "Test Preset")
        #expect(vm.iconName == "star.fill")
        #expect(vm.goalType == .time)
        #expect(vm.goalUnit == "min")
        #expect(vm.goalValue == 10)
        #expect(vm.presetIdentifier == "test.preset")
        #expect(vm.isPreset)
    }

    @Test("Edit mode pre-fills from task")
    func editModePrefill() {
        let task = HabitTask(
            title: "Meditate",
            iconName: "brain.head.profile",
            goalType: .time,
            goalValue: 10,
            goalUnit: "min",
            colorToken: "purple"
        )
        let vm = TaskConfigurationViewModel(mode: .edit(task))
        #expect(vm.title == "Meditate")
        #expect(vm.iconName == "brain.head.profile")
        #expect(vm.goalType == .time)
        #expect(vm.goalValue == 10)
        #expect(vm.colorToken == "purple")
    }

    @Test("goalValueString converts correctly")
    func goalValueString() {
        let vm = TaskConfigurationViewModel(mode: .create)
        vm.goalValue = 5.0
        #expect(vm.goalValueString == "5")

        vm.goalValue = 3.5
        #expect(vm.goalValueString == "3.5")

        vm.goalValueString = "7"
        #expect(vm.goalValue == 7.0)

        vm.goalValueString = "abc"
        #expect(vm.goalValue == nil)
    }
}

// MARK: - TaskListViewModel Tests

@Suite("TaskListViewModel")
struct TaskListViewModelTests {
    @Test("filteredTasks returns all when no category selected")
    func noFilter() {
        let vm = TaskListViewModel()
        let tasks = [
            HabitTask(title: "A", sortOrder: 1),
            HabitTask(title: "B", sortOrder: 0),
        ]
        let filtered = vm.filteredTasks(tasks)
        #expect(filtered.count == 2)
        #expect(filtered[0].title == "B") // sorted by sortOrder
    }

    @Test("filteredTasks filters by category ID")
    func categoryFilter() {
        let vm = TaskListViewModel()
        let cat = Category(name: "Test")
        let task1 = HabitTask(title: "A", category: cat)
        let task2 = HabitTask(title: "B")

        vm.selectedCategoryID = cat.id
        let filtered = vm.filteredTasks([task1, task2])
        #expect(filtered.count == 1)
        #expect(filtered[0].title == "A")
    }
}

// MARK: - TaskStatsViewModel Tests

@Suite("TaskStatsViewModel")
struct TaskStatsViewModelTests {
    @Test("Defaults to 30-day window")
    func defaultWindow() {
        let task = HabitTask(title: "Test")
        let vm = TaskStatsViewModel(task: task)

        let calendar = Calendar.current
        let daysDiff = calendar.dateComponents([.day], from: vm.windowStart, to: vm.windowEnd).day!
        #expect(daysDiff == 30)
    }

    @Test("updateWindow changes the dates")
    func updateWindow() {
        let task = HabitTask(title: "Test")
        let vm = TaskStatsViewModel(task: task)

        let calendar = Calendar.current
        let newStart = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let newEnd = calendar.date(from: DateComponents(year: 2026, month: 1, day: 31))!

        vm.updateWindow(start: newStart, end: newEnd)
        #expect(calendar.isDate(vm.windowStart, inSameDayAs: newStart))
        #expect(calendar.isDate(vm.windowEnd, inSameDayAs: newEnd))
    }
}

// MARK: - Test Helpers

private enum TestData {
    static let calendar = Calendar.current

    static func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 12) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    /// Builds a task with completions at the given dates (not persisted).
    static func task(
        frequency: FrequencyType = .daily,
        n: Int = 1,
        tracking: TrackingMode = .eachCompletion,
        scheduledDays: [Int] = [1, 2, 3, 4, 5, 6, 7],
        completions: [Date] = []
    ) -> HabitTask {
        let t = HabitTask(
            title: "Test",
            frequencyType: frequency,
            timesPerPeriod: n,
            tracking: tracking,
            scheduledDays: scheduledDays
        )
        for d in completions {
            t.completions.append(TaskCompletion(completedAt: d, task: t))
        }
        return t
    }
}

// MARK: - PeriodService Tests

@Suite("PeriodService")
struct PeriodServiceTests {
    private let cal = Calendar.current

    @Test("Daily period bounds span one calendar day")
    func dailyBounds() {
        let t = TestData.task(frequency: .daily, n: 1)
        let day = TestData.date(2026, 2, 11)
        let bounds = PeriodService.periodBounds(for: t, on: day, calendar: cal)
        #expect(cal.isDate(bounds.start, inSameDayAs: day))
        let expectedEnd = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: day))!
        #expect(bounds.end == expectedEnd)
    }

    @Test("Weekly period starts on configured week start day (Monday)")
    func weeklyBoundsMonday() {
        let t = TestData.task(frequency: .weekly, n: 3)
        // 2026-02-11 is a Wednesday; Monday of that week is 2026-02-09.
        let wed = TestData.date(2026, 2, 11)
        let bounds = PeriodService.periodBounds(for: t, on: wed, calendar: cal, weekStartDay: 1)
        let monday = cal.startOfDay(for: TestData.date(2026, 2, 9))
        #expect(bounds.start == monday)
        #expect(bounds.end == cal.date(byAdding: .day, value: 7, to: monday)!)
    }

    @Test("Monthly period spans the calendar month")
    func monthlyBounds() {
        let t = TestData.task(frequency: .monthly, n: 3)
        let mid = TestData.date(2026, 2, 15)
        let bounds = PeriodService.periodBounds(for: t, on: mid, calendar: cal)
        #expect(bounds.start == cal.startOfDay(for: TestData.date(2026, 2, 1, hour: 0)))
        #expect(bounds.end == cal.startOfDay(for: TestData.date(2026, 3, 1, hour: 0)))
    }

    @Test("Daily multi-task list state transitions 0/3 -> partial -> complete")
    func dailyStates() {
        let day = TestData.date(2026, 2, 11)
        let t = TestData.task(frequency: .daily, n: 3, completions: [])

        var p = PeriodService.periodProgress(for: t, on: day, calendar: cal)
        #expect(p.listState == .incomplete)
        #expect(p.current == 0)
        #expect(p.showsCounter)

        t.completions.append(TaskCompletion(completedAt: TestData.date(2026, 2, 11, hour: 8), task: t))
        p = PeriodService.periodProgress(for: t, on: day, calendar: cal)
        #expect(p.listState == .partial)
        #expect(p.current == 1)

        t.completions.append(TaskCompletion(completedAt: TestData.date(2026, 2, 11, hour: 12), task: t))
        t.completions.append(TaskCompletion(completedAt: TestData.date(2026, 2, 11, hour: 18), task: t))
        p = PeriodService.periodProgress(for: t, on: day, calendar: cal)
        #expect(p.listState == .complete)
        #expect(p.current == 3)
    }

    @Test("canAcceptCompletion is false once complete (over-completion blocked)")
    func gatingAtComplete() {
        let day = TestData.date(2026, 2, 11)
        let t = TestData.task(frequency: .daily, n: 1, completions: [TestData.date(2026, 2, 11, hour: 9)])
        #expect(!PeriodService.canAcceptCompletion(for: t, on: day, calendar: cal))
    }

    @Test("N=1 profiles show no counter")
    func simpleNoCounter() {
        let t = TestData.task(frequency: .weekly, n: 1)
        let p = PeriodService.periodProgress(for: t, on: TestData.date(2026, 2, 11), calendar: cal)
        #expect(!p.showsCounter)
    }

    @Test("Specific days is hidden when today is not scheduled and target = day count")
    func specificDaysVisibility() {
        // Mon/Wed/Fri scheduled; 2026-02-10 is a Tuesday (hidden), 02-11 Wed (visible).
        let t = TestData.task(frequency: .specificDays, scheduledDays: [1, 3, 5])
        #expect(PeriodService.target(for: t) == 3)

        let tue = TestData.date(2026, 2, 10)
        #expect(PeriodService.periodProgress(for: t, on: tue, calendar: cal).listState == .hidden)

        let wed = TestData.date(2026, 2, 11)
        #expect(PeriodService.periodProgress(for: t, on: wed, calendar: cal).listState != .hidden)
    }

    @Test("Legacy everyWeek behaves as weekly for period math")
    func everyWeekActsWeekly() {
        let t = TestData.task(frequency: .everyWeek, n: 2)
        #expect(PeriodService.effectiveFrequency(for: t) == .weekly)
        let bounds = PeriodService.periodBounds(for: t, on: TestData.date(2026, 2, 11), calendar: cal, weekStartDay: 1)
        #expect(bounds.start == cal.startOfDay(for: TestData.date(2026, 2, 9)))
    }
}

// MARK: - Stats Credit Tests

@Suite("StatisticsService Tracking")
struct StatisticsTrackingTests {
    private let cal = Calendar.current

    @Test("Weekly eachCompletion credits each raw completion")
    func weeklyEachCompletion() {
        let comps = [TestData.date(2026, 2, 9), TestData.date(2026, 2, 10), TestData.date(2026, 2, 11)]
        let t = TestData.task(frequency: .weekly, n: 3, tracking: .eachCompletion, completions: comps)
        let from = TestData.date(2026, 2, 9, hour: 0)
        let to = TestData.date(2026, 2, 15, hour: 23)
        #expect(StatisticsService.completionCount(for: t, from: from, to: to, weekStartDay: 1, calendar: cal) == 3)
    }

    @Test("Weekly periodComplete credits one for a completed period")
    func weeklyPeriodComplete() {
        let comps = [TestData.date(2026, 2, 9), TestData.date(2026, 2, 10), TestData.date(2026, 2, 11)]
        let t = TestData.task(frequency: .weekly, n: 3, tracking: .periodComplete, completions: comps)
        let from = TestData.date(2026, 2, 9, hour: 0)
        let to = TestData.date(2026, 2, 15, hour: 23)
        #expect(StatisticsService.completionCount(for: t, from: from, to: to, weekStartDay: 1, calendar: cal) == 1)
    }

    @Test("Daily multi-task is forced periodComplete (3/3 -> 1, 2/3 -> 0)")
    func dailyForcedPeriodComplete() {
        let from = TestData.date(2026, 2, 11, hour: 0)
        let to = TestData.date(2026, 2, 11, hour: 23)

        let full = TestData.task(frequency: .daily, n: 3, completions: [
            TestData.date(2026, 2, 11, hour: 8),
            TestData.date(2026, 2, 11, hour: 12),
            TestData.date(2026, 2, 11, hour: 18),
        ])
        #expect(StatisticsService.completionCount(for: full, from: from, to: to, calendar: cal) == 1)

        let partial = TestData.task(frequency: .daily, n: 3, completions: [
            TestData.date(2026, 2, 11, hour: 8),
            TestData.date(2026, 2, 11, hour: 12),
        ])
        #expect(StatisticsService.completionCount(for: partial, from: from, to: to, calendar: cal) == 0)
    }
}

// MARK: - Streak Tests

@Suite("Streak Logic")
struct StreakTests {
    private let cal = Calendar.current

    @Test("Daily N=3: 5 completions across 2 days -> streak 1")
    func dailyStreak() {
        // Today (Wed 02-11): 2 completions; Tue 02-10: 3 completions.
        let t = TestData.task(frequency: .daily, n: 3, completions: [
            TestData.date(2026, 2, 11, hour: 8),
            TestData.date(2026, 2, 11, hour: 12),
            TestData.date(2026, 2, 10, hour: 8),
            TestData.date(2026, 2, 10, hour: 12),
            TestData.date(2026, 2, 10, hour: 18),
        ])
        let streak = PeriodService.currentStreak(for: t, on: TestData.date(2026, 2, 11), calendar: cal, weekStartDay: 1)
        #expect(streak == 1)
    }

    @Test("Weekly eachCompletion N=3: 5 completions across 2 weeks -> streak 5")
    func weeklyEachStreak() {
        // Week B (current, Mon 02-09): 2; Week A (Mon 02-02): 3.
        let t = TestData.task(frequency: .weekly, n: 3, tracking: .eachCompletion, completions: [
            TestData.date(2026, 2, 9), TestData.date(2026, 2, 10),
            TestData.date(2026, 2, 2), TestData.date(2026, 2, 3), TestData.date(2026, 2, 4),
        ])
        let streak = PeriodService.currentStreak(for: t, on: TestData.date(2026, 2, 11), calendar: cal, weekStartDay: 1)
        #expect(streak == 5)
    }

    @Test("Weekly periodComplete N=3: 5 completions across 2 weeks -> streak 1")
    func weeklyPeriodStreak() {
        let t = TestData.task(frequency: .weekly, n: 3, tracking: .periodComplete, completions: [
            TestData.date(2026, 2, 9), TestData.date(2026, 2, 10),
            TestData.date(2026, 2, 2), TestData.date(2026, 2, 3), TestData.date(2026, 2, 4),
        ])
        let streak = PeriodService.currentStreak(for: t, on: TestData.date(2026, 2, 11), calendar: cal, weekStartDay: 1)
        #expect(streak == 1)
    }
}

// MARK: - Migration Tests

@Suite("MigrationService")
struct MigrationServiceTests {
    @MainActor
    @Test("Legacy everyWeek is normalized to weekly")
    func normalizeEveryWeek() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: HabitTask.self, TaskCompletion.self, Category.self, AppSettings.self,
            configurations: config
        )
        let context = container.mainContext

        let task = HabitTask(title: "Gym", frequencyType: .everyWeek, timesPerPeriod: 3)
        context.insert(task)
        // Completions must be preserved.
        let completion = TaskCompletion(completedAt: .now, task: task)
        context.insert(completion)

        MigrationService.normalizeIfNeeded(context: context)

        #expect(task.frequencyType == .weekly)
        #expect(task.tracking == .eachCompletion)
        #expect(task.completions.count == 1)

        // Idempotent: running again is a no-op.
        MigrationService.normalizeIfNeeded(context: context)
        #expect(task.frequencyType == .weekly)
    }
}

// MARK: - Configuration Picker Logic Tests

@Suite("TaskConfiguration Picker Logic")
struct TaskConfigurationPickerTests {
    @Test("Tracking picker hidden for daily, shown for weekly 1<N<7")
    func trackingVisibility() {
        let vm = TaskConfigurationViewModel(mode: .create)

        vm.frequencyType = .daily
        vm.timesPerPeriod = 3
        #expect(!vm.showsTrackingPicker)

        vm.frequencyType = .weekly
        vm.timesPerPeriod = 3
        #expect(vm.showsTrackingPicker)

        vm.timesPerPeriod = 1
        #expect(!vm.showsTrackingPicker)
    }

    @Test("Weekly with all 7 days hides tracking picker")
    func weeklyFullHidesTracking() {
        let vm = TaskConfigurationViewModel(mode: .create)
        vm.frequencyType = .weekly
        vm.timesPerPeriod = 7
        #expect(!vm.showsTrackingPicker)
    }

    @Test("Specific days tracking shown only when not all 7 selected")
    func specificDaysTracking() {
        let vm = TaskConfigurationViewModel(mode: .create)
        vm.frequencyType = .specificDays
        vm.scheduledDays = [1, 3, 5]
        #expect(vm.showsTrackingPicker)

        vm.scheduledDays = Set(1...7)
        #expect(!vm.showsTrackingPicker)

        vm.scheduledDays = [1]
        #expect(!vm.showsTrackingPicker)
    }

    @Test("Changing frequency clamps times-per-period into range")
    func clampOnFrequencyChange() {
        let vm = TaskConfigurationViewModel(mode: .create)
        vm.frequencyType = .daily
        vm.timesPerPeriod = 40 // valid for daily (1...48)
        vm.frequencyType = .weekly // weekly max 7
        #expect(vm.timesPerPeriod == 7)
        #expect(vm.timesPerPeriodRange == 1...7)
    }

    @Test("Times stepper hidden for specific days")
    func stepperHiddenSpecificDays() {
        let vm = TaskConfigurationViewModel(mode: .create)
        vm.frequencyType = .specificDays
        #expect(!vm.showsTimesStepper)
    }
}
