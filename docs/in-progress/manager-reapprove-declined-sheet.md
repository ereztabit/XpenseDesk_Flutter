# Manager can re-approve a declined sheet

> **Status:** Planned — **blocked on server (API is WIP)**.

## Problem

A manager who declines a sheet currently has no way to undo it. Per the Expense
Sheets transformation design, there is no manager-side "reopen"/undo — the
manager must wait for the employee to fix and resubmit, or contact them
out-of-band. See `docs/in-progress/ExpenseSheetsTransformation/03-SheetReview.md`
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

## Server dependency / open questions

- API contract is **WIP** — endpoint, request shape, resulting status.
- Does re-approving a declined sheet also clear/retain `latestDeclineComment`?
- Are there block-mode / cycle-closed pre-conditions (cf. the existing
  approve/decline 403 handling)?

## Done when

- Manager can approve a `Declined` sheet directly from sheet review.
- Sheet + manager dashboard buckets refresh after the action.
- ExpenseSheetsTransformation specs updated to reflect the reversed decision.
