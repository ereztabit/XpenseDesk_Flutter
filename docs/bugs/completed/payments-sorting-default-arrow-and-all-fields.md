# Bug: Sorting — default to employee name asc, show arrow, hint on hover, sort all fields

> **Status: done**

## Resolution

Default sort is now employee-name ascending with the arrow shown on load and
re-applied on every Search. Added `govId` and `email` to `PaymentsSortField`
(+ `_compare`) and made their header cells sortable, so every column sorts.
Sortable headers show a "Sort by this column" tooltip (`sortColumnTooltip`) +
pointer cursor. Files: `lib/utils/payments_utils.dart`,
`lib/widgets/payments/payments_header_cell.dart`,
`lib/widgets/payments/desktop_payments_header_row.dart`,
`lib/screens/payments_report_screen.dart`, ARB en/he. Verified by user.

## Problem

Table sorting is incomplete and undiscoverable:
- It should default to sorting by employee name ascending, with the sort arrow
  shown on that column from the start.
- Hovering a header should hint that the column is sortable.
- All columns should be sortable (currently only a subset).

## Reproduce Steps

1. Open the Payments Report.
   -- Expected: rows already sorted by employee name asc, arrow visible on that
      header; hovering any header shows a sortable hint; every column sorts.
   -- Actual: no default sort/arrow; no hover hint; not all fields are sortable.

## Suggested Solution Approach

Initialize sort state to employee-name ascending and render the arrow. Add a
tooltip/hover affordance on header cells. Extend the sortable field set to cover
all columns.

## Suggested Fix

- Default sort: in `lib/screens/payments_report_screen.dart`, initialize
  `_sortField` to the employee-name field and `_sortAscending = true` (instead of
  null). Ensure `PaymentsSortUtils.sort` and the header arrow reflect it.
- Hover hint: in `lib/widgets/payments/payments_header_cell.dart`, wrap sortable
  headers in a `Tooltip` ("sort by ...") and use a pointer cursor on web.
- All fields: extend `PaymentsSortField` in `lib/utils/payments_utils.dart` and
  the `_compare` logic to every column; wire each header to `onSort`. Keep the
  null-last behavior already in `_nullLastFor`.
- Add any new ARB keys for tooltips to both ARB files.
