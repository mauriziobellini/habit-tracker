import SwiftUI
import Charts

/// Task stats view (FR-4): shows completion count, percentage, trend chart.
struct TaskStatsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State var viewModel: TaskStatsViewModel
    @State private var selectedTrendDate: Date?

    private var accentColor: Color {
        TaskColor.from(token: viewModel.task.colorToken).color
    }

    init(task: HabitTask) {
        _viewModel = State(initialValue: TaskStatsViewModel(task: task))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Task header
                    taskHeader

                    // Time window selector
                    timeWindowButton

                    // Stats cards
                    statsCards

                    // Trend chart
                    trendChart

                    // Streak
                    streakCard

                    // Manage completions button
                    manageCompletionsButton
                }
                .padding(16)
            }
            .navigationTitle("Stats")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .sheet(isPresented: $viewModel.showingTimeWindowPicker) {
                TimeWindowSelectorView { start, end in
                    viewModel.updateWindow(start: start, end: end)
                }
            }
            .sheet(isPresented: $viewModel.showingManageCompletions) {
                ManageCompletionsView(task: viewModel.task)
            }
            .onAppear {
                viewModel.loadSettings(from: modelContext)
            }
        }
    }

    // MARK: - Task Header

    private var taskHeader: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.15))
                    .frame(width: 64, height: 64)

                if let icon = viewModel.task.iconName {
                    Image(systemName: icon)
                        .font(.title)
                        .foregroundStyle(accentColor)
                } else {
                    Text(viewModel.task.initialsDisplay)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(accentColor)
                }
            }

            Text(viewModel.task.title)
                .font(.title3.weight(.semibold))
        }
    }

    // MARK: - Time Window Button

    private var timeWindowButton: some View {
        Button {
            viewModel.showingTimeWindowPicker = true
        } label: {
            HStack {
                Image(systemName: "calendar")
                Text(viewModel.windowDescription)
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
                value: "\(viewModel.completionCount)",
                icon: "checkmark.circle.fill"
            )

            statCard(
                title: "Completion %",
                value: String(format: "%.0f%%", viewModel.completionPercentage),
                icon: "percent"
            )
        }
    }

    private func statCard(title: String, value: String, icon: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(accentColor)

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
        let data = viewModel.trendData
        guard !data.isEmpty else { return [] }
        if data.count <= 5 {
            return data.map(\.date)
        }
        // Show ~5 evenly spaced labels, always including first and last
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
        return viewModel.trendData.min {
            abs($0.date.timeIntervalSince(selectedTrendDate)) < abs($1.date.timeIntervalSince(selectedTrendDate))
        }
    }

    private func trendDateLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        let code = UserDefaults.standard.string(forKey: AppLanguage.userDefaultsKey) ?? "en"
        formatter.locale = Locale(identifier: code)
        return formatter.string(from: date)
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

            if viewModel.trendData.isEmpty {
                Text("No data for this period")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
            } else {
                Chart {
                    ForEach(viewModel.trendData) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Completions", point.count)
                        )
                        .foregroundStyle(accentColor)
                        .interpolationMethod(.catmullRom)

                        AreaMark(
                            x: .value("Date", point.date),
                            y: .value("Completions", point.count)
                        )
                        .foregroundStyle(accentColor.opacity(0.1))
                        .interpolationMethod(.catmullRom)

                        PointMark(
                            x: .value("Date", point.date),
                            y: .value("Completions", point.count)
                        )
                        .foregroundStyle(accentColor)
                    }

                    if let selectedTrendPoint {
                        RuleMark(x: .value("Date", selectedTrendPoint.date))
                            .foregroundStyle(accentColor.opacity(0.35))
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
                        .foregroundStyle(accentColor)
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
        .onChange(of: viewModel.windowStart) { selectedTrendDate = nil }
        .onChange(of: viewModel.windowEnd) { selectedTrendDate = nil }
    }

    // MARK: - Streak Card

    private var streakCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Current Streak")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("\(viewModel.currentStreak) days")
                    .font(.title2.weight(.bold))
            }
            Spacer()
            Image(systemName: "flame.fill")
                .font(.largeTitle)
                .foregroundStyle(accentColor)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }

    // MARK: - Manage Completions

    private var manageCompletionsButton: some View {
        Button {
            viewModel.showingManageCompletions = true
        } label: {
            Text("Manage Task Completions")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(accentColor)
                )
        }
    }
}
