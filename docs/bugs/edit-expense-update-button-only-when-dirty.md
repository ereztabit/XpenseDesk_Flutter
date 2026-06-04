# Bug: Edit Expense -- Update Button Enabled Without Changes

## Problem

When editing an expense, the Update / Save button is enabled even when the user has
not changed anything. The button should only become available once the form is
"dirty" -- i.e. at least one field differs from the values the expense was loaded
with. Saving an unchanged form is a pointless write and a confusing affordance.

## Reproduce Steps

1. Open an expense for edit (employee: a Pending expense on a Draft sheet;
   manager: tap Edit on the expense detail).
2. Do not change any field.
3. Result: the Update / Save button is enabled and clickable.
4. Expected: the button is disabled until something actually changes; re-enabled
   once a field differs from its loaded value, and disabled again if the user
   reverts back to the original values.

## Suggested Solution Approach

Gate the save/update button on "valid AND dirty" instead of just "valid".

## Suggested Fix

File: lib/screens/employee_expense_detail_screen.dart

- In `_initForm`, capture a snapshot of the loaded values (amount text, merchant,
  note, receiptRef, selectedDate, selectedCategoryId, selectedCurrencyCode,
  isAiData).
- Add an `_isDirty` getter that compares the current controller/selection values
  to that snapshot (true if any differ).
- Change the save/update button's `onPressed` from `_canSave && !_isSaving` to
  `_canSave && _isDirty && !_isSaving` (both the employee `_buildActionButtons`
  save button and the manager-mode update button).
- Consider wiring `hasUnsavedChanges` (FormBehaviorMixin) to `_isDirty` as well so
  the navigation guard only prompts when there are real changes.

Note: the amount field is normalised through a formatter on load, so compare the
parsed numeric value (not the raw text) to avoid false-positive dirtiness.
