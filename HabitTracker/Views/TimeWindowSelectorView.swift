import SwiftUI

/// Full-screen date range picker (FR-4.1).
/// Scroll to browse months; tap to select start and end dates.
struct TimeWindowSelectorView: View {
    @Environment(\.dismiss) private var dismiss

    var onSelect: (Date, Date) -> Void

    @State private var startDate: Date? = nil
    @State private var endDate: Date? = nil
    @State private var referenceDate = Date.now

    /// Range of months to display (24 months back, 2 forward).
    private var months: [Date] {
        let calendar = Calendar.current
        var result: [Date] = []
        for offset in -24...2 {
            if let date = calendar.date(byAdding: .month, value: offset, to: referenceDate) {
                let start = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
                result.append(start)
            }
        }
        return result
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 24) {
                        ForEach(months, id: \.self) { monthDate in
                            monthView(for: monthDate)
                                .id(monthDate)
                        }
                    }
                    .padding(16)
                }
                .onAppear {
                    // Scroll to current month
                    let calendar = Calendar.current
                    let currentMonth = calendar.date(
                        from: calendar.dateComponents([.year, .month], from: Date.now)
                    )!
                    proxy.scrollTo(currentMonth, anchor: .center)
                }
            }
            .navigationTitle("Select Dates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        if let start = startDate, let end = endDate {
                            let sorted = [start, end].sorted()
                            onSelect(sorted[0], sorted[1])
                        } else if let start = startDate {
                            onSelect(start, start)
                        }
                        dismiss()
                    }
                    .disabled(startDate == nil)
                }
            }
        }
    }

    // MARK: - Month View

    private func monthView(for monthDate: Date) -> some View {
        let calendar = Calendar.current
        let monthName = monthDate.formatted(.dateTime.month(.wide).year())
        let days = daysInMonth(monthDate, calendar: calendar)
        let firstWeekday = calendar.component(.weekday, from: monthDate)
        // Convert to 0-indexed Monday start
        let offset = (firstWeekday + 5) % 7

        let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

        return VStack(alignment: .leading, spacing: 8) {
            Text(monthName)
                .font(.headline)
                .padding(.leading, 4)

            // Weekday headers
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(["M", "T", "W", "T", "F", "S", "S"], id: \.self) { day in
                    Text(day)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                        .frame(height: 24)
                }
            }

            LazyVGrid(columns: columns, spacing: 4) {
                // Empty cells for offset
                ForEach(0..<offset, id: \.self) { _ in
                    Color.clear.frame(height: 36)
                }

                // Day cells
                ForEach(days, id: \.self) { date in
                    dayCell(date)
                }
            }
        }
    }

    private func dayCell(_ date: Date) -> some View {
        let calendar = Calendar.current
        let day = calendar.component(.day, from: date)
        let isSelected = isDateSelected(date)
        let isInRange = isDateInRange(date)

        return Button {
            handleDayTap(date)
        } label: {
            Text("\(day)")
                .font(.subheadline)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(isSelected ? Color.accentColor : isInRange ? Color.accentColor.opacity(0.2) : Color.clear)
                )
                .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Selection Logic

    private func handleDayTap(_ date: Date) {
        if startDate == nil {
            // First tap: set start
            startDate = date
            endDate = nil
        } else if endDate == nil {
            // Second tap: set end
            endDate = date
        } else {
            // Third tap: new start
            startDate = date
            endDate = nil
        }
    }

    private func isDateSelected(_ date: Date) -> Bool {
        let calendar = Calendar.current
        if let start = startDate, calendar.isDate(date, inSameDayAs: start) { return true }
        if let end = endDate, calendar.isDate(date, inSameDayAs: end) { return true }
        return false
    }

    private func isDateInRange(_ date: Date) -> Bool {
        guard let start = startDate, let end = endDate else { return false }
        let sorted = [start, end].sorted()
        return date >= sorted[0] && date <= sorted[1]
    }

    // MARK: - Helpers

    private func daysInMonth(_ monthDate: Date, calendar: Calendar) -> [Date] {
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
