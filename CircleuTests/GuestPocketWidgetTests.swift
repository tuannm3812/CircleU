import XCTest
@testable import Circleu

/// Home Screen widget (6 November): one card the person chose to put there, and it leaves when
/// its message or all data is deleted.
@MainActor
final class GuestPocketWidgetTests: XCTestCase {
    private var folder: URL!
    private var shelf: GuestPocketCardShelf!

    override func setUp() async throws {
        folder = FileManager.default.temporaryDirectory.appendingPathComponent("PocketWidget-\(UUID())")
        shelf = .file(at: folder.appendingPathComponent("Shelf/PocketCard.json"))
    }

    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: folder)
    }

    private func session() async throws -> (GuestJournalViewModel, GuestPracticeViewModel) {
        let (journal, practice) = try await GuestComposition.local(at: GuestJournalLocation(
            directory: folder.appendingPathComponent("Journal"), setupMarker: folder.appendingPathComponent("Setup.json"))).makeSession()
        practice.pocketCardShelf = shelf
        return (journal, practice)
    }

    private func card(_ id: UUID?) -> GuestPocketCardSnapshot {
        GuestPocketCardSnapshot(wording: "Could we talk?", want: nil, steadyingLine: "Slow is fine.", tone: "Firm",
                                made: Date(timeIntervalSince1970: 1_800_000_000), messageID: id)
    }

    func testNothingReachesTheShelfUntilIAsk() {
        let model = GuestPocketCardModel(wording: "Could we talk?", goal: "", tone: "Soft", shelf: shelf)
        XCTAssertNil(shelf.load(), "making a card does not put it on the Home Screen")
        XCTAssertFalse(model.isOnHomeScreen)
    }

    func testShowOnHomeScreenKeepsExactlyTheCardIMade() throws {
        let id = UUID()
        let model = GuestPocketCardModel(wording: "Could we talk?", goal: "A fair split", tone: "Firm", messageID: id, shelf: shelf)
        model.showOnHomeScreen()
        let saved = try XCTUnwrap(shelf.load())
        XCTAssertEqual(saved, model.card.snapshot(messageID: id))
        XCTAssertEqual(GuestPocketCard(snapshot: saved), model.card, "tapping the widget opens the same card")
        XCTAssertTrue(model.isOnHomeScreen)
    }

    func testChangingTheCardOffersToShowItAgain() {
        let model = GuestPocketCardModel(wording: "Could we talk?", goal: "", tone: "Soft", shelf: shelf)
        model.showOnHomeScreen()
        model.tone = .firm
        XCTAssertFalse(model.isOnHomeScreen, "the widget still shows the earlier version")
    }

    func testAFailedWriteSaysSo() {
        let failing = GuestPocketCardShelf(read: { nil }, write: { _ in throw CocoaError(.fileWriteUnknown) }, remove: { true })
        let model = GuestPocketCardModel(wording: "Could we talk?", goal: "", tone: "Soft", shelf: failing)
        model.showOnHomeScreen()
        XCTAssertTrue(model.homeScreenFailed)
        XCTAssertFalse(model.isOnHomeScreen)
    }

    func testTakeOffLeavesNothingBehind() throws {
        try shelf.show(card(nil))
        XCTAssertTrue(shelf.takeOff())
        XCTAssertNil(shelf.load())
        XCTAssertTrue(shelf.takeOff(), "already gone is fine")
    }

    func testDeletingTheMessageTakesItsCardOff() async throws {
        let (journal, practice) = try await session()
        let kept = try await practice.store.createPractice(situation: "", goal: "", wording: "Kept", sourceEntryID: nil)
        let gone = try await practice.store.createPractice(situation: "", goal: "", wording: "Gone", sourceEntryID: nil)
        await practice.load()
        try shelf.show(card(kept.id))
        let other = await practice.deleteMessage(id: gone.id, journal: journal)
        XCTAssertNil(other)
        XCTAssertNotNil(shelf.load(), "another message going leaves the card")
        let deleted = await practice.deleteMessage(id: kept.id, journal: journal)
        XCTAssertNil(deleted)
        XCTAssertNil(shelf.load(), "deleted words do not stay on the Home Screen")
    }

    func testDeletingAnEntryWithItsMessagesTakesTheCardOff() async throws {
        let (journal, practice) = try await session()
        journal.draft = "An entry"
        _ = await journal.saveDraft()
        let entry = try XCTUnwrap(journal.entries.first)
        let message = try await practice.store.createPractice(situation: "", goal: "", wording: "Linked", sourceEntryID: entry.id)
        await practice.load()
        try shelf.show(card(message.id))
        let result = await practice.deleteEntry(id: entry.id, linkedPractice: .deleteBoth, journal: journal)
        XCTAssertNil(result)
        XCTAssertNil(shelf.load())
    }

    func testACardThatWillNotComeOffAfterADeleteSaysSo() async throws {
        let (journal, practice) = try await session()
        let message = try await practice.store.createPractice(situation: "", goal: "", wording: "Saved", sourceEntryID: nil)
        await practice.load()
        let stuck = card(message.id)
        let data = try JSONEncoder().encode(stuck)
        practice.pocketCardShelf = GuestPocketCardShelf(read: { data }, write: { _ in }, remove: { false })
        let result = await practice.deleteMessage(id: message.id, journal: journal)
        XCTAssertNil(result)
        XCTAssertTrue(journal.notices.contains(GuestPracticeViewModel.pocketCardLeftMessage))
    }

    func testDeleteAllTakesTheCardOff() async throws {
        let (journal, practice) = try await session()
        let message = try await practice.store.createPractice(situation: "", goal: "", wording: "Saved", sourceEntryID: nil)
        await practice.load()
        try shelf.show(card(message.id))
        let settings = GuestSettingsViewModel(journal: journal, practice: practice)
        await settings.deleteAll()
        XCTAssertNil(shelf.load())
        XCTAssertEqual(settings.message, GuestSettingsViewModel.deletedMessage)
    }

    func testACardThatCannotBeRemovedIsReported() async throws {
        let (journal, practice) = try await session()
        practice.pocketCardShelf = GuestPocketCardShelf(read: { nil }, write: { _ in }, remove: { false })
        let settings = GuestSettingsViewModel(journal: journal, practice: practice)
        await settings.deleteAll()
        XCTAssertEqual(settings.message, GuestSettingsViewModel.deletedExportPendingMessage)
    }
}
