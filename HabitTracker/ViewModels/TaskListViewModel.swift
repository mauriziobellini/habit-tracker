import Foundation
import SwiftData
import SwiftUI

@Observable
final class TaskListViewModel {
    var selectedCategoryID: UUID?
    var showingTaskSelector = false
    var showingSettings = false
    var taskToEdit: HabitTask?
    var taskForStats: HabitTask?
    var taskToDelete: HabitTask?
    var showDeleteConfirmation = false

    /// Filter tasks by the selected category. `nil` means "All".
    func filteredTasks(_ tasks: [HabitTask]) -> [HabitTask] {
        guard let categoryID = selectedCategoryID else {
            return tasks.sorted { $0.sortOrder < $1.sortOrder }
        }
        return tasks
            .filter { $0.category?.id == categoryID }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    func confirmDelete(_ task: HabitTask) {
        taskToDelete = task
        showDeleteConfirmation = true
    }

    func deleteTask(context: ModelContext) {
        guard let task = taskToDelete else { return }
        context.delete(task)
        taskToDelete = nil
    }
}
