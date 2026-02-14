import Foundation
import SwiftData

@Model
final class Category {
    var id: UUID
    var name: String
    var isPreset: Bool
    var sortOrder: Int
    var createdAt: Date

    @Relationship(deleteRule: .nullify, inverse: \HabitTask.category)
    var tasks: [HabitTask] = []

    init(
        id: UUID = UUID(),
        name: String,
        isPreset: Bool = false,
        sortOrder: Int = 0,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.isPreset = isPreset
        self.sortOrder = sortOrder
        self.createdAt = createdAt
    }
}
