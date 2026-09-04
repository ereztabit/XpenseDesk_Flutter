# Add expenses to a non-approved sheet + explicit resubmit

> Mission: FS-1003 (backend: BackEnd/XpenseDeskServer/docs/backlog/add-expenses-to-non-approved-sheet-story.md)

## The business case

The manager declines an employee's sheet during the approval pass (typically:
missing receipts). The employee adds the missing receipts **to that same
sheet** and submits it back when they feel ready. A manager may add an expense
to any sheet that is not yet Approved. Approval closes the sheet.

The sheet is normally on the **previous** cycle, since decline happens after
cycle promotion.

## Blocked on the backend

Every item below needs FS-1003's backend half first: `POST /api/expenses` has
no `expenseSheetId` (the server picks the open cycle's sheet), and there is no
submit endpoint. Building the UI before that would create the line on the
wrong sheet with a 200 response.

## Client changes

### 1. Enable "+ New expense" on a non-approved sheet

`newExpenseEnabled: isCurrentDraft` at `lib/screens/user_dashboard_screen.dart:168`
is fed by `SheetSelection.isCurrentCycleDraft`
(`lib/utils/sheet_utils.dart:54`), which returns false for any status other
than Draft **and** for any cycle other than the newest. Both halves of that
gate have to go for this flow: the target is a Declined sheet, usually on an
older cycle.

New rule: enabled when the selected sheet's status is Draft (1),
WaitingForApproval (2) or Declined (4) -- regardless of cycle. Disabled on
Approved (3).

Keep `isCurrentCycleDraft` for whatever else needs "is this the live draft";
add a separate predicate (`SheetSelection.acceptsNewExpenses`) rather than
loosening the existing one.

### 2. Pass the target sheet through the new-expense flow

`/employee/new-expense` is pushed with no arguments today, and
`ExpenseService` sends no sheet id. Both need the selected
`expenseSheetId` threaded through, sent on create, and the screen should name
the sheet it is adding to (cycle label) so a previous-cycle target is never a
surprise.

### 3. "Submit for approval" on the Declined banner

`lib/widgets/employee_dashboard/declined_sheet_banner.dart` is deliberately
button-free ("The auto-flow is server-driven", story 01 3.2). That premise
changes: the banner gains a **primary** action calling the new
`POST /api/expensesheets/{id}/submit`.

This is the main route, not an escape hatch. The endpoint clears **every**
declined line on the sheet in one call, so the employee never opens an
individual declined expense to "re-approve" it -- add the forgotten receipt,
tap submit, done. The banner copy has to say that, and the existing
declined-count hint plus the "we will resend it for you when you fix
everything" explainer must be rewritten around the button: as written they
tell the user to go line by line, which is exactly the friction being removed.

Confirm before sending (it leaves the employee's hands), then refresh
`mySheetsProvider` + `sheetDetailProvider`. Handle 403 (not the owner), 409
(wrong status / empty sheet), and the billing 403 block-mode response the
approve/decline CTAs already handle.

### 4. Manager: add an expense from Sheet Review

`lib/screens/sheet_review_screen.dart` gains an "Add expense" action for a
sheet in **WaitingForApproval or Declined only**. Not Draft: managers do not
see Draft sheets, and an employee's Draft is private until they submit it (the
server returns 403 for a manager targeting a Draft). The created line belongs
to the **sheet owner**, not the manager -- the UI must say so, since the
manager is filling a form for someone else's reimbursement.

Hidden on an Approved sheet.

### 5. Sheet Review must mark a line that was declined in an earlier round

**Required, not optional** -- it is the compensating control for a rule this
mission removes. Until now a per-line decline was final: a whole-sheet approve
never revived a Declined line, so the manager could approve a returned sheet
without re-examining it. After FS-1003 a whole-sheet resubmit turns every
declined line back into Pending, and the manager's one-tap sheet approve
**will** approve it. Without a marker they blind-approve lines they already
refused.

The signal needs no new field: the backend preserves `reviewedByUserId` /
`reviewedAt` on the reset lines, so **Pending + non-null `reviewedAt` = "you
returned this line in an earlier round"**. That combination cannot occur
today, so nothing existing reads it. Surface it in Sheet Review's Pending tab
(badge on the line plus, ideally, who returned it and when) and in the
approve-sheet confirm dialog
(`lib/widgets/sheet_review/approve_sheet_confirm_dialog.dart`) as a count:
"3 of these were returned to the employee earlier".

### 6. Approved sheet stays closed

No add affordance anywhere for status 3, on either dashboard.

### 7. Make the cycle visible on both sides

The whole point is that the target sheet is usually **not** the current cycle,
so neither side may leave the cycle implicit:

- employee: the new-expense screen names the sheet/cycle it is filing into
  (section 2), and the picker must not make an old Declined sheet look like
  the current one;
- manager: the queue card and Sheet Review header show the cycle label for a
  resubmitted sheet. Server-side confirmed: a resubmit stamps a fresh
  `submittedAt`, so an old-cycle sheet arrives at the **top** of the queue
  (`SubmittedAt DESC`) -- a manager will otherwise read it as this month's.

## Related

- **Bug: a declined expense cannot be resubmitted without editing a field**
  (`docs/bugs/declined-expense-cannot-be-resubmitted-without-editing-a-field.md`)
  -- the `_isDirty` gate on the expense-detail CTA. Independent fix, same
  screen family, and the same underlying frustration. If FS-1003's whole-sheet
  submit lands first, that bug shrinks to "relabel and stop lying about being
  blocked"; it does not disappear.

## Verified server-side (do not re-check)

Checked against dev, 2026-09-04:

- a previous-cycle Declined sheet **is** returned by `GET /api/expensesheets/me`
  (no cycle filter), and `SheetSelection.nonFinalised`
  (`lib/utils/sheet_utils.dart`) strips only Approved -- so it already reaches
  the picker. The only thing hiding it is the "+ New expense" gate in
  section 1;
- both sheet lists are capped at 12 rows server-side, employee list ordered by
  cycle label descending -- a Declined sheet more than ~12 cycles old is not in
  the payload at all. Do not build UI that assumes every sheet is present;
- an unchanged save on a declined line **is** accepted by the server and does
  resolve the line. The client's `_isDirty` block is entirely self-inflicted
  (see Related).

## Localization

New strings both languages (`lib/l10n/app_en.arb`, `app_he.arb`): the submit
CTA, its confirm/success/failure copy, the "adding to <cycle>" label, and the
manager's "this expense will be filed under <employee>" note.
