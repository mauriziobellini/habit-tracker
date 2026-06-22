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

    init(
        id: UUID = UUID(),
        hasCompletedOnboarding: Bool = false,
        weekStartDay: Int = 1,
        measurementSystem: MeasurementSystem = .metric,
        cachedIsPremium: Bool = false,
        lastEntitlementCheckAt: Date? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.weekStartDay = weekStartDay
        self.measurementSystem = measurementSystem
        self.cachedIsPremium = cachedIsPremium
        self.lastEntitlementCheckAt = lastEntitlementCheckAt
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
