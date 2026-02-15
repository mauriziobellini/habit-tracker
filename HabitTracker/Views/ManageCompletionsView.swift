import SwiftUI
import SwiftData

/// Full-screen calendar for managing past task completions (FR-5).
/// Tap a completed day to un-complete; tap an incomplete day to mark as completed.
struct ManageCompletionsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let task: HabitTask

    @State private var displayedMonth = Date.now

    private var calendar: Calendar { .current }

    private var accentColor: Color {
        TaskColor.from(token: task.colorToken).color
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // Month navigation
                monthNavigator

                // Weekday headers
                weekdayHeaders

                // Day grid
                dayGrid

                Spacer()
            }
            .padding(16)
            .navigationTitle("Manage Completions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - Month Navigator

    private var monthNavigator: some View {
        HStack {
            Button {
                displayedMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth)!
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3.weight(.semibold))
            }

            Spacer()

            Text(displayedMonth.formatted(.dateTime.month(.wide).year()))
                .font(.headline)

            Spacer()

            Button {
                displayedMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth)!
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title3.weight(.semibold))
            }
        }
    }

    // MARK: - Weekday Headers

    private var weekdayHeaders: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
        return LazyVGrid(columns: columns, spacing: 4) {
            ForEach(Array(["M", "Tu", "W", "Th", "F", "Sa", "Su"].enumerated()), id: \.offset) { _, day in
                Text(day)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
                    .frame(height: 24)
            }
        }
    }

    // MARK: - Day Grid

    private var dayGrid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
        let monthStart = calendar.date(
            from: calendar.dateComponents([.year, .month], from: displayedMonth)
        )!
        let days = daysInMonth(monthStart)
        let firstWeekday = calendar.component(.weekday, from: monthStart)
        let offset = (firstWeekday + 5) % 7

        return LazyVGrid(columns: columns, spacing: 8) {
            ForEach(0..<offset, id: \.self) { _ in
                Color.clear.frame(height: 40)
            }

            ForEach(days, id: \.self) { date in
                dayCell(date)
            }
        }
    }

    private func dayCell(_ date: Date) -> some View {
        let dayNumber = calendar.component(.day, from: date)
        let isCompleted = task.isCompleted(on: date, calendar: calendar)
        let isFuture = date > Date.now

        return Button {
            guard !isFuture else { return }
            toggleCompletion(on: date)
        } label: {
            ZStack {
                Circle()
                    .fill(isCompleted ? accentColor : Color(.secondarySystemBackground))
                    .frame(width: 40, height: 40)

                Text("\(dayNumber)")
                    .font(.subheadline.weight(isCompleted ? .bold : .regular))
                    .foregroundColor(isCompleted ? .white : isFuture ? Color(.tertiaryLabel) : .primary)
            }
        }
        .buttonStyle(.plain)
        .disabled(isFuture)
    }

    // MARK: - Toggle Logic

    private func toggleCompletion(on date: Date) {
        let existing = task.completions(on: date, calendar: calendar)

        if existing.isEmpty {
            // Add completion
            let noon = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: date)!
            let completion = TaskCompletion(completedAt: noon, task: task)
            modelContext.insert(completion)
        } else {
            // Remove completions for this day
            for completion in existing {
                modelContext.delete(completion)
            }
        }
    }

    // MARK: - Helpers

    private func daysInMonth(_ monthDate: Date) -> [Date] {
        guard let range = calendar.range(of: .day, in: .month, for: monthDate) else { return [] }
        return range.compactMap { day in
            calendar.date(from: DateComponents(
                year: calendar.component(.year, from: monthDate),
                month: calendar.component(.month, from: monthDate),
                day: day
            ))
        }
    }
}
