import Foundation
import os

/// Analytics events for the freemium paywall funnel (PRD - Freemium §5, §9).
enum AnalyticsEvent: String {
    case paywallShown = "paywall_shown"
    case planSelected = "plan_selected"
    case purchaseStarted = "purchase_started"
    case purchaseCompleted = "purchase_completed"
    case purchaseFailed = "purchase_failed"
    case restoreTapped = "restore_tapped"
    case restoreSuccess = "restore_success"
    case restoreFailed = "restore_failed"
    case legacyPremiumDetected = "legacy_premium_detected"
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
