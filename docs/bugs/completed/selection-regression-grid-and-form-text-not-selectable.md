# Bug: Regression - grid and form text no longer selectable after SelectionArea removal

> **Status: done**

## Resolution

Restored text selection with scoped selection regions instead of the app-wide
wrapper. A new shared widget, lib/widgets/selectable_scope.dart (a thin
SelectionArea wrapper, single kill-switch, crash history documented in-place),
is applied at table/list-body level:

- Baked into both generic shells - lib/widgets/sticky_report_table.dart
  (cycle expenses report) and lib/widgets/section_table.dart (billing
  history) - so anything built on them gets selection for free.
- Added to the bespoke tables: payments desktop/mobile, employee sheet-expense
  desktop/mobile, manager sheet-bucket desktop/mobile, analysis master/pivot,
  and the user-management list.
- Read-only form values: the Profile email (profile_identity_card.dart) is now
  SelectableText; the user-list email is covered by the list scope.
- Sheet Review line grids (desktop Table + mobile compact list) deliberately
  have NO scope: every row is a TableRowInkWell/InkWell that wins the drag, so
  selection can never start there, and a scope disposed by the approve/decline
  provider rebuild triggered a defunct-element markNeedsBuild assertion. The
  sheet's copyable values (name, email, totals, dates, decline comment) are
  selectable in SheetReviewHeaderCard instead.

The app-wide SelectionArea was NOT reintroduced - the framework assertion it
tripped still exists in Flutter 3.44.7 (SelectableRegion.add,
selectable_region.dart). Scoped regions avoid it structurally: overlay panels
mount in the Navigator's Overlay, never inside a content-level scope.

Verified by user in dev (seeded data): Payments report cell selection,
Profile + User Management email copy, sheet header card selection, row taps on
bucket/sheet-review tables, and the company-config dropdown/resize crash
scenario stayed clean. CR pass: clean (see
selection-regression-grid-and-form-text-not-selectable-CR.md). Shipped on
develop as v1.24 (2026-07-25).

## Problem

Text selection is broken again across the app. We previously fixed this
app-wide (docs/bugs/completed/payments-text-not-selectable-cross-app.md) by
wrapping each route in a `SelectionArea` inside `AuthGate`. That wrapper was
later deliberately removed (see the NOTE in `lib/widgets/auth_gate.dart`,
~line 44) because the app-wide `SelectionArea` triggers a Flutter 3.41.2
framework assertion (`SelectableRegion: _selectable == null is not true`)
when provider-driven rebuilds re-insert widgets carrying their own
`SelectionContainer` (dropdown/menu/tooltip overlays).

Removing the wrapper fixed the crash but silently regressed selection
everywhere. Users can no longer copy values they routinely need:

- Report/grid columns - e.g. on the Payments report
  (https://app.xpensedesk.com/manager/payments) none of the column content
  (names, emails, amounts, references) can be selected or copied.
- Form read-only display fields - e.g. copying the user's email address from
  the Profile screen or from the User Management screen. Anything rendered as
  a plain `Text` (the Flutter equivalent of a div/span) is unselectable.

## Reproduce Steps

1. Open the Payments report (/manager/payments).
2. Try to click-drag over any cell value, or right-click -> copy.
   -- Expected: the cell text selects and can be copied.
   -- Actual: nothing selects; the grid behaves like a static image.
3. Open Profile (or User Management) and try to select the email address
   shown in a read-only/display field.
   -- Expected: the value is selectable/copyable.
   -- Actual: it cannot be selected.

## Acceptance Rules

1. Grid/report textual column content must be selectable - all columns, all
   reports (Payments is the reference case).
2. Form read-only display elements (Text-rendered values, the div/span
   equivalents) must be selectable. Editable inputs are already selectable by
   design and need no change.
3. The Flutter 3.41.2 `SelectableRegion` assertion must NOT come back - no
   red error screen on provider-driven rebuilds involving dropdowns, menus,
   or tooltips.

## Suggested Solution Approach

Restore copyability without reintroducing the app-wide `SelectionArea` that
caused the framework assertion. Selection should be scoped to the content
that actually needs it (grid cells, read-only display values), keeping
overlays (dropdowns, menus, tooltips) outside any selection region.

## Suggested Fix

Needs investigation, but the likely direction is scoped selection instead of
the global wrapper:

- Wrap table/grid bodies in a scoped `SelectionArea` (e.g. in
  `lib/widgets/payments/desktop_payments_table.dart` and
  `mobile_payments_table.dart`, and the other report tables), or switch cell
  `Text` widgets to `SelectableText`. Watch for conflicts with row taps /
  link affordances - `SelectableText` inside tappable rows may swallow taps.
- For form display values (Profile, User Management), use `SelectableText`
  for read-only values, or keep the earlier pattern of
  `TextFormField(readOnly: true)` instead of `enabled: false` (see the prior
  fix in `lib/screens/employee_expense_detail_screen.dart`).
- Whatever approach is chosen, verify against the crash scenario documented
  in `lib/widgets/auth_gate.dart` (dropdown/menu/tooltip overlays under a
  SelectionArea during provider-driven rebuilds), and re-check on any future
  Flutter upgrade whether the framework fix allows going app-wide again.
