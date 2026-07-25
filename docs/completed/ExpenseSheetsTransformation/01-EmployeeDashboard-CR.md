# Story 01 — Employee Dashboard · Code Review

**Reviewing:** all files created or modified by [01-EmployeeDashboard.md](01-EmployeeDashboard.md).
**Lens:** the two rules called out by the reviewer —
1. No large files. Every component is its own class **in its own file**.
2. Logic belongs in services. Helpers belong in utils. Widgets shouldn't house either.

---

## TL;DR

The data and provider layer is clean. The widget layer has **three structural issues** worth fixing before story 02 builds on this code:

1. **Five widget files are over 200 lines**, four of them because they contain a second, large private widget class that should be in its own file.
2. **Two screens carry domain logic and permission rules inline.** Selection rules ("which sheet is the current-cycle Draft?", "which is the default?") and bucket math ("count of declined expenses", "can this tab edit?") are pure functions on sheet/expense data — they belong in `lib/utils/` so the manager dashboard (story 02) can reuse them.
3. **`'AI'` is hardcoded in 4 places** (2 mine, 2 pre-existing). Currencies are clean. Extracting a shared `AiBadge` widget kills the duplication.

Fixes are mechanical. Estimated 30–45 minutes. No build break risk.

## ✅ Resolution (applied 2026-05-23)

All three issues fixed via the refactor plan in §6. Final state:

| Audit | Before | After |
|---|---|---|
| Widget files > 200 lines | 5 | 0 |
| Embedded private widgets (non-`_FooState`) | 6 | 0 |
| Hardcoded `'AI'` sites | 4 | 1 (centralised in `lib/widgets/ai_badge.dart`) |
| Domain logic inside widgets | 10 helpers across 4 files | 0 (all moved to `lib/utils/sheet_utils.dart` — 3 grouped classes: `SheetSelection`, `SheetExpenseBuckets`, `SheetPermissions`) |
| Build status | ✅ clean | ✅ clean |
| Resolution overflow (desktop Actions column) | flex-based, fragile at narrow widths | `SizedBox(width: 80)` — fixed minimum |

The 200-line rule is now codified as **Rule 1** in [`.claude/commands/code-review.md`](../../../.claude/commands/code-review.md), with the explicit exception that util/service modules may exceed 200 when they contain multiple grouped classes by theme (`sheet_utils.dart` at 223 lines is the canonical example).

---

## 1. File-size audit

| File | Lines | Verdict |
|---|---:|---|
| lib/models/dashboard_ui_state.dart | 6 | ✅ |
| lib/providers/expense_sheet_provider.dart | 37 | ✅ |
| lib/models/expense_sheet_log_entry.dart | 42 | ✅ |
| lib/widgets/employee_dashboard/view_mode_toggle.dart | 44 | ✅ |
| lib/models/expense_sheet_status.dart | 49 | ✅ |
| lib/widgets/employee_dashboard/page_header_row.dart | 66 | ✅ |
| lib/models/expense_sheet_list_item.dart | 72 | ✅ |
| lib/widgets/employee_dashboard/mobile_sheet_expense_carousel.dart | 76 | ✅ |
| lib/widgets/employee_dashboard/sheet_status_badge.dart | 76 | ✅ |
| lib/widgets/employee_dashboard/sheet_expense_empty_state.dart | 77 | ✅ |
| lib/models/expense_sheet_detail.dart | 92 | ✅ |
| lib/widgets/employee_dashboard/sheet_picker_dropdown.dart | 97 | ✅ |
| lib/providers/employee_dashboard_provider.dart | 111 | ✅ |
| lib/widgets/employee_dashboard/returned_sheets_global_alert.dart | 113 | ✅ |
| lib/widgets/employee_dashboard/declined_sheet_banner.dart | 114 | ✅ |
| lib/widgets/employee_dashboard/sheet_picker_tile.dart | 182 | ⚠️ borderline |
| lib/screens/user_dashboard_screen.dart | 208 | ❌ over |
| lib/widgets/employee_dashboard/status_filter_tabs.dart | 235 | ❌ over |
| lib/widgets/employee_dashboard/mobile_sheet_expense_list.dart | 252 | ❌ over |
| lib/widgets/employee_dashboard/employee_dashboard_body.dart | 282 | ❌ over |
| lib/widgets/employee_dashboard/desktop_sheet_expense_table.dart | 311 | ❌ over |

