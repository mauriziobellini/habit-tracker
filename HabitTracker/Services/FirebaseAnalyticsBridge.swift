import Foundation
import os
import FirebaseCore
import FirebaseAnalytics

/// Minimal Firebase wrapper used **only** to feed Google Ads conversion goals
/// (Measurement PRD §9 "Firebase / Google Ads only"). Firebase sends exactly two events:
/// `first_open` (automatic once configured) and `purchase` (forwarded from StoreKit success).
///
/// Firebase is never used for product analysis — that lives entirely in PostHog.
enum FirebaseAnalyticsBridge {
    private static let logger = Logger(subsystem: "co.fooshi.habitring", category: "analytics")
    private static let placeholderMarkerKey = "IS_PLACEHOLDER"

    private(set) static var isConfigured = false

    /// Configures Firebase only if a real `GoogleService-Info.plist` is present. While the
    /// committed placeholder is in place (`IS_PLACEHOLDER == true`) or the file is missing,
    /// configuration is skipped so cold launch is unaffected and no data leaves the device.
    static func configureIfAvailable() {
        guard !isConfigured else { return }

        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path) else {
            logger.debug("Firebase not configured: GoogleService-Info.plist missing")
            return
        }

        if let isPlaceholder = plist[placeholderMarkerKey] as? Bool, isPlaceholder {
            logger.debug("Firebase not configured: placeholder GoogleService-Info.plist")
            return
        }

        guard let options = FirebaseOptions(contentsOfFile: path) else {
            logger.debug("Firebase not configured: invalid GoogleService-Info.plist")
            return
        }

        FirebaseApp.configure(options: options)
        isConfigured = true
        logger.debug("Firebase configured for Ads conversion measurement")
    }

    /// Sends the single Firebase `purchase` event for Google Ads. No-op unless Firebase is
    /// configured. Only a non-PII `plan` parameter is attached (PRD §9); monetary value and
    /// currency are intentionally omitted in v1.
    static func logPurchase(plan: String?) {
        guard isConfigured else { return }
        var parameters: [String: Any] = [:]
        if let plan { parameters["plan"] = plan }
        Analytics.logEvent(AnalyticsEventPurchase, parameters: parameters.isEmpty ? nil : parameters)
    }
}
