# Poster refinement 08: Patterns and the widget

8 November 2026. [Refinement 07](../refinement-07/README.md) updated with the current app. Headline, background, Pingu art and program lockup are unchanged and referenced from refinement 07.

- [Poster PNG](CircleU-Poster-v8.png): 2560 × 1440, from [poster.html](poster.html).
- [LinkedIn version](CircleU-Poster-v8-LinkedIn.png): 2400 × 1254, from [poster-linkedin.html](poster-linkedin.html).

## What changed

- The phones now show Today, Patterns and Practice, on main at PR #74. Sample entries are invented.
- The steps are Write it down. Find your words. See what comes up.
- The pocket card widget sits at the lower left of the phones.

## Sources

Phone screens are exact iPhone 18 Pro Simulator captures, made with `-CircleUSeedShowcase` and `-CircleUSeedPatterns`. `assets/widget.png` is the widget's SwiftUI view rendered by a throwaway test with invented words, not a capture of a Home Screen, so its margins are approximate.

## Rebuilding

Render each page with headless Chrome at a 2× device scale factor: 1280,720 for the poster and 1200,627 for LinkedIn. See [refinement 07](../refinement-07/README.md).
