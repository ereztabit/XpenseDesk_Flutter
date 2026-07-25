# Bug: Manager Dashboard missing the top analysis widget

> **Status: new**

## Problem

The manager dashboard used to show a spend analysis widget at the top of the
page. It is gone now. The manager lands on the dashboard and sees only the sheet
buckets (Pending review, Returned to employee, Approved) with no spend overview /
analysis summary above them.

## Reproduce Steps

1. Log in as a manager.
2. Land on the Manager Dashboard.
   -- Expected: an analysis / spend overview widget at the top of the page.
   -- Actual: the top of the page shows only a placeholder; no analysis widget is
      rendered.

## Suggested Solution Approach

Restore a real spend analysis summary at the top of the manager dashboard, above
the sheet bucket cards.

## Suggested Fix

Needs a product decision on exactly what the top widget should show before
implementing.

Context from the code:

- The sheet-centric rewrite (commit `5d75fa7` — "manager dashboard: sheet-centric
  rewrite end-to-end") replaced the top-of-page content with a non-functional
  `SpendOverviewPlaceholder`. See
  [manager_dashboard_screen.dart:78](lib/screens/manager_dashboard_screen.dart#L78)
  and `lib/widgets/manager_dashboard/spend_overview_placeholder.dart`.
- The full analysis widget suite still exists under `lib/widgets/analysis/`
  (master/detail cards, bar charts, pivot/master tables, filter card) but is now
  only wired into the separate `lib/screens/expenses_analysis_screen.dart`, not
  the manager dashboard.
- A spend-overview spec already exists at `docs/backlog/spend-overview-spec.md`
  — likely the intended replacement for the placeholder. Confirm whether the fix
  is to ship that spec, or to re-embed the existing analysis widget at the top of
  the dashboard.
