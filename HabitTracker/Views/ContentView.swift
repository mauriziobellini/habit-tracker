import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
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
            SeedDataService.seedIfNeeded(context: modelContext)
            applyUITestingSeedIfNeeded()
            let settings = AppSettings.shared(in: modelContext)
            showOnboarding = !settings.hasCompletedOnboarding
            hasSeeded = true
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
}
