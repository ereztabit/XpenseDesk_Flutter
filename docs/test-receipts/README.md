# Synthetic Test Receipts — Multi-Currency AI Scan (Follow-up 2)

Six generated receipt images for verifying that the AI receipt scan handles
foreign currency end to end (ISO code vs symbol, codes outside the tracked
list). See docs/backlog/multi-currency-expenses.md.

Regenerate after editing `receipts.json`:

```
powershell -ExecutionPolicy Bypass -File generate_receipts.ps1
```

These live under `docs/` (not `assets/`) on purpose — they must never be
bundled into the app build.

## Test matrix

| # | File | Currency on receipt | Tracked? | What to verify |
|---|------|--------------------|----------|----------------|
| 1 | 01_ils_hebrew.png | ₪ symbol, Hebrew text | Base (ILS) | Base currency selected; amount 87.50; no conversion hint |
| 2 | 02_usd_symbol_only.png | `$` symbol only — the word "USD" appears nowhere | Yes (USD) | AI normalizes `$` to ISO `USD`; dropdown shows USD; live ILS conversion hint appears; amount 42.75 |
| 3 | 03_eur_symbol.png | `€` symbol only | Yes (EUR) | Same as #2 for EUR; amount 31.20 |
| 4 | 04_gbp_untracked.png | `£` symbol | **No** | Graceful handling: fallback to base or clear signal. NOT an empty currency dropdown that silently submits "GBP" |
| 5 | 05_jpy_untracked.png | `¥` symbol, zero-decimal amounts (2,400) | **No** | Same as #4 + amount parsed correctly despite no decimal point and thousands comma |
| 6 | 06_no_currency.png | None — plain numbers | n/a | Falls back to company base currency (the `?? base` path); amount 45.00 |
| 7 | 07_no_currency_mixed_formats.png | None, and five different number styles | n/a | Total is `3.838,58` (European) = **3838.58**; line items repeat 1234.56 as `1,234.56`, `1.234,56` and `1 234,56`. Amount parsed correctly, and the detected-details card shows a grouped number with **no** symbol |
| 8 | 08_merchant_no_amount.png | None — a delivery note with no prices at all | n/a | Merchant and date detected, no amount: the detected-details card shows `—` for the amount and stays a summary (it must NOT fall through to the plain form — that only happens when *nothing* is read) |

| 9 | 09_no_date.png | ₪ symbol (base) | Base (ILS) | Amount 247.50 reads fine, and **no date appears anywhere** — no printed date, and nothing date-shaped in the ticket number to latch onto. Panel must open editable with the Date field red. If the AI invents today's date instead of returning null, that is itself a finding |

Receipts 7-9 were added for the New Expense entry improvements QA
(`docs/in-progress/new-expense-entry-improvements-QA.md`); 2, 3 and 4 double as
the USD / EUR / untracked-currency cases for that same round.

Note: #2/#3 assume the dev company tracks USD/EUR and #4/#5 assume it does NOT
track GBP/JPY — check the company's `trackedCurrencies` first and read the
results accordingly.

## What to check on every scan

1. **AI box** — detected amount + currency as displayed.
2. **Currency dropdown** — which entry is selected (or whether it is empty).
3. **Conversion preview** — the base-currency hint (or its error state) for
   foreign currencies.
4. **Submit payload** — `currencyCode` + `dynamicAmount` in the POST
   /api/expenses request (browser network tab).
5. **Saved expense** — server-computed base `amount`, `rateUsed`, `isForeign`
   on the created expense.

## Known client seam (from the static audit)

The scan result's `currency` is pushed into `_selectedCurrencyCode` verbatim
(`lib/screens/new_expense_screen.dart`), with no validation against
`trackedCurrencies`. An out-of-list code (or raw symbol) will not match any
dropdown entry but WOULD still be submitted. Receipts #4/#5 exercise exactly
this seam.
