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
            .alert("Delete Category", isPresented: $viewModel.showDeleteCategoryConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    viewModel.deleteCategory(context: modelContext)
                }
            } message: {
                if let cat = viewModel.categoryToDelete {
                    Text("Delete \"\(cat.name)\"? Tasks in this category will become uncategorized.")
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

            Button("Language") {
                // Open iOS Settings for language
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
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
        } header: {
            Text("Measurement Units")
        }
    }

    // MARK: - Category Section

    private var categorySection: some View {
        Section {
            ForEach(categories) { category in
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
                .swipeActions(edge: .trailing) {
                    if !category.isPreset {
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
}
