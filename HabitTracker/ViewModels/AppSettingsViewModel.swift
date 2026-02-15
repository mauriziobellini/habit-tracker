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
}
