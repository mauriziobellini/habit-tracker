import Foundation

/// Builds the app's analytics service at launch (Measurement PRD §9).
///
/// - UI tests (any `--uitesting*` launch argument) always get the silent `NoOpAnalyticsService`
///   so tests stay deterministic and never hit the network.
/// - Builds without a real PostHog key (placeholder/unconfigured) also fall back to no-op, so
///   local/dev/CI builds run without sending data.
/// - Otherwise a `PostHogAnalyticsService` is returned and Firebase is configured (if a real
///   `GoogleService-Info.plist` is present) to enable automatic `first_open`.
enum AnalyticsServiceFactory {
    static func make(processInfo: ProcessInfo = .processInfo) -> AnalyticsService {
        if processInfo.arguments.contains(where: { $0.hasPrefix("--uitesting") }) {
            return NoOpAnalyticsService()
        }

        guard let config = PostHogRuntimeConfig.fromBundle() else {
            return NoOpAnalyticsService()
        }

        FirebaseAnalyticsBridge.configureIfAvailable()
        return PostHogAnalyticsService(config: config)
    }
}
