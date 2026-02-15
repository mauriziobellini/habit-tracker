import SwiftUI
import SwiftData

/// App settings screen (FR-7).
struct AppSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Category.sortOrder) private var categories: [Category]

    @State private var viewModel = AppSettingsViewModel()

    var body: some View {
        NavigationStack {
            Form {
                // MARK: General
                generalSection

                // MARK: Measurement Units
                unitsSection

                // MARK: Categories
                categorySection

                // MARK: Support
                supportSection
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
        }
    }

    // MARK: - General Section

    private var generalSection: some View {
        Section {
            Picker("Week starts on", selection: $viewModel.weekStartDay) {
                Text("Monday").tag(1)
                Text("Saturday").tag(6)
                Text("Sunday").tag(7)
            }

            // TODO: Re-enable when localization is implemented (see issue #10)
            // Button("Language") {
            //     if let url = URL(string: UIApplication.openSettingsURLString) {
            //         UIApplication.shared.open(url)
            //     }
            // }
        } header: {
            Text("General")
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
            Text(category.name)
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

    private var supportSection: some View {
        Section {
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
}
