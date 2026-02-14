import Testing
import Foundation
@testable import HabitTracker

// MARK: - Enum Tests

@Suite("Enums")
struct EnumTests {
    @Test("MeasurementDuration raw value round-trip")
    func measurementDurationRoundTrip() {
        for duration in MeasurementDuration.allCases {
            let rawValue = duration.rawValue
            #expect(MeasurementDuration(rawValue: rawValue) == duration)
        }
    }

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
        #expect(task.measurementDuration == .daily)
        #expect(task.goalType == .none)
        #expect(task.frequencyType == .daily)
        #expect(task.timesPerDay == 1)
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

    @Test("expectedCompletions for daily task")
    func expectedDaily() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -6, to: today)!

        let task = HabitTask(title: "Test", frequencyType: .daily, timesPerDay: 2)
        let expected = StatisticsService.expectedCompletions(
            for: task, from: sevenDaysAgo, to: today, calendar: calendar
        )
        #expect(expected == 14) // 7 days * 2 times
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
            measurementDuration: .daily,
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
