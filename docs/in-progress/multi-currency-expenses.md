# Multi-Currency Expenses — Feature Plan

Status: **core + Follow-up 1 shipped.** Submit sends `dynamicAmount`, base-currency
display and live conversion-preview hint are live. Remaining: Follow-up 2 — verify
the AI receipt scan handles foreign currency end to end (ISO code vs symbol, codes
outside the tracked list).
Source of truth (backend): `C:\Projects\XpenseDesk\BackEnd\XpenseDeskServer\docs\guides\flutter-multi-currency-guide.md`

## Goal

Support expenses entered in any supported currency. The user types an amount in
the currency they pick; the **server is the source of truth for conversion** —
it recomputes and stores the base-currency value on save and ignores any
converted figure the app sends. The app shows a **live preview** of the
converted (base-currency) amount as a display-only hint.

## The one rule to internalize

On submit we send only `dynamicAmount` + `currencyCode`. We never send a
converted/base amount or a rate — the server owns those. Any amount the app
converts on screen is cosmetic.

## API contract (what changed)

### Create / Update request — `POST` / `PUT /api/expenses`
- **Renamed:** `amount` → **`dynamicAmount`** (value in `currencyCode`).
- `currencyCode` unchanged — the currency the user picked.
- **Stop sending** any base/converted amount. The old `amount` request field is gone.

### Single-expense response — `GET /api/expenses/{id}`
`amount` is now **always the base currency**. New fields:

| Field | Meaning |
|---|---|
| `amount` | value in **base currency** — always |
| `currencyCode` | currency the user entered (e.g. `"USD"`) |
| `dynamicAmount` | what the user entered, in `currencyCode` |
| `baseCurrencyCode` | the company base, e.g. `"ILS"` |
| `isForeign` | `true` if entered in a non-base currency |
| `rateUsed` | rate applied (null for local) |
| `rateDate` | rate's date (may be earlier than expense date — weekend/holiday carry-forward) |

### Lists, search, sheets, reports
Everything outside the single expense is **base-currency only**.
`GET /api/expenses/search` and the sheet expense list **no longer return
`currencyCode`**; `amount` is the base value. Drop `currencyCode` from those models.

### Live conversion preview — `GET /api/conversion/preview`
Session-token authenticated (`Authorization: Bearer <token>`) — **no** function
secret. (The internal `/api/currency/*` endpoints are secret-gated for ops; do
not call them from the app.)

```
GET /api/conversion/preview?currency=USD&amount=100&date=2026-06-01
```
Response:
```json
{
  "amount": 100, "currency": "USD", "expenseDate": "2026-06-01",
  "baseCurrency": "ILS", "ils": 281.30,
  "rateUsed": 2.813, "rateDate": "2026-06-01",
  "note": "Exact-day rate."
}
```
- `ils` = the converted value to show (semantically "amount in base currency",
  even though the JSON key is literally `ils`). Label it with `baseCurrency`.
- `note`: `"Exact-day rate."` | `"Carried forward from <date>."` | `"Base currency - no conversion."`.
- Short-circuit (no call) when `currency == baseCurrency`.

### Error handling
- A date **before available rate history** → create/update returns **HTTP 400**
  with `errorCode == "ExchangeRateUnavailable"` and a message naming
  currency/date. Show inline; do not proceed.
- Weekends/holidays are fine (server carries last rate forward).

## Screen map

Two editable surfaces — both flow amount/currency/date into the same controllers,
so conversion logic is shared:

| Screen | Role | Inputs | Save button |
|--------|------|--------|-------------|
| `lib/screens/new_expense_screen.dart` | **Create** — manual typing **and** AI reveal (AI populates the same `_amountController` / `_selectedCurrencyCode` / `_selectedDate`) | `_amountController`, `_selectedCurrencyCode`, `_selectedDate` | submit `AppButton`, gated by `_canAttemptSubmit && !_isSubmitting` |
| `lib/screens/employee_expense_detail_screen.dart` | **Edit** — employee edit, manager edit, read-only view (mode flags) | `_amountController`, `_selectedCurrencyCode`, `_selectedDate` | Save `AppButton`, gated by `_canSave && _isDirty && !_isSaving` |

View-only surfaces (sheet review, cycle report, dashboards/charts) show only
base-currency totals — **no conversion UI needed** there.

## Live-preview behavior requirements (editable screens)

