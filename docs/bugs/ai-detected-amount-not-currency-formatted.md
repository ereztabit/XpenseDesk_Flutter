# Bug: AI Detected Details Card Shows Unformatted Amount Instead of Currency Format

> **Status: new**

## Problem

After scanning a receipt with AI on the New Expense screen, the "Detected
details" (Hebrew: "פרטים שזוהו") summary card shows the detected amount as a
raw number followed by the ISO currency code, e.g. `1880.00 ILS`. Everywhere
else in the app amounts are shown with a thousands separator and the currency
symbol, so this card should show `₪1,880.00`.

Two formatting defects in one value:

1. No thousands grouping - `1880.00` instead of `1,880.00`.
2. Currency code instead of symbol - `ILS` instead of `₪` (and positioned
   after the number instead of the symbol-first convention used app-wide).

This also violates the project code-review rule #3: "No hardcoded currency
symbols - every amount uses `num.toCurrency(companyLocale, currencyCode)`".

## Reproduce Steps

1. Log in as an employee and open the New Expense screen.
2. Upload a receipt image with an amount of 1,880.00 ILS (e.g. the demo
   "DEMO OFFICE SUPPLIES LTD" receipt) and let the AI scan complete.
3. Look at the amount field in the "Detected details" summary card.
   -- Expected: `₪1,880.00` (symbol + thousands-separated amount, formatted
      per the company locale, same as everywhere else in the app).
   -- Actual: `1880.00 ILS` (raw `toStringAsFixed(2)` plus the ISO code).

## Suggested Solution Approach

The detected-amount value in the AI summary card should be rendered through
the same company-locale currency formatting used across the rest of the app,
so the user sees one consistent money format everywhere.

## Suggested Fix

`_buildDetectedSummary` in `lib/screens/new_expense_screen.dart` (around
lines 1147-1151) builds the amount text manually:

```dart
final amountText = result?.amount != null && result?.currencyCode != null
    ? '${result!.amount!.toStringAsFixed(2)} ${result.currencyCode}'
    : ...
```

Replace with the `CompanyCurrencyFormat` extension from
`lib/utils/format_utils.dart`, e.g.
`result!.amount!.toCurrency(companyLocale, result.currencyCode!)` - the
`companyLocale` is already passed into the method. Decide the fallback for the
code-less branch (amount detected but no currency): plain
`toFormattedNumber(companyLocale)` keeps the grouping without inventing a
symbol.

Note: the summary card intentionally shows the *detected* currency (which may
be foreign), so the symbol must be derived from `result.currencyCode`, not
from the company base currency.
