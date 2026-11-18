# Budgets (Petty Cash) - API Guide

> Mission: FS-1012 PC-1. Story: docs/done/pc-1-budget-sheet.md.
> Same file in the Flutter repo: docs/api-guides/budgets-api-guide.md.
> S1 (a budget exists): create, manager list, read one. S2 / S3 append to
> this guide; nothing here changes meaning later (additive only).

A budget is an expense sheet of the PettyCash module: a named amount given to
one holder (any active user, managers included) until an end date. On screen
the module is "Budgets"; API names stay `budgets` / `PettyCash`. All bodies use
the common `ApiResponse` envelope (`success`, `message`, `errorCode`, `data`).

## Gate

Every call needs Budgets on for the company: the platform admin flag
(`configuration.isPettyCashEnabled` on `GET /api/company`) **and** the
`PettyCash` module switched on (`modules[]` on the same call). Otherwise every
call returns **403 `BudgetsNotEnabled`**.

## The budget object

```json
{
  "budgetId": "8f0c...",
  "number": 1001,
  "name": "Events Q4",
  "holderUserId": "5b1e...",
  "holderName": "Dana Levi",
  "holderEmail": "dana@acme.co.il",
  "statusId": 1,
  "initialAmount": 2500.00,
  "budgetAmount": 2500.00,
  "spentAmount": 0.00,
  "balance": 2500.00,
  "endDate": "2026-12-31",
  "currencyCode": "ILS",
  "createdAt": "2026-11-17T09:12:44.123",
  "submittedAt": null,
  "reviewedAt": null
}
```

| Field | Meaning |
|---|---|
| `budgetId` | The budget's expense sheet id |
| `number` | Per-company running number, 1001 first. Show as `#1001` |
| `holderName` | May be `null` (user without a full name) - fall back to `holderEmail` |
| `statusId` | Sheet statuses: 1 Draft (shown "Draft", same as Monthly), 2 Awaiting approval, 3 Approved, 4 Returned |
| `budgetAmount` | Initial amount + top-ups (top-ups arrive in PC-2; equals `initialAmount` until then) |
| `spentAmount` | The budget's expenses, declined lines excluded (always 0 in S1) |
| `balance` | `budgetAmount - spentAmount`; can be negative |
| `endDate` | Date only, `yyyy-MM-dd`. Overdue = outstanding and today (company date) is after it |
| `currencyCode` | The company currency |

Derived on the client (business rules in the UX hand-off section 5): outstanding
= status not Approved; needs attention = outstanding and (balance < 0 or
overdue); used % = spent / budget.

## Calls

| Method + path | Who | Body / query | `data` |
|---|---|---|---|
| `POST /api/budgets` | Manager | `{ "name", "holderUserId", "initialAmount", "endDate" }` | the new budget |
| `GET /api/budgets` | Manager | optional `?holderUserId=<guid>&search=<text>` | outstanding budgets (not Approved), ordered by end date then number |
| `GET /api/budgets/{budgetId}` | Manager (any budget) or the holder (own) | - | the budget, any status |

**Create.** `name` trimmed, 1-100 characters, unique per company across all its budgets, any status (case-insensitive). `initialAmount` > 0.
`endDate` today or later in the company's time zone. The new budget is Draft,
gets the next number, and its "Budget created" audit row names the manager.
The holder can be the manager themself.

**List.** All outstanding budgets of the company. `search` matches the budget
name, the `#number` (with or without `#`, partial) or the holder's name /
email. The client may also filter locally - the list is small.

## Error codes

