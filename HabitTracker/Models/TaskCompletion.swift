import Foundation
import SwiftData

@Model
final class TaskCompletion {
    var id: UUID
    var completedAt: Date
    var value: Double?

    var task: HabitTask?

    init(
        id: UUID = UUID(),
        completedAt: Date = .now,
        value: Double? = nil,
        task: HabitTask? = nil
    ) {
        self.id = id
        self.completedAt = completedAt
        self.value = value
        self.task = task
    }
}
