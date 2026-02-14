import SwiftUI
import SwiftData

/// Task selector view shown when user adds a new task (FR-3).
/// Shows custom task name input at top, preset category tabs, and preset task list.
struct NewTaskSelectorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Category.sortOrder) private var categories: [Category]

    @State private var customTaskName = ""
    @State private var selectedPresetCategory = "Health"
    @State private var navigateToConfig = false
    @State private var configViewModel: TaskConfigurationViewModel?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Custom task input
                customTaskSection

                Divider()

                // Preset category tabs
                presetCategoryTabs

                // Preset task list
                presetTaskList
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .navigationDestination(isPresented: $navigateToConfig) {
                if let vm = configViewModel {
                    TaskConfigurationView(
                        viewModel: vm,
                        onSave: { dismiss() }
                    )
                }
            }
        }
    }

    // MARK: - Custom Task Section

    private var customTaskSection: some View {
        HStack(spacing: 12) {
            TextField("Create custom task…", text: $customTaskName)
                .textFieldStyle(.roundedBorder)
                .font(.body)

            Button {
                let vm = TaskConfigurationViewModel(mode: .create)
                vm.title = customTaskName.trimmingCharacters(in: .whitespaces)
                configViewModel = vm
                navigateToConfig = true
            } label: {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)
            }
            .disabled(customTaskName.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Preset Category Tabs

    private var presetCategoryTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(PresetTaskCatalog.categoryNames, id: \.self) { name in
                    Button {
                        selectedPresetCategory = name
                    } label: {
                        Text(name)
                            .font(.subheadline.weight(.medium))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(selectedPresetCategory == name
                                          ? Color.accentColor
                                          : Color(.secondarySystemBackground))
                            )
                            .foregroundStyle(selectedPresetCategory == name ? .white : .primary)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    // MARK: - Preset Task List

    private var presetTaskList: some View {
        List {
            ForEach(PresetTaskCatalog.tasks(forCategory: selectedPresetCategory)) { preset in
                Button {
                    let vm = TaskConfigurationViewModel(mode: .create)
                    vm.applyPreset(preset, categories: categories)
                    configViewModel = vm
                    navigateToConfig = true
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: preset.iconName)
                            .font(.title3)
                            .foregroundStyle(Color.accentColor)
                            .frame(width: 32, height: 32)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(preset.name)
                                .font(.body)
                                .foregroundStyle(.primary)
                            if let unit = preset.defaultUnit {
                                Text(preset.goalType.displayName + " (\(unit))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .listStyle(.plain)
    }
}
