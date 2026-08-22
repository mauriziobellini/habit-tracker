import Foundation

/// Schedules the two habit-strength proximity pushes (PRD - Habit strength §8).
///
/// iOS will not reliably run code at 09:00 and this project has no background
/// refresh task, so tomorrow's notification is scheduled ahead of time and
/// re-validated on the next foreground. A user who never opens the app therefore
/// receives a push computed from slightly stale data — an accepted trade-off, since
/// the alternative is no nudge at all for exactly the users who need one.
@MainActor
enum StrengthNotificationScheduler {

    /// Local hour at which both pushes fire (PRD §8).
    private static let deliveryHour = 9

    static func refresh(
        tasks: [HabitTask],
        weekStartDay: Int,
        now: Date = .now,
        calendar: Calendar = .current
    ) async {
        let service = NotificationService.shared

        // Never prompt from here — this runs unattended on foreground.
        guard await service.authorizationStatus() == .authorized else {
            for task in tasks {
                service.cancelStrengthNotifications(for: task.id)
            }
            return
        }

        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: now),
              let fireDate = calendar.date(
                bySettingHour: deliveryHour, minute: 0, second: 0, of: tomorrow
              ) else { return }

        let tomorrowWeekday = calendar.isoWeekday(for: tomorrow)

        for task in tasks {
            // Clear first: a stale push whose projection no longer holds must not
            // survive into tomorrow.
            service.cancelStrengthNotifications(for: task.id)

            // A Mon/Wed/Fri habit should not be nudged on a Tuesday.
            guard task.isScheduled(forWeekday: tomorrowWeekday) else { continue }

            let current = HabitStrengthService.strength(
                for: task, on: tomorrow, calendar: calendar, weekStartDay: weekStartDay
            )

            let afterMiss = HabitStrengthService.projectedStrengthAssumingMiss(
                for: task, on: tomorrow, calendar: calendar, weekStartDay: weekStartDay
            )
            let afterCompletion = HabitStrengthService.projectedStrength(
                for: task, assumingCompletionOn: tomorrow,
                calendar: calendar, weekStartDay: weekStartDay
            )

            // At most one push per habit per day. Reversion wins when both apply:
            // losing ground is the more urgent message, and a user with fifteen
            // habits should not wake up to fifteen notifications.
            if afterMiss.stage < current.stage {
                service.scheduleStrengthNotification(
                    for: task,
                    kind: .reversion,
                    title: title(for: task, stage: current.stage),
                    body: NSLocalizedString(
                        "One check-in today keeps your habit formation on track.",
                        comment: ""
                    ),
                    at: fireDate
                )
            } else if afterCompletion.stage > current.stage {
                service.scheduleStrengthNotification(
                    for: task,
                    kind: .proximity,
                    title: title(for: task, stage: current.stage),
                    body: NSLocalizedString(
                        "One check-in today makes you leap to the next stage",
                        comment: ""
                    ),
                    at: fireDate
                )
            }
        }
    }

    /// `{habit name} · {stage}` (PRD §8). The habit name is user-typed, which is fine
    /// in a local notification but must never reach analytics.
    private static func title(for task: HabitTask, stage: HabitStage) -> String {
        "\(task.title) · \(stage.displayName)"
    }
}
