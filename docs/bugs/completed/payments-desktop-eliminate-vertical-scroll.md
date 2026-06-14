# Bug: Desktop payments table has an unwanted inner vertical scroll

> **Status: done**

## Resolution

Desktop now flows with the page — the screen wraps the desktop view in a
`SingleChildScrollView`, the view's root `Column` is `mainAxisSize.min` and the
table is no longer in an `Expanded`. `DesktopPaymentsTable` was rewritten to
size to its rows (header + rows in one column) with only horizontal scroll; it
no longer uses the shared `StickyReportTable` / a vertical controller. Mobile
keeps its internal scroll. Files:
`lib/screens/payments_report_screen.dart`,
`lib/widgets/payments/desktop_payments_view.dart`,
`lib/widgets/payments/desktop_payments_table.dart`. Verified by user.

## Problem

On desktop there is no reason for the payments table to have its own vertical
scrollbar. The inner vertical scroll should be eliminated so the content flows
with the page.

## Reproduce Steps

1. Open the Payments Report on desktop.
2. Observe the table region.
   -- Expected: no separate inner vertical scrollbar on the table.
   -- Actual: the table body scrolls vertically inside its own region.

## Suggested Solution Approach

Remove the table's internal vertical scroll on desktop; let the rows lay out
naturally within the page (the D17 "only the table body scrolls" decision is
being revised for desktop).

## Suggested Fix

- `lib/widgets/payments/desktop_payments_table.dart` /
  `lib/widgets/payments/desktop_payments_view.dart`: the table is currently
  wrapped so its body scrolls (uses `verticalScrollController`). Drop the inner
  vertical scrollable on desktop so the table sizes to its rows.
- Re-check the pinned-header behavior: if the header was sticky because of the
  inner scroll, confirm the header still reads correctly once the inner scroll
  is gone.
- The 100-row cap + paging-overflow notice already bounds the row count, so an
  unbounded list is not a concern.
