import SwiftUI
import SwiftData

@main
struct HabitTrackerApp: App {
    @AppStorage(AppLanguage.userDefaultsKey) private var languageCode = "en"

    private let analytics: AnalyticsService
    @State private var entitlementManager: EntitlementManager
    @State private var purchaseService: PurchaseService
    private let appOpenTracker: AppOpenTracker

    init() {
        if UserDefaults.standard.string(forKey: AppLanguage.userDefaultsKey) == nil {
            let detected = AppLanguage.detectFromDevice()
            UserDefaults.standard.set(detected.rawValue, forKey: AppLanguage.userDefaultsKey)
        }
        Bundle.setLanguage(UserDefaults.standard.string(forKey: AppLanguage.userDefaultsKey) ?? "en")

        let analytics = AnalyticsServiceFactory.make()
        let entitlements = EntitlementManager(analytics: analytics)
        self.analytics = analytics
        _entitlementManager = State(initialValue: entitlements)
        _purchaseService = State(initialValue: PurchaseService(entitlementManager: entitlements, analytics: analytics))
        appOpenTracker = AppOpenTracker(analytics: analytics)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.locale, Locale(identifier: languageCode))
                .environment(entitlementManager)
                .environment(purchaseService)
                .environment(\.analyticsService, analytics)
                .environment(\.appOpenTracker, appOpenTracker)
                .id(languageCode)
                .onChange(of: languageCode) { _, newValue in
                    Bundle.setLanguage(newValue)
                }
                .task {
                    entitlementManager.startObservingTransactions()
                    await entitlementManager.refresh()
                }
        }
        .modelContainer(for: [
            Category.self,
            HabitTask.self,
            TaskCompletion.self,
            AppSettings.self,
        ])
    }
}

/// Fires `app_open` when the app becomes active, with the debounce and first-open rules from
/// the Measurement PRD §9: 30-second debounce to avoid double-counting returns from system
/// sheets, and `is_first_open=true` only on the very first open after install.
final class AppOpenTracker {
    private let analytics: AnalyticsService
    private let debounceInterval: TimeInterval
    private let firstOpenKey = "analytics.did_first_open"
    private var lastOpenAt: Date?

    init(analytics: AnalyticsService, debounceInterval: TimeInterval = 30) {
        self.analytics = analytics
        self.debounceInterval = debounceInterval
    }

    func trackOpenIfNeeded(now: Date = .now) {
        if let last = lastOpenAt, now.timeIntervalSince(last) < debounceInterval {
            return
        }
        lastOpenAt = now

        let defaults = UserDefaults.standard
        let isFirstOpen = !defaults.bool(forKey: firstOpenKey)
        if isFirstOpen {
            defaults.set(true, forKey: firstOpenKey)
        }
        analytics.track(.appOpen, properties: ["is_first_open": String(isFirstOpen)])
    }
}

// MARK: - Analytics Environment

private struct AnalyticsServiceKey: EnvironmentKey {
    static let defaultValue: AnalyticsService = NoOpAnalyticsService()
}

private struct AppOpenTrackerKey: EnvironmentKey {
    static let defaultValue: AppOpenTracker? = nil
}

extension EnvironmentValues {
    var analyticsService: AnalyticsService {
        get { self[AnalyticsServiceKey.self] }
        set { self[AnalyticsServiceKey.self] = newValue }
    }

    var appOpenTracker: AppOpenTracker? {
        get { self[AppOpenTrackerKey.self] }
        set { self[AppOpenTrackerKey.self] = newValue }
    }
}
