## Problem

Three issues on the manager expense detail screen when edit mode is active.

1. No Cancel button in manager edit mode.
   When the manager clicks Edit and makes changes, there is no way to discard those
   changes and return to read-only view without saving. Employee mode has a Discard
   button (line 719) that calls Navigator.pop(). Manager mode has no equivalent.

2. Approve and Decline buttons remain active during edit.
   While the manager has unsaved field changes (_isEditingEnabled == true), the
   Approve and Decline buttons are still tappable. Only _isSaving disables them.
   The manager could approve or decline without saving their edits, or the edits
   could silently conflict with the action outcome.

3. Date in the manager info header shows short numeric format instead of long format.
   The header shows "6/3/2026" (from toCompanyDate / DateFormat.yMd) but should show
   "June 3rd 2026" (toLongDate format), consistent with how dates appear elsewhere
   in the app.

## Reproduce Steps

1. Open any expense in manager mode (/manager/expense/:id).
2. Click the Edit button to enter edit mode.
   -- Observe: only "Update Expense Details" is shown. No Cancel / Discard button
      anywhere on the screen (issue 1).
   -- Observe: Approve and Decline buttons are still green/red and tappable (issue 2).
3. Look at the employee name / date line at the top of the form.
   -- Observe: date reads "6/3/2026" instead of "June 3rd 2026" (issue 3).

## Suggested Solution Approach

1. Add a Cancel button next to "Update Expense Details" that resets _isEditingEnabled
   to false and restores the original field values (same pattern as employee Discard).

2. Gate Approve and Decline on edit state:
   onPressed: (_isSaving || _isEditingEnabled) ? null : _approve / _decline

3. Change the createdAt date in _buildManagerInfoHeader to use toLongDate instead of
   toCompanyDate.

## Suggested Fix

File: lib/screens/employee_expense_detail_screen.dart

Issue 1 -- add Cancel alongside the save button in _buildActionButtons (line 676):
  Row with two buttons: Cancel (secondary, resets edit state) + Update Expense Details.

Issue 2 -- lines 657 and 665:
  Current:  onPressed: _isSaving ? null : _approve
  Fix:      onPressed: (_isSaving || _isEditingEnabled) ? null : _approve
  Same change for _decline on line 665.

Issue 3 -- line 592:
  Current:  expense.createdAt.toCompanyDate(companyLocale)
  Fix:      expense.createdAt.toLongDate(companyLocale)
