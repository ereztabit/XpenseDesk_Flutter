# Multi-Currency Expenses — Feature Plan

Status: **planned, not started**
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

- [ ] Send `dynamicAmount` instead of `amount`; stop sending any base/converted amount.
- [ ] Detail model: add `dynamicAmount`, `baseCurrencyCode`, `isForeign`, `rateUsed`, `rateDate`; treat `amount` as base.
- [ ] List/search/sheet models: remove `currencyCode`; render `amount` as base.
- [ ] Live preview via `GET /api/conversion/preview` (session token) with rules 1–6 above.
- [ ] Handle `400 ExchangeRateUnavailable`.
