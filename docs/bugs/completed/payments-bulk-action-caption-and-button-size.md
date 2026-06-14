# Bug: Bulk-action box needs a caption and larger buttons

> **Status: done**

## Resolution

The bulk-action eyebrow now reads "פעולה מרוכזת" (he value of `bulkActionLabel`)
and the Export / Mark-as-Processed buttons are full-size (dropped `dense`) to
match the filter card's Search button. Files: `lib/l10n/app_he.arb`,
`lib/widgets/payments/desktop_bulk_action_bar.dart`. Verified by user.

## Problem

The bulk-action box (shown when rows are selected) lacks a clear caption and its
buttons are undersized. It should have the caption "פעולה מרוכזת" ("bulk
action"), and its buttons should be enlarged to match the size of the Search
button in the filter card.

## Reproduce Steps

1. Open the Payments Report and select one or more awaiting sheets.
2. Observe the bulk-action box.
   -- Expected: a "פעולה מרוכזת" caption; Export/Mark-processed buttons sized to
      match the filter card's Search button.
   -- Actual: no clear caption; buttons are smaller than the Search button.

## Suggested Solution Approach

Add the caption and align the bulk buttons' height/padding to the Search button.

## Suggested Fix

- `lib/widgets/payments/desktop_bulk_action_bar.dart` and
  `lib/widgets/payments/mobile_bulk_action_card.dart`: add a "פעולה מרוכזת"
  caption (new ARB key in both files).
- Match button sizing to the Search button in
  `lib/widgets/payments/payments_filter_card.dart` — likely drop `dense: true`
  on the `AppButton`s or align their padding/height to the Search action.
- Keep the icon-column-vs-Expanded responsiveness rule in mind at narrow widths.
