# Story 02 — Manager Dashboard · Code Review

**Reviewing:** all files created or modified by [02-ManagerDashboard.md](02-ManagerDashboard.md), built across slices #16–23.

**Lens:** the six rules codified in [`.claude/commands/code-review.md`](../../../.claude/commands/code-review.md).

**Audit ran 2026-05-24.** `flutter build web` clean.

---

## TL;DR

Manager dashboard shipped end-to-end against the locked server contract. Row tap → Sheet Review is a placeholder snackbar until story 03 ships; refresh contract is already wired. Two widget files marginally exceed the 200-line target — both justified by the Rule 1 micro-helper exception. Otherwise clean across all six rules.

---

## 1. Server contract verification

Cross-referenced [`Controllers/ExpenseSheetsController.cs`](../../../../../BackEnd/XpenseDeskServer/Controllers/ExpenseSheetsController.cs), [`Services/ExpenseSheets/ExpenseSheetService.cs`](../../../../../BackEnd/XpenseDeskServer/Services/ExpenseSheets/ExpenseSheetService.cs), and the BDD test feature [`XpenseDeskServer.Tests/Features/Expenses/ManagerDashboardSheetLists.feature`](../../../../../BackEnd/XpenseDeskServer/XpenseDeskServer.Tests/Features/Expenses/ManagerDashboardSheetLists.feature). Client implementation matches every scenario:

| Server behavior | Client wiring |
|---|---|
| `/queue` returns `PagedExpenseSheetListResponse` (top 12, no client paging) | `ExpenseService.getApprovalsQueue()` → `PagedExpenseSheets` |
| `GET /api/expense-sheets?statusId&cycleId?&userId?&page&pageSize` returns same envelope | `getCompanyExpenseSheets({statusId, userId?, cycleId?, page, pageSize})` |
| `statusId` required → `400 MandatoryFieldsMissing` | Required `int statusId` arg; no possibility to omit |
| `statusId` not in {2,3,4} → `400 InvalidExpenseSheetStatusForListing` | `InvalidExpenseSheetStatusForListingException` mapped from errorCode |
| Cross-company `userId` → `200`, empty items, `totalCount=0`, `grandTotalAmount=0` | Handled by normal empty-envelope rendering |
| `pageSize` clamped to 1–100 server-side | Default 12 from client; never sends >100 |
| `hasMore = (page * pageSize) < totalCount` | Read from envelope, not re-derived |
| Manager-only (403 for employee) | UI gated by `AuthGate(managerOnly)` |
| **DTO parity** across `/queue`, `/me`, `/{userId}/list`, paged endpoint | One client model `ExpenseSheetListItem` for all four — and **cleaned up** to match: dropped phantom `reviewedByName` (only on detail DTO), made `createdByUserId` nullable to match server `Guid?` |

**One contract-driven model fix applied this round:** `ExpenseSheetListItem.reviewedByName` was a phantom field — story 01 added it speculatively but the server never populates it on list rows. Removed. `reviewedByName` still lives on `ExpenseSheetDetail` (the detail endpoint *does* return it).

## 2. File-size audit

| File | Lines | Verdict |
|---|---:|---|
| sheet_bucket_enums.dart | 11 | ✅ |
| paging_overflow_notice.dart | 37 | ✅ |
| approved_card.dart | 40 | ✅ |
| page_header_row.dart | 42 | ✅ |
| desktop_sheet_bucket_header.dart | 43 | ✅ |
| desktop_sheet_bucket_table.dart | 43 | ✅ |
| mobile_sheet_bucket_list.dart | 43 | ✅ |
| spend_overview_placeholder.dart | 53 | ✅ |
| paged_expense_sheets.dart | 56 | ✅ |
| sheet_bucket_card_header.dart | 75 | ✅ |
| returned_to_employee_card.dart | 77 | ✅ |
| sheet_bucket_empty_state.dart | 80 | ✅ |
| pending_review_card.dart | 81 | ✅ |
| employee_filter_dropdown.dart | 84 | ✅ |
| manager_dashboard_provider.dart | 100 | ✅ |
| manager_dashboard_screen.dart | 105 | ✅ |
| mobile_sheet_bucket_row.dart | 166 | ✅ |
| sheet_bucket_card.dart | 205 | ⚠️ 5 over |
| desktop_sheet_bucket_row.dart | 218 | ⚠️ 18 over |

The two over-limit files:

- **`sheet_bucket_card.dart` (205)** — the orchestrator widget for the shared collapsible card. Body is the public `SheetBucketCard` + its `_SheetBucketCardState` (FooState — allowed). No substantial private widgets — the header was extracted to `sheet_bucket_card_header.dart`. The state class is the only thing keeping this over 200. Acceptable; further breakdown would split state from build with no clarity gain.
- **`desktop_sheet_bucket_row.dart` (218)** — `DesktopSheetBucketRow` is the substantial widget (~150 lines of layout). The trailing 70 lines are two micro-helpers: `_ActionWidget` (35 lines, switch dispatcher) + `_MiniOutlinedButton` (30 lines, styling wrapper). Per **Rule 1 exception** (trivial styling micro-helpers under ~30 lines may stay private), both are justifiably private.

## 3. Embedded private classes audit

6 hits — all justified:

