# Bug: Payments table caption is misleading — should be a "found sheets" summary

> **Status: new**

## Problem

The caption above the payments table reads "בחרו גליונות לעיבוד תשלום" ("choose
sheets for payment processing"). This is misleading: under the Processed/All
views there is nothing to choose, so an instruction to "select" makes no sense.
The caption should instead summarize the result set — how many sheets and the
total amount.

## Reproduce Steps

1. Open the Payments Report (manager).
2. Look at the caption directly above the table.
   -- Expected: a neutral results summary, e.g. "גליונות שנמצאו (30 | 1200 שקל)".
   -- Actual: "בחרו גליונות לעיבוד תשלום" — implies a selection action even when
      none is possible.

## Suggested Solution Approach

Replace the instructional caption with a results summary: count of rows found +
combined amount, formatted in the company locale/currency.

## Suggested Fix

- The caption is `l10n.selectSheetsCaption`, rendered in
  `lib/widgets/payments/desktop_payments_view.dart` and
  `lib/widgets/payments/mobile_payments_view.dart`.
- Replace with a new "found sheets" line that concatenates a localized label +
  the row count + total amount via `num.toCurrency(companyLocale, currencyCode)`
  (separate `Text` runs for RTL safety, per the no-mixed-direction rule).
- Total amount: reuse the existing selection-total util pattern over all loaded
  rows (`PaymentsSelectionUtils`), or sum `rows` directly in a util.
- Add the new ARB keys to `app_en.arb` + `app_he.arb`; retire
  `selectSheetsCaption` if unused.
