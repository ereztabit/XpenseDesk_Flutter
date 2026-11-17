# Budgets (Petty Cash) - API Guide

> Mission: FS-1012 PC-1. Story: docs/petty-cash/pc-1-budget-sheet.md.
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

## Monthly is untouched

Budget sheets have no cycle and never appear in any Monthly call (sheets,
queue, dashboard counters, payments, reports, cycle close).
