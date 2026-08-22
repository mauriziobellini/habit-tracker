import Foundation
import UserNotifications

/// Manages local notification scheduling for habit tasks (FR-7, data-model section 7).
@MainActor
final class NotificationService {
    static let shared = NotificationService()
    private let center = UNUserNotificationCenter.current()

    private init() {}

    // MARK: - Permission

    /// Current system authorization status. The system only shows the prompt while the status
    /// is `.notDetermined`, so call sites read this first to tell a real prompt from a no-op.
    func authorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

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

        // Determine which weekdays to schedule.
        // Weekly/monthly habits are visible every day until their period quota is
        // met, so a daily reminder is appropriate; specific-days reminders fire
        // only on the scheduled weekdays. (v1: reminders are not suppressed once a
        // weekly/monthly period is complete — tracked as a future enhancement.)
        let weekdays: [Int] // ISO 8601: 1=Mon...7=Sun
        switch task.frequencyType {
        case .daily, .weekly, .monthly, .everyWeek:
            weekdays = Array(1...7)
        case .specificDays:
            weekdays = task.scheduledDays
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
            content.title = NSLocalizedString("Habit Reminder", comment: "")
            content.body = String(format: NSLocalizedString("Time to %@!", comment: ""), task.title)
            content.sound = .default

            let identifier = reminderIdentifier(for: task.id, weekday: isoWeekday)
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
        center.removePendingNotificationRequests(withIdentifiers: reminderIdentifiers(for: task.id))
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
        let identifier = reminderIdentifier(for: task.id, weekday: isoWeekday)
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    // MARK: - Habit strength notifications

    /// Category shared by both proximity pushes, carrying the Mark done / Later
    /// actions (PRD - Habit strength §10.9).
    static let strengthCategoryIdentifier = "HABIT_STRENGTH"
    static let markDoneActionIdentifier = "MARK_DONE"
    static let snoozeActionIdentifier = "SNOOZE"

    /// Which of the two habit-strength pushes a request is.
    enum StrengthNotificationKind: String {
        case proximity
        case reversion
    }

    /// Registers the actionable category. Must run before any notification can be
    /// delivered, otherwise the actions silently do not appear.
    func registerNotificationCategories() {
        let markDone = UNNotificationAction(
            identifier: Self.markDoneActionIdentifier,
            title: NSLocalizedString("Mark done", comment: ""),
            // No `.foreground`: the point is to complete without opening the app.
            options: []
        )
        let snooze = UNNotificationAction(
            identifier: Self.snoozeActionIdentifier,
            title: NSLocalizedString("Later", comment: ""),
            options: []
        )
        let category = UNNotificationCategory(
            identifier: Self.strengthCategoryIdentifier,
            actions: [markDone, snooze],
            intentIdentifiers: [],
            options: []
        )
        center.setNotificationCategories([category])
    }

    /// Schedules one habit-strength push.
    func scheduleStrengthNotification(
        for task: HabitTask,
        kind: StrengthNotificationKind,
        title: String,
        body: String,
        at date: Date
    ) {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = calendar.component(.hour, from: date)
        components.minute = calendar.component(.minute, from: date)

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = Self.strengthCategoryIdentifier

        let request = UNNotificationRequest(
            identifier: strengthIdentifier(for: task.id, kind: kind),
            content: content,
            // Not repeating: the projection is only valid for the day it was computed.
            trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        )
        center.add(request)
    }

    /// Cancels both habit-strength pushes for a habit.
    ///
    /// Separate from `cancelNotifications(for:)` on purpose: that method clears the
    /// seven reminder identifiers and is called by `rescheduleNotifications` on every
    /// habit edit, which would otherwise wipe these out as collateral damage.
    func cancelStrengthNotifications(for taskID: UUID) {
        center.removePendingNotificationRequests(
            withIdentifiers: StrengthNotificationKind.allIdentifiers(for: taskID)
        )
    }

    /// Cancels every notification for a habit, reminders included. Called on delete —
    /// habit deletion previously left reminders pending, so a push could arrive
    /// naming a habit that no longer exists.
    func cancelAllNotifications(for task: HabitTask) {
        cancelAllNotifications(forTaskID: task.id)
    }

    /// Same, by identifier: the orphan sweep no longer has a `HabitTask` to work from.
    func cancelAllNotifications(forTaskID taskID: UUID) {
        let identifiers = allIdentifiers(for: taskID)
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        // A reminder already sitting in Notification Center outlives the habit too.
        center.removeDeliveredNotifications(withIdentifiers: identifiers)
    }

    /// Removes every request belonging to a habit that no longer exists.
    ///
    /// Reminders are repeating weekly triggers, so a habit deleted by a build that
    /// did not cancel them keeps firing forever. Cancelling on delete only helps from
    /// now on; this sweep is what clears the requests already on users' devices.
    /// Identifiers this service did not create are left untouched.
    ///
    /// - Parameter livingTaskIDs: evaluated *after* the system's requests are read, so
    ///   a habit created while this runs cannot be mistaken for an orphan and have its
    ///   brand-new reminders swept away.
    func removeOrphanedNotifications(livingTaskIDs: () -> Set<UUID>) async {
        let pending = await center.pendingNotificationRequests().map(\.identifier)
        let delivered = await center.deliveredNotifications().map(\.request.identifier)

        let scheduled = Set((pending + delivered).compactMap(Self.taskID(fromIdentifier:)))
        guard !scheduled.isEmpty else { return }

        for taskID in scheduled.subtracting(livingTaskIDs()) {
            cancelAllNotifications(forTaskID: taskID)
        }
    }

    func strengthIdentifier(for taskID: UUID, kind: StrengthNotificationKind) -> String {
        "strength-\(taskID.uuidString)-\(kind.rawValue)"
    }

    /// Recovers the habit ID from a habit-strength notification identifier.
    ///
    /// `nonisolated` because it is pure string parsing, and the notification
    /// delegate needs it before it has hopped to the main actor.
    nonisolated static func taskID(fromStrengthIdentifier identifier: String) -> UUID? {
        let parts = identifier.split(separator: "-", omittingEmptySubsequences: false)
        // "strength", then the five dash-separated UUID groups, then the kind.
        guard parts.count == 7, parts[0] == "strength" else { return nil }
        return UUID(uuidString: parts[1...5].joined(separator: "-"))
    }

    /// Recovers the habit ID from any identifier this service issues, reminder or
    /// strength push. `nil` means the identifier came from somewhere else and must
    /// be left alone.
    nonisolated static func taskID(fromIdentifier identifier: String) -> UUID? {
        if let taskID = taskID(fromStrengthIdentifier: identifier) { return taskID }
        let parts = identifier.split(separator: "-", omittingEmptySubsequences: false)
        // "task", the five dash-separated UUID groups, "day", then the ISO weekday.
        guard parts.count == 8, parts[0] == "task", parts[6] == "day" else { return nil }
        return UUID(uuidString: parts[1...5].joined(separator: "-"))
    }

    // MARK: - Helpers

    private func reminderIdentifier(for taskID: UUID, weekday: Int) -> String {
        "task-\(taskID.uuidString)-day-\(weekday)"
    }

    /// Every weekday slot, not just the scheduled ones: the habit's frequency may
    /// have changed since the requests were added.
    private func reminderIdentifiers(for taskID: UUID) -> [String] {
        (1...7).map { reminderIdentifier(for: taskID, weekday: $0) }
    }

    private func allIdentifiers(for taskID: UUID) -> [String] {
        reminderIdentifiers(for: taskID) + StrengthNotificationKind.allIdentifiers(for: taskID)
    }
}

extension NotificationService.StrengthNotificationKind: CaseIterable {
    static func allIdentifiers(for taskID: UUID) -> [String] {
        allCases.map { "strength-\(taskID.uuidString)-\($0.rawValue)" }
    }
}
