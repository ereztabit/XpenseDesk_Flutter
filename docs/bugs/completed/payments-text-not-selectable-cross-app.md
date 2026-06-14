# Bug: Screen text is not selectable / copyable (app-wide)

> **Status: done**

## Resolution

Made screen text selectable/copyable app-wide by wrapping each route's content
in a `SelectionArea` inside `AuthGate` (every route renders through it). Placed
per-route (below the Navigator) so it has the Navigator's Overlay as ancestor —
no app-level Overlay hack, and selection never spans stacked routes.

Read-only inputs were a second case: a disabled `TextFormField` can't be
selected at all, so the expense-detail read-only fields now use
`readOnly: !enabled` instead of `enabled: false` — the value stays
selectable/copyable while remaining non-editable (same greyed styling).

Known minor gaps (acceptable): `DropdownMenu` values (category/currency) and
dialog text are not covered — can be made selectable on request.

Files: `lib/widgets/auth_gate.dart`,
`lib/screens/employee_expense_detail_screen.dart`. Verified by user across the
sheet-review and expense-detail screens. CR pass: clean.

## Problem

Text on screen cannot be selected or copied — the UI behaves like an image rather
than an operational document. The user wants to copy/paste values (emails,
amounts, names, references). This is a GENERAL, cross-cutting issue across the
whole app, not just the Payments Report — flagged here but should be discussed
and scoped as an app-wide concern before implementation.

## Reproduce Steps

1. Open any screen with data (e.g. Payments Report).
2. Try to click-drag to select a value, or right-click -> copy.
   -- Expected: text is selectable and copyable.
   -- Actual: nothing selects; the content feels like a static image.

## Suggested Solution Approach

Make text selectable broadly. Two levers in Flutter:
- Wrap large regions (or the whole `MaterialApp` body) in a `SelectionArea` so
  ordinary `Text` widgets become selectable without per-widget changes.
- Use `SelectableText` for specific high-value fields where `SelectionArea`
  interactions (e.g. inside tappable rows/links) conflict.

## Suggested Fix

- DISCUSS FIRST (per user): this is app-wide. Decide between a top-level
  `SelectionArea` (broad, low-effort, but can interfere with taps/links/InkWell)
  vs targeted `SelectableText` on data cells.
- Likely landing spot for a global approach: the app shell / scaffold wrapper
  used by all screens. Verify it does not break row taps, the new name-link
  affordance, drag-to-select vs checkbox selection, and web pointer behavior.
- This is the "depart from the rest" item — treat as its own track, not bundled
  into the Payments fixes.
