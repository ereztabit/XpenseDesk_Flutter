# Story 03 — Sheet Review

**Status:** Specced, ready to build. All server contracts verified against the live `XpenseDeskServer` repo on 2026-05-24 (not just the discovery doc).

**Opens from:** a row tap on the manager dashboard ([02-ManagerDashboard.md](02-ManagerDashboard.md)). The dashboard already wires a placeholder snackbar + a refresh-on-return contract; this story swaps the snackbar for real navigation.

**Out of scope:** employee-initiated sheet review (employees act on their own sheet inline on the employee dashboard — story 01), per-line rejection *reasons* (a separate backlog feature — see §3.6), paginated history.

---

## 1. TL;DR

Sheet Review is the manager's **decision screen**. The manager dashboard is the inbox (which sheets need attention); this is where they act. One screen, manager-only route, three stacked zones:

1. **Header card** — sheet status badge, employee, cycle, submitted/reviewed timestamps, decline-comment callout (if previously declined), and the two whole-sheet CTAs.
2. **Line items** — the sheet's expenses. Each tappable to view detail; each with per-line approve/decline as a power-user escape hatch.
3. **Activity timeline** — the status-log audit trail (`Draft → WaitingForApproval → Declined "fix categories" → …`).

**Action availability is driven by sheet status, not by role:**
- Sheet is `WaitingForApproval` → full actions (approve sheet / decline sheet / per-line).
- Sheet is `Approved` or `Declined` → **read-only** (header + lines + timeline, no action affordances).

The whole-sheet flow is the default per product (one decision per employee per month). Per-line is secondary.

---

## 2. UX spec

### 2.1 Core concepts
- Manager taps a sheet row on the dashboard → navigates here with the `expenseSheetId`.
- Screen loads the full sheet via `sheetDetailProvider(id)` (**already built** in story 01).
- **Whole-sheet approve** flips every still-pending line to approved → sheet `Approved`.
- **Whole-sheet decline** requires a comment, flips every still-pending line to declined → sheet `Declined`. The comment is what the employee sees in their declined-sheet banner (story 01).
- **Per-line approve/decline** is allowed only while the sheet is `WaitingForApproval`. After each per-line mutation the server **auto-evaluates** the sheet (discovery doc §0.6): if every line ends up approved, the sheet auto-flips to `Approved`; a per-line decline never flips the sheet to `Declined` (only the whole-sheet decline does).
- After any successful action, refresh the sheet detail. If the sheet left `WaitingForApproval` (→ Approved / Declined), the screen switches to read-only in place; the manager can pop back to the dashboard (which re-fetches its buckets via the wired refresh-on-return contract).

### 2.2 Header card
- Status badge (reuse `SheetStatusBadge`, 4-state — built in story 01).
- Employee name + email, cycle label (locale long-month via `toCycleLongMonth`), expense count, sheet total.
- `submittedAt` / `reviewedAt` timestamps (company-locale formatted).
- **Decline-comment callout** — when the sheet has a `latestDeclineComment`, render it (reuse the visual language of the employee `DeclinedSheetBanner`). Relevant when a manager re-opens a sheet that bounced.
- **CTAs** (only when sheet is `WaitingForApproval`):
  - **Approve sheet** — primary. Opens a lightweight confirm dialog ("Approve all N items?") to prevent fat-finger, then calls `approveSheet(id)`.
  - **Decline sheet** — destructive/secondary. Opens the **decline-comment modal** (§2.5) — comment required.

### 2.3 Line items
- Reuse the expense row/card widgets from story 01 where possible (`ExpenseSummary` is the line shape — the detail endpoint nests `ExpenseListItemResponse`, which the client maps via `ExpenseSummary.fromJson`).
- Each line shows: merchant, category (+ `AiBadge` when `isAiData`), amount, per-line status badge.
- Tapping a line → existing manager expense detail route `/manager/expense/{id}` (read-only-aware).
- **Per-line actions** (only when sheet is `WaitingForApproval`): approve (success) + decline (destructive). Secondary to the whole-sheet CTAs.

### 2.4 Activity timeline
- Renders `ExpenseSheetDetail.log[]` (built in story 01 as `ExpenseSheetLogEntry`, with `isSystemDriven`).
- Each entry: `fromStatusAlias → toStatusAlias`, actor (`changedByName`, or "System / Cycle close" when `isSystemDriven`), timestamp, and `comment` when present (decline transitions).
- Vertical list, naturally responsive.

