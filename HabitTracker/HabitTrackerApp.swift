import SwiftUI
import SwiftData

@main
struct HabitTrackerApp: App {
    @AppStorage(AppLanguage.userDefaultsKey) private var languageCode = "en"

    private let analytics: AnalyticsService
    @State private var entitlementManager: EntitlementManager
    @State private var purchaseService: PurchaseService

    init() {
        if UserDefaults.standard.string(forKey: AppLanguage.userDefaultsKey) == nil {
            let detected = AppLanguage.detectFromDevice()
            UserDefaults.standard.set(detected.rawValue, forKey: AppLanguage.userDefaultsKey)
        }
        Bundle.setLanguage(UserDefaults.standard.string(forKey: AppLanguage.userDefaultsKey) ?? "en")

        let analytics = NoOpAnalyticsService()
        let entitlements = EntitlementManager(analytics: analytics)
        self.analytics = analytics
        _entitlementManager = State(initialValue: entitlements)
        _purchaseService = State(initialValue: PurchaseService(entitlementManager: entitlements, analytics: analytics))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.locale, Locale(identifier: languageCode))
                .environment(entitlementManager)
                .environment(purchaseService)
                .environment(\.analyticsService, analytics)
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

// MARK: - Analytics Environment

private struct AnalyticsServiceKey: EnvironmentKey {
    static let defaultValue: AnalyticsService = NoOpAnalyticsService()
}

extension EnvironmentValues {
    var analyticsService: AnalyticsService {
        get { self[AnalyticsServiceKey.self] }
        set { self[AnalyticsServiceKey.self] = newValue }
    }
}
