import Foundation
import UserNotifications

/// Manages local notification scheduling for habit tasks (FR-7, data-model section 7).
@MainActor
final class NotificationService {
    static let shared = NotificationService()
    private let center = UNUserNotificationCenter.current()

    private init() {}

    // MARK: - Permission

    /// Request notification authorization. Call early (e.g., when user enables a notification).
    func requestAuthorization() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    // MARK: - Schedule

    /// Schedule notifications for a task based on its frequency and notification settings.
    func scheduleNotifications(for task: HabitTask) {
        guard task.notificationEnabled,
              let notificationTime = task.notificationTime else { return }

        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: notificationTime)
        let minute = calendar.component(.minute, from: notificationTime)

        // Determine which weekdays to schedule
        let weekdays: [Int] // ISO 8601: 1=Mon...7=Sun
        switch task.frequencyType {
        case .daily:
            weekdays = Array(1...7)
        case .specificDays:
            weekdays = task.scheduledDays
        case .everyWeek:
            weekdays = Array(1...7)
        }

        for isoWeekday in weekdays {
            // Convert ISO weekday (1=Mon) to Apple weekday (1=Sun, 2=Mon...)
            let appleWeekday = isoWeekday == 7 ? 1 : isoWeekday + 1

            var dateComponents = DateComponents()
            dateComponents.hour = hour
            dateComponents.minute = minute
            dateComponents.weekday = appleWeekday

            let trigger = UNCalendarNotificationTrigger(
                dateMatching: dateComponents,
                repeats: true
            )

            let content = UNMutableNotificationContent()
            content.title = "Habit Reminder"
            content.body = "Time to \(task.title)!"
            content.sound = .default

            let identifier = notificationIdentifier(for: task, weekday: isoWeekday)
            let request = UNNotificationRequest(
                identifier: identifier,
                content: content,
                trigger: trigger
            )

            center.add(request)
        }
    }

    // MARK: - Cancel

    /// Cancel all pending notifications for a task.
    func cancelNotifications(for task: HabitTask) {
        let identifiers = (1...7).map { notificationIdentifier(for: task, weekday: $0) }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    // MARK: - Reschedule

    /// Cancel and re-schedule (useful when task is edited).
    func rescheduleNotifications(for task: HabitTask) {
        cancelNotifications(for: task)
        scheduleNotifications(for: task)
    }

    // MARK: - Suppress Today

    /// Cancel today's pending notification when the task is completed early.
    func suppressTodayNotification(for task: HabitTask) {
        let calendar = Calendar.current
        let isoWeekday = calendar.isoWeekday(for: .now)
        let identifier = notificationIdentifier(for: task, weekday: isoWeekday)
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    // MARK: - Helpers

    private func notificationIdentifier(for task: HabitTask, weekday: Int) -> String {
        "task-\(task.id.uuidString)-day-\(weekday)"
    }
}