The screen orchestrator (208) is barely over and drops cleanly once selection logic moves to utils (§3 below). The other four overflow because they each contain a second private widget class.

## 2. Private classes that should be their own files

`grep '^class _\w+ '` on the widget folder turns up seven hits. Two are routine state-class pairs and can stay (`_UserDashboardScreenState`, `_SheetPickerDropdownState`). The other five are real components inlined as private classes:

| Host file | Embedded class | Lines | Recommendation |
|---|---|---:|---|
| desktop_sheet_expense_table.dart | `_HeaderRow` | ~45 | Extract to `desktop_sheet_table_header.dart` |
| desktop_sheet_expense_table.dart | `_BodyRow` | ~160 | Extract to `desktop_sheet_table_row.dart` |
| desktop_sheet_expense_table.dart | `_ActionIconButton` | ~25 | Promote to shared `lib/widgets/action_icon_button.dart` (mobile list reuses the same pattern) |
| mobile_sheet_expense_list.dart | `_Row` | ~190 | Extract to `mobile_sheet_expense_row.dart` |
| status_filter_tabs.dart | `_TabButton` | ~115 | Extract to `status_filter_tab_button.dart` |
| employee_dashboard_body.dart | `_ExpensesArea` | ~100 | Extract to `sheet_expenses_area.dart` |

After this round of splits all five "over" files drop well under 200.

## 3. Logic that belongs in utils, not widgets

Three concerns each accidentally landed in a widget:

### 3.1 One sheet-utils file, grouped by concern

All ten helpers across the widgets are pure functions on sheet/expense data. They go in **one file** with multiple small static-method classes — the same pattern `lib/utils/format_utils.dart` already uses (one file, multiple extensions grouped by theme).

```
lib/utils/sheet_utils.dart

  class SheetSelection {
    /// Filter out finalised (Approved) sheets — they live in history.
    static List<ExpenseSheetListItem> nonFinalised(List<ExpenseSheetListItem> all);

    /// Default picker selection: current-cycle Draft if present,
    /// otherwise the newest non-finalised sheet.
    static ExpenseSheetListItem? defaultSelection(List<ExpenseSheetListItem> visible);

    /// True when this sheet is the Draft for the highest cycle label
    /// in the full list.
    static bool isCurrentCycleDraft(ExpenseSheetListItem sheet, List<ExpenseSheetListItem> all);

    /// Picker dropdown order: current-cycle Draft first, then cycleLabel desc.
    static List<ExpenseSheetListItem> pickerOrder(List<ExpenseSheetListItem> sheets);

    /// Stable dismissal key for the returned-sheets alert — sorted IDs
    /// joined by `|`. Reappears when the set of returned sheets changes.
    static String dismissalKey(List<ExpenseSheetListItem> returnedSheets);
  }

  class SheetExpenseBuckets {
    static List<ExpenseSummary> filterByTab(List<ExpenseSummary> all, FilterTab tab);
    static Map<FilterTab, int> countsPerTab(List<ExpenseSummary> all);
    static Map<FilterTab, double> totalsPerTab(List<ExpenseSummary> all);
  }

  class SheetPermissions {
    /// Mirrors the server matrix in ExpenseSheetsEvolution.md §0.7.
    static bool canEditExpense({
      required int sheetStatusId,
      required int expenseStatusId,
      required bool isManager,
    });

    static bool canDeleteExpense({
      required int sheetStatusId,
      required int expenseStatusId,
      required bool isManager,
    });
  }
```

One file. One import line. The class-per-concern keeps usage semantically clear at call sites: `SheetSelection.defaultSelection(...)`, `SheetPermissions.canEditExpense(...)`. Story 02 + story 03 get all the primitives for free.

### 3.2 Helpers currently inlined in widgets — to move

