# Bug: No "Back" on the budget page for a budget you hold yourself

> **Status: new**

Found by the owner on prod, 2026-11-18 (v1.50), on budget #1002, which the
signed-in manager holds herself.

## Problem

The budget page shows "Back" only for someone else's budget and, since
FS-1013, for the holder's approved budget. On an **open** budget that the
viewer holds - a manager's own budget, or an employee's - there is no Back at
all. The design leaned on the sheet switcher bar as the way out, but a manager
who opened the budget from the budget list has no direct way back to the list,
and the switcher bar is not a "back".

## Reproduce Steps

1. As a manager, create a budget held by yourself (or open an existing one,
   e.g. #1002 in the prod demo company).
2. Open the budget list, then open that budget.
   -- Expected: a "Back" button that returns to the list exactly as left
      (FS-1013: sections and scroll kept).
   -- Actual: no Back button; only the switcher bar and the browser's back.
3. Same as an employee holding an open budget: no Back to their dashboard.

## Suggested Solution Approach

Every budget page has Back. It returns to the page the user came from when
there is one; otherwise to the natural home - the budget list for a manager,
the dashboard for an employee.

## Suggested Fix

`budgetBackTarget` in `lib/utils/budget_edit_utils.dart` returns null for the
holder of an outstanding budget, which hides the button
(`lib/screens/budget_page_screen.dart`, the `budgetBackTarget(...) case final back?`
block). Make it always return a target: `AppRoutes.budgetsList` for a manager
(own budget included), `AppRoutes.employeeDashboard` for an employee. The page
already pops when the navigator can pop, and only falls back to the target for
a deep link. Update the "Back" unit test in `test/utils/budget_utils_test.dart`.
