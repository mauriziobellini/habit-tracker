import Foundation

/// A habit's formation progress at a point in time (PRD - Habit strength §7).
///
/// Deliberately a plain value type rather than a `@Model`: the score is derived
/// from `TaskCompletion` rows, so persisting it would leave a stale number behind
/// whenever past completions are edited.
struct HabitStrength: Equatable {
    /// `HS = 100 * (0.55R + 0.45C)`, rounded and clamped to `0...100`.
    let score: Int

    /// Stage for `score`, forced to `.starting` while the habit is not yet eligible.
    let stage: HabitStage

    /// `R = 1 - e^(-N/40)` — repetition strength.
    let repetition: Double

    /// `C = completions / expected opportunities` in the consistency window, capped at 1.
    let consistency: Double

    /// `N` — stat-credited completions over the habit's whole history.
    let totalCompletions: Int

    /// Whether the score may be shown. Below three completions the app shows a
    /// placeholder instead of a number (PRD §8).
    let isEligible: Bool
}
