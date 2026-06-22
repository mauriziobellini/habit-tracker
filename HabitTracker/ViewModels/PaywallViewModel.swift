import Foundation
import SwiftUI

/// Drives the paywall: plan selection, product loading, purchase, and restore (PRD - Freemium §6, §8).
@Observable
@MainActor
final class PaywallViewModel {
    var selectedPlan: PremiumPlan = .default

    /// True while a purchase or restore is in flight (disables the plan selector + CTA).
    var isProcessing = false

    /// Error message to surface in an alert, if any.
    var errorMessage: String?
    var showError = false

    /// Set to true when the user becomes premium (purchase or restore) so the view can dismiss.
    var didCompletePurchase = false

    /// Informational message after a restore that found nothing to restore.
    var infoMessage: String?
    var showInfo = false

    let purchaseService: PurchaseService
    let entitlementManager: EntitlementManager
    private let analytics: AnalyticsService

    /// Where the paywall was launched from, for analytics (e.g. "add_habit", "locked_habit").
    let source: String

    init(
        purchaseService: PurchaseService,
        entitlementManager: EntitlementManager,
        analytics: AnalyticsService = NoOpAnalyticsService(),
        source: String = "add_habit"
    ) {
        self.purchaseService = purchaseService
        self.entitlementManager = entitlementManager
        self.analytics = analytics
        self.source = source
    }

    /// Call when the paywall appears: load products and log the impression.
    func onAppear() async {
        analytics.track(.paywallShown, properties: ["source": source])
        await purchaseService.loadProducts()
    }

    func select(_ plan: PremiumPlan) {
        guard plan != selectedPlan else { return }
        selectedPlan = plan
        analytics.track(.planSelected, properties: ["plan": plan.rawValue])
    }

    /// Display price for a plan, or a localized placeholder while loading.
    func priceText(for plan: PremiumPlan) -> String {
        purchaseService.displayPrice(for: plan) ?? "—"
    }

    /// Localized label for the primary CTA based on the selected plan.
    var continueButtonTitle: String {
        switch selectedPlan {
        case .monthly, .yearly: return String(localized: "Subscribe")
        case .lifetime: return String(localized: "Buy Lifetime")
        }
    }

    /// Whether the auto-renewal disclosure should be shown (subscriptions only).
    var showsAutoRenewDisclosure: Bool {
        selectedPlan.isSubscription
    }

    func purchase() async {
        guard !isProcessing else { return }
        isProcessing = true
        defer { isProcessing = false }

        let outcome = await purchaseService.purchase(selectedPlan)
        switch outcome {
        case .success:
            didCompletePurchase = true
        case .pending:
            infoMessage = String(localized: "Your purchase is pending approval.")
            showInfo = true
        case .cancelled:
            break
        case .failed(let message):
            errorMessage = message
            showError = true
        }
    }

    func restore() async {
        guard !isProcessing else { return }
        isProcessing = true
        defer { isProcessing = false }

        analytics.track(.restoreTapped, properties: ["source": "paywall"])
        let restored = await entitlementManager.restore()
        if restored {
            analytics.track(.restoreSuccess)
            didCompletePurchase = true
        } else {
            analytics.track(.restoreFailed, properties: ["reason": "nothing_to_restore"])
            infoMessage = String(localized: "No previous purchases found to restore.")
            showInfo = true
        }
    }
}
