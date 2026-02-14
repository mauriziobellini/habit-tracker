import Foundation
import SwiftUI

@Observable
final class TaskStatsViewModel {
    let task: HabitTask

    var windowStart: Date
    var windowEnd: Date
    var showingTimeWindowPicker = false
    var showingManageCompletions = false

    init(task: HabitTask) {
        self.task = task
        // Default: last 30 days
        let now = Date.now
        let end = Calendar.current.startOfDay(for: now)
        self.windowEnd = end
        self.windowStart = Calendar.current.date(byAdding: .day, value: -30, to: end)!
    }

    // MARK: - Computed Stats

    var completionCount: Int {
        StatisticsService.completionCount(for: task, from: windowStart, to: windowEnd)
    }

    var completionPercentage: Double {
        StatisticsService.completionPercentage(for: task, from: windowStart, to: windowEnd)
    }

    var trendData: [StatisticsService.TrendPoint] {
        StatisticsService.trendData(for: task, from: windowStart, to: windowEnd)
    }

    var currentStreak: Int {
        task.currentStreak()
    }

    var windowDescription: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return "\(formatter.string(from: windowStart)) – \(formatter.string(from: windowEnd))"
    }

    func updateWindow(start: Date, end: Date) {
        windowStart = Calendar.current.startOfDay(for: start)
        windowEnd = Calendar.current.startOfDay(for: end)
    }
}
