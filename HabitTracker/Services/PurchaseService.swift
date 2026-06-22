import Foundation
import StoreKit

/// Outcome of a purchase attempt, surfaced to the paywall UI.
enum PurchaseOutcome: Equatable {
    case success
    case pending
    case cancelled
    case failed(String)
}

/// Wraps StoreKit 2 product loading and purchasing (PRD - Freemium §9).
///
/// Entitlement state lives in `EntitlementManager`; this service only loads products and
/// drives purchase flows, delegating entitlement refresh back to the manager.
@Observable
@MainActor
final class PurchaseService {
    /// Loaded products keyed by their identifier.
    private(set) var products: [String: Product] = [:]

    /// True while products are being fetched from the App Store.
    private(set) var isLoadingProducts = false

    private let entitlementManager: EntitlementManager
    private let analytics: AnalyticsService

    init(entitlementManager: EntitlementManager, analytics: AnalyticsService = NoOpAnalyticsService()) {
        self.entitlementManager = entitlementManager
        self.analytics = analytics
    }

    /// The StoreKit product for a given plan, if loaded.
    func product(for plan: PremiumPlan) -> Product? {
        products[plan.productID]
    }

    /// Localized display price (e.g. "€0.99") for a plan, or nil if not loaded.
    func displayPrice(for plan: PremiumPlan) -> String? {
        product(for: plan)?.displayPrice
    }

    /// Load all paywall products from the App Store.
    func loadProducts() async {
        guard products.isEmpty else { return }
        isLoadingProducts = true
        defer { isLoadingProducts = false }
        do {
            let loaded = try await Product.products(for: ProductIDs.all)
            var map: [String: Product] = [:]
            for product in loaded {
                map[product.id] = product
            }
            products = map
        } catch {
            products = [:]
        }
    }

    /// Purchase the product backing the given plan and refresh entitlements on success.
    func purchase(_ plan: PremiumPlan) async -> PurchaseOutcome {
        guard let product = product(for: plan) else {
            return .failed(String(localized: "Product not available. Please try again."))
        }

        analytics.track(.purchaseStarted, properties: ["plan": plan.rawValue])

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try EntitlementManager.checkVerified(verification)
                await transaction.finish()
                await entitlementManager.refresh()
                analytics.track(.purchaseCompleted, properties: ["plan": plan.rawValue])
                return .success
            case .pending:
                return .pending
            case .userCancelled:
                analytics.track(.purchaseFailed, properties: ["plan": plan.rawValue, "reason": "cancelled"])
                return .cancelled
            @unknown default:
                analytics.track(.purchaseFailed, properties: ["plan": plan.rawValue, "reason": "unknown"])
                return .failed(String(localized: "Purchase could not be completed."))
            }
        } catch {
            analytics.track(.purchaseFailed, properties: ["plan": plan.rawValue, "reason": "error"])
            return .failed(String(localized: "Purchase failed. Please try again."))
        }
    }
}
