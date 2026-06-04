# Bug: Employee dashboard expense list issues

> **Status: done**

## Problem

Four UI issues on the employee dashboard expense list affecting all sheet states (Draft, Submitted, Declined, Approved).

1. Status filter tabs (Pending / Approved / Declined) are only shown for Declined sheets.
   They are missing for Submitted sheets, where the manager may have individually
   approved or declined some expenses while the sheet is still WaitingForApproval.

2. On mobile, approved expenses open in edit mode instead of view-only mode.
   A parameter naming bug in MobileSheetExpenseCarousel passes the view callback
   into MobileExpenseCard's onEdit parameter, causing the card to render edit controls
   even when the sheet is read-only. Desktop is correct.

3. On mobile, declined expenses inside a Declined sheet do not support swipe-to-delete.
   SheetPermissions.canDeleteExpense likely returns false for Declined expenses within
   a Declined sheet, so enableSwipeToDelete is false and SwipeableExpenseCard is never
   used. The employee should be able to delete a declined expense the same way they
   delete a draft expense (swipe left).

4. The expense status pill (Pending / Approved / Declined badge) is missing from the
   desktop expense table. The desktop row only shows: row number, date, amount,
   category, merchant, and action icons. ExpenseStatusBadge is used in MobileExpenseCard
   but never rendered in DesktopSheetTableRow or its header.

## Reproduce Steps

1. Log in as an employee.
2. Open a Submitted sheet -- observe no Pending/Approved/Declined filter tabs (issue 1).
3. On mobile, tap an expense in an Approved sheet -- observe it opens with edit controls
   instead of a read-only view (issue 2).
4. On mobile, open a Declined sheet and swipe left on a declined expense -- observe no
   delete action appears (issue 3).
5. On desktop, open any sheet -- observe no status badge column in the expense table
   (issue 4).

## Suggested Solution Approach

1. Tabs: render StatusFilterTabs for Submitted sheets in employee_dashboard_body.dart
   (currently only rendered inside the _isDeclined branch, line 101).

2. Mobile view-only bug: fix the parameter in MobileSheetExpenseCarousel (line 71)
   -- pass onView to MobileExpenseCard's correct slot (add a separate onView param to
   MobileExpenseCard, or check the callback intent before assigning).

3. Swipe-to-delete for declined: verify SheetPermissions.canDeleteExpense returns true
   for expenseStatusId == Declined when sheetStatusId == Declined, same as for Draft.
   If not, fix the permission rule. canDelete drives enableSwipeToDelete in
   sheet_expenses_area.dart (line 83).

4. Status pill on desktop: add an ExpenseStatusBadge column (flex ~14) to
   DesktopSheetTableRow and the matching header in desktop_sheet_expense_table.dart.
   Reduce Category or Merchant flex by the same amount to compensate.

## Suggested Fix

Issue 2 -- lib/widgets/employee_dashboard/mobile_sheet_expense_carousel.dart line 71:
  Current:  onEdit: widget.onView != null ? () => widget.onView!(expense) : null
  Fix:      add onView parameter to MobileExpenseCard and pass widget.onView there;
            leave onEdit null so the card renders as read-only.

Issue 3 -- check SheetPermissions.canDeleteExpense for (sheetStatus=Declined, expenseStatus=Declined).
  If false, add the Declined+Declined case to the allow-list.

Issue 4 -- lib/widgets/employee_dashboard/desktop_sheet_table_row.dart:
  Add after the Merchant Expanded column:
    Expanded(flex: 14, child: Align(alignment: AlignmentDirectional.centerStart,
      child: ExpenseStatusBadge(expenseStatusId: expense.expenseStatusId, isAiData: expense.isAiData)))
  Reduce Merchant flex from 22 to 16 (or Category from 25 to 19) to keep the row balanced.
  Add matching header label in desktop_sheet_expense_table.dart _SheetTableHeader.

## Resolution

Three of the four issues shipped; issue 4 was consciously dropped (see below).

1. Status filter tabs on Submitted sheets -- StatusFilterTabs now render for
   Submitted sheets in lib/widgets/employee_dashboard/employee_dashboard_body.dart,
   not just the Declined branch.

2. Mobile read-only view -- lib/widgets/employee_dashboard/mobile_sheet_expense_carousel.dart
   now has a dedicated onView slot; the view callback no longer leaks into onEdit,
   so read-only sheets open in view mode on mobile.

3. Swipe-to-delete for declined expenses -- lib/utils/sheet_utils.dart
   `SheetPermissions.canDeleteExpense` case 4 (Declined sheet) returns true for
   expenseStatusId 1 (Pending) or 3 (Declined). employee_dashboard_body.dart wires
   that permission into `canDelete`, which drives `enableSwipeToDelete` on
   lib/widgets/employee_dashboard/sheet_expenses_area.dart's mobile carousel.

4. Status pill on the desktop *employee* expense table -- NOT implemented, dropped
   by decision (not important). The manager Sheet Review table already shows the
   status badge (closed under manager-sheet-review-desktop-layout-issues); the
   employee-side desktop table (desktop_sheet_table_row.dart) intentionally keeps
   its current columns with no status column.
