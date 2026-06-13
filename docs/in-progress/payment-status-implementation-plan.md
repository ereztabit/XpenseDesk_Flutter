# Payment Status — Implementation Plan

Merged from:
- [payment-status-feature-spec.md](payment-status-feature-spec.md) — product/UX spec (Lovable)
- [payment-status-flutter-guide.md](payment-status-flutter-guide.md) — backend API contract (**authoritative on data & behavior**)
- 5 UI screenshots provided 2026-06-12 (**authoritative on layout**: dashboard card, report desktop, mark-as-processed modal, advanced filters, report mobile)

Execution model: autonomous, phase by phase. Each phase ends with `flutter build web` (must pass)
and a `/code-review` pass (blocker/should-fix findings fixed before moving on, logged in the phase notes).
No commits without explicit instruction. User verifies in browser at each ✅ gate.

---

## STATUS BOARD

> Legend: ⬜ not started · 🔨 in progress · 🧱 built (compiles) · 🔍 CR passed · ✅ user verified

| # | Phase | Deliverable | Status | Notes |
|---|-------|-------------|--------|-------|
| 1 | Data layer | Models, `PaymentService`, providers, `CompanyInfo.paymentsSummary` | 🔍 | Build ✓, analyze ✓. CR: greps clean; fixed double-iteration of lazy iterable in `withoutSheets` + 4 null-aware-element lints |
| 2 | Dashboard rework + card + route skeleton | Teammates strip (B–D states), `AwaitingPaymentCard` (both states), `/manager/payments` route + screen shell + nav-menu link (desktop & mobile) | 🔍 | Build ✓, analyze ✓, greps ✓. `teammates_counter.dart` → `teammates_strip.dart` (renamed per file-naming rule). CR fix: Flexible on strip labels (narrow-overflow). Note: "View Report" button is label-only (AppButton icons are leading; trailing chevron not supported) |
| 3 | Report filters (desktop) | Filter card: status, approval-date range, advanced (employee/cycle/processed range), Reset/Search | 🔍 | Build ✓, analyze ✓, greps ✓. New shared `DateRangeFilter` + `PaymentsDropdown` (CLAUDE.md DropdownMenu template). Export All rendered disabled until Phase 6 |
| 4 | Results table (desktop) | Sticky table, badges, paging notice, row tap → sheet review | 🔍 | Build ✓, analyze ✓, greps ✓. CR fix: extracted `PaymentsHeaderCell` to its own file (table file was 253 lines). Sortable: employee/cycle/approved/amount/status/processed. Selection params wired but inert until Phase 5 |
| 5 | Selection + Mark as Processed | Checkboxes, bulk bar, per-row action, confirm modal, in-place refresh, error handling | 🔍 | Build ✓, analyze ✓, greps ✓. CR extractions: `DialogDateField`/`DialogTextField`/`PaymentsDialogHeader` (reusable by Phase 9 edit dialog), `DesktopPaymentsView` (also pre-stages the Phase 7 mobile branch). Screen at 213 lines — state+handlers only, all layout extracted (target is <200; remaining lines are the selection/process/conflict handlers that belong on the screen) |
| 6 | Excel exports | Export All (filters) + Export Selected (ids) | 🔍 | Build ✓, analyze ✓. Export flow lives in `PaymentsExportNotifier` (provider layer); download via new public `ExcelExportService.downloadXlsxBytes`. Export All sends the APPLIED filter; filenames dated `payments-report-/payments-selected-yyyy-MM-dd.xlsx` |
| 7 | Mobile layout | Tune-icon filter dialog (D16), mobile table w/ sortable header + inline cycle line, animated bulk card | 🔍 | Build ✓, analyze ✓, greps ✓. Views refactored to ConsumerWidgets watching shared providers (less prop-drilling); screen branches `context.isMobile`. CR fix: extracted `MobilePaymentsHeaderCell`. Screen 245 lines — pure orchestration (state/handlers + two view delegations), all layout extracted |
| 8 | Sheet review payment strip | Payment status strip on manager sheet detail | 🔍 | Build ✓, analyze ✓, greps ✓. 4 payment fields on `ExpenseSheetDetail`; payable total = `SheetExpenseBuckets.approvedAmount` (new util, approved lines only); strip hidden when no payment dimension; processed sheets' detail providers invalidated after a process action |
| 9 | Edit / Revert processed — **scope gate** | Row action on Processed rows: edit details / revert to awaiting | ⏸️ | **Skipped — awaiting user scope decision** (gate respected during the autonomous run). API + reusable dialog widgets are ready; ~1 phase of work when approved |
| 10 | Final pass | RTL/l10n audit, full CR, docs → completed, current-work cleanup | 🔍 | RTL greps clean; EN/HE ARB parity 687=687; full `flutter analyze` zero findings in feature files (16 pre-existing elsewhere). **Adversarial CR pass (whole diff)** fixed 2 real issues: B2 — descending sort lifted null `—` dates to the top (nulls now sink in both directions); SF6 — date-range `→` separator didn't mirror in RTL (now en-dash). False alarm: line counts within cap (197/196). Open notes (no fix): SF1 dropdown null-cast is latent (all current dropdowns nullable), SF3 conflict-ids parser depends on backend payload shape — verify when server lands. Docs→completed deferred to sign-off |

