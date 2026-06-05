# Manager View Switcher — Spec (Flutter)

A segmented pill toggle that lets a Manager switch between **Team Expenses** (the
default manager dashboard) and **My Expenses** (their own employee-style expense
view). This is the Flutter equivalent of the reference UI spec; it adapts the
routing and state model to this project's role-gated architecture.

---

## Purpose

A Manager is also a regular user — they submit their own expenses and get
reimbursed like any employee. The View Switcher is an in-page control that lets
the manager choose which "hat" they wear without leaving the dashboard context.

- **Team Expenses** — the manager's default landing view (`/dashboard`,
  `ManagerDashboardScreen`). Pending / returned / approved sheets for the team.
- **My Expenses** — the manager's personal view. Reuses the existing employee
  dashboard (`/user/dashboard`, `UserDashboardScreen`) scoped to the manager's
  own expenses.

---

## Key architectural decision — reuse the employee routes

The employee dashboard, New Expense, and expense detail screens already run
entirely on **user-scoped providers** (`mySheetsProvider`, `sheetDetailProvider`,
etc.). Pointed at an authenticated manager, they return the manager's own data
with no changes. The only blocker is role gating: those routes are
`employeeOnboardedOnly` (`roleId == 2`), so a manager is redirected to
`/dashboard`.

**Approach (chosen): relax the gate, no new routes.**

- Introduce a new `AuthGateMode.selfExpenseAccess` that allows managers
  (`roleId == 1`) unconditionally and onboarded employees (`roleId == 2` with a
  non-null `termsConsentDate`).
- Apply it to the three self-service routes:
  - `/user/dashboard`
  - `/employee/new-expense`
  - `/employee/expense/:id`
- The switcher toggles `/dashboard` ⇄ `/user/dashboard`. No `/manager/my-expenses`
  routes, no path parameterization, no "viewer context" object — the manager
  simply visits the employee screens as themselves.

URLs for the manager's personal view stay under `/user/...`. (The reference
spec's `/manager/my-expenses*` URLs are intentionally **not** adopted — they
would force a viewer-context indirection through every child navigation for no
functional gain.)

### Routes after the change

| Route | Screen | Gate |
|-------|--------|------|
| `/dashboard` | `ManagerDashboardScreen` | `managerOnly` (unchanged) |
| `/user/dashboard` | `UserDashboardScreen` | `selfExpenseAccess` |
| `/employee/new-expense` | `NewExpenseScreen` | `selfExpenseAccess` |
| `/employee/expense/:id` | `EmployeeExpenseDetailScreen` (self mode) | `selfExpenseAccess` |

Out of scope: the AppHeader menu's history-report link is already role-aware
(manager → `/manager/analysis/report`, employee → `/employee/history/report`),
so the manager's own cycle history is reached through existing manager routes,
not through this switcher.

---

## Placement

Rendered **inside the page body**, directly below `AppHeader` and above the main
dashboard content — **not** in the global nav menu or avatar dropdown.

- **Manager Dashboard** (`/dashboard`) — switcher at the top of the content
  `Column`, above `SpendOverviewPlaceholder`. "Team Expenses" pill active.
- **Employee Dashboard** (`/user/dashboard`) — switcher at the top of the
  content, above `PageHeaderRow`. "My Expenses" pill active. Shown **only** for a
  manager self-view; self-hides for real employees (see below).

The widget self-gates: it reads `userInfoProvider` and returns
`SizedBox.shrink()` when `roleId != 1`. That lets both dashboards drop in
`const ManagerViewSwitcher()` unconditionally — it renders for managers and
disappears for employees. (This is the Flutter analogue of the reference spec's
`viewer.isManagerSelf` conditional.)

---

## Visual Design

### Container
- Centered (`Center` / `Align` — the dashboard `Column` is
  `crossAxisAlignment.start`, so the pill must center itself).
- Rounded-full border, 2px, `AppTheme.primary` at 30% alpha → `withAlpha(77)`.
- Background `AppTheme.card`.
- Internal padding 4px (`EdgeInsets.all(4)`).
- Subtle shadow (`shadow-sm` equivalent: black ~5% alpha, blur 2, offset (0,1)).
- Bottom margin ~16px baked into the widget when visible.

