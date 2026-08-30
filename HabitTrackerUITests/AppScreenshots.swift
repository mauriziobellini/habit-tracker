import XCTest

/// Navigates to each screen the App Store listing shows and holds there, while
/// the host captures the simulator (see `scripts/capture-app-screenshots.sh`).
///
/// A companion to `AppPreviewRecording`: same demo seed, same dark-mode
/// simulator, but it stops on four screens instead of playing through them.
/// Skipped unless the host sets `CAPTURE_APP_SCREENSHOTS`.
final class AppScreenshots: XCTestCase {
    private var app: XCUIApplication!

    /// How long each screen stays up. The host polls the simulator throughout
    /// and picks the frame that falls inside this window, so it only has to be
    /// comfortably longer than one capture.
    private let hold: TimeInterval = 3.0

    override func setUpWithError() throws {
        try XCTSkipUnless(
            ProcessInfo.processInfo.environment["CAPTURE_APP_SCREENSHOTS"] == "1",
            "Capture script — set CAPTURE_APP_SCREENSHOTS=1 to run it."
        )
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = [
            "--uitesting",
            "--uitesting-premium",
            "--uitesting-demo-video",
        ]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    func testCaptureStoreScreenshots() throws {
        let meditate = habitCircle(titled: "Meditate")
        XCTAssertTrue(meditate.waitForExistence(timeout: 20), "Dashboard did not appear")
        // The strength rings and stage badges are computed on first layout.
        wait(2.0)

        capture("dashboard")

        meditate.tap()
        let ring = app.descendants(matching: .any)["habitSummary_strengthRing"]
        XCTAssertTrue(ring.waitForExistence(timeout: 5), "Summary sheet did not open")
        wait(0.8)
        capture("habit-details")

        let statsButton = app.buttons["habitSummary_statsButton"]
        XCTAssertTrue(statsButton.waitForExistence(timeout: 5), "Stats action is missing")
        statsButton.tap()
        XCTAssertTrue(
            app.navigationBars["Stats"].waitForExistence(timeout: 8),
            "Stats screen did not open"
        )
        wait(1.2)
        capture("stats")

        app.buttons["Close"].firstMatch.tap()
        wait(1.0)

        // A different habit for the configuration shot, so the set is not four
        // screens of the same purple.
        habitCircle(titled: "Side project").tap()
        let editButton = app.buttons["habitSummary_editButton"]
        XCTAssertTrue(editButton.waitForExistence(timeout: 5), "Edit action is missing")
        editButton.tap()
        XCTAssertTrue(
            app.navigationBars["Edit Task"].waitForExistence(timeout: 8),
            "Task configuration did not open"
        )
        wait(1.2)
        capture("habit-configuration")
    }

    // MARK: - Helpers

    private func habitCircle(titled title: String) -> XCUIElement {
        app.buttons
            .matching(NSPredicate(
                format: "identifier BEGINSWITH 'taskCircle_' AND label CONTAINS %@", title
            ))
            .firstMatch
    }

    /// Announces that the named screen is up, then holds it there.
    private func capture(_ name: String) {
        print("SCREENSHOT_MARK \(name) \(Date().timeIntervalSince1970)")
        wait(hold)
    }

    private func wait(_ interval: TimeInterval) {
        Thread.sleep(forTimeInterval: interval)
    }
}
