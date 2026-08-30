import XCTest

/// Drives the app through the App Store preview walkthrough while the host
/// records the simulator screen (see `scripts/record-app-preview.sh`).
///
/// This is a recording script rather than a test: it asserts only enough to fail
/// fast if a screen does not appear, because a silent mis-navigation would
/// otherwise produce a video of the wrong thing. It is skipped unless the host
/// sets `RECORD_APP_PREVIEW`, so an ordinary test run is unaffected.
///
/// Each segment the final cut uses is bracketed by a `PREVIEW_MARK` line carrying
/// a wall-clock timestamp. The host subtracts the moment recording started to turn
/// those into cut points, so the navigation between segments never reaches the cut.
final class AppPreviewRecording: XCTestCase {
    private var app: XCUIApplication!

    /// Long enough for the eye to land on a screen and read it, short enough that
    /// five segments plus title cards still fit inside Apple's 30-second ceiling.
    private let beat: TimeInterval = 1.0

    override func setUpWithError() throws {
        try XCTSkipUnless(
            ProcessInfo.processInfo.environment["RECORD_APP_PREVIEW"] == "1",
            "Recording script — set RECORD_APP_PREVIEW=1 to run it."
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

    func testRecordAppPreviewWalkthrough() throws {
        let dashboard = habitCircle(titled: "Meditate")
        XCTAssertTrue(dashboard.waitForExistence(timeout: 20), "Dashboard did not appear")
        // The strength rings and stage badges are computed on first layout; let them
        // land before the camera is pointed at them.
        wait(2.0)

        recordDashboard()
        recordTapAndHoldCompletion()
        recordHabitSummary()
        recordHabitStats()
        recordHabitConfiguration()

        wait(1.0)
    }

    // MARK: - Segments

    /// The full grid: five habits, five colours, five stages.
    private func recordDashboard() {
        mark("dashboard_in")
        wait(2.6)
        mark("dashboard_out")
    }

    /// Tap and hold on "Gym", the habit the seed deliberately leaves open today.
    private func recordTapAndHoldCompletion() {
        let gym = habitCircle(titled: "Gym")
        XCTAssertTrue(gym.waitForExistence(timeout: 5), "Gym habit is missing")

        mark("complete_in")
        wait(0.5)
        // The hold threshold is 1.4s; the extra margin covers gesture dispatch so
        // the ring is never caught mid-retraction.
        gym.press(forDuration: 1.9)
        // Holds through the completion burst and its settle.
        wait(1.7)
        mark("complete_out")
    }

    /// Single tap opens the summary sheet: hero strength ring, stage, consistency grid.
    private func recordHabitSummary() {
        habitCircle(titled: "Meditate").tap()
        let ring = app.descendants(matching: .any)["habitSummary_strengthRing"]
        XCTAssertTrue(ring.waitForExistence(timeout: 5), "Summary sheet did not open")
        wait(0.6)

        mark("summary_in")
        wait(3.2)
        mark("summary_out")
    }

    /// Stats: completion counts, percentage, and the trend chart.
    private func recordHabitStats() {
        let statsButton = app.buttons["habitSummary_statsButton"]
        XCTAssertTrue(statsButton.waitForExistence(timeout: 5), "Stats action is missing")
        statsButton.tap()

        XCTAssertTrue(
            app.navigationBars["Stats"].waitForExistence(timeout: 8),
            "Stats screen did not open"
        )
        wait(1.2)

        // Held rather than scrubbed. Dragging across the chart to raise its
        // callout does nothing here: this screen's SwiftUI gestures — the chart
        // selection, the form controls — ignore XCUITest's synthetic events,
        // even though buttons on the same screens respond normally.
        mark("stats_in")
        wait(3.4)
        mark("stats_out")

        app.buttons["Close"].firstMatch.tap()
        wait(1.0)
    }

    /// Configuration: goal, schedule, reminder, and the colour palette.
    private func recordHabitConfiguration() {
        habitCircle(titled: "Side project").tap()
        let editButton = app.buttons["habitSummary_editButton"]
        XCTAssertTrue(editButton.waitForExistence(timeout: 5), "Edit action is missing")
        editButton.tap()

        XCTAssertTrue(
            app.navigationBars["Edit Task"].waitForExistence(timeout: 8),
            "Task configuration did not open"
        )
        wait(1.2)

        mark("config_in")
        wait(1.7)
        slowScrollDown()
        wait(1.9)
        mark("config_out")
    }

    // MARK: - Gestures

    /// A slow, even drag rather than `swipeUp()`, which flings the form past the
    /// sections the video is meant to show.
    private func slowScrollDown() {
        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.74))
        let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.34))
        start.press(forDuration: 0.1, thenDragTo: end, withVelocity: 260, thenHoldForDuration: 0.3)
    }


    // MARK: - Helpers

    private func habitCircle(titled title: String) -> XCUIElement {
        app.buttons
            .matching(NSPredicate(
                format: "identifier BEGINSWITH 'taskCircle_' AND label CONTAINS %@", title
            ))
            .firstMatch
    }

    private func wait(_ interval: TimeInterval) {
        Thread.sleep(forTimeInterval: interval)
    }

    /// Emits a cut point. Wall-clock rather than elapsed test time, so the host can
    /// line it up against the moment it started the screen recording.
    private func mark(_ name: String) {
        print("PREVIEW_MARK \(name) \(Date().timeIntervalSince1970)")
    }
}
