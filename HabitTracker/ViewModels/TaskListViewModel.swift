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
    var taskForMenu: HabitTask?
    var showingTaskMenu = false

    // Reward celebration
    var showingRewardCelebration = false
    var rewardCelebrationText = ""

    // First completion celebration (Experiment - Opt out notifications)
    var showingFirstCompletionPrompt = false
    var firstCompletionOffersReminderOptIn = false
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

    // MARK: - First completion celebration

    /// Celebrate the very first completion and, when that habit has no reminder, use the
    /// moment to offer one (Experiment - Opt out notifications).
    func presentFirstCompletionPrompt(for task: HabitTask, analytics: AnalyticsService = NoOpAnalyticsService()) {
        firstCompletionTask = task
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

    func deleteTask(context: ModelContext, analytics: AnalyticsService = NoOpAnalyticsService()) {
        guard let task = taskToDelete else { return }
        analytics.track(.habitDeleted, properties: ["frequency": task.frequencyType.analyticsValue])
        context.delete(task)
        taskToDelete = nil
    }
}
