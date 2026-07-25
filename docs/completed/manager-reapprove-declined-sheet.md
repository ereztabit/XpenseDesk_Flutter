# Manager can re-approve a declined sheet

> **Status:** SHIPPED & confirmed.
> The existing `POST /api/expense-sheets/{id}/approve` now also accepts sheets in
> `Declined` status (no new endpoint).

## Problem

A manager who declines a sheet currently has no way to undo it. Per the Expense
Sheets transformation design, there is no manager-side "reopen"/undo — the
manager must wait for the employee to fix and resubmit, or contact them
out-of-band. See `docs/completed/ExpenseSheetsTransformation/03-SheetReview.md`
§3.7 and `ExpenseSheetsEvolution.md` §3.6/§9.

This feature **intentionally reverses that decision**: the server is adding an
API that lets a manager re-approve (approve) a sheet currently in `Declined`
(`statusId == 4`) without round-tripping through the employee.

### Why — the escape hatch

The "wait for the employee to resubmit" model breaks down when the employee
simply **doesn't act** on a declined sheet (didn't really modify it, ignored it,
left the company, etc.). The sheet then sits in `Declined` forever and the
manager has no way to close it out. Re-approve is the manager's escape hatch:
when a declined sheet is stuck, the manager can take it over and resolve it as
they see fit — re-approve it as-is rather than being blocked on employee action.

> ⚠️ Because this contradicts the earlier "no reopen, ever" design, update
> `03-SheetReview.md` §3.7 and `ExpenseSheetsEvolution.md` when this ships so the
> two specs don't conflict.

## Current state

- Decline flow lives in the sheet review screen / providers
  (`lib/providers/expense_sheet_provider.dart`, sheet review widgets under
  `lib/widgets`/`lib/screens` for manager sheet review).
- `statusId == 4` = `Declined`; there is deliberately no reopen affordance.
- Codebase grep for `reopen` is expected to be **zero** today — adding this must
  not resurrect the old per-expense `/api/expenses/{id}/reopen` endpoint (gone,
  returns 404). This is a **sheet-level** action against the new API.

## Proposed approach (refine when API lands)

1. Add the re-approve call to `ApiService` → `expense_service.dart` /
   `expense_sheet_provider.dart`.
2. Surface a "Re-approve" action on a `Declined` sheet in the manager sheet
   review screen (gated to manager role + `statusId == 4`).
3. Confirmation dialog; on success refresh the sheet + manager queue buckets.
4. All captions localized (EN + HE) per CLAUDE.md.

## Server answers (resolved)

- **Approve precondition:** sheet must be `WaitingForApproval(2)` or `Declined(4)`.
- **Line flip:** "every still-Pending line → Approved." Declined lines stay declined.
- **All-declined sheet:** approve **succeeds** — the line flip is simply a no-op,
  no "nothing to approve" error, no minimum-approvable-line requirement. The sheet
  becomes `Approved(3)`, every line stays Declined, ₪0 reimbursed, terminal (no
  further edits/deletes). **Approve IS the close path** — no dedicated finalize
  action needed.
- **`latestDeclineComment` is RETAINED after approve** (it's the last Declined-target
  log entry; the Declined→Approved row has a null comment so the field keeps
  returning the old reason). ⚠️ **Client must gate any decline UI on
  `expenseSheetStatusId == 4`, not on the field being non-null.**
- **Preconditions (unchanged):** manager-only → 403; block-mode (locked/overdue)
  → 403 `SubscriptionRequired` (applies here too); wrong status (Draft/Approved)
  → 409 `ExpenseSheetWrongStatusForAction`; not found / other company → 404. No
  cycle precondition (works after cycle close).
- **Audit:** status history records `… → Declined → Approved` with the decline
  comment preserved in the log.

### Client implications

1. **Approve stays enabled even when 0 approvable** (it's the close path). For that
   case, use the server's suggested confirm copy: *"All expenses on this sheet are
   declined. Approving will close the sheet with nothing reimbursed."*
2. **Stale decline callout (must fix):** `sheet_review_header_card.dart` renders
   `_DeclineCommentCallout` whenever `latestDeclineComment` is non-empty, ignoring
   status. After re-approve the sheet is Approved but keeps the comment, so the
   callout would wrongly show on an approved sheet. Gate it on
   `expenseSheetStatusId == ExpenseSheetStatus.declined.id`.

## Done when

- Manager can approve a `Declined` sheet directly from sheet review.
- Sheet + manager dashboard buckets refresh after the action.
- ExpenseSheetsTransformation specs updated to reflect the reversed decision.
