import SwiftUI
import SwiftData

struct TaskListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \HabitTask.sortOrder) private var tasks: [HabitTask]
    @Query(sort: \Category.sortOrder) private var categories: [Category]
    @Query private var allSettings: [AppSettings]

    private var weekStartDay: Int {
        allSettings.first?.weekStartDay ?? 1
    }

    @State private var viewModel = TaskListViewModel()
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(EntitlementManager.self) private var entitlementManager
    @Environment(PurchaseService.self) private var purchaseService
    @Environment(\.analyticsService) private var analytics

    /// IDs of habits locked behind the paywall (lapsed subscription with >2 habits).
    private var lockedHabitIDs: Set<UUID> {
        let allTasks = Array(tasks)
        return Set(allTasks.map(\.id)).subtracting(
            HabitAccessPolicy.accessibleHabitIDs(
                habits: allTasks,
                isPremium: entitlementManager.isPremium,
                id: { $0.id },
                createdAt: { $0.createdAt }
            )
        )
    }

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
            .sheet(isPresented: $viewModel.showingPaywall, onDismiss: {
                viewModel.handlePaywallDismissed(analytics: analytics)
            }) {
                PaywallView(
                    viewModel: PaywallViewModel(
                        purchaseService: purchaseService,
                        entitlementManager: entitlementManager,
                        analytics: analytics,
                        source: viewModel.paywallSource
                    ),
                    onPremiumUnlocked: {
                        viewModel.premiumUnlocked = true
                    }
                )
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
                    viewModel.deleteTask(context: modelContext, analytics: analytics)
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
                        analytics.track(.statsOpened, properties: ["scope": "habit"])
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
                        category.localizedDisplayName,
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
        guard let id = viewModel.selectedCategoryID else {
            return NSLocalizedString("All", comment: "")
        }
        return categories.first { $0.id == id }?.localizedDisplayName
            ?? NSLocalizedString("All", comment: "")
    }

    // MARK: - Add Button

    private var addButton: some View {
        Button {
            viewModel.handleAddTapped(
                currentHabitCount: tasks.count,
                isPremium: entitlementManager.isPremium,
                analytics: analytics
            )
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
            analytics.track(.settingsOpened)
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
            analytics.track(.statsOpened, properties: ["scope": "general"])
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

    /// Visible tasks: filtered by category, with specific-days habits hidden on
    /// non-scheduled days (PRD §9 / state machine §7).
    private var visibleTasks: [HabitTask] {
        viewModel.filteredTasks(tasks).filter { task in
            PeriodService.periodProgress(
                for: task,
                on: .now,
                weekStartDay: weekStartDay
            ).listState != .hidden
        }
    }

    private var taskGridView: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 24) {
                ForEach(visibleTasks) { task in
                    taskCell(task)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 80) // space for settings gear
        }
    }

    private func taskCell(_ task: HabitTask) -> some View {
        let progress = PeriodService.periodProgress(for: task, on: .now, weekStartDay: weekStartDay)
        let isLocked = lockedHabitIDs.contains(task.id)

        return TapAndHoldTaskView(
            task: task,
            progress: progress,
            circleSize: 80,
            isLocked: isLocked,
            onSingleTap: {
                if isLocked {
                    viewModel.presentPaywall(source: "locked_habit", openSelectorOnUnlock: false)
                } else {
                    viewModel.taskForMenu = task
                    viewModel.showingTaskMenu = true
                }
            },
            onCompleted: {
                recordCompletion(for: task)
            }
        )
    }

    private func recordCompletion(for task: HabitTask) {
        // Over-completion rule: the task list never records beyond the period quota.
        guard PeriodService.canAcceptCompletion(for: task, on: .now, weekStartDay: weekStartDay) else {
            return
        }

        let completion = TaskCompletion(task: task)
        modelContext.insert(completion)
        analytics.track(.habitCompleted, properties: task.analyticsStructuralProperties)
        // Suppress today's notification if task completed early
        if task.notificationEnabled {
            NotificationService.shared.suppressTodayNotification(for: task)
        }
        // Check if this completion triggers a reward
        if task.rewardEnabled, let rewardText = task.rewardText, !rewardText.isEmpty {
            let streak = task.currentStreak(weekStartDay: weekStartDay)
            if streak > 0 && streak % task.rewardStreakCount == 0 {
                viewModel.rewardCelebrationText = rewardText
                viewModel.showingRewardCelebration = true
                analytics.track(.rewardUnlocked, properties: ["streak_count": AnalyticsBucket.streak(streak)])
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
                viewModel.handleAddTapped(
                    currentHabitCount: tasks.count,
                    isPremium: entitlementManager.isPremium,
                    analytics: analytics
                )
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
