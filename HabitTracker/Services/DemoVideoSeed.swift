import Foundation
import SwiftData

/// Seeds the deterministic showcase state used to record the App Store preview
/// video (`--uitesting-demo-video`).
///
/// The five habits are spread across five different stages, because the whole
/// point of the recording is to show the strength ring, the stage badges and a
/// consistency grid that has some texture to it. Reaching a given stage is not
/// something a seed can assert directly — the score is derived from completions
/// — so each habit's history length and miss pattern were chosen against
/// `HabitStrengthService`'s formula and are documented per habit below.
///
/// Everything runs against the in-memory store (the flag carries the
/// `--uitesting` prefix), so nothing here can reach a real user's database.
@MainActor
enum DemoVideoSeed {
    static let launchArgument = "--uitesting-demo-video"

    /// One habit's showcase configuration.
    private struct Recipe {
        let title: String
        let icon: String
        let color: String
        /// Days of history, counting back from today.
        let historyDays: Int
        /// Whether today is already ticked off. Habits left open are the ones the
        /// recording can complete on camera with a tap and hold.
        let completedToday: Bool
        /// Days that were missed, as offsets back from today. Held as an explicit
        /// closure rather than a random draw so every recording is identical.
        let isMissed: (Int) -> Bool
    }

    /// Target stage per habit, for the record:
    /// Meditate → Mastering, Read a book → Established, Side project → Strong,
    /// Gym → Building, Run → Developing.
    private static let recipes: [Recipe] = [
        Recipe(
            title: "Meditate",
            icon: "brain.head.profile",
            color: "purple",
            historyDays: 130,
            completedToday: true,
            // Two slips, both far enough back to be outside the consistency window.
            isMissed: { $0 == 97 || $0 == 118 }
        ),
        Recipe(
            title: "Read a book",
            icon: "book.fill",
            color: "teal",
            historyDays: 62,
            completedToday: true,
            isMissed: { $0 % 9 == 4 }
        ),
        Recipe(
            title: "Side project",
            icon: "hammer.fill",
            color: "orange",
            historyDays: 46,
            completedToday: false,
            isMissed: { $0 % 5 == 0 }
        ),
        Recipe(
            title: "Gym",
            icon: "figure.strengthtraining.traditional",
            color: "magenta",
            historyDays: 32,
            completedToday: false,
            isMissed: { $0 % 3 == 0 }
        ),
        Recipe(
            title: "Run",
            icon: "figure.run",
            color: "lime",
            historyDays: 15,
            completedToday: false,
            isMissed: { $0 % 2 == 0 }
        ),
    ]

    static func seedIfNeeded(context: ModelContext) {
        guard ProcessInfo.processInfo.arguments.contains(launchArgument) else { return }

        let settings = AppSettings.shared(in: context)
        settings.hasCompletedOnboarding = true
        settings.hasSeededHabitStrength = true
        // Both are one-shot prompts that would otherwise take the screen mid-take.
        settings.hasSeenFirstCompletionPrompt = true
        settings.hasRequestedAppReview = true

        guard ((try? context.fetch(FetchDescriptor<HabitTask>())) ?? []).isEmpty else { return }

        let calendar = Calendar.current
        for (index, recipe) in recipes.enumerated() {
            let createdAt = calendar.date(byAdding: .day, value: -recipe.historyDays, to: .now) ?? .now
            let task = HabitTask(
                title: recipe.title,
                iconName: recipe.icon,
                colorToken: recipe.color,
                sortOrder: index,
                createdAt: createdAt
            )
            context.insert(task)

            let firstOffset = recipe.completedToday ? 0 : 1
            for offset in firstOffset...recipe.historyDays where !recipe.isMissed(offset) {
                guard let day = calendar.date(byAdding: .day, value: -offset, to: .now),
                      let noon = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: day)
                else { continue }
                context.insert(TaskCompletion(completedAt: noon, task: task))
            }

            // Establish the stage baseline the way the upgrade backfill would, so
            // opening the app does not fire five celebration overlays at once.
            let stage = HabitStrengthService.strength(
                for: task, on: .now, calendar: calendar, weekStartDay: settings.weekStartDay
            ).stage
            task.lastObservedStage = stage
            task.lastCelebratedStage = stage
            task.strengthEvaluatedAt = .now
        }
    }
}
