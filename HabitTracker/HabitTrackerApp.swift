import SwiftUI
import SwiftData

@main
struct HabitTrackerApp: App {
    @AppStorage(AppLanguage.userDefaultsKey) private var languageCode = "en"

    init() {
        if UserDefaults.standard.string(forKey: AppLanguage.userDefaultsKey) == nil {
            let detected = AppLanguage.detectFromDevice()
            UserDefaults.standard.set(detected.rawValue, forKey: AppLanguage.userDefaultsKey)
        }
        Bundle.setLanguage(UserDefaults.standard.string(forKey: AppLanguage.userDefaultsKey) ?? "en")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.locale, Locale(identifier: languageCode))
                .id(languageCode)
                .onChange(of: languageCode) { _, newValue in
                    Bundle.setLanguage(newValue)
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
