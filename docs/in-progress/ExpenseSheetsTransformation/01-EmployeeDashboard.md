# Story 01 — Employee Dashboard

**Status:** Ready to build. Server-contract gaps in §3 were resolved on 2026-05-23 — we are aligning the client to the server's model (no "Reopened" mode, no Resubmit button). See §3 for the decisions and §FAQ in the discovery doc for the rationale.

**Replaces:** the current employee main view at [`lib/screens/user_dashboard_screen.dart`](../../../lib/screens/user_dashboard_screen.dart) (383 lines — entire body to be rebuilt; route preserved).

**Out of scope:** Manager dashboard, expense-detail / new-expense / edit screens, finalised-sheet history, server-side changes.

---

## 1. TL;DR

When an employee opens the app, they no longer see a flat "list of expenses + processed component". They see **their current expense sheet** — a sheet-centric workspace driven by a picker at the top. The picker lists every non-finalised sheet they own (current-cycle draft + any past-cycle drafts that came back after a rejection + anything they've already submitted). The list, actions, alerts, and filter tabs below all react to the picker selection.

Four stacked zones, top to bottom:

1. **Page header** — title · view-mode toggle (mobile only) · "New expense" button
2. **Sheets Picker & Alerts** — global returned-sheet banner, picker dropdown, declined-sheet banner (when applicable)
3. **Status filter tabs** — only when the selected sheet is in **Declined** mode (Rejected · Pending · Approved buckets)
4. **Expenses list** — scoped to the picker selection (mobile: cards or list; desktop: table)

Every behavior rule is in §2. Every server-contract concern is in §3. Tasks are in §6.

---

## 2. UX spec — what we're building

(This section paraphrases the canonical UX guideline; if you find a contradiction with this story, the guideline wins. The verbatim spec lives in conversation history and should be embedded into this story as needed.)

### 2.1 Core concepts
- An **Expense Sheet** = one employee × one billing cycle.
- Sheet has one of these UI modes, mapped 1:1 from the server's `expenseSheetStatusId`:
  - `Draft` — `statusId=1`. Current-cycle work-in-progress; auto-submits at cycle close.
  - `Submitted` — `statusId=2` (`WaitingForApproval`). Sitting with the manager. Read-only.
  - `Declined` — `statusId=4`. Manager returned the sheet with a comment. The employee fixes/deletes the rejected line items; the sheet **auto-promotes back to `Submitted` (or `Approved`)** as the items are addressed. No explicit "resubmit" action exists. See §3.1, §3.2 + discovery-doc FAQ.
  - (`statusId=3` `Approved` is finalised and **does not show on this screen** — it lives in history.)
- Dashboard only shows **non-finalised** sheets (`Draft + Submitted + Declined`).
- New expenses ALWAYS attach to the current-cycle clean Draft, regardless of picker selection.
- Picker default selection = current-cycle Draft; selection is local UI state, not persisted across sessions.

### 2.2 Page header
- Title: `myExpenses` (locale-aware, semibold).
- View-mode toggle (**mobile only**, visible only when the sheet is an editable Draft *and* at least one expense renders):
  - Square ghost icon button (~32×32), icon swaps between **list** and **gallery**, persists choice to local storage (`expense_layout_mode`).
- **New expense** button — primary filled, leading `+`. Enabled **only** when the picker is on the current-cycle clean Draft. Rendered but disabled in Submitted / Declined modes.

### 2.3 Sheets Picker & Alerts (zones A–C)

**A. Global Returned-Sheet Alert** (conditional banner)
- Shows when ≥1 returned sheet exists AND the picker is NOT currently on one of those returned sheets.
- Destructive color scheme (red 40% opacity border, red 5% tinted background, ~6–8px radius).
- Mobile copy: `returnedSheetsAlertShort`. Desktop: `returnedSheetsAlertSingle` (n=1) or `returnedSheetsAlert` with `{n}` token.
- **Review** button — sets picker to first returned sheet (no navigation).
- **Dismiss** (X). Dismissal key = sorted returned-sheet IDs joined by `|`, persisted under `returned_alert_dismissed_key`. Banner re-appears automatically if the set of returned sheets changes.

**B. Sheet Picker (dropdown)**
- Order: current-cycle Draft first, then remaining active sheets by cycle id descending.
- Two-row trigger and items (identical layout):
  - Row 1: icon (destructive alert for Declined, neutral document otherwise) · cycle label (locale long-month, e.g. "March 2026") · status badge on trailing edge
  - Row 2: meta line (muted, 12px) — `sentForApprovalOn {date}` for Submitted, `itemsCount {count}` otherwise · trailing total amount with currency **symbol as suffix** (e.g. `115.00₪`)
- Dropdown panel ≤320px, never wider than `viewport - 32px`. Respects RTL.
- Declined mode: trigger border = destructive 40%, background = destructive 5%.
- **Status badge mapping.** The badge widget supports all four server statuses so it can be reused by the manager dashboard (story 02). The employee dashboard only ever renders three of them (Approved sheets are finalised and live in history — they don't appear in the picker).

  | Server status (`statusId`)         | Label key                | Tone        | Rendered on employee dashboard? |
  |------------------------------------|--------------------------|-------------|---------------------------------|
  | `Draft` (1)                        | `sheetStatusDraft`       | muted       | yes                             |
  | `WaitingForApproval` (2)           | `sheetStatusAwaiting`    | amber       | yes                             |
  | `Approved` (3)                     | `sheetStatusApproved`    | success     | no (manager dashboard only)     |
  | `Declined` (4)                     | `sheetStatusReturned`    | destructive | yes                             |

  > User-facing copy: "Returned" reads better than "Declined" — the badge label key (`sheetStatusReturned`) is deliberate. Internally / in code we use `Declined` to mirror the server.

**C. Declined-Sheet Banner** (visible only in Declined mode, attached to picker row)
- Mobile (<768px): stacks below picker, full width.
- Desktop (≥768px): inline on the picker row, hugging trailing edge **or** stacked below if the row is too tight — pick whichever reads better; the banner is the visual focus, the picker is secondary in this mode.
- Destructive color scheme matching the picker border (red 40% border, red 5% background tint, ~6–8px radius).
- Content (stacked, in order):
  1. Title row: destructive alert icon + bold prefix `declinedByManagerPrefix` (e.g. "{managerName} declined this sheet:") — manager name pulled from `reviewedByName`; fallback to `declinedByManagerFallback` ("Your manager declined this sheet:") when `reviewedByName` is null.
  2. The raw `latestDeclineComment` text (preserve line breaks, no rich rendering).
  3. Explainer copy `declinedSheetExplainer` — "Fix or remove the highlighted items below. Your sheet will return to your manager automatically when every rejected item is addressed."
  4. *(Optional, only when at least one Declined item remains)* a quiet progress hint: `'$remaining ${l10n.declinedSheetProgressHint}'` → "2 of 3 items still need attention." Build by concatenation per CLAUDE.md ARB rule.
- **No buttons.** There is no Resubmit action. The auto-flow is server-driven (see §3.2 + discovery-doc FAQ).
- After every successful per-expense edit/delete on a `Declined` sheet, the screen invalidates `sheetDetailProvider(id)` so the user immediately sees the badge flip (`Declined → WaitingForApproval` once non-Declined items remain, or `Declined → Approved` if everything left is Approved, or the sheet hard-deletes if everything is gone).
- If `latestDeclineComment` is null/empty (rare — only when a sheet reached Declined via a path that didn't carry a comment), drop content row 2 and tighten the layout. Banner still renders so the explainer copy is shown.

**State matrix** (drives every other zone):

| Mode      | Picker icon        | Picker border    | Declined banner | Global alert         |
|-----------|--------------------|------------------|-----------------|----------------------|
| Draft     | document, muted   | default          | hidden          | shown if OTHER returned exists |
| Submitted | document, muted   | default          | hidden          | shown if OTHER returned exists |
| Declined  | alert, destructive | destructive tint | **shown**       | hidden (avoid double cue) |

### 2.4 Status filter tabs (Declined mode only)
- Sits directly under the picker + banner, above the list.
- Three tabs in fixed order, omitting empty buckets: **Rejected** (destructive — the `Declined` per-expense bucket), **Pending** (primary), **Approved** (success).
- Tab content: label · count chip · *(desktop only)* `· {total}` appended.
- Mobile: full-pill, equal-width flex. Desktop: top-rounded corners, butting onto the table card below; active tab raises one z-layer.
- Default selection: Rejected. If empty, auto-pick the first non-empty bucket in order.
- Per-bucket editability + server-side consequence (drives row affordances and gestures):
  - **Rejected** (per-expense `Declined`): edit + delete. **Editing auto-resets the expense to Pending** and re-evaluates the sheet — that's how the sheet returns to the manager. **Deleting** also re-evaluates; if all remaining items are Approved, sheet auto-flips to Approved with no manager re-review.
  - **Pending**: edit + delete. No status side-effects.
  - **Approved**: read-only (eye icon, no delete, no swipe). Server blocks deletes (`403`) and edits (`409 ExpenseEditApprovedExpenseOnDeclinedSheet`) on this bucket while the sheet is Declined.
- Visual emphasis: items in the Rejected bucket get a destructive accent (e.g. left border + tinted background) so they pop as "the actionable ones" — they are the only path back to the manager.

### 2.5 Expenses list

**Desktop (table card):**
- Columns: **# (8%)**, Date (20%), Amount (15%), Category (25%), Merchant (22%), Actions (10%).
- The **#** column is a **positional row number** (1-indexed within the visible list, not the expense's `receiptRef` field). The mobile carousel and list views render the same number as a small leading badge before the merchant name. The expense's `receiptRef` does not render on this dashboard at all (it lives on the expense detail screen).
- Amount uses the project's currency format (confirm prefix vs suffix in `lib/utils/format_utils.dart` during Slice 1 — single company currency, no multi-currency on this screen). Date uses the company locale. Category cell may show small "AI" badge.
- Actions: Edit (pencil) when editable, View (eye) otherwise → routes to expense detail. Delete (trash, destructive) only when the bucket allows delete.
- Empty state inside the card: sparkle in tinted circle, `employeeEmptyStateTitle`, `employeeEmptyStateDesc` (Draft) or `noExpensesPendingDesc` (other), "+ New expense" only when adding is allowed.

**Mobile (toggle-driven):**
- **Card / Carousel view** (default): one expense per card, swipe horizontally between cards; bidirectional swipe-to-delete when bucket allows; tap opens read-only-aware bottom-drawer detail.
- **List view**: compact stacked rows; inline edit/view/delete icons.
- Empty state mirrors desktop, inline above the list area.

**Delete confirmation:** centered modal, RTL-aware, `deleteExpenseTitle`, `deleteExpenseConfirm`, Cancel + Delete (destructive).

### 2.6 Cross-zone rules
- Picker selection drives every zone below.
- Adding a new expense **always** targets the current-cycle clean Draft. Disabled outside that mode.
- Edit allowed when: Draft mode, OR Declined mode AND active tab is Rejected/Pending.
- Delete follows the same rule.
- Submitted sheets are fully read-only (server enforces this; UI mirrors it).
- **There is no Resubmit action.** A Declined sheet returns to the manager automatically once every Declined line on it is either edited (auto-resets to Pending) or deleted. The server re-evaluates after each mutation; the client refreshes `sheetDetailProvider(id)` after every successful PUT/DELETE on a Declined sheet so the badge update is visible immediately.
- Cycle close: any non-empty current-cycle Draft auto-submits; empty drafts are discarded. Declined sheets are **not** touched by cycle promotion — they wait for the employee to address them.

### 2.7 Edge cases
- Zero active sheets → hide picker/alerts/tabs/list; show desktop empty state directly.
- Submitted sheet missing `submittedAt` → fall back to creation date for `sentForApprovalOn`.
- Declined sheet with empty/null `latestDeclineComment` → banner still renders (the auto-resubmit explainer is the load-bearing part); drop the comment row only.
- Returned-sheet set changes while alert is dismissed → alert reappears (key mismatch).
- Currently-selected sheet IS a Declined sheet → global alert hidden (no double cue; the banner is right there).
- Default Declined tab (Rejected) is empty → auto-pick next non-empty bucket. This is a real path: the employee already fixed every rejected item and the sheet just hasn't reloaded; the next refresh will move the sheet out of Declined entirely.
- Editing the last remaining `Declined` expense on a `Declined` sheet → sheet auto-promotes to `WaitingForApproval`. Selection should stay on the same sheet id; picker badge flips to amber.
- Deleting the last remaining expense on a `Declined` sheet → sheet **hard-deletes server-side**. Client must catch the next 404, drop the selection, and fall back to the picker default (current-cycle Draft).
- Deleting all `Declined` expenses while some Approved remain → sheet auto-promotes to `Approved` with no manager re-review. Sheet leaves the dashboard (Approved is finalised → history); fall back to picker default.
- Picker has only one sheet → still render as a dropdown for consistency.

---

## 3. Server Contract Reconciliation — resolved 2026-05-23

The UX spec was originally written against a mental model where the employee explicitly drives the sheet back to the manager. The server intentionally doesn't work that way. The decisions below align the client to the server's model. The discovery doc — [`ExpenseSheetsEvolution.md`](ExpenseSheetsEvolution.md) — carries the full rationale in its "FAQ for Flutter teams" section.

### 3.1 "Reopened draft" doesn't exist on the server — DROP the concept

**Decision (2026-05-23):** No `reopened` flag. No fifth state. The `Declined` sheet status IS the "needs fixing" state.

**Mental-model swap:**

| Old mental model                                | New mental model                                                                |
|------------------------------------------------|---------------------------------------------------------------------------------|
| Sheet enters a special "draft with reopened flag" state | Sheet sits in `Declined` (`statusId=4`)                                |
| UI shows the flag as a callout                  | UI uses `statusAlias = "Declined"` + `latestDeclineComment`                     |
| Employee "fixes" then taps Resubmit             | Employee edits or deletes the Declined items; status flips on its own           |

**Why this works:** the signal the UX was reaching for — "this sheet needs my attention" — is already carried by `statusId == 4` plus a non-null `latestDeclineComment`. No new flag, no new status, no client-side state machine. A subtle bonus: if the employee *deletes* every Declined item and the rest were already Approved, the sheet auto-flips to `Approved` (no manager re-review). The "reopened draft + flag" model could not express that nuance.

**Client impact:**
- Drop any `reopened` field from local sheet models.
- Mode enum is just `Draft | Submitted | Declined` (mirroring `statusId` 1/2/4).
- Picker's destructive styling triggers off `statusId == 4`.

### 3.2 "Resubmit" button has no endpoint — DROP the button

**Decision (2026-05-23):** No `/resubmit` endpoint. Replace the button with a **passive banner** that explains the auto-flow.

**Why no endpoint:**
- An explicit `/resubmit` endpoint would introduce a real failure mode — the employee fixes everything, forgets to tap the button, manager waits indefinitely. Auto-eval eliminates that class of bug.
- Auto-eval correctly handles "fix two, delete the third", "delete everything rejected so the sheet auto-approves with no manager re-review", and "edit then re-edit" — without UI choreography.
- Two ways to do the same thing would race; the button would frequently 409 because the server already promoted the sheet.

**Banner copy (replaces button):**
> *Fix or remove the highlighted items below. Your sheet will return to your manager automatically when every rejected item is addressed.*

Optional progress hint, only when ≥1 Declined item remains:
> *2 of 3 items still need attention.*

**Client impact:**
- Drop the Resubmit button widget and all `resubmitSheet*` i18n keys.
- Drop the standalone manager-note dialog — fold its content into the banner inline.
- After every successful PUT/DELETE on a `Declined` sheet, invalidate `sheetDetailProvider(id)` so the picker badge flips visibly. **That is the moment of visible feedback that replaces the old "Resubmit" tap.**
- Style Declined per-expense rows so they pop visually (they're the actionable items).

### 3.3 "partially_rejected" is not a server status

**UX spec:** Status badge `sheetStatusApprovedWithRejections` maps to `partially_rejected`.

**Server:** Sheet statuses are `Draft | WaitingForApproval | Approved | Declined`. An `Approved` sheet **can** contain some Declined expenses (because per-expense decisions during the approval flow stick around — see discovery doc §0.5/§0.6), but the sheet status itself is just `Approved`.

**Options:**
- **(a)** Derive `partially_rejected` client-side from `(sheetStatus == Approved) && (any expense has expenseStatusId == 3 Declined)`. The badge stays in UI; server schema unchanged.
- **(b)** Ask backend to project a derived `displayStatus` field on the sheet payload.
- **(c)** Drop the `partially_rejected` distinction; show all approved sheets with the same badge. (Spec says these are finalised and don't show on the employee dashboard anyway — only in history — so the badge only matters in history surface; revisit then.)

**Decision:** _pending — but lowest priority since these don't appear on this screen._

### 3.4 Cycle label formatting needs a date source

**UX spec:** Picker shows cycle labels formatted as locale long-month — `DateFormat.yMMMM(locale)`, e.g. "March 2026" / "מרץ 2026".

**Server:** Sheet list rows expose `cycleLabel: "2026/05"` and `expenseCycleId`. Only the **sheet detail** endpoint includes `cycleStartAt`.

**Options:**
- **(a)** Parse `"2026/05"` client-side into a DateTime and format.
- **(b)** Ask backend to expose `cycleStartAt` on the list projection too.

**Decision:** _pending — recommend (a) for now, it's trivial._

### 3.5 Submitted-at fallback

**UX spec:** "Submitted sheet missing a submitted-at timestamp: fall back to the creation date for the `sentForApprovalOn` token."

**Server:** Sheet detail provides `submittedAt`; list projection also exposes `submittedAt`. The fallback path may never fire — but the spec is correct as a defensive measure. **No server change needed.**

### 3.6 Empty `rejectionNote`

**UX spec:** Hide Manager Note button if `rejectionNote` is empty.

**Server:** Decline endpoint **requires** a non-empty comment (returns 400 `ExpenseSheetDeclineCommentRequired` otherwise), surfaced on the detail as `latestDeclineComment`. So in practice an empty `rejectionNote` should never happen for sheets reached via the normal decline flow. But: a sheet with no log entry yet (or one only declined via per-expense decline — which the server doesn't model as a whole-sheet decline) won't have `latestDeclineComment`. The defensive UX is still correct.

**Decision:** No server change. Treat absence/empty/whitespace as "no note".

---

## 4. Decisions resolved (vs. the earlier implementation plan)

The UX spec answers most of the questions parked in [`expense-sheets-implementation-plan.md` §3](expense-sheets-implementation-plan.md):

- **Q1 (Where does "My Sheets" live?):** Resolved — there is no separate "My Sheets" tab; the employee dashboard **is** the sheet workspace, driven by a picker. The old `user_dashboard_screen.dart` is fully replaced.
- **Q2 (Fate of `cycle_expenses_report_screen.dart`?):** Partially resolved — its responsibilities for the employee's own view move into the new dashboard. Its cross-employee / export-report role is out of scope for this story (Manager-side decision).
- **Q3 (Current-cycle widget on employee dashboard?):** Resolved — the picker itself + the "+ New expense" button gating IS the current-cycle surfacing. No separate widget.
- **Q4 (Decline modal placement):** N/A for this story (manager-side).
- **Q5 (Per-expense approve/decline visibility):** N/A for this story (manager-side).
- **Q6 (Polling cadence on Approvals queue):** N/A for this story (manager-side).
- **Q7 (Cycle-close visibility):** Resolved indirectly — picker shows cycle labels and a Draft is the current cycle. No countdown messaging in MVP.

---

## 5. Architecture

### 5.1 Models (additions/changes)
- `ExpenseSheetStatus` enum (`draft=1, waitingForApproval=2, approved=3, declined=4`). Add `fromId` constructor.
- `SheetMode` enum (UI-only): `draft | submitted | declined`. Mapped 1:1 from `statusId` (1→draft, 2→submitted, 4→declined). `statusId=3 Approved` is finalised and never reaches this screen.
- `ExpenseSheetListItem` — list-row DTO from `/me` (and `/queue`, `/{userId}/list` for future stories). Carries: id, createdByUserId, createdByName, cycleId, cycleLabel, statusId, statusAlias, submittedAt?, reviewedAt?, reviewedByName?, expenseCount, totalAmount, currencyCode.
- `ExpenseSheetDetail` — full detail from `/{id}`. Adds cycleStartAt, cycleEndAt, latestDeclineComment, expenses[], log[].
- Extend `ExpenseSummary` and `ExpenseDetail` with: `expenseSheetId?`, `expenseSheetStatusId?`, `expenseSheetStatusAlias?`.
- **No `reopened` flag anywhere.** Don't add one as a derived getter either — code reads `statusId == 4` directly to mean "declined".

### 5.2 Providers (Riverpod)
- `expenseServiceProvider` — exists.
- `mySheetsProvider` → `FutureProvider<List<ExpenseSheetListItem>>` — fetches `/api/expense-sheets/me`, filtered client-side to non-finalised (`statusId` ∈ {1, 2, 4}). Re-fetched on resume + after any mutation that may change a sheet status.
- `sheetDetailProvider.family<String sheetId>` → `FutureProvider<ExpenseSheetDetail>` — loads on picker selection change. **Invalidated by the screen after every successful PUT/DELETE on a Declined sheet** (this is what surfaces the auto-promotion to the user).
- `selectedSheetIdProvider` → `StateProvider<String?>` — picker selection. Default = the current-cycle Draft's id (computed once `mySheetsProvider` resolves). Falls back to picker default if the selected id 404s (sheet hard-deleted).
- `selectedFilterTabProvider` → `StateProvider<FilterTab>` — Rejected/Pending/Approved. Default = Rejected, auto-corrected if empty.
- `dismissedReturnedAlertKeyProvider` → `StateNotifierProvider<String?>` reading/writing `SharedPreferences` key `returned_alert_dismissed_key`.
- `expenseLayoutModeProvider` → `StateNotifierProvider<LayoutMode>` reading/writing `SharedPreferences` key `expense_layout_mode`.

### 5.3 Service additions (`lib/services/expense_service.dart`)
- `getMySheets()` → `GET /api/expense-sheets/me`
- `getSheetDetail(sheetId)` → `GET /api/expense-sheets/{id}`
- **No `resubmitSheet` method** — per §3.2 there is no such endpoint and no client-side equivalent. The badge flip happens via `sheetDetailProvider` invalidation after PUT/DELETE.
- New typed exceptions: `ExpenseSheetNotFoundException`, `ExpenseDateTooOldException`, `EditApprovedExpenseOnDeclinedSheetException` (mapped from `409 ExpenseEditApprovedExpenseOnDeclinedSheet`).
- Extend `searchExpenses` to accept optional `expenseSheetId` filter (used by the list zone, scoped to selected sheet).

### 5.4 Screen decomposition (CLAUDE.md mandates < 200 lines for the orchestrator)

`lib/screens/user_dashboard_screen.dart` (orchestrator, ~150 lines) composes:

```
lib/widgets/employee_dashboard/
  page_header_row.dart                 # title + view-mode toggle + New expense
  view_mode_toggle.dart                # the ghost icon-swap button (mobile only)
  sheets_picker_section.dart           # composes A+B+C
    returned_sheets_global_alert.dart  # zone A
    sheet_picker_dropdown.dart         # zone B (uses MenuAnchor on desktop, bottom sheet on mobile)
    sheet_picker_tile.dart             # the two-row tile (shared by trigger + items)
    declined_sheet_banner.dart         # zone C — replaces the old action strip + dialog
  sheet_status_badge.dart              # 4-state badge widget (Draft / Awaiting / Approved / Returned) — built complete so it's reusable by the manager dashboard. Employee call sites only ever pass the first, second, or fourth.
  status_filter_tabs.dart              # the 3-bucket tab row (mobile pills + desktop tabs)
  expenses_list_section.dart           # responsive switch: desktop table / mobile cards / mobile list
    desktop_sheet_expense_table.dart
    mobile_sheet_expense_carousel.dart
    mobile_sheet_expense_list.dart
    sheet_expense_empty_state.dart
  delete_expense_confirmation_dialog.dart  # reusable; may already exist
```

### 5.5 Routes
- Keep `/employee/dashboard` (or the existing route — verify in `router.dart`). The screen file is rewritten in place.
- New screen is wrapped in `AuthGate` like every other route.

---

## 6. Tasks (sequenced)

Each slice is independently mergeable. Stop after every slice and verify before continuing.

### Slice 1 — Foundation (no UI change)
- [ ] Add `ExpenseSheetStatus` enum + `SheetMode` enum + `LayoutMode` enum + `FilterTab` enum.
- [ ] Add `ExpenseSheetListItem` model.
- [ ] Add `ExpenseSheetDetail` model (+ `ExpenseSheetLogEntry` for future stories; OK to defer if unused here).
- [ ] Extend `ExpenseSummary` + `ExpenseDetail` with the 3 sheet fields.
- [ ] Add service methods: `getMySheets`, `getSheetDetail`, optional `expenseSheetId` filter on search.
- [ ] Add typed exceptions for new error codes.
- [ ] Add providers: `mySheetsProvider`, `sheetDetailProvider.family`, `selectedSheetIdProvider`, `selectedFilterTabProvider`, `dismissedReturnedAlertKeyProvider`, `expenseLayoutModeProvider`.
- [ ] **All i18n keys (§7) added to `app_en.arb` + `app_he.arb` BEFORE any widget code.** `flutter pub get` runs cleanly.
- [ ] `flutter build web` clean. App still works (old dashboard still rendering).

### Slice 2 — Page header
- [ ] `page_header_row.dart` (title + container row).
- [ ] `view_mode_toggle.dart` (mobile only; writes `expense_layout_mode`).
- [ ] New-expense button gating: enabled only on current-cycle Draft selection.
- [ ] Wire into the dashboard scaffold; old body still below.

### Slice 3 — Picker + global alert (no list yet)
- [ ] `sheet_status_badge.dart`.
- [ ] `sheet_picker_tile.dart` (two-row).
- [ ] `sheet_picker_dropdown.dart` (MenuAnchor desktop, modal bottom sheet mobile; ≤320px panel; RTL; per CLAUDE.md `DropdownMenu` rules use template if applicable).
- [ ] `returned_sheets_global_alert.dart` with dismissal key persistence.
- [ ] Bind selection state + default to current-cycle Draft.
- [ ] Hide everything else below for now.

### Slice 4 — Declined-sheet banner
- [ ] `declined_sheet_banner.dart` — composes manager-name intro + raw decline comment + auto-resubmit explainer copy + optional progress hint.
- [ ] Responsive: stacks under picker on mobile; inline beside or under picker on desktop (whichever reads better given the comment length).
- [ ] Renders only when selected sheet has `statusId == 4`. Otherwise hidden.
- [ ] Verify the state matrix from §2.3 by clicking through Draft / Submitted / Declined.
- [ ] No buttons. No dialog. No Resubmit anywhere in the tree (`grep -RIn -i 'resubmit' lib/widgets/employee_dashboard` returns nothing).

### Slice 5 — Status filter tabs
- [ ] `status_filter_tabs.dart` (mobile pills + desktop tabs).
- [ ] Default-tab logic (Rejected → first non-empty).
- [ ] Editability flags derived per bucket.
- [ ] Only rendered in Declined mode.

### Slice 6 — Expenses list (desktop table)
- [ ] `desktop_sheet_expense_table.dart` with the spec'd columns/widths.
- [ ] Edit/view + delete affordances gated by editability.
- [ ] AI badge.
- [ ] Empty state inside the card.

### Slice 7 — Expenses list (mobile carousel + list)
- [ ] `mobile_sheet_expense_carousel.dart` with horizontal swipe between cards + bidirectional `Dismissible` for delete (when allowed).
- [ ] `mobile_sheet_expense_list.dart` compact row variant.
- [ ] `sheet_expense_empty_state.dart`.
- [ ] Honour the view-mode toggle.

### Slice 8 — Delete confirmation + service wiring + auto-promotion refresh
- [ ] `delete_expense_confirmation_dialog.dart` (or reuse if existing dialog matches the spec — verify visual match).
- [ ] Hook delete to existing `expenseService.deleteExpense`.
- [ ] **After every successful PUT/DELETE on a Declined sheet:** invalidate `sheetDetailProvider(id)` AND `mySheetsProvider`. This is the auto-promotion feedback loop — the user must see the picker badge flip without manual refresh.
- [ ] Handle the three auto-eval outcomes:
  - Sheet → `WaitingForApproval`: badge turns amber, banner disappears, filter tabs disappear. Picker selection stays.
  - Sheet → `Approved`: sheet leaves the dashboard (it's finalised). Selection falls back to picker default.
  - Sheet hard-deleted (last expense gone): next read 404s. Selection falls back to picker default with a soft toast.

### Slice 9 — RTL, locale, formatting sweep
- [ ] Cycle labels via `DateFormat.yMMMM(locale)`. Locale comes from `companyLocaleProvider` (CLAUDE.md).
- [ ] Dates via `format_utils.dart` extensions (`toCompanyDate`).
- [ ] Amounts via `toCurrency` extensions (suffix per project convention; verify).
- [ ] Logical insets (`EdgeInsetsDirectional`), no hard-coded `Icons.arrow_back_ios`, no `TextAlign.left/.right`.
- [ ] Visual RTL pass with locale switched to Hebrew.

### Slice 10 — Smoke + cleanup
- [ ] All edge cases from §2.7 manually walked through.
- [ ] Old `user_dashboard_screen.dart` body fully replaced. No orphan widgets left in `lib/widgets/`.
- [ ] No `setState` for shared state — Riverpod everywhere per CLAUDE.md.
- [ ] No `Color.withOpacity` (use `withAlpha`).
- [ ] No raw `http.*` outside `ApiService`.
- [ ] No hardcoded user-visible strings (`grep -RIn '"' lib/screens lib/widgets/employee_dashboard` audit).
- [ ] Final pass against the spec §2 line by line.

---

## 7. i18n keys

All keys below need EN + HE strings. **Add to `app_en.arb` + `app_he.arb` before any widget code.**

**Header**
- `myExpenses`, `newExpense`, `view`

**Picker meta**
- `sentForApprovalOn` (with `{date}` — but per CLAUDE.md *no ARB placeholders*, so concat in widget; key holds the literal text without the date)
- `itemsCount` (same; key holds the literal label, count concatenated in widget)

**Status badges** (4 keys total — widget is built complete for reuse by the manager dashboard; the employee dashboard only renders 3 of them)
- `sheetStatusDraft`, `sheetStatusAwaiting`, `sheetStatusApproved`, `sheetStatusReturned`

**Declined banner**
- `declinedByManagerPrefix` — used as `'${managerName} ${l10n.declinedByManagerPrefix}'` (e.g. "Bob declined this sheet:"). Concatenate the name in the widget; ARB holds only the trailing literal.
- `declinedByManagerFallback` — full sentence used when `reviewedByName` is null (e.g. "Your manager declined this sheet:").
- `declinedSheetExplainer` — the auto-resubmit copy (e.g. "Fix or remove the highlighted items below. Your sheet will return to your manager automatically when every rejected item is addressed.").
- `declinedSheetProgressHint` — used as `'${remaining}/${total} ${l10n.declinedSheetProgressHint}'` (e.g. "items still need attention").

**Global alert**
- `returnedSheetsAlert` (template — keep `{n}` literal in widget concat), `returnedSheetsAlertSingle`, `returnedSheetsAlertShort`, `reviewSheet`, `dismiss`

**Tabs**
- `filterRejected`, `filterPending`, `filterApproved`

**Table headers**
- `tableRowNumberHeader` (renders as `#` literal — key exists for screen-reader/accessible labelling), `date`, `amount`, `category`, `merchant`

**Pluralization** (CLAUDE.md bans ARB placeholders, so plural forms are two keys, switched in widget code):
- `itemsCountSingular` ("item") and `itemsCountPlural` ("items"). Concatenation: `count == 1 ? '$count ${l10n.itemsCountSingular}' : '$count ${l10n.itemsCountPlural}'`.

**Row actions**
- `edit`, `view`, `delete`

**Empty states**
- `employeeEmptyStateTitle`, `employeeEmptyStateDesc`, `noExpensesPendingDesc`

**Delete dialog**
- `deleteExpenseTitle`, `deleteExpenseConfirm`, `cancel`

> Per CLAUDE.md "ARB strings — no placeholders" rule: any `{n}` / `{date}` / `{count}` token mentioned in the UX spec is built by **concatenation in the widget**, not via ARB placeholder syntax.

---

## 8. Risks & gotchas

- **`user_dashboard_screen.dart` (383 lines) is being fully gutted.** Audit what else routes to or depends on its widgets before deleting — anything in `lib/widgets/expenses/` reused elsewhere stays; everything used only by this screen can be retired.
- **Mobile carousel UX is new** (current app has cards but not horizontal swipe between them). Plan a small spike on swipe-between-cards vs. swipe-to-delete gesture conflict before Slice 7.
- **`DropdownMenu` web crash** with `expandedInsets: EdgeInsets.zero` + fixed `width` (CLAUDE.md). Follow the documented template; consider `MenuAnchor` instead since the trigger is a custom two-row tile, not a Material text field.
- **Currency suffix format** — confirm `format_utils.dart` already supports suffix; if not, extend it (don't fork formatting per screen).
- **Cycle label parsing** — `"2026/05"` is unambiguous but trust it cautiously; format defensively.
- **Auto-promotion timing.** A Declined sheet may flip to `WaitingForApproval` (or `Approved`, or vanish) immediately after the user's last edit/delete. The picker must not flash an empty state or stale selection during the transition — invalidate `sheetDetailProvider(id)` + `mySheetsProvider` together, and only after both resolve should we decide whether to keep the selection or fall back to the picker default.
- **Empty `latestDeclineComment`.** Rare but possible (a sheet that reached Declined via a path that didn't store a comment). Banner must still render the explainer copy; comment row is the only thing that hides.
- **Don't reintroduce the dropped concepts.** No `reopened` field, no Resubmit method, no manager-note dialog. If any of these creep back during PRs, push back — they will desync from the server's auto-promotion behavior.

---

## 9. Done definition

- Spec §2 implemented end-to-end on web (desktop + mobile breakpoints) and verified for both EN and HE.
- All §2.7 edge cases manually walked through, including the three auto-eval outcomes (sheet → WaitingForApproval, sheet → Approved, sheet hard-deleted).
- All §6 slices' verification items pass.
- §3.3, §3.4 still-open decisions resolved or explicitly deferred to a follow-up story.
- Old `user_dashboard_screen.dart` body fully replaced; CLAUDE.md scaffolding rules satisfied (orchestrator <200 lines, no `_build*` private helpers).
- `grep -RIn -i 'reopen\|resubmit' lib/screens lib/widgets/employee_dashboard lib/models lib/services lib/providers` returns nothing.
