import XCTest

/// Patterns tab: a quiet empty state, then counts of the person's own tags.
final class GuestPatternsUITests: XCTestCase {
    func shot(_ app: XCUIApplication, _ name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot()); shot.name = name; shot.lifetime = .keepAlways; add(shot)
    }
    func has(_ app: XCUIApplication, _ text: String, _ timeout: TimeInterval = 5) -> Bool {
        app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", text)).firstMatch.waitForExistence(timeout: timeout)
    }

    func testEmptyUntilAFewEntriesAreTagged() throws {
        continueAfterFailure = false
        let app = launchGuest(fresh: true)
        app.tabBars.buttons["Patterns"].tap()
        XCTAssertTrue(has(app, "Tag a few entries"))
        shot(app, "patterns-empty")
    }

    func testCountsAndPeriods() throws {
        continueAfterFailure = false
        let app = launchGuest(fresh: true, ["-CircleUSeedShowcase", "YES", "-CircleUSeedPatterns", "YES"])
        app.tabBars.buttons["Patterns"].tap()
        XCTAssertTrue(has(app, "Study and Worried came up together", 10))
        shot(app, "patterns-top")
        app.swipeUp()
        XCTAssertTrue(has(app, "Contexts"))
        shot(app, "patterns-scrolled")
        app.swipeDown()
        app.buttons["All time"].tap()
        XCTAssertTrue(has(app, "Study and Worried"), "the same counts, all time")
    }

    func testTappingACountShowsThoseEntries() throws {
        continueAfterFailure = false
        let app = launchGuest(fresh: true, ["-CircleUSeedShowcase", "YES", "-CircleUSeedPatterns", "YES"])
        app.tabBars.buttons["Patterns"].tap()
        let worried = app.buttons["Worried, 4"]
        XCTAssertTrue(worried.waitForExistence(timeout: 10))
        worried.tap()
        XCTAssertTrue(app.navigationBars["Worried"].waitForExistence(timeout: 5))
        XCTAssertTrue(has(app, "Group chat about the slides went quiet again."))
        XCTAssertFalse(app.staticTexts["Coffee with Sam helped a lot."].exists, "only the Worried entries")
        shot(app, "patterns-worried")
        app.navigationBars.buttons.element(boundBy: 0).tap()
        let pair = app.buttons.containing(NSPredicate(format: "label CONTAINS %@", "Study and Worried")).firstMatch
        XCTAssertTrue(pair.waitForExistence(timeout: 5))
        pair.tap()
        XCTAssertTrue(app.navigationBars["Study and Worried"].waitForExistence(timeout: 5))
    }
}
