import Foundation
import SwiftUI
#if canImport(FoundationModels)
import FoundationModels
#endif

/// Single source of truth for whether the objectives feature is shown (PRD - objectives §8.1).
///
/// Evaluated on every "+" tap, never cached and never driven by a remote flag, so turning
/// Apple Intelligence on or off takes effect on the next tap. The feature is off when any of
/// these hold: iOS earlier than 26, `.unavailable(.deviceNotEligible)`,
/// `.unavailable(.appleIntelligenceNotEnabled)`, `.unavailable(.modelNotReady)`, any other
/// unavailable reason, or the on-device model not supporting the app's language.
protocol ObjectiveAvailabilityChecking {
    func isAvailable() -> Bool
}

struct LiveObjectiveAvailability: ObjectiveAvailabilityChecking {
    /// The in-app language, not `Locale.current`: users can run the app in a language
    /// other than the device's, and suggestions must come back in the app's language.
    var locale: () -> Locale = { AppLanguage.current.locale }
    var modelIsAvailable: (Locale) -> Bool = LiveObjectiveAvailability.systemModelIsAvailable

    func isAvailable() -> Bool {
        modelIsAvailable(locale())
    }

    static func systemModelIsAvailable(for locale: Locale) -> Bool {
        #if canImport(FoundationModels)
        guard #available(iOS 26, *) else { return false }
        let model = SystemLanguageModel.default
        guard case .available = model.availability else { return false }
        return model.supportsLocale(locale)
        #else
        return false
        #endif
    }
}

struct FixedObjectiveAvailability: ObjectiveAvailabilityChecking {
    let value: Bool
    func isAvailable() -> Bool { value }
}

enum ObjectiveAvailabilityFactory {
    static let launchArgumentPrefix = "--uitesting-objectives"

    /// UI tests force the gate so they stay deterministic: on a Mac with Apple Intelligence
    /// the simulator reports the model as available, which would put the bottom sheet in
    /// front of every existing add-habit test.
    static func make(arguments: [String] = ProcessInfo.processInfo.arguments) -> ObjectiveAvailabilityChecking {
        if arguments.contains(where: { $0.hasPrefix(launchArgumentPrefix) }) {
            return FixedObjectiveAvailability(value: true)
        }
        if arguments.contains(where: { $0.hasPrefix("--uitesting") }) {
            return FixedObjectiveAvailability(value: false)
        }
        return LiveObjectiveAvailability()
    }
}

// MARK: - Environment

private struct ObjectiveAvailabilityKey: EnvironmentKey {
    static let defaultValue: ObjectiveAvailabilityChecking = FixedObjectiveAvailability(value: false)
}

extension EnvironmentValues {
    var objectiveAvailability: ObjectiveAvailabilityChecking {
        get { self[ObjectiveAvailabilityKey.self] }
        set { self[ObjectiveAvailabilityKey.self] = newValue }
    }
}
