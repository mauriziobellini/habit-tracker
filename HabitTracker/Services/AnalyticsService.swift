import Foundation
import os

/// Analytics events for the freemium funnel and product usage (PRD - Measurement §9).
/// Names must match the taxonomy in the Measurement PRD exactly so PostHog insights stay stable.
enum AnalyticsEvent: String {
    // Freemium / monetisation (already wired at call sites).
    case paywallShown = "paywall_shown"
    case planSelected = "plan_selected"
    case purchaseStarted = "purchase_started"
    case purchaseCompleted = "purchase_completed"
    case purchaseFailed = "purchase_failed"
    case restoreTapped = "restore_tapped"
    case restoreSuccess = "restore_success"
    case restoreFailed = "restore_failed"
    case legacyPremiumDetected = "legacy_premium_detected"

    // Activation & monetisation (Measurement PRD §9).
    case appOpen = "app_open"
    case onboardingCompleted = "onboarding_completed"
    case habitCreated = "habit_created"
    case paywallDismissed = "paywall_dismissed"
    case addHabitTapped = "add_habit_tapped"

    // App usage & engagement (Measurement PRD §9).
    case habitCompleted = "habit_completed"
    case habitEdited = "habit_edited"
    case habitDeleted = "habit_deleted"
    case statsOpened = "stats_opened"
    case settingsOpened = "settings_opened"
    case rewardUnlocked = "reward_unlocked"
}

/// Abstraction over analytics so the provider (TelemetryDeck, Firebase, etc.) can be swapped
/// without touching call sites. Events carry no PII and no habit content (PRD - Freemium §9).
protocol AnalyticsService: AnyObject {
    func track(_ event: AnalyticsEvent, properties: [String: String])
}

extension AnalyticsService {
    func track(_ event: AnalyticsEvent) {
        track(event, properties: [:])
    }
}

/// Default no-op implementation. The app ships local-first with no analytics backend;
/// events are logged to the unified log only, which keeps the no-tracking privacy posture
/// until a real provider is wired in.
final class NoOpAnalyticsService: AnalyticsService {
    private let logger = Logger(subsystem: "co.fooshi.habitring", category: "analytics")

    func track(_ event: AnalyticsEvent, properties: [String: String]) {
        if properties.isEmpty {
            logger.debug("event: \(event.rawValue, privacy: .public)")
        } else {
            let rendered = properties
                .sorted { $0.key < $1.key }
                .map { "\($0.key)=\($0.value)" }
                .joined(separator: ",")
            logger.debug("event: \(event.rawValue, privacy: .public) [\(rendered, privacy: .public)]")
        }
    }
}
