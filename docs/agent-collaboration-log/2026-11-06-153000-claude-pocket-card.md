# Pocket card, first version

- Recorded: 2026-11-06 15:30 +11:00; Australia/Sydney.
- Agent / role: Claude Code, implementer.
- Status: on `codex/pocket-card`; suite and Codex results in the PR.
- Source: owner chose the pocket card from four feature ideas, reviewed the clickable prototype (https://claude.ai/artifact/QAjRwdoTqt6ToSP3xzyNGm) and accepted the three recommendations.

## Decisions (owner, 6 November)

Tones match Practice (Soft, Balanced, Firm), not a separate style set. Steadying line: a list of six plus "write my own". Image first; the Home Screen widget is a later, separate piece because it is its own app extension with its own signing.

## Work

- `GuestPocketCard.swift`: the card value (`wording`, optional `want`, `steadyingLine`, `tone`), `GuestPocketCardModel` (tone from Practice, chosen line, own line trimmed and capped at 60), `GuestPocketCardView` drawn at a 360-point design width and scaled, `GuestPocketCardSheet` with a system `ShareLink` for a 1080 × 1350 image rendered by `ImageRenderer`.
- Entry: "Make a pocket card" on a saved Practice message, under Copy and Continue conversation.
- `NSPhotoLibraryAddUsageDescription` added to the three app build configurations so the share sheet's Save Image works; the app itself never reads the photo library.
- Art: existing Pingu assets per tone (calm portrait, thumbs up, practising). Dedicated card illustrations are a later asset batch; no image generation was used.
- Stories: new P10.1–P10.4.

## Verification

`GuestPocketCardTests` (6) with the copy lint pass; `GuestPocketCardUITests` passes and its two captures were inspected (Balanced with the preselected line; Firm with an own line). Full suites and the Codex pass are in the PR. Not verified: the share sheet and Save Image on a physical phone.
