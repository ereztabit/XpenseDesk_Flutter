# Flutter Client Discovery — ExpenseSheets, Expenses, Company

**Audience:** Flutter app team integrating against `XpenseDeskServer` after Story 1 (Expense Sheets) Part 2 shipped.

**Server base path:** `/api`

**Auth:** All endpoints below require `Authorization: Bearer <session-token>` unless explicitly noted.

**Envelope:** Every response is wrapped in:

```jsonc
{
  "success":   true | false,
  "message":   "Human readable",
  "errorCode": "<ApiErrorCodes enum value> | null",
  "data":      <payload> | null
}
```

A non-2xx status always sets `success=false` and usually `errorCode` (string from the `ApiErrorCodes` enum). `data` may carry structured context (e.g., the expense id that conflicts).

---

## 0. The concept of Expense Sheets

Before reading the endpoint specs, internalize the model. Everything below the line follows from this section.

### 0.1 The big idea

An **expense sheet** is a container that groups one employee's expenses for one cycle. Approval happens at the *sheet* level, not per-expense. The goal is to give the manager **one decision per employee per month** — sign off on the whole monthly report at once — with the per-expense decision available as an escape hatch when only some items are problematic.

The mental model: a sheet is the **monthly expense report**. The employee fills it out implicitly (every expense they file lands on the current draft sheet automatically), the system "submits" it on cycle-close day, and the manager signs off on the whole thing.

The old per-expense `Pending → Approved → reopen` flow is replaced. The new flow is sheet-centric.

### 0.2 Vocabulary

| Term | Meaning |
|------|---------|
| **Cycle** | A month-long window for the company, anchored on the company's `CutoverDay`. There is exactly one **Open** cycle at a time; the rest are **Closed**. |
| **Sheet** | One row in `ExpenseSheet`, scoped to `(CompanyId, CreatedByUserId, ExpenseCycleId)`. Owns the expenses filed for that user in that cycle. |
| **Sheet status** | `Draft (1)` → `WaitingForApproval (2)` → `Approved (3)` *or* `Declined (4)`. Plus the implicit "deleted" terminal for empty drafts. |
| **Expense status** | `Pending (1)` → `Approved (2)` *or* `Declined (3)`. Editing a `Declined` expense on a `Declined` sheet resets it back to `Pending`. |
| **Cycle promotion** | The per-company batch job (an **external Azure Function**, NOT the Flutter app, NOT a server hosted job) that runs on cycle day. It submits non-empty drafts, hard-deletes empty drafts, closes the open cycle, and opens the next one. |
| **Auto-evaluation** | After any per-expense mutation, the server re-derives the sheet's status from its expenses' statuses. |

### 0.3 Sheet lifecycle

```
                  (lazy-created on the employee's
                   first expense of the cycle)
                              │
                              ▼
   ┌─────────────────────┐ promote-cycle  ┌──────────────────────┐
   │       Draft (1)     │ ─────────────► │  WaitingForApproval  │
   │                     │  (non-empty)   │         (2)          │
   └──────────┬──────────┘                └──────────┬───────────┘
              │                                     │
   promote-cycle (empty)                manager     │   manager
              │                         approves    │   declines
              ▼                         sheet OR    │   sheet
        ┌───────────┐                   per-expense │   (with comment)
        │  deleted  │                   makes all   │
        │  (hard)   │                   approved    │
        └───────────┘                              │
                                                    ▼
                                       ┌──────────────────────┐
                                       │      Approved (3)    │ ◄────┐
                                       └──────────────────────┘      │
                                                                     │ employee edits
                                       ┌──────────────────────┐      │ all Declined
                                       │      Declined (4)    │ ─────┘ expenses on a
                                       └──────┬───────────────┘        Declined sheet
                                              │                        until all are
                            empty after       │                        Approved
                            employee deletes  │
                              ▼               ▼
                        ┌───────────┐    (employee edits
                        │  deleted  │     a Declined
                        │  (hard)   │     expense → sheet
                        └───────────┘     auto-returns
                                          to WaitingForApproval)
```

A sheet **starts existence only when the employee files their first expense in a cycle**. There is no "create sheet" action. There is no "submit sheet" action either — the cycle promotion job is the only thing that submits drafts.

### 0.4 Cycle promotion — the only transition out of Draft

Cycle promotion runs once per company on the company's cycle day. The Azure Function calls `proc_PromoteCompanyCycle` per company. The proc does, in one transaction:

1. Find the company's open cycle whose `CycleEndAt` has passed.
2. For every **Draft sheet with at least one expense** on that cycle: set status to `WaitingForApproval`, stamp `SubmittedAt`, write a log row `Draft → WaitingForApproval`.
3. For every **Draft sheet with zero expenses** on that cycle: **hard-delete** the sheet and its log rows. Empty drafts never survive cycle close.
4. Close the cycle (`CycleStatus = 'Closed'`, `ClosedAt = now`).
5. Open the next cycle via the existing `proc_OpenCompanyCycle`.