---

## 1. Decisions & Conflict Resolutions

Where the Lovable spec, the API guide, and the screenshots disagree, the call below is final
(rule of thumb applied: **API contract wins on data/behavior, screenshots win on layout**).

| # | Topic | Lovable spec said | API / screenshot says | Decision |
|---|-------|-------------------|----------------------|----------|
| D1 | Free-text search (name/govId/email) | Text input, submit on Enter | No search param exists; Employee **dropdown** (`userId`) in advanced filters | **Employee dropdown, no text search** |
| D2 | Payment reference on process | Required | API: optional; modal screenshot: "Optional accounting batch ID" | **Optional** |
| D3 | Payment status filter | Segmented control, 2 options | Dropdown; `paymentStatus` omitted = All | **Dropdown: All / Awaiting Payment / Processed, default Awaiting Payment** |
| D4 | Employee sees payment strip on their sheet | Yes (§6, detailed) | API guide §9: "No payment data for employees anywhere — employee-facing screens are unchanged" | **Out of scope.** Employee screens untouched. Noted in §6 (future backlog) |
| D5 | Dashboard changes | "Slim teammates strip", restyled stat cards, new payment card | Mock + user rulings (rounds 3–4) | **Two dashboard changes** (Phase 2): ① `TeammatesCounter` card → slim chrome-less strip (people glyph + "N Teammates" + manager count kept **just like today** + gear + "Manage" text link). **The strip replaces the card only in states B–D — State A (no employees yet) keeps the existing invite-block flow untouched**; helping the manager invite the first employees still dominates. ② New `AwaitingPaymentCard` below `SpendOverviewCard`. **Counter cards (pending/approved/returned) are explicitly NOT changed** — user ruled the current implementation is better than the mock ("View →" affordance, minHeight, column layout all stay). Also unchanged: greeting, view switcher, `SpendOverviewCard`, mobile `SheetsSummaryMobileCard` |
| D19 | Awaiting Payment card — zero state | Success icon, "All clear", ghost View History button | Zero-state mock (4th round): neutral chrome, success check circle, **"Nothing to pay — you're done"**, success-tinted hint "All approved sheets have been processed.", **"View History" as a text link + chevron** (spend-card "View more" pattern), not a button | **Follow mock** |
| D6 | Modal contents | Summary line + collapsible affected-sheets preview | Screenshot (confirmed twice): title + X close, Processed Date / Reference ID / Note, Cancel + Confirm. No summary line, no sheet preview | **Pixel-faithful to screenshot.** No summary line (count + total live in the bulk bar behind the modal), no expandable sheet list. X / Esc / scrim = Cancel: close, selection preserved |
| D7 | Approval-status badge column in report | Yes (col 6) | Screenshot has no such column (every row here is approved by definition) | **Omit** |
| D8 | Bulk bar position (mobile) | Slides up from bottom | Screenshot: green-tinted card at top, under header, with Export + Mark as Processed + "N sheet(s) of X₪" | **Follow screenshot: top card** |
| D9 | Bulk bar (desktop) | Sticky bar with count, total, Mark as Processed, Clear-selection | Desktop screenshot (2nd round): green/success-tinted card under the filter card — "BULK ACTION" eyebrow + icon (leading), Export + Mark as Processed buttons (center), "N sheet(s) of X₪" (trailing). **No Clear-selection button** | **Follow screenshot.** Same green-card visual language as mobile; deselection happens via the checkboxes / header checkbox, no dedicated Clear button |
| D10 | "Processed by" on sheet detail strip | Shown | Detail response carries only `paymentStatus`, `processedDate`, `reference`, `note` — no processedBy | **Omit** (backend ask if wanted later) |
| D11 | Cycle label format | "Mar 2026" | API returns `cycleLabel` string (e.g. "2026/04") | **Render `cycleLabel` as-is** (consistent with existing sheet lists) |
| D12 | Per-row Mark as Processed | De-emphasized, bulk is the path | Screenshots show explicit per-row button (desktop) / icon (mobile) | **Include.** Opens the same modal with a single id |
| D13 | Animations (rows animate in/out, 200ms bar slide) | Specified | — | **Soft requirement.** `AnimatedSwitcher`/`AnimatedSize` where cheap; skip anything that fights `StickyReportTable` |
| D14 | Paging UI | Not addressed | Envelope is paged, `pageSize` clamped to 100 | **`pageSize=100`, no pager controls.** If `hasMore`, show overflow notice "Showing X of Y" (PagingOverflowNotice pattern). Revisit if real data outgrows it |
| D15 | Column sorting | Not mentioned in either doc | API has **no sort param**; user confirmed columns are sortable (desktop AND the mobile header row) | **Client-side sort** over the loaded page, exactly like `cycle_expenses_report_screen._applySorting()`: tap header toggles field + asc/desc, sort indicator on active column. Default order = as returned by server |
| D16 | Mobile filter surface | Bottom sheet with Apply | User: "filters popup just like in other reports" — existing reports open a **filter dialog** from the tune icon | **Reuse the existing report filter-dialog pattern** (tune icon with active-count badge → dialog with all filters + apply/search). No bottom sheet. Lovable's "active filter chips" row is dropped — the count badge on the tune icon covers it per screenshot |
| D17 | Page scroll model | — | User confirmed: app header + page title row + bulk card + caption + table header are **pinned**; scrolling happens **inside the table body only** | **No page-level `SingleChildScrollView`** on this screen (deviation from the standard scaffold, same as the cycle report). Desktop: `StickyReportTable` provides it. Mobile: fixed column (header rows + bulk card + caption + list header), `Expanded` → internal `ListView.builder` for rows |
| D18 | Processed Date + Reference columns | Rendered only under the Processed filter | Desktop screenshot shows both columns under the **Awaiting** filter, dash-filled | **Always render both columns**; null → dash. No filter-dependent column set |

