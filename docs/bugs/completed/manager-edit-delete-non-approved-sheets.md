# Bug: Manager Can Edit/Delete Any Expense Unless the Sheet Is Approved

> **Status: done.** Shipped end-to-end -- client across all layouts and the four
> server procs applied; verified. See the Resolution section at the end.

## Problem

A manager should be able to fully **edit and delete** expenses on any sheet that is
**not Approved** (i.e. Draft, WaitingForApproval, or Declined), so they can correct
and finalize a sheet on behalf of an unresponsive employee. Only an **Approved**
(finalized) sheet is locked for everyone.

Today this rule is not enforced consistently across the edit, delete, and approve
paths, on both the client and the server.

## Use Case

1. Manager declines a sheet (it is returned to the employee).
2. The employee is slow / unresponsive.
3. The manager should be able to edit and/or delete the expenses themselves and
   re-approve the sheet on the employee's behalf -- without waiting.

## Current Behavior (gaps)

- **Edit -- allowed too broadly.** A manager can edit even on an **Approved** sheet.
  - Client: `employee_expense_detail_screen.dart` `_isEditable` returns
    `_isEditingEnabled` in manager mode with no sheet-status check.
  - Server: `proc_UpdateExpense` treats a manager as "always allowed" (no
    sheet-status guard).
  - Expected: blocked when the sheet is Approved.

- **Delete -- allowed too narrowly.** A manager can delete only on Draft or Declined
  sheets, not WaitingForApproval.
  - Client: `SheetPermissions.canDeleteExpense` (manager -> Draft|Declined).
  - Server: `proc_DeleteExpense` (manager -> Draft|Declined).
  - Expected: allowed on any non-Approved sheet (Draft, WaitingForApproval, Declined).

- **Re-approve on a declined sheet.** Per-expense approve/decline requires the sheet
  to be WaitingForApproval (server), and the per-expense approve/decline row is
  hidden on non-WaitingForApproval sheets in the detail screen. So the manager fixes
  the declined expenses (editing resets each to Pending); once all declines are
  resolved the sheet auto-returns to WaitingForApproval (per `proc_EvaluateExpenseSheet`),
  and the manager approves the whole sheet. Confirm this full path works end-to-end
  for a manager acting on the employee's behalf.

## Desired Rule (single source of truth)

- Manager **edit** allowed iff sheet status != Approved.
- Manager **delete** allowed iff sheet status != Approved.
- Approved sheets are fully locked for everyone.

## Suggested Fix

Client:
- `lib/screens/employee_expense_detail_screen.dart` `_isEditable`: in manager mode,
  return false when the parent sheet is Approved
  (`expense.expenseSheetStatusId == ExpenseSheetStatus.approved.id`); otherwise
  `_isEditingEnabled`.
- `lib/utils/sheet_utils.dart` `SheetPermissions.canEditExpense` (manager branch):
  return `sheetStatusId != Approved` instead of always true.
- `SheetPermissions.canDeleteExpense` (manager branch): return
  `sheetStatusId != Approved` (allow Draft, WaitingForApproval, Declined).

Server (`XpenseDeskServer`):
- `proc_UpdateExpense`: guard so a manager cannot edit when the parent sheet is
  Approved.
- `proc_DeleteExpense`: allow manager delete on WaitingForApproval too; block only
  on Approved.

Notes:
- Keep the existing per-expense approve/decline gating (only on WaitingForApproval).
  Re-approving a declined sheet happens by resolving its declines (which returns it
  to WaitingForApproval) and then approving the whole sheet -- not by per-line
  approve on a Declined sheet.
- Client and server must agree, or the client will paint actions that the server
  then rejects.

## Resolution

Shipped end-to-end. The single rule is now enforced consistently: **manager may
edit, approve, or delete a line on any sheet except Approved; Approved sheets are
fully locked for everyone.**

Client (all done, `flutter analyze` + `flutter build web` clean):
- `lib/utils/sheet_utils.dart` -- `SheetPermissions.canEditExpense` and
  `canDeleteExpense` manager branches now return `sheetStatusId != Approved`.
- `lib/screens/employee_expense_detail_screen.dart` -- `_isEditable` blocks manager
  edit on Approved (`_isEditingEnabled && !_isSheetApproved`); the Edit button is
  hidden on Approved and restyled as a proper `AppButton`; the manager
  Approve/Decline/Delete row renders each action independently.
- Per-line actions now appear consistently across **all** layouts -- desktop table
  (`desktop_sheet_review_row.dart`), mobile compact list
  (`mobile_sheet_review_compact_row.dart`), and the mobile swipe card
  (`manager_swipeable_expense_card.dart` / `mobile_sheet_review_list.dart`). The
  swipe card's action-panel width auto-sizes to the visible actions, Delete skips
  the fly-away (it opens the shared confirm dialog), and the first card replays the
  swipe-hint peek each time the card layout appears.
- `sheet_review_screen.dart` gating: approve on WaitingForApproval **or** Declined;
  decline only on WaitingForApproval; delete on any non-Approved sheet.

Rule refinement vs. the original "Notes": the manager can now **approve or delete a
declined line directly on a Declined sheet** (no need to edit-to-reset first). A
Declined sheet stays Declined while any declined expense remains, and only
auto-returns to WaitingForApproval once all declines are resolved
(`proc_EvaluateExpenseSheet` guard).

Server (`XpenseDeskServer`, procs applied via MCP by the user):
- `proc_UpdateExpense` -- manager blocked when the parent sheet is Approved.
- `proc_DeleteExpense` -- manager delete allowed on any non-Approved sheet.
- `proc_ApproveExpense` -- manager per-line approve allowed on Declined sheets.
- `proc_EvaluateExpenseSheet` -- Declined sheet stays Declined while a declined
  expense remains.
- Backend test suite re-run and verified green for these proc changes.
