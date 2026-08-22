import Foundation
import SwiftData

@Model
final class AppSettings {
    var id: UUID
    var hasCompletedOnboarding: Bool
    var weekStartDay: Int
    var measurementSystem: MeasurementSystem
    var createdAt: Date

    /// Cached premium flag for optimistic UI on cold launch (PRD - Freemium §9).
    /// StoreKit remains the source of truth; this is refreshed asynchronously on launch.
    var cachedIsPremium: Bool = false

    /// Timestamp of the last successful StoreKit entitlement check.
    var lastEntitlementCheckAt: Date?

    /// The first-completion celebration is shown once per install
    /// (Experiment - Opt out notifications).
    var hasSeenFirstCompletionPrompt: Bool = false

    /// One-shot flag so the habit-strength upgrade backfill runs exactly once.
    /// Without it, existing habits would be treated as brand-new on the first
    /// launch after the update and fire a barrage of stage celebrations
    /// (PRD - Habit strength §10.5).
    var hasSeededHabitStrength: Bool = false

    /// The App Store review prompt is requested at most once per install
    /// (PRD - Habit strength §11).
    var hasRequestedAppReview: Bool = false

    init(
        id: UUID = UUID(),
        hasCompletedOnboarding: Bool = false,
        weekStartDay: Int = 1,
        measurementSystem: MeasurementSystem = .metric,
        cachedIsPremium: Bool = false,
        lastEntitlementCheckAt: Date? = nil,
        hasSeenFirstCompletionPrompt: Bool = false,
        hasSeededHabitStrength: Bool = false,
        hasRequestedAppReview: Bool = false,
        createdAt: Date = .now
    ) {
        self.id = id
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.weekStartDay = weekStartDay
        self.measurementSystem = measurementSystem
        self.cachedIsPremium = cachedIsPremium
        self.lastEntitlementCheckAt = lastEntitlementCheckAt
        self.hasSeenFirstCompletionPrompt = hasSeenFirstCompletionPrompt
        self.hasSeededHabitStrength = hasSeededHabitStrength
        self.hasRequestedAppReview = hasRequestedAppReview
        self.createdAt = createdAt
    }
}

// MARK: - Fetch or Create Singleton

extension AppSettings {
    @MainActor
    static func shared(in context: ModelContext) -> AppSettings {
        let descriptor = FetchDescriptor<AppSettings>()
        if let existing = try? context.fetch(descriptor).first {
            return existing
        }
        let settings = AppSettings()
        context.insert(settings)
        return settings
    }
}