**API behaviors baked into the design** (from the guide, non-negotiable):

- Payment status is **server-computed**; the client never sets "AwaitingPayment" — it only processes/reverts.
- Enum convention: **int id in query params** (`1`=Awaiting, `2`=Processed), **string name in responses & write bodies**.
- All write responses return a fresh `paymentsSummary` → update the dashboard card **from the response, never refetch `/api/company`**.
- Process / bulk-update are **all-or-nothing**; on `PaymentSheetNotAwaiting` the error `data` lists offending ids → refetch list, highlight, keep modal open with inline error.
- Max 100 ids per write/export-selected call.
- Zero-amount approved sheets never appear in any payment surface — server guarantees it, client doesn't filter.
- **The entire feature is manager-only** (user directive). Enforced at every layer: menu item `requiresManagerRole: true`; route behind `AuthGate` managerOnly; dashboard card manager-dashboard-only + hidden when `paymentsSummary` is `null` (the employee response); payment strip only on the manager sheet review screen; employee-facing screens completely untouched (D4). Server enforces 403 independently.
- All amounts in company base currency → `amount.toCurrency(companyLocale, companyCurrencyCode)`.

---

## 2. Architecture — New & Touched Files

### New files

| File | Contents |
|------|----------|
| `lib/models/payments_summary.dart` | `PaymentsSummary { int awaitingCount; double awaitingTotalAmount; }` + `fromJson` |
| `lib/models/payment_report_row.dart` | Row per API §3: `expenseSheetId`, `createdByUserId`, `employeeName`, `employeeGovId?`, `employeeEmail`, `cycleLabel`, `approvedDate`, `amount`, `paymentStatus` (string→enum), `processedDate?`, `reference?`, `note?` |
| `lib/models/paged_payments.dart` | Paged envelope (same shape as `PagedExpenseSheets`): items, page, pageSize, totalCount, hasMore, pageTotalAmount, grandTotalAmount |
| `lib/services/payment_service.dart` | All 6 endpoints + typed exceptions (see Phase 1) |
| `lib/providers/payments_provider.dart` | Service provider, `PaymentsFilter` value class, filter notifier, results notifier |
| `lib/screens/payments_report_screen.dart` | Orchestrator only — state, providers, layout (< 200 lines) |
| `lib/widgets/date_range_filter.dart` | **Generic** from/to date-range field (shared root — used twice here, reusable elsewhere). Label + two `showDatePicker` triggers + clear |
| `lib/widgets/manager_dashboard/awaiting_payment_card.dart` | Dashboard card, non-zero + zero states |
| `lib/widgets/payments/payment_status_badge.dart` | Awaiting (amber outline) / Processed (success outline) |
| `lib/widgets/payments/payments_filter_card.dart` | Desktop filter card: status dropdown + approval range + advanced toggle + Reset/Export All/Search row |
| `lib/widgets/payments/payments_advanced_filters.dart` | Expandable: employee dropdown, cycle dropdown, processed-date range |
| `lib/widgets/payments/desktop_payments_table.dart` | Header + `ListView.builder` body inside `StickyReportTable` |
| `lib/widgets/payments/desktop_payments_row.dart` | One row: checkbox, cells, per-row action button, highlight state |
| `lib/widgets/payments/desktop_bulk_action_bar.dart` | Green-tinted card (D9): BULK ACTION eyebrow · Export + Mark as Processed · "N sheet(s) of X₪" trailing. Animated in/out |
| `lib/widgets/payments/mark_processed_dialog.dart` | Modal (D6): title + X close, Processed Date (required, default today), Reference ID (optional), Note (optional, multiline), inline error, loading Confirm. X/Esc/scrim = Cancel, selection preserved |
| `lib/widgets/payments/mobile_payments_table.dart` | Mobile table-like list: pinned sortable header row (Employee / Amount / Payment Status) + internal `ListView.builder` of rows (D17) |
| `lib/widgets/payments/mobile_payment_row.dart` | Checkbox + name + amount + badge + trailing action icon, **cycle label as inline secondary line under the row** |
| `lib/widgets/payments/mobile_bulk_action_card.dart` | Green-tinted top card: BULK ACTION eyebrow, Export + Mark as Processed, "N sheet(s) of X". Animated in/out |
| `lib/widgets/payments/payments_filter_dialog.dart` | Mobile filter dialog (existing reports' tune-icon pattern, D16): all five filters + search/apply |
| `lib/widgets/payments/payments_active_filter_badge.dart` | Filter icon button with active-filter count badge (mobile header) |
| `lib/widgets/sheet_review/payment_status_strip.dart` | Strip between header/actions and line section (Phase 8) |
| `lib/widgets/payments/edit_payment_dialog.dart` | Phase 9 (scope-gated): edit processed date/reference/note, revert action |

### Touched files

| File | Change |
|------|--------|
| `lib/models/company_info.dart` | Add `PaymentsSummary? paymentsSummary` + `fromJson` + `copyWith` (add `copyWith` if missing) |
| `lib/providers/company_provider.dart` | Add `updatePaymentsSummary(PaymentsSummary)` — in-place `AsyncData` update, no refetch |
| `lib/screens/manager_dashboard_screen.dart` | Insert `AwaitingPaymentCard` after `SpendOverviewCard` (~line 152) |
| `lib/widgets/manager_dashboard/teammates_counter.dart` | D5①: card → slim strip, manager count kept (possible rename to `teammates_strip.dart`). States B–D only |
| `lib/router.dart` | `case '/manager/payments'` → `AuthGate(managerOnly) → PaymentsReportScreen` |
| `lib/models/menu_items.dart` | New `payments` menu item (manager-only) + `activeIdForRoute` mapping |
| `lib/widgets/header/desktop_menu.dart` + `lib/widgets/header/mobile_menu_sheet.dart` | id → route navigation for `payments` (mobile: close sheet first) |
| `lib/models/expense_sheet_detail.dart` | Phase 8: add 4 nullable payment fields |
| `lib/screens/sheet_review_screen.dart` | Phase 8: insert `PaymentStatusStrip` before `SheetReviewLineSection` (~line 390) |
| `lib/l10n/app_en.arb` / `app_he.arb` | Keys added per phase, **before** widget code, then `flutter pub get` |

### Key reused components (verified to exist)

- `StickyReportTable` (`lib/widgets/sticky_report_table.dart`) — desktop table container, as-is
- `CycleSelector`, `EmployeeFilterDropdown` pattern, `SearchButton`, `AppButton`
- `ApiService.get/post/put/postBinary` — `postBinary` already exists for xlsx downloads
- Browser download trigger pattern from `cycle_expenses_report_screen.dart` (web Blob + anchor)
- `PagedExpenseSheets` shape → `PagedPayments`; `PagingOverflowNotice` pattern
- `CounterCard` / `SpendOverviewCard` styling language for the dashboard card (amber alert chrome: `AppTheme.amber.withAlpha(20)` bg)
- `CancelSubscriptionDialog` pattern for the modal (loading + inline error + pop-true + post-frame SnackBar)
- `SubscriptionRequiredException` + existing locked-company messaging
- Pending-vs-applied filter state split from `expenses_analysis_screen.dart`
- `toCompanyDate` / `toCurrency` from `format_utils.dart`, locale from `companyLocaleProvider`

### State design

- **Filter state**: `PaymentsFilter` immutable class (statusId `int?`, userId, cycleId, approvedFrom/To, processedFrom/To). Held in a **non-autoDispose Notifier** → survives navigation away/back within the session (spec's filter-retention requirement, free).
- **Pending vs applied**: the screen edits a *pending* copy; `Search` commits it to the notifier, which triggers the fetch. Mobile sheet commits only on Apply.
- **Results**: `AsyncNotifier<PagedPayments?>` with `search(filter)`, `refresh()` (re-runs current filter), and `applyProcessResult(...)` (in-place row removal under Awaiting filter — preserves scroll).
- **Selection**: screen-local `Set<String>` (sheet ids). Cleared on successful process and on filter change. Capped at 100 with a friendly message (`PaymentBulkLimitExceeded` guard client-side too).
- **Sorting (D15)**: screen-local `_sortField` + `_sortAscending`, applied client-side to the loaded page before rendering (cycle-report pattern). Shared by desktop and mobile views; reset on new search.
- **Dashboard card**: reads `companyProvider`'s `paymentsSummary`; every write response calls `companyNotifier.updatePaymentsSummary(...)`.

---

## 3. Phases

Every phase: ARB keys first (en + he) → `flutter pub get` → widgets → wire-up → `flutter build web` → `/code-review` → fix blockers/should-fix → log findings in Status Board notes → user verifies.

---

### Phase 1 — Data layer (no UI)

**Files:** `payments_summary.dart`, `payment_report_row.dart`, `paged_payments.dart`, `payment_service.dart`, `payments_provider.dart`, `company_info.dart`, `company_provider.dart`

`PaymentService` (constructor-injected `ApiService` + `AuthService`, per existing pattern):

| Method | Endpoint | Notes |
|--------|----------|-------|
| `getPayments(PaymentsFilter, {page, pageSize=100})` | `GET /api/payments` | int `paymentStatus`, dates as `yyyy-MM-dd` |
| `processPayments({ids, processedDate, reference?, note?})` | `POST /api/payments/process` | returns `(processedCount, PaymentsSummary)` |
| `updatePayment(id, {status, processedDate?, reference?, note?})` | `PUT /api/payments/{id}` | status as string name; returns fresh `PaymentsSummary` |
| `bulkUpdatePayments({ids, status, ...})` | `POST /api/payments/bulk-update` | revert path |
| `exportPaymentsReport(PaymentsFilter)` | `POST /api/reports/export-payments-report` | `postBinary` → `Uint8List` |
| `exportSelectedPayments(ids)` | `POST /api/reports/bulk-export-payments-report` | `postBinary`, max 100 |

Typed exceptions (mirroring `expense_service.dart` style): `PaymentException(message, errorCode)`,
`PaymentSheetNotAwaitingException(offendingIds)` (parsed from error `data`),
`PaymentSheetNotProcessedException`, `PaymentBulkLimitExceededException`; reuse
`SubscriptionRequiredException` and 404 handling conventions.

`CompanyInfo`: nullable `paymentsSummary`, parsed defensively. `CompanyNotifier.updatePaymentsSummary()` added.

**Gate:** build passes; no visible change. CR on data-layer rules (no raw http, typed exceptions, immutable models).

---

### Phase 2 — Dashboard: teammates strip + Awaiting Payment card + route skeleton

> **⛔ DASHBOARD SCOPE GUARD (user directive, binding).** Exactly TWO visible dashboard changes
> are authorized: ① the teammates row appearance (card → slim strip, only when employees exist)
> and ② the new Awaiting Payment card. **DO NOT TOUCH anything else on the dashboard**:
> greeting, view switcher, invite block / State A flow, FirstSheetsInfoRow, counter cards
> (`counter_card.dart`, `sheet_counter_cards.dart`, `sheets_summary_mobile_card.dart`),
> `SpendOverviewCard` and its breakdown, refresh/invalidations, providers, routes, spacing of
> existing elements. If implementing the two changes appears to require modifying any file
> outside `teammates_counter.dart`, the new card widget, and the screen's children list —
> STOP and ask first.

**ARB keys:** `awaitingPaymentLabel`, `awaitingPaymentSheets` (for "N sheets" suffix via concat), `awaitingPaymentHint` ("Approved sheets not yet processed in payroll."), `awaitingPaymentAllClear` ("Nothing to pay — you're done"), `awaitingPaymentAllClearHint` ("All approved sheets have been processed."), `viewReport`, `viewHistory`, `paymentsTitle` (teammates/manage strings already exist)

**Work — dashboard rework (D5):**
1. **Teammates strip** (states B–D only; State A invite-block flow untouched): replace `TeammatesCounter`'s card layout with a slim chrome-less row — people glyph + "N Teammates" + manager count (kept, same data as today) + gear glyph + "Manage" text link (same `AppRoutes.managerUsers` target). Rework in place (`teammates_counter.dart`) or rename to `teammates_strip.dart` per file-naming rule — decide at CR.
2. **Counter cards: NO CHANGES** (user ruling — current implementation is better than the mock; `counter_card.dart` / `sheet_counter_cards.dart` untouched).
3. **`AwaitingPaymentCard`** (`ConsumerWidget`):
   - Reads `companyProvider` → `paymentsSummary`; `null` → `SizedBox.shrink()`.
   - **Non-zero:** amber-tinted chrome (border + `withAlpha(20)` bg), wallet icon in warning circle, "Awaiting Payment" muted label, `N sheets` large + total inline (`toCurrency`, smaller weight per mock), hint line desktop-only (`context.isMobile` hides it), trailing `AppButton` primary "View Report" + chevron → `/manager/payments` (args: processed filter = false).
   - **Zero (D19):** neutral chrome, success check circle icon, **"Nothing to pay — you're done"** primary line, success-tinted hint "All approved sheets have been processed." (desktop-only like the non-zero hint), trailing **"View History" text link + chevron** (spend-card "View more" pattern) → `/manager/payments` (args: processed filter = true).
4. Insert into `manager_dashboard_screen.dart` after `SpendOverviewCard` with 16px gap.

**Work — route skeleton + navigation menu:**
5. `PaymentsReportScreen` **skeleton**: scaffold with AppHeader / back row + title / AppFooter, reads route argument (initial status filter), body placeholder. (Phase 4 converts the body to the D17 pinned-scroll model.)
6. Route `/manager/payments` in `router.dart`, `AuthGate` managerOnly.
7. **Navigation menu entry** (all platforms, per CLAUDE.md multi-platform rule):
   - `MenuItems.getItems`: new item `id: 'payments'`, `requiresManagerRole: true`, wallet/payments outlined icon, label `t.paymentsTitle` — placed after `sheet-approvals` (manager workflow order: review → pay; **placement open to veto**).
   - id → route mapping in **both** `DesktopMenu` and `MobileMenuSheet` (close the sheet before navigating, per existing pattern). Opens the report with the default Awaiting filter (no arg).
   - `MenuItems.activeIdForRoute`: `'/manager/payments'` → `'payments'` for active-item highlight.
   - Verify via both navigation paths, desktop and mobile.

**Verify:** dashboard matches mocks — slim teammates strip with manager count (B–D states; a fresh company with no employees still gets the invite block); counter cards untouched; Awaiting Payment card non-zero state with live data (3 sheets / 1,152.00₪ in dev) AND zero state after processing everything ("Nothing to pay — you're done" + View History link); employee login shows no payment card; both CTAs land on the skeleton; RTL + mobile check.

---

### Phase 3 — Report filters (desktop)

**ARB keys:** `paymentStatusFilterLabel`, `paymentStatusAll`, `paymentStatusAwaiting`, `paymentStatusProcessed`, `approvalDateLabel`, `processedDateLabel`, `advancedFilters`, `employeeFilterLabel`, `cycleFilterLabel`, `allOption`, `resetFilters`, `exportAll`, plus date-range widget keys (`dateRangeFrom`, `dateRangeTo`, `dateRangeClear`)

**Work:**
1. `DateRangeFilter` (generic, root widgets folder): uppercase section label, two date fields (each opens `showDatePicker`), formatted via `toCompanyDate`, clearable, `EdgeInsetsDirectional` throughout. Returns `(DateTime? from, DateTime? to)` via callbacks.
2. `PaymentsFilterCard` per screenshot: row 1 = Payment Status `DropdownMenu` (per CLAUDE.md template: fixed width, `isCollapsed`, no `expandedInsets`) + Approval Date range. "ADVANCED FILTERS" expand/collapse toggle (chevron + label, `AnimatedSize`). Bottom row: Reset (ghost, leading) … Export All (normal, **disabled until Phase 6**) + Search (`SearchButton`).
3. `PaymentsAdvancedFilters` — expand/collapse reveals three more filters (Employee, Cycle, Processed Date range per screenshot). Data sources, all existing — **no new APIs needed for any filter**:
   - **Payment Status**: static local list (All / Awaiting Payment / Processed) → int id or omitted in the query.
   - **Approval Date / Processed Date ranges**: local `showDatePicker` pair (new `DateRangeFilter` widget) → `yyyy-MM-dd` params.
   - **Employee**: `companyEmployeesProvider` (`lib/providers/manager_dashboard_provider.dart:23`, already feeds the dashboard's employee filter) → `userId` param. "All" sentinel = omit. *Caveat: this provider returns active employees only (RoleId=2) — a peer manager's own sheets won't be filterable by name. Acceptable for now; backend `userId` accepts any guid if we later widen the source.*
   - **Cycle**: `cyclesProvider` (`lib/providers/expense_provider.dart:40` → `ExpenseService.getCycles()`, same source as the cycle expenses report) → `cycleId` param. "All" sentinel = omit.
4. Wire pending→applied: Search commits to `paymentsFilterProvider` and triggers `paymentsResultProvider.search()`. Reset restores defaults (status=Awaiting, everything else empty) and re-searches. Route arg from Phase 2 pre-applies Awaiting/Processed.
5. Initial load on screen open: auto-search with the pre-applied filter (per API recipe: `GET /api/payments?paymentStatus=1&page=1`).

**Verify:** filters render per screenshot, advanced section expands, search hits the API with correct params (network tab), reset works, filter state survives navigating away and back.

---

### Phase 4 — Results table (desktop)

**ARB keys:** column headers (`employeeColumn`, `govIdColumn`, `emailColumn`, `cycleColumn`, `approvedDateColumn`, `amountColumn`, `paymentStatusColumn`, `processedDateColumn`, `referenceColumn`), `markAsProcessed`, `selectSheetsCaption`, `noPaymentsFound`, overflow-notice strings

**Work:**
1. `PaymentStatusBadge`: Awaiting = amber outline/tint; Processed = success outline/tint (mirror `SheetStatusBadge` implementation).
2. `DesktopPaymentsTable` inside `StickyReportTable`: columns per screenshot —
   checkbox · Employee · Gov ID · Email · Cycle · Approved Date · Amount · Payment Status · Processed Date · Reference · row-action.
   Null govId/email/processedDate/reference → dash. Amount bold, end-aligned, tabular-nums, `toCurrency`. Reference bold. Horizontal scroll for narrow desktop (StickyReportTable provides it).
   **Sortable headers (D15)**: tap toggles field/direction with an arrow indicator, client-side sort on the loaded page — copy `_applySorting()` from the cycle report. Sortable: Employee, Cycle, Approved Date, Amount, Payment Status, Processed Date.
   **Scroll model (D17)**: no page-level scroll view — filter card, caption, and table header stay pinned; only the table body scrolls vertically (StickyReportTable's built-in behavior).
3. Caption above table: "Select sheets to process for payment".
4. Row body tap → `Navigator.pushNamed` existing sheet review route with `expenseSheetId` (back preserves filter/scroll since the screen stays in the stack).
5. Checkbox column **rendered but inert this phase** (no bulk bar yet); checkbox only on Awaiting rows, blank cell on Processed rows.
6. Empty state + loading + error states (StickyReportTable built-ins) ; overflow notice when `hasMore`.

**Verify:** table matches screenshot against dev data; dashes for nulls; row tap opens sheet review and back returns with state intact; Processed filter shows Processed Date + Reference populated.

---

### Phase 5 — Selection + Mark as Processed

**ARB keys:** `markSheetsProcessedTitle`, `processedDateField`, `referenceIdField`, `referenceIdPlaceholder`, `noteField`, `notePlaceholder`, `confirm`, `cancel`, `bulkActionLabel` ("BULK ACTION" eyebrow), `sheetsOfSuffix` parts (for "N sheet(s) of X" via concat), `processSuccessToast` parts, error strings (`tooManySheetsSelected`, `sheetsNoLongerAwaiting`, `paymentActionFailed`)

**Work:**
1. Activate selection: header select-all checkbox (selects all selectable rows on page), row checkboxes, selected-row tint, `Set<String>` in screen state.
2. `DesktopBulkActionBar` (D9, per screenshot): green/success-tinted card between filter card and caption when selection ≥ 1 — "BULK ACTION" eyebrow + icon leading, **Export** (disabled until Phase 6) + **Mark as Processed** buttons center, "N sheet(s) of X₪" trailing (total computed from selected rows). **Animates in/out** (AnimatedSize + fade, ~200ms — hard requirement, applies to the mobile bulk card in Phase 7 too). No Clear button — deselect via checkboxes. Pinned outside the table scroll region (D17) so it never scrolls away while selecting down the list.
3. `MarkProcessedDialog` (per screenshot + D6): title + X close button, Processed Date (required, defaults today, `showDatePicker`), Reference ID (optional, placeholder "Optional accounting batch ID" localized), Note (optional, multiline). No summary line. Confirm: spinner + disable → `processPayments`. Cancel / X / Esc / scrim: close, keep selection.
4. Per-row "Mark as Processed" button (Awaiting rows) → same dialog with single id.
5. On success: close dialog → `applyProcessResult` (rows leave the Awaiting view in place, scroll preserved) → clear selection → `companyNotifier.updatePaymentsSummary(response.paymentsSummary)` → floating SnackBar "Processed N sheets" (+ reference when provided).
6. Failure handling, all inline in the dialog (form stays filled, selection preserved):
   - `PaymentSheetNotAwaitingException` → refetch current filter in background, highlight offending row ids, inline message "some sheets are no longer awaiting — re-select and retry".
   - `MandatoryFieldsMissing` → field-level validation message on date.
   - `SubscriptionRequiredException` → existing locked-company message.
   - `PaymentBulkLimitExceeded` → "too many sheets selected" (also guarded client-side at 100).
   - Network/other → generic retry message.

**Verify (the big one):** select 2 of 3 → bar shows correct count/total → process with reference → rows disappear in place, dashboard card drops to 1, toast shows; switch to Processed filter → rows there with date+reference; per-row button works; cancel preserves selection; simulate concurrency (process same sheet from a second session) → batch fails wholesale with highlight.

---

### Phase 6 — Excel exports

**ARB keys:** `exportSelected`, `exportFailed`

**Work:**
1. **Export All** (filter bar): sends the **currently applied** filter params (not pending edits) to `export-payments-report`; download via existing web Blob/anchor pattern; filename `payments-report-<yyyy-MM-dd>.xlsx` (date from applied filter or today). Loading state on button.
2. **Export Selected** (bulk bar): sends ids to `bulk-export-payments-report`.
3. Enable both buttons (placed in Phases 3/5). Error → SnackBar.

**Verify:** both downloads open in Excel with the documented 9 columns; Export All respects active filters; Export Selected matches selection.

---

### Phase 7 — Mobile layout

**ARB keys:** `filters`, `applyFilters`, chip labels as needed

**Work (per mobile screenshot — a distinct layout, not a squeezed desktop):**
1. Header row: back + title + `PaymentsActiveFilterBadge` (tune icon + active-filter count badge) + compact Export All button. **Pinned** (D17).
2. `PaymentsFilterDialog` (D16): opened from the tune icon, **same dialog pattern as the existing reports** (cycle expenses / analysis screens): all five filters stacked + search/apply button; dismiss discards pending edits. Reuses the same pending-filter widgets as desktop.
3. `MobilePaymentsTable` (D17 scroll model): fixed column = header row → animated `MobileBulkActionCard` → "Select sheets to process for payment" caption → **pinned sortable header row** (Employee / Amount / Payment Status — tap to sort, D15) → `Expanded` → internal `ListView.builder` of rows. The page itself never scrolls.
4. `MobilePaymentRow`: leading checkbox, employee name, amount, payment badge, trailing circle action icon (per-row mark-as-processed); **cycle label rendered as an inline secondary line under the row** (small, muted — per screenshot). Row body tap → sheet review.
5. `MobileBulkActionCard` (green/success-tinted, top position per screenshot): "BULK ACTION" eyebrow with icon, Export + Mark as Processed buttons, "N sheet(s) of X₪" summary line. **Animates in on first selection, out when selection clears** (same ~200ms treatment as desktop).
6. Breakpoint switch in the screen via `context.isMobile`; mark-as-processed dialog already responsive (maxWidth-constrained).

**Verify:** match mobile screenshot at < 600px; pinned regions stay put while the row list scrolls; sort by tapping mobile headers; filter dialog apply/dismiss semantics; bulk card animates in/out; bulk flow end-to-end on mobile; RTL pass.

---

### Phase 8 — Sheet review payment strip (manager)

**ARB keys:** `paymentStatusLabel`, `processedOnLabel`, `payableTotalLabel`

**Work:**
1. `ExpenseSheetDetail`: add nullable `paymentStatus`, `processedDate`, `reference`, `note` (graceful parse).
2. `PaymentStatusStrip` (`lib/widgets/sheet_review/`): rendered only when `paymentStatus != null` (manager view only — this screen already is).
   - **Awaiting:** warning wallet glyph, "Payment status" label, Awaiting badge, payable total trailing. No empty reference/date rows.
   - **Processed:** success check glyph, Processed badge, **Reference** bold/tabular-nums, **Processed on** (`toCompanyDate`), payable total trailing. (No processed-by — D10.)
3. Insert in `sheet_review_screen.dart` between actions and `SheetReviewLineSection` (16px gaps).
4. After a process action on the report, the detail provider for affected sheets is invalidated (`ref.invalidate(sheetDetailProvider(id))`) so re-opening shows fresh state.

**Verify:** open an awaiting sheet from the report → strip shows awaiting; process it → reopen → strip shows processed with reference/date; sheets with no payment dimension (zero-amount/unapproved) show no strip.

---

### Phase 9 — Edit / Revert processed rows ⚠️ SCOPE GATE

The API supports editing processed details and reverting to awaiting (`PUT /api/payments/{id}`,
`POST /api/payments/bulk-update`), and the product spec says Processed must be reversible.
**The screenshots show no UI for it.** Proposed minimal scope — **confirm before this phase starts**:

1. On **Processed** rows (desktop row action / mobile trailing icon): "Edit" opens `EditPaymentDialog`
   prefilled with date/reference/note (`note` is returned by the list API exactly for this).
2. Dialog has a secondary destructive "Revert to Awaiting" action with a confirm step
   (reuse `LastActionConfirmDialog`).
3. Both paths update rows in place + refresh dashboard summary from the response.
4. Bulk revert: **skip for now** (the "undo a payroll run" recipe) unless requested.

Errors: `PaymentSheetNotProcessed` → refetch + inline message; `MandatoryFieldsMissing` (date required when status stays Processed) → field validation.

---

### Phase 10 — Final pass

1. Full RTL checklist sweep over every new widget (Step-5 table from CLAUDE.md).
2. l10n audit: zero hardcoded strings, he translations reviewed.
3. Full `/code-review` over the cumulative diff; fix findings.
4. `flutter build web` final + manual smoke of all flows desktop/mobile/he.
5. Move `payment-status-feature-spec.md`, `payment-status-flutter-guide.md`, and this plan to `docs/completed/` (after user sign-off only); update `docs/current-work.md`.

---

## 4. Out of Scope (explicit)

- Employee-facing payment visibility (D4) — backend says no data exists for employees; revisit when the API adds it. Lovable spec §6 is the design reference for that future work.
- Bulk revert / "undo a payroll run" flow (Phase 9 note).
- Pagination controls beyond the 100-row page + overflow notice (D14).
- Sheet-review-side "process" actions — processing lives only in the Payments Report (per spec: deeper actions live in the report).
- Dashboard redesign items from Lovable spec §3 (teammates strip rework, stat-card changes) — D5.

## 5. Open Questions for Approval

1. **Phase 9 scope** — include the minimal Edit/Revert dialog as proposed, defer entirely, or expand to bulk revert?
2. **Paging (D14)** — OK with pageSize=100 + overflow notice, no pager?

~~3. Modal summary line~~ — resolved during plan review: pixel-faithful to the screenshot, no summary line (D6).
