import SwiftUI
import SwiftData

/// The consistency grid from the habit summary sheet (PRD - Habit strength §8).
///
/// Seven rows (weekdays) by one column per week, today in the rightmost column,
/// scrollable back through history. Deliberately carries no day numbers or weekday
/// letters: it exists to convey a feeling of consistency at a glance, not to be
/// read as a calendar.
struct HabitDailyGridView: View {
    @Environment(\.modelContext) private var modelContext

    let task: HabitTask
    let weekStartDay: Int
    /// Reference "today". Injectable so tests and previews are deterministic.
    var referenceDate: Date = .now
    let onTap: () -> Void

    /// Weeks visible without scrolling (PRD §8: 25 columns).
    private static let visibleWeeks = 25

    /// Hard cap on rendered history — two years is far more than the grid can
    /// usefully show and bounds the one-off day-set build.
    private static let maximumWeeks = 104

    private static let cellSize: CGFloat = 11
    private static let cellSpacing: CGFloat = 3

    /// Days with at least one completion. Built once when the sheet appears rather
    /// than filtering per cell — the grid renders ~175 cells before any scrolling.
    @State private var completedDays: Set<Date> = []

    private var calendar: Calendar { .current }

    private var accentColor: Color {
        TaskColor.from(token: task.colorToken).color
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Self.cellSpacing) {
                ForEach(weekStarts, id: \.self) { weekStart in
                    column(weekStart: weekStart)
                }
            }
            .padding(.horizontal, 2)
        }
        // Opens on the current week; there is nothing to the right of it to reach.
        .defaultScrollAnchor(.trailing)
        .frame(height: 7 * Self.cellSize + 6 * Self.cellSpacing)
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
        .task(id: task.id) { rebuildCompletedDays() }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier("habitDailyGrid")
    }

    private func column(weekStart: Date) -> some View {
        VStack(spacing: Self.cellSpacing) {
            ForEach(0..<7, id: \.self) { offset in
                cell(for: calendar.date(byAdding: .day, value: offset, to: weekStart) ?? weekStart)
            }
        }
    }

    @ViewBuilder
    private func cell(for day: Date) -> some View {
        RoundedRectangle(cornerRadius: 2.5)
            .fill(fillColor(for: day))
            .frame(width: Self.cellSize, height: Self.cellSize)
    }

    /// Three levels, not two. Days outside the habit's lifetime — before it was
    /// created, or still to come this week — are rendered fainter than missed days,
    /// so "couldn't have happened" never reads as "failed". The grid always spans at
    /// least 25 weeks, so a young habit would otherwise appear to have months of
    /// misses behind it.
    private func fillColor(for day: Date) -> Color {
        if completedDays.contains(day) { return accentColor }

        let today = calendar.startOfDay(for: referenceDate)
        if day > today || day < task.historyStart(calendar: calendar) {
            return accentColor.opacity(0.06)
        }

        return accentColor.opacity(0.18)
    }

    // MARK: - Geometry

    /// Week start dates, oldest first, ending with the week containing today.
    private var weekStarts: [Date] {
        let currentWeekStart = PeriodService.weekStart(
            for: referenceDate, calendar: calendar, weekStartDay: weekStartDay
        )
        let firstWeekStart = PeriodService.weekStart(
            for: task.historyStart(calendar: calendar),
            calendar: calendar,
            weekStartDay: weekStartDay
        )

        let weeksOfHistory = calendar.dateComponents(
            [.weekOfYear], from: firstWeekStart, to: currentWeekStart
        ).weekOfYear ?? 0

        // Always fill the visible width, even for a brand-new habit, so the grid
        // does not start as a lonely single column.
        let weekCount = min(Self.maximumWeeks, max(Self.visibleWeeks, weeksOfHistory + 1))

        return (0..<weekCount).reversed().compactMap { weeksBack in
            calendar.date(byAdding: .weekOfYear, value: -weeksBack, to: currentWeekStart)
        }
    }

    // MARK: - Data

    /// Highlighting uses **raw** completion presence, not period credit: a weekly
    /// `periodComplete` habit must still show the individual days it was done on
    /// (PRD §8).
    private func rebuildCompletedDays() {
        guard let start = weekStarts.first else { return }
        let end = calendar.date(byAdding: .day, value: 7, to: weekStarts.last ?? start) ?? start

        // Narrow by date in the store — the expensive dimension — then match the
        // habit in memory. Predicating on the optional `task` relationship is the
        // fragile part of SwiftData's predicate support, and the date-bounded
        // result set is already small.
        let descriptor = FetchDescriptor<TaskCompletion>(
            predicate: #Predicate { $0.completedAt >= start && $0.completedAt < end }
        )
        let rows = (try? modelContext.fetch(descriptor)) ?? task.completions
        let taskID = task.id

        completedDays = Set(
            rows
                .filter { $0.task?.id == taskID }
                .map { calendar.startOfDay(for: $0.completedAt) }
        )
    }

    private var accessibilityLabel: String {
        let format = NSLocalizedString(
            "Consistency grid, %lld days completed", comment: ""
        )
        return String(format: format, completedDays.count)
    }
}
