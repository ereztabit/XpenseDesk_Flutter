# Bug: Sheet-monitoring status cards are not equal height

> **Status: done**

## Resolution

Wrapped the desktop card `Row` in `IntrinsicHeight` with
`CrossAxisAlignment.stretch` so all three cards match the tallest one's height
(the `minHeight` floor stays for the all-short case). File:
`lib/widgets/manager_dashboard/sheet_counter_cards.dart`. Verified by user.

## Problem

The three sheet-monitoring boxes on the manager dashboard (returned / approved /
awaiting-approval) render at different heights because their body text differs in
length. They should all be the same height.

## Reproduce Steps

1. Open the manager dashboard.
2. Compare the three status cards in the top row.
   -- Expected: all three cards share the same height.
   -- Actual: heights differ depending on caption length.

## Suggested Fix

- The three cards sit in a `Row`. Wrap them so they stretch to a common height —
  e.g. `Row(crossAxisAlignment: CrossAxisAlignment.stretch)` with each card in an
  `Expanded`, or `IntrinsicHeight` around the row.
- Locate in the manager-dashboard status-section widgets under
  `lib/widgets/manager_dashboard/`.
