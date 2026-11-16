import SwiftUI
import SwiftData
import UserNotifications

@main
struct HabitTrackerApp: App {
    @AppStorage(AppLanguage.userDefaultsKey) private var languageCode = "en"

    private let analytics: AnalyticsService
    @State private var entitlementManager: EntitlementManager
    @State private var purchaseService: PurchaseService
    private let appOpenTracker: AppOpenTracker
    private let objectiveAvailability = ObjectiveAvailabilityFactory.make()
    private let modelContainer: ModelContainer
    @State private var strengthCache = HabitStrengthCache()
    /// Retained for the lifetime of the app: `UNUserNotificationCenter` holds its
    /// delegate weakly, so a local would be deallocated and the actions would
    /// silently stop working.
    private let notificationActionHandler: NotificationActionHandler

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
        let container = Self.makeModelContainer()
        modelContainer = container

        let handler = NotificationActionHandler(container: container)
        notificationActionHandler = handler
        UNUserNotificationCenter.current().delegate = handler
    }

    /// UI tests run against an in-memory store so every launch starts from an empty database.
    /// Without this, habits created by one test leak into the next through the on-disk store.
    private static func makeModelContainer(processInfo: ProcessInfo = .processInfo) -> ModelContainer {
        let schema = Schema([
            Category.self,
            HabitTask.self,
            TaskCompletion.self,
            AppSettings.self,
        ])
        let isUITesting = processInfo.arguments.contains { $0.hasPrefix("--uitesting") }
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: isUITesting)
        do {
            return try ModelContainer(for: schema, configurations: configuration)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.locale, Locale(identifier: languageCode))
                .environment(entitlementManager)
                .environment(purchaseService)
                .environment(\.analyticsService, analytics)
                .environment(\.appOpenTracker, appOpenTracker)
                .environment(strengthCache)
                .environment(\.objectiveAvailability, objectiveAvailability)
                .environment(\.makeObjectiveGenerator, { ObjectiveSuggestionFactory.make() })
                .id(languageCode)
                .onChange(of: languageCode) { _, newValue in
                    Bundle.setLanguage(newValue)
                }
                .task {
                    NotificationService.shared.registerNotificationCategories()
                    entitlementManager.startObservingTransactions()
                    await entitlementManager.refresh()
                }
        }
        .modelContainer(modelContainer)
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
