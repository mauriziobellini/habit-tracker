import SwiftUI
import SwiftData
import Charts

/// General stats view showing aggregated statistics across all tasks, with optional category filtering.
struct GeneralStatsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \HabitTask.sortOrder) private var allTasks: [HabitTask]
    @Query(sort: \Category.sortOrder) private var categories: [Category]

    @State private var selectedCategoryID: UUID? = nil
    @State private var windowStart: Date
    @State private var windowEnd: Date
    @State private var weekStartDay: Int = 1
    @State private var showingTimeWindowPicker = false
    @State private var selectedTrendDate: Date?

    init() {
        let cal = Calendar.current
        let todayStart = cal.startOfDay(for: .now)
        _windowStart = State(initialValue: cal.date(byAdding: .day, value: -30, to: todayStart)!)
        _windowEnd = State(initialValue: cal.date(byAdding: .day, value: 1, to: todayStart)!.addingTimeInterval(-1))
    }

    private var filteredTasks: [HabitTask] {
        if let categoryID = selectedCategoryID {
            return allTasks.filter { $0.category?.id == categoryID }
        }
        return allTasks
    }

    private var completionCount: Int {
        StatisticsService.totalCompletionCount(tasks: filteredTasks, from: windowStart, to: windowEnd, weekStartDay: weekStartDay)
    }

    private var completionPercentage: Double {
        StatisticsService.averageCompletionPercentage(tasks: filteredTasks, from: windowStart, to: windowEnd, weekStartDay: weekStartDay)
    }

    private var trendData: [StatisticsService.TrendPoint] {
        StatisticsService.trendDataForAll(tasks: filteredTasks, from: windowStart, to: windowEnd, weekStartDay: weekStartDay)
    }

    private var windowDescription: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        let code = UserDefaults.standard.string(forKey: AppLanguage.userDefaultsKey) ?? "en"
        formatter.locale = Locale(identifier: code)
        return "\(formatter.string(from: windowStart)) \u{2013} \(formatter.string(from: windowEnd))"
    }

    private func trendDateLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        let code = UserDefaults.standard.string(forKey: AppLanguage.userDefaultsKey) ?? "en"
        formatter.locale = Locale(identifier: code)
        return formatter.string(from: date)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Category filter
                    categoryDropdown

                    // Time window selector
                    timeWindowButton

                    // Stats cards
                    statsCards

                    // Trend chart
                    trendChart
                }
                .padding(16)
            }
            .navigationTitle("General Stats")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .sheet(isPresented: $showingTimeWindowPicker) {
                TimeWindowSelectorView { start, end in
                    let cal = Calendar.current
                    windowStart = cal.startOfDay(for: start)
                    let endStart = cal.startOfDay(for: end)
                    windowEnd = cal.date(byAdding: .day, value: 1, to: endStart)!.addingTimeInterval(-1)
                }
            }
            .onAppear {
                let settings = AppSettings.shared(in: modelContext)
                weekStartDay = settings.weekStartDay
            }
        }
    }

    // MARK: - Category Dropdown

    private var categoryDropdown: some View {
        Menu {
            Button {
                selectedCategoryID = nil
            } label: {
                Label("All", systemImage: selectedCategoryID == nil ? "checkmark" : "")
            }

            Divider()

            ForEach(categories.filter { !$0.tasks.isEmpty }) { category in
                Button {
                    selectedCategoryID = category.id
                } label: {
                    Label(
                        category.localizedDisplayName,
                        systemImage: selectedCategoryID == category.id ? "checkmark" : ""
                    )
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(selectedCategoryName)
                    .font(.subheadline.weight(.medium))
                Image(systemName: "chevron.down")
                    .font(.caption2.weight(.semibold))
            }
            .foregroundStyle(.primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.secondarySystemBackground))
            )
        }
    }

    private var selectedCategoryName: String {
        guard let id = selectedCategoryID else {
            return NSLocalizedString("All", comment: "")
        }
        return categories.first { $0.id == id }?.localizedDisplayName
            ?? NSLocalizedString("All", comment: "")
    }

    // MARK: - Time Window Button

    private var timeWindowButton: some View {
        Button {
            showingTimeWindowPicker = true
        } label: {
            HStack {
                Image(systemName: "calendar")
                Text(windowDescription)
                    .font(.subheadline)
                Image(systemName: "chevron.right")
                    .font(.caption2)
            }
            .foregroundStyle(.primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.secondarySystemBackground))
            )
        }
    }

    // MARK: - Stats Cards

    private var statsCards: some View {
        HStack(spacing: 16) {
            statCard(
                title: "Completions",
                value: "\(completionCount)",
                icon: "checkmark.circle.fill"
            )

            statCard(
                title: "Avg Completion %",
                value: String(format: "%.0f%%", completionPercentage),
                icon: "percent"
            )
        }
    }

    private func statCard(title: String, value: String, icon: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Color.accentColor)

            Text(value)
                .font(.title.weight(.bold))
                .foregroundStyle(.primary)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }

    // MARK: - Trend Chart

    /// Compute explicit x-axis date values from trend data so the last value
    /// is always visible and dates match the configured week start day.
    private var chartXAxisDates: [Date] {
        let data = trendData
        guard !data.isEmpty else { return [] }
        if data.count <= 5 {
            return data.map(\.date)
        }
        var dates: [Date] = []
        let step = max(1, (data.count - 1) / 4)
        for i in stride(from: 0, to: data.count, by: step) {
            dates.append(data[i].date)
        }
        if let last = data.last?.date, dates.last != last {
            dates.append(last)
        }
        return dates
    }

    /// The data point closest to the date the user tapped on the chart.
    private var selectedTrendPoint: StatisticsService.TrendPoint? {
        guard let selectedTrendDate else { return nil }
        return trendData.min {
            abs($0.date.timeIntervalSince(selectedTrendDate)) < abs($1.date.timeIntervalSince(selectedTrendDate))
        }
    }

    private func trendCallout(for point: StatisticsService.TrendPoint) -> some View {
        VStack(spacing: 2) {
            Text(trendDateLabel(for: point.date))
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text("\(point.count)")
                .font(.headline)
            Text("Completions")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
        )
        .accessibilityElement(children: .combine)
    }

    private var trendChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Trend")
                .font(.headline)

            if trendData.isEmpty {
                Text("No data for this period")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
            } else {
                Chart {
                    ForEach(trendData) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Completions", point.count)
                        )
                        .foregroundStyle(Color.accentColor)
                        .interpolationMethod(.catmullRom)

                        AreaMark(
                            x: .value("Date", point.date),
                            y: .value("Completions", point.count)
                        )
                        .foregroundStyle(Color.accentColor.opacity(0.1))
                        .interpolationMethod(.catmullRom)

                        PointMark(
                            x: .value("Date", point.date),
                            y: .value("Completions", point.count)
                        )
                        .foregroundStyle(Color.accentColor)
                    }

                    if let selectedTrendPoint {
                        RuleMark(x: .value("Date", selectedTrendPoint.date))
                            .foregroundStyle(Color.accentColor.opacity(0.35))
                            .zIndex(-1)
                            .annotation(
                                position: .top,
                                spacing: 4,
                                overflowResolution: .init(x: .fit(to: .chart), y: .fit(to: .chart))
                            ) {
                                trendCallout(for: selectedTrendPoint)
                            }

                        PointMark(
                            x: .value("Date", selectedTrendPoint.date),
                            y: .value("Completions", selectedTrendPoint.count)
                        )
                        .foregroundStyle(Color.accentColor)
                        .symbolSize(130)
                    }
                }
                .chartXSelection(value: $selectedTrendDate)
                .sensoryFeedback(.selection, trigger: selectedTrendPoint?.date)
                .chartXAxis {
                    AxisMarks(values: chartXAxisDates) { _ in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .frame(height: 200)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
        .onChange(of: selectedCategoryID) { selectedTrendDate = nil }
        .onChange(of: windowStart) { selectedTrendDate = nil }
        .onChange(of: windowEnd) { selectedTrendDate = nil }
    }
}
