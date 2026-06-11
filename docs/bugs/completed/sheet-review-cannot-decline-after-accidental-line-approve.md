# Bug: Cannot decline an expense after accidentally approving it

> **Status: done** -- verified by the user. Note: per-line decline on a Declined
> (returned) sheet succeeds only once the backend proc fix lands -- until then
> the server errors and the app surfaces the message.

## Product Rule (confirmed by Erez, 2026-06-11)

**The sheet is the lock, not the line.** Until the sheet is Approved (terminal),
every manager action on a line stays available. The only per-line hiding is the
no-op case (approve on an already-approved line, decline on an already-declined
line). Once the sheet is Approved, everything is locked -- that is the one and
only lock.

Implications for this bug:
- If the accidental approve auto-finalized the sheet (last unapproved line ->
  sheet Approved), the lock engaging is CORRECT per this rule -- the warning
  dialog before that click is the safeguard, and that sub-case is not a bug.
- On a WaitingForApproval sheet, decline on an Approved line must be available
  (client code reading says it already is -- exact repro still needed).
- On a Declined sheet, per-line decline is currently hidden client-side
  (WaitingForApproval-only gate in sheet_review_screen.dart and
  employee_expense_detail_screen.dart line 864). Per this rule that gate is
  WRONG -- a Declined sheet is not terminal, so per-line decline should be
  available there too. Pending backend confirmation (question 4 below) that
  the server accepts it.

## Problem

A manager reviewing a sheet with multiple expenses per-line approves one
expense by accident. They want to undo the mistake by declining that line.
The decline button is missing from the panel, so there is no way to reverse
an accidental per-line approve.

## Reproduce Steps

1. Log in as a manager and open a WaitingForApproval sheet with multiple
   expenses in Sheet Review.
2. Per-line approve one expense (accidentally, in the real case).
3. Try to decline that same expense -- via the row actions (the line now sits
   in the Approved filter tab) or by opening the expense detail panel.
   -- Expected: the decline button is still available; manager declines and
      the line flips Approved -> Declined.
   -- Actual: the decline button is missing from the panel.

## Investigation Notes (client code as of filing)

All four manager surfaces gate per-line decline as "callback provided AND the
line is not already Declined" -- i.e. by code reading they DO render decline on
an Approved line while the sheet is WaitingForApproval:

- lib/widgets/sheet_review/desktop_sheet_review_row.dart line 50
- lib/widgets/sheet_review/mobile_sheet_review_compact_row.dart line 51
- lib/widgets/expenses/manager_swipeable_expense_card.dart line 243
- lib/screens/employee_expense_detail_screen.dart line 864 (showDecline = isWfa
  AND statusId != 3)

The one path that fully removes the decline affordance: the accidental approve
was the LAST not-yet-approved line, so the server auto-finalized the sheet to
Approved (proc_EvaluateExpenseSheet). An Approved sheet is terminal -- all
per-line actions correctly disappear. There is a pre-finalize warning dialog
(LastActionConfirmDialog) before that click, but once confirmed there is no
undo.

So the exact repro needs pinning down: which surface the manager was on, and
what the SHEET status was right after the approve (still WaitingForApproval,
or auto-finalized to Approved).

## Backend Answer (received 2026-06-11)

The backend confirmed the product rule: button visibility derives from the
SHEET status, not the expense status. The per-line manager matrix:

| Sheet status        | Approve | Decline | Edit | Delete |
|---------------------|---------|---------|------|--------|
| WaitingForApproval  | yes     | yes     | yes  | yes    |
| Declined (returned) | yes     | yes (backend proc fix landing) | yes | yes |
| Approved (terminal) | no      | no      | no   | no     |

- Only per-line nuance: hide Approve on an already-Approved line and Decline
  on an already-Declined line (API rejects no-op repeats).
- POST /api/expenses/{id}/approve and /decline -- no body changes.
  Approve-on-returned-sheet already works; decline-on-returned-sheet errors
  until their proc fix lands (the change they are shipping).
- The one irreversible moment is sheet finalization: a per-line approve that
  resolves the last non-approved line auto-finalizes the sheet to Approved
  instantly. Backend asked for an explicit confirm on that specific tap --
  detectable client-side as "the only line whose status isn't Approved".

## Resolution (verified 2026-06-11)

- lib/screens/sheet_review_screen.dart -- per-line decline callback now gated
  on "sheet not terminal" (WaitingForApproval or Declined), same as approve;
  whole-sheet decline stays WfA-only. The pre-finalize LastActionConfirmDialog
  on a line approve now fires on Declined sheets too, not just WfA.
- lib/screens/employee_expense_detail_screen.dart -- detail-panel showDecline
  relaxed from WfA-only to WfA-or-Declined; same pre-finalize warning gate
  relaxed.
- Row/card widgets needed no change -- they already hide only the no-op
  (approve on Approved line, decline on Declined line).
- The finalize confirm the backend requested already existed
  (LastActionConfirmDialog + SheetExpenseBuckets.approveFinalizesSheet, which
  implements exactly their "only line whose status isn't Approved" detection).
- Related polish shipped in the same change: the open-detail icon on the
  desktop Sheet Review rows now follows the same rule -- pencil/Edit while the
  sheet is non-terminal, eye/View on an Approved sheet (canEditLines threaded
  from sheet_review_screen.dart down to desktop_sheet_review_row.dart).

## Suggested Solution Approach

Depends on the backend answer:

- If the server supports Approved -> Declined per-line on a WaitingForApproval
  sheet: reproduce the missing-button case precisely and fix whatever gate
  hides it (or, if the repro turns out to be the auto-finalize case, decide
  the product behavior for an accidentally finalized sheet).
- If the server does NOT support it: the client surfaces listed above are
  offering a decline that would 409 -- tighten the client gates to
  Pending-only, and file the Approved -> Declined flip as a server feature
  request (it is the natural undo for an accidental approve).

## Suggested Fix

Needs investigation -- do not assert a code fix until the backend answers and
the missing-button surface is reproduced.
