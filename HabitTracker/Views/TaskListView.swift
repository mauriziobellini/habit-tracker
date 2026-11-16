import SwiftUI
import SwiftData
// For `\.requestReview` (PRD - Habit strength §11).
import StoreKit

struct TaskListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \HabitTask.sortOrder) private var tasks: [HabitTask]
    @Query(sort: \Category.sortOrder) private var categories: [Category]
    @Query private var allSettings: [AppSettings]

    private var weekStartDay: Int {
        allSettings.first?.weekStartDay ?? 1
    }

    @State private var viewModel = TaskListViewModel()
    /// Reference date for everything the grid renders. Kept in state (instead of reading
    /// `.now` inline) so resuming the app after midnight re-evaluates the grid for the new
    /// day — otherwise the list keeps yesterday's completion state until a cold start.
    @State private var dayReferenceDate: Date = .now
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(EntitlementManager.self) private var entitlementManager
    @Environment(PurchaseService.self) private var purchaseService
    @Environment(\.analyticsService) private var analytics
    @Environment(HabitStrengthCache.self) private var strengthCache
    @Environment(\.requestReview) private var requestReview
    @Environment(\.objectiveAvailability) private var objectiveAvailability
    @Environment(\.makeObjectiveGenerator) private var makeObjectiveGenerator

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
            .sheet(isPresented: $viewModel.showingAddOptions, onDismiss: {
                viewModel.performPendingAddOption()
            }) {
                AddHabitOptionsSheet { option in
                    viewModel.selectAddOption(option, analytics: analytics)
                }
            }
            .sheet(isPresented: $viewModel.showingObjectives) {
                objectivesConfigurator
                    .presentationDetents([.large])
            }
            .sheet(isPresented: $viewModel.showingPaywall, onDismiss: {
                viewModel.handlePaywallDismissed(
                    objectivesAvailable: objectiveAvailability.isAvailable(),
                    analytics: analytics
                )
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
                    viewModel.deleteTask(
                        context: modelContext,
                        analytics: analytics,
                        strengthCache: strengthCache
                    )
                }
            } message: {
                if let task = viewModel.taskToDelete {
                    Text("Are you sure you want to delete \"\(task.title)\"? This action cannot be undone.")
                }
            }
            .sheet(item: $viewModel.taskForSummary, onDismiss: {
                // The chosen action runs only once this sheet is gone — presenting a
                // second sheet on top of a dismissing one silently drops it.
                viewModel.performPendingSummaryAction(analytics: analytics)
            }) { task in
                HabitSummarySheetView(
                    task: task,
                    strength: strengthCache.strength(
                        for: task, on: dayReferenceDate, weekStartDay: weekStartDay
                    ),
                    weekStartDay: weekStartDay,
                    onAction: { viewModel.requestSummaryAction($0, for: task) }
                )
            }
            .sheet(item: $viewModel.taskForCompletions) { task in
                ManageCompletionsView(task: task)
            }
            .sheet(isPresented: $viewModel.showingGeneralStats) {
                GeneralStatsView()
            }
            .task {
                // Cold launch does not always register as a scenePhase change. The
                // evaluator is idempotent per day, so an overlapping call is a no-op.
                evaluateStagesOnForeground()
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    refreshDayIfNeeded()
                    evaluateStagesOnForeground()
                }
            }
            .onReceive(
                NotificationCenter.default
                    .publisher(for: .NSCalendarDayChanged)
                    .receive(on: RunLoop.main)
            ) { _ in
                refreshDayIfNeeded()
            }
            .onReceive(
                NotificationCenter.default
                    .publisher(for: UIApplication.significantTimeChangeNotification)
                    .receive(on: RunLoop.main)
            ) { _ in
                refreshDayIfNeeded()
            }
        }
        // Celebrations wrap the whole stack, not its content: an overlay applied
        // inside the stack renders below the navigation bar, so the title and
        // toolbar buttons stayed visible on top of the opaque backdrop.
        .overlay {
            if viewModel.showingRewardCelebration, let habit = viewModel.rewardCelebrationHabit {
                RewardCelebrationView(
                    habit: habit,
                    rewardText: viewModel.rewardCelebrationText
                ) {
                    viewModel.dismissRewardCelebration(analytics: analytics)
                }
                .transition(.opacity)
                .zIndex(100)
            }
        }
        .overlay {
            if viewModel.showingFirstCompletionPrompt, let habit = viewModel.firstCompletionHabit {
                FirstCompletionCelebrationView(
                    habit: habit,
                    offersReminderOptIn: viewModel.firstCompletionOffersReminderOptIn,
                    onEnableReminder: { time in
                        viewModel.enableReminderFromFirstCompletionPrompt(
                            at: time,
                            analytics: analytics
                        )
                    },
                    onDismiss: {
                        viewModel.dismissFirstCompletionPrompt(analytics: analytics)
                    }
                )
                .transition(.opacity)
                .zIndex(101)
            }
        }
        .overlay {
            if viewModel.showingStageCelebration, let transition = viewModel.stageCelebration {
                StageCelebrationView(
                    stage: transition.to,
                    habit: CelebrationHabit(task: transition.task),
                    offersNotificationOptIn: !transition.task.notificationEnabled,
                    onEnableNotifications: { time in
                        viewModel.enableNotificationsFromStageCelebration(
                            at: time, context: modelContext, analytics: analytics
                        )
                    },
                    onDismiss: {
                        viewModel.dismissStageCelebration(
                            context: modelContext, analytics: analytics
                        )
                    }
                )
                .transition(.opacity)
                .zIndex(102)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.showingRewardCelebration)
        .animation(.easeInOut(duration: 0.3), value: viewModel.showingFirstCompletionPrompt)
        .animation(.easeInOut(duration: 0.3), value: viewModel.showingStageCelebration)
    }

    private func refreshDayIfNeeded() {
        let now = Date.now
        guard !Calendar.current.isDate(dayReferenceDate, inSameDayAs: now) else { return }
        dayReferenceDate = now
    }

    // MARK: - Habit strength evaluation

    /// Opportunistic daily evaluation. iOS will not reliably run code at a fixed
    /// time and there is no background refresh task in this project, so foreground
    /// is the dependable trigger (PRD - Habit strength §10.9).
    private func evaluateStagesOnForeground() {
        strengthCache.invalidateAll()
        let transitions = HabitStageEvaluator.evaluate(
            tasks: Array(tasks),
            context: modelContext,
            cache: strengthCache,
            weekStartDay: weekStartDay
        )
        viewModel.enqueueStageCelebrations(transitions, analytics: analytics)
        scheduleStrengthNotifications()
    }

    private func scheduleStrengthNotifications() {
        let habits = Array(tasks)
        let day = weekStartDay
        let context = modelContext
        Task { @MainActor in
            await StrengthNotificationScheduler.refresh(tasks: habits, weekStartDay: day)
            // After the refresh, so the requests it just added are already visible to
            // the sweep. Clears reminders stranded by earlier builds, which deleted a
            // habit without cancelling its repeating weekly triggers.
            await NotificationService.shared.removeOrphanedNotifications {
                // Re-fetched rather than reusing `habits`: that snapshot can be stale
                // by the time the sweep reads it.
                let living = (try? context.fetch(FetchDescriptor<HabitTask>())) ?? []
                return Set(living.map(\.id))
            }
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

    private func handleAddTapped() {
        viewModel.handleAddTapped(
            currentHabitCount: tasks.count,
            isPremium: entitlementManager.isPremium,
            objectivesAvailable: objectiveAvailability.isAvailable(),
            analytics: analytics
        )
    }

    @ViewBuilder
    private var objectivesConfigurator: some View {
        if let generator = makeObjectiveGenerator() {
            let system = allSettings.first?.measurementSystem ?? .metric
            ObjectivesConfiguratorView(
                viewModel: ObjectivesViewModel(
                    generator: generator,
                    analytics: analytics,
                    isPremium: { [entitlementManager] in entitlementManager.isPremium },
                    measurementSystem: { system }
                )
            )
        }
    }

    private var addButton: some View {
        Button {
            handleAddTapped()
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
                on: dayReferenceDate,
                weekStartDay: weekStartDay
            ).listState != .hidden
        }
    }

    private var taskGridView: some View {
        ScrollView {
            VStack(spacing: 0) {
                gridHint

                LazyVGrid(columns: columns, spacing: 24) {
                    ForEach(visibleTasks) { task in
                        taskCell(task)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 80) // space for settings gear
        }
    }

    /// The two gestures are not discoverable on their own, and guessing wrong on the
    /// hold leads to repeated taps (PRD - Habit strength §11).
    private var gridHint: some View {
        Text("Tap and hold to complete, single tap for details")
            .font(.caption)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.bottom, 16)
            .accessibilityIdentifier("taskListHint")
    }

    private func taskCell(_ task: HabitTask) -> some View {
        let progress = PeriodService.periodProgress(for: task, on: dayReferenceDate, weekStartDay: weekStartDay)
        let isLocked = lockedHabitIDs.contains(task.id)
        let strength = strengthCache.strength(
            for: task, on: dayReferenceDate, weekStartDay: weekStartDay
        )

        return TapAndHoldTaskView(
            task: task,
            progress: progress,
            circleSize: 80,
            isLocked: isLocked,
            strength: strength,
            onSingleTap: {
                if isLocked {
                    viewModel.presentPaywall(source: "locked_habit", openSelectorOnUnlock: false)
                } else {
                    viewModel.presentSummary(
                        for: task, isEligible: strength.isEligible, analytics: analytics
                    )
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

        let isFirstCompletionEver = tasks.allSatisfy { $0.completions.isEmpty }

        let completion = TaskCompletion(task: task)
        modelContext.insert(completion)

        // Invalidate before reading strength: the score attached to a completion must
        // be the value *after* it is recorded, or the funnel reads one step behind
        // (PRD - Habit strength §11).
        strengthCache.invalidate(taskID: task.id)
        let strength = strengthCache.strength(
            for: task, on: .now, weekStartDay: weekStartDay
        )

        var completionProps = task.analyticsStructuralProperties(strength: strength)
        completionProps["is_first"] = String(isFirstCompletionEver)
        analytics.track(.habitCompleted, properties: completionProps)
        // Suppress today's notification if task completed early
        if task.notificationEnabled {
            NotificationService.shared.suppressTodayNotification(for: task)
        }

        // Re-evaluate this habit right away (force, because today was already
        // evaluated) so the celebration lands in the same session as the completion
        // that earned it.
        let transitions = HabitStageEvaluator.evaluate(
            tasks: [task],
            context: modelContext,
            cache: strengthCache,
            weekStartDay: weekStartDay,
            force: true
        )
        scheduleStrengthNotifications()

        // First completion ever: celebrate and, if this habit has no reminder, offer one —
        // shown once per install (Experiment - Opt out notifications). The celebration takes
        // the screen, so the reward check below is skipped for this completion.
        if isFirstCompletionEver {
            let settings = AppSettings.shared(in: modelContext)
            if !settings.hasSeenFirstCompletionPrompt {
                settings.hasSeenFirstCompletionPrompt = true
                viewModel.presentFirstCompletionPrompt(for: task, analytics: analytics)
                viewModel.enqueueStageCelebrations(transitions, analytics: analytics)
                return
            }
        }

        // Check if this completion triggers a reward
        if task.rewardEnabled, let rewardText = task.rewardText, !rewardText.isEmpty {
            let streak = task.currentStreak(weekStartDay: weekStartDay)
            if streak > 0 && streak % task.rewardStreakCount == 0 {
                viewModel.rewardCelebrationText = rewardText
                viewModel.rewardCelebrationHabit = CelebrationHabit(task: task)
                viewModel.showingRewardCelebration = true
                analytics.track(.rewardUnlocked, properties: ["streak_count": AnalyticsBucket.streak(streak)])
            }
        }

        // Queued last so the reward celebration, if any, takes the screen first.
        viewModel.enqueueStageCelebrations(transitions, analytics: analytics)
        requestReviewIfEarned()
    }

    /// Asks for an App Store review once the user has three completions to their
    /// name (PRD - Habit strength §11). Deferred until no celebration owns the
    /// screen: iOS silently suppresses a prompt behind a modal, and the one-shot
    /// flag would be spent for nothing.
    private func requestReviewIfEarned() {
        guard !ProcessInfo.processInfo.arguments.contains(where: { $0.hasPrefix("--uitesting") }) else {
            return
        }
        let settings = AppSettings.shared(in: modelContext)
        guard !settings.hasRequestedAppReview else { return }
        guard !viewModel.showingRewardCelebration,
              !viewModel.showingFirstCompletionPrompt,
              !viewModel.showingStageCelebration else { return }

        // Bounded per habit by its own history: a shared `.distantPast` start would
        // make the period enumerator walk millennia to answer a question about the
        // number three.
        var total = 0
        for task in tasks {
            total += StatisticsService.completionCount(
                for: task,
                from: task.historyStart(),
                to: .now,
                weekStartDay: weekStartDay
            )
            if total >= 3 { break }
        }
        guard total >= 3 else { return }

        settings.hasRequestedAppReview = true
        requestReview()
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
                handleAddTapped()
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
