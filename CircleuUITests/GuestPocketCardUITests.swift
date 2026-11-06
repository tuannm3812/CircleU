import XCTest

/// Pocket card: made from a saved Practice message, with a tone, a steadying line and a share action.
final class GuestPocketCardUITests: XCTestCase {
    func shot(_ app: XCUIApplication, _ name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot()); shot.name = name; shot.lifetime = .keepAlways; add(shot)
    }

    func testMakeAPocketCardFromASavedMessage() throws {
        continueAfterFailure = false
        let app = launchGuest(fresh: true, ["-CircleUGuidedSuggestions", "YES"])
        app.tabBars.buttons["Practice"].tap()
        XCTAssertTrue(app.buttons["Practice a message"].waitForExistence(timeout: 10))
        app.buttons["Practice a message"].tap()
        app.buttons["Help me get started"].tap()
        let intent = app.textFields["Your intent"]
        XCTAssertTrue(intent.waitForExistence(timeout: 5))
        intent.tap(); intent.typeText("A fair split")
        app.buttons["Continue"].tap()
        let wording = app.textViews["Your wording"]
        XCTAssertTrue(wording.waitForExistence(timeout: 5))
        wording.tap(); wording.typeText("Could we agree on the slides before Friday?")
        app.buttons["Save without feedback"].tap()
        let make = app.buttons["Make a pocket card"]
        XCTAssertTrue(make.waitForExistence(timeout: 10), "offered on the saved message")
        for _ in 0..<4 where !make.isHittable { app.swipeUp() }
        make.tap()

        XCTAssertTrue(app.navigationBars["Pocket card"].waitForExistence(timeout: 5))
        let card = app.otherElements.matching(NSPredicate(format: "label BEGINSWITH %@", "Pocket card.")).firstMatch
        XCTAssertTrue(card.waitForExistence(timeout: 5))
        XCTAssertTrue(card.label.contains("Could we agree on the slides before Friday?"), "my wording")
        XCTAssertTrue(card.label.contains("What I want: A fair split"), "my goal")
        XCTAssertTrue(card.label.contains("One breath, then the first sentence."), "the first line is preselected")
        shot(app, "pocket-1-balanced")

        app.buttons["Firm card"].tap()
        let line = app.buttons["It’s okay to pause."]
        for _ in 0..<4 where !line.isHittable { app.swipeUp() }
        line.tap()
        XCTAssertTrue(card.label.contains("It’s okay to pause."))
        let own = app.textFields["Write my own"]
        for _ in 0..<4 where !own.isHittable { app.swipeUp() }
        own.tap(); own.typeText("I have thought about this.")
        XCTAssertTrue(card.label.contains("I have thought about this."), "my own line wins")
        XCTAssertTrue(app.buttons["Share or save"].exists, "one action to share or save the image")
        app.swipeDown(); app.swipeDown()
        shot(app, "pocket-2-firm-own-line")
        app.buttons["Close"].tap()
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "Saved · not sent")).firstMatch.waitForExistence(timeout: 5),
                      "back on the saved message, unchanged")
    }
}
