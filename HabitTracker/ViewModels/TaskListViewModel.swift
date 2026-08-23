import Foundation
import SwiftData
import SwiftUI

@Observable
final class TaskListViewModel {
    var selectedCategoryID: UUID?
    var showingTaskSelector = false
    var showingSettings = false
    var showingGeneralStats = false
    var taskToEdit: HabitTask?
    var taskForStats: HabitTask?
    var taskToDelete: HabitTask?
    var showDeleteConfirmation = false

    // Habit summary bottom sheet (PRD - Habit strength §8). Replaces the tap-to-menu
    // confirmation dialog; Stats / Edit / Remove now live inside the sheet.
    var taskForSummary: HabitTask?
    var taskForCompletions: HabitTask?
    private var pendingSummaryAction: (action: HabitSummarySheetView.Action, task: HabitTask)?

    // Reward celebration
    var showingRewardCelebration = false
    var rewardCelebrationText = ""
    /// The habit the reward belongs to, so the overlay can name it.
    var rewardCelebrationHabit: CelebrationHabit?

    // Stage advance celebration (PRD - Habit strength §8)
    var showingStageCelebration = false
    var stageCelebration: HabitStageEvaluator.Transition?
    /// Advances waiting their turn. Several habits can cross a boundary on the same
    /// completion pass, and stacking overlays would bury them.
    private var queuedStageCelebrations: [HabitStageEvaluator.Transition] = []

    // First completion celebration (Experiment - Opt out notifications)
    var showingFirstCompletionPrompt = false
    var firstCompletionOffersReminderOptIn = false
    /// Kept past dismissal so the overlay does not lose the habit name mid fade-out.
    var firstCompletionHabit: CelebrationHabit?
    private var firstCompletionTask: HabitTask?

    // Freemium paywall (PRD - Freemium §6, §7)
    var showingPaywall = false
    var paywallSource = "add_habit"
    private var wantsSelectorAfterUnlock = false
    var premiumUnlocked = false

    /// Decide what happens when the user taps "+": open the selector or show the paywall.
    func handleAddTapped(currentHabitCount: Int, isPremium: Bool, analytics: AnalyticsService = NoOpAnalyticsService()) {
        analytics.track(.addHabitTapped, properties: [
            "habit_count_before": AnalyticsBucket.habitCount(currentHabitCount),
            "is_premium": String(isPremium),
        ])
        if HabitAccessPolicy.shouldPresentPaywallForNewHabit(
            currentHabitCount: currentHabitCount,
            isPremium: isPremium
        ) {
            presentPaywall(source: "add_habit", openSelectorOnUnlock: true)
        } else {
            showingTaskSelector = true
        }
    }

    /// Present the paywall (e.g. from the add button or a locked habit tap).
    func presentPaywall(source: String, openSelectorOnUnlock: Bool) {
        paywallSource = source
        wantsSelectorAfterUnlock = openSelectorOnUnlock
        premiumUnlocked = false
        showingPaywall = true
    }

    /// Called when the paywall sheet finishes dismissing. Continues the add-habit flow if the
    /// user unlocked premium while trying to create a habit (chained sheet, PRD - Freemium §8).
    func handlePaywallDismissed(analytics: AnalyticsService = NoOpAnalyticsService()) {
        // Measurement PRD §9: `paywall_dismissed` fires only when the sheet closed without a
        // successful purchase/restore in that session (abandon signal).
        if !premiumUnlocked {
            analytics.track(.paywallDismissed, properties: ["source": paywallSource])
        }
        if premiumUnlocked && wantsSelectorAfterUnlock {
            showingTaskSelector = true
        }
        premiumUnlocked = false
        wantsSelectorAfterUnlock = false
    }

    // MARK: - Habit summary bottom sheet

    func presentSummary(for task: HabitTask, isEligible: Bool, analytics: AnalyticsService = NoOpAnalyticsService()) {
        analytics.track(.habitSummaryOpened, properties: ["is_eligible": String(isEligible)])
        taskForSummary = task
    }

