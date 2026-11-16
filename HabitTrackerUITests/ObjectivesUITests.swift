import XCTest

/// UI tests for "Add from objective" (docs/acceptance-criteria-objectives.md).
///
/// `--uitesting-objectives*` forces the availability gate on and swaps the on-device model
/// for a deterministic stub, so these run on any simulator. Without it the gate is off.
final class ObjectivesUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Gate and bottom sheet

    /// AC: Given objectives are unavailable, "+" opens today's add flow directly.
    func testGateOff_PlusOpensSelectorDirectly() {
        launch([])
        app.buttons["addTaskButton"].tap()

        XCTAssertTrue(app.navigationBars["New Task"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["addOption_objective"].exists)
    }

    /// AC: Given objectives are available, "+" shows both options, and "Add habit" opens
    /// today's flow.
    func testGateOn_PlusShowsBothOptions() {
        launch(["--uitesting-objectives"])
        app.buttons["addTaskButton"].tap()

        XCTAssertTrue(app.buttons["addOption_habit"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["addOption_objective"].exists)
        attachScreenshot("objectives-options-sheet")

        app.buttons["addOption_habit"].tap()
        XCTAssertTrue(app.navigationBars["New Task"].waitForExistence(timeout: 5))
    }

    // MARK: - Configurator

    /// AC: The configurator shows presets, the input, the footnote and a disabled submit.
    func testConfigurator_InitialState() {
        launch(["--uitesting-objectives"])
        openConfigurator()

        XCTAssertTrue(app.staticTexts["objectiveFootnote"].exists)
        XCTAssertFalse(app.buttons["objectiveSubmit"].isEnabled, "Submit must be disabled with empty input")
        XCTAssertTrue(firstHittablePreset() != nil, "No preset is visible")
        attachScreenshot("objectives-configurator")
    }

    /// AC: Submitting an objective streams at least three proposals with the criteria.
    func testSubmit_ShowsProposals() {
        launch(["--uitesting-objectives"])
        openConfigurator()
        submit("Learn to play piano")

        XCTAssertTrue(app.buttons["objectiveCard_0"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["objectiveCard_3"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["objectiveCriteria"].exists)
        XCTAssertTrue(app.buttons["objectiveGenerateMore"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["objectiveNewSearch"].exists)
        attachScreenshot("objectives-proposals")
    }

    /// AC: Tapping a preset starts generation without pressing submit.
    func testPreset_StartsGeneration() throws {
        launch(["--uitesting-objectives"])
        openConfigurator()

        let preset = try XCTUnwrap(firstHittablePreset(), "No preset is visible")
        preset.tap()

        XCTAssertTrue(app.buttons["objectiveCard_0"].waitForExistence(timeout: 10))
    }

    /// AC: Generate more appends a new batch below the existing proposals.
    func testGenerateMore_AppendsProposals() {
        launch(["--uitesting-objectives"])
        openConfigurator()
        submit("Learn to play piano")
        waitForGenerationToFinish()

        app.buttons["objectiveGenerateMore"].tap()
        XCTAssertTrue(app.buttons["objectiveCard_6"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["objectiveCard_0"].exists, "Earlier proposals must stay")
    }

    /// AC: Refine adds a new batch that accounts for the refinement.
    func testRefine_AppendsProposals() {
        launch(["--uitesting-objectives"])
        openConfigurator()
        submit("Learn to play piano")
        waitForGenerationToFinish()

        let refineInput = app.descendants(matching: .any)["objectiveRefineInput"].firstMatch
        refineInput.tap()
        refineInput.typeText("Only ten minutes a day")
        app.buttons["objectiveRefine"].tap()

        XCTAssertTrue(app.buttons["objectiveCard_6"].waitForExistence(timeout: 10))
    }

    /// AC: New search returns to the empty configurator.
    func testNewSearch_ResetsConfigurator() {
        launch(["--uitesting-objectives"])
        openConfigurator()
        submit("Learn to play piano")
        waitForGenerationToFinish()

        app.buttons["objectiveNewSearch"].tap()
        XCTAssertTrue(objectiveInput.waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["objectiveCard_0"].exists)
        XCTAssertFalse(app.buttons["objectiveSubmit"].isEnabled)
    }

    // MARK: - Adding

    /// AC: Tapping a proposal opens the pre-filled configurator; saving marks it added and
    /// creates the habit.
    func testAddProposal_CreatesHabitAndMarksAdded() {
        launch(["--uitesting-objectives"])
        openConfigurator()
        submit("Learn to play piano")
        waitForGenerationToFinish()

        addProposal(at: 0)
        XCTAssertTrue(app.buttons["objectiveCardAdded_0"].waitForExistence(timeout: 5))

        app.buttons["objectiveClose"].tap()
        let habit = app.buttons
            .matching(NSPredicate(format: "identifier BEGINSWITH 'taskCircle_' AND label CONTAINS 'Practice scales'"))
            .firstMatch
        XCTAssertTrue(habit.waitForExistence(timeout: 5), "The added habit is missing from the list")
    }

    /// AC: A free user at the habit limit sees the paywall when opening a proposal.
    func testFreeLimit_ProposalShowsPaywall() {
        launch(["--uitesting-objectives"])
        openConfigurator()
        submit("Learn to play piano")
        waitForGenerationToFinish()

        addProposal(at: 0)
        addProposal(at: 1)

        app.buttons["objectiveCard_2"].tap()
        XCTAssertTrue(app.buttons["paywallContinue"].waitForExistence(timeout: 5))

        app.buttons["paywallClose"].tap()
        XCTAssertTrue(app.buttons["objectiveCard_2"].waitForExistence(timeout: 5), "Proposals must survive the paywall")
    }

    // MARK: - Errors

    /// AC: A rejected objective shows the rejection message and keeps the input.
    func testRejected_ShowsMessage() {
        launch(["--uitesting-objectives-reject"])
        openConfigurator()
        submit("Something inappropriate")

        XCTAssertTrue(app.descendants(matching: .any)["objectiveRejected"].waitForExistence(timeout: 10))
        XCTAssertTrue(objectiveInput.exists)
        XCTAssertFalse(app.buttons["objectiveCard_0"].exists)
    }

    /// AC: A generation error offers a retry.
    func testError_OffersRetry() {
        launch(["--uitesting-objectives-error"])
        openConfigurator()
        submit("Learn to play piano")

        XCTAssertTrue(app.buttons["objectiveRetry"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.descendants(matching: .any)["objectiveFailed"].exists)
    }

    // MARK: - Helpers

    private var objectiveInput: XCUIElement {
        app.descendants(matching: .any)["objectiveInput"].firstMatch
    }

    private func launch(_ extraArgs: [String]) {
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--uitesting-free"] + extraArgs
        app.launch()

        let skip = app.buttons["skipOnboarding"]
        XCTAssertTrue(skip.waitForExistence(timeout: 5), "Onboarding did not appear on a clean launch")
        skip.tap()
        XCTAssertTrue(app.buttons["addTaskButton"].waitForExistence(timeout: 5))
    }

    private func openConfigurator(file: StaticString = #filePath, line: UInt = #line) {
        app.buttons["addTaskButton"].tap()
        let option = app.buttons["addOption_objective"]
        XCTAssertTrue(option.waitForExistence(timeout: 5), "Objective option is missing", file: file, line: line)
        option.tap()
        XCTAssertTrue(objectiveInput.waitForExistence(timeout: 5), "Configurator did not open", file: file, line: line)
    }

    private func submit(_ objective: String) {
        objectiveInput.tap()
        objectiveInput.typeText(objective)
        let submit = app.buttons["objectiveSubmit"]
        XCTAssertTrue(submit.isEnabled)
        submit.tap()
    }

    private func waitForGenerationToFinish(file: StaticString = #filePath, line: UInt = #line) {
        let more = app.buttons["objectiveGenerateMore"]
        XCTAssertTrue(more.waitForExistence(timeout: 10), file: file, line: line)
        let enabled = expectation(for: NSPredicate(format: "isEnabled == true"), evaluatedWith: more)
        wait(for: [enabled], timeout: 10)
    }

    private func addProposal(at index: Int, file: StaticString = #filePath, line: UInt = #line) {
        let card = app.buttons["objectiveCard_\(index)"]
        XCTAssertTrue(card.waitForExistence(timeout: 5), file: file, line: line)
        card.tap()

        let save = app.buttons["Save"]
        XCTAssertTrue(save.waitForExistence(timeout: 5), "Habit configurator did not open", file: file, line: line)
        save.tap()
        allowNotificationsIfAsked()
        XCTAssertTrue(
            app.buttons["objectiveCardAdded_\(index)"].waitForExistence(timeout: 5),
            "Proposal was not marked as added",
            file: file,
            line: line
        )
    }

    private func attachScreenshot(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// Saving a habit with a reminder asks for notification permission the first time.
    private func allowNotificationsIfAsked() {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let allow = springboard.buttons["Allow"]
        if allow.waitForExistence(timeout: 2) {
            allow.tap()
        }
    }

    /// The carousel moves on its own, so pick a preset that is currently on screen.
    private func firstHittablePreset() -> XCUIElement? {
        let presets = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'objectivePreset_'"))
        _ = presets.firstMatch.waitForExistence(timeout: 5)
        // Asking for `isHittable` on a pill that scrolled off screen raises an error.
        let screen = app.windows.firstMatch.frame.insetBy(dx: 40, dy: 0)
        return presets.allElementsBoundByIndex.first { screen.contains($0.frame) }
    }
}
