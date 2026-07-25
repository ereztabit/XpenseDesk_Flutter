# Payment Status — Flutter Integration Guide

Audience: the Flutter team building the dashboard "Awaiting Payment" card and the
Payments Report screen (web + mobile).

This is the API **contract** for the Payment Status feature
(`docs/payment-status-spec.md`). The backend is being built against this exact
shape — if anything here doesn't fit the client, raise it now, not after.

Every response uses the standard envelope:
`{ "success": bool, "message": string, "errorCode": string|null, "data": ... }`.
All endpoints below are **manager-only** (403 for any other role).

---

## 1. The mental model (read this first)

- A sheet's **payment status is computed by the server**, never set directly:
  - Sheet `Approved` + approved-lines total > 0 + no processed record -> `AwaitingPayment`
  - Sheet `Approved` + processed record -> `Processed`
  - Anything else -> the sheet simply never appears in any payment view.
- **You never "create" a payment status.** Approving a sheet makes it Awaiting
  automatically. Zero-amount approved sheets (e.g. a fully-declined sheet that was
  closed) never enter the payment world — do not expect them in lists or counts.
- **Processed is not terminal.** Date / reference / note are editable any time, and
  a sheet can be reverted to Awaiting. Every change is appended to the sheet's
  existing activity log (the same log you already render on sheet detail — payment
  events appear there as Approved -> Approved entries with a descriptive comment).

## 2. Dashboard card — zero extra calls

The card's data is in the company profile you already load:

`GET /api/company` ->
```jsonc
{
  ...existing fields...,
  "paymentsSummary": { "awaitingCount": 3, "awaitingTotalAmount": 1152.00 }
}
```

- **Managers only** — for employees `paymentsSummary` is `null`. Code defensively:
  treat `null` as "do not render the card".
- Zero state: `{ "awaitingCount": 0, "awaitingTotalAmount": 0.00 }` — card stays
  visible per the product spec.
- **Freshness rule: never refetch `/api/company` after a payment action.** Every
  payment WRITE response (process / update / bulk-update) carries a fresh
  `paymentsSummary` — update the card state from that.

## 3. The report list

`GET /api/payments?paymentStatus=2&userId=&cycleId=&approvedFrom=&approvedTo=&processedFrom=&processedTo=&page=1&pageSize=25`

Filter params (all optional, ANDed; apply on explicit Search, per UX):

**Enum convention (intentional, matches the rest of the API):** in QUERY PARAMS
payment status is an int id (`1` = AwaitingPayment, `2` = Processed — same pattern
as `statusId` on the sheet lists); in RESPONSES and WRITE BODIES it is the string
name (`"AwaitingPayment"` / `"Processed"` — same pattern as `subscriptionStatus`).

| Param | Type | Maps to UX filter | Notes |
|---|---|---|---|
| `paymentStatus` | int | Payment Status dropdown | omit = All, `1` = AwaitingPayment, `2` = Processed |
| `approvedFrom` / `approvedTo` | date (`yyyy-MM-dd`) | Approval Date range | range on the sheet's approval date, boundaries inclusive |
| `userId` | guid | Employee dropdown | |
| `cycleId` | guid | Cycle dropdown | |
| `processedFrom` / `processedTo` | date | Processed Date range | Awaiting rows NEVER match this range (they have no processed date) |
| `page` / `pageSize` | int | paging | pageSize clamped to 100 server-side |

Response `data` — same paged envelope as the sheet lists:

```jsonc
{
  "items": [
    {
      "expenseSheetId": "guid",
      "createdByUserId": "guid",
      "employeeName": "Dana Levi",
      "employeeGovId": "012345678",     // null -> render a dash
      "employeeEmail": "dana@acme.com",
      "cycleLabel": "2026/04",          // the sheet's ORIGINAL cycle
      "approvedDate": "2026-05-02T08:11:00",
      "amount": 384.00,                 // approved lines only, company currency (ILS)
      "paymentStatus": "AwaitingPayment",   // or "Processed"
      "processedDate": null,            // date, set when Processed
      "reference": null,                // accounting batch id
      "note": null                      // returned so the edit modal can prefill
    }
  ],
  "page": 1, "pageSize": 25, "totalCount": 7, "hasMore": false,
  "pageTotalAmount": 1152.00, "grandTotalAmount": 1152.00
}
```

Display rules already decided: `employeeGovId` null -> dash; `processedDate` /
`reference` null -> dash; `amount` is bold/right-aligned in ILS; an employee can
appear in multiple rows (one row per sheet — the Jan/Feb/Mar lazy-manager case is
three rows, each with its own original `cycleLabel`).

Row tap -> your existing read-only sheet detail screen (`GET /api/expense-sheets/{id}`).
The detail response will additionally include the four payment fields
(`paymentStatus`, `processedDate`, `reference`, `note`) so the badge can render there.

