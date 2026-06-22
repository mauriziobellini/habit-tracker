import XCTest

/// UI tests for the freemium paywall and premium settings (PRD - Freemium §6, §7, §8).
final class FreemiumUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func makeApp(_ extraArgs: [String]) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting"] + extraArgs
        return app
    }

    // MARK: - Paywall

    /// AC: Free user with 2 habits tapping "+" sees the paywall on the 3rd habit.
    func testPaywall_AppearsOnThirdHabitAttempt() {
        let app = makeApp(["--uitesting-seed-two", "--uitesting-free"])
        app.launch()

        let addButton = app.buttons["addTaskButton"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5))
        addButton.tap()

        // The paywall continue button should appear instead of the task selector.
        let continueButton = app.buttons["paywallContinue"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 5), "Paywall should appear on the 3rd habit")
    }

    /// AC: Paywall shows all three plan options.
    func testPaywall_ShowsThreePlans() {
        let app = makeApp(["--uitesting-seed-two", "--uitesting-free"])
        app.launch()

        let addButton = app.buttons["addTaskButton"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5))
        addButton.tap()

        XCTAssertTrue(app.buttons["plan_yearly"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["plan_monthly"].exists)
        XCTAssertTrue(app.buttons["plan_lifetime"].exists)
    }

    /// AC: Closing the paywall returns to the task list without creating a habit.
    func testPaywall_CloseDismisses() {
        let app = makeApp(["--uitesting-seed-two", "--uitesting-free"])
        app.launch()

        let addButton = app.buttons["addTaskButton"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5))
        addButton.tap()

        let close = app.buttons["paywallClose"]
        XCTAssertTrue(close.waitForExistence(timeout: 5))
        close.tap()

        XCTAssertTrue(addButton.waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["paywallContinue"].exists)
    }

    // MARK: - Premium settings

    /// AC: Premium user sees an active status and a Restore Purchases action in Settings.
    func testSettings_PremiumUserSeesRestore() {
        let app = makeApp(["--uitesting-seed-two", "--uitesting-premium"])
        app.launch()

        let settingsButton = app.buttons["settingsButton"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 5))
        settingsButton.tap()

        XCTAssertTrue(app.buttons["restorePurchasesButton"].waitForExistence(timeout: 5))
    }

    /// AC: A premium user with unlimited habits is not gated when adding more habits.
    func testPremiumUser_AddOpensSelectorNotPaywall() {
        let app = makeApp(["--uitesting-seed-two", "--uitesting-premium"])
        app.launch()

        let addButton = app.buttons["addTaskButton"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5))
        addButton.tap()

        // The paywall must NOT appear for premium users.
        XCTAssertFalse(app.buttons["paywallContinue"].waitForExistence(timeout: 2))
    }
}
