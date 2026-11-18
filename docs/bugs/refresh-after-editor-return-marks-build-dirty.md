# Bug: Returning from the expense editor logs "setState() or markNeedsBuild() called during build"

> **Status: new**

Found in FS-1013 (PC-2) manual QA, 2026-11-18. Fixed there for the budget
review list only; the same pattern remains on two other screens.

## Problem

A screen that opens the expense editor and refreshes its data when the editor
closes logs a Riverpod error to the console every time ("setState() or
markNeedsBuild() called during build", raised from `_updateTickerMode`). The
page itself shows the right data, so users see nothing, but the console noise
hides real errors and the rebuild order is fragile.

## Reproduce Steps

1. As a manager, open a submitted Monthly sheet in Sheet Review.
2. Tap a line - the expense editor opens.
3. Press Back.
   -- Expected: the sheet refreshes, the console is clean.
   -- Actual (expected per code review, not yet seen in QA): the console logs
      the Riverpod "called during build" error.
4. Same on My expenses (and on a budget, as the holder): open an expense, Back.

## Suggested Solution Approach

Refresh after the returning page has rebuilt, not during it.

## Suggested Fix

- While the editor covers a page, Riverpod 3 pauses the page's watchers
  (TickerMode). `pushNamed(...).then((_) => invalidate...)` invalidates them
  before the next frame; they resume during the return's build and mark the
  page dirty mid-build.
- Call sites: `lib/screens/sheet_review_screen.dart:164-167`
  (`_openLineDetail`) and `lib/widgets/employee_dashboard/sheet_expenses_area.dart:68`
  (`_editOrView`). The budget review list
  (`lib/widgets/budgets/budget_review_lines_section.dart`) already defers with
  `WidgetsBinding.instance.addPostFrameCallback`.
- Add one shared helper (e.g. `refreshAfterReturn(VoidCallback)` that runs the
  callback after the next frame) and use it at all three call sites.