    /// Records the chosen action and dismisses the sheet. The action itself runs in
    /// `performPendingSummaryAction` once the sheet is gone — presenting a second
    /// sheet while this one is still on screen silently drops it.
    func requestSummaryAction(_ action: HabitSummarySheetView.Action, for task: HabitTask) {
        pendingSummaryAction = (action, task)
        taskForSummary = nil
    }

    func performPendingSummaryAction(analytics: AnalyticsService = NoOpAnalyticsService()) {
        guard let pending = pendingSummaryAction else { return }
        pendingSummaryAction = nil

        switch pending.action {
        case .stats:
            // Kept as the existing event so historical insights stay comparable.
            analytics.track(.statsOpened, properties: ["scope": "habit"])
            taskForStats = pending.task
        case .edit:
            taskToEdit = pending.task
        case .remove:
            confirmDelete(pending.task)
        case .manageCompletions:
            taskForCompletions = pending.task
        }
    }

    // MARK: - Stage advance celebration

    /// Queues celebratable advances and shows the first one.
    func enqueueStageCelebrations(
        _ transitions: [HabitStageEvaluator.Transition],
        analytics: AnalyticsService = NoOpAnalyticsService()
    ) {
        for transition in transitions where !transition.isAdvance {
            // Reversions are never celebrated, but they are worth measuring.
            analytics.track(.stageReverted, properties: [
                "from_stage": transition.from.rawValue,
                "to_stage": transition.to.rawValue,
            ])
        }

        queuedStageCelebrations.append(contentsOf: transitions.filter { $0.isCelebratable })
        showNextStageCelebrationIfIdle(analytics: analytics)
    }

    private func showNextStageCelebrationIfIdle(analytics: AnalyticsService) {
        // Never stack overlays. If a reward or first-completion celebration owns the
        // screen, the advance waits — their dismiss handlers drain this queue. An
        // advance dropped here is not lost for good either: the evaluator re-offers
        // anything above the celebrated high-water mark.
        guard !showingStageCelebration,
              !showingRewardCelebration,
              !showingFirstCompletionPrompt,
              !queuedStageCelebrations.isEmpty else { return }
        let next = queuedStageCelebrations.removeFirst()
        stageCelebration = next
        showingStageCelebration = true
        analytics.track(.stageAdvanceCelebrationShown, properties: [
            "from_stage": next.from.rawValue,
            "to_stage": next.to.rawValue,
            "notification_prompt_shown": String(!next.task.notificationEnabled),
        ])
    }

    /// Turns the reminder on for the habit that just advanced, reusing the same
    /// permission path as the first-completion prompt.
    @MainActor
    func enableNotificationsFromStageCelebration(
        at time: Date,
        context: ModelContext,
        analytics: AnalyticsService = NoOpAnalyticsService()
    ) {
        guard let transition = stageCelebration else { return }
        let task = transition.task

        task.notificationEnabled = true
        task.notificationTime = time
        task.updatedAt = .now

        analytics.track(.stageAdvanceCelebrationAction, properties: ["action": "enabled_notifications"])

        Task { @MainActor in
            let wasPrompted = await NotificationService.shared.authorizationStatus() == .notDetermined
            let granted = await NotificationService.shared.requestAuthorization()
            if granted {
                NotificationService.shared.rescheduleNotifications(for: task)
            }
            analytics.track(.notificationPermissionResult, properties: [
                "source": "stage_celebration",
                "granted": String(granted),
                "was_prompted": String(wasPrompted),
            ])
        }

        dismissStageCelebration(context: context, analytics: analytics, trackAction: false)
    }

