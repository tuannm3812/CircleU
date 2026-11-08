# Patterns icon and accessibility pass

8 November 2026, Claude. Owner go-ahead on the proposed next steps.

## What changed

- `GuestIconPatterns`: a tab icon of three rising bars and a sun-orange dot, drawn as SVG in the existing icon colours and rendered by headless Chrome. No image model was used.
- At accessibility text sizes the three stat tiles and the weekly bars become rows, because their words were cut off ("Entr…", "12…"). A long tag name no longer breaks mid-word.

## Accessibility audit

`performAccessibilityAudit` and captures at Accessibility XXXL covered Today, Patterns, the entries list and an open entry, through a throwaway test.

Left as they are, by my judgement: contrast reports on elements behind the blurred tab bar and on the disabled Save button, and "Text clipped" on an accessibility label that deliberately holds more than the visible time.

Not covered: VoiceOver used by a person, and Practice steps and Settings at the largest size.
