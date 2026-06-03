## Problem

When a manager finishes reviewing every individual expense on a sheet (approving or
declining each one), the UI takes no action and shows no prompt. The manager is left
staring at the sheet with no guidance, and can simply close it without resolving the
sheet outcome.

Two cases are broken:

1. All expenses approved -- the backend already auto-flips the sheet to Approved
   (proc_EvaluateExpenseSheet). The frontend just silently refreshes and shows the
   updated status. No navigation back, no toast, no confirmation. The manager does not
   know they are done.

2. All expenses reviewed, at least one declined -- the sheet stays WaitingForApproval
   (correct, backend does not auto-approve in this case). The frontend refreshes
   silently. The manager is not prompted to resolve the sheet. They can close the screen
   and leave the sheet in a dead state: WaitingForApproval with no pending expenses and
   no sheet-level decision. The employee cannot act on it.

## Reproduce Steps

1. Log in as a manager and open a sheet in WaitingForApproval with 2+ expenses.
2. Approve every expense one by one using the inline approve icon.
   -- Observe: UI refreshes, nothing else happens. Sheet is now Approved but manager
      gets no feedback and is not navigated away.
3. Repeat with a fresh sheet. Decline at least one expense and approve the rest.
   -- Observe: after the last per-expense action, UI refreshes silently. No dialog
      appears asking the manager what to do with the sheet. Manager can close the page.

## Suggested Solution Approach

After every per-expense approve or decline action in sheet_review_screen.dart, once
_refresh() completes, count how many expenses are still Pending.

If pendingCount == 0:
  - If all expenses are Approved: the sheet is already auto-approved by the backend.
    Navigate back to the manager dashboard and show a success toast ("Sheet approved").
  - If at least one expense is Declined: show a dialog:
      "All expenses have been reviewed. Some were declined.
       What would you like to do?"
      [Approve sheet]   -- approves the sheet as-is
      [Decline sheet]   -- declines the sheet so the employee can make corrections

The dialog must not be dismissable without choosing an option (no tap-outside-to-close).

## Suggested Fix

File: lib/screens/sheet_review_screen.dart

After _handleLineApprove() and _handleLineDecline() call _refresh(), add a helper:

  Future<void> _checkSheetCompletion() async {
    final detail = // read from current provider state after refresh
    final pending = detail.expenses.where((e) => e.expenseStatusId == 1).length;
    if (pending > 0) return;

    final allApproved = detail.expenses.every((e) => e.expenseStatusId == 2);
    if (allApproved) {
      // backend already approved the sheet -- just navigate away
      if (mounted) Navigator.of(context).pop();
      // optionally show a SnackBar
      return;
    }

    // some declined -- show resolution dialog (not dismissable)
    // on Approve: call _handleApprove()
    // on Decline: show decline-comment dialog then call _handleDecline()
  }

Call _checkSheetCompletion() at the end of _handleLineApprove() and _handleLineDecline(),
after the await _refresh() call.