### 2.5 Decline-comment modal / sheet
- **Desktop:** centered dialog, max ~448px. Single multiline text field (required) + Cancel + Decline (destructive). Decline button disabled until non-empty.
- **Mobile:** bottom sheet (consistent with the existing `showMobileExpenseModal` pattern), same required-comment field.
- Client enforces non-empty before submit; if it somehow slips through, map the server's `400 ExpenseSheetDeclineCommentRequired` to the same field error.

### 2.6 Responsive — first-class (desktop ≠ mobile)

| Zone | Desktop (≥768) | Mobile (<768) |
|---|---|---|
| Header CTAs | Inline on the header card, trailing edge | **Sticky bottom action bar** — pinned, thumb-reachable while scrolling lines |
| Line items | Table (merchant / category / amount / status / per-line actions column) | Cards or compact rows |
| Per-line actions | Inline ✓/✗ buttons in the row's action column | **Swipe-to-approve/decline** — reuse `ManagerSwipeableExpenseCard` (already exists: pending→Approve+Decline, approved→Decline, declined→Approve) |
| Decline modal | Centered dialog (~448px) | Bottom sheet |
| Timeline | Vertical list | Vertical list, denser padding |

**Reuse, don't reinvent:** `lib/widgets/expenses/manager_swipeable_expense_card.dart` already implements mobile swipe-to-approve/decline per expense status. Audit it first; lift or adapt rather than building new.

### 2.7 Edge cases
- **Sheet 404 on load** (deleted / hard-deleted / not visible) → "This sheet no longer exists." + a back button. The server returns 404 the same way for not-found and not-authorized (no existence leak).
- **Sheet not `WaitingForApproval` on arrival** (manager opened it from the Approved or Returned bucket) → read-only, no CTAs, no per-line actions.
- **Action races (409 `ExpenseSheetWrongStatusForAction`)** — the sheet changed state between the dashboard list-fetch and the tap (e.g. the employee just edited it, auto-promoting it; or a cycle job moved it). Show "This sheet is no longer waiting for approval", refresh the detail, drop into read-only.
- **Per-line approve on the last pending line** → sheet auto-flips to `Approved`. Refresh; screen goes read-only; CTAs disappear.
- **Per-line decline of every line** → sheet **stays** `WaitingForApproval` (auto-eval never targets Declined). UI copy must not imply "all rejected = sheet rejected." The manager must use the whole-sheet decline to actually decline.
- **Block-mode active** (`SoftLocked` / `MustPayNextLogin`) → server returns `403 SubscriptionRequired` on approve/decline. We surface a clear error (and ideally pre-gate — see §3.5).

---

## 3. Server Contract — verified 2026-05-24

All endpoints `[Authorize]`, standard `{success, message, errorCode, data}` envelope. Verified against `Controllers/ExpenseSheetsController.cs`, `Controllers/ExpensesController.cs`, and the response DTOs.

### 3.1 `GET /api/expense-sheets/{id}` — load the sheet — ✅ already wired
- Returns `ExpenseSheetDetailResponse`: header + `expenses[]` (`ExpenseListItemResponse`) + `log[]` (`ExpenseSheetStatusLogEntryResponse`).
- Role guard: active manager OR the sheet's creator. Anyone else → `404 ExpenseSheetNotFound`.
- **Client status:** `getSheetDetail(id)` + `sheetDetailProvider.family<sheetId>` + `ExpenseSheetDetail` / `ExpenseSheetLogEntry` models all built in story 01. **No new model work.**

### 3.2 `POST /api/expense-sheets/{id}/approve` — whole-sheet approve — ⚠️ new client method
- Manager only (`403` otherwise). Block-mode gated (`403 SubscriptionRequired`). **No request body.**
- Success: `200 { success: true, message: "Expense sheet approved successfully." }`.
- Errors: `404 ExpenseSheetNotFound`, `409 ExpenseSheetWrongStatusForAction` (not WaitingForApproval), `403 SubscriptionRequired`.
- Server behavior: every still-pending line → approved (stamped with manager id/time); already-approved/declined lines untouched; sheet → Approved.
- **Client status:** NOT wired. Add `approveSheet(id)`.

