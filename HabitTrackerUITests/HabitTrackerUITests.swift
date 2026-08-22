import XCTest

/// UI tests derived from acceptance-criteria.md.
/// Each test maps to one or more Given/When/Then criteria.
///
/// The app runs against an in-memory store under `--uitesting`, so every test starts
/// with onboarding pending and zero habits. `--uitesting-free` pins the entitlement
/// state so StoreKit is never queried during a test run.
final class HabitTrackerUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--uitesting-free"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Onboarding (ref: 4.2)

    /// AC: Given first launch → onboarding shows the welcome screen.
    func testOnboarding_WelcomeScreenAppears() {
        let welcomeTitle = app.staticTexts["onboardingWelcomeTitle"]
        XCTAssertTrue(welcomeTitle.waitForExistence(timeout: 5), "Onboarding welcome screen did not appear")
    }

    /// AC: Skip button is visible and dismisses onboarding.
    func testOnboarding_SkipButton() {
        let skipButton = app.buttons["skipOnboarding"]
        XCTAssertTrue(skipButton.waitForExistence(timeout: 5), "Skip button is missing on first launch")
        skipButton.tap()

        let addButton = app.buttons["addTaskButton"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5), "Task list did not appear after skipping onboarding")
    }

    // MARK: - FR-2: Task List

    /// AC: Given no tasks → empty state shown.
    func testTaskList_EmptyState() {
        dismissOnboarding()

        let emptyText = app.staticTexts["No habits yet"]
        XCTAssertTrue(emptyText.waitForExistence(timeout: 5), "Empty state is missing with no habits")
    }

    /// AC: Given task list → "+" button visible in top right.
    func testTaskList_AddButtonExists() {
        dismissOnboarding()

        XCTAssertTrue(app.buttons["addTaskButton"].waitForExistence(timeout: 5))
    }

    /// AC: Given task list → settings gear visible.
    func testTaskList_SettingsButtonExists() {
        dismissOnboarding()

        XCTAssertTrue(app.buttons["settingsButton"].waitForExistence(timeout: 5))
    }

    /// AC: Tapping "+" opens new task selector.
    func testTaskList_AddButtonOpensSelector() {
        dismissOnboarding()
        openTaskSelector()
    }

    /// AC: Tapping settings gear opens settings.
    func testTaskList_SettingsOpens() {
        dismissOnboarding()
        openSettings()
    }

    // MARK: - New Task Selector (ref: FR-3)

    /// AC: Custom task name input and go button.
    func testNewTaskSelector_CustomTaskInput() {
        dismissOnboarding()
        openTaskSelector()

        let textField = app.textFields["customTaskField"]
        XCTAssertTrue(textField.waitForExistence(timeout: 5), "Custom task field is missing from the selector")
    }

    /// AC: Preset category tabs are visible.
    func testNewTaskSelector_CategoryTabs() {
        dismissOnboarding()
        openTaskSelector()

        for category in ["Health", "Fitness", "Learning", "Social"] {
            let tab = app.buttons["presetCategory_\(category)"]
            XCTAssertTrue(tab.waitForExistence(timeout: 5), "\(category) category tab is missing")
        }
    }

    /// AC: Tapping a preset task navigates to configuration.
    func testNewTaskSelector_PresetNavigatesToConfig() {
        dismissOnboarding()
        openTaskSelector()
        tapMeditatePreset()

        let configTitle = app.navigationBars["Configure Task"]
        XCTAssertTrue(configTitle.waitForExistence(timeout: 5), "Preset did not navigate to task configuration")
    }

    // MARK: - FR-3: Task Configuration

    /// AC: Save button exists and task is saved.
    func testTaskConfiguration_SaveTask() {
        dismissOnboarding()
        createMeditateTask()
    }

    // MARK: - FR-6: Habit summary sheet

    /// AC: a single tap opens the habit summary sheet carrying Stats, Edit and Remove.
    /// Replaces the confirmation dialog the menu used to be
    /// (PRD - Habit strength §8).
    func testHabitSummarySheet_ShowsStrengthAndActions() {
        dismissOnboarding()
        createMeditateTask()

        // A single tap opens the summary sheet; tap-and-hold completes instead.
        let taskCircle = firstTaskCircle
        XCTAssertTrue(taskCircle.waitForExistence(timeout: 5))
        taskCircle.tap()

        XCTAssertTrue(
            app.buttons["habitSummary_statsButton"].waitForExistence(timeout: 5),
            "Habit summary sheet did not open on a single tap"
        )
        XCTAssertTrue(app.buttons["habitSummary_editButton"].exists)
        XCTAssertTrue(app.buttons["habitSummary_removeButton"].exists)

        // A brand-new habit has no completions, so the score is withheld rather
        // than shown as zero.
        XCTAssertTrue(
            app.staticTexts["Habit strength will be shown after 3 completions"].exists,
            "Ineligible habit should show the placeholder instead of a score"
        )
    }

    /// AC: choosing Edit from the summary sheet opens task configuration. Guards the
    /// dismiss-then-present handoff, which silently drops the second sheet if the
    /// action fires while the summary sheet is still on screen.
    func testHabitSummarySheet_EditOpensConfiguration() {
        dismissOnboarding()
        createMeditateTask()

        let taskCircle = firstTaskCircle
        XCTAssertTrue(taskCircle.waitForExistence(timeout: 5))
        taskCircle.tap()

        let editButton = app.buttons["habitSummary_editButton"]
        XCTAssertTrue(editButton.waitForExistence(timeout: 5))
        editButton.tap()

        XCTAssertTrue(
            app.navigationBars["Edit Task"].waitForExistence(timeout: 5),
            "Edit did not open task configuration after the summary sheet dismissed"
        )
    }

    /// AC: an established habit shows a stage badge on the dashboard, and its summary
    /// sheet shows a numeric score rather than the placeholder
    /// (PRD - Habit strength §8).
    func testHabitSummarySheet_EstablishedHabitShowsScoreAndBadge() {
        app.terminate()
        app.launchArguments += ["--uitesting-seed-strong"]
        app.launch()

        let taskCircle = firstTaskCircle
        XCTAssertTrue(taskCircle.waitForExistence(timeout: 5))

        let badge = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'stageBadge_'"))
            .firstMatch
        XCTAssertTrue(
            badge.waitForExistence(timeout: 5),
            "A habit with 60 days of history should carry a stage badge"
        )
        attachScreenshot(named: "Dashboard with strength ring and stage badge")

        taskCircle.tap()

        let ring = app.descendants(matching: .any)["habitSummary_strengthRing"]
        XCTAssertTrue(ring.waitForExistence(timeout: 5), "Summary sheet did not show the strength ring")
        XCTAssertFalse(
            app.staticTexts["Habit strength will be shown after 3 completions"].exists,
            "An eligible habit should show a score, not the placeholder"
        )
        XCTAssertTrue(
            app.descendants(matching: .any)["habitDailyGrid"].exists,
            "Consistency grid is missing"
        )
        attachScreenshot(named: "Habit summary sheet")
    }

    // MARK: - FR-7: Settings

    /// AC: Settings shows week start day, measurement units, categories.
    func testSettings_SectionsExist() {
        dismissOnboarding()
        openSettings()

        XCTAssertTrue(app.staticTexts["General"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Measurement Units"].exists)
        XCTAssertTrue(app.staticTexts["Categories"].exists)
    }

    // MARK: - Helpers

    /// Attaches a screenshot to the test report, so a visual regression is visible in
    /// the results rather than only as a failed predicate.
    private func attachScreenshot(named name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// The habit circles rendered in the task list grid.
    private var firstTaskCircle: XCUIElement {
        app.buttons
            .matching(NSPredicate(format: "identifier BEGINSWITH 'taskCircle_'"))
            .firstMatch
    }

    private func dismissOnboarding(file: StaticString = #filePath, line: UInt = #line) {
        let skipButton = app.buttons["skipOnboarding"]
        XCTAssertTrue(
            skipButton.waitForExistence(timeout: 5),
            "Onboarding did not appear on a clean launch",
            file: file,
            line: line
        )
        skipButton.tap()

        XCTAssertTrue(
            app.buttons["addTaskButton"].waitForExistence(timeout: 5),
            "Task list did not appear after onboarding",
            file: file,
            line: line
        )
    }

    private func openTaskSelector(file: StaticString = #filePath, line: UInt = #line) {
        let addButton = app.buttons["addTaskButton"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5), "Add button is missing", file: file, line: line)
        addButton.tap()

        XCTAssertTrue(
            app.navigationBars["New Task"].waitForExistence(timeout: 5),
            "New task selector did not open",
            file: file,
            line: line
        )
    }

    private func openSettings(file: StaticString = #filePath, line: UInt = #line) {
        let settingsButton = app.buttons["settingsButton"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 5), "Settings button is missing", file: file, line: line)
        settingsButton.tap()

        XCTAssertTrue(
            app.navigationBars["Settings"].waitForExistence(timeout: 5),
            "Settings did not open",
            file: file,
            line: line
        )
    }

    private func tapMeditatePreset(file: StaticString = #filePath, line: UInt = #line) {
        let preset = app.buttons["preset_health.meditate"]
        XCTAssertTrue(preset.waitForExistence(timeout: 5), "Meditate preset is missing", file: file, line: line)
        preset.tap()
    }

    /// Creates the "Meditate" habit from the preset catalog and asserts it lands in the list.
    private func createMeditateTask(file: StaticString = #filePath, line: UInt = #line) {
        openTaskSelector(file: file, line: line)
        tapMeditatePreset(file: file, line: line)

        let saveButton = app.buttons["Save"]
        XCTAssertTrue(
            saveButton.waitForExistence(timeout: 5),
            "Save button is missing in task configuration",
            file: file,
            line: line
        )
        saveButton.tap()

        // The habit circle merges its title into one accessibility element, so match on the label.
        let savedHabit = app.buttons
            .matching(NSPredicate(format: "identifier BEGINSWITH 'taskCircle_' AND label CONTAINS 'Meditate'"))
            .firstMatch
        XCTAssertTrue(
            savedHabit.waitForExistence(timeout: 5),
            "Saved habit did not appear in the task list",
            file: file,
            line: line
        )
    }
}
