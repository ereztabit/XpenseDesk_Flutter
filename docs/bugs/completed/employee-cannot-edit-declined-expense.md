## Problem

An employee cannot edit a declined expense on a declined sheet. The form opens in
read-only mode even though the server allows the edit and the SheetPermissions
utility correctly returns canEditExpense = true for this case.

The bug is in employee_expense_detail_screen.dart in the _isEditable getter:

  bool get _isEditable {
    if (widget.readOnly) return false;
    if (widget.isManagerMode) return _isEditingEnabled && !_isClosed;
    return _expense?.isPending == true && !_isClosed;  // <-- only checks Pending
  }

A declined expense has expenseStatusId == 3 (isPending == false), so _isEditable
returns false and all form fields are locked. The employee cannot correct the expense
and resubmit as intended by the decline flow.

SheetPermissions.canEditExpense in sheet_utils.dart line 193 is correct:
  case 4: // Declined sheet
    return expenseStatusId == 1 || expenseStatusId == 3; // Pending or Declined

The detail screen does not honour this rule.

## Reproduce Steps

1. Log in as an employee.
2. Open a Declined sheet.
3. Tap a declined expense.
   -- Observe: all form fields are read-only; no Save button.
   -- Expected: fields are editable; employee can correct and save.

## Suggested Fix

File: lib/screens/employee_expense_detail_screen.dart

Change _isEditable to also allow editing when the expense is Declined and the
parent sheet is also Declined:

  bool get _isEditable {
    if (widget.readOnly) return false;
    if (widget.isManagerMode) return _isEditingEnabled && !_isClosed;
    if (_expense == null || _isClosed) return false;
    final sheetStatusId = _expense!.expenseSheetStatusId;
    final expenseStatusId = _expense!.expenseStatusId;
    // Draft sheet: only Pending expenses
    if (sheetStatusId == 1) return expenseStatusId == 1;
    // Declined sheet: Pending or Declined expenses
    if (sheetStatusId == 4) return expenseStatusId == 1 || expenseStatusId == 3;
    return false;
  }

Ensure ExpenseSummary / the loaded expense model exposes expenseSheetStatusId so
the screen can read it (it is already present in the API response).
