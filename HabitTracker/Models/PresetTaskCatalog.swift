import Foundation

/// A single entry in the preset task catalog. Not persisted — used to pre-fill
/// a new `HabitTask` when the user selects a preset from the task selector.
struct PresetTask: Identifiable {
    let id: String          // e.g. "fitness.run"
    let name: String
    let iconName: String    // SF Symbol name
    let categoryName: String
    let goalType: GoalType
    let defaultUnit: String?
    let defaultGoalValue: Double?
}

/// Static catalog of 25 preset tasks (FR-3 / data-model section 4).
enum PresetTaskCatalog {
    static let all: [PresetTask] = [
        // MARK: Fitness
        PresetTask(id: "fitness.walk",    name: "Walk",     iconName: "figure.walk",       categoryName: "Fitness", goalType: .distance,    defaultUnit: "km",    defaultGoalValue: 3),
        PresetTask(id: "fitness.run",     name: "Run",      iconName: "figure.run",        categoryName: "Fitness", goalType: .distance,    defaultUnit: "km",    defaultGoalValue: 5),
        PresetTask(id: "fitness.bike",    name: "Bike",     iconName: "bicycle",           categoryName: "Fitness", goalType: .distance,    defaultUnit: "km",    defaultGoalValue: 10),
        PresetTask(id: "fitness.pushups", name: "Push ups", iconName: "figure.strengthtraining.functional", categoryName: "Fitness", goalType: .repetitions, defaultUnit: "times", defaultGoalValue: 20),
        PresetTask(id: "fitness.pullups", name: "Pull ups", iconName: "figure.strengthtraining.traditional", categoryName: "Fitness", goalType: .repetitions, defaultUnit: "times", defaultGoalValue: 10),
        PresetTask(id: "fitness.gym",     name: "Gym",      iconName: "dumbbell.fill",     categoryName: "Fitness", goalType: .time,        defaultUnit: "min",   defaultGoalValue: 60),
        PresetTask(id: "fitness.swim",    name: "Swim",     iconName: "figure.pool.swim",  categoryName: "Fitness", goalType: .time,        defaultUnit: "min",   defaultGoalValue: 30),

        // MARK: Health
        PresetTask(id: "health.meditate",          name: "Meditate",                 iconName: "brain.head.profile",   categoryName: "Health", goalType: .time,     defaultUnit: "min",  defaultGoalValue: 10),
        PresetTask(id: "health.healthyMeal",       name: "Eat a healthy meal",       iconName: "fork.knife",           categoryName: "Health", goalType: .none,     defaultUnit: nil,    defaultGoalValue: nil),
        PresetTask(id: "health.journal",           name: "Write journal",            iconName: "book.fill",            categoryName: "Health", goalType: .time,     defaultUnit: "min",  defaultGoalValue: 15),
        PresetTask(id: "health.walkDog",           name: "Walk the dog",             iconName: "dog.fill",             categoryName: "Health", goalType: .time,     defaultUnit: "min",  defaultGoalValue: 30),
        PresetTask(id: "health.vitamins",          name: "Take vitamins",            iconName: "pill.fill",            categoryName: "Health", goalType: .none,     defaultUnit: nil,    defaultGoalValue: nil),
        PresetTask(id: "health.drinkWater",        name: "Drink water",              iconName: "drop.fill",            categoryName: "Health", goalType: .cups,     defaultUnit: "cups", defaultGoalValue: 8),
        PresetTask(id: "health.decreaseCaffeine",  name: "Decrease caffeine",        iconName: "cup.and.saucer.fill",  categoryName: "Health", goalType: .cups,     defaultUnit: "cups", defaultGoalValue: 2),
        PresetTask(id: "health.decreaseCalories",  name: "Decrease calories intake", iconName: "flame.fill",           categoryName: "Health", goalType: .calories, defaultUnit: "kcal", defaultGoalValue: 2000),
        PresetTask(id: "health.dontSmoke",         name: "Don't smoke",              iconName: "nosign",               categoryName: "Health", goalType: .none,     defaultUnit: nil,    defaultGoalValue: nil),
        PresetTask(id: "health.dontBiteNails",     name: "Don't bite nails",         iconName: "hand.raised.fill",     categoryName: "Health", goalType: .none,     defaultUnit: nil,    defaultGoalValue: nil),
        PresetTask(id: "health.daylight",          name: "Time in daylight",         iconName: "sun.max.fill",         categoryName: "Health", goalType: .time,     defaultUnit: "min",  defaultGoalValue: 30),
        PresetTask(id: "health.bedTimeEarly",      name: "Bed time early",           iconName: "bed.double.fill",      categoryName: "Health", goalType: .none,     defaultUnit: nil,    defaultGoalValue: nil),
        PresetTask(id: "health.washHands",         name: "Wash hands",               iconName: "hands.sparkles.fill",  categoryName: "Health", goalType: .none,     defaultUnit: nil,    defaultGoalValue: nil),
        PresetTask(id: "health.floss",             name: "Floss your teeth",         iconName: "mouth.fill",           categoryName: "Health", goalType: .none,     defaultUnit: nil,    defaultGoalValue: nil),

        // MARK: Social
        PresetTask(id: "social.callParents",  name: "Call parents",     iconName: "phone.fill",               categoryName: "Social", goalType: .time, defaultUnit: "min", defaultGoalValue: 15),
        PresetTask(id: "social.callFriend",   name: "Call a friend",    iconName: "phone.arrow.up.right.fill", categoryName: "Social", goalType: .time, defaultUnit: "min", defaultGoalValue: 15),
        PresetTask(id: "social.askFriendOut", name: "Ask a friend out", iconName: "person.2.fill",            categoryName: "Social", goalType: .none, defaultUnit: nil,   defaultGoalValue: nil),
        PresetTask(id: "social.kissPartner",  name: "Kiss partner",     iconName: "heart.fill",               categoryName: "Social", goalType: .none, defaultUnit: nil,   defaultGoalValue: nil),
        PresetTask(id: "social.talkStranger", name: "Talk to a stranger", iconName: "bubble.left.and.bubble.right.fill", categoryName: "Social", goalType: .none, defaultUnit: nil, defaultGoalValue: nil),

        // MARK: Learning
        PresetTask(id: "learning.learnLanguage",  name: "Learn a language",  iconName: "character.book.closed.fill", categoryName: "Learning", goalType: .time, defaultUnit: "min", defaultGoalValue: 30),
        PresetTask(id: "learning.readBook",       name: "Read a book",       iconName: "book.closed.fill",           categoryName: "Learning", goalType: .time, defaultUnit: "min", defaultGoalValue: 30),
        PresetTask(id: "learning.playInstrument", name: "Play instrument",   iconName: "pianokeys",                  categoryName: "Learning", goalType: .time, defaultUnit: "min", defaultGoalValue: 30),
    ]

    /// Preset tasks filtered by category name.
    static func tasks(forCategory categoryName: String) -> [PresetTask] {
        all.filter { $0.categoryName == categoryName }
    }

    /// All unique category names from the catalog, in display order.
    static var categoryNames: [String] {
        ["Health", "Fitness", "Learning", "Social"]
    }
}
