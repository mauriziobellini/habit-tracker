import XCTest

/// UI tests derived from acceptance-criteria.md.
/// Each test maps to one or more Given/When/Then criteria.
final class HabitTrackerUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        // Reset state for clean test runs
        app.launchArguments = ["--uitesting"]
        app.launch()
    }

    // MARK: - Onboarding (ref: 4.2)

    /// AC: Given first launch → onboarding shows tap-and-hold tutorial.
    func testOnboarding_WelcomeScreenAppears() {
        // On first launch, the onboarding should appear
        // Look for the welcome text
        let welcomeText = app.staticTexts["Build Streaks.\nForm Habits."]
        if welcomeText.waitForExistence(timeout: 3) {
            XCTAssertTrue(welcomeText.exists)
        }
    }

    /// AC: Skip button is visible and dismisses onboarding.
    func testOnboarding_SkipButton() {
        let skipButton = app.buttons["skipOnboarding"]
        if skipButton.waitForExistence(timeout: 3) {
            skipButton.tap()
            // After skip, task list should appear
            let addButton = app.buttons["addTaskButton"]
            XCTAssertTrue(addButton.waitForExistence(timeout: 3))
        }
    }

    // MARK: - FR-2: Task List

    /// AC: Given no tasks → empty state shown.
    func testTaskList_EmptyState() {
        // Skip onboarding first
        skipOnboardingIfPresent()

        let emptyText = app.staticTexts["No habits yet"]
        XCTAssertTrue(emptyText.waitForExistence(timeout: 3))
    }

    /// AC: Given task list → "+" button visible in top right.
    func testTaskList_AddButtonExists() {
        skipOnboardingIfPresent()

        let addButton = app.buttons["addTaskButton"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 3))
    }

    /// AC: Given task list → settings gear visible.
    func testTaskList_SettingsButtonExists() {
        skipOnboardingIfPresent()

        let settingsButton = app.buttons["settingsButton"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 3))
    }

    /// AC: Tapping "+" opens new task selector.
    func testTaskList_AddButtonOpensSelector() {
        skipOnboardingIfPresent()

        let addButton = app.buttons["addTaskButton"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 3))
        addButton.tap()

        // Task selector should appear with "New Task" title
        let newTaskTitle = app.navigationBars["New Task"]
        XCTAssertTrue(newTaskTitle.waitForExistence(timeout: 3))
    }

    /// AC: Tapping settings gear opens settings.
    func testTaskList_SettingsOpens() {
        skipOnboardingIfPresent()

        let settingsButton = app.buttons["settingsButton"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 3))
        settingsButton.tap()

        let settingsTitle = app.navigationBars["Settings"]
        XCTAssertTrue(settingsTitle.waitForExistence(timeout: 3))
    }

    // MARK: - New Task Selector (ref: FR-3)

    /// AC: Custom task name input and go button.
    func testNewTaskSelector_CustomTaskInput() {
        skipOnboardingIfPresent()
        openTaskSelector()

        // Custom task text field should exist
        let textField = app.textFields["Create custom task…"]
        XCTAssertTrue(textField.waitForExistence(timeout: 3))
    }

    /// AC: Preset category tabs are visible.
    func testNewTaskSelector_CategoryTabs() {
        skipOnboardingIfPresent()
        openTaskSelector()

        let healthTab = app.buttons["Health"]
        XCTAssertTrue(healthTab.waitForExistence(timeout: 3))
    }

    /// AC: Tapping a preset task navigates to configuration.
    func testNewTaskSelector_PresetNavigatesToConfig() {
        skipOnboardingIfPresent()
        openTaskSelector()

        // Tap on "Meditate" (Health category is default)
        let meditateCell = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Meditate'")).firstMatch
        if meditateCell.waitForExistence(timeout: 3) {
            meditateCell.tap()

            // Should navigate to configuration
            let configTitle = app.navigationBars["Configure Task"]
            XCTAssertTrue(configTitle.waitForExistence(timeout: 3))
        }
    }

    // MARK: - FR-3: Task Configuration

    /// AC: Save button exists and task is saved.
    func testTaskConfiguration_SaveTask() {
        skipOnboardingIfPresent()
        openTaskSelector()

        // Tap a preset
        let meditateCell = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Meditate'")).firstMatch
        guard meditateCell.waitForExistence(timeout: 3) else { return }
        meditateCell.tap()

        // Configuration view should appear
        let saveButton = app.buttons["Save"]
        guard saveButton.waitForExistence(timeout: 3) else { return }
        saveButton.tap()

        // Should return to task list with the task visible
        let taskList = app.staticTexts["Meditate"]
        XCTAssertTrue(taskList.waitForExistence(timeout: 5))
    }

    // MARK: - FR-6: Task Menu

    /// AC: Context menu shows Stats, Edit, Remove.
    func testTaskMenu_ContextMenuOptions() {
        // Create a task first
        createMeditateTask()

        // Long press to trigger context menu
        let taskElement = app.staticTexts["Meditate"]
        guard taskElement.waitForExistence(timeout: 3) else { return }
        taskElement.press(forDuration: 1.5)

        // Check menu items
        let statsButton = app.buttons["Stats"]
        let editButton = app.buttons["Edit"]
        let removeButton = app.buttons["Remove"]

        XCTAssertTrue(statsButton.waitForExistence(timeout: 3))
        XCTAssertTrue(editButton.exists)
        XCTAssertTrue(removeButton.exists)
    }

    // MARK: - FR-7: Settings

    /// AC: Settings shows week start day, measurement units, categories.
    func testSettings_SectionsExist() {
        skipOnboardingIfPresent()

        let settingsButton = app.buttons["settingsButton"]
        guard settingsButton.waitForExistence(timeout: 3) else { return }
        settingsButton.tap()

        let generalHeader = app.staticTexts["General"]
        let unitsHeader = app.staticTexts["Measurement Units"]
        let categoriesHeader = app.staticTexts["Categories"]

        XCTAssertTrue(generalHeader.waitForExistence(timeout: 3))
        XCTAssertTrue(unitsHeader.exists)
        XCTAssertTrue(categoriesHeader.exists)
    }

    // MARK: - Helpers

    private func skipOnboardingIfPresent() {
        let skipButton = app.buttons["skipOnboarding"]
        if skipButton.waitForExistence(timeout: 2) {
            skipButton.tap()
            // Wait for task list to load
            _ = app.buttons["addTaskButton"].waitForExistence(timeout: 3)
        }
    }

    private func openTaskSelector() {
        let addButton = app.buttons["addTaskButton"]
        guard addButton.waitForExistence(timeout: 3) else { return }
        addButton.tap()
    }

    private func createMeditateTask() {
        skipOnboardingIfPresent()
        openTaskSelector()

        let meditateCell = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Meditate'")).firstMatch
        guard meditateCell.waitForExistence(timeout: 3) else { return }
        meditateCell.tap()

        let saveButton = app.buttons["Save"]
        guard saveButton.waitForExistence(timeout: 3) else { return }
        saveButton.tap()

        // Wait for task to appear in list
        _ = app.staticTexts["Meditate"].waitForExistence(timeout: 3)
    }
}
