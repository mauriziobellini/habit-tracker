import SwiftUI
import SwiftData

/// Full-screen sheet where the user describes an objective and gets habit proposals
/// generated on device (PRD - objectives §8.3).
///
/// It presents its own paywall: the task list's paywall sheet cannot appear while this
/// sheet is on screen.
struct ObjectivesConfiguratorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.analyticsService) private var analytics
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(EntitlementManager.self) private var entitlementManager
    @Environment(PurchaseService.self) private var purchaseService
    @Query private var tasks: [HabitTask]
    @Query private var allSettings: [AppSettings]

    @State private var viewModel: ObjectivesViewModel
    @State private var configuration: ProposalConfiguration?
    @State private var showingPaywall = false
    @State private var paywallProposal: HabitProposal?
    @State private var premiumUnlocked = false
    @FocusState private var focusedField: Field?

    private enum Field { case objective, refine }

    init(viewModel: ObjectivesViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    private var measurementSystem: MeasurementSystem {
        allSettings.first?.measurementSystem ?? .metric
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        if viewModel.hasSubmitted {
                            resultsSection
                        } else {
                            inputSection
                        }
                    }
                    .padding(.vertical, 16)
                }
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: viewModel.proposals.count) { oldCount, newCount in
                    // Follow new cards from "Refine" / "Generate more"; the first batch
                    // starts at the top, where the user already is.
                    guard newCount > oldCount, viewModel.lastMode != .initial,
                          let last = viewModel.proposals.last else { return }
                    if reduceMotion {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    } else {
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
            }
            .navigationTitle("Add from objective")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .accessibilityIdentifier("objectiveClose")
                }
                if viewModel.showsNewSearch {
                    ToolbarItem(placement: .primaryAction) {
                        Button("New search") {
                            viewModel.newSearch()
                            focusedField = .objective
                        }
                        .accessibilityIdentifier("objectiveNewSearch")
                    }
                }
            }
            .navigationDestination(item: $configuration) { configuration in
                TaskConfigurationView(viewModel: configuration.viewModel) {
                    viewModel.markAdded(id: configuration.proposalID)
                }
            }
        }
        .sheet(isPresented: $showingPaywall, onDismiss: handlePaywallDismissed) {
            PaywallView(
                viewModel: PaywallViewModel(
                    purchaseService: purchaseService,
                    entitlementManager: entitlementManager,
                    analytics: analytics,
                    source: "objective_proposal"
                ),
                onPremiumUnlocked: { premiumUnlocked = true }
            )
        }
        .onAppear {
            analytics.track(.objectiveConfiguratorOpened, properties: [
                "habit_count_before": AnalyticsBucket.habitCount(tasks.count),
                "is_premium": String(entitlementManager.isPremium),
            ])
            viewModel.onAppear()
        }
        .onDisappear {
            viewModel.onDisappear()
        }
    }

    // MARK: - Input

    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            ObjectivePresetCarousel(
                presets: ObjectivePresetCatalog.all,
                isEnabled: !viewModel.isGenerating
            ) { preset in
                focusedField = nil
                viewModel.submitPreset(preset)
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Describe what you want to achieve")
                    .font(.title3.weight(.semibold))
                    .accessibilityAddTraits(.isHeader)

                TextField("I want to...", text: $viewModel.inputText, axis: .vertical)
                    .lineLimit(1...6)
                    .focused($focusedField, equals: .objective)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(.secondarySystemBackground))
                    )
                    .accessibilityIdentifier("objectiveInput")

                footnote

                if viewModel.phase == .rejected {
                    message("We cannot suggest anything for that request", identifier: "objectiveRejected")
                }

                Button {
                    focusedField = nil
                    viewModel.submit()
                } label: {
                    Text("Get habits")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.canSubmit)
                .accessibilityIdentifier("objectiveSubmit")
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Results

    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let objective = viewModel.submittedObjective {
                Text(objective)
                    .font(.title3.weight(.semibold))
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("objectiveSubmittedText")
            }
            ForEach(Array(viewModel.refinements.enumerated()), id: \.offset) { _, refinement in
                Label(refinement, systemImage: "arrow.turn.down.right")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            if let criteria = viewModel.criteria {
                Text(criteria)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("objectiveCriteria")
            }

            ForEach(Array(viewModel.proposals.enumerated()), id: \.element.id) { index, proposal in
                ObjectiveProposalCard(
                    proposal: proposal,
                    index: index,
                    measurementSystem: measurementSystem
                ) {
                    open(proposal, at: index)
                }
                .id(proposal.id)
                .transition(.opacity)
            }

            ForEach(0..<viewModel.skeletonCount, id: \.self) { _ in
                ObjectiveSkeletonCard()
            }

            switch viewModel.phase {
            case .rejected:
                message("We cannot suggest anything for that request", identifier: "objectiveRejected")
            case .failed:
                VStack(alignment: .leading, spacing: 8) {
                    message("Something went wrong. Try again.", identifier: "objectiveFailed")
                    Button("Try again") { viewModel.retry() }
                        .frame(minHeight: 44)
                        .accessibilityIdentifier("objectiveRetry")
                }
            default:
                EmptyView()
            }

            if !viewModel.proposals.isEmpty {
                Button {
                    viewModel.generateMore()
                } label: {
                    Label("Generate more", systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.bordered)
                .disabled(!viewModel.canGenerateMore)
                .accessibilityIdentifier("objectiveGenerateMore")

                refineRow
            }

            footnote
                .padding(.top, 4)
        }
        .padding(.horizontal, 16)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: viewModel.proposals.count)
    }

    private var refineRow: some View {
        HStack(alignment: .bottom, spacing: 8) {
            TextField("Add details to refine the suggestions", text: $viewModel.refineText, axis: .vertical)
                .lineLimit(1...4)
                .focused($focusedField, equals: .refine)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(.secondarySystemBackground))
                )
                .accessibilityIdentifier("objectiveRefineInput")

            Button {
                focusedField = nil
                viewModel.refine()
            } label: {
                Text("Refine")
                    .font(.headline)
                    .frame(minHeight: 44)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!viewModel.canRefine)
            .accessibilityIdentifier("objectiveRefine")
        }
    }

    private var footnote: some View {
        Text("Suggestions are generated on your iPhone")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .accessibilityIdentifier("objectiveFootnote")
    }

    private func message(_ text: LocalizedStringKey, identifier: String) -> some View {
        Label(text, systemImage: "exclamationmark.circle")
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .accessibilityIdentifier(identifier)
    }

    // MARK: - Adding a proposal

    private func open(_ proposal: HabitProposal, at index: Int) {
        guard !proposal.isAdded else { return }
        analytics.track(.objectiveProposalOpened, properties: [
            "position": index,
            "frequency": proposal.frequency.analyticsValue,
            "goal_type": proposal.goalType.rawValue,
        ])
        if HabitAccessPolicy.shouldPresentPaywallForNewHabit(
            currentHabitCount: tasks.count,
            isPremium: entitlementManager.isPremium
        ) {
            paywallProposal = proposal
            premiumUnlocked = false
            showingPaywall = true
        } else {
            configure(proposal)
        }
    }

    private func configure(_ proposal: HabitProposal) {
        let configurationViewModel = TaskConfigurationViewModel(mode: .create)
        configurationViewModel.applyProposal(proposal, measurementSystem: measurementSystem)
        configuration = ProposalConfiguration(proposalID: proposal.id, viewModel: configurationViewModel)
    }

    private func handlePaywallDismissed() {
        // Measurement PRD §9: `paywall_dismissed` only when no purchase/restore happened.
        if premiumUnlocked, let proposal = paywallProposal {
            configure(proposal)
        } else {
            analytics.track(.paywallDismissed, properties: ["source": "objective_proposal"])
        }
        paywallProposal = nil
        premiumUnlocked = false
    }
}

/// Navigation value for the habit configurator opened from a proposal.
private struct ProposalConfiguration: Identifiable, Hashable {
    let id = UUID()
    let proposalID: UUID
    let viewModel: TaskConfigurationViewModel

    static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
