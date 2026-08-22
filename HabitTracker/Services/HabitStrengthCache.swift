import Foundation
import Observation

/// Memoises Habit Strength per habit per day.
///
/// Computing `N` walks every period since `createdAt`, and the dashboard renders
/// every habit, so an uncached read would recompute the whole history on each
/// SwiftUI body pass (PRD - Habit strength §10.8). The score can only change when
/// the completion set changes or the day rolls over, which is exactly the cache key.
@Observable
@MainActor
final class HabitStrengthCache {

    private struct CacheKey: Hashable {
        let taskID: UUID
        let day: Date
    }

    /// Bumped on invalidation so observing views recompute. The storage itself is
    /// deliberately *not* observed: filling the cache happens during a body pass,
    /// and publishing that write would re-enter the view update it was serving.
    private(set) var generation: Int = 0

    @ObservationIgnored
    private var entries: [CacheKey: HabitStrength] = [:]

    @ObservationIgnored
    private let calendar: Calendar

    /// Entry ceiling before stale days are pruned. Generous enough that a normal
    /// session never trims, low enough that scrolling long histories cannot grow
    /// the dictionary without bound.
    @ObservationIgnored
    private let capacity: Int

    init(calendar: Calendar = .current, capacity: Int = 512) {
        self.calendar = calendar
        self.capacity = capacity
    }

    // MARK: - Reads

    func strength(
        for task: HabitTask,
        on date: Date = .now,
        weekStartDay: Int = 1
    ) -> HabitStrength {
        let key = CacheKey(taskID: task.id, day: calendar.startOfDay(for: date))
        if let cached = entries[key] {
            return cached
        }

        let computed = HabitStrengthService.strength(
            for: task, on: date, calendar: calendar, weekStartDay: weekStartDay
        )
        if entries.count >= capacity {
            entries = entries.filter { $0.key.day == key.day }
        }
        entries[key] = computed
        return computed
    }

    // MARK: - Invalidation

    /// Call after inserting or deleting a completion, or after editing a habit's
    /// frequency, quota, tracking mode or scheduled days — all of which change how
    /// completions are credited.
    func invalidate(taskID: UUID) {
        entries = entries.filter { $0.key.taskID != taskID }
        generation += 1
    }

    /// Call on app foreground (the date may have rolled over) and after the upgrade
    /// backfill.
    func invalidateAll() {
        entries.removeAll(keepingCapacity: true)
        generation += 1
    }

    /// Test seam: how many entries are currently memoised.
    var entryCount: Int { entries.count }
}