### 3.3 `POST /api/expense-sheets/{id}/decline` — whole-sheet decline — ⚠️ new client method
- Manager only. Block-mode gated. **Body:** `{ "comment": "non-empty string" }` (`DeclineExpenseSheetRequest`).
- `comment` required → `400 ExpenseSheetDeclineCommentRequired` if empty/whitespace.
- Success: `200 { success: true, message: "Expense sheet declined successfully." }`.
- Errors: `400 ExpenseSheetDeclineCommentRequired`, `404 ExpenseSheetNotFound`, `409 ExpenseSheetWrongStatusForAction`, `403 SubscriptionRequired`.
- Server behavior: every still-pending line → declined; already-approved lines untouched (they stay approved on a declined sheet); sheet → Declined; comment stored on the log row → surfaces as `latestDeclineComment`.
- **Client status:** NOT wired. Add `declineSheet(id, comment)`.

### 3.4 `POST /api/expenses/{id}/approve` and `/decline` — per-line — ✅ already wired
- Manager only (`RoleId == 1`). Block-mode gated. **No request body** (no per-line reason — see §3.6).
- Only valid while the parent sheet is `WaitingForApproval`; otherwise the SQL guard fires → `400 { message: "Unable to approve/decline expense" }` (generic, no specific errorCode).
- After the mutation the server auto-evaluates the sheet (§2.1 / discovery doc §0.6).
- **Client status:** `approveExpense(id)` + `declineExpense(id)` already exist in `ExpenseService` (lines 373/387). **No new method**; just call them from the new UI and refresh the detail after.

### 3.5 Block-mode — **gap to note**
Block-mode (`SoftLocked` / `MustPayNextLogin`) is **not surfaced anywhere in the Flutter client today** (grep for `blockMode` → zero hits). The server enforces it on all four approve/decline endpoints (`403 SubscriptionRequired`). For this story:
- **Minimum:** handle the `403 SubscriptionRequired` gracefully — show a clear "Your subscription doesn't allow this action" message, don't crash.
- **Better (optional, may defer):** pre-gate the CTAs by reading block-mode from `GET /api/company`. Requires surfacing `blockMode` into a provider first — that's arguably its own small story. **Decision needed (§4).**

### 3.6 Per-line decline has no reason field — confirmed
The backlog item "Missing rejection reason field for manager" is a **separate future feature**. Today, per-line `/decline` takes no body. Only the **whole-sheet** decline carries a comment. Story 03 builds to the current contract: per-line decline is comment-less; the sheet-level comment is the explanation channel.

### 3.7 `/api/expenses/{id}/reopen` — gone
Confirmed removed server-side. No "reopen" affordance anywhere in this screen. A manager who wants to undo waits for the employee to resubmit (auto-eval) or contacts them.

> **Update (2026-06-11) — partially superseded.** The whole-sheet
> `POST /api/expense-sheets/{id}/approve` now also accepts `Declined` sheets:
> a manager can approve a sheet they previously returned (declined lines stay
> declined; an all-declined sheet just closes as Approved with ₪0). Re-declining
> a Declined sheet is still rejected, and the per-expense `reopen` endpoint
> stays dead. See docs/in-progress/manager-reapprove-declined-sheet.md.

---

## 4. Decisions — resolved 2026-05-24

1. **Block-mode pre-gating (§3.5): DEFERRED.** This story handles the `403 SubscriptionRequired` gracefully (clear message, no crash) but does NOT pre-gate the CTAs. Surfacing `blockMode` into a provider is a separate cross-cutting follow-up.
2. **Sheet-level decline comment: confirmed API-provided.** `POST /api/expense-sheets/{id}/decline` requires `{ comment }`; it surfaces as `latestDeclineComment`. Per-line decline stays comment-less — one explanation channel at the sheet level, by design. No per-line reason field in this story.
3. **Per-line decline-all stays WaitingForApproval: noted, treat as a low-priority edge case.** The behavior is correct as-is (the sheet only declines via the whole-sheet endpoint). We keep the whole-sheet flow as the obvious primary path but do NOT over-invest in special warning copy for the decline-all scenario. Revisit only if it confuses real users.
4. **Approve confirmation dialog:** light confirm ("Approve all N items?") to prevent fat-finger bulk approve.
5. **Read-only entry from Approved/Returned buckets:** in scope — the screen renders read-only for non-`WaitingForApproval` sheets. Status drives it; no separate route.

---

## 5. Architecture

### 5.1 Models — all already exist ✅
- `ExpenseSheetDetail`, `ExpenseSheetLogEntry`, `ExpenseSummary` (with sheet fields), `ExpenseSheetStatus` — all built in story 01. **Zero new models.**

