# Patterns visual pass

8 November 2026, Claude. The owner confirmed the widget works on the iPhone and asked to improve the Patterns visuals and plan next steps.

## What changed

- Three stat tiles: Entries, Days written and Tagged.
- "Week by week": one bar per 7-day stretch over the last 4 weeks, in one hue, with counts and dates.
- Chevrons on every tappable row and on the highlight.
- An entries line at the top of the drill-down list, for example "4 entries · last 4 weeks".

## Review

Codex found one blocker, fixed: a future-dated entry counted in the totals but in no bar. The 4-week period now ends at tomorrow's midnight everywhere. Following its suggestion, the last bar is labelled "Last 7 days", and VoiceOver says "entries".

## Not done

No explicit DST or midnight-boundary tests.