Constraints:

- **The client never triggers promotion in production.** The Azure Function owns the schedule.
- **The proc is idempotent.** Calling it twice on the same closing window is a no-op the second time (it only acts on cycles whose end has passed).
- **An open cycle whose end is still in the future is left alone.**
- In dev/test, `POST /api/test/promote-cycle` lets you trigger it manually for the calling company. Pair with `POST /api/test/backdate-current-cycle-end` to fake the "cycle day arrived" trigger.

### 0.5 Manager actions on a submitted sheet

Once a sheet is `WaitingForApproval`, the manager has two paths. Both are valid; the UI should default to the whole-sheet flow but expose per-expense as a power-user option.

**Whole-sheet approve** — `POST /api/expense-sheets/{id}/approve`
- Flips every still-`Pending` expense on the sheet to `Approved` (with `reviewedByUserId` = manager).
- Leaves already-Approved or already-Declined expenses untouched.
- Transitions sheet → `Approved`. One log row.

**Whole-sheet decline** — `POST /api/expense-sheets/{id}/decline`
- Requires a non-empty `comment` (server returns 400 `ExpenseSheetDeclineCommentRequired` otherwise).
- Flips every still-`Pending` expense on the sheet to `Declined`.
- Leaves already-Approved expenses **alone** — they stay Approved on the now-Declined sheet, which is a real and important state.
- Transitions sheet → `Declined`. The comment is recorded on the log row.

**Per-expense approve / decline** — `POST /api/expenses/{id}/approve|decline`
- Only allowed when the parent sheet is in `WaitingForApproval`. Otherwise the SQL guard fires and the server returns a 4xx.
- After the per-expense update, the server **auto-evaluates** the sheet (§0.6).

### 0.6 Auto-evaluation — what it does and what it does NOT do

After every per-expense mutation on a sheet currently in `WaitingForApproval` or `Declined`, the server runs `proc_EvaluateExpenseSheet`. The rule set is intentionally narrow:

| Current sheet status | All expenses Approved? | Has at least one non-Approved? | Empty? | New status |
|---|---|---|---|---|
| `Draft` | n/a — auto-eval **never** runs on Draft | | | unchanged |
| `Approved` | n/a — auto-eval **never** runs on Approved | | | unchanged |
| `WaitingForApproval` | yes | — | — | `Approved` |
| `WaitingForApproval` | no | yes | — | stays `WaitingForApproval` |
| `WaitingForApproval` | — | — | yes (defensive) | unchanged |
| `Declined` | yes | — | — | `Approved` |
| `Declined` | no | yes | — | `WaitingForApproval` |
| `Declined` | — | — | yes | **hard-deleted** (sheet + all log rows) |

Three consequences of this matrix worth memorizing:

1. **Auto-eval never targets `Declined`.** The only way to put a sheet into Declined is the explicit whole-sheet decline endpoint. A per-expense decline that "happens to" decline every expense on the sheet leaves the sheet in `WaitingForApproval` — auto-eval will keep targeting WfA because no transition to Declined is in the rule set.
2. **A `Declined` sheet is recoverable.** The employee just edits the bad expenses (which resets them to `Pending`) or deletes them. The sheet's status will follow the matrix above.
3. **A `Declined` sheet that loses its last expense disappears.** The employee gets a 404 the next time they try to read it. This is intentional cleanup, not a bug.

### 0.7 Edit / delete authority

The server enforces a single rule matrix on edit (`PUT /api/expenses/{id}`) and delete (`DELETE /api/expenses/{id}`). The Flutter UI should mirror it so we don't paint buttons that will 409.

