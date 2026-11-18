# Bug: Holder has no way back from an approved budget's page

> **Status: new**

Found in the PC-1 (FS-1012) production sanity check, 2026-11-18. Fix in PC-2 (FS-1013).

## Problem

Once a budget is approved it leaves the holder's navigation (by design:
approved budgets will only be reachable from History, not built yet). If the
holder still lands on that budget's page - from a saved link, a bookmark, the
browser history, or a page that was open when the manager approved it - the
page has no "Back" link and no switcher bar. The only way out is the logo in
the header. Every other page in the app gives a visible way back.

## Reproduce Steps

Production, demo company 17884, Hebrew, mobile width (375px); the same on
desktop and in English.

1. As the manager, create a budget and pick an employee as the holder.
2. Sign in as that employee (the holder). The switcher bar shows "Monthly" and
   "Budgets"; tap "Budgets" - it opens the budget page,
   `/budgets/<budgetId>`. Copy that URL.
3. Add one expense and tap "Submit for approval".
4. Sign in as the manager, open Budgets -> Awaiting approval -> the budget,
   and approve it.
5. Sign in again as the employee.
   -- The home screen now has no switcher bar (Monthly is the only type left) -
      correct.
6. Open the URL copied in step 2.
   -- Expected: the read-only approved budget, with a "Back" link to the
      employee's home screen (My expenses).
   -- Actual: the read-only approved budget with no "Back" link and no switcher
      bar. The only exit is the header logo.

Reproduced on prod 2026-11-18 with budget #1001 "Prod sanity PC-1".

## Suggested Solution Approach

The budget page always shows a way back. For a manager it is the Budgets list
(as today); for the holder, when the budget has no entry in the navigation
(approved, or the bar is hidden), it goes to the holder's home screen.

## Suggested Fix

- `lib/screens/budget_page_screen.dart` (around line 118) shows the "Back"
  button only when `!budgetIsHeldBy(b, me)`, and it always targets
  `AppRoutes.budgetsList` (a manager-only list). The holder relies on the
  switcher bar, which is gone once the budget is approved.
- Show the button for the holder too when the budget is approved (or whenever
  the sheet-nav has no page for this route - `sheetNavPageFor(...) == null`),
  targeting the holder's dashboard (`/user/dashboard`, or `/dashboard` for a
  manager-holder) instead of `budgetsList`. Put the target choice in
  `lib/utils/budget_utils.dart` and unit-test it.
