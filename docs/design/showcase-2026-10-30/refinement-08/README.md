# Poster refinement 08: Patterns and the widget

8 November 2026. [Refinement 07](../refinement-07/README.md) updated with the current app. Headline, background, Pingu art and program lockup are unchanged and referenced from refinement 07.

- [Poster PNG](CircleU-Poster-v8.png): 2560 × 1440, from [poster.html](poster.html).
- [LinkedIn version](CircleU-Poster-v8-LinkedIn.png): 2400 × 1254, from [poster-linkedin.html](poster-linkedin.html).

## What changed

- The phones now show Today, Patterns and Practice, on main at PR #76. Sample entries are invented.
- The steps are Write it down. Find your words. See what comes up.
- The pocket card widget sits at the lower left of the phones.

## Sources

Phone screens are exact iPhone 18 Pro Simulator captures, made with `-CircleUSeedShowcase` and `-CircleUSeedPatterns`. `assets/widget.png` is the widget's SwiftUI view rendered by a throwaway test with invented words, not a capture of a Home Screen, so its margins are approximate.

## Rebuilding

Render each page with headless Chrome at a 2× device scale factor: 1280,720 for the poster and 1200,627 for LinkedIn. See [refinement 07](../refinement-07/README.md).

## LinkedIn images

1200 × 627, rendered at 2×, for the owner's post, in posting order. The owner adds their own showcase and training photos.

1. [Poster, LinkedIn version](CircleU-Poster-v8-LinkedIn.png)
2. [Brand origin](../refinement-07/linkedin/CircleU-LinkedIn-brand-slide-1.png), unchanged
3. [Brand system](linkedin/CircleU-LinkedIn-brand-slide-2.png), with current screens
4. [Figma prototype](../refinement-07/linkedin/CircleU-LinkedIn-figma.png), unchanged
5. [The app](linkedin/CircleU-LinkedIn-app.png): Today, Journal, Practice and Patterns
6. [Pocket card and widget](linkedin/CircleU-LinkedIn-pocket-card.png)

`assets/card.png` is the app's own card export with invented words. The Miro board and an Xcode screenshot were dropped by the owner.
