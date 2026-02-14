import SwiftUI

/// Curated set of 16 accent colors for tasks (UX principles section 4).
/// Each token maps to a `Color` that is vibrant in both light and dark mode.
enum TaskColor: String, CaseIterable, Identifiable {
    case blue       = "blue"
    case indigo     = "indigo"
    case purple     = "purple"
    case pink       = "pink"
    case red        = "red"
    case orange     = "orange"
    case yellow     = "yellow"
    case green      = "green"
    case mint       = "mint"
    case teal       = "teal"
    case cyan       = "cyan"
    case brown      = "brown"
    case coral      = "coral"
    case lavender   = "lavender"
    case magenta    = "magenta"
    case lime       = "lime"

    var id: String { rawValue }

    /// The SwiftUI Color for this token.
    var color: Color {
        switch self {
        case .blue:     return .blue
        case .indigo:   return .indigo
        case .purple:   return .purple
        case .pink:     return .pink
        case .red:      return .red
        case .orange:   return .orange
        case .yellow:   return .yellow
        case .green:    return .green
        case .mint:     return .mint
        case .teal:     return .teal
        case .cyan:     return .cyan
        case .brown:    return .brown
        case .coral:    return Color(red: 1.0, green: 0.44, blue: 0.37)
        case .lavender: return Color(red: 0.69, green: 0.62, blue: 0.87)
        case .magenta:  return Color(red: 0.85, green: 0.24, blue: 0.63)
        case .lime:     return Color(red: 0.55, green: 0.80, blue: 0.22)
        }
    }

    var displayName: String {
        rawValue.capitalized
    }

    /// Look up a `TaskColor` by its raw string token; falls back to `.blue`.
    static func from(token: String) -> TaskColor {
        TaskColor(rawValue: token) ?? .blue
    }
}
