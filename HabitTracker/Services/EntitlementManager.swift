import Foundation
import StoreKit
import SwiftUI

/// Single source of truth for the user's premium entitlement state (PRD - Freemium §7, §9).
///
/// Premium is granted when the user has an active subscription **or** any lifetime purchase.
/// Lifetime includes both the €15 non-consumable IAP and legacy €0.99 paid-app customers,
/// who are mapped to lifetime via `AppTransaction` (PRD - Freemium §10).
@Observable
@MainActor
final class EntitlementManager {
    /// Whether the user currently has an active auto-renewable subscription.
    private(set) var hasActiveSubscription = false

    /// Whether the user owns lifetime premium (purchased €15 IAP or legacy €0.99 paid-app).
    private(set) var hasLifetimePurchase = false

    /// Whether the lifetime entitlement came from a legacy paid-app download (vs. the €15 IAP).
    private(set) var isLegacyCustomer = false

    /// True once the first entitlement refresh has completed (used to avoid UI flicker).
    private(set) var didLoad = false

    /// Combined premium flag used throughout the app.
    var isPremium: Bool { hasActiveSubscription || hasLifetimePurchase }

    private let analytics: AnalyticsService
    private var updatesTask: Task<Void, Never>?

    init(analytics: AnalyticsService = NoOpAnalyticsService()) {
        self.analytics = analytics
        applyUITestingOverridesIfNeeded()
    }

    /// Begin listening for StoreKit transaction updates (call once at app launch).
    func startObservingTransactions() {
        guard updatesTask == nil else { return }
        updatesTask = Task(priority: .background) { [weak self] in
            for await update in Transaction.updates {
                guard let self else { return }
                if let transaction = try? Self.checkVerified(update) {
                    await transaction.finish()
                    await self.refresh()
                }
            }
        }
    }

    /// Re-evaluate all entitlements: subscriptions, lifetime IAP, and legacy paid-app ownership.
    func refresh() async {
        if isUITestingOverrideActive { return }

        var subscriptionActive = false
        var ownsLifetimeIAP = false

        for await result in Transaction.currentEntitlements {
            guard let transaction = try? Self.checkVerified(result) else { continue }
            guard transaction.revocationDate == nil else { continue }
            switch transaction.productType {
            case .autoRenewable:
                subscriptionActive = true
            case .nonConsumable:
                ownsLifetimeIAP = true
            default:
                break
            }
        }

        // A user is "legacy" only when their lifetime access comes from the old paid-app
        // download rather than the €15 lifetime IAP (PRD - Freemium §10).
        let ownsLegacyPaidApp = await checkLegacyPaidAppOwnership()
        let isLegacy = !ownsLifetimeIAP && ownsLegacyPaidApp
        if isLegacy && !isLegacyCustomer {
            analytics.track(.legacyPremiumDetected)
        }

        hasActiveSubscription = subscriptionActive
        hasLifetimePurchase = ownsLifetimeIAP || isLegacy
        isLegacyCustomer = isLegacy
        didLoad = true
    }

    /// Restore purchases by syncing with the App Store, then re-evaluating entitlements.
    /// Returns `true` if the user has premium after the restore (PRD - Freemium §7).
    @discardableResult
    func restore() async -> Bool {
        try? await AppStore.sync()
        await refresh()
        return isPremium
    }

    // MARK: - Legacy paid-app mapping

    /// Detects whether the user originally purchased the legacy €0.99 paid app.
    ///
    /// Existing customers paid for the **app download**, not an IAP, so ownership is detected
    /// via `AppTransaction.originalAppVersion`: any original purchase predating the first
    /// freemium version is a legacy customer entitled to lifetime premium (PRD - Freemium §10).
    private func checkLegacyPaidAppOwnership() async -> Bool {
        do {
            let result = try await AppTransaction.shared
            guard let appTransaction = try? Self.checkVerified(result) else { return false }
            // In the sandbox, TestFlight, and Xcode environments `originalAppVersion` is
            // always "1.0" and does not reflect real purchase history. Trusting it there
            // would incorrectly grant lifetime premium to App Review, hiding the paywall
            // and IAPs (App Review Guideline 2.1). Legacy mapping is production-only.
            guard appTransaction.environment == .production else { return false }
            return Self.isLegacyVersion(
                appTransaction.originalAppVersion,
                firstFreemiumVersion: FreemiumConfig.firstFreemiumVersion
            )
        } catch {
            return false
        }
    }

    /// Returns `true` if `originalVersion` is strictly older than `firstFreemiumVersion`.
    ///
    /// Exposed (internal) for unit testing the version comparison logic without StoreKit.
    nonisolated static func isLegacyVersion(_ originalVersion: String, firstFreemiumVersion: String) -> Bool {
        compareVersions(originalVersion, firstFreemiumVersion) == .orderedAscending
    }

    /// Numeric, component-wise version comparison ("1.10" > "1.9").
    nonisolated static func compareVersions(_ lhs: String, _ rhs: String) -> ComparisonResult {
        let lhsParts = lhs.split(separator: ".").map { Int($0) ?? 0 }
        let rhsParts = rhs.split(separator: ".").map { Int($0) ?? 0 }
        let count = max(lhsParts.count, rhsParts.count)
        for index in 0..<count {
            let left = index < lhsParts.count ? lhsParts[index] : 0
            let right = index < rhsParts.count ? rhsParts[index] : 0
            if left < right { return .orderedAscending }
            if left > right { return .orderedDescending }
        }
        return .orderedSame
    }

    // MARK: - Verification

    enum StoreError: Error { case failedVerification }

    static func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }

    // MARK: - UI Testing Overrides

    private var isUITestingOverrideActive: Bool {
        let args = ProcessInfo.processInfo.arguments
        return args.contains("--uitesting-premium") || args.contains("--uitesting-free")
    }

    private func applyUITestingOverridesIfNeeded() {
        let args = ProcessInfo.processInfo.arguments
        if args.contains("--uitesting-premium") {
            hasLifetimePurchase = true
            didLoad = true
        } else if args.contains("--uitesting-free") {
            hasActiveSubscription = false
            hasLifetimePurchase = false
            didLoad = true
        }
    }
}
