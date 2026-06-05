# Bug: Mobile swipe-delete leaves the card on screen until manual refresh

> **Status: new**

## Problem

On the employee dashboard (mobile), deleting an expense via swipe-to-delete
confirms and deletes server-side, but the card stays on screen. Only after a
manual refresh does it disappear.

Root cause: `DeleteExpenseDialog` invalidates `expenseSearchProvider` on success
and only calls its `onRefresh` callback on the error path. The employee
dashboard list, however, reads `sheetDetailProvider` -- which is never
invalidated by the swipe path. `SwipeableExpenseCard._handleTapDelete` calls
`DeleteExpenseDialog.show(...)` but does not call `onRefresh` on success, so
nothing re-fetches the sheet detail the list is built from.

(The non-swipe delete path in `SheetExpensesArea._delete` does call `onRefresh()`
after the dialog, which is why desktop / compact-list delete updates correctly.)

## Reproduce Steps

1. As an employee on mobile, open a sheet with deletable expenses.
2. Swipe a card to reveal Delete, tap Delete, confirm.
   -- Expected: the card disappears immediately.
   -- Actual: the card remains until a manual page refresh.

## Suggested Solution Approach

Ensure the swipe-delete success path refreshes the list the dashboard renders
from (`sheetDetailProvider`).

## Suggested Fix

In `SwipeableExpenseCard._handleTapDelete`, call `widget.onRefresh?.call()` after
a successful delete (the dialog returns `deleted == true`). Alternatively, have
`DeleteExpenseDialog` invoke `onRefresh` on success too (not only on error).
Verify it doesn't double-refresh with the resubmit path
(`onResubmitted`) already added for the last declined line.
