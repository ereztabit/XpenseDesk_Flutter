# Expense Sheets — Flutter Implementation Plan

**Status:** Working draft. Pair this with the discovery doc.

**Source of truth (server side):** [`docs/completed/ExpenseSheetsTransformation/ExpenseSheetsEvolution.md`](./ExpenseSheetsEvolution.md). Read §0 (concept) before touching this file. Any answer that contradicts the discovery doc is wrong — update this plan, not the server contract.

---

## 0. What this doc is

A living plan for how the Flutter client absorbs the new sheet-centric approval model. It is **not** a spec — it's the punch list we evolve as we make UX decisions and ship slices. The discovery doc tells us *what the server does*; this doc tracks *what the app must do to expose that*.

Two jobs we own:
1. **UX** — surface sheets as a first-class concept (employee + manager) without making the app feel heavier than today.
2. **API activation** — wire up the new `/api/expense-sheets/*` endpoints, mutate existing `/api/expenses/*` callsites, kill `reopen` (already gone client-side — see §3.1), enforce the edit/delete rule matrix, and map new error codes.

---

## 1. What we have today (audit)

Grounding the plan in the current code so we know what to touch vs. build.

**Models** (`lib/models/`)
- `ExpenseSummary` — list-row DTO. Missing the 3 new sheet fields.
- `ExpenseDetail` — single-expense DTO. Missing the 3 new sheet fields.
- `ExpenseCycle` — exists.
- No `ExpenseSheet*` models yet.

**Service** (`lib/services/expense_service.dart`)
- Has `approveExpense(id)`, `declineExpense(id)`, `updateExpense`, `deleteExpense`, `createExpense`, `searchExpenses`, `getExpenseById`, plus reports.
- No sheet endpoints.
- `ExpenseException` + `ExpenseNotFoundException` + `ExpenseClosedException` exist; will need a couple more typed errors for the new codes.

**Provider** (`lib/providers/expense_provider.dart`)
- 46 lines: `expenseServiceProvider`, `expenseSearchProvider`, `expenseDetailProvider.family`, `cyclesProvider`. Clean. We'll add sheet providers here.

**Screens that will be impacted**
- `manager_dashboard_screen.dart` (362 lines) — entry point. Will gain an "Approvals" surface.
- `user_dashboard_screen.dart` (383 lines) — entry point. Will gain a "My current sheet" surface.
- `cycle_expenses_report_screen.dart` (**1140 lines**) — today this is the manager's per-cycle expense list with per-row approve/decline. This is the file most disrupted. **Open question:** does it become the sheet-detail screen, or stay as a reporting/export view and we build sheet-detail fresh? (See §4.)
- `employee_expense_detail_screen.dart` (**1013 lines**) — single-expense view. Edit-button visibility must follow the new matrix. Will display parent sheet status.
- `new_expense_screen.dart` — date picker must clamp to `today - 12 months`.

**Widgets** (`lib/widgets/expenses/`) — `expense_card`, `mobile_expense_card`, `desktop_expense_table`, `expense_status_badge`, `expense_status_toggle`, `manager_swipeable_expense_card`, `swipeable_expense_card`. All show per-expense status; several will need a second badge for sheet status, and the swipe-to-approve gesture needs to be gated on sheet being `WaitingForApproval`.

**Confirmed already done**
- Codebase grep for `reopen` → **zero hits**. Nothing to delete on this front (`/api/expenses/{id}/reopen` was never wired). Verify once more before closing the task.

---

## 2. UX concept — high level

Before tasks, a sketch of the destination. **All of §2 is up for debate** — these are starting positions for the design conversation, not committed UI.

### 2.1 Employee experience

The mental model: *"My monthly expense report fills itself out as I add expenses, and auto-submits on day X."*

