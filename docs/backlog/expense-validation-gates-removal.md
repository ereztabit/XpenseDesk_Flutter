# Expense validation gates removal

## Problem / request

Expense entry (new expense + edit expense) currently requires amount, date,
merchant, and category before submit is allowed. Going forward, **price and
date are the only mandatory fields** — merchant, category, note, receipt ref
etc. all become optional.

## Scope

- `lib/screens/new_expense_screen.dart` — remove the `merchant` requirement
  from `_canAttemptSubmit`/`_canSubmit`, drop the merchant `errorText`/required
  asterisk, drop the category "shake + scroll to + categoryRequired" reminder
  behavior and its required asterisk. Amount + date remain required exactly as
  today.
- `lib/screens/employee_expense_detail_screen.dart` (edit expense) — same
  mandatory-field reduction for its validation gates.
- Server submit path (`ExpenseService.createExpense` / update expense request)
  — when `categoryId` is null at submit time, default it to `5` ("Other")
  instead of blocking submit or sending null.

## Out of scope / open questions

- Confirm category id `5` maps to "Other" in `lib/models/expense_category.dart`
  before wiring the default.
- Confirm backend accepts/expects a non-null categoryId on create (i.e. that
  the client-side default is the right layer, vs. the server defaulting it).
