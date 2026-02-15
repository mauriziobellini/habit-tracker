import Foundation
import SwiftData
import SwiftUI

@Observable
final class TaskStatsViewModel {
    let task: HabitTask
    var weekStartDay: Int = 1

    var windowStart: Date
    var windowEnd: Date
    var showingTimeWindowPicker = false
    var showingManageCompletions = false

    init(task: HabitTask, weekStartDay: Int = 1) {
        self.task = task
        self.weekStartDay = weekStartDay
        // Default: last 30 days including today
        let cal = Calendar.current
        let todayStart = cal.startOfDay(for: .now)
        // End of today so current day's completions are included
        self.windowEnd = cal.date(byAdding: .day, value: 1, to: todayStart)!.addingTimeInterval(-1)
        self.windowStart = cal.date(byAdding: .day, value: -30, to: todayStart)!
    }

    // MARK: - Load Week Start Day

    @MainActor
    func loadSettings(from context: ModelContext) {
        let settings = AppSettings.shared(in: context)
        weekStartDay = settings.weekStartDay
    }

    // MARK: - Computed Stats

    var completionCount: Int {
        StatisticsService.completionCount(for: task, from: windowStart, to: windowEnd)
    }

    var completionPercentage: Double {
        StatisticsService.completionPercentage(for: task, from: windowStart, to: windowEnd)
    }

    var trendData: [StatisticsService.TrendPoint] {
        StatisticsService.trendData(for: task, from: windowStart, to: windowEnd, weekStartDay: weekStartDay)
    }

    var currentStreak: Int {
        task.currentStreak()
    }

    var windowDescription: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return "\(formatter.string(from: windowStart)) \u{2013} \(formatter.string(from: windowEnd))"
    }

    func updateWindow(start: Date, end: Date) {
        let cal = Calendar.current
        windowStart = cal.startOfDay(for: start)
        // End of the selected end day so all completions that day are included
        let endStart = cal.startOfDay(for: end)
        windowEnd = cal.date(byAdding: .day, value: 1, to: endStart)!.addingTimeInterval(-1)
    }
}
