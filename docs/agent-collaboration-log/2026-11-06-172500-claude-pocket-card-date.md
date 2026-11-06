# Pocket card: date made

6 November 2026, Claude. Owner request after trying the card on the iPhone: "should we have date for that also".

## What changed

- `GuestPocketCard` has `made` (a `Date`) and `madeLabel` (day and short month in the person's locale). The model fixes the date when the sheet opens.
- The card shows it beside the mark: "CircleU · 6 Nov". VoiceOver reads "Made 6 Nov." at the end of the card summary.
- Story P10.5 and unit test `testCardShowsTheDayItWasMade`.

## Decisions

The date is the day the card was made, set automatically. A date the person picks ("for Friday") was considered and left out: it adds a control for little gain, and can follow if the owner asks.

## Verification

Pocket card unit tests, the copy lint and the pocket card UI journey on the iPhone 18 Pro Simulator; full suites before merge. Owner had confirmed the previous build's share and Save Image on the phone (two saved cards sent back, long text fitted).
