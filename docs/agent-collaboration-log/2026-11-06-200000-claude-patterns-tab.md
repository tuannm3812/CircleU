# Patterns tab

6 November 2026, Claude. The owner asked for one more feature in the navigation bar, chose Patterns from three options, and approved it from real screen captures.

## What changed

- Fourth tab, `GuestPatternsView`, with `GuestPatterns.make`, a pure count of the person's own tags.
- Empty until three entries are tagged. Then a highlight when a context and feeling were chosen together more than once, bars for feelings and contexts, and a 4 weeks / All time switch.
- `-CircleUSeedPatterns`: Debug-only sample entries, used with `-CircleUSeedShowcase` on a reset store.

## Decisions

- This changes the owner-approved three destinations to four, by owner decision on 6 November.
- Counts only. Nothing is inferred from the words, and the screen does not say what a pattern means.
- The tab reuses `GuestIconFeelings`; a dedicated icon waits for the next art batch.

## Not done

Tapping a bar does not yet open those entries.

## Review

Codex's first pass found one blocker, fixed: a failed journal load looked like "no tags". The screen now shows loading and failure with Try again. It also noted the 4 weeks window covered 29 dates; it is now 28.
