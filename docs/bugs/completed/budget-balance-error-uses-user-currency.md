# Bug: Budget "not enough balance" amount shown in the user's currency

> **Status: done**

Found in the PC-1 (FS-1012) finish code review, 2026-11-18. Fix in PC-2 (FS-1013).

## Problem

When an expense would take a budget below zero, the server refuses it with
`BudgetBalanceExceeded` and the balance left. The app formats that amount in the
signed-in user's currency, falling back to a hardcoded `'ILS'`, instead of the
budget's own currency. If the user's currency is not the budget's, the message
shows the right number with the wrong currency sign.

## Reproduce Steps

1. A user whose profile currency differs from the company base currency holds a
   budget (budgets are in the company currency).
2. On the budget, add an expense larger than the balance left.
   -- Expected: "only X left" with the budget's currency.
   -- Actual: X is shown with the user's currency (or ILS if unset).

## Suggested Solution Approach

The refusal amount always reads in the budget's currency.

## Suggested Fix

- `lib/screens/new_expense_screen.dart:722` and
  `lib/screens/employee_expense_detail_screen.dart:210` pass
  `ref.read(userInfoProvider)?.currencyCode ?? 'ILS'` to `budgetExpenseErrorText`.
- Pass the budget's `currencyCode` (the new-expense screen has the budget id; the
  detail screen can read the budget), falling back to
  `companyBaseCurrencyProvider` (`lib/providers/auth_provider.dart:224`). No
  hardcoded currency (CR rule 3).

## Resolution

Fixed in FS-1013 PC-2, shipped as v1.50 (2026-11-18). The new-expense screen
uses the budget's `currencyCode` (`_budgetCurrency()` in
`lib/screens/new_expense_screen.dart`), the expense detail screen reads the
line's budget the same way (`employee_expense_detail_screen.dart`), both
falling back to `companyBaseCurrencyProvider`. Commit 62f4d42.
