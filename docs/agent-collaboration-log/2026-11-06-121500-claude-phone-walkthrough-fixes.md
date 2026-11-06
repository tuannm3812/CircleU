# Phone walkthrough fixes: header, questions, tags after saving

- Recorded: 2026-11-06 12:15 +11:00; Australia/Sydney.
- Agent / role: Claude Code, implementer.
- Status: on `codex/phone-walkthrough-fixes`; suite and Codex results in the PR.
- Source: owner's spoken walkthrough of Guest Test (`e8abbfc`) on the iPhone 11 Pro Max, 6 November.

## What the owner saw

The brand mark and name on Today sat in a rounded capsule that looked tappable and did nothing; an unlabelled Pingu avatar sat in the header; three questions felt thin; it was unclear whether context and feeling are chosen or automatic; the magnifying-glass icon on Journal cards was not understood; the three tabs did not feel consistent. The owner also wants a story around Pingu and possibly another view; that is a product decision, put to the owner as options, not built here.

## Work

- `GuestBrandToolbar` (shared): brand mark on the left with no button background (`sharedBackgroundVisibility(.hidden)` on iOS 26+, hit testing off), Settings on the right. Used by Today, Journal and Practice; Journal keeps its calendar toggle.
- The Pingu picker is no longer in Today's header; it stays in Settings, where it already was.
- Six writing questions in two groups (Looking back, Looking ahead). Still optional and never inserted into the words.
- Tags stay the person's own choice (no inference). The Saved card now offers **Tag** beside **Reflect**, opening the picker for the entry just saved.
- Journal cards say "Reflected" instead of showing the reflection icon alone.
- Stories T8.1, T10.2, T10.3, S4.2–S4.4, J7.6 updated; S4.3 retired with the header picker.

## Verification

Focused unit tests and the full suites are recorded in the PR. Simulator results; the owner's phone gets the build after merge.
