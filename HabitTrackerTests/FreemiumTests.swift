import Testing
import Foundation
@testable import HabitTracker

// MARK: - PremiumPlan

@Suite("PremiumPlan")
struct PremiumPlanTests {
    @Test("Default plan is yearly")
    func defaultIsYearly() {
        #expect(PremiumPlan.default == .yearly)
    }

    @Test("Display order is yearly, monthly, lifetime")
    func displayOrder() {
        #expect(PremiumPlan.displayOrder == [.yearly, .monthly, .lifetime])
    }

    @Test("Each plan maps to the correct product ID")
    func productIDs() {
        #expect(PremiumPlan.monthly.productID == ProductIDs.monthly)
        #expect(PremiumPlan.yearly.productID == ProductIDs.yearly)
        #expect(PremiumPlan.lifetime.productID == ProductIDs.lifetime)
    }

    @Test("Subscriptions are monthly and yearly; lifetime is not")
    func isSubscription() {
        #expect(PremiumPlan.monthly.isSubscription)
        #expect(PremiumPlan.yearly.isSubscription)
        #expect(!PremiumPlan.lifetime.isSubscription)
    }

    @Test("All product IDs are unique and present")
    func productIDCatalog() {
        #expect(ProductIDs.all.count == 3)
        #expect(Set(ProductIDs.all).count == 3)
        #expect(ProductIDs.subscriptions == [ProductIDs.monthly, ProductIDs.yearly])
    }
}

// MARK: - Legacy version detection

@Suite("Legacy paid-app version mapping")
struct LegacyVersionTests {
    @Test("Original version older than first freemium version is legacy")
    func olderIsLegacy() {
        #expect(EntitlementManager.isLegacyVersion("1.1.0", firstFreemiumVersion: "2.0.0"))
        #expect(EntitlementManager.isLegacyVersion("1.9.9", firstFreemiumVersion: "2.0.0"))
        #expect(EntitlementManager.isLegacyVersion("1.0", firstFreemiumVersion: "2.0.0"))
    }

    @Test("Original version at or after first freemium version is not legacy")
    func newerIsNotLegacy() {
        #expect(!EntitlementManager.isLegacyVersion("2.0.0", firstFreemiumVersion: "2.0.0"))
        #expect(!EntitlementManager.isLegacyVersion("2.0.1", firstFreemiumVersion: "2.0.0"))
        #expect(!EntitlementManager.isLegacyVersion("3.0.0", firstFreemiumVersion: "2.0.0"))
    }

    @Test("Version comparison is numeric, not lexicographic")
    func numericComparison() {
        #expect(EntitlementManager.compareVersions("1.10.0", "1.9.0") == .orderedDescending)
        #expect(EntitlementManager.compareVersions("1.2", "1.2.0") == .orderedSame)
        #expect(EntitlementManager.compareVersions("1.0", "2.0") == .orderedAscending)
    }
}

// MARK: - HabitAccessPolicy

@Suite("HabitAccessPolicy")
struct HabitAccessPolicyTests {
    /// Lightweight stand-in for a habit so the policy can be tested without SwiftData.
    private struct FakeHabit {
        let id: UUID
        let createdAt: Date
    }

    private func makeHabits(_ count: Int) -> [FakeHabit] {
        let base = Date(timeIntervalSince1970: 1_000_000)
        return (0..<count).map { index in
            FakeHabit(id: UUID(), createdAt: base.addingTimeInterval(Double(index) * 60))
        }
    }

    @Test("Free user with fewer than the limit is not gated when adding")
    func freeUnderLimitNoPaywall() {
        #expect(!HabitAccessPolicy.shouldPresentPaywallForNewHabit(currentHabitCount: 0, isPremium: false))
        #expect(!HabitAccessPolicy.shouldPresentPaywallForNewHabit(currentHabitCount: 1, isPremium: false))
    }

    @Test("Free user at the limit is gated when adding a third habit")
    func freeAtLimitShowsPaywall() {
        #expect(HabitAccessPolicy.shouldPresentPaywallForNewHabit(currentHabitCount: 2, isPremium: false))
        #expect(HabitAccessPolicy.shouldPresentPaywallForNewHabit(currentHabitCount: 5, isPremium: false))
    }

    @Test("Premium user is never gated when adding")
    func premiumNeverGated() {
        #expect(!HabitAccessPolicy.shouldPresentPaywallForNewHabit(currentHabitCount: 99, isPremium: true))
    }

    @Test("Free user keeps only the oldest two habits accessible")
    func freeKeepsOldestTwo() {
        let habits = makeHabits(5)
        let accessible = HabitAccessPolicy.accessibleHabitIDs(
            habits: habits,
            isPremium: false,
            id: { $0.id },
            createdAt: { $0.createdAt }
        )
        #expect(accessible.count == 2)
        #expect(accessible.contains(habits[0].id))
        #expect(accessible.contains(habits[1].id))
        #expect(!accessible.contains(habits[2].id))
    }

    @Test("Premium user has all habits accessible")
    func premiumAllAccessible() {
        let habits = makeHabits(5)
        let accessible = HabitAccessPolicy.accessibleHabitIDs(
            habits: habits,
            isPremium: true,
            id: { $0.id },
            createdAt: { $0.createdAt }
        )
        #expect(accessible.count == 5)
    }

    @Test("Habits beyond the limit are locked for free users")
    func lockedBeyondLimit() {
        let habits = makeHabits(3)
        #expect(!HabitAccessPolicy.isLocked(habit: habits[0], in: habits, isPremium: false, id: { $0.id }, createdAt: { $0.createdAt }))
        #expect(!HabitAccessPolicy.isLocked(habit: habits[1], in: habits, isPremium: false, id: { $0.id }, createdAt: { $0.createdAt }))
        #expect(HabitAccessPolicy.isLocked(habit: habits[2], in: habits, isPremium: false, id: { $0.id }, createdAt: { $0.createdAt }))
    }

    @Test("Nothing is locked for premium users")
    func nothingLockedForPremium() {
        let habits = makeHabits(3)
        for habit in habits {
            #expect(!HabitAccessPolicy.isLocked(habit: habit, in: habits, isPremium: true, id: { $0.id }, createdAt: { $0.createdAt }))
        }
    }
}
