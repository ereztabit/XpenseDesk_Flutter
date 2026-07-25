# Story 02 — Manager Dashboard

**Status:** Ready to spec; **blocked on server delivery** of `GET /api/expense-sheets` (the new paged list endpoint locked in this story's §3). Once that lands, the build can start.

**Replaces:** the current manager main view at [`lib/screens/manager_dashboard_screen.dart`](../../../lib/screens/manager_dashboard_screen.dart) (362 lines — entire body to be rebuilt; route preserved).

**Out of scope:** Sheet Review screen (whole-sheet + per-line approve/decline lives there, story 03), Spend Overview widget internals (separate story — we ship a soft-degraded placeholder), paginated "View all" screens (separate story — we surface an overflow notice but no nav), billing alerts.

---

## 1. TL;DR

The manager dashboard is the **team-wide expense state** at a glance. Same route as today, completely rebuilt body. Instead of a flat list with a "processed" component, the manager now sees three sheet buckets reflecting **whose court the ball is in**:

1. **Pending review** — sheets sitting with the manager (`WaitingForApproval`). Hero card.
2. **Returned to employee** — sheets the manager declined that are waiting on the employee (`Declined`). Visibility for follow-ups.
3. **Approved** — terminal sheets (`Approved`). Audit / history.

The dashboard is **read-only**: row tap → Sheet Review (story 03) is the only action. No create, no edit, no inline approve/decline. The Sheet Status Badge widget built in story 01 gets its 4th color (Approved success) here.

Layout top-to-bottom:

1. **Spend Overview** (placeholder slot — see [spend-overview-spec.md](../../backlog/spend-overview-spec.md)).
2. **Page header** — title + employee filter dropdown.
3. **Pending review card** (hero, default expanded) — uses `/api/expense-sheets/queue`.
4. **Returned to employee card** (default expanded if non-empty, collapsed if empty) — uses `/api/expense-sheets?statusId=4`.
5. **Approved card** (default collapsed) — uses `/api/expense-sheets?statusId=3`.

Every behavior rule is in §2. Server contract is locked — §3 records what we agreed and points to the discovery-doc FAQ.

---

## 2. UX spec

### 2.1 Core concepts

- The dashboard surfaces **three buckets**, one per "whose court". The bucket label tells the manager what's happening; the row's status badge tells them the underlying status. Both agree.
- The manager never authors expenses on this screen. There is no picker, no per-line UI, no inline mutation.
- Each row is a **sheet entry point**. Tap → Sheet Review (story 03).
- **Auto-promotion is a visible feature here.** When an employee fixes a Returned sheet, it auto-promotes to `WaitingForApproval` server-side. The next refresh of the manager dashboard moves that sheet from "Returned to employee" → "Pending review" with a fresh timestamp. The manager sees the workflow without any client-side state machine.
- The employee filter narrows all three buckets atomically.

### 2.2 Spend Overview (soft-degrade placeholder)

- Renders at the very top, full-width.
- The real widget is specced in [spend-overview-spec.md](../../backlog/spend-overview-spec.md) — not yet built.
- Until then, this slot renders a **one-line placeholder** derived from the three providers: `'{queueCount} sheets pending · {grandTotalAmount} {currencySuffix}'`. Muted, no chrome, takes up minimal vertical space.
- When the real widget ships, we swap the placeholder for it — no other layout changes.

### 2.3 Page header

- Leading: page title `managerDashboardTitle` ("Approvals" — see §6 i18n for the rationale on the title choice). Large semibold, locale-aware.
- Trailing: **employee filter dropdown**.
  - ~160px wide on desktop, ~32px tall, 12sp font.
  - Leading filter icon (14×14, muted).
  - Default option `allEmployees` ("All employees"), sentinel value `null`.
  - One option per **active employee** in the company (RoleId=2, Status=Active), alphabetically sorted.
  - **Do not pre-filter to "employees with at least one sheet."** A new hire shows up in the dropdown immediately; an empty filtered result is meaningful UX.
  - Selection applies to all three cards atomically. Local UI state, not persisted across sessions.
  - Source: `GET /api/users/all` (manager-only — already exists per `lib/screens/users_screen.dart`).
  - **Mobile:** same dropdown, same dimensions — does NOT switch to a modal sheet (per the spec).

### 2.4 Sheet bucket cards — shared contract

Each of the three cards is an instantiation of a shared `SheetBucketCard` widget configured with:

- title key
- data provider
- header trailing widget (amount in amber, amount muted, or hidden)
- timestamp column label key + source field (`submittedAt` vs `reviewedAt`)
- row action affordance (Review button vs eye icon)
- empty-state copy key
- default-expanded boolean (with override: if empty, can collapse silently)
- overflow notice copy key (when `totalCount > pageSize`)

Shared structure:
- Collapsible card. Header row: title · count in parens (e.g. "(4)") · trailing widget · chevron-down (rotates 180° on open, 200ms ease).
- Body when empty: centered empty state with bucket-specific copy. No CTA.
- Body when populated: responsive switch — desktop table, mobile list.
- Footer when `totalCount > 12`: **paging-overflow notice** — "Showing 12 of {N} most recent. Pagination coming soon." Muted, single line. No link yet — the paginated screen ships separately. (This is the temporary form of the spec's "View all" affordance — we trade the link for an honest notice until the paginated screen exists.)

**Desktop table columns** (per card — the timestamp + action columns vary, the rest are shared):

| Column     | Width | Source                                          |
|------------|-------|--------------------------------------------------|
| Employee   | 22%   | `createdByName`                                  |
| Cycle      | 18%   | `cycleLabel` formatted as locale long-month       |
| Items      | 12%   | `expenseCount`                                   |
| Total      | 15%   | `totalAmount` with currency suffix                |
| Timestamp  | 18%   | varies per bucket (see §2.5/§2.6/§2.7)           |
| Action     | 15%   | varies per bucket                                 |

Whole row is the tap target → Sheet Review. The Action cell's affordance is a visual cue, not a separate hit area.

**Mobile list** (per card):
- Single-column, divider-separated rows.
- Leading: employee name bold; meta line `'{cycleLabel} · {expenseCount} ${l10n.items}'`; status timestamp below when applicable.
- Trailing: `totalAmount` stacked above a small outlined action button.
- Whole row tappable.

### 2.5 Pending review card (hero)

- **Data source:** `GET /api/expense-sheets/queue` (existing endpoint, capped server-side at 12, ordered `SubmittedAt DESC`).
- **Default state:** expanded.
- **Header trailing widget:** `'{grandTotalAmount} {currencySuffix} ${l10n.awaitingSuffix}'` in **amber/warning tone**. Hidden when zero or null. Comes from the queue envelope's new `grandTotalAmount` field (server change locked this round).
- **Timestamp column:** `'submitted' / submittedAt` formatted with `toCompanyDate`.
- **Action cell:** outlined "Review" button (small).
- **Empty state:** clock icon in tinted circle, title `noPendingSheets`, muted description.
- **Overflow notice:** triggers when the queue returns 12 rows. The 13th-onwards is invisible until the paginated screen ships.

### 2.6 Returned to employee card

- **Data source:** `GET /api/expense-sheets?statusId=4&pageSize=12&page=1` (new endpoint).
- **Default state:** expanded if non-empty, collapsed if empty. (Avoids visual clutter when there's nothing to follow up on.)
- **Header trailing widget:** `'{grandTotalAmount} {currencySuffix}'` in **muted destructive tone** (no "awaiting" suffix — these aren't waiting on the manager).
- **Timestamp column:** `'returnedAt' / reviewedAt` (the moment the manager declined the sheet). Formatted with `toCompanyDate`.
- **Action cell:** outlined "View" button or small eye icon (decision in slice 4 — pick whichever reads better against the destructive-tinted row).
- **Empty state:** check-circle icon in tinted circle, title `noReturnedSheets`, muted description.
- **Auto-promotion note:** when a sheet leaves this bucket (employee fixed it → server moved it to WfA), the manager will see it disappear here AND show up in Pending review on next refresh. Don't surface a special UI cue for the transition — the bucket move IS the cue.

### 2.7 Approved card

- **Data source:** `GET /api/expense-sheets?statusId=3&pageSize=12&page=1` (new endpoint).
- **Default state:** collapsed.
- **Header trailing widget:** **hidden** (no actionable info — sum of historical approvals isn't useful here; the future Spend Overview is the right place for that).
- **Timestamp column:** `'approvedAt' / reviewedAt` formatted with `toCompanyDate`.
- **Action cell:** ghost icon button (eye icon) → Sheet Review (read-only mode in story 03).
- **Empty state:** muted text-only "No approved sheets yet." (No CTA, no large icon — this is audit, not action.)
- **Overflow notice:** same pattern as the other cards.

### 2.8 Cross-zone rules

- Employee filter applies to all three providers atomically. Implementation: filter state lives in a single `selectedEmployeeFilterProvider`; each card's provider watches it as a family parameter.
- Pull-to-refresh refreshes all three providers + the employees list. Triggered on the scroll container, not per-card.
- **On return from Sheet Review** (story 03 will navigate via `Navigator.push`), invalidate all three sheet providers — the sheet just acted on may have moved buckets. Do not auto-scroll the manager back to its new card; leave the scroll position alone.
- No mutations on this screen. No toasts.
- No swipe gestures.

### 2.9 Edge cases

- **Zero sheets across all three buckets:** page renders normally; each card shows its empty state. Spend Overview placeholder shows "0 sheets pending".
- **Employee filter narrows to one user with sheets only in one bucket:** the other two cards show their empty states without breaking layout.
- **Sheet with no `submittedAt`** (defensive — shouldn't happen organically): render em-dash in the Submitted cell. Server sort puts these at the bottom.
- **Sheet with no `reviewedAt`** in Returned / Approved (also defensive): em-dash; bottom of sort.
- **Filter dropdown contains only the manager** (single-user company): show "All employees" only. All three cards empty. Filter dropdown still renders so the manager isn't surprised.
- **An employee with sheets goes inactive while the page is open:** their existing sheets stay in the data; they no longer appear in the dropdown options. "All employees" view still shows them. (Filter behavior on stale `selectedEmployeeFilter` value — keep the selection until the user explicitly changes it; their sheets continue to render.)
- **Auto-promotion happens during a refresh:** a sheet might be in the Returned response AND the Pending response if the server transitioned between the two calls. Defensive dedupe: if a sheet appears in two cards (same `expenseSheetId`), trust the Pending bucket (most-actionable wins). This is a rare race; not worth a server-side coordination.
- **`grandTotalAmount` on `/queue`** (server adds this in the same change): if missing for any reason (older server version), the hero card hides the trailing amount widget silently — don't show "null awaiting".

---

## 3. Server Contract Reconciliation — resolved 2026-05-23

Three conflicts from the spec review, all resolved in coordination with the server team. Full Q&A lives in conversation history; the highlights:

### 3.1 Where do Declined sheets live? — **three buckets**

"Processed" was a 2-bucket model that hid an in-flight state behind a "final" label. Replaced with three buckets: **Pending review** (WfA, manager's court) · **Returned to employee** (Declined, employee's court) · **Approved** (terminal). The bouncing behavior — sheets moving from Returned → Pending when the employee fixes things — becomes a visible feature instead of a bug.

### 3.2 No "processed sheets" endpoint — **server adds `GET /api/expense-sheets`**

New paged endpoint:

```
GET /api/expense-sheets?statusId={2|3|4}&cycleId={guid?}&userId={guid?}&page={int=1}&pageSize={int=25}
```

- **Role guard:** Manager only.
- `statusId` is required; values outside `{2,3,4}` return `400` with `errorCode: "InvalidExpenseSheetStatusForListing"` (new code). `statusId=1` (Draft) explicitly rejected — drafts are private.
- Default ordering: `SubmittedAt DESC` for `statusId=2`, `ReviewedAt DESC` for `statusId=3` and `statusId=4`.
- Cross-company `userId` filter silently returns empty (`200`, `totalCount=0`) — no existence leak.
- Returns the same `ExpenseSheetListItemResponse` row shape as `/queue`, `/me`, `/{userId}/list`. DTO parity is a forward commitment; new fields land on all four endpoints together. As a bonus the server is also aligning `proc_GetExpenseSheetQueue` to populate `CreatedAt` (currently null on `/queue` only).
- **Paging envelope:**

```jsonc
{
  "items":            [ /* ExpenseSheetListItemResponse */ ],
  "page":             1,
  "pageSize":         25,
  "totalCount":       87,
  "hasMore":          true,
  "pageTotalAmount":  1820.50,
  "grandTotalAmount": 18420.75
}
```

- `pageSize` clamped to 1–100 server-side. `page` minimum 1, no max.
- `hasMore` is strictly `(page * pageSize) < totalCount`. Asking for a page beyond `totalCount` returns `items: []`, accurate `totalCount`, `hasMore: false`.
- **`grandTotalAmount` also added to the `/queue` envelope** (same change) so the hero card header has the bucket total without paging math.

### 3.3 Queue cap at 12 — **kept; client surfaces an overflow notice**

The `/queue` cap is intentional ("top of mind" view). We don't paginate `/queue`; the new endpoint does that job better. The cards render an honest "Showing 12 of {N} most recent. Pagination coming soon." notice when `totalCount > 12`. No clickable "View all" until the paginated screen ships (separate follow-up).

### 3.4 Badge widget — **4 states only**

Story 01 was patched to bump the Sheet Status Badge from 3-state to 4-state (Draft / WaitingForApproval / Approved / Declined). No `partially_rejected` — it was shorthand from the old mental model where Declined was terminal. If we ever need "WfA sheet with some declined line-items" as a visible signal, it goes on Sheet Review as a secondary chip on the row, not as a fifth badge color.

---

## 4. Decisions resolved (vs. the earlier implementation plan)

The earlier high-level plan ([`expense-sheets-implementation-plan.md`](expense-sheets-implementation-plan.md)) had several open questions on the manager side. Resolution:

- **Q4 (Decline modal placement):** Out of scope for this story; lives on Sheet Review (story 03).
- **Q5 (Per-expense approve/decline visibility on manager sheet-detail):** Out of scope; Sheet Review.
- **Q6 (Polling cadence on Approvals queue):** No polling — pull-to-refresh + refresh-on-return-from-Sheet-Review. Notifications are explicit out-of-scope per the discovery doc §8.

---

## 5. Architecture

### 5.1 Models (reuse + additions)
- `ExpenseSheetStatus` enum, `ExpenseSheetListItem` — already added by story 01.
- **New** `PagedExpenseSheets` envelope DTO: items, page, pageSize, totalCount, hasMore, pageTotalAmount, grandTotalAmount.
- **New** `CompanyUser` (or reuse whatever `users_screen.dart` already uses) — minimum: `userId`, `displayName`, `roleId`, `status`. Sorted alphabetically client-side.
- The existing `/queue` envelope grows `grandTotalAmount` (server change). Wrap `/queue` response in a lightweight `ApprovalsQueueResponse(items, grandTotalAmount)` so the hero card has both.

### 5.2 Providers (Riverpod)
- `selectedEmployeeFilterProvider` → `StateProvider<String?>` — null means "all employees".
- `companyEmployeesProvider` → `FutureProvider<List<CompanyUser>>` — loaded once; rarely changes during a session. Used to populate the dropdown.
- `approvalsQueueProvider.family<String? employeeId>` → `FutureProvider<ApprovalsQueueResponse>` — calls `/api/expense-sheets/queue`. Server already filters by company; client passes `userId` only if `employeeId != null` (will need a server-side check — see Risks §8).
- `returnedSheetsProvider.family<String? employeeId>` → `FutureProvider<PagedExpenseSheets>` — `?statusId=4&pageSize=12&page=1[&userId=...]`.
- `approvedSheetsProvider.family<String? employeeId>` → `FutureProvider<PagedExpenseSheets>` — `?statusId=3&pageSize=12&page=1[&userId=...]`.
- All four card providers watch `selectedEmployeeFilterProvider` indirectly through their family param — invalidation cascades when filter changes.

> **Open detail:** the existing `/queue` doesn't accept a `userId` filter (it's defined as "WfA across the company"). When the employee filter narrows to one person, we have two options: (a) ask backend to add `userId` to `/queue` for symmetry with the new endpoint, or (b) use the new endpoint with `?statusId=2&userId=...&pageSize=12` for the Pending card whenever a filter is active. **Recommend (b)** — zero server change, keeps the hero card path simple in the unfiltered case. Confirm during slice 3.

### 5.3 Service additions (`lib/services/expense_service.dart`)
- `getApprovalsQueue()` → `GET /api/expense-sheets/queue` (already added by story 01 — verify it returns the new `grandTotalAmount`).
- `getSheets({required int statusId, String? userId, String? cycleId, int page = 1, int pageSize = 12})` → new endpoint.
- `getCompanyUsers()` — likely already exists for `users_screen.dart`. If so, reuse; if not, add.
- New typed exception: `InvalidExpenseSheetStatusForListingException` (mapped from the new error code). Defensive — shouldn't fire under normal use.

### 5.4 Screen decomposition

`lib/screens/manager_dashboard_screen.dart` (orchestrator, ~150 lines) composes:

```
lib/widgets/manager_dashboard/
  page_header_row.dart                 # title + employee filter
  employee_filter_dropdown.dart        # the trailing dropdown
  spend_overview_placeholder.dart      # the soft-degraded slot
  sheet_bucket_card.dart               # the shared collapsible card (header + body + footer)
  pending_review_card.dart             # configures sheet_bucket_card for /queue
  returned_to_employee_card.dart       # configures it for statusId=4
  approved_card.dart                   # configures it for statusId=3
  desktop_sheet_bucket_table.dart      # the table body
  mobile_sheet_bucket_list.dart        # the mobile list body
  sheet_bucket_empty_state.dart        # the 3 empty-state variants
  paging_overflow_notice.dart          # "Showing 12 of N most recent. Pagination coming soon."
```

Reuse from story 01: `sheet_status_badge.dart` (now 4-state).

### 5.5 Routes
- Keep `/manager/dashboard` (or whatever the existing route is — verify in `router.dart`). Rebuilt in place. Wrapped in `AuthGate` + manager-role guard (already exists).

---

## 6. Tasks (sequenced)

Each slice independently mergeable. Stop and verify after each.

### Slice 1 — Foundation (no UI change)
- [ ] Add `PagedExpenseSheets` envelope model.
- [ ] Add `ApprovalsQueueResponse` wrapper (`items` + `grandTotalAmount`).
- [ ] Add `getSheets(...)` service method on `ExpenseService`.
- [ ] Update `getApprovalsQueue()` return type if it currently throws away `grandTotalAmount`.
- [ ] Add `getCompanyUsers()` if not already present; verify the existing users-screen call path.
- [ ] Add `InvalidExpenseSheetStatusForListingException`.
- [ ] Add providers: `selectedEmployeeFilterProvider`, `companyEmployeesProvider`, `approvalsQueueProvider.family`, `returnedSheetsProvider.family`, `approvedSheetsProvider.family`.
- [ ] All i18n keys (§7) added to `app_en.arb` + `app_he.arb`. `flutter pub get` clean.
- [ ] `flutter build web` clean. App still works (old dashboard still rendering).

### Slice 2 — Page shell + header + Spend Overview placeholder
- [ ] Rebuild `manager_dashboard_screen.dart` scaffold per CLAUDE.md (`AppHeader → Expanded → SingleChildScrollView → ConstrainedContent → Column`).
- [ ] `page_header_row.dart` + `employee_filter_dropdown.dart`.
- [ ] `spend_overview_placeholder.dart` — one-line summary from `/queue`'s `grandTotalAmount` + count.
- [ ] Old body still below for now.

### Slice 3 — Pending review hero card
- [ ] `sheet_bucket_card.dart` (the shared widget).
- [ ] `desktop_sheet_bucket_table.dart`, `mobile_sheet_bucket_list.dart`, `sheet_bucket_empty_state.dart`, `paging_overflow_notice.dart`.
- [ ] `pending_review_card.dart` instantiates the shared card with `/queue` config (amber-amount trailing widget, "submitted" timestamp).
- [ ] Confirm filter-by-userId path (recommendation §5.2 (b)): when filter is non-null, swap to the new endpoint with `?statusId=2&userId=...&pageSize=12`.
- [ ] 4-state badge renders correctly for `WaitingForApproval`.

### Slice 4 — Returned to employee card
- [ ] `returned_to_employee_card.dart` — instantiates with `?statusId=4` config (muted-destructive amount, "returnedAt" timestamp).
- [ ] Default-expanded-if-non-empty rule.
- [ ] Visual differentiation: rows in this card carry a subtle destructive tint so the bucket itself feels "stuck".
- [ ] 4-state badge renders `Declined` correctly.

### Slice 5 — Approved card
- [ ] `approved_card.dart` — instantiates with `?statusId=3` config (no amount widget, "approvedAt" timestamp, eye-icon action).
- [ ] Default collapsed.
- [ ] 4-state badge renders `Approved` correctly — this is the first call site for the success-tone variant. Visual review against AppTheme tokens.

### Slice 6 — Filter wiring + refresh contracts
- [ ] Employee filter applies to all three providers atomically.
- [ ] Pull-to-refresh on the scroll container invalidates all three sheet providers + `companyEmployeesProvider`.
- [ ] **Refresh-on-return-from-Sheet-Review** wired (placeholder route until story 03 ships — but the invalidation contract is in place so story 03 just navigates).
- [ ] Defensive dedupe across buckets (auto-promotion race): if a sheet id appears in both Pending and Returned responses, keep it only in Pending.

### Slice 7 — RTL, locale, formatting sweep
- [ ] Cycle labels via `DateFormat.yMMMM(companyLocale)`.
- [ ] Dates via `toCompanyDate(companyLocale)`.
- [ ] Amounts via `toCurrency(companyLocale, currencyCode)` — suffix format.
- [ ] Logical insets, no hard-coded LTR icons.
- [ ] Visual RTL pass with locale switched to Hebrew.

### Slice 8 — Smoke + cleanup
- [ ] All §2.9 edge cases walked through manually.
- [ ] Old `manager_dashboard_screen.dart` body fully replaced. No orphan widgets in `lib/widgets/`.
- [ ] No `setState` for shared state — Riverpod everywhere.
- [ ] No `Color.withOpacity` (use `withAlpha`).
- [ ] No raw `http.*` outside `ApiService`.
- [ ] No hardcoded user-visible strings — grep audit on `lib/screens/manager_dashboard_screen.dart` and `lib/widgets/manager_dashboard/`.
- [ ] `grep -RIn -i 'partially_rejected\|processed' lib/widgets/manager_dashboard` returns nothing (legacy concepts).
- [ ] Final pass against §2 line by line.

---

## 7. i18n keys

EN + HE for each. **Add to ARB before any widget code.**

**Header**
- `managerDashboardTitle` — "Approvals" (EN), "אישורים" (HE) or similar. "Pending sheets" from the original spec is misleading once we have three buckets; "Approvals" reads as "manager's approval workspace" and covers all three buckets cleanly. *Open: validate the Hebrew copy with the team.*

**Employee filter**
- `employee`, `allEmployees`

**Card titles**
- `pendingReviewCardTitle` ("Pending review")
- `returnedToEmployeeCardTitle` ("Returned to employee")
- `approvedCardTitle` ("Approved")

**Card header amount suffix**
- `awaitingSuffix` — used as `'${amount} ${currencySuffix} ${l10n.awaitingSuffix}'` ("awaiting"). Concat per CLAUDE.md ARB rule.

**Table columns / mobile labels**
- `employee`, `cycle`, `items`, `total`, `submitted`, `returnedAt`, `approvedAt`, `action`, `review`

**Row actions**
- `review` (Pending card button) — already in story 01? verify.
- `view` (Returned/Approved card icon button) — already in story 01.

**Empty states**
- `noPendingSheets` (was `noExpensesPending` in the original spec — renamed per the decisions doc Minor #5)
- `noReturnedSheets`
- `noApprovedSheets`

**Paging overflow**
- `pagingOverflowPrefix` — used as `'${l10n.pagingOverflowPrefix} ${shown} ${l10n.pagingOverflowOf} ${total} ${l10n.pagingOverflowSuffix}'` ("Showing 12 of N most recent. Pagination coming soon."). Build by concat per CLAUDE.md.
  - Alternative: a single key `pagingOverflowNotice` that's positional-free, with the numbers stitched in by widget. Decide during slice 3.

**Status badges** — reused from story 01 (4 keys: `sheetStatusDraft`, `sheetStatusAwaiting`, `sheetStatusApproved`, `sheetStatusReturned`).

**Locale / RTL / formatting** — same contract as story 01 §9.

---

## 8. Risks & gotchas

- **Blocker:** the new `/api/expense-sheets` endpoint must ship before slices 4–5 can be built. Slices 1–3 can begin in parallel with the server work — they only need `/queue` (existing, with `grandTotalAmount` extension).
- **`manager_dashboard_screen.dart` (362 lines) is being fully rebuilt.** Audit dependencies before deleting — `lib/widgets/dashboard/spend_overview_widget.dart` already exists (per the grep at story-01-planning time), confirm whether it's the placeholder or the partial real widget. If real, slot it in directly instead of writing a placeholder.
- **`/queue` filter-by-userId.** Existing endpoint doesn't accept `userId`. Recommendation §5.2 (b) is to switch to the new paged endpoint whenever the filter is active. Confirm during slice 3 — if the server team adds `userId` to `/queue` for symmetry, prefer that.
- **Auto-promotion race.** A sheet can transition from `Declined` → `WaitingForApproval` between the Returned and Pending API calls (rare but real). Defensive dedupe — covered in slice 6 — keeps the UI honest.
- **DTO parity drift over time.** The server team committed to evolving the four sheet-list endpoints together. If a future PR adds a field to `/me` but not `/queue`, the shared client DTO breaks silently. Worth a code-review note: any change to the row DTO touches all four endpoint mappings.
- **`pageSize` clamping.** Server silently clamps to 1–100. We pass 12 from cards and a future bigger number from the paginated screen. No defensive client check needed; just don't bother passing values >100.
- **Spend Overview slot vs. real widget timing.** If the real widget ships mid-story, we don't want to rebuild the layout. Spec the placeholder to occupy the same vertical slot the real widget will (Column child at index 1) so swapping is one-line.
- **Don't reintroduce dropped concepts.** No `partially_rejected`, no "Processed" bucket, no secondary chips on this screen (chips belong on Sheet Review). Same guard as story 01 §8.

---

## 9. Done definition

- §2 implemented end-to-end on web (desktop + mobile breakpoints) and verified for EN and HE.
- All §2.9 edge cases manually walked through, including auto-promotion bounce and stale-filter cases.
- All §6 slices' verification items pass.
- 4-state badge renders correctly across all three cards (this story's the first visual proof of the Approved variant).
- Old `manager_dashboard_screen.dart` body fully replaced; CLAUDE.md scaffolding rules satisfied (orchestrator <200 lines, no `_build*` private helpers).
- `grep -RIn -i 'partially_rejected\|processed.*sheet\|reopen\|resubmit' lib/screens/manager_dashboard_screen.dart lib/widgets/manager_dashboard` returns nothing.
- Sheet Review navigation contract in place (placeholder route OK) so story 03 can drop in without dashboard rework.
