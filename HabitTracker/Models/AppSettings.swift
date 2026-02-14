import Foundation
import SwiftData

@Model
final class AppSettings {
    var id: UUID
    var hasCompletedOnboarding: Bool
    var weekStartDay: Int
    var measurementSystem: MeasurementSystem
    var createdAt: Date

    init(
        id: UUID = UUID(),
        hasCompletedOnboarding: Bool = false,
        weekStartDay: Int = 1,
        measurementSystem: MeasurementSystem = .metric,
        createdAt: Date = .now
    ) {
        self.id = id
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.weekStartDay = weekStartDay
        self.measurementSystem = measurementSystem
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
