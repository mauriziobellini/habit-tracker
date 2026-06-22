import Foundation

/// Pure, side-effect-free rules that decide which habits a user can access and whether
/// creating a new habit requires premium (PRD - Freemium §7).
///
/// Kept free of StoreKit and SwiftData so it can be unit-tested in isolation.
enum HabitAccessPolicy {
    /// Whether tapping "+" to create another habit should present the paywall.
    ///
    /// Free users may keep up to `freeHabitLimit` habits; attempting to create one beyond
    /// that triggers the paywall. Premium users are never gated.
    static func shouldPresentPaywallForNewHabit(
        currentHabitCount: Int,
        isPremium: Bool,
        freeLimit: Int = FreemiumConfig.freeHabitLimit
    ) -> Bool {
        if isPremium { return false }
        return currentHabitCount >= freeLimit
    }

    /// The set of habit IDs that remain fully usable for a non-premium user.
    ///
    /// When a subscription lapses and the user has more than `freeLimit` habits, only the
    /// oldest `freeLimit` (by creation date) stay active; the rest are locked. Premium users
    /// retain access to everything.
    static func accessibleHabitIDs<Habit>(
        habits: [Habit],
        isPremium: Bool,
        freeLimit: Int = FreemiumConfig.freeHabitLimit,
        id: (Habit) -> UUID,
        createdAt: (Habit) -> Date
    ) -> Set<UUID> {
        if isPremium {
            return Set(habits.map(id))
        }
        let ordered = habits.sorted { createdAt($0) < createdAt($1) }
        return Set(ordered.prefix(freeLimit).map(id))
    }

    /// Whether a specific habit is locked (greyed out, opens paywall on tap) for this user.
    static func isLocked<Habit>(
        habit: Habit,
        in habits: [Habit],
        isPremium: Bool,
        freeLimit: Int = FreemiumConfig.freeHabitLimit,
        id: (Habit) -> UUID,
        createdAt: (Habit) -> Date
    ) -> Bool {
        if isPremium { return false }
        let accessible = accessibleHabitIDs(
            habits: habits,
            isPremium: isPremium,
            freeLimit: freeLimit,
            id: id,
            createdAt: createdAt
        )
        return !accessible.contains(id(habit))
    }
}
