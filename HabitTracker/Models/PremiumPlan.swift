import Foundation

/// The three premium options offered on the paywall (PRD - Freemium §6, §7).
enum PremiumPlan: String, CaseIterable, Identifiable {
    case monthly
    case yearly
    case lifetime

    var id: String { rawValue }

    /// The StoreKit product identifier backing this plan.
    var productID: String {
        switch self {
        case .monthly: return ProductIDs.monthly
        case .yearly: return ProductIDs.yearly
        case .lifetime: return ProductIDs.lifetime
        }
    }

    /// Whether this plan is an auto-renewable subscription (vs. a one-time purchase).
    var isSubscription: Bool {
        switch self {
        case .monthly, .yearly: return true
        case .lifetime: return false
        }
    }

    /// The plan selected by default on the paywall (PRD - Freemium §6: yearly).
    static let `default`: PremiumPlan = .yearly

    /// Display order on the paywall: yearly first (default/best value), then monthly, then lifetime.
    static let displayOrder: [PremiumPlan] = [.yearly, .monthly, .lifetime]

    /// Localized title shown on the plan row.
    var title: String {
        switch self {
        case .monthly: return String(localized: "Monthly")
        case .yearly: return String(localized: "Yearly")
        case .lifetime: return String(localized: "Lifetime")
        }
    }
}
