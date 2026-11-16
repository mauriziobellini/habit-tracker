import Foundation

/// A ready-made objective shown in the configurator's carousel. Not persisted.
struct ObjectivePreset: Identifiable, Equatable {
    /// Stable identifier sent to analytics as `preset_id`, so preset usage can be
    /// reported without sending any text.
    let id: String
    /// English source string, used as the localization key.
    let title: String

    var localizedTitle: String {
        NSLocalizedString(title, comment: "")
    }
}

/// Static catalog of objective presets (PRD - objectives §8.3).
enum ObjectivePresetCatalog {
    static let all: [ObjectivePreset] = [
        ObjectivePreset(id: "learn_piano",      title: "Learn to play piano"),
        ObjectivePreset(id: "learn_guitar",     title: "Learn to play guitar"),
        ObjectivePreset(id: "morning_person",   title: "Become a morning person"),
        ObjectivePreset(id: "great_parent",     title: "Become a great parent"),
        ObjectivePreset(id: "good_shape",       title: "Get in good shape"),
        ObjectivePreset(id: "be_present",       title: "Be more present"),
        ObjectivePreset(id: "read_more",        title: "Read more books"),
        ObjectivePreset(id: "sleep_better",     title: "Sleep better"),
        ObjectivePreset(id: "learn_language",   title: "Learn a new language"),
        ObjectivePreset(id: "less_stress",      title: "Feel less stressed"),
        ObjectivePreset(id: "eat_healthier",    title: "Eat healthier"),
        ObjectivePreset(id: "run_5k",           title: "Run a 5K"),
    ]
}
