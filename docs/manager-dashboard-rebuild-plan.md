# Manager Dashboard Rebuild Plan

## Context

The manager dashboard went unstable (crashes on resize, navigation back from other screens).
Stub screen (`ManagerDashboardStubScreen`) confirmed infrastructure is stable — root cause is
inside the screen itself.

Strategy: reconstruct the screen element-by-element into `manager_dashboard_screen.dart`,
replacing the original. Each step must build and pass a manual stability check before proceeding.

Stub screen (`manager_dashboard_stub_screen.dart`) and router pointing to it remain until
step 7 is complete and verified.

---

## Elements Inventory

The original screen has 7 logical layers:

| # | Element | Risk notes |
|---|---------|------------|
| 1 | Scaffold skeleton | Provider watch (`expenseSearchProvider`) but no content rendered |
| 2 | Header row — title only | `_buildHeaderRow` without the dropdown |
| 3 | Header row — employee dropdown | `_EmployeeFilterDropdown` (DropdownMenu) — **previously had `BoxConstraints(w=Infinity)` crash** |
| 4 | SpendOverviewWidget | Reads 3 providers; unknown internal widget complexity |
| 5 | Async when — loading / error states | `expensesAsync.when` wrapper |
| 6 | Desktop content | `DesktopExpenseTable` x2 (pending + processed) |
| 7 | Mobile content | `ExpenseStatusToggle` + `ManagerSwipeableExpenseCard` (swipeable, ValueNotifier) |

---

## Rebuild Steps

### Step 1 — Scaffold skeleton + provider watch
- Scaffold with AppHeader / AppFooter
- Watch `expenseSearchProvider`, `companyLocaleProvider`, `userInfoProvider`
- Render nothing inside the scroll area (empty Column)
- **Verify:** navigate to dashboard, resize, go to user management and back — no errors

### Step 2 — Header row (title only)
- Add `_buildHeaderRow` with only the `Text(l10n.pendingExpenses)` title
- No dropdown yet
- **Verify:** same navigation + resize test

### Step 3 — Employee filter dropdown
- Restore `_EmployeeFilterDropdown` inside `_buildHeaderRow`
- Constraints MUST be `const BoxConstraints(minHeight: 36, maxHeight: 36)` (NOT `BoxConstraints.tight(Size.fromHeight(...))`)
- **Verify:** click the dropdown to open it, resize window while dropdown is open

### Step 4 — SpendOverviewWidget
- Add `SpendOverviewWidget` above the header row
- **Verify:** collapsed/expanded toggle, resize

### Step 5 — Async when shell (loading + error)
- Add `expensesAsync.when(loading: ..., error: ..., data: (_) => const SizedBox())`
- No actual data content yet
- **Verify:** initial load spinner appears then disappears

### Step 6 — Desktop expense tables
- Add `_buildDesktopContent` inside the `data:` branch, gated on `context.isDesktop`
- `DesktopExpenseTable` x2 (pending + processed)
- **Verify:** desktop layout, expand/collapse tables, navigate away and back

### Step 7 — Mobile content
- Add `_buildMobileContent` for the mobile branch
- `ExpenseStatusToggle` + `ManagerSwipeableExpenseCard` + `ValueNotifier`
- **Verify:** mobile viewport, swipe cards, tab switching

---

## Cleanup (after Step 7 verified)
- [ ] Delete `lib/screens/manager_dashboard_stub_screen.dart`
- [ ] Remove stub import from `lib/router.dart`
- [ ] Restore router `/dashboard` to `ManagerDashboardScreen()`
- [ ] Update `docs/current-work.md`

---

## Current Status

- [x] Stub created and confirmed stable
- [x] Step 1 — Scaffold skeleton
- [x] Step 2 — Header row (title only)
- [x] Step 3 — Employee dropdown (root cause: `expandedInsets: EdgeInsets.zero` + missing `isCollapsed`)
- [x] Step 4 — SpendOverviewWidget
- [x] Step 5 — Async when shell
- [x] Step 6 — Desktop tables
- [x] Step 7 — Mobile content