1. **Any change to amount / currency / date re-evaluates the conversion** —
   including after an AI reveal populates the fields.
2. The converted amount is a **read-only label**, never a text field — the user
   cannot type it.
3. **While a conversion is running the expense cannot be saved** (button disabled).
4. Each calculation shows a **small inline spinner** in the conversion label.
5. **If conversion fails, show the error message and do not proceed** (save stays
   disabled).
6. Convert to the **company base currency** (`companyBaseCurrencyProvider`,
   derived from `userInfo.currencyCode`) — could be ILS or any supported
   currency. Not hardcoded to ILS.

## Architecture decisions

- **Detail display (foreign expense):** original `dynamicAmount + currencyCode`
  is **primary**; booked `amount + baseCurrencyCode` is **secondary**
  ("@ `rateUsed` on `rateDate`"). Non-foreign: just `amount + baseCurrencyCode`.
- **Shared conversion pieces** (avoid duplicating across the two screens):
  - `ConversionPreviewController` — a `ChangeNotifier` the screen owns in
    `initState`. Holds `{status: idle|loading|success|error, baseAmount,
    baseCurrency, error}`. Debounces amount keystrokes (~450ms); fires
    immediately on currency/date change. Debounce-pending folds into `loading`.
    Exposes `canSave` (true only when `status == success`, or
    `selectedCurrency == base`). **Must dispose + cancel its debounce Timer in
    the screen `dispose()`** to avoid a post-unmount `setState`.
  - `ConversionPreviewLabel` — `StatelessWidget`: base-currency value +
    inline spinner (loading) + error text (error). Read-only.
- **Save gating:** add `&& _conversion.canSave` to each save/submit `onPressed`
  condition.
- **Base-currency rendering in lists:** lists/charts render
  `amount.toCurrency(locale, baseCurrency)` using `companyBaseCurrencyProvider`,
  since per-row `currencyCode` is removed from list models.

## Implementation steps (build + verify + wait between each)

| Step | Change |
|------|--------|
| 1 | Request models: `amount` → `dynamicAmount` in `ExpenseService.createExpense`, `UpdateExpenseRequest` (field + `toJson`), and both call sites; stop sending any base amount |
| 2 | `expense_detail.dart`: add `dynamicAmount`, `baseCurrencyCode`, `isForeign`, `rateUsed`, `rateDate`; document `amount` as base currency |
| 3 | Drop `currencyCode` from `expense_summary.dart`, `expense_sheet_list_item.dart`, `cycle_expense_row.dart`; add `companyBaseCurrencyProvider` (from `userInfo.currencyCode`, default `'ILS'`) |
| 4 | Display: lists/charts render base currency; detail screen original-primary / base-secondary (let `flutter build web` surface every `currencyCode` read site to fix) |
| 5 | Edit form binds amount field to `dynamicAmount` (fallback `amount`); submit sends `dynamicAmount` |
| 6 | Handle `400 ExchangeRateUnavailable` inline (new EN + HE ARB key) |
| 7 | `ExpenseService.convertToBase(currency, amount, date)` → `ApiService.get('/api/conversion/preview', queryParams)`; short-circuit when `currency == base`; returns display-only `(baseAmount, baseCurrency)` |
| 8a | `ConversionPreviewController` (ChangeNotifier: debounce + status + base-currency target) |
| 8b | `ConversionPreviewLabel` widget (read-only label + inline spinner + error text) |
| 8c | Wire into `new_expense_screen.dart` incl. AI-reveal completion path; gate submit on `canSave` |
| 8d | Wire into `employee_expense_detail_screen.dart`; gate Save on `canSave`; trigger when enabling edit |
| 9 | `/code-review` pass per `.claude/commands/code-review.md` |

## Checklist (from backend guide)

- [x] Send `dynamicAmount` instead of `amount`; stop sending any base/converted amount.
- [x] Detail model: add `dynamicAmount`, `baseCurrencyCode`, `isForeign`, `rateUsed`, `rateDate`; treat `amount` as base.
- [x] List/search/sheet models: remove `currencyCode`; render `amount` as base.
- [x] Live preview via `GET /api/conversion/preview` (session token) with rules 1–6 above.
- [x] Handle `400 ExchangeRateUnavailable`.
- [x] Build the currency picker from `trackedCurrencies` on `GET /api/company` — Follow-up 1, shipped.