### 5.2 Service additions (`lib/services/expense_service.dart`)
- `approveSheet(String sheetId)` → `POST /api/expense-sheets/{id}/approve`. Map `409 → ExpenseSheetWrongStatusException` (new), `404 → ExpenseSheetNotFoundException` (exists), `403 SubscriptionRequired → SubscriptionRequiredException` (new typed exception).
- `declineSheet(String sheetId, String comment)` → `POST /api/expense-sheets/{id}/decline`. Same mappings + `400 ExpenseSheetDeclineCommentRequired → DeclineCommentRequiredException` (new).
- New typed exceptions: `ExpenseSheetWrongStatusException`, `DeclineCommentRequiredException`, `SubscriptionRequiredException`.
- `approveExpense` / `declineExpense` — already exist; reuse.

### 5.3 Providers
- `sheetDetailProvider.family<String>` — exists. Invalidate after every action.
- No new providers strictly required. (A small `StateProvider` for "action in flight" can live as local screen state.)

### 5.4 Routes (`router.dart`)
- Add `/manager/sheet/{id}` → `SheetReviewScreen`, wrapped in `AuthGate(managerOnly)`. Follows the existing `/manager/expense/{id}` default-branch pattern.
- Swap the manager dashboard `_onRowTap` snackbar for `Navigator.pushNamed('/manager/sheet/${sheet.expenseSheetId}').then((_) => _refreshSheetProviders())`. The refresh contract is already wired.

### 5.5 Screen decomposition (CLAUDE.md < 200 lines orchestrator)

```
lib/screens/sheet_review_screen.dart        # orchestrator (~150): state, provider, layout, action handlers
lib/widgets/sheet_review/
  sheet_review_header_card.dart              # status badge + employee/cycle/timestamps + decline-comment callout
  sheet_review_actions.dart                  # the two CTAs — inline (desktop) vs sticky bottom bar (mobile)
  decline_sheet_dialog.dart                  # required-comment modal (dialog desktop / bottom sheet mobile)
  approve_sheet_confirm_dialog.dart          # "Approve all N items?" confirm
  sheet_review_line_list.dart                # responsive switch: desktop table vs mobile cards
  desktop_sheet_review_table.dart            # line-item table + per-line ✓/✗ action column
  desktop_sheet_review_row.dart              # one line row
  mobile_sheet_review_list.dart              # mobile cards; reuses ManagerSwipeableExpenseCard when WfA
  sheet_activity_timeline.dart               # renders log[]
  sheet_activity_timeline_entry.dart         # one log row (system vs user, optional comment)
```

Reuse from earlier stories: `SheetStatusBadge`, `AiBadge`, `ActionIconButton`, `ManagerSwipeableExpenseCard`, `toCompanyDate`/`toCurrency`/`toCycleLongMonth`, the `DeclinedSheetBanner` visual language for the callout.

---

## 6. Tasks (sequenced slices)

### Slice 1 — Service + exceptions (no UI)
- [ ] `approveSheet(id)`, `declineSheet(id, comment)` on `ExpenseService`.
- [ ] Typed exceptions: `ExpenseSheetWrongStatusException`, `DeclineCommentRequiredException`, `SubscriptionRequiredException`.
- [ ] ARB keys (§7) EN + HE before any widget code.
- [ ] Build clean.

### Slice 2 — Route + screen scaffold + header card
- [ ] Register `/manager/sheet/{id}` in `router.dart` (AuthGate managerOnly).
- [ ] `SheetReviewScreen` scaffold per CLAUDE.md (AppHeader → Expanded → SingleChildScrollView → ConstrainedContent → Column). Loads `sheetDetailProvider(id)`; 404 + loading + error states.
- [ ] `sheet_review_header_card.dart` — badge, employee, cycle, timestamps, decline-comment callout.
- [ ] Wire the manager dashboard row tap to navigate here.

### Slice 3 — Line items (desktop table + mobile list)
- [ ] `sheet_review_line_list.dart` responsive switch.
- [ ] `desktop_sheet_review_table.dart` + `desktop_sheet_review_row.dart` (fixed-width action column per CR Rule 6).
- [ ] `mobile_sheet_review_list.dart` — reuse `ManagerSwipeableExpenseCard` when WfA, read-only card otherwise.
- [ ] Line tap → `/manager/expense/{id}`.