## 4. Mark as Processed (the confirmation modal)

`POST /api/payments/process`
```jsonc
{
  "expenseSheetIds": ["guid", "guid"],
  "processedDate": "2026-06-15",   // required; defaults to today IN THE CLIENT
  "reference": "PAY-042",          // optional
  "note": "June payroll run"       // optional
}
```

Rules:
- Only sheets currently `AwaitingPayment` may be in the array (the UI already
  prevents selecting Processed rows — the server enforces it too).
- **All-or-nothing.** If ANY sheet in the array is invalid (already processed,
  not approved, not yours), the WHOLE batch fails and nothing changes. The error
  response lists the offending sheet ids in `data` so you can highlight them.
- Max **100 ids** per call; 101+ is a 400 (you will not hit this from a single page).

Success response `data`:
```jsonc
{
  "processedCount": 2,
  "paymentsSummary": { "awaitingCount": 1, "awaitingTotalAmount": 175.45 }
}
```
Refresh the table in place and update the dashboard card from `paymentsSummary`.

## 5. Edit / revert

Single sheet:
`PUT /api/payments/{expenseSheetId}`
Bulk (same body + id array):
`POST /api/payments/bulk-update`

```jsonc
// EDIT processed details (sheet(s) must be Processed):
{ "paymentStatus": "Processed", "processedDate": "2026-06-16",
  "reference": "PAY-042b", "note": "corrected date" }

// REVERT to awaiting (explicit — this is the undo):
{ "paymentStatus": "AwaitingPayment" }
```

Rules:
- `paymentStatus` is REQUIRED and explicit. `"Processed"` without a
  `processedDate` is a 400 — the server never treats a missing date as a revert.
- Revert clears date/reference/note server-side; the sheet reappears as Awaiting.
- Targets must currently be `Processed` (you cannot "update" an Awaiting sheet —
  that's what /process is for). Bulk is all-or-nothing like /process.
- Every response carries the fresh `paymentsSummary` like section 4.

## 6. Excel exports — two distinct buttons

| Button in UX | Endpoint | Body |
|---|---|---|
| **Export All** (filter bar) | `POST /api/reports/export-payments-report` | the SAME filter params as the list (status, employee, cycle, both date ranges). Server exports the full filtered set — you do NOT collect ids across pages |
| **Export selected** (bulk bar) | `POST /api/reports/bulk-export-payments-report` | `{ "expenseSheetIds": [...] }`, max 100 |

Both return an `.xlsx` file (binary download) with columns: Employee Name, Gov ID,
Email, Cycle, Approved Date, Amount, Payment Status, Processed Date, Reference.

## 7. Error codes you must handle

| Code | When | Suggested UI |
|---|---|---|
| `PaymentBulkLimitExceeded` | more than 100 ids in one call | "Too many sheets selected" |
| `PaymentSheetNotAwaiting` | /process batch contains a non-awaiting sheet (`data` lists offending ids) | refresh table, highlight rows, re-prompt |
| `PaymentSheetNotProcessed` | update/revert targets a sheet that is not Processed | refresh table |
| `ExpenseSheetNotFound` | id doesn't exist or belongs to another company | refresh table |
| `MandatoryFieldsMissing` | processedDate missing on Processed-status write | inline field validation |
| `SubscriptionRequired` (403) | company is payment-locked (block mode) — applies to all WRITE endpoints | existing locked-company UX |
| plain 403 | caller is not a manager | should never happen from manager screens |

Stale-data note: another manager may process/revert sheets while the screen is open.
The all-or-nothing failures above are your concurrency signal — on any 4xx from a
bulk action, refetch the current filter and re-render before retrying.

## 8. Quick recipes

- **Dashboard load:** read `paymentsSummary` from the `GET /api/company` you already
  make. Null -> no card (non-manager).
- **Open report screen:** `GET /api/payments?paymentStatus=1&page=1` (Awaiting is
  the default filter per UX).
- **Process flow:** select rows -> modal -> `POST /process` -> on success refresh
  rows in place + update card from response. On `PaymentSheetNotAwaiting` ->
  refetch, highlight `data` ids.
- **Fix a typo in a reference:** row action -> `PUT /api/payments/{id}` with
  `paymentStatus: "Processed"` + corrected fields.
- **Undo a payroll run:** select the processed rows of that run (filter by
  Processed + reference) -> `POST /bulk-update` with
  `{ paymentStatus: "AwaitingPayment" }`.
- **Export All vs selected:** filter-bar button sends filters; bulk-bar button
  sends ids. Never page-walk to build an Export All.

## 9. What does NOT exist (so nobody goes looking)

- No DELETE endpoint — revert is the explicit update above.
- No per-employee rollup endpoint — the report is one row per sheet; Excel serves
  the accountant.
- No currency field — all amounts are company base currency (ILS).
- No payment data for employees anywhere — employee-facing screens are unchanged.
