import Foundation

/// Central source of truth for StoreKit product identifiers and freemium limits.
///
/// These identifiers must match the products configured in App Store Connect and in
/// `Configuration.storekit`. They must never be renamed once shipped, otherwise existing
/// purchasers would lose their entitlements (see PRD - Freemium §10).
enum ProductIDs {
    static let monthly = "co.fooshi.habitring.premium.monthly"
    static let yearly = "co.fooshi.habitring.premium.yearly"
    static let lifetime = "co.fooshi.habitring.premium.lifetime"

    /// All purchasable products offered on the paywall.
    static let all: [String] = [monthly, yearly, lifetime]

    /// Auto-renewable subscriptions (excludes the lifetime non-consumable).
    static let subscriptions: [String] = [monthly, yearly]
}

/// Freemium configuration constants.
enum FreemiumConfig {
    /// Number of habits a non-premium user can create and use for free.
    static let freeHabitLimit = 2

    /// The first app marketing version distributed under the freemium model.
    ///
    /// Any user whose original App Store purchase predates this version paid the legacy
    /// €0.99 one-time download and is mapped to lifetime premium (PRD - Freemium §10).
    static let firstFreemiumVersion = "2.0.0"
}
