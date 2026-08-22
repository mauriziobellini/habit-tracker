import Foundation
import SwiftData
import UserNotifications

/// Handles the Mark done / Later actions on habit-strength notifications
/// (PRD - Habit strength §10.9).
///
/// "Mark done" completes the habit without launching the app, so it runs outside
/// the SwiftUI hierarchy and needs its own `ModelContext` — taken from the app's
/// shared container, never a new one, since a second container over the same store
/// would write into a parallel universe.
final class NotificationActionHandler: NSObject, UNUserNotificationCenterDelegate {
    private let container: ModelContainer
    private let weekStartDay: () -> Int

    init(container: ModelContainer, weekStartDay: @escaping () -> Int = { 1 }) {
        self.container = container
        self.weekStartDay = weekStartDay
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let identifier = response.notification.request.identifier
        let action = response.actionIdentifier

        Task { @MainActor in
            defer { completionHandler() }

            guard let taskID = NotificationService.taskID(fromStrengthIdentifier: identifier) else {
                return
            }

            switch action {
            case NotificationService.markDoneActionIdentifier:
                recordCompletion(taskID: taskID)
            case NotificationService.snoozeActionIdentifier:
                // "Later" just clears today's nudge; the next foreground pass will
                // decide afresh whether a push is still warranted.
                NotificationService.shared.cancelStrengthNotifications(for: taskID)
            default:
                break
            }
        }
    }

    @MainActor
    private func recordCompletion(taskID: UUID) {
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<HabitTask>(
            predicate: #Predicate { $0.id == taskID }
        )
        // A deleted habit is a normal outcome here, not an error: the push may have
        // been delivered before the cancellation landed.
        guard let task = try? context.fetch(descriptor).first else { return }

        // Honour the same over-completion rule the task list enforces, so the
        // notification cannot push a habit past its period quota.
        guard PeriodService.canAcceptCompletion(
            for: task, on: .now, weekStartDay: weekStartDay()
        ) else { return }

        context.insert(TaskCompletion(task: task))
        try? context.save()
    }
}
