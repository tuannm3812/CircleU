# Patterns: tap a count to see its entries

8 November 2026, Claude. Owner choice: "ok work with pattern".

## What changed

- Each feeling and context row, and the highlight card, opens `GuestPatternEntriesView`. That view lists the entries behind the count for the same period, newest first, dated like Journal, and they can be opened and retagged there.
- `GuestPatterns.inPeriod`, `entries(_:for:)`, `Filter` and `Route`, so the list always uses the same rule as the count.
- `GuestJournalRow` is no longer private, so Journal and Patterns share one row.

## Verification

Unit `testATapShowsExactlyTheEntriesBehindTheCount` and UI `testTappingACountShowsThoseEntries`, plus the full suites before merge.

## Review

Codex's first pass found one blocker, fixed: a failed reload after retagging showed "No entries left here." The list now shows loading and failure with Try again.
Its second pass found that Delete all left an entry open in Patterns; the Patterns stack now resets on Delete all, as Journal does.