| | Manager | Employee, sheet Draft | Employee, sheet WaitingForApproval | Employee, sheet Approved | Employee, sheet Declined |
|---|---|---|---|---|---|
| **Edit Pending expense** | ✅ no status change | ✅ no status change | ❌ 409 | ❌ 409 (only Approved expenses exist here) | ✅ no status change |
| **Edit Approved expense** | ✅ no status change | (cannot exist — Drafts don't have Approved expenses) | ❌ 409 | ❌ 409 | ❌ 409 `ExpenseEditApprovedExpenseOnDeclinedSheet` |
| **Edit Declined expense** | ✅ no status change | (cannot exist) | (cannot exist) | (cannot exist) | ✅ **resets expense to Pending and re-evals sheet** |
| **Delete expense** | ✅ when sheet is Draft or Declined; never on WfA/Approved | ✅ if Pending | ❌ 409 | ❌ 409 | ✅ Pending or Declined; ❌ Approved (403) |
| **Create expense** | ✅ always; lands on current open cycle's draft sheet | ✅ same | (n/a — sheet not Draft) | (n/a — sheet not Draft) | ✅ but lands on the **current** cycle's draft sheet, NOT on the Declined past-cycle sheet |

The matrix is enforced in the stored procs themselves. The Flutter UI is just preventing wasted round trips and giving the user a better signal.

### 0.8 Constraints worth tattooing on the wall

- **Sheets are lazy.** No "create sheet" endpoint. Filing an expense creates the sheet behind the scenes (in `proc_CreateExpense`).
- **One sheet per (user, cycle).** The combination is unique. Filing a second expense in the same cycle re-uses the existing draft.
- **A sheet always has a cycle.** `ExpenseSheet.ExpenseCycleId` is `NOT NULL`. The cycle's `CycleStatus` may be `Open` or `Closed`, but the link is permanent.
- **An expense always has a sheet.** `Expenses.ExpenseSheetId` is `NOT NULL` with a foreign key. There is no such thing as an "orphan" expense.
- **The 12-month past-date rule** is enforced on create and update. `expenseDate` older than `today - 12 months` is rejected with `ExpenseDateTooOld`.
- **Manager always wins for edit.** A manager can edit any expense regardless of sheet/expense status, with no auto-eval and no status change. Use this sparingly — it bypasses the workflow.
- **The whole-sheet decline endpoint requires a comment.** Empty/whitespace is rejected up front. The comment is stored on the status-log row and exposed via the sheet detail as `latestDeclineComment`.
- **The manager queue caps at 12 sheets**, ordered by `submittedAt DESC`. Older waiting sheets are off-screen until pagination is added (not in scope for Story 1).
- **Cross-employee visibility is hidden.** An employee asking for another employee's sheet detail gets `404`, not `403`. We don't leak the existence of peer sheets.
- **`/api/expenses/{id}/reopen` no longer exists.** Calling it returns `404`. Remove every reference from the client.

### 0.9 Why the model is shaped this way (design tradeoffs)

A few decisions that look quirky in isolation make sense once you see them as a set:

- **Auto-eval never targets Declined.** Forcing the manager to explicitly choose "I want this whole sheet declined" makes the negative path deliberate. A bulk-decline of every line item is a different intent — "I rejected each one individually" — and the sheet status reflects that nuance.
- **Empty drafts get hard-deleted.** It keeps the manager queue clean and lets us tell employees with confidence that "no sheet" means "you filed nothing this cycle." It also means a "sheet exists" signal in the UI is always meaningful.
- **Editing a Declined expense resets it to Pending instead of going through a separate `reopen` action.** The verb the user wants is "fix and resubmit" — collapsing that into a single edit is the natural workflow. The state transition is automatic so the UI doesn't have to expose a two-step flow.
- **Cycle promotion is external (an Azure Function).** It runs on each company's local cycle day at the right local time. Keeping it out of the API process means it doesn't compete with user traffic and it's not affected by app deploys. The server just exposes the proc; the timer lives elsewhere.

---

## 1. Conceptual changes the Flutter app must absorb

### 1.1 Sheets are the new approval unit
- Per-expense `Pending → Approved/Declined` is **still here**, but a manager can no longer act on an individual expense until the *parent sheet* has been submitted (Draft → WaitingForApproval).
- The submission happens automatically: an **Azure Function** (outside the app) runs `proc_PromoteCompanyCycle` on each company's cycle day. The client never triggers it in production. In dev/test you can hit `POST /api/test/promote-cycle` (see §4.1).
- After submission the manager has two paths:
  - **Whole-sheet decision** — `POST /api/expense-sheets/{id}/approve` or `/decline` (preferred default flow).
  - **Per-expense decision** — same `POST /api/expenses/{id}/approve|decline` you already call. The server auto-evaluates the sheet status afterward (it stays in `WaitingForApproval` unless every expense is `Approved`, in which case the sheet flips to `Approved`; auto-flipping to `Declined` only happens via the whole-sheet endpoint).

### 1.2 `/api/expenses/{id}/reopen` is GONE
- Remove every reference in the app. There is no "reopen" anymore.
- The replacement flow: when a sheet is `Declined`, the employee can **edit** any `Declined` expense on it. The server resets that expense to `Pending` automatically and re-evaluates the sheet (which moves back to `WaitingForApproval`).

### 1.3 New status enums

```dart
enum ExpenseStatus { pending(1), approved(2), declined(3); ... }

enum ExpenseSheetStatus {
  draft(1),
  waitingForApproval(2),
  approved(3),
  declined(4);
  ...
}
```

The server projects both an `Id` and an `Alias` (the string name) on every response. Prefer the `Id` for branching logic; show the `Alias` as-is or run it through a localization map.

### 1.4 Sheet-aware edit / delete rule matrix

The server enforces this matrix per `(role, sheetStatus, expenseStatus)`. The Flutter UI should mirror it so we don't show buttons that will 409.

| Action                              | Manager | Employee on Draft sheet | Employee on WaitingForApproval | Employee on Approved | Employee on Declined sheet                                                                                       |
|-------------------------------------|---------|--------------------------|--------------------------------|----------------------|-------------------------------------------------------------------------------------------------------------------|
| **Edit** expense (PUT)              | Always allowed; status unchanged | `Pending` only | Blocked (409) | Blocked (409) | `Pending` allowed; `Declined` allowed and **auto-resets to Pending**; `Approved` blocked (409) |
| **Delete** expense (DELETE)         | Allowed on Draft and Declined sheets only; never on WfA or Approved | `Pending` only | Blocked (409) | Blocked (409) | `Pending` and `Declined` allowed; `Approved` blocked (403) |
| **Approve / Decline** (per-expense) | Only when sheet is `WaitingForApproval` | n/a | n/a | n/a | n/a |
| **Create** new expense              | Always allowed | n/a | n/a | n/a | n/a — **but** it lands on the current open cycle's draft sheet, NOT on a declined past sheet |

Auto-evaluations to be aware of:

- **Per-expense approve on the sheet's last `Pending` expense → sheet auto-flips to `Approved`.**
- **Per-expense decline → sheet stays `WaitingForApproval`** (auto-eval never targets `Declined`; only `proc_DeclineExpenseSheet` does).
- **Editing a `Declined` expense on a `Declined` sheet → expense resets to `Pending`, sheet re-evaluated:**
  - if at least one non-Approved expense remains → sheet → `WaitingForApproval`
  - if all expenses are Approved → sheet → `Approved`
- **Deleting the last expense on a `Declined` sheet → sheet is hard-deleted (404 on subsequent reads).**

### 1.5 12-month past-date rule

`POST /api/expenses` and `PUT /api/expenses/{id}` reject `expenseDate` older than 12 months from today with:

```json
{ "success": false, "message": "Expense date cannot be more than 12 months old.",
  "errorCode": "ExpenseDateTooOld" }
```

Status `400`. The Flutter date picker should pre-clamp `min = today - 12 months` and surface a clear error if the user manually types an older date.

### 1.6 Subscription block mode

Same block-mode rules as before, restated for clarity:

- All sheet-level **approve / decline** endpoints respect `BlockMode`. If not `None` they return `403` with `errorCode: SubscriptionRequired`. Reuse the existing "Your subscription does not allow this action" modal.
- All per-expense **approve / decline** endpoints behave identically.
- **Create / edit / delete / search** endpoints are **not** block-mode gated. Employees can keep filing expenses while the company is `SoftLocked` / `MustPayNextLogin`.

---

## 2. ExpenseSheets controller — NEW (`/api/expense-sheets`)

All endpoints `[Authorize]`. All return the standard envelope.

### 2.1 `GET /api/expense-sheets/queue` — Manager queue

- **Role guard:** Manager only (`403` otherwise).
- Returns up to **12** sheets currently in `WaitingForApproval` for the company.
- Ordered by `submittedAt DESC`.
- `data` shape:

```jsonc
[
  {
    "expenseSheetId":       "guid",
    "createdByUserId":      "guid",
    "createdByName":        "string",
    "createdByEmail":       "string",
    "expenseCycleId":       "guid",
    "cycleLabel":           "2026/05",
    "expenseSheetStatusId": 2,                  // always 2 here
    "statusAlias":          "WaitingForApproval",
    "createdAt":            null,               // not populated on this projection
    "submittedAt":          "2026-05-23T10:11:12Z",
    "reviewedAt":           null,
    "expenseCount":         3,
    "totalAmount":          1230.50,
    "currencyCode":         "ILS"
  }
]
```

UI: **Approvals tab** for managers. Show one row per sheet. Tapping opens the sheet detail (§2.4).

### 2.2 `GET /api/expense-sheets/me?expenseCycleId={guid?}` — My sheets

- **No role guard.** Manager and employee both call it for **their own** sheets.
- Returns up to **12** of the caller's sheets, ordered by `cycleLabel DESC`.
- Optional `expenseCycleId` query filters to a single cycle.
- Same row shape as queue, but here `statusAlias` can be any of `Draft / WaitingForApproval / Approved / Declined`, and `createdAt / reviewedAt` are populated.

UI: **My Expenses → Sheets tab** for both roles. The newest cycle's row is the "current" sheet; the rest are history.

### 2.3 `GET /api/expense-sheets/{userId}/list?expenseCycleId={guid?}`

- **Role guard:** Manager only.
- Same shape as 2.2 but for a specific employee. Powers the manager's drill-down into one employee's history.

### 2.4 `GET /api/expense-sheets/{expenseSheetId}` — Detail

- **Role guard:** an active manager OR the sheet's creator. Anyone else gets `404` (intentional — we don't leak existence cross-employee).
- `data` is a flat header + two arrays:

