import SwiftUI
import SwiftData

/// Full task configuration form (FR-3). Used for both creating and editing tasks.
struct TaskConfigurationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Category.sortOrder) private var categories: [Category]
    @Query private var allSettings: [AppSettings]

    @Bindable var viewModel: TaskConfigurationViewModel
    var onSave: (() -> Void)? = nil

    private var measurementSystem: MeasurementSystem {
        allSettings.first?.measurementSystem ?? .metric
    }

    private var weekStartDay: Int {
        allSettings.first?.weekStartDay ?? 1
    }

    var body: some View {
        Form {
            // MARK: Icon & Title
            iconAndTitleSection

            // MARK: Goal
            goalSection

            // MARK: Schedule
            scheduleSection

            // MARK: Notifications
            notificationSection

            // MARK: Appearance
            appearanceSection

            // MARK: Category
            categorySection
        }
        .navigationTitle(isEditing ? "Edit Task" : "Configure Task")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    viewModel.save(context: modelContext, categories: categories)
                    onSave?()
                    dismiss()
                }
                .disabled(!viewModel.canSave)
                .fontWeight(.semibold)
            }
        }
        .sheet(isPresented: $viewModel.showingIconPicker) {
            IconPickerView(selectedIcon: $viewModel.iconName)
        }
    }

    private var isEditing: Bool {
        if case .edit = viewModel.mode { return true }
        return false
    }

    // MARK: - Icon & Title Section

    private var iconAndTitleSection: some View {
        Section {
            HStack(spacing: 16) {
                // Icon preview
                Button {
                    viewModel.showingIconPicker = true
                } label: {
                    ZStack {
                        Circle()
                            .fill(TaskColor.from(token: viewModel.colorToken).color.opacity(0.15))
                            .frame(width: 56, height: 56)

                        if let icon = viewModel.iconName {
                            Image(systemName: icon)
                                .font(.title2)
                                .foregroundStyle(TaskColor.from(token: viewModel.colorToken).color)
                        } else {
                            Text(initialsPreview)
                                .font(.headline)
                                .foregroundStyle(TaskColor.from(token: viewModel.colorToken).color)
                        }
                    }
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 4) {
                    TextField("Task name", text: $viewModel.title)
                        .font(.headline)

                    Button("Change icon") {
                        viewModel.showingIconPicker = true
                    }
                    .font(.caption)
                    .foregroundStyle(Color.accentColor)
                }
            }
            .padding(.vertical, 4)
        } header: {
            Text("Task")
        }
    }

    private var initialsPreview: String {
        let words = viewModel.title.split(separator: " ")
        if words.count >= 2 {
            return String(words[0].prefix(1) + words[1].prefix(1)).uppercased()
        }
        let raw = viewModel.title.trimmingCharacters(in: .whitespaces)
        return String(raw.prefix(2)).uppercased()
    }

    // MARK: - Goal Section

    private var goalSection: some View {
        Section {
            Picker("Goal type", selection: $viewModel.goalType) {
                ForEach(GoalType.allCases) { type in
                    Text(type.displayName).tag(type)
                }
            }

            if viewModel.goalType != .none {
                let systemUnits = viewModel.goalType.units(for: measurementSystem)
                HStack {
                    // Stepper for goal value
                    let step: Double = viewModel.goalType == .calories ? 10 : 1
                    let minVal: Double = viewModel.goalType == .calories ? 10 : 1
                    Stepper(
                        value: Binding(
                            get: { viewModel.goalValue ?? minVal },
                            set: { viewModel.goalValue = $0 }
                        ),
                        in: minVal...99999,
                        step: step
                    ) {
                        Text("\(Int(viewModel.goalValue ?? minVal))")
                            .font(.headline)
                    }

                    if !systemUnits.isEmpty {
                        Picker("Unit", selection: unitBinding) {
                            ForEach(systemUnits, id: \.self) { unit in
                                Text(unit).tag(unit)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
            }

            Picker("Measurement period", selection: $viewModel.measurementDuration) {
                ForEach(MeasurementDuration.allCases) { duration in
                    Text(duration.displayName).tag(duration)
                }
            }
        } header: {
            Text("Goal")
        }
    }

    private var unitBinding: Binding<String> {
        Binding(
            get: { viewModel.goalUnit ?? viewModel.goalType.primaryUnit ?? "" },
            set: { viewModel.goalUnit = $0 }
        )
    }

    // MARK: - Schedule Section

    private var scheduleSection: some View {
        Section {
            Picker("Frequency", selection: $viewModel.frequencyType) {
                ForEach(FrequencyType.allCases) { freq in
                    Text(freq.displayName).tag(freq)
                }
            }

            if viewModel.frequencyType == .daily {
                Stepper("Times per day: \(viewModel.timesPerDay)",
                        value: $viewModel.timesPerDay, in: 1...10)
            }

            if viewModel.frequencyType == .specificDays {
                weekdayPicker
            }

            if viewModel.frequencyType == .everyWeek {
                Stepper("Times per week: \(viewModel.timesPerDay)",
                        value: $viewModel.timesPerDay, in: 1...7)
            }
        } header: {
            Text("Schedule")
        }
    }

    /// Ordered weekdays starting from the user's configured week start day.
    private var orderedWeekdays: [Weekday] {
        let all = Weekday.allCases
        guard let startIndex = all.firstIndex(where: { $0.rawValue == weekStartDay }) else {
            return Array(all)
        }
        return Array(all[startIndex...]) + Array(all[..<startIndex])
    }

    private var weekdayPicker: some View {
        HStack(spacing: 8) {
            ForEach(orderedWeekdays) { day in
                let isSelected = viewModel.scheduledDays.contains(day.rawValue)
                Button {
                    if isSelected {
                        viewModel.scheduledDays.remove(day.rawValue)
                    } else {
                        viewModel.scheduledDays.insert(day.rawValue)
                    }
                } label: {
                    Text(String(day.shortName.prefix(2)))
                        .font(.caption.weight(.semibold))
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(isSelected ? Color.accentColor : Color(.secondarySystemBackground))
                        )
                        .foregroundStyle(isSelected ? .white : .primary)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Notification Section

    private var notificationSection: some View {
        Section {
            Toggle("Reminder", isOn: $viewModel.notificationEnabled)

            if viewModel.notificationEnabled {
                DatePicker(
                    "Time",
                    selection: $viewModel.notificationTime,
                    displayedComponents: .hourAndMinute
                )
            }
        } header: {
            Text("Notification")
        }
    }

    // MARK: - Appearance Section

    private var appearanceSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text("Color")
                    .font(.subheadline)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 12) {
                    ForEach(TaskColor.allCases) { taskColor in
                        Button {
                            viewModel.colorToken = taskColor.rawValue
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(taskColor.color)
                                    .frame(width: 32, height: 32)

                                if viewModel.colorToken == taskColor.rawValue {
                                    Image(systemName: "checkmark")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(.white)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.vertical, 4)
        } header: {
            Text("Appearance")
        }
    }

    // MARK: - Category Section

    private var categorySection: some View {
        Section {
            Picker("Category", selection: $viewModel.selectedCategoryID) {
                Text("None").tag(UUID?.none)
                ForEach(categories) { cat in
                    Text(cat.name).tag(UUID?.some(cat.id))
                }
            }

            if viewModel.showingNewCategoryField {
                HStack {
                    TextField("Category name", text: $viewModel.newCategoryName)
                    Button("Add") {
                        viewModel.createCategory(context: modelContext)
                    }
                    .disabled(viewModel.newCategoryName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            } else {
                Button("Create New Category") {
                    viewModel.showingNewCategoryField = true
                }
            }
        } header: {
            Text("Category")
        }
    }
}