    @MainActor
    func dismissStageCelebration(
        context: ModelContext,
        analytics: AnalyticsService = NoOpAnalyticsService(),
        trackAction: Bool = true
    ) {
        if let transition = stageCelebration {
            HabitStageEvaluator.markCelebrated(transition, context: context)
            if trackAction {
                analytics.track(.stageAdvanceCelebrationAction, properties: ["action": "dismissed"])
            }
        }
        stageCelebration = nil
        showingStageCelebration = false
        showNextStageCelebrationIfIdle(analytics: analytics)
    }

    // MARK: - First completion celebration

    /// Celebrate the very first completion and, when that habit has no reminder, use the
    /// moment to offer one (Experiment - Opt out notifications).
    func presentFirstCompletionPrompt(for task: HabitTask, analytics: AnalyticsService = NoOpAnalyticsService()) {
        firstCompletionTask = task
        firstCompletionHabit = CelebrationHabit(task: task)
        firstCompletionOffersReminderOptIn = !task.notificationEnabled
        showingFirstCompletionPrompt = true
        analytics.track(.firstCompletionPromptShown, properties: [
            "variant": firstCompletionOffersReminderOptIn ? "with_optin" : "congrats_only",
        ])
    }

    /// Turns the reminder on for the celebrated habit and schedules it once the system grants
    /// permission. The habit keeps `notificationEnabled` even if permission is denied, so the
    /// intent survives if the user later allows notifications in Settings.
    @MainActor
    func enableReminderFromFirstCompletionPrompt(
        at time: Date,
        analytics: AnalyticsService = NoOpAnalyticsService()
    ) {
        guard let task = firstCompletionTask else { return }

        task.notificationEnabled = true
        task.notificationTime = time
        task.updatedAt = .now

        analytics.track(.firstCompletionPromptAction, properties: ["action": "enable_reminder"])

        Task { @MainActor in
            let wasPrompted = await NotificationService.shared.authorizationStatus() == .notDetermined
            let granted = await NotificationService.shared.requestAuthorization()
            if granted {
                NotificationService.shared.rescheduleNotifications(for: task)
            }
            analytics.track(.notificationPermissionResult, properties: [
                "source": "first_completion_prompt",
                "granted": String(granted),
                "was_prompted": String(wasPrompted),
            ])
        }

        dismissFirstCompletionPrompt()
    }

    func dismissFirstCompletionPrompt(analytics: AnalyticsService? = nil) {
        analytics?.track(.firstCompletionPromptAction, properties: [
            "action": firstCompletionOffersReminderOptIn ? "dismiss" : "acknowledge",
        ])
        showingFirstCompletionPrompt = false
        firstCompletionTask = nil
        showNextStageCelebrationIfIdle(analytics: analytics ?? NoOpAnalyticsService())
    }

    func dismissRewardCelebration(analytics: AnalyticsService = NoOpAnalyticsService()) {
        showingRewardCelebration = false
        showNextStageCelebrationIfIdle(analytics: analytics)
    }

    /// Filter tasks by the selected category. `nil` means "All".
    func filteredTasks(_ tasks: [HabitTask]) -> [HabitTask] {
        guard let categoryID = selectedCategoryID else {
            return tasks.sorted { $0.sortOrder < $1.sortOrder }
        }
        return tasks
            .filter { $0.category?.id == categoryID }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    func confirmDelete(_ task: HabitTask) {
        taskToDelete = task
        showDeleteConfirmation = true
    }

    @MainActor
    func deleteTask(
        context: ModelContext,
        analytics: AnalyticsService = NoOpAnalyticsService(),
        strengthCache: HabitStrengthCache? = nil
    ) {
        guard let task = taskToDelete else { return }
        analytics.track(.habitDeleted, properties: ["frequency": task.frequencyType.analyticsValue])
        // Deleting a habit previously left its notifications pending, so a reminder
        // or strength nudge could arrive naming a habit that no longer exists.
        NotificationService.shared.cancelAllNotifications(for: task)
        strengthCache?.invalidate(taskID: task.id)
        context.delete(task)
        taskToDelete = nil
    }
}