```jsonc
{
  "expenseSheetId":       "guid",
  "companyId":            "guid",
  "createdByUserId":      "guid",
  "createdByName":        "string",
  "createdByEmail":       "string",
  "expenseCycleId":       "guid",
  "cycleLabel":           "2026/05",
  "cycleStartAt":         "2026-05-01T00:00:00Z",
  "cycleEndAt":           "2026-05-31T23:59:59Z",
  "cycleStatus":          "Open" | "Closed",
  "expenseSheetStatusId": 2,
  "statusAlias":          "WaitingForApproval",
  "createdAt":            "2026-05-02T08:00:00Z",
  "submittedAt":          "2026-05-31T23:59:59Z",
  "reviewedAt":           null,
  "reviewedByUserId":     null,
  "reviewedByName":       null,
  "latestDeclineComment": "Please fix categories",   // null until the sheet has ever been declined
  "expenses": [
    {
      "expenseId":       "guid",
      "companyId":       "guid",
      "createdByUserId": "guid",
      "createdByName":   "string",
      "createdAt":       "ISO",
      "expenseDate":     "ISO",
      "merchantName":    "string?",
      "categoryId":      1,
      "categoryName":    "Travel",
      "amount":          123.45,
      "currencyCode":    "ILS",
      "isAiData":        false,
      "expenseStatusId": 1,
      "statusAlias":     "Pending",
      "reviewedByUserId":null,
      "reviewedBy":      null,
      "reviewedAt":      null,
      "receiptRef":      "string?",
      "note":            "string?",
      "expenseSheetId":  "guid",
      // sheet status is the same as the header above; the projection here
      // does NOT add ExpenseSheetStatusId/Alias to keep the array compact.
    }
  ],
  "log": [
    {
      "expenseSheetStatusLogId": "guid",
      "fromStatusId":   1,    // nullable; null on the very first row (Draft create)
      "fromStatusAlias":"Draft",
      "toStatusId":     2,
      "toStatusAlias":  "WaitingForApproval",
      "changedByUserId":null, // null when the change was system-driven (e.g., cycle promotion)
      "changedByName":  null,
      "changedAt":      "ISO",
      "comment":        "string?"   // populated on Declined transitions
    }
  ]
}
```

