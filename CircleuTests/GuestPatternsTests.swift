import XCTest
@testable import Circleu

/// Patterns (6 November): counts of the person's own tags, nothing inferred.
final class GuestPatternsTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    private func entry(daysAgo: Int = 0, _ context: GuestEntryContext? = nil, _ feeling: GuestEntryFeeling? = nil) -> GuestJournalEntry {
        let date = now.addingTimeInterval(-Double(daysAgo) * 86_400)
        return GuestJournalEntry(id: UUID(), originalWords: "Words", revision: 1, createdAt: date, updatedAt: date,
                                 context: context, feeling: feeling)
    }

    func testCountsMyTagsMostOftenFirst() {
        let patterns = GuestPatterns.make([entry(.work, .worried), entry(.study, .worried), entry(.study, .calm), entry(.study)],
                                          period: .allTime, now: now)
        XCTAssertEqual(patterns.feelings.map(\.tag), [.worried, .calm])
        XCTAssertEqual(patterns.feelings.map(\.count), [2, 1])
        XCTAssertEqual(patterns.contexts.map(\.tag), [.study, .work])
        XCTAssertEqual(patterns.contexts.map(\.count), [3, 1])
    }

    func testUntaggedEntriesStayOutOfTheCounts() {
        let patterns = GuestPatterns.make([entry(), entry(), entry(.work, nil)], period: .allTime, now: now)
        XCTAssertEqual(patterns.entryCount, 3)
        XCTAssertEqual(patterns.taggedCount, 1)
        XCTAssertEqual(patterns.feelings.count, 0, "no feeling is guessed")
    }

    func testFourWeeksLeavesOutOlderEntries() {
        let all = [entry(daysAgo: 2, .work, .calm), entry(daysAgo: 27, .work, .calm), entry(daysAgo: 28, .work, .calm)]
        XCTAssertEqual(GuestPatterns.make(all, period: .fourWeeks, now: now).entryCount, 2, "28 calendar days, today included")
        XCTAssertEqual(GuestPatterns.make(all, period: .allTime, now: now).entryCount, 3)
    }

    func testTogetherNeedsMoreThanOneEntry() {
        XCTAssertNil(GuestPatterns.make([entry(.work, .calm), entry(.study, .sad)], period: .allTime, now: now).topPair)
        let pair = GuestPatterns.make([entry(.work, .calm), entry(.work, .calm), entry(.study, .sad)], period: .allTime, now: now).topPair
        XCTAssertEqual(pair, GuestPatterns.Pair(context: .work, feeling: .calm, count: 2))
    }

    func testThreeTaggedEntriesAreEnough() {
        XCTAssertFalse(GuestPatterns.make([entry(.work), entry(nil, .calm), entry()], period: .allTime, now: now).hasEnough)
        XCTAssertTrue(GuestPatterns.make([entry(.work), entry(nil, .calm), entry(.study)], period: .allTime, now: now).hasEnough)
    }
}
