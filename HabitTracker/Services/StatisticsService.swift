import Foundation

/// Computes task statistics from `TaskCompletion` records (FR-4, data-model section 5).
enum StatisticsService {
    /// A single data point for the trend line chart.
    struct TrendPoint: Identifiable {
        let id = UUID()
        let date: Date
        let count: Int
    }

    // MARK: - Completion Count

    /// Number of completions within a date range.
    static func completionCount(
        for task: HabitTask,
        from startDate: Date,
        to endDate: Date
    ) -> Int {
        task.completions.filter { c in
            c.completedAt >= startDate && c.completedAt <= endDate
        }.count
    }

    // MARK: - Expected Completions

    /// Number of completions expected within a date range based on frequency settings.
    static func expectedCompletions(
        for task: HabitTask,
        from startDate: Date,
        to endDate: Date,
        calendar: Calendar = .current
    ) -> Int {
        var count = 0
        var date = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate)

        while date <= end {
            let weekday = calendar.isoWeekday(for: date)
            if task.isScheduled(forWeekday: weekday) {
                count += task.timesPerDay
            }
            date = calendar.date(byAdding: .day, value: 1, to: date)!
        }

        return count
    }

    // MARK: - Completion Percentage

    /// Percentage of completions achieved vs expected.
    static func completionPercentage(
        for task: HabitTask,
        from startDate: Date,
        to endDate: Date,
        calendar: Calendar = .current
    ) -> Double {
        let expected = expectedCompletions(for: task, from: startDate, to: endDate, calendar: calendar)
        guard expected > 0 else { return 0 }
        let actual = completionCount(for: task, from: startDate, to: endDate)
        return min(Double(actual) / Double(expected) * 100.0, 100.0)
    }

    // MARK: - Trend Line Data

    /// Aggregated completion counts for trend line chart.
    /// - 7-day buckets if window < 60 days
    /// - Monthly buckets if window >= 60 days
    static func trendData(
        for task: HabitTask,
        from startDate: Date,
        to endDate: Date,
        calendar: Calendar = .current
    ) -> [TrendPoint] {
        let days = calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 0
        let useMonthly = days >= 60

        if useMonthly {
            return monthlyTrend(for: task, from: startDate, to: endDate, calendar: calendar)
        } else {
            return weeklyTrend(for: task, from: startDate, to: endDate, calendar: calendar)
        }
    }

    // MARK: - Private Bucketing

    private static func weeklyTrend(
        for task: HabitTask,
        from startDate: Date,
        to endDate: Date,
        calendar: Calendar = .current
    ) -> [TrendPoint] {
        var points: [TrendPoint] = []
        var bucketStart = calendar.startOfDay(for: startDate)

        while bucketStart < endDate {
            let bucketEnd = min(
                calendar.date(byAdding: .day, value: 7, to: bucketStart)!,
                endDate
            )
            let count = completionCount(for: task, from: bucketStart, to: bucketEnd)
            points.append(TrendPoint(date: bucketStart, count: count))
            bucketStart = calendar.date(byAdding: .day, value: 7, to: bucketStart)!
        }

        return points
    }

    private static func monthlyTrend(
        for task: HabitTask,
        from startDate: Date,
        to endDate: Date,
        calendar: Calendar = .current
    ) -> [TrendPoint] {
        var points: [TrendPoint] = []
        var bucketStart = calendar.startOfDay(for: startDate)

        while bucketStart < endDate {
            let bucketEnd = min(
                calendar.date(byAdding: .month, value: 1, to: bucketStart)!,
                endDate
            )
            let count = completionCount(for: task, from: bucketStart, to: bucketEnd)
            points.append(TrendPoint(date: bucketStart, count: count))
            bucketStart = calendar.date(byAdding: .month, value: 1, to: bucketStart)!
        }

        return points
    }
}