UI:
- **Header block** = sheet card (status badge, submitted/reviewed timestamps, cycle label, "latest decline comment" callout if `Declined`).
- **Expenses list** = the existing expense list cell.
- **Activity timeline** = `log[]` rendered as `Draft → WaitingForApproval → Declined ("comment") → WaitingForApproval → Approved`. The system-vs-user distinction (`changedByUserId == null`) should render as "System" / "Cycle close".

### 2.5 `POST /api/expense-sheets/{expenseSheetId}/approve`

- Role: Manager only.
- Block-mode: rejected if not `None` (errorCode `SubscriptionRequired`).
- Body: none.
- Success: `200 { success: true, message: "Expense sheet approved successfully." }`.
- Failure error codes you should map:
  - `ExpenseSheetNotFound` → 404 toast: "Sheet was deleted by someone else."
  - `ExpenseSheetWrongStatusForAction` → 409: "This sheet is no longer waiting for approval." (sheet changed state between list-fetch and tap)
  - `SubscriptionRequired` → reuse existing paywall modal.

Server behavior to anticipate:
- Every still-`Pending` expense on the sheet is flipped to `Approved`, stamped with the manager's `reviewedByUserId / reviewedAt`.
- Already-Approved or already-Declined expenses are **not** touched.
- The sheet transitions to `Approved`.

### 2.6 `POST /api/expense-sheets/{expenseSheetId}/decline`

- Role: Manager only.
- Block-mode: same as approve.
- Body:

```jsonc
{ "comment": "non-empty string" }
```

- **`comment` is required.** Empty/whitespace returns `400` with `errorCode: ExpenseSheetDeclineCommentRequired`. The Flutter UI must enforce a non-empty text field before submit, and translate that error code if it slips through.
- Success: `200 { success: true, message: "Expense sheet declined successfully." }`.

Server behavior:
- Every still-`Pending` expense on the sheet is flipped to `Declined`. Approved/Declined expenses are untouched.
- The sheet transitions to `Declined`. `comment` is stored on the log row.

### 2.7 Status-code summary

| HTTP | When it happens                                                                 |
|------|---------------------------------------------------------------------------------|
| 200  | Success                                                                         |
| 400  | Validation: missing decline comment                                             |
| 403  | Wrong role; block-mode active; unauthenticated                                  |
| 404  | Sheet not found / not visible to caller                                         |
| 409  | Sheet is not in `WaitingForApproval` when you try to approve/decline it         |
| 500  | Unhandled DB exception. Show a generic retry-or-contact-support toast.          |

---

## 3. Expenses controller — DELTAS only (`/api/expenses`)

The endpoint **paths are unchanged**, but several responses, requests, and behaviors changed. Bullet points are what to update in Flutter.

### 3.1 New fields on every expense response

Both `GET /api/expenses/{id}` and `GET /api/expenses/search` / `{userId}/search` now project three new fields on the expense object:

