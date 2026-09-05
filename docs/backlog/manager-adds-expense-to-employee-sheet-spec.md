# Manager adds an expense to an employee's sheet (approved on entry)

> Mission: FS-1004 (backend: BackEnd/XpenseDeskServer/docs/backlog/manager-adds-expense-to-employee-sheet-story.md)

## The business case

During the approval pass the manager is the one who knows what is missing --
usually a receipt the employee cannot produce, or a line they forgot. The
manager can already correct any line on a non-Approved sheet; they cannot add
one. Today that needs a DBA running SQL by hand.

Two rules from the backend half, both visible in the UI:

1. **The line belongs to the employee** -- they are the one reimbursed. The
   manager is filling in a form for someone else's money, and the screen has to
   say so.
2. **The line is created already approved** -- the manager who would approve it
   is the one entering it. No second approval step, and the line appears in the
   Approved tab immediately, not in Pending.

## Blocked on the backend

`POST /api/expenses` has no `expenseSheetId` today and always files the line
against the acting user's own open-cycle sheet. Building this first would
silently create the manager's own expense on the wrong sheet with a 200
response.

## Client changes

### 1. "Add expense" action in Sheet Review

`lib/screens/sheet_review_screen.dart` gains an "Add expense" action, visible
**only** for a sheet in WaitingForApproval (2) or Declined (4).

- Hidden on Approved (3) -- approval closes the sheet.
- Draft (1) does not arise: managers never see Draft sheets. If one somehow
  reaches the screen, the action stays hidden; the server refuses it anyway.

### 2. The form must name whose expense it is

Reuse the existing new-expense form, but the manager's entry point differs from
the employee's in three ways and all three must be on screen:

- **who it is filed under** -- "This expense will be filed under <employee>",
  prominent, not a footnote. The manager is entering a reimbursement for
  another person;
- **which cycle/sheet it lands on** -- the target is usually a *previous*
  cycle, so the cycle label must be shown. Never leave it implicit;
- **that it is approved on save** -- the confirm/success copy says the line is
  recorded as approved, so the manager is not left waiting for it to appear in
  the Pending tab.

### 3. After save

Refresh `sheetDetailProvider` (and the queue if the review screen was reached
from it). The new line appears in the **Approved** tab. The sheet's own status
does not change -- a Declined sheet is still Declined, a WaitingForApproval
sheet is still waiting. The screen must not imply the sheet was approved or
resubmitted.

### 4. Errors

Handle 404 (sheet not found), 409 (Approved or Draft sheet), 403 (other
company), and the billing block-mode 403 the approve/decline CTAs already
handle.

## Out of scope

- The employee adding an expense to their own non-approved sheet, the
  "Submit for approval" banner CTA, and the returned-earlier marker on Pending
  lines -- all FS-1003.
- Any add affordance on an Approved sheet, on either dashboard.

## Localization

New strings in both languages (`lib/l10n/app_en.arb`, `app_he.arb`): the
action label, the "filed under <employee>" note, the "adding to <cycle>" label,
and the approved-on-save confirm/success/failure copy.