Core shipped in `fdfb445` / `6df2e25`; Follow-up 1 shipped after. Follow-up 2 still open.

---

## Follow-ups (pending — not yet implemented)

### Follow-up 1 — Load currencies from the backend (stop hardcoding) — DONE

Shipped: `TrackedCurrency` model, `CompanyInfo.trackedCurrencies`,
`trackedCurrenciesProvider` (company-sourced, base-only fallback while loading),
all three pickers migrated, new-expense default = base currency.
`ExpenseCurrency` no longer used by any live picker (only the unused
`expense_form.dart` still references it).


**Problem.** The currency picker is currently hardcoded in
`lib/models/expense_currency.dart` (`ExpenseCurrency.values` — AUD/CAD/EUR/GBP/ILS/USD).
Per the backend guide ("Where the currency picker comes from"), the list must come
from the server so it always matches what the server can actually convert, and can
grow without an app release.

**Source.** `GET /api/company` now returns a **`trackedCurrencies`** array (derived
from the company country → currency provider, e.g. Israel → Bank of Israel):

```json
"trackedCurrencies": [
  { "currencyCode": "ILS", "currencyName": "Israeli Shekel", "currencySymbol": "₪", "isBaseCurrency": true },
  { "currencyCode": "USD", "currencyName": "US Dollar",      "currencySymbol": "$", "isBaseCurrency": false }
]
```

| Field | Use |
|---|---|
| `currencyCode` | value sent as the expense `currencyCode` |
| `currencyName` | dropdown display name |
| `currencySymbol` | dropdown / amount-field prefix |
| `isBaseCurrency` | exactly one true; the company base. Server already returns it first |

**Work.**
- Add `trackedCurrencies` (`List<TrackedCurrency>`) to the company model + `fromJson`
  (the `GET /api/company` model — `CompanyInfo` / wherever the company fetch lands).
- Expose a provider (e.g. `trackedCurrenciesProvider`) sourced from the loaded company.
- Replace `ExpenseCurrency.values` usage in the three pickers
  (`new_expense_screen`, `employee_expense_detail_screen`, `mobile_expense_modal`)
  with the tracked list; lead with / default to the `isBaseCurrency` entry.
- Derive the base currency for `companyBaseCurrencyProvider` from the
  `isBaseCurrency` entry (it currently reads `userInfo.currencyCode`, default `'ILS'`).
- Once migrated, retire `ExpenseCurrency` (or keep only as an offline fallback).
- Re-check: the live-preview base comparison and the `'ILS'` literal fallbacks should
  defer to the tracked base entry.

**Acceptance.** Picker is server-driven; adding a provider currency on the backend
shows up without an app release; no hardcoded currency list remains in widget code.

### Follow-up 2 — Verify AI receipt scan handles foreign currency

**Question.** When the AI scanner reads an invoice denominated in a non-base
currency (e.g. USD), does the app correctly treat it as foreign end to end?

**Current code (to verify, not yet confirmed end to end):**
- `ReceiptAnalysisResult` parses `currencyCode` from JSON key **`currency`**
  (`lib/models/receipt_analysis_result.dart`).
- `new_expense_screen` AI-reveal sets
  `_selectedCurrencyCode = result.currencyCode ?? 'ILS'` and the amount into
  `_amountController`, then (post-fix) calls `_evaluateConversion()`.

**Things to check during manual testing:**
1. Does the analyze-receipt API actually return a `currency` for a USD invoice, and
   in what shape (`"USD"` vs `"$"` vs null)?
2. If it returns a code **not in the picker list** (e.g. `JPY` while hardcoded list
   lacks it), the `DropdownMenu.initialSelection` won't match an entry → blank/odd
   picker. (Follow-up 1 — server-driven list — largely resolves this.)
3. Does the conversion preview fire after the AI reveal for a USD scan (≈ base shown)?
4. On save, is `dynamicAmount` (scanned USD amount) + `currencyCode: USD` sent, and
   does the detail screen then show it as foreign (original primary / base secondary)?
5. Symbol vs code mismatch: confirm the API returns an ISO code, not a symbol — if it
   returns `"$"` the picker/convert calls would break.

**Acceptance.** A USD receipt scan results in a foreign expense: USD shown as
entered, base-currency preview while editing, server books the converted base value,
detail view shows original + booked.
