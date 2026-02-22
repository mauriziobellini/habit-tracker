import Foundation
import SwiftData
import SwiftUI

@Observable
final class AppSettingsViewModel {
    var weekStartDay: Int = 1
    var measurementSystem: MeasurementSystem = .metric
    var showingNewCategory = false
    var newCategoryName = ""
    var categoryToDelete: Category? = nil
    var showDeleteCategoryConfirmation = false
    var categoryToRename: Category? = nil
    var renameCategoryName = ""
    var showRenameCategoryAlert = false
    var showEmailCopiedAlert = false
    var showDeleteAllDataConfirmation = false

    @MainActor
    func load(from context: ModelContext) {
        let settings = AppSettings.shared(in: context)
        weekStartDay = settings.weekStartDay
        measurementSystem = settings.measurementSystem
    }

    @MainActor
    func save(to context: ModelContext) {
        let settings = AppSettings.shared(in: context)
        settings.weekStartDay = weekStartDay
        settings.measurementSystem = measurementSystem
    }

    @MainActor
    func addCategory(context: ModelContext) {
        let trimmed = newCategoryName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let category = Category(name: trimmed)
        context.insert(category)
        newCategoryName = ""
        showingNewCategory = false
    }

    func confirmDeleteCategory(_ category: Category) {
        categoryToDelete = category
        showDeleteCategoryConfirmation = true
    }

    @MainActor
    func deleteCategory(context: ModelContext) {
        guard let category = categoryToDelete else { return }
        // Unlink tasks from this category before deleting
        for task in category.tasks {
            task.category = nil
        }
        context.delete(category)
        categoryToDelete = nil
    }

    func startRenaming(_ category: Category) {
        categoryToRename = category
        renameCategoryName = category.name
        showRenameCategoryAlert = true
    }

    @MainActor
    func saveRename() {
        let trimmed = renameCategoryName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, let category = categoryToRename else { return }
        category.name = trimmed
        categoryToRename = nil
        renameCategoryName = ""
    }

    func cancelRename() {
        categoryToRename = nil
        renameCategoryName = ""
    }

    /// Deletes all habits, completions, and categories; resets onboarding. Preset categories are re-seeded on next launch.
    @MainActor
    func deleteAllData(context: ModelContext) {
        let taskDescriptor = FetchDescriptor<HabitTask>()
        let categoryDescriptor = FetchDescriptor<Category>()
        guard let tasks = try? context.fetch(taskDescriptor),
              let categories = try? context.fetch(categoryDescriptor) else { return }

        for task in tasks {
            NotificationService.shared.cancelNotifications(for: task)
        }
        for task in tasks {
            context.delete(task)
        }
        for category in categories {
            context.delete(category)
        }
        let settings = AppSettings.shared(in: context)
        settings.hasCompletedOnboarding = false
        settings.weekStartDay = 1
        settings.measurementSystem = .metric
    }
}
