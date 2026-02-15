import SwiftUI
import SwiftData

struct TaskListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \HabitTask.sortOrder) private var tasks: [HabitTask]
    @Query(sort: \Category.sortOrder) private var categories: [Category]

    @State private var viewModel = TaskListViewModel()
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// Collapse to 1 column at accessibility text sizes (UX principles section 7).
    private var columns: [GridItem] {
        if dynamicTypeSize >= .accessibility3 {
            return [GridItem(.flexible(), spacing: 16)]
        }
        return [
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16),
        ]
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()

                if tasks.isEmpty {
                    emptyStateView
                } else {
                    taskGridView
                }

                // Bottom bar \u{2014} settings (left), stats (right of settings)
                VStack {
                    Spacer()
                    HStack {
                        settingsButton
                        generalStatsButton
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                }
            }
            .navigationTitle("My Habits")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    categoryMenu
                }
                ToolbarItem(placement: .topBarTrailing) {
                    addButton
                }
            }
            .sheet(isPresented: $viewModel.showingTaskSelector) {
                NewTaskSelectorView()
            }
            .sheet(isPresented: $viewModel.showingSettings) {
                AppSettingsView()
            }
            .sheet(item: $viewModel.taskToEdit) { task in
                NavigationStack {
                    TaskConfigurationView(
                        viewModel: TaskConfigurationViewModel(mode: .edit(task))
                    )
                }
            }
            .sheet(item: $viewModel.taskForStats) { task in
                TaskStatsView(task: task)
            }
            .alert("Delete Task", isPresented: $viewModel.showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    viewModel.deleteTask(context: modelContext)
                }
            } message: {
                if let task = viewModel.taskToDelete {
                    Text("Are you sure you want to delete \"\(task.title)\"? This action cannot be undone.")
                }
            }
            .confirmationDialog(
                viewModel.taskForMenu?.title ?? "Task",
                isPresented: $viewModel.showingTaskMenu,
                titleVisibility: .visible
            ) {
                Button("Stats") {
                    if let task = viewModel.taskForMenu {
                        viewModel.taskForStats = task
                    }
                }
                Button("Edit") {
                    if let task = viewModel.taskForMenu {
                        viewModel.taskToEdit = task
                    }
                }
                Button("Remove", role: .destructive) {
                    if let task = viewModel.taskForMenu {
                        viewModel.confirmDelete(task)
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
            .sheet(isPresented: $viewModel.showingGeneralStats) {
                GeneralStatsView()
            }
            .overlay {
                if viewModel.showingRewardCelebration {
                    RewardCelebrationView(
                        rewardText: viewModel.rewardCelebrationText
                    ) {
                        viewModel.showingRewardCelebration = false
                    }
                    .transition(.opacity)
                    .zIndex(100)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: viewModel.showingRewardCelebration)
        }
    }

    // MARK: - Category Dropdown

    private var categoryMenu: some View {
        Menu {
            Button {
                viewModel.selectedCategoryID = nil
            } label: {
                Label("All", systemImage: viewModel.selectedCategoryID == nil ? "checkmark" : "")
            }

            Divider()

            ForEach(categories.filter { !$0.tasks.isEmpty }) { category in
                Button {
                    viewModel.selectedCategoryID = category.id
                } label: {
                    Label(
                        category.name,
                        systemImage: viewModel.selectedCategoryID == category.id ? "checkmark" : ""
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
        }
    }

    private var selectedCategoryName: String {
        guard let id = viewModel.selectedCategoryID else { return "All" }
        return categories.first { $0.id == id }?.name ?? "All"
    }

    // MARK: - Add Button

    private var addButton: some View {
        Button {
            viewModel.showingTaskSelector = true
        } label: {
            Image(systemName: "plus")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(
                    Circle().fill(Color.accentColor)
                )
                .clipShape(Circle())
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .background(Color.clear)
        .accessibilityLabel(String(localized: "Add new habit"))
        .accessibilityIdentifier("addTaskButton")
    }

    // MARK: - Settings Button

    private var settingsButton: some View {
        Button {
            viewModel.showingSettings = true
        } label: {
            Image(systemName: "gearshape.fill")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
        .accessibilityLabel(String(localized: "Settings"))
        .accessibilityIdentifier("settingsButton")
    }

    // MARK: - General Stats Button

    private var generalStatsButton: some View {
        Button {
            viewModel.showingGeneralStats = true
        } label: {
            Image(systemName: "chart.bar.fill")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
        .accessibilityLabel(String(localized: "General Stats"))
        .accessibilityIdentifier("generalStatsButton")
    }

    // MARK: - Task Grid

    private var taskGridView: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 24) {
                ForEach(viewModel.filteredTasks(tasks)) { task in
                    taskCell(task)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 80) // space for settings gear
        }
    }

    private func taskCell(_ task: HabitTask) -> some View {
        let isCompleted = task.isCompleted(on: .now)

        return TapAndHoldTaskView(
            task: task,
            isCompleted: isCompleted,
            circleSize: 80,
            onSingleTap: {
                viewModel.taskForMenu = task
                viewModel.showingTaskMenu = true
            },
            onCompleted: {
                recordCompletion(for: task)
            }
        )
    }

    private func recordCompletion(for task: HabitTask) {
        let completion = TaskCompletion(task: task)
        modelContext.insert(completion)
        // Suppress today's notification if task completed early
        if task.notificationEnabled {
            NotificationService.shared.suppressTodayNotification(for: task)
        }
        // Check if this completion triggers a reward
        if task.rewardEnabled, let rewardText = task.rewardText, !rewardText.isEmpty {
            let streak = task.currentStreak()
            if streak > 0 && streak % task.rewardStreakCount == 0 {
                viewModel.rewardCelebrationText = rewardText
                viewModel.showingRewardCelebration = true
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "plus.circle.dashed")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            Text("No habits yet")
                .font(.title2.weight(.semibold))

            Text("Tap the + button to create your first habit")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                viewModel.showingTaskSelector = true
            } label: {
                Text("Add Habit")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(Capsule().fill(Color.accentColor))
            }
            .padding(.top, 8)
        }
        .padding(32)
    }
}
