import Foundation

// MARK: - Supported Languages

enum AppLanguage: String, CaseIterable, Identifiable {
    case english    = "en"
    case spanish    = "es"
    case portuguese = "pt-PT"
    case french     = "fr"
    case german     = "de"
    case italian    = "it"
    case dutch      = "nl"

    var id: String { rawValue }

    /// Native-language name so users can find their language regardless of current app locale.
    var displayName: String {
        switch self {
        case .english:    return "English"
        case .spanish:    return "Español"
        case .portuguese: return "Português"
        case .french:     return "Français"
        case .german:     return "Deutsch"
        case .italian:    return "Italiano"
        case .dutch:      return "Nederlands"
        }
    }

    var locale: Locale { Locale(identifier: rawValue) }

    static let userDefaultsKey = "appLanguage"

    /// Picks the best supported language from the device's preferred languages list.
    static func detectFromDevice() -> AppLanguage {
        for preferred in Locale.preferredLanguages {
            if preferred.hasPrefix("pt-PT") || preferred.hasPrefix("pt_PT") {
                return .portuguese
            }
            if preferred.hasPrefix("pt") { continue }

            let baseCode = String(preferred.prefix(2))
            if let match = allCases.first(where: { $0.rawValue == baseCode }) {
                return match
            }
        }
        return .english
    }
}

// MARK: - Bundle Language Override

private var associatedBundleKey: UInt8 = 0

private final class LocalizedBundle: Bundle, @unchecked Sendable {
    override func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        if let bundle = objc_getAssociatedObject(self, &associatedBundleKey) as? Bundle {
            return bundle.localizedString(forKey: key, value: value, table: tableName)
        }
        return super.localizedString(forKey: key, value: value, table: tableName)
    }
}

extension Bundle {
    /// Overrides the bundle used for all `localizedString(forKey:…)` calls on
    /// `Bundle.main`, so `Text("key")`, `String(localized:)`, and
    /// `NSLocalizedString` all resolve from the chosen `.lproj` folder.
    static func setLanguage(_ code: String) {
        object_setClass(Bundle.main, LocalizedBundle.self)

        if let path = Bundle.main.path(forResource: code, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            objc_setAssociatedObject(Bundle.main, &associatedBundleKey, bundle, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        } else {
            objc_setAssociatedObject(Bundle.main, &associatedBundleKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}
