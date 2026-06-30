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

    /// Raw number of `TaskCompletion` records within a date range (no crediting).
    static func rawCompletionCount(
        for task: HabitTask,
        from startDate: Date,
        to endDate: Date
    ) -> Int {
        task.completions.filter { c in
            c.completedAt >= startDate && c.completedAt <= endDate
        }.count
    }

    /// Stat-credited completion count within a date range, honoring the task's
    /// tracking mode (PRD §6):
    /// - `eachCompletion` (weekly/monthly/specific days): every raw completion counts.
    /// - `periodComplete` and all daily habits: one credit per fully-completed period.
    static func completionCount(
        for task: HabitTask,
        from startDate: Date,
        to endDate: Date,
        weekStartDay: Int = 1,
        calendar: Calendar = .current
    ) -> Int {
        switch PeriodService.effectiveTracking(for: task) {
        case .eachCompletion:
            return rawCompletionCount(for: task, from: startDate, to: endDate)
        case .periodComplete:
            let n = PeriodService.target(for: task)
            let periods = periodsInWindow(
                for: task, from: startDate, to: endDate,
                calendar: calendar, weekStartDay: weekStartDay
            )
            return periods.reduce(0) { sum, period in
                let c = task.completions.filter {
                    $0.completedAt >= period.start && $0.completedAt < period.end
                }.count
                return sum + (c >= n ? 1 : 0)
            }
        }
    }

    // MARK: - Expected Completions

    /// Number of completions expected within a date range based on frequency and
    /// tracking. For `periodComplete`/daily this is the number of periods (one
    /// credit each); for `eachCompletion` it is `N` per period.
    static func expectedCompletions(
        for task: HabitTask,
        from startDate: Date,
        to endDate: Date,
        weekStartDay: Int = 1,
        calendar: Calendar = .current
    ) -> Int {
        let periods = periodsInWindow(
            for: task, from: startDate, to: endDate,
            calendar: calendar, weekStartDay: weekStartDay
        )
        switch PeriodService.effectiveTracking(for: task) {
        case .periodComplete:
            return periods.count
        case .eachCompletion:
            return periods.count * PeriodService.target(for: task)
        }
    }

    // MARK: - Completion Percentage

    /// Percentage of completions achieved vs expected.
    static func completionPercentage(
        for task: HabitTask,
        from startDate: Date,
        to endDate: Date,
        weekStartDay: Int = 1,
        calendar: Calendar = .current
    ) -> Double {
        let expected = expectedCompletions(
            for: task, from: startDate, to: endDate,
            weekStartDay: weekStartDay, calendar: calendar
        )
        guard expected > 0 else { return 0 }
        let actual = completionCount(
            for: task, from: startDate, to: endDate,
            weekStartDay: weekStartDay, calendar: calendar
        )
        return min(Double(actual) / Double(expected) * 100.0, 100.0)
    }

    // MARK: - Period enumeration

    /// All period intervals (by the task's frequency) that overlap `[from, to]`,
    /// starting from the period containing `from`.
    static func periodsInWindow(
        for task: HabitTask,
        from startDate: Date,
        to endDate: Date,
        calendar: Calendar = .current,
        weekStartDay: Int = 1
    ) -> [(start: Date, end: Date)] {
        guard startDate <= endDate else { return [] }
        var result: [(start: Date, end: Date)] = []
        var bounds = PeriodService.periodBounds(
            for: task, on: startDate, calendar: calendar, weekStartDay: weekStartDay
        )
        var guardCount = 0
        while bounds.start <= endDate && guardCount < 100_000 {
            result.append(bounds)
            bounds = PeriodService.periodBounds(
                for: task, on: bounds.end, calendar: calendar, weekStartDay: weekStartDay
            )
            guardCount += 1
        }
        return result
    }

    // MARK: - Trend Line Data

    /// Aggregated completion counts for trend line chart.
    /// - 7-day buckets if window < 60 days
    /// - Monthly buckets if window >= 60 days
    static func trendData(
        for task: HabitTask,
        from startDate: Date,
        to endDate: Date,
        weekStartDay: Int = 1,
        calendar: Calendar = .current
    ) -> [TrendPoint] {
        let days = calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 0
        let useMonthly = days >= 60

        if useMonthly {
            return monthlyTrend(for: task, from: startDate, to: endDate, weekStartDay: weekStartDay, calendar: calendar)
        } else {
            return weeklyTrend(for: task, from: startDate, to: endDate, weekStartDay: weekStartDay, calendar: calendar)
        }
    }

    /// Aggregated completion counts for all tasks within a date range.
    static func trendDataForAll(
        tasks: [HabitTask],
        from startDate: Date,
        to endDate: Date,
        weekStartDay: Int = 1,
        calendar: Calendar = .current
    ) -> [TrendPoint] {
        let days = calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 0
        let useMonthly = days >= 60

        if useMonthly {
            return monthlyTrendForAll(tasks: tasks, from: startDate, to: endDate, weekStartDay: weekStartDay, calendar: calendar)
        } else {
            return weeklyTrendForAll(tasks: tasks, from: startDate, to: endDate, weekStartDay: weekStartDay, calendar: calendar)
        }
    }

    /// Total stat-credited completions across multiple tasks in a date range.
    static func totalCompletionCount(
        tasks: [HabitTask],
        from startDate: Date,
        to endDate: Date,
        weekStartDay: Int = 1,
        calendar: Calendar = .current
    ) -> Int {
        tasks.reduce(0) { sum, task in
            sum + completionCount(
                for: task, from: startDate, to: endDate,
                weekStartDay: weekStartDay, calendar: calendar
            )
        }
    }

    /// Average completion percentage across multiple tasks in a date range.
    static func averageCompletionPercentage(
        tasks: [HabitTask],
        from startDate: Date,
        to endDate: Date,
        weekStartDay: Int = 1,
        calendar: Calendar = .current
    ) -> Double {
        guard !tasks.isEmpty else { return 0 }
        let total = tasks.reduce(0.0) { sum, task in
            sum + completionPercentage(
                for: task, from: startDate, to: endDate,
                weekStartDay: weekStartDay, calendar: calendar
            )
        }
        return total / Double(tasks.count)
    }

    // MARK: - Private Bucketing

    private static func weeklyTrend(
        for task: HabitTask,
        from startDate: Date,
        to endDate: Date,
        weekStartDay: Int = 1,
        calendar: Calendar = .current
    ) -> [TrendPoint] {
        var points: [TrendPoint] = []
        // Align bucket start to the configured week start day
        var bucketStart = calendar.startOfDay(for: startDate)
        let currentWeekday = calendar.isoWeekday(for: bucketStart)
        let daysSinceWeekStart = (currentWeekday - weekStartDay + 7) % 7
        bucketStart = calendar.date(byAdding: .day, value: -daysSinceWeekStart, to: bucketStart)!

        while bucketStart < endDate {
            let bucketEnd = min(
                calendar.date(byAdding: .day, value: 7, to: bucketStart)!,
                endDate
            )
            // Credit completions per the tracking mode so the trend matches the
            // headline completion count (PRD §6 Stats accounting).
            let count = completionCount(
                for: task, from: bucketStart, to: bucketEnd,
                weekStartDay: weekStartDay, calendar: calendar
            )
            points.append(TrendPoint(date: bucketStart, count: count))
            bucketStart = calendar.date(byAdding: .day, value: 7, to: bucketStart)!
        }

        return points
    }

    private static func weeklyTrendForAll(
        tasks: [HabitTask],
        from startDate: Date,
        to endDate: Date,
        weekStartDay: Int = 1,
        calendar: Calendar = .current
    ) -> [TrendPoint] {
        var points: [TrendPoint] = []
        var bucketStart = calendar.startOfDay(for: startDate)
        let currentWeekday = calendar.isoWeekday(for: bucketStart)
        let daysSinceWeekStart = (currentWeekday - weekStartDay + 7) % 7
        bucketStart = calendar.date(byAdding: .day, value: -daysSinceWeekStart, to: bucketStart)!

        while bucketStart < endDate {
            let bucketEnd = min(
                calendar.date(byAdding: .day, value: 7, to: bucketStart)!,
                endDate
            )
            let count = totalCompletionCount(
                tasks: tasks, from: bucketStart, to: bucketEnd,
                weekStartDay: weekStartDay, calendar: calendar
            )
            points.append(TrendPoint(date: bucketStart, count: count))
            bucketStart = calendar.date(byAdding: .day, value: 7, to: bucketStart)!
        }

        return points
    }

    private static func monthlyTrendForAll(
        tasks: [HabitTask],
        from startDate: Date,
        to endDate: Date,
        weekStartDay: Int = 1,
        calendar: Calendar = .current
    ) -> [TrendPoint] {
        var points: [TrendPoint] = []
        var bucketStart = calendar.startOfDay(for: startDate)

        while bucketStart < endDate {
            let bucketEnd = min(
                calendar.date(byAdding: .month, value: 1, to: bucketStart)!,
                endDate
            )
            let count = totalCompletionCount(
                tasks: tasks, from: bucketStart, to: bucketEnd,
                weekStartDay: weekStartDay, calendar: calendar
            )
            points.append(TrendPoint(date: bucketStart, count: count))
            bucketStart = calendar.date(byAdding: .month, value: 1, to: bucketStart)!
        }

        return points
    }

    private static func monthlyTrend(
        for task: HabitTask,
        from startDate: Date,
        to endDate: Date,
        weekStartDay: Int = 1,
        calendar: Calendar = .current
    ) -> [TrendPoint] {
        var points: [TrendPoint] = []
        var bucketStart = calendar.startOfDay(for: startDate)

        while bucketStart < endDate {
            let bucketEnd = min(
                calendar.date(byAdding: .month, value: 1, to: bucketStart)!,
                endDate
            )
            // Credit completions per the tracking mode (PRD §6 Stats accounting).
            let count = completionCount(
                for: task, from: bucketStart, to: bucketEnd,
                weekStartDay: weekStartDay, calendar: calendar
            )
            points.append(TrendPoint(date: bucketStart, count: count))
            bucketStart = calendar.date(byAdding: .month, value: 1, to: bucketStart)!
        }

        return points
    }
}