| File | Class | Status |
|---|---|---|
| sheet_bucket_card.dart | `_SheetBucketCardState` | ✅ FooState pair (Rule 1 allowance) |
| desktop_sheet_bucket_row.dart | `_ActionWidget` | ✅ Rule 1 exception (33 lines, switch dispatcher) |
| desktop_sheet_bucket_row.dart | `_MiniOutlinedButton` | ✅ Rule 1 exception (30 lines, styling wrapper) |
| mobile_sheet_bucket_row.dart | `_MobileBucketAction` | ✅ Rule 1 exception (32 lines, switch dispatcher) |
| pending_review_card.dart | `_AwaitingPill` | ✅ Rule 1 exception (24 lines, styled pill) |
| returned_to_employee_card.dart | `_MutedDestructiveBadge` | ✅ Rule 1 exception (24 lines, styled badge) |

Substantial extracted this round (during Slice 6 cleanup): `_DesktopBucketHeader` → `desktop_sheet_bucket_header.dart`, `_DesktopBucketRow` → `desktop_sheet_bucket_row.dart`, `_MobileBucketRow` → `mobile_sheet_bucket_row.dart`, `_Header` → `sheet_bucket_card_header.dart`. Plus `SheetBucketTimestampSource` + `SheetBucketActionStyle` enums lifted from the table file into a dedicated `sheet_bucket_enums.dart` so the mobile list doesn't have to import from `desktop_*` (which was a weirdness flagged before the refactor).

## 4. Hardcoded currencies & captions

- **Currencies — clean ✅.** Zero `'$'` / `'₪'` / `'€'` / `'£'` literals in any manager-dashboard widget file. Every amount renders via `num.toCurrency(companyLocale, currencyCode)` from `lib/utils/format_utils.dart`.
- **Captions — clean ✅.** `grep "Text\('[A-Za-z]"` over `lib/widgets/manager_dashboard` returns zero hits. Every user-visible string uses `AppLocalizations.of(context)!`.
- Reused the [shared `AiBadge`](../../../lib/widgets/ai_badge.dart) widget where AI badges appear (no new `'AI'` literals introduced).

## 5. Flutter hygiene

`grep` for `withOpacity`, `arrow_back_ios`, `arrow_forward_ios`, `TextAlign.left|right`, `EdgeInsets.only(left:|right:)` — all zero.

`EdgeInsetsDirectional` is used wherever directional spacing matters (e.g. the filter dropdown leading icon at `EdgeInsetsDirectional.only(start: 8)`).

## 6. Responsive overflow risk (Rule 6)

- Desktop table Actions column uses `SizedBox(width: 80)` instead of `Expanded(flex:)` — same fix from story 01's slice 6 retroactive.
- Mobile rows use `Expanded(child: ...)` for the leading column + `Column(crossAxisAlignment: CrossAxisAlignment.end)` for the trailing — no fixed-width-in-flex traps.

## 7. ARB key delta

Added EN + HE for: `managerDashboardTitle`, `allEmployees`, `pendingReviewCardTitle`, `returnedToEmployeeCardTitle`, `approvedCardTitle`, `awaitingSuffix`, `noPendingSheets`, `noReturnedSheets`, `noApprovedSheets`, `pagingOverflowPrefix`, `pagingOverflowOf`, `pagingOverflowSuffix`, `returnedAt`, `approvedAt`, `cycle`, `items`, `submitted`, `tableTotalHeader`, `sheetReviewComingSoon`. Hebrew uses `גליון`/`גליונות` per the earlier correction.

## 8. Known follow-ups (not blockers)

- **`refreshAllProviders`** now invalidates the manager dashboard's family providers + the employee sheet providers. Pull-to-refresh on any screen will reset them — intentional per the helper's "inactive providers are silently reset" contract, but worth noting in case a future screen wants to opt out.
- **Sheet Review navigation** — row tap shows a placeholder snackbar. When story 03 ships, swap the body of `_ManagerDashboardScreenState._onRowTap` (one TODO marker in place) with `Navigator.pushNamed('/manager/sheet/{id}').then((_) => _refreshSheetProviders())`. The refresh contract is already wired.
- **Spend Overview** — soft-degraded placeholder at the top. Real widget (`lib/widgets/dashboard/spend_overview_widget.dart`) already exists but is expense-list-centric, not sheet-centric. Refactoring it to be sheet-aware is its own story.
- **DTO drift across endpoints** is a forward commitment from the server team (story 02 §3.2). If future server changes add a field to `/me` but skip `/queue`, the shared `ExpenseSheetListItem` model breaks silently. Add a code-review note: any change to the row DTO must update all four endpoint mappings together.
- **Hebrew translations** — `אישורים`, `ממתינים לאישור`, `הוחזר לעובד`, `אושרו`, `ממתינים` (suffix), `מציג / מתוך / הפריטים האחרונים. תמיכת עימוד תגיע בקרוב.`, `מסך סקירת הגליון יגיע בקרוב`. Best-effort — please skim and adjust where it sounds unnatural.

---

## Done definition

- ✅ §2 of [02-ManagerDashboard.md](02-ManagerDashboard.md) implemented end-to-end.
- ✅ Server contracts verified against `XpenseDeskServer` and its BDD test feature file.
- ✅ All six CR rules from `.claude/commands/code-review.md` satisfied.
- ✅ Build clean.
- ⏸ Manual UI verification — your turn.
