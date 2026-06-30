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
    var goalType: GoalType = .none
    var goalValue: Double? = nil
    var goalUnit: String? = nil
    var frequencyType: FrequencyType = .daily {
        didSet { clampTimesToFrequency() }
    }
    var timesPerPeriod: Int = 1
    var tracking: TrackingMode = .eachCompletion
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
            goalType = task.goalType
            goalValue = task.goalValue
            goalUnit = task.goalUnit
            // Normalize the legacy `everyWeek` value for the editor.
            frequencyType = task.frequencyType == .everyWeek ? .weekly : task.frequencyType
            timesPerPeriod = task.timesPerPeriod
            tracking = task.tracking
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
        title = preset.localizedName
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
        if frequencyType == .specificDays && scheduledDays.isEmpty { return false }
        return !title.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // MARK: - Schedule helpers

    /// Valid range for the times-per-period stepper, per frequency (PRD §9).
    var timesPerPeriodRange: ClosedRange<Int> {
        switch frequencyType {
        case .daily:        return 1...48
        case .weekly:       return 1...7
        case .monthly:      return 1...30
        case .specificDays, .everyWeek: return 1...7
        }
    }

    /// Localized label for the times-per-period stepper.
    var timesPerPeriodLabel: String {
        switch frequencyType {
        case .daily:
            return String(format: NSLocalizedString("Times per day: %lld", comment: ""), timesPerPeriod)
        case .monthly:
            return String(format: NSLocalizedString("Times per month: %lld", comment: ""), timesPerPeriod)
        default:
            return String(format: NSLocalizedString("Times per week: %lld", comment: ""), timesPerPeriod)
        }
    }

    /// Whether the times-per-period stepper is shown (specific days uses the
    /// weekday selector instead, so the quota is implicit).
    var showsTimesStepper: Bool {
        frequencyType == .daily || frequencyType == .weekly || frequencyType == .monthly
    }

    /// Whether the tracking picker is offered (PRD §9):
    /// weekly/monthly only when `1 < N < max`; specific days only when not all 7
    /// days are selected (and more than one day). Never for daily.
    var showsTrackingPicker: Bool {
        switch frequencyType {
        case .daily, .everyWeek:
            return false
        case .weekly:
            return timesPerPeriod > 1 && timesPerPeriod < 7
        case .monthly:
            return timesPerPeriod > 1 && timesPerPeriod < 30
        case .specificDays:
            return scheduledDays.count > 1 && scheduledDays.count < 7
        }
    }

    /// Keeps `timesPerPeriod` valid when the frequency changes.
    private func clampTimesToFrequency() {
        let range = timesPerPeriodRange
        timesPerPeriod = min(max(timesPerPeriod, range.lowerBound), range.upperBound)
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

    /// The quota value to persist. For specific days the target is derived from
    /// the selected weekdays, so we store that count for consistency.
    private var resolvedTimesPerPeriod: Int {
        frequencyType == .specificDays ? max(1, scheduledDays.count) : timesPerPeriod
    }

    @MainActor
    func save(context: ModelContext, categories: [Category]) {
        switch mode {
        case .create:
            let task = HabitTask(
                title: title.trimmingCharacters(in: .whitespaces),
                iconName: iconName,
                isPreset: isPreset,
                presetIdentifier: presetIdentifier,
                goalType: goalType,
                goalValue: goalType == .none ? nil : goalValue,
                goalUnit: goalType == .none ? nil : goalUnit,
                frequencyType: frequencyType,
                timesPerPeriod: resolvedTimesPerPeriod,
                tracking: tracking,
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
            task.goalType = goalType
            task.goalValue = goalType == .none ? nil : goalValue
            task.goalUnit = goalType == .none ? nil : goalUnit
            task.frequencyType = frequencyType
            task.timesPerPeriod = resolvedTimesPerPeriod
            task.tracking = tracking
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