### Pill Buttons (two)
- Rounded-full shape.
- Padding `EdgeInsets.symmetric(horizontal: 16, vertical: 6)` (`px-4 py-1.5`).
- Font 12px mobile / 14px desktop (`context.isMobile`), weight `w600`.
- Leading icon, size 14, gap 6px to label:
  - Team Expenses → `Icons.people_outline` (Lucide `Users`).
  - My Expenses → `Icons.receipt_long_outlined` (Lucide `Receipt`).

| State | Background | Text | Notes |
|-------|-----------|------|-------|
| Active | `AppTheme.primary` | `AppTheme.primaryForeground` | slight elevation |
| Inactive | transparent | `AppTheme.mutedForeground` | hover → `AppTheme.foreground` |

Modern-patterns hygiene: use `withAlpha`, not `withOpacity`; directional
insets only.

---

## Behavior

### Navigation
Tapping an inactive pill navigates to its route via
`Navigator.pushReplacementNamed` (toggle semantics — no back-stack buildup):
- Team Expenses → `/dashboard`
- My Expenses → `/user/dashboard`

Tapping the already-active pill is a no-op.

### Active-pill resolution
Driven by the current route name
(`ModalRoute.of(context)?.settings.name`), not local state:
- name starts with `/user/dashboard` → **My Expenses** active.
- otherwise → **Team Expenses** active.

No state management — route state drives the active pill.

---

## Internationalization

| Key | EN | HE | Used for |
|-----|----|----|----------|
| `myExpenses` | "My Expenses" | "ההוצאות שלי" | right pill (already exists) |
| `teamExpenses` | "Team Expenses" | "הוצאות הצוות" | left pill (**add**) |

Add `teamExpenses` to `app_en.arb` and `app_he.arb` before writing the widget,
then `flutter pub get` to regenerate. No ARB placeholders.

---

## Responsive

Identical on desktop and mobile — centered, intrinsic width; font scales
12 → 14px at the mobile breakpoint. Both labels are short (≤ ~14 chars); no
truncation expected.

---

## Accessibility

- Each pill is a real tappable button (`InkWell` / `Material`), pointer cursor on
  web (consistent with `AppButton`).
- Active state uses the `primary` / `primaryForeground` token pair for guaranteed
  contrast; inactive uses `mutedForeground` on `card`.
- Consider `Semantics(button: true, selected: isActive, ...)` to mirror the
  reference spec's `aria-pressed`.

---

## Implementation Notes (Flutter)

- **New widget**: `lib/widgets/manager/manager_view_switcher.dart`
  - `ManagerViewSwitcher` — `ConsumerWidget`; reads `userInfoProvider`, self-hides
    for non-managers; resolves active pill from the route name.
  - Private `_Pill` `StatefulWidget` (or `MouseRegion`-wrapped) to handle the
    inactive-hover text-color transition.
- **AuthGate**: add `AuthGateMode.selfExpenseAccess` + its `_resolveRedirect`
  case in `lib/widgets/auth_gate.dart`.
- **Router**: switch `/user/dashboard`, `/employee/new-expense`,
  `/employee/expense/:id` to `selfExpenseAccess` in `lib/router.dart`.
- **Placement edits**:
  - `lib/screens/manager_dashboard_screen.dart` — add the switcher as the first
    child of the content `Column`.
  - `lib/screens/user_dashboard_screen.dart` — add the switcher above the content
    (inside `ConstrainedContent`, above the `sheetsAsync.when(...)`) so it shows
    across loading / empty / data states.
- Dependencies: `flutter_riverpod`, `AppTheme`, `AppLocalizations`,
  `responsive_utils`. No new packages.

---

## Open questions / risks

- **Backend**: confirm a manager (`roleId == 1`) can create and own expense
  sheets via the user-scoped expense APIs. The product framing ("a manager is
  also a regular user") implies yes; verify before building so the My-Expenses
  view isn't perpetually empty / 403-ing on New Expense.
- **Onboarding**: managers don't go through employee onboarding
  (`termsConsentDate`). `selfExpenseAccess` deliberately skips that check for
  managers — confirm there's no other per-employee precondition the self-service
  screens assume.