- **Home (today's screen):** add a small "Current sheet" card.
  - Status badge (Draft until cycle-day).
  - "Auto-submits on day {cutoverDay}".
  - Count + total of expenses on it. Tap → sheet detail.
- **New tab "My sheets":** list of all my sheets across cycles, newest first. Badge per row. Tap → detail.
- **Sheet detail screen:**
  - Header: status, cycle label, submitted/reviewed timestamps, **prominent decline-comment callout if `Declined`**.
  - Expenses list (reuse existing cell).
  - Activity timeline (`Draft → WaitingForApproval → Declined "fix categories" → WaitingForApproval → Approved`). System events render as "System / Cycle close".
- **Filing an expense:** unchanged except (a) date picker clamped, (b) we show a one-line confirmation "Added to your {month} sheet".
- **Declined sheet recovery:** open the sheet, declined-expense rows are visually flagged, tap → edit → save → row goes back to Pending, sheet flips back to `WaitingForApproval`. **No explicit "reopen" button anywhere.**

### 2.2 Manager experience

The mental model: *"One decision per employee per month. I sign off on the report, not the line items."*

- **Home (manager dashboard):** "Approvals" card / count badge → opens the queue.
- **Approvals queue:** up to 12 sheets in `WaitingForApproval`, sorted newest-submitted first. Each row: employee name, cycle, expense count, total, submitted-at.
- **Sheet detail (manager view):** same as employee detail, with two CTAs in the header:
  - **Approve sheet** (primary) — flips all pending → approved.
  - **Decline sheet** (destructive, secondary) — opens a modal that **requires a non-empty comment**.
  - Per-expense approve/decline remains in the row UI as a power-user escape hatch (only enabled when sheet is `WaitingForApproval`).
- **Employee drill-down:** from the employee list (or wherever today's "see this user's expenses" lives) → "Sheets" tab showing that employee's history.

### 2.3 Shared things

- **Sheet status badge** — new widget. 4 states. Colors: Draft = muted, WaitingForApproval = amber, Approved = success, Declined = destructive. (Confirm with AppTheme tokens.)
- **Activity timeline** — new widget. Vertical list of log rows with from→to status, actor, timestamp, optional comment.
- **Decline modal** — new widget. Single textarea, required, primary "Decline sheet" + cancel.
- **Polling** — server doesn't push notifications. Sheet detail screens should refresh on resume/foreground; queue refreshes on pull-to-refresh + when user navigates back from a sheet they just acted on. Don't add aggressive polling — keep it explicit.

---

## 3. Open questions / decisions to lock before coding

These block specific tasks. Resolving them upfront keeps us from rebuilding screens.

1. **Where does "My Sheets" live in the nav?** New top-level tab? Subtab inside "My Expenses"? Replace the current expense list?
2. **What happens to `cycle_expenses_report_screen.dart`?** Three options:
   - (a) Repurpose it as the new sheet-detail screen (rename, gut, rebuild). Cheapest in LOC; loses the cycle-wide cross-employee export view if anyone uses it.
   - (b) Leave it as a reporting/export screen accessible from manager menu; build sheet-detail fresh. Cleanest separation; some duplication.
   - (c) Split it into two screens by purpose. Most work; cleanest long-term.
3. **Does the employee dashboard get a "current sheet" widget, or do we just rely on the new tab?** Affects how visible cycle-close day becomes.
4. **Manager decline-comment UX:** inline modal vs. push to a confirm screen vs. bottom sheet on mobile. (I'd default to a modal everywhere; revisit if it feels cramped on mobile.)
5. **Per-expense approve/decline visibility on the manager sheet-detail.** Always shown but disabled outside `WaitingForApproval`, or hidden entirely? (I'd hide.)
6. **Polling vs. manual refresh on the Approvals queue.** Pull-to-refresh + auto-refresh-on-focus, or add a 30s background poll?
7. **Cycle-close visibility for the employee.** Do we show "Sheet auto-submits in 4 days" type messaging anywhere, or just the static "day X" line?
8. **QA harness:** ship the three `/api/test/*` helpers behind a dev-menu now, or after the main flow works end-to-end?
9. **Migration / staging:** ship all phases on one PR, or land Phase 0 (foundation) separately first so the rest can build on it without merge thrash?

---

## 4. Implementation phases

Each phase is a milestone we can ship and verify in isolation. Phases are sequenced so we never break the app between merges. Inside a phase, tasks can run in parallel.

### Phase 0 — Foundation (no UI change)

Goal: make the data layer aware of sheets without touching any screen.

- [ ] Add `ExpenseSheetStatus` enum (`draft=1, waitingForApproval=2, approved=3, declined=4`) with `fromId` lookup.
- [ ] Extend `ExpenseSummary` with `expenseSheetId`, `expenseSheetStatusId`, `expenseSheetStatusAlias` (all nullable for safety).
- [ ] Extend `ExpenseDetail` with the same 3 fields.
- [ ] Add `ExpenseSheetListItem` model (queue / my-sheets / employee-list row shape — §2.1 of discovery doc).
- [ ] Add `ExpenseSheetDetail` model (header + expenses + log — §2.4).
- [ ] Add `ExpenseSheetLogEntry` model.
- [ ] Add `DeclineSheetRequest` model (just `comment`).
- [ ] Add new typed exceptions: `ExpenseSheetNotFoundException`, `ExpenseSheetWrongStatusException`, `DeclineCommentRequiredException`, `ExpenseDateTooOldException`, `EditApprovedExpenseOnDeclinedSheetException`. Keep `ExpenseException` as the generic fallback.
- [ ] Extend `ExpenseService`:
  - `getApprovalsQueue()` → `GET /api/expense-sheets/queue`
  - `getMySheets({String? cycleId})` → `GET /api/expense-sheets/me`
  - `getSheetsForUser(userId, {String? cycleId})` → `GET /api/expense-sheets/{userId}/list`
  - `getSheetDetail(sheetId)` → `GET /api/expense-sheets/{id}`
  - `approveSheet(sheetId)` → `POST /api/expense-sheets/{id}/approve`
  - `declineSheet(sheetId, comment)` → `POST /api/expense-sheets/{id}/decline`
  - Add `expenseSheetId` optional query to existing `searchExpenses`.
  - Map new error codes to typed exceptions.
- [ ] Add Riverpod providers: `approvalsQueueProvider`, `mySheetsProvider.family<cycleId?>`, `userSheetsProvider.family<(userId, cycleId?)>`, `sheetDetailProvider.family<sheetId>`.
- [ ] ARB keys for every new piece of copy (status names, error codes, screen titles, modal labels). **Add ARB before any widget code — CLAUDE.md rule.**
- [ ] `flutter build web` clean.

### Phase 1 — Surface sheet status on existing expense surfaces

Goal: existing screens still work but now show sheet context.

- [ ] New widget `ExpenseSheetStatusBadge` (4 states, themed colors).
- [ ] Update `expense_card`, `mobile_expense_card`, `desktop_expense_table` to render the sheet badge next to / under the expense badge.
- [ ] Update `employee_expense_detail_screen` to show "Part of sheet: {cycleLabel} · {status}" with a tap-through to sheet detail (target screen built in Phase 3).
- [ ] Visual review on desktop + mobile, RTL pass.

### Phase 2 — My Sheets (employee + manager, same surface)

- [ ] `MySheetsScreen` — list of my sheets. Uses `mySheetsProvider`. Pull-to-refresh.
- [ ] Empty state copy ("You haven't filed any expenses yet").
- [ ] Route registration under `AuthGate`.
- [ ] Hook from dashboard ("My sheets" entry).

### Phase 3 — Sheet Detail screen

Build once, used by both employee and manager.

- [ ] `SheetDetailScreen` orchestrator (< 200 lines per CLAUDE.md).
  - State + provider wiring.
  - Layout: `AppHeader → Expanded → SingleChildScrollView → ConstrainedContent → Column(...)`.
- [ ] `SheetDetailHeaderCard` widget.
- [ ] `SheetDetailExpenseList` widget (wraps existing expense cell).
- [ ] `SheetActivityTimeline` widget.
- [ ] `DeclineCommentCallout` widget (only renders when `statusAlias == Declined` and `latestDeclineComment != null`).
- [ ] 404 path: show "This sheet no longer exists" and route back.

### Phase 4 — Manager Approvals flow

- [ ] `ApprovalsQueueScreen` — list of sheets in WfA.
- [ ] Manager-only route guard.
- [ ] Tap-through to sheet detail.
- [ ] In sheet detail (manager mode): show `Approve sheet` + `Decline sheet` CTAs in header.
- [ ] `DeclineSheetDialog` widget — single comment field, required, calls `declineSheet`.
- [ ] Block-mode gate on both CTAs (pre-empt the 403 with the existing paywall modal).
- [ ] On success, invalidate `approvalsQueueProvider` + `sheetDetailProvider(id)` and pop back to queue.

### Phase 5 — Edit/delete matrix enforcement in UI

- [ ] In every place we render edit/delete affordances on an expense, gate visibility on the new `(role, sheetStatus, expenseStatus)` matrix (§1.4 / §0.7 of discovery doc).
- [ ] Keep server 409/403 as a defensive toast — if we ever paint a button we shouldn't have, the user still gets a clean error.
- [ ] Editing a `Declined` expense on a `Declined` sheet: after save, refresh sheet detail to show the auto-eval (sheet → WfA).
- [ ] Per-expense approve/decline buttons: only render when parent sheet is in `WaitingForApproval`.

### Phase 6 — Date clamp, 12-month rule

- [ ] In `new_expense_screen` (and edit screen if separate), set `firstDate = today - 12 months` on the picker.
- [ ] On submit, if the server still returns `ExpenseDateTooOld` (e.g. someone typed a date), show the localized error.

### Phase 7 — Localization

- [ ] Add EN + HE copy for every new ARB key (statuses, screen titles, CTA labels, decline-modal text, all new error codes from §5 of discovery doc).
- [ ] Verify RTL on all new screens (no `EdgeInsets.left/right`, no `TextAlign.left`, no hard-coded `Icons.arrow_back_ios`).

### Phase 8 — QA helpers (dev-only)

Decide in Q8 above whether to ship this with the main flow or after.

- [ ] Dev-menu entry behind an `AppConfig` flag.
- [ ] Button: "Backdate current cycle end" → `POST /api/test/backdate-current-cycle-end`.
- [ ] Button: "Promote cycle" → `POST /api/test/promote-cycle`.
- [ ] Both confirm-before-firing.

### Phase 9 — Smoke run + cleanup

Follow §7 of the discovery doc as the checklist:

- [ ] File expense → see "Draft" badge.
- [ ] Manager queue empty while sheet is Draft.
- [ ] Backdate + promote → sheet appears in queue.
- [ ] Whole-sheet approve.
- [ ] Whole-sheet decline without comment → blocked client + server.
- [ ] Whole-sheet decline with comment → comment visible in timeline.
- [ ] Employee edits a Declined expense → row resets to Pending, sheet flips to WfA.
- [ ] Employee deletes the only expense on a Declined sheet → sheet disappears.
- [ ] 13-month-old expense rejected.
- [ ] Soft-lock → approve/decline disabled with paywall copy.
- [ ] Search by `expenseSheetId` returns only that sheet's expenses.
- [ ] Final grep for `reopen` → still zero.

---

## 5. Risks & non-obvious gotchas

- **`cycle_expenses_report_screen.dart` is 1140 lines.** Touching it is high-risk; whatever we decide in Q2, scope the change carefully and extract widgets per CLAUDE.md screen-decomposition rules.
- **`employee_expense_detail_screen.dart` is 1013 lines.** Same risk. Consider extracting widgets *before* adding sheet-aware logic, not as part of the same change.
- **Auto-eval is not symmetric.** A bulk per-expense decline does **not** put the sheet in `Declined` — only the whole-sheet endpoint does. UI copy needs to be careful: "Sheet still waiting for approval" can be confusing if every line is rejected.
- **Hard-deleted Declined sheets.** Deleting the last expense on a `Declined` sheet makes the sheet vanish. Provider invalidation must handle the 404, not crash.
- **`expandedInsets` + fixed-width `DropdownMenu` web bug** (CLAUDE.md) — if any new screen uses dropdowns (cycle picker?), follow the documented template.
- **Date formatting uses *company locale*, not UI language** (CLAUDE.md). All new timestamps in sheet header + timeline must use `toCompanyDate` / `companyLocaleProvider`.
- **Polling cost on Approvals queue.** Server doesn't push. If we add a background timer, scope to the screen — don't leak across navigation.
- **Sheet detail 404 cross-employee.** Don't surface "you don't have access" — server intentionally returns 404 so we don't leak peer-sheet existence. Treat all 404s the same: "This sheet doesn't exist."

---

## 6. Out of scope (parking lot)

- Notifications (push) on sheet approve/decline — server doesn't emit; revisit later.
- Pagination for sheet lists — capped at 12 server-side. Only add when users hit the wall.
- Co-employee read access ("team leads who aren't formal managers") — file follow-up if requested.
- Bulk operations on the Approvals queue (approve N sheets at once) — not in MVP.

---

## 7. References

- Discovery doc: [`docs/completed/ExpenseSheetsTransformation/ExpenseSheetsEvolution.md`](./ExpenseSheetsEvolution.md)
- Product north star: [`docs/product/ai_expense_approval_mvp_north_star.md`](../../product/ai_expense_approval_mvp_north_star.md)
- Screen map: [`docs/product/mvp_screen_map.md`](../../product/mvp_screen_map.md)
- CLAUDE.md — screen scaffold, ARB-first rule, edit/delete matrix mirror requirement