### Slice 4 — Whole-sheet approve
- [ ] `sheet_review_actions.dart` — inline (desktop) / sticky bottom bar (mobile). CTAs only when WfA.
- [ ] `approve_sheet_confirm_dialog.dart`.
- [ ] Wire `approveSheet`; on success invalidate `sheetDetailProvider(id)`; screen goes read-only; handle 409/404/403.

### Slice 5 — Whole-sheet decline
- [ ] `decline_sheet_dialog.dart` (dialog desktop / bottom sheet mobile), required comment.
- [ ] Wire `declineSheet`; invalidate detail; handle 400/409/404/403.

### Slice 6 — Per-line approve/decline
- [ ] Desktop inline ✓/✗ in the action column; mobile swipe (ManagerSwipeableExpenseCard).
- [ ] Call existing `approveExpense`/`declineExpense`; after each, invalidate the detail and handle the auto-eval outcome (sheet may flip to Approved → read-only).
- [ ] Copy guard: per-line decline-all does NOT decline the sheet — don't imply otherwise.

### Slice 7 — Activity timeline
- [ ] `sheet_activity_timeline.dart` + `sheet_activity_timeline_entry.dart`.
- [ ] System vs user rendering; comment on decline transitions.

### Slice 8 — RTL / locale / formatting sweep
- [ ] Cycle labels, dates, amounts via the company-locale utils. Logical insets. Hebrew RTL pass.

### Slice 9 — Smoke + CR pass
- [ ] All §2.7 edge cases walked through (404, read-only entry, 409 race, per-line auto-flip, per-line decline-all stays WfA, block-mode 403).
- [ ] `/code-review` per the six rules. Orchestrator < 200 lines, no embedded substantial widgets, no hardcoded currencies/captions.

---

## 7. i18n keys (EN + HE, added before widget code)

**Header / actions**
- `sheetReviewTitle`, `approveSheet`, `declineSheet`, `approveSheetConfirmTitle`, `approveSheetConfirmBodyPrefix` (concat with count), `sheetApprovedToast`, `sheetDeclinedToast`

**Decline modal**
- `declineSheetTitle`, `declineSheetCommentLabel`, `declineSheetCommentHint`, `declineSheetCommentRequired`, `declineSheetConfirm`

**Per-line + errors**
- `approve`, `decline` (likely exist — verify), `sheetWrongStatusError`, `actionSubscriptionRequired`, `sheetNoLongerExists`

**Timeline**
- `activityTimelineTitle`, `timelineSystemActor`, `timelineCycleClose`

> Reuse where they already exist (`reviewSheet`, `view`, `sheetStatus*`, `itemsCount*`, `cycle`, `items`, etc.). Verify before adding duplicates. No ARB placeholders — concat counts/dates in the widget.

---

## 8. Risks & gotchas
- **`manager_dashboard_screen.dart` `_onRowTap`** has a `TODO(story-03)` marker — the swap point. Don't forget to also keep `_refreshSheetProviders()` in the `.then()`.
- **Auto-eval surprise** — the sheet can change status as a *side effect* of a per-line action. Always refresh the detail after a per-line mutation and re-derive read-only vs. actionable from the fresh status. Never assume the local status is still valid post-action.
- **Per-line decline semantics** — the single most confusing rule. Declining every line individually leaves the sheet WaitingForApproval. The manager MUST use the whole-sheet decline to decline. Copy + affordance design must make the whole-sheet path the obvious one.
- **Block-mode is unsurfaced client-side** — handle the 403 defensively; pre-gating is a deferred follow-up (§4 decision 1).
- **`ManagerSwipeableExpenseCard` reuse** — it was built for the *old* manager dashboard's flat expense list. Confirm its callbacks (`onApprove`/`onDecline`) and status-driven button logic still fit; adapt rather than fork.
- **Read-only correctness** — a manager opening an already-Approved sheet from the Approved bucket must see zero action affordances. Drive everything off `statusId == WaitingForApproval`.

---

## 9. Done definition
- §2 implemented end-to-end on web (desktop + mobile breakpoints), EN + HE.
- All §2.7 edge cases manually verified.
- All four endpoints exercised against the live server.
- Manager dashboard row tap navigates here; refresh-on-return confirmed (sheet that was acted on moves buckets on the dashboard).
- `/code-review` clean; orchestrator < 200 lines; CR doc `03-SheetReview-CR.md` written.
- §4 open decisions recorded with final answers.