| Currently in | Helper | Lands as |
|---|---|---|
| `user_dashboard_screen.dart` | `_visibleSheets`, `_defaultSheet`, `_isCurrentCycleDraft` | `SheetSelection.nonFinalised` / `.defaultSelection` / `.isCurrentCycleDraft` |
| `sheet_picker_dropdown.dart` | `_sortedSheets()` | `SheetSelection.pickerOrder` |
| `returned_sheets_global_alert.dart` | `_keyFor()` | `SheetSelection.dismissalKey` |
| `employee_dashboard_body.dart` | `_filteredExpenses`, `_countsPerTab`, `_totalsPerTab` | `SheetExpenseBuckets.filterByTab` / `.countsPerTab` / `.totalsPerTab` |
| `employee_dashboard_body.dart` | `_canEditForDeclinedTab`, `_canDeleteForDeclinedTab` | `SheetPermissions.canEditExpense` / `.canDeleteExpense` (richer signature — takes statusIds + role instead of just a tab; the body translates the tab to a status id at the call site) |

### 3.3 What stays in widgets

`sheet_picker_tile.dart` getters (`_isDeclined`, `_isSubmitted`, `_leadingIcon`, `_leadingIconColor`, `_metaText`, `_totalText`) are presentation — they pick icons and colors. They stay on the widget.

### 3.4 Cycle-label parsing — already in utils ✅

`String.toCycleLongMonth(locale)` correctly went into `lib/utils/format_utils.dart` during the Slice 3 build. Mentioned only because it's the pattern — the rest of §3.2 follows the same approach.

## 4. Hardcoded currencies & captions audit

### Currencies — clean ✅

`grep` for `'$'`, `'₪'`, `'€'`, `'£'` literals inside string content across the employee-dashboard widgets returns **zero hits**. Every amount goes through `num.toCurrency(companyLocale, currencyCode)` in `format_utils.dart`, which derives the symbol from `NumberFormat.simpleCurrency(name: currencyCode)`. Switch the company's `currencyCode` server-side and every amount on the dashboard re-renders with the new symbol — no code changes needed.

### Captions — one exception worth flagging ⚠️

`grep` for `Text('[A-Za-z]`, `tooltip:`, `label:`, `hintText:`, `labelText:`, `message:` with raw-string values returns **one** caption literal in my new code:

```dart
// desktop_sheet_expense_table.dart:227
Text('AI', style: ...)
// mobile_sheet_expense_list.dart:177
Text('AI', style: ...)
```

This is the `AI` badge on AI-detected expense rows.

**Project precedent matters here:** the same literal `'AI'` already exists in two pre-existing files:

```
lib/screens/employee_expense_detail_screen.dart:462
lib/widgets/expenses/mobile_expense_modal.dart:317
```

So the established convention is "AI" stays English in both EN and HE — it's an initialism / brand-y term that doesn't translate naturally. My two new sites match that convention.

**Two ways to resolve:**

- **(a) Add an ARB key `aiBadge` = "AI" / "AI"** and route all four sites through `l10n.aiBadge`. Strictly correct per CLAUDE.md "EVERY user-visible string MUST use AppLocalizations" rule. Cost: 4 file edits + 2 ARB entries that are literally identical English in both languages.

- **(b) Extract a shared `AiBadge` widget** (`lib/widgets/ai_badge.dart`) — encapsulates the `'AI'` literal in one place so it stops being copy-pasted across files. Doesn't touch ARB. The literal stays but it's no longer scattered.

Recommend **(b)** — it removes the duplication, lets us style the badge consistently, and the `'AI'` literal lives in exactly one file from then on. If we later decide to localise (option a), it's a single-file change.

### Other typographic characters — fine

`'—'` (em dash) for null-value fallback and `' · '` (middle dot) as a separator in the mobile list — both used in widget code as literals. These are typography, not captions; they read identically in EN and HE and don't need translation. Same pattern is already used across `mobile_expense_card.dart` and other existing widgets.

---

## 4b. Known regression risk — desktop table overflow at narrow widths

**Discovered during manual UI testing of Slice 6 (2026-05-23).** The desktop expense table's Actions column was rendered with `Expanded(flex: 10)` — that's roughly 10% of the row width. The column has to host two 32×32 icon buttons + a 4px gap = **68px of intrinsic-width content**. At any viewport where the row's 10% is less than ~68px (so total table width < ~680px), Flutter renders a `RIGHT OVERFLOWED BY 4.8 PIXELS` debug stripe.

**Fix applied:** Actions flex bumped to 12, Date flex reduced to 18 to keep the total at 100, `mainAxisSize.min` added to the inner Row, the inter-icon `SizedBox(width: 4)` removed. Build clean, overflow gone at the viewport the user reported.

