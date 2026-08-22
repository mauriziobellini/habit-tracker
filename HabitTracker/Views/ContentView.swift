import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.appOpenTracker) private var appOpenTracker
    @Environment(EntitlementManager.self) private var entitlementManager
    @State private var hasSeeded = false
    @State private var showOnboarding = false

    var body: some View {
        Group {
            if !hasSeeded {
                Color(.systemBackground)
            } else if showOnboarding {
                OnboardingView {
                    withAnimation {
                        showOnboarding = false
                    }
                }
            } else {
                TaskListView()
            }
        }
        .onAppear {
            MigrationService.normalizeIfNeeded(context: modelContext)
            SeedDataService.seedIfNeeded(context: modelContext)
            applyUITestingSeedIfNeeded()
            let settings = AppSettings.shared(in: modelContext)
            showOnboarding = !settings.hasCompletedOnboarding
            hasSeeded = true
        }
        .onChange(of: scenePhase, initial: true) { _, phase in
            // Observe scenePhase on a View (not App) so the environment is valid and
            // launch UI is not blocked by App-level scene wiring.
            if phase == .active {
                appOpenTracker?.trackOpenIfNeeded()
            }
        }
        .onChange(of: entitlementManager.isPremium) { _, isPremium in
            // Persist the latest entitlement state for optimistic launch UI (PRD - Freemium §9).
            let settings = AppSettings.shared(in: modelContext)
            settings.cachedIsPremium = isPremium
            settings.lastEntitlementCheckAt = .now
        }
    }

    /// Seeds a deterministic state for UI tests: skips onboarding and creates exactly two
    /// free-tier habits so the paywall can be triggered on a third (PRD - Freemium §6).
    private func applyUITestingSeedIfNeeded() {
        seedTwoHabitsIfNeeded()
        seedStrongHabitIfNeeded()
    }

    private func seedTwoHabitsIfNeeded() {
        guard ProcessInfo.processInfo.arguments.contains("--uitesting-seed-two") else { return }
        let settings = AppSettings.shared(in: modelContext)
        settings.hasCompletedOnboarding = true

        let descriptor = FetchDescriptor<HabitTask>()
        let existing = (try? modelContext.fetch(descriptor)) ?? []
        guard existing.count < 2 else { return }
        for index in existing.count..<2 {
            let task = HabitTask(title: "Test Habit \(index + 1)", iconName: "star.fill", sortOrder: index)
            modelContext.insert(task)
        }
    }

    /// Seeds one habit with a long unbroken history, so UI tests can reach the states
    /// that only exist once a habit has been going for a while: the strength ring, the
    /// stage badge, and a real score in the summary sheet (PRD - Habit strength §8).
    /// Without this every UI test sees a brand-new habit, which is exactly the one case
    /// where all of that is hidden.
    private func seedStrongHabitIfNeeded() {
        guard ProcessInfo.processInfo.arguments.contains("--uitesting-seed-strong") else { return }
        let settings = AppSettings.shared(in: modelContext)
        settings.hasCompletedOnboarding = true
        // Skip the backfill, which would otherwise seed the stage and suppress the
        // very transitions a test may want to observe.
        settings.hasSeededHabitStrength = true

        let descriptor = FetchDescriptor<HabitTask>()
        guard ((try? modelContext.fetch(descriptor)) ?? []).isEmpty else { return }

        let calendar = Calendar.current
        let historyDays = 60
        let createdAt = calendar.date(byAdding: .day, value: -historyDays, to: .now) ?? .now
        let task = HabitTask(
            title: "Meditate",
            iconName: "brain.head.profile",
            colorToken: "purple",
            createdAt: createdAt
        )
        modelContext.insert(task)

        // Every day but today, so the habit is still completable in the test.
        for dayOffset in 1...historyDays {
            guard let day = calendar.date(byAdding: .day, value: -dayOffset, to: .now),
                  let noon = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: day)
            else { continue }
            modelContext.insert(TaskCompletion(completedAt: noon, task: task))
        }
    }
}
