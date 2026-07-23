import Foundation
import os
import PostHog

/// Runtime PostHog configuration read from the app bundle (Info.plist keys backed by
/// `Analytics.xcconfig`). Returns `nil` when the key is missing or still the placeholder,
/// which lets the factory fall back to `NoOpAnalyticsService` on unconfigured builds.
struct PostHogRuntimeConfig {
    let apiKey: String
    let host: String

    private static let placeholderPrefix = "phc_REPLACE"

    static func fromBundle(_ bundle: Bundle = .main) -> PostHogRuntimeConfig? {
        guard let apiKey = bundle.object(forInfoDictionaryKey: "PostHogAPIKey") as? String,
              !apiKey.isEmpty,
              !apiKey.hasPrefix(placeholderPrefix) else {
            return nil
        }
        let host = (bundle.object(forInfoDictionaryKey: "PostHogHost") as? String)
            .flatMap { $0.isEmpty ? nil : $0 } ?? "https://eu.i.posthog.com"
        return PostHogRuntimeConfig(apiKey: apiKey, host: host)
    }
}

/// Sends the full product event taxonomy to PostHog Cloud (Measurement PRD §9) and forwards
/// the single `purchase` event to Firebase for Google Ads on StoreKit success. All events are
/// anonymous (no `identify`, no PII, no habit content).
final class PostHogAnalyticsService: AnalyticsService {
    private let logger = Logger(subsystem: "co.fooshi.habitring", category: "analytics")
    private let installCohortDate: String
    private var didAttachCohort = false

    init(config: PostHogRuntimeConfig) {
        installCohortDate = Self.resolveInstallCohortDate()

        let phConfig = PostHogConfig(apiKey: config.apiKey, host: config.host)
        // Prefer explicit events over autocapture to keep privacy and event quality under
        // control (PRD §9). We send our own `app_open`, so lifecycle/screen autocapture is off.
        phConfig.captureApplicationLifecycleEvents = false
        phConfig.captureScreenViews = false
        PostHogSDK.shared.setup(phConfig)
    }

    func track(_ event: AnalyticsEvent, properties: [String: String]) {
        // Attach the install cohort as a set-once person property on the first capture of the
        // session. `install_cohort_date` is a coarse local date (no timestamp) and no PII.
        var setOnce: [String: Any]?
        if !didAttachCohort {
            setOnce = ["install_cohort_date": installCohortDate]
            didAttachCohort = true
        }

        PostHogSDK.shared.capture(
            event.rawValue,
            properties: properties.isEmpty ? nil : properties,
            userPropertiesSetOnce: setOnce
        )

        // One StoreKit success -> one PostHog `purchase_completed` + one Firebase `purchase`
        // (PRD §9, §11). Keeps the purchase call site single inside PurchaseService.
        if event == .purchaseCompleted {
            FirebaseAnalyticsBridge.logPurchase(plan: properties["plan"])
        }
    }

    /// Local calendar date (YYYY-MM-DD) captured once and persisted, so cohort charts are stable
    /// across launches without storing a precise timestamp.
    private static func resolveInstallCohortDate() -> String {
        let key = "analytics.install_cohort_date"
        if let stored = UserDefaults.standard.string(forKey: key) {
            return stored
        }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        let value = formatter.string(from: .now)
        UserDefaults.standard.set(value, forKey: key)
        return value
    }
}
