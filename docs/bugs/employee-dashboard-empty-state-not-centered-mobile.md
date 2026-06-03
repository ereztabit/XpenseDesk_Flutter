## Problem

On mobile, the empty state message on a Draft sheet ("No expenses in this sheet") is
not vertically centered in the available screen space. The content (sparkle icon, title,
description, New Expense button) sits at the top of the card with padding above and
below, but the card itself only wraps the content height and does not fill the
remaining viewport. The result is a small card floating near the top of the screen
with a large empty background below it.

## Reproduce Steps

1. Log in as an employee on mobile.
2. Open a Draft sheet that has no expenses yet.
   -- Observe: the empty state card is near the top of the screen; large empty
      background area below.
   -- Expected: the content is centered in the available viewport height below the
      sheet picker.

## Suggested Solution Approach

The Card wrapping SheetExpenseEmptyState needs a minimum height constraint equal to
the available viewport space below the sheet picker. The Column inside
SheetExpenseEmptyState should center its children vertically within that space.

## Suggested Fix

File: lib/widgets/employee_dashboard/sheet_expense_empty_state.dart
  Change Column mainAxisSize from MainAxisSize.min to MainAxisSize.max and add
  mainAxisAlignment: MainAxisAlignment.center.

File: lib/widgets/employee_dashboard/sheet_expenses_area.dart (line 64) and
      lib/screens/user_dashboard_screen.dart (line 125):
  Wrap the Card in a ConstrainedBox with minHeight based on remaining viewport height
  so the Column has space to center into:
    ConstrainedBox(
      constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height * 0.5),
      child: Card(...)
    )

Same fix applies to the "no sheets at all" empty state in user_dashboard_screen.dart.