| Code | Status | When |
|---|---|---|
| `BudgetsNotEnabled` | 403 | Flag off or PettyCash module off |
| `BudgetAccessDenied` | 403 | An employee creates or lists budgets, or reads someone else's |
| `BudgetNotFound` | 404 | No such budget in the company (deleted, another company's, a Monthly sheet id) |
| `BudgetNameRequired` | 400 | Name missing or blank |
| `BudgetNameTooLong` | 400 | Name over 100 characters |
| `BudgetNameAlreadyExists` | 409 | Another budget of the company has this name, any status (case-insensitive; only a deleted budget frees its name) |
| `BudgetHolderRequired` | 400 | `holderUserId` missing |
| `BudgetHolderNotActive` | 400 | Holder is not an active user of the company |
| `BudgetAmountRequired` | 400 | `initialAmount` missing |
| `BudgetAmountInvalid` | 400 | `initialAmount` not above 0 (or absurdly large) |
| `BudgetEndDateRequired` | 400 | `endDate` missing |
| `BudgetEndDateInPast` | 400 | `endDate` before the company's today |

Validation order: name, holder, amount, end date, then holder active, end date not past, name free - the first failing check
answers.

## S2a - expenses on a budget

No new expense endpoints: the existing expense calls take a budget as their
sheet. `budgetId` **is** the sheet id.

| Call | Budget behaviour |
|---|---|
| `GET /api/budgets/mine` | Any role. The caller's own outstanding budgets (same object, same order) - for the nav |
| `GET /api/expense-sheets/{budgetId}` | The budget with its expenses - the same sheet-detail shape as Monthly. On a budget `moduleId` = 2 and the cycle fields (`expenseCycleId`, `cycleLabel`, `cycleStartAt`, `cycleEndAt`, `cycleStatus`) are `null`. Manager or the holder; others 404. A deleted budget is 404 |
| `POST /api/expenses` | Send `expenseSheetId` = the budget id. The holder **or any manager** may add (else 403 `BudgetAccessDenied`). The line is owned by the holder and stays Pending (a budget is approved as a whole, S3). `categoryId` must be an active **PettyCash** category; `null` = the Budgets "Other" |
| `PUT /api/expenses/{id}` | Same rules for a line on a budget. Editable until the budget is Approved (also while Awaiting approval) |
| `DELETE /api/expenses/{id}` | Same rules. Deleting the last line never removes the budget |

Every other field and rule of these calls (date, amount, currency
conversion, receipt image, free-receipt limit) is unchanged. Without
`expenseSheetId` a create still lands on the caller's Monthly sheet.

**Balance.** When the company does not allow a negative balance (the PettyCash
module setting `allowNegativeBalance` false or unset), a create or an amount
raise that would take the balance below zero is refused with 409
`BudgetBalanceExceeded` and `data: { "balance": 420.00 }` - what is left now,
in the company currency. Lowering an amount is never refused.

### S2a error codes

| Code | Status | When |
|---|---|---|
| `BudgetsNotEnabled` | 403 | Budgets were switched off for the company (flag or module) |
| `BudgetAccessDenied` | 403 | Not the holder and not a manager (checked before any status) |
| `BudgetNotFound` | 404 | The budget was deleted |
| `BudgetApprovedClosed` | 409 | The budget is approved - its expenses are frozen |
| `BudgetExpenseCategoryNotAvailable` | 400 | The category is not an active Budgets category |
| `BudgetBalanceExceeded` | 409 | Below zero and not allowed; `data.balance` |

## S2b - bulk upload into a budget, and free receipts

**Bulk.** `POST /api/bulk-uploads` takes an optional `budgetId` next to
`files`. Every receipt of the batch is filed into that budget instead of the
sender's Monthly sheet, exactly as a single `POST /api/expenses` with
`expenseSheetId` would. Staging (`POST /api/bulk-uploads/files`) and the batch
list (`GET /api/bulk-uploads`) are unchanged; the batch belongs to its sender.

```json
{ "files": [ { "stagedFileId": "...", "originalFileName": "a.jpg" } ], "budgetId": "3f2a..." }
```

The batch is checked whole before anything is queued - refused, never cut
short: Budgets usable (403 `BudgetsNotEnabled`), the budget exists (404
`BudgetNotFound`), the holder or a manager (403 `BudgetAccessDenied`), not
approved (409 `BudgetApprovedClosed`), then free receipts (below). Per receipt,
a budget rule that refuses the line (balance, closed or deleted meanwhile) ends
that file `Unreadable` with the budget code as its `failureCode` - e.g.
`BudgetBalanceExceeded` - and no expense. A receipt read only in part is filed
flagged Action Required on the budget, as on Monthly.

**Free receipts.** A budget's expenses are owned by its holder, so they use the
**holder's** free receipts, whoever files them - a single expense and a batch
alike; the files of a batch still being read count against the holder too.
`GET /api/users/me/free-receipts` is unchanged (the caller's own). When the
holder is the caller the refusals are the usual `FreeReceiptsUsedUp` /
`FreeReceiptsNotEnough`; when a manager files into someone else's budget:

| Code | Status | When |
|---|---|---|
| `BudgetHolderFreeReceiptsUsedUp` | 403 | The holder has no free receipts left; `data.freeReceiptsLeft` = 0 |
| `BudgetHolderFreeReceiptsNotEnough` | 403 | The batch has more files than the holder has left; `data.freeReceiptsLeft` = the holder's |

## Monthly is untouched

Budget sheets have no cycle and never appear in any Monthly call (sheets,
queue, dashboard counters, payments, reports, cycle close). Budget expenses
have no cycle either and never appear in Monthly sheets, totals or reports.

## S3 - submit and review

| Call | Behaviour |
|---|---|
| `POST /api/budgets/{budgetId}/submit` | The **holder** sends a Draft or Returned budget for approval; returns the budget object. A manager's own budget comes back **Approved** (approved on submit, the Monthly rule). Editing stays open while Awaiting approval |
| `POST /api/expense-sheets/{budgetId}/approve` | The existing sheet call. Approves the budget and its pending lines; Approved closes it. A budget is **prepaid**: it never enters the payment lifecycle (`paymentStatus` stays `null`) |
| `POST /api/expense-sheets/{budgetId}/decline` | The existing sheet call, `{ "comment": "..." }` required. Returns the budget to its holder; **its lines stay Pending** (a Monthly decline still declines them) so the holder edits and resubmits |
| `GET /api/expense-sheets/{budgetId}` | `log` is the Activity trail: to-status 1 = created (by the manager), 2 = submitted, 4 = returned (`comment` = the reason), 3 = approved. `latestDeclineComment`, `submittedAt`, `reviewedAt` feed the status strips |

Line-level review is PC-2: `POST /api/expenses/{id}/approve` or `/decline` on
a budget line is refused with 409 `BudgetLineReviewNotAvailable`.

Budgets never appear in the Monthly queue, company sheet lists, counters,
payments or payment reports (ModuleId = 1 guards).

### S3 error codes

| Code | Status | When |
|---|---|---|
| `BudgetAccessDenied` | 403 | Submit by anyone but the holder (a manager included) |
| `BudgetSubmitNotAllowed` | 409 | The budget is not Draft or Returned (already submitted, or approved) |
| `BudgetHasActionRequired` | 409 | An expense on it still needs action (a bulk receipt read only in part) |
| `BudgetLineReviewNotAvailable` | 409 | Approving or declining one line of a budget |
| `BudgetNotFound` / `BudgetsNotEnabled` | 404 / 403 | As in S1 |
