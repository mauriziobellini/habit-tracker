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
