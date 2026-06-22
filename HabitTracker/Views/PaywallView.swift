import SwiftUI

/// Freemium paywall presented as a bottom sheet when a free user reaches the habit limit,
/// or taps a locked habit after a lapsed subscription (PRD - Freemium §6, §8).
struct PaywallView: View {
    @State var viewModel: PaywallViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Called after a successful purchase/restore so the presenter can continue the flow
    /// (e.g. open the new task selector).
    var onPremiumUnlocked: () -> Void = {}

    private static let termsURL = URL(string: "https://habit-ring.lovable.app/terms")!
    private static let privacyURL = URL(string: "https://habit-ring.lovable.app/privacy")!

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    header
                    planSelector
                    disclosureFooter
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 140)
            }
            .background(Color(.systemBackground))
            .safeAreaInset(edge: .bottom) {
                continueBar
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    closeButton
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .task { await viewModel.onAppear() }
        .onChange(of: viewModel.didCompletePurchase) { _, completed in
            if completed {
                onPremiumUnlocked()
                dismiss()
            }
        }
        .alert(String(localized: "Something went wrong"), isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? String(localized: "Please try again."))
        }
        .alert(String(localized: "Restore Purchases"), isPresented: $viewModel.showInfo) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.infoMessage ?? "")
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "infinity.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(Color.accentColor)
                .symbolRenderingMode(.hierarchical)
                .padding(.top, 8)

            Text("Unlock unlimited habits")
                .font(.title.weight(.bold))
                .multilineTextAlignment(.center)

            Text("You've reached the free limit of \(FreemiumConfig.freeHabitLimit) habits.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Plan selector

    private var planSelector: some View {
        VStack(spacing: 12) {
            ForEach(PremiumPlan.displayOrder) { plan in
                planRow(plan)
            }
        }
    }

    private func planRow(_ plan: PremiumPlan) -> some View {
        let isSelected = viewModel.selectedPlan == plan
        return Button {
            viewModel.select(plan)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .font(.title2)
                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(plan.title)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        if plan == .yearly {
                            Text("Best value")
                                .font(.caption2.weight(.bold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(Color.accentColor.opacity(0.15)))
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                    Text(subtitle(for: plan))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(viewModel.priceText(for: plan))
                    .font(.headline)
                    .foregroundStyle(.primary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isProcessing)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(plan.title), \(viewModel.priceText(for: plan))")
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
        .accessibilityIdentifier("plan_\(plan.rawValue)")
    }

    private func subtitle(for plan: PremiumPlan) -> String {
        switch plan {
        case .monthly: return String(localized: "Billed monthly")
        case .yearly: return String(localized: "Billed yearly")
        case .lifetime: return String(localized: "One-time payment, no renewals")
        }
    }

    // MARK: - Continue bar

    private var continueBar: some View {
        VStack(spacing: 8) {
            Button {
                Task { await viewModel.purchase() }
            } label: {
                ZStack {
                    if viewModel.isProcessing {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text(viewModel.continueButtonTitle)
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Capsule().fill(Color.accentColor))
                .foregroundStyle(.white)
            }
            .disabled(viewModel.isProcessing)
            .accessibilityIdentifier("paywallContinue")

            Button {
                Task { await viewModel.restore() }
            } label: {
                Text("Restore Purchases")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .disabled(viewModel.isProcessing)
            .accessibilityIdentifier("paywallRestore")
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 8)
        .background(.bar)
    }

    // MARK: - Disclosure footer

    private var disclosureFooter: some View {
        VStack(spacing: 8) {
            if viewModel.showsAutoRenewDisclosure {
                Text("Subscriptions renew automatically until cancelled. Cancel anytime in Settings at least 24 hours before the end of the current period.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 16) {
                Link("Terms of Use", destination: Self.termsURL)
                Link("Privacy Policy", destination: Self.privacyURL)
            }
            .font(.caption2)
        }
    }

    // MARK: - Close

    private var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark.circle.fill")
                .font(.title2)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.secondary)
        }
        .frame(width: 44, height: 44)
        .accessibilityLabel(String(localized: "Close"))
        .accessibilityIdentifier("paywallClose")
    }
}
