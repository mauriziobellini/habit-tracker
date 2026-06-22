import SwiftUI
import SwiftData

/// App settings screen (FR-7).
struct AppSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Category.sortOrder) private var categories: [Category]
    @AppStorage(AppLanguage.userDefaultsKey) private var languageCode = "en"
    @Environment(EntitlementManager.self) private var entitlementManager
    @Environment(\.analyticsService) private var analytics

    @State private var viewModel = AppSettingsViewModel()

    private static let manageSubscriptionsURL = URL(string: "https://apps.apple.com/account/subscriptions")!

    var body: some View {
        NavigationStack {
            Form {
                // MARK: General
                generalSection

                // MARK: Premium
                premiumSection

                // MARK: Measurement Units
                unitsSection

                // MARK: Categories
                categorySection

                // MARK: Support
                supportSection

                // MARK: Data
                dataSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        viewModel.save(to: modelContext)
                        dismiss()
                    }
                }
            }
            .onAppear {
                viewModel.load(from: modelContext)
            }
            .alert("Email Copied", isPresented: $viewModel.showEmailCopiedAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Support email copied to clipboard. Send your message to habit-tracker@fooshi.co")
            }
            .alert(String(localized: "Restore Purchases"), isPresented: $viewModel.showRestoreResultAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.restoreResultMessage)
            }
            .alert("Rename Category", isPresented: $viewModel.showRenameCategoryAlert) {
                TextField("Category name", text: $viewModel.renameCategoryName)
                Button("Cancel", role: .cancel) {
                    viewModel.cancelRename()
                }
                Button("Save") {
                    viewModel.saveRename()
                }
                .disabled(viewModel.renameCategoryName.trimmingCharacters(in: .whitespaces).isEmpty)
            } message: {
                Text("Enter a new name for the category")
            }
            .alert("Delete Category", isPresented: $viewModel.showDeleteCategoryConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    viewModel.deleteCategory(context: modelContext)
                }
            } message: {
                if let cat = viewModel.categoryToDelete {
                    if cat.tasks.isEmpty {
                        Text("Delete \"\(cat.name)\"?")
                    } else {
                        Text("Delete \"\(cat.name)\"? \(cat.tasks.count) task(s) are assigned to this category and will become uncategorized.")
                    }
                }
            }
            .alert(String(localized: "Delete All Data"), isPresented: $viewModel.showDeleteAllDataConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button(String(localized: "Delete All Data"), role: .destructive) {
                    viewModel.deleteAllData(context: modelContext)
                    dismiss()
                }
            } message: {
                Text(String(localized: "This will remove all habits, completions, and categories. Preset categories will be restored on next launch. This cannot be undone."))
            }
        }
    }

    // MARK: - General Section

    private var generalSection: some View {
        Section {
            Picker("Language", selection: $languageCode) {
                ForEach(AppLanguage.allCases) { lang in
                    Text(lang.displayName).tag(lang.rawValue)
                }
            }

            Picker("Week starts on", selection: $viewModel.weekStartDay) {
                Text("Monday").tag(1)
                Text("Saturday").tag(6)
                Text("Sunday").tag(7)
            }
        } header: {
            Text("General")
        }
    }

    // MARK: - Premium Section

    private var premiumSection: some View {
        Section {
            HStack {
                Image(systemName: entitlementManager.isPremium ? "checkmark.seal.fill" : "seal")
                    .foregroundStyle(entitlementManager.isPremium ? Color.accentColor : .secondary)
                Text(entitlementManager.isPremium ? "Premium active" : "Free plan")
                    .foregroundStyle(.primary)
                Spacer()
                if entitlementManager.isLegacyCustomer {
                    Text("Lifetime")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Button {
                Task { await viewModel.restore(entitlementManager: entitlementManager, analytics: analytics) }
            } label: {
                HStack {
                    Image(systemName: "arrow.clockwise")
                        .foregroundStyle(.secondary)
                    Text("Restore Purchases")
                        .foregroundStyle(.primary)
                    Spacer()
                    if viewModel.isRestoring {
                        ProgressView()
                    }
                }
            }
            .disabled(viewModel.isRestoring)
            .accessibilityIdentifier("restorePurchasesButton")

            if entitlementManager.hasActiveSubscription {
                Button {
                    if UIApplication.shared.canOpenURL(Self.manageSubscriptionsURL) {
                        UIApplication.shared.open(Self.manageSubscriptionsURL)
                    }
                } label: {
                    HStack {
                        Image(systemName: "creditcard")
                            .foregroundStyle(.secondary)
                        Text("Manage Subscription")
                            .foregroundStyle(.primary)
                    }
                }
                .accessibilityIdentifier("manageSubscriptionButton")
            }
        } header: {
            Text("Premium")
        }
    }

    // MARK: - Units Section

    private var unitsSection: some View {
        Section {
            Picker("Units", selection: $viewModel.measurementSystem) {
                ForEach(MeasurementSystem.allCases) { system in
                    Text(system.displayName).tag(system)
                }
            }
            .pickerStyle(.inline)
            .labelsHidden()
        } header: {
            Text("Measurement Units")
        }
    }

    // MARK: - Category Section

    private var categorySection: some View {
        Section {
            ForEach(categories) { category in
                categoryRow(category)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        if !category.isPreset {
                            Button(role: .destructive) {
                                viewModel.confirmDeleteCategory(category)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }

                            Button {
                                viewModel.startRenaming(category)
                            } label: {
                                Label("Rename", systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                    }
                    .contextMenu {
                        if !category.isPreset {
                            Button {
                                viewModel.startRenaming(category)
                            } label: {
                                Label("Rename", systemImage: "pencil")
                            }

                            Button(role: .destructive) {
                                viewModel.confirmDeleteCategory(category)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
            }

            if viewModel.showingNewCategory {
                HStack {
                    TextField("Category name", text: $viewModel.newCategoryName)
                    Button("Add") {
                        viewModel.addCategory(context: modelContext)
                    }
                    .disabled(viewModel.newCategoryName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            } else {
                Button("Add Category") {
                    viewModel.showingNewCategory = true
                }
            }
        } header: {
            Text("Categories")
        }
    }

    private func categoryRow(_ category: Category) -> some View {
        HStack {
            Text(category.localizedDisplayName)
                .foregroundStyle(.primary)

            Spacer()

            if category.isPreset {
                Text("Built-in")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Support Section

    private static let privacyPolicyURL = URL(string: "https://habit-ring.lovable.app/privacy")!

    private var supportSection: some View {
        Section {
            Button {
                if UIApplication.shared.canOpenURL(Self.privacyPolicyURL) {
                    UIApplication.shared.open(Self.privacyPolicyURL)
                }
            } label: {
                HStack {
                    Image(systemName: "hand.raised.fill")
                        .foregroundStyle(.secondary)
                    Text("Privacy Policy")
                        .foregroundStyle(.primary)
                }
            }

            Button {
                let email = "habit-tracker@fooshi.co"
                if let url = URL(string: "mailto:\(email)"),
                   UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url)
                } else {
                    UIPasteboard.general.string = email
                    viewModel.showEmailCopiedAlert = true
                }
            } label: {
                HStack {
                    Image(systemName: "envelope.fill")
                        .foregroundStyle(.secondary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Contact Support")
                            .foregroundStyle(.primary)
                        Text("habit-tracker@fooshi.co")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        } header: {
            Text("Support")
        }
    }

    // MARK: - Data Section

    private var dataSection: some View {
        Section {
            Button(role: .destructive) {
                viewModel.showDeleteAllDataConfirmation = true
            } label: {
                Label(String(localized: "Delete All Data"), systemImage: "trash")
            }
        } header: {
            Text(String(localized: "Data"))
        } footer: {
            Text(String(localized: "Remove all habits and data. Onboarding will show again on next launch."))
        }
    }
}