**Why it's a regression risk:** the fix is still flex-percentage based. If a future change adds a third action icon, or if a viewport is narrower than today's minimum, the same class of overflow returns.

**Robust fix (apply during Step C of the refactor plan):** when `_BodyRow` and `_HeaderRow` are extracted into their own files, switch the Actions column from `Expanded(flex: ...)` to `SizedBox(width: 80)`. Intrinsic-width content (icon buttons) belongs in a fixed-width container, not a proportional one. Adopt the same pattern for any future column that hosts only icons.

This is now codified as **Rule 6 (Responsive overflow risk)** in [`.claude/commands/code-review.md`](../../../.claude/commands/code-review.md) so the lesson sticks.

---

## 5. Other observations (smaller stuff)

- **`mobile_sheet_expense_carousel.dart` is still a vertical stack**, not a true carousel. Called out in the slice 10 caveats but worth tracking as a follow-up before manager-side work changes assumptions about mobile gestures.
- **`expense_dashboard_body.dart` `_refreshAll`** invalidates three providers including the unrelated `expenseSearchProvider`. That last invalidate is defensive (some old UI path may still watch it) but is no-op for this screen — could be dropped once we confirm no one watches it.
- **`Padding(padding: const EdgeInsetsDirectional.only(start: 26))`** in `declined_sheet_banner.dart` repeats three times. Tiny duplication, fine for now; would refactor to a local `_indent` const if the banner grows.
- **Existing `lib/widgets/expenses/` widgets** (`expense_status_toggle`, `mobile_expense_modal`, `total_approved_badge`, `expenses_empty_state`) are no longer referenced by the employee dashboard. Out-of-scope for this CR; flag for a separate cleanup once story 02 finishes its rewrite.

## 6. Recommended refactor plan (sequenced)

Each step is independently shippable. Mechanical work; ~30–45 minutes total.

### Step A — Create one utils file (no widget changes)
- [ ] `lib/utils/sheet_utils.dart` — three classes: `SheetSelection`, `SheetExpenseBuckets`, `SheetPermissions`. All ten helpers from §3.1 + §3.2.
- [ ] Build clean.

### Step B — Wire utils into existing widgets (no behavior change)
- [ ] `user_dashboard_screen.dart` → use `SheetSelection`. Drops to ~140 lines.
- [ ] `employee_dashboard_body.dart` → use `SheetExpenseBuckets` + `SheetPermissions`. Drops to ~190 lines (after step C drops further).
- [ ] `sheet_picker_dropdown.dart` → use `SheetSelection.pickerOrder`.
- [ ] `returned_sheets_global_alert.dart` → use `SheetSelection.dismissalKey`.
- [ ] Build clean.

### Step C — Extract embedded widgets into their own files
- [ ] `_HeaderRow` → `desktop_sheet_table_header.dart`.
- [ ] `_BodyRow` → `desktop_sheet_table_row.dart`.
- [ ] `_ActionIconButton` → `lib/widgets/action_icon_button.dart` (shared, picked up by both the desktop table and the mobile list).
- [ ] `_Row` → `mobile_sheet_expense_row.dart`.
- [ ] `_TabButton` → `status_filter_tab_button.dart`.
- [ ] `_ExpensesArea` → `sheet_expenses_area.dart`.
- [ ] **AI badge** → `lib/widgets/ai_badge.dart` (shared; replaces the four scattered `Text('AI')` sites — my two new ones plus the two pre-existing ones).
- [ ] Build clean.

### Step D — Verify final state
- [ ] `wc -l` on every employee-dashboard widget file — every result under 200.
- [ ] `grep '^class _\w+ ' lib/widgets/employee_dashboard` returns only the conventional `_FooState` pairs.
- [ ] Visual smoke pass against story 01 §2 — nothing should look different.

---

## Decision needed

Three options:

- **(a) Apply A → B → C → D now.** Worth it because story 02 will reuse the utils immediately, and the widget extractions stop tech debt from compounding.
- **(b) Apply A + B (utils only) now, defer C (widget extraction) to a later pass.** Lower risk; gets the reuse value before story 02.
- **(c) Defer all of it.** Acceptable if story 02 has higher priority; revisit before story 03.

My recommendation: **(a)** — it's all mechanical, the build is the safety net, and going into story 02 with clean primitives saves us from copy-pasting.

Tell me which one and I'll execute.
