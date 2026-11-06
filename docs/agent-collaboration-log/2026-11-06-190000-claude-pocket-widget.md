# Pocket card Home Screen widget

6 November 2026, Claude. Owner choice ("ok move to home screen widge") from the next-steps card.

## What changed

- New target `CircleuPocketWidget` (small and medium, static, no refresh schedule) with its own resized Pingu art and the bundled font. `CircleuShared/` is compiled into both the app and the widget.
- `GuestPocketCardSnapshot` and `GuestPocketCardShelf`: one copy of one card. The widget never opens the journal store.
- Card sheet: "Show on Home Screen". Tapping the widget opens `GuestPocketCardHomeSheet` by `circleu-guest://pocket-card`, with "Take off Home Screen".
- `GuestPracticeViewModel.load()` retires a card whose message is gone; Delete all takes it off and reports a failure.

## Decisions

- **Opt-in, not "the last card made".** The widget shows personal words on the Home Screen, so a card goes there only on a tap. Words use `privacySensitive`.
- **Keychain, not an App Group.** Guest Test is signed with the UTS team's wildcard profile, which has no App Groups, and Xcode has no signed-in account here to create one. The profile does allow keychain groups, so the app and the widget share a keychain item (after first unlock, this device only, out of backups). Trade-off: a keychain item survives deleting the app; Delete all and Take off Home Screen remove it. Move to an App Group when the app has its own release identity.
- **Guest Test only.** A Run Script embeds the widget for GuestReview, because an Embed phase cannot vary by configuration. Debug and Release build the extension unsigned and ship without it; Release has no URL scheme and keeps its entitlements. Checked in the built Release app.
- A card is a snapshot: editing the saved message later does not change it.

## Verification

Full unit and UI suites on the iPhone 18 Pro Simulator, signed device build, Release build without the widget. The extension registered in the simulator after `Config/PocketWidgetInfo.plist` fixed a missing `NSExtension` dictionary, which only an install exposes. Layouts were rendered by a throwaway test, so system margins are approximated.

Not covered: a real widget placed on a Home Screen and a real widget tap, the keychain read from the widget, and locked redaction. The owner checks these on the iPhone.

## Review

Codex's first pass found two blockers, both fixed: card removal depended on the reload after a delete, and a failed removal was silent. Removal now runs straight after the delete commits, with a lasting notice if it fails, and the card sheet stays open with an error. Its second pass found none.