```jsonc
"expenseSheetId":          "guid? | null",
"expenseSheetStatusId":    1 | 2 | 3 | 4 | null,
"expenseSheetStatusAlias": "Draft | WaitingForApproval | Approved | Declined | null"
```

Add these to your `ExpenseDto` model. They will never be null for newly created expenses (every expense is on a sheet), but keep them nullable for safety with older payloads.

**UX win:** the expense list cell can now show a small badge "On sheet · WaitingForApproval" without an extra round-trip. Use it for filtering — e.g., "Show only expenses on submitted sheets".

### 3.2 `GET /api/expenses/search` and `/{userId}/search` — new query param

```
?expenseCycleId={guid}       (existing)
?expenseSheetId={guid}       (NEW — optional)
```

Pass `expenseSheetId` to scope the list to a specific sheet (replaces the previous `expenseCycleId` hack when drilling into a sheet's expenses).

### 3.3 `POST /api/expenses` — Create

- **No request shape change** vs. the previous version.
- **New rejection:** `expenseDate < today - 12 months` → `400 { errorCode: "ExpenseDateTooOld" }`.
- **Server now auto-creates a draft sheet** for the employee for the active cycle if none exists. The Flutter app should NOT pre-create or check for a sheet; just POST the expense and read the response.
- All existing validation (missing fields, future date, non-positive amount, bad currency code) still applies.

### 3.4 `PUT /api/expenses/{id}` — Update

- **No request shape change.** Same `ExpenseRequest` body.
- **The server now resolves `(role, sheetStatus, expenseStatus)` from the token and the row** — the previous `currentCycleId` path is gone. Just call PUT.
- New error mapping:
  - `KeyNotFoundException` → `404` "Expense does not exist." OR "Parent expense sheet does not exist." (sheet was hard-deleted under you)
  - `409 { errorCode: ExpenseEditApprovedExpenseOnDeclinedSheet }` — the rule-matrix disallowed the edit. Show "This expense can't be edited in its current state."
  - `400 { errorCode: ExpenseDateTooOld }` — same 12-month rule.

### 3.5 `POST /api/expenses/{id}/approve`, `/decline`

- **Endpoints unchanged**, but now they **require the parent sheet to be `WaitingForApproval`**. If not, the SQL guard fires and the controller returns `400` with the generic "Unable to approve/decline expense" message.
- In the Flutter UI, only expose these actions when the sheet detail shows `WaitingForApproval`. After tapping, refresh the sheet detail to reflect the auto-eval outcome (sheet may have flipped to `Approved`).
- Block-mode unchanged (`SubscriptionRequired` 403).

### 3.6 `POST /api/expenses/{id}/reopen` — REMOVED

Delete every Flutter call to this endpoint. Server returns `404` if you call it. Replace the "Reopen" button:

- For employees, the equivalent is **edit the Declined expense** — server resets it to Pending automatically.
- For managers, there is no "reopen" anymore; if a manager wants to undo a decision, they need to wait for the employee to re-submit or contact the employee directly.
  - **Update (2026-06-11):** superseded for the whole-sheet case — `POST /api/expense-sheets/{id}/approve` now also accepts `Declined` sheets (declined lines stay declined; all-declined sheets close as Approved with nothing reimbursed). Re-decline is still rejected. See docs/in-progress/manager-reapprove-declined-sheet.md.

### 3.7 `DELETE /api/expenses/{id}` — Delete

- **Endpoint unchanged**, behavior expanded.
- Managers can now delete employee expenses **when the sheet is `Draft` or `Declined`**. Update the Flutter "manager view of an employee's expense" to expose the delete affordance accordingly.
- Existing error codes still apply:
  - `403 { errorCode: ExpensesDeleteNotAuthorized }` — non-creator non-manager.
  - `409 { errorCode: ExpensesDeleteExpenseCannotBeDeleted }` — sheet is WaitingForApproval/Approved or the expense is Approved on a Declined sheet. `data` payload includes `{ expenseId, status }`.

### 3.8 `POST /api/expenses/analyze-receipt`

No change. Still rate-limited under `Moderated`. Still returns mock data when the request has `QaAutomation: on` header.

---

## 4. Company controller — minor relevance (`/api/company`)

Most of CompanyController is billing/subscription which is unchanged. Only items relevant to the sheets work:

### 4.1 `GET /api/company` — Full details

No payload change. The Flutter app already uses `cutoverDay` here; that drives the **cycle promotion date** which the user should see on the home screen ("Sheet auto-submits on the 15th").

Optionally add a footer line like:
> Your sheets close on day **{cutoverDay}** each month. Edits after that point go onto next month's sheet.

### 4.2 Block-mode reminder

`GetCompanyFullDetailsAsync` returns `blockMode` ∈ `{None, SoftLocked, MustPayNextLogin}`. The Flutter app already gates "Approve / Decline" UI on this. With the new sheet-level endpoints, **apply the same gate to the sheet-approve / sheet-decline buttons**. Server enforces it too (returns `403 SubscriptionRequired`), but pre-gating avoids a wasted round-trip.

### 4.3 No new company-level endpoints

No new endpoints were added under `/api/company`. Subscription flows (cancel / resume / move-to-annual / move-to-monthly / cancel future plan / billing / payment-method / payment-setup / billing transactions / change-log) are unchanged.

### 4.4 Dev-only helpers for QA (`/api/test/*`)

If the Flutter QA harness drives the API in dev mode, two new endpoints might be useful:

| Endpoint                                       | What it does                                                              |
|------------------------------------------------|----------------------------------------------------------------------------|
| `POST /api/test/backdate-current-cycle-end`    | Sets the open cycle's `CycleEndAt` to "one second ago" so the next promote-cycle treats it as due. |
| `POST /api/test/promote-cycle`                 | Triggers `proc_PromoteCompanyCycle` — submits non-empty drafts, hard-deletes empty drafts, closes the open cycle and opens the next. |
| `POST /api/test/reset-system`                  | Wipes ALL test data. Use with care; auth-anonymous, dev-mode only.        |

All three are 403 in production. Don't ship them in the user-facing app.

---

## 5. ApiErrorCodes the client should know about

New codes added to the server enum. The Flutter localization map should grow accordingly:

| Code                                              | When / suggested copy                                                                                   |
|---------------------------------------------------|---------------------------------------------------------------------------------------------------------|
| `ExpenseSheetNotFound`                            | 404 from sheet endpoints. "This sheet no longer exists."                                                |
| `ExpenseSheetWrongStatusForAction`                | 409 from sheet approve/decline. "This sheet is no longer waiting for approval."                          |
| `ExpenseSheetDeclineCommentRequired`              | 400 from sheet decline. "Please add a comment explaining the decline."                                  |
| `ExpenseDateTooOld`                               | 400 from create/update. "Expense date can't be more than 12 months in the past."                        |
| `ExpenseEditApprovedExpenseOnDeclinedSheet`       | 409 from update. "This expense can't be edited in its current state."                                   |
| `UserHasExpenseSheets` / `UserHasReviewedExpenseSheets` / `UserHasExpenseSheetStatusLogEntries` | 409 from `DELETE /api/users/{id}`. "Can't delete a user who created / reviewed / changed sheets."       |
| (already in enum) `SubscriptionRequired`          | 403 on sheet approve/decline. Reuse existing paywall flow.                                              |
| (already in enum) `ExpensesDeleteExpenseCannotBeDeleted` | 409 on expense delete. `data.status` tells you why.                                                |
| (already in enum) `ExpensesDeleteNotAuthorized`   | 403 on expense delete by a non-creator non-manager.                                                     |

---

## 6. Suggested Flutter implementation order

1. **Models** — add `ExpenseSheetStatus` enum, `ExpenseSheetDto` (list-item), `ExpenseSheetDetailDto`, `ExpenseSheetStatusLogEntryDto`, `DeclineExpenseSheetRequest`. Extend `ExpenseDto` with the 3 new sheet-related fields.
2. **API client** — wrap `/api/expense-sheets/queue`, `/me`, `/{userId}/list`, `/{id}`, `/{id}/approve`, `/{id}/decline`. Add `expenseSheetId` query to the existing `/api/expenses/search`.
3. **Delete `reopen()`** from the API client and any UI that calls it.
4. **Update expense update/delete UI** to respect §1.4 matrix. Hide buttons that the matrix forbids based on the new `expenseSheetStatusId` field. Keep the server-side errors as a defensive fallback (toast on 409/403).
5. **Build the Sheets tabs**:
   - **Manager → Approvals queue** (`/queue`)
   - **Manager → Employee history** (`/{userId}/list`)
   - **Everyone → My sheets** (`/me`)
   - **Sheet detail screen** (`/{id}`) — header + expenses + timeline
6. **Date picker** — clamp `firstDate = today - 12 months`.
7. **Localization** — add the new error code copy in §5.
8. **QA harness (optional)** — wire the three `/api/test/*` helpers behind a dev-only debug menu so manual testers can drive cycle promotion without waiting for the Azure Function.

---

## 7. Smoke checklist for the Flutter dev box

Run through these scenarios against a fresh test company to confirm parity with the server:

- [ ] Employee creates expense → expense card shows badge "Draft".
- [ ] Manager queue is empty while the sheet is Draft.
- [ ] QA helper: backdate + promote-cycle → sheet flips to WaitingForApproval, appears in manager queue.
- [ ] Manager approves the sheet → sheet card shows Approved, every expense Approved.
- [ ] Manager declines the sheet **without** a comment → blocked client-side; if bypassed, server returns 400 with `ExpenseSheetDeclineCommentRequired`.
- [ ] Manager declines with comment → sheet Declined, comment appears in the timeline.
- [ ] Employee opens a Declined sheet → can edit any expense; on save, the expense becomes Pending and the sheet badge flips back to WaitingForApproval.
- [ ] Employee deletes the only expense on a Declined sheet → sheet card disappears (server hard-deletes it).
- [ ] Employee tries to file an expense dated 13 months ago → blocked with friendly copy.
- [ ] Soft-lock the company in dev → approve/decline buttons are disabled with the paywall copy; server returns 403 if bypassed.
- [ ] Search by `expenseSheetId` returns only the expenses on that sheet.
- [ ] `POST /api/expenses/{id}/reopen` is **not** invoked anywhere in the app (grep the codebase).

---

## 8. Open questions / parking lot

- **Notifications.** The server doesn't push a notification when a sheet is approved / declined. If the Flutter app wants real-time updates, the existing polling cadence on the sheet detail screen is the path of least resistance. A push channel can be added later.
- **Pagination.** Sheet list endpoints currently cap at TOP 12 with no cursor. If users routinely have > 12 closed sheets to scroll, we'll add pagination — out of scope for Story 1.
- **Per-employee co-employee view.** A peer cannot view another employee's sheet (404). If that's desired (e.g., team leads who aren't formal managers), file a follow-up.
- **Cross-cycle expense.** When a cycle closes mid-thought, anything filed after the close lands on the new cycle's draft sheet. The expense's `expenseDate` field is independent of cycle assignment — make sure the Flutter UI doesn't suggest otherwise.

---

## 9. FAQ for Flutter (and other client) teams

Recurring questions from client teams reading this doc for the first time. If you find yourself drafting a "but where's the X endpoint" message, check here first.

### 9.1 "My UX spec assumes the sheet enters a 'reopened draft' state after rejection. Where is it?"

It doesn't exist. The design rejects a fifth state. A declined sheet sits in `Declined (statusId=4)` until the employee fixes the rejected items. The signal you're reaching for — "this sheet needs my attention" — is already carried by `statusId == 4` plus a non-null `latestDeclineComment`. No flag, no extra status.

The old mental model vs. the actual one:

| Old mental model                              | Actual model                                                        |
|----------------------------------------------|----------------------------------------------------------------------|
| Sheet enters a "draft with reopened flag" state | Sheet sits in `Declined`                                          |
| UI shows the flag as a callout                | UI uses `statusAlias = "Declined"` + the `latestDeclineComment` field |
| Employee "fixes" then taps Resubmit           | Employee edits or deletes the Declined items; status flips on its own |

### 9.2 "I need a `/resubmit` endpoint for my Resubmit button. Where is it?"

There isn't one, and the design rejects adding one. Reasoning:

- An explicit `/resubmit` endpoint would introduce a real failure mode — the employee fixes everything, forgets to tap the button, and the manager waits indefinitely for a sheet that's actually ready. Auto-eval eliminates that bug class.
- Auto-eval correctly handles "fix two items, delete the third", "delete every rejected item so the sheet auto-promotes to `Approved` with no manager re-review", and "edit then re-edit" — without any UI choreography.
- Two ways to do the same thing would race, with the auto-flow always winning by milliseconds, so the button would frequently 409.

**Recommended client UX:** a passive banner on a Declined sheet that shows `latestDeclineComment` and explains the auto-flow. Refresh the sheet detail after every successful PUT/DELETE on a Declined sheet so the user sees the badge flip (`Declined → WaitingForApproval` or `→ Approved`) without a manual reload. **That badge flip is the moment of visible feedback that replaces the old "Resubmit" tap.**

### 9.3 "How does the manager find out the sheet came back?"

The next time they refresh the queue. No push notifications today. The sheet returns to `WaitingForApproval` and reappears in `GET /api/expense-sheets/queue`. Per-expense Approved decisions from the manager's first pass are preserved across the cycle.

### 9.4 "What happens if the employee deletes every rejected item instead of editing them?"

Driven by the auto-eval matrix in §0.6:

- If the remaining expenses are all `Approved` → sheet auto-flips to `Approved`, no manager re-review.
- If no expenses remain → sheet **hard-deletes** (rows in `ExpenseSheet` and its log are removed). Subsequent reads return `404`.
- If some `Pending` remain → sheet → `WaitingForApproval`.

Clients should be prepared for all three outcomes after the user's last delete.

### 9.5 "Is there a `partially_rejected` sheet status?"

No. Sheet statuses are exactly `Draft | WaitingForApproval | Approved | Declined`. An `Approved` sheet **can** carry some `Declined` per-expense rows (the manager approved the rest, the declined ones stay declined), but the sheet status itself is just `Approved`. If a UX needs to distinguish that case, derive it client-side from `(sheetStatusId == 3) && (any expense.expenseStatusId == 3)`.

---

**Server reference docs:**
- Backend story: `docs/expense-sheets/story-1-expense-sheets.md`
- Stored procedure guide: `docs/expense-sheets/part-1-proc-guide.md`
- API + tests plan: `docs/expense-sheets/part-2.md`
