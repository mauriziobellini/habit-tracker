import Foundation
import SwiftData
import SwiftUI

@Observable
final class TaskConfigurationViewModel {
    // MARK: - Mode

    enum Mode {
        case create
        case edit(HabitTask)
    }

    let mode: Mode

    // MARK: - Form Fields

    var title: String = ""
    var iconName: String? = nil
    var measurementDuration: MeasurementDuration = .daily
    var goalType: GoalType = .none
    var goalValue: Double? = nil
    var goalUnit: String? = nil
    var frequencyType: FrequencyType = .daily
    var timesPerDay: Int = 1
    var scheduledDays: Set<Int> = Set(1...7)
    var notificationEnabled: Bool = false
    var notificationTime: Date = Calendar.current.date(
        from: DateComponents(hour: 9, minute: 0)
    ) ?? .now
    var colorToken: String = "blue"
    var selectedCategoryID: UUID? = nil
    var newCategoryName: String = ""
    var showingNewCategoryField: Bool = false
    var showingIconPicker: Bool = false

    // Reward
    var rewardEnabled: Bool = false
    var rewardStreakCount: Int = 2
    var rewardText: String = ""

    var presetIdentifier: String? = nil
    var isPreset: Bool = false

    // MARK: - Initialization

    init(mode: Mode) {
        self.mode = mode

        switch mode {
        case .create:
            break
        case .edit(let task):
            title = task.title
            iconName = task.iconName
            measurementDuration = task.measurementDuration
            goalType = task.goalType
            goalValue = task.goalValue
            goalUnit = task.goalUnit
            frequencyType = task.frequencyType
            timesPerDay = task.timesPerDay
            scheduledDays = Set(task.scheduledDays)
            notificationEnabled = task.notificationEnabled
            notificationTime = task.notificationTime ?? Calendar.current.date(
                from: DateComponents(hour: 9, minute: 0)
            ) ?? .now
            colorToken = task.colorToken
            selectedCategoryID = task.category?.id
            rewardEnabled = task.rewardEnabled
            rewardStreakCount = task.rewardStreakCount
            rewardText = task.rewardText ?? ""
            presetIdentifier = task.presetIdentifier
            isPreset = task.isPreset
        }
    }

    /// Initialize from a preset task catalog entry.
    func applyPreset(_ preset: PresetTask, categories: [Category]) {
        title = preset.name
        iconName = preset.iconName
        goalType = preset.goalType
        goalUnit = preset.defaultUnit
        goalValue = preset.defaultGoalValue
        presetIdentifier = preset.id
        isPreset = true

        // Match category by name
        if let cat = categories.first(where: { $0.name == preset.categoryName }) {
            selectedCategoryID = cat.id
        }
    }

    // MARK: - Validation

    var canSave: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // MARK: - Goal Value String Binding

    var goalValueString: String {
        get {
            if let v = goalValue {
                return v.truncatingRemainder(dividingBy: 1) == 0
                    ? String(Int(v))
                    : String(v)
            }
            return ""
        }
        set {
            goalValue = Double(newValue)
        }
    }

    // MARK: - Save

    @MainActor
    func save(context: ModelContext, categories: [Category]) {
        switch mode {
        case .create:
            let task = HabitTask(
                title: title.trimmingCharacters(in: .whitespaces),
                iconName: iconName,
                isPreset: isPreset,
                presetIdentifier: presetIdentifier,
                measurementDuration: measurementDuration,
                goalType: goalType,
                goalValue: goalType == .none ? nil : goalValue,
                goalUnit: goalType == .none ? nil : goalUnit,
                frequencyType: frequencyType,
                timesPerDay: timesPerDay,
                scheduledDays: Array(scheduledDays).sorted(),
                notificationEnabled: notificationEnabled,
                notificationTime: notificationEnabled ? notificationTime : nil,
                colorToken: colorToken,
                rewardEnabled: rewardEnabled,
                rewardStreakCount: rewardStreakCount,
                rewardText: rewardEnabled ? (rewardText.trimmingCharacters(in: .whitespaces).isEmpty ? nil : rewardText.trimmingCharacters(in: .whitespaces)) : nil,
                category: categories.first { $0.id == selectedCategoryID }
            )
            context.insert(task)
            // Schedule notifications for new task
            if task.notificationEnabled {
                Task {
                    let granted = await NotificationService.shared.requestAuthorization()
                    if granted {
                        NotificationService.shared.scheduleNotifications(for: task)
                    }
                }
            }

        case .edit(let task):
            task.title = title.trimmingCharacters(in: .whitespaces)
            task.iconName = iconName
            task.measurementDuration = measurementDuration
            task.goalType = goalType
            task.goalValue = goalType == .none ? nil : goalValue
            task.goalUnit = goalType == .none ? nil : goalUnit
            task.frequencyType = frequencyType
            task.timesPerDay = timesPerDay
            task.scheduledDays = Array(scheduledDays).sorted()
            task.notificationEnabled = notificationEnabled
            task.notificationTime = notificationEnabled ? notificationTime : nil
            task.colorToken = colorToken
            task.rewardEnabled = rewardEnabled
            task.rewardStreakCount = rewardStreakCount
            task.rewardText = rewardEnabled ? (rewardText.trimmingCharacters(in: .whitespaces).isEmpty ? nil : rewardText.trimmingCharacters(in: .whitespaces)) : nil
            task.category = categories.first { $0.id == selectedCategoryID }
            task.updatedAt = .now
            // Reschedule notifications on edit
            NotificationService.shared.rescheduleNotifications(for: task)
        }
    }

    /// Creates a new custom category and selects it.
    @MainActor
    func createCategory(context: ModelContext) {
        let trimmed = newCategoryName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        let category = Category(name: trimmed)
        context.insert(category)
        selectedCategoryID = category.id
        newCategoryName = ""
        showingNewCategoryField = false
    }
}
