import SwiftUI
import XCTest
@testable import Circleu

/// Pocket card (6 November): a card to glance at before the real conversation, made only from
/// what the person wrote or chose.
@MainActor
final class GuestPocketCardTests: XCTestCase {
    func testCardUsesMyWordingMyGoalAndTheToneIChoseInPractice() {
        let model = GuestPocketCardModel(wording: "  Could we agree on the slides before Friday?  ",
                                         goal: " A fair split ", tone: "Firm")
        XCTAssertEqual(model.card.wording, "Could we agree on the slides before Friday?")
        XCTAssertEqual(model.card.want, "A fair split")
        XCTAssertEqual(model.card.tone, .firm)
        XCTAssertEqual(model.card.steadyingLine, GuestPocketCard.steadyingLines[0], "the first line is preselected")
    }

    func testWantIsLeftOffWhenNoGoalWasGiven() {
        let model = GuestPocketCardModel(wording: "Could we talk?", goal: "   ", tone: "Balanced")
        XCTAssertNil(model.card.want, "nothing is invented for me")
        XCTAssertEqual(model.card.tone, .balanced)
        XCTAssertEqual(GuestPocketCardModel(wording: "Hi", goal: "", tone: "Unknown").card.tone, .balanced,
                       "an unknown tone falls back to Balanced")
    }

    func testSixSteadyingLinesEachShortAndDistinct() {
        XCTAssertEqual(GuestPocketCard.steadyingLines.count, 6)
        XCTAssertEqual(Set(GuestPocketCard.steadyingLines).count, 6)
        XCTAssertTrue(GuestPocketCard.steadyingLines.allSatisfy { $0.count <= GuestPocketCard.steadyingLineLimit })
    }

    func testMyOwnLineReplacesTheChoiceAndIsTrimmedAndCapped() {
        let model = GuestPocketCardModel(wording: "Could we talk?", goal: "", tone: "Soft")
        model.choose(GuestPocketCard.steadyingLines[2])
        XCTAssertEqual(model.card.steadyingLine, GuestPocketCard.steadyingLines[2])
        model.ownLine = "   I have thought about this.   "
        XCTAssertEqual(model.card.steadyingLine, "I have thought about this.", "my own line wins when it has words")
        model.ownLine = String(repeating: "a", count: 200)
        XCTAssertEqual(model.card.steadyingLine.count, GuestPocketCard.steadyingLineLimit)
        model.ownLine = "   "
        XCTAssertEqual(model.card.steadyingLine, GuestPocketCard.steadyingLines[2], "clearing it returns to my choice")
    }

    func testEveryToneHasItsOwnBundledPingu() {
        XCTAssertEqual(Set(GuestPocketCard.Tone.allCases.map(\.asset)).count, 3)
        for tone in GuestPocketCard.Tone.allCases { XCTAssertNotNil(UIImage(named: tone.asset), tone.asset) }
    }

    func testCardRendersToAShareableImage() throws {
        let model = GuestPocketCardModel(wording: "Could we agree on the slides before Friday?", goal: "A fair split", tone: "Soft")
        let image = try XCTUnwrap(model.renderImage())
        XCTAssertEqual(image.size.width * image.scale, GuestPocketCard.exportSize.width, accuracy: 1)
        XCTAssertEqual(image.size.height * image.scale, GuestPocketCard.exportSize.height, accuracy: 1)
    }
}
