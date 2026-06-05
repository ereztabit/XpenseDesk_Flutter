# Bug: No warning before the last action that finalizes/re-submits a sheet

> **Status: in progress**

## Implementation (built, awaiting manual verification)

Pre-action confirmation gate added before any per-expense action that auto-transitions the sheet. Shared dialog `lib/widgets/last_action_confirm_dialog.dart` (non-dismissable); detection helpers `SheetExpenseBuckets.approveFinalizesSheet` / `isLastDeclinedExpense` in `lib/utils/sheet_utils.dart`. Gates:

- Manager inline approve (sheet review) -- `sheet_review_screen.dart._handleLineApprove`; one chokepoint covers desktop table + mobile card + mobile compact.
- Manager detail-screen approve -- `employee_expense_detail_screen.dart._approve` (reads parent sheet via `sheetDetailProvider`).
- Employee edit-save of last declined line -- `employee_expense_detail_screen.dart._save`.
- Employee delete of last declined line -- `sheet_expenses_area.dart._delete` (desktop icon + mobile compact) and `swipeable_expense_card.dart` (mobile swipe), flag threaded from `employee_dashboard_body.dart`.

Scope note: the manager gate fires only on WaitingForApproval sheets (approve never finalizes a Declined sheet -- and the escape-hatch approve on a Declined sheet is separately broken server-side: `proc_ApproveExpense` requires WfA, so it no-ops). Decline never auto-finalizes, so it is not gated.

## Problem

A sheet's state transition happens automatically as a side effect of the user's
LAST per-expense action, with no warning beforehand. The user does not realize the
action they are about to take is final, and is left disoriented after it happens.

Two cases:

1. Manager, WaitingForApproval sheet, acting on expenses one by one (inline
   approve/decline). The moment the manager handles the LAST pending expense, the
   backend auto-evaluates and finalizes the sheet (-> Approved), and the manager is
   thrown back to the dashboard with no explanation of what just happened.

2. Employee, Declined sheet, fixing the declined expenses (edit or delete). The
   moment the employee handles the LAST remaining declined expense, the entire sheet
   auto-resubmits for approval. No warning, no confirmation.

In both cases the transition itself is correct behavior -- the issue is that it
happens silently, with no chance for the user to understand or back out.

## Reproduce Steps

Manager:
1. Log in as a manager, open a WaitingForApproval sheet with 2+ pending expenses.
2. Approve/decline expenses one by one with the inline icons.
3. On the LAST pending expense, take the action.
   -- Actual: sheet finalizes and the manager is bounced to the dashboard with no
      prompt or explanation.
   -- Expected: before that last action, a confirmation explains the sheet will be
      finalized, and asks to proceed.

Employee:
1. Log in as an employee, open a Declined sheet with 2+ declined expenses.
2. Edit or delete the declined expenses one by one.
3. On the LAST declined expense, take the action.
   -- Actual: the whole sheet silently re-submits for approval.
   -- Expected: before that last action, a confirmation explains the sheet will be
      re-submitted, and asks to proceed.

## Suggested Solution Approach

Gate the LAST action with a pre-action confirmation. Before performing the action,
detect whether it is the one that will trigger the sheet transition; if so, show a
non-dismissable confirm dialog. Run the action only on confirm.

- Manager (inline approve/decline): the action is "last" when there is exactly one
  expense still Pending before it -- i.e. acting on it brings pending count to 0.
  Dialog copy: "This is the last expense on this sheet. After this, the sheet will
  be finalized (approved). Do you want to proceed?"

- Employee (edit/delete on a Declined sheet): the action is "last" when there is
  exactly one declined expense remaining before it. Dialog copy: "This is the last
  declined expense. After this, the sheet will be re-submitted for approval. Do you
  want to proceed?"

The dialog must not be dismissable by tapping outside (force an explicit choice).

## Suggested Fix

Needs investigation before asserting exact call sites -- the two flows differ:

- Manager: lib/screens/sheet_review_screen.dart, in _handleLineApprove /
  _handleLineDecline. Count Pending expenses (expenseStatusId == 1) from the current
  sheet detail BEFORE calling the service; if count == 1, show the confirm dialog
  first and only call approveExpense/declineExpense on confirm.

- Employee: the resubmit is triggered server-side when the last declined expense is
  resolved, but the employee's edit happens on a SEPARATE detail screen
  (/employee/expense/{id}) -- the save/delete there is what flips the sheet, not the
  dashboard. So the gate likely belongs at the delete site
  (lib/widgets/employee_dashboard/sheet_expenses_area.dart _delete) AND at the
  edit-save site in the expense detail screen. Need to confirm exactly where the
  resubmit fires and how "last declined expense" is determined before wiring the
  prompt. Investigate before coding.

New ARB keys (EN + HE) required for both dialog variants (title, body, proceed,
cancel). No placeholders -- concatenate any dynamic parts in the widget.
