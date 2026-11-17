# Sheet-type navigation bar - spec (FS-1012 nav slice)

> Mission: FS-1012 (PC-1). Flutter only - no backend change.
> Design source: Lovable app mock "Expense Desk" (`0c5b063f-74a7-4490-b75e-746f4a712bde`),
> hand-off spec `public/sheet-type-nav-spec.md` in that project (approved by the
> product owner 2026-11-17). This document is the Flutter translation of it plus
> what the production app needs on top (real data, coming-soon state, dev preview).
> Business rules for Budgets: BackEnd/XpenseDeskServer/docs/petty-cash/00-plan.md.

Status: SHIPPED v1.45 (2026-11-17, release 3f60e44). Budgets and Travel pages are still placeholders - they are designed and built in PC-1 (FS-1012) and its successors.

## 1. What it is

One navigation bar, organised by **sheet type** (module), that sits directly under
the app header on every width. It replaces the manager's Team / My expenses
switcher (`ManagerViewSwitcher`, deleted).

- **Level 1** = the types: Monthly, Budgets, Travel.
- **Level 2** = the pages of one type, plus a Back control.

Vocabulary: the module internally called Petty Cash (`pettyCash`, `PettyCash`) is
called **Budgets / תקציבים** everywhere on screen. Internal keys, API names and
docs file names do not change.

## 2. The tree

| Type | Page | Who | Route | Badge |
|---|---|---|---|---|
| Monthly | Team expenses | managers | `/dashboard` | sheets awaiting review (`approvalsQueueProvider(null).totalCount`) |
| Monthly | My expenses | everyone | `/user/dashboard` | my returned sheets (`mySheetsProvider`, status Declined = 4) |
| Budgets | All budgets | managers | `/budgets` | budgets below zero (red) |
| Budgets | one line per budget assigned to me | holder | `/budgets/<id>` | none; shows the balance |
| Travel | - | - | - | "Coming soon", not clickable |

Level-1 badge of a type = the badge of its first page (Monthly: Team for a
manager, My returned for an employee; Budgets: below-zero count, red).

### Coming soon (production today)

Budgets and Travel are not built yet. When a company has the module (present in
`companyModulesProvider` = admin flag on, and `isEnabled` = turned on by the
company), its level-1 item renders **disabled with a "Coming soon" tag**, like
Travel in the mock. Employees never see Budgets until they hold a budget, so in
production an employee sees Budgets nowhere.

### Dev preview (ENV=dev only, never in prod)

A floating "Dev" button (bottom inline-end, only when `AppConfig.isDev`) opens a
sheet with:

- **Budgets preview** - treat Budgets as built: managers get All budgets, and the
  mock budgets below become my budgets. Off = production behaviour.
- **Budgets assigned to me** - 0..5 from the mock seed.
- **Module overrides** - Monthly / Budgets / Travel: follow server, force on, force
  off. Lets us see one-type, two-type and three-type bars without touching the DB.
  (Monthly off is a simulation only - the product keeps Monthly locked on.)

Mock seed (currency = company currency, amounts as given):

| id | name | balance |
|---|---|---|
| b1 | Office supplies and hospitality - Tel Aviv headquarters | 420 |
| b2 | Events | -80 |
| b3 | Field team | 1,250 |
| b4 | Warehouse - Haifa | 310 |
| b5 | Client visits | -45 |

Default: preview off; when turned on, 4 assigned. All-budgets badge in preview =
number of seed budgets below zero.

`/budgets` and `/budgets/<id>` render placeholder pages ("designed in a later
round") and are reachable only with the preview on; otherwise they redirect to the
user's home dashboard.

## 3. Who sees the bar

- Shown on: Manager dashboard (Team expenses), User dashboard (My expenses), the
  two Budgets placeholder pages. Not on profile, users, settings, reports, forms,
  login, onboarding, admin.
- Build the visible types for the user (rules above). Then:
  - **no type** -> no bar;
  - **one type with one page** -> no bar (an employee with Monthly only sees
    exactly what they see today);
  - **one type with 2+ pages** -> skip level 1, show its level 2 **without Back**
    (a manager in a company with no extra modules sees Team / My expenses
    centred - today's switcher, restyled);
  - **2+ types** -> full two-level bar.
- A type whose pages are all "coming soon" counts as a visible type (it shows at
  level 1) but has no level 2.

## 4. Behaviour

- On load the bar opens at level 2 of the current page's type with that page
  active. Tapping a type at level 1 opens its level 2 **and** navigates to its
  first page. Back returns to level 1 without navigating (local state; any
  navigation resets it).
- Navigation uses `pushReplacementNamed` through the navigation guard (same as
  the old switcher). Tapping the active page is a no-op.
- The active page is scrolled into view inside its row (horizontal only) when the
  bar opens or the page changes.
- When the level-2 row overflows it scrolls sideways (no scrollbar) with an edge
  fade on the side that has more content.
- Motion: level change = fade + short slide from the inline-end; the active
  indicator slides between items (300 ms ease-out). No motion when
  `MediaQuery.disableAnimations` is set.

## 5. Look

- Band: card (white) background, full width, bottom border `AppTheme.border`.
  Content constrained like the header row: max width `AppTheme.containerMaxWidth`,
  horizontal padding 24, so its edges line up with the header's logo / avatar.
- Height: desktop 60; mobile (< 768) 76 on both levels (items 64) so the bar never
  jumps between levels.
- Track: `AppTheme.muted`, fully rounded, 4 padding. Items are pills on it.
- Active item: white card pill, soft shadow, 1px ring in the type accent at ~25%,
  3px accent dash at its bottom; label foreground w600, icon in the accent.
  Inactive: label `mutedForeground`, hover -> foreground on a faint tint.
- Accents: Monthly `primary`, Budgets `success`, Travel `amber`.
- Icons: Monthly `calendar_month_outlined`, Budgets `account_balance_wallet_outlined`,
  Travel `flight_outlined`; Team expenses `people_outline`, My expenses
  `receipt_long_outlined`, All budgets `account_balance_wallet_outlined`, each
  budget = 10px dot (success, destructive below zero).
- Badges: count pill (primary; destructive when alert), number only, hidden at 0.

### Desktop (>= 768)

- Level 1: track centred, items sized to their label: icon + full name + badge.
  Coming soon: muted, icon + name + small "Coming soon" chip.
- Level 2: three zones - [Back] [centred group] [spacer the width of Back]. The
  group is one track: caption (type icon in accent + type name, muted, not
  clickable) + thin divider + page pills. Only the group shrinks and scrolls; the
  caption stays pinned at its start; Back never disappears.
- Back: neutral outlined round button, arrow + "Back" (arrow flips in RTL). Never
  primary fill.
- Budget pill: dot + name (max 180, one line, ellipsis, full name in tooltip) with
  the balance on a second line (11px, muted; destructive below zero).

### Mobile (< 768)

- Level 1: items share the width equally; each is a vertical stack - icon (badge
  on its top-end corner) over a **short** label (12px, up to 2 lines, centred, no
  ellipsis). Coming soon: tiny tag under the label.
- Level 2: round icon-only Back (44) + the row. Each page is a vertical stack -
  icon / dot over the full label (12px, up to 2 lines); budgets add the balance
  line (10px) and clamp the name to 2 lines within 120. Up to 3 pages share the
  width; 4+ get min width 88 and the row scrolls.
- No caption on mobile.

## 6. Captions (en / he)

| Key | English | Hebrew |
|---|---|---|
| `modulesMonthly` (existing) | Monthly expenses | הוצאות חודשיות |
| `modulesPettyCash` (renamed) | Budgets | תקציבים |
| `modulesTravel` (existing) | Travel abroad | נסיעות לחו"ל |
| `sheetNavMonthlyShort` | Monthly | חודשי |
| `sheetNavBudgetsShort` | Budgets | תקציבים |
| `sheetNavTravelShort` | Travel | נסיעות |
| `teamExpenses` (existing) | Team expenses | (existing) |
| `myExpenses` (existing) | My expenses | (existing) |
| `sheetNavAllBudgets` | All budgets | כל התקציבים |
| `sheetNavBack` | Back | חזרה |
| `sheetNavComingSoon` | Coming soon | בקרוב |
| `sheetNavWaiting` (semantics, prefix) | waiting | ממתינים |
| `sheetNavLabel` (semantics) | Sheet types | סוגי גיליונות |
| `sheetNavAllBudgetsPlaceholder` | All budgets - coming soon | כל התקציבים - בקרוב |
| `sheetNavBudgetPlaceholder` | Budget page - coming soon | דף התקציב - בקרוב |
| `devSheetNav*` (dev panel only) | localised like the rest | |

Rename (on-screen only): every existing "Petty Cash" / "קופה קטנה" string becomes
"Budgets" / "תקציבים" (module settings, platform-admin switch, negative-balance
hint).

## 7. Problems already solved in design - do not repeat

1. A 240px desktop sidebar buried the simple "add expense" flow -> one top bar on all widths.
2. Navigation inside the mobile hamburger menu is never found -> a visible bar.
3. Bar order: header -> billing banner -> bar -> page. (In Flutter the header
   column does not scroll, so the bar is fixed for free.)
4. A type tap must also navigate to its first page.
5. Active item off-screen in a scrolling row -> scroll it into view + edge fades.
6. Back must look like Back: neutral outlined, labelled on desktop.
7. Keep the white band and its border.
8. Align the bar's content with the header's content edges.
9. Level-2 group must be centred on the screen, not in the space left by Back;
   and Back must never be squeezed out when the group overflows.
10. Budget balance goes under the name, not beside it.
11. Mobile labels truncated ("Mo...", "Team ex...") -> vertical stacks, short type
    names on level 1, badge on the icon corner, same height on both levels.
12. Long free-text budget names -> capped (desktop ellipsis + tooltip, mobile 2 lines).
13. One type -> no level 1, no Back; one page -> no bar.

## 8. Code layout

- `lib/models/sheet_nav.dart` - `SheetNavType`, `SheetNavPage`, `SheetNavSection`.
- `lib/utils/sheet_nav_utils.dart` - pure tree builder + visibility rules + route
  matching (unit-tested).
- `lib/providers/sheet_nav_provider.dart` - wires role, modules, counts, dev preview.
- `lib/providers/sheet_nav_dev_provider.dart` + `lib/models/sheet_nav_dev_state.dart`
  - dev preview state and seed.
- `lib/widgets/sheet_nav/` - `SheetTypeBar` (placed by screens under `AppHeader`)
  and its parts; `SheetNavDevButton`.
- `lib/screens/budgets_placeholder_screen.dart` - both placeholder pages.

## 9. Verification (before hand-over)

Run locally (ENV=dev) and check in the browser pane at **360, 375, 414, 768, 1024,
1280, 1440, 1920** wide, in **English and Hebrew**:

| # | Scenario | Expect |
|---|---|---|
| V1 | Manager, no extra modules | Level 2 only, Team / My centred, no Back; badges |
| V2 | Employee, Monthly only | No bar; dashboard as today |
| V3 | Manager, Budgets + Travel on, preview off | Level 1 with Budgets and Travel "Coming soon" |
| V4 | Manager, preview on, 4 budgets | Budgets level 2: All budgets + 4, scrolls on mobile, long name capped, negatives red |
| V5 | Employee, preview on, budgets assigned | Monthly + Budgets; no All budgets |
| V6 | Back / type tap / page tap | Levels and navigation per section 4 |
| V7 | Billing banner shown | header -> banner -> bar |
| V8 | Prod build | No Dev button; Budgets never navigable |

## Manual QA

### Run 1 - 2026-11-17
- Branch / commit: feature/sheet-type-nav @ uncommitted
- QA company: XpenseDesk Demo Company (dev); manager m@xpensedesk.com; employee e@xpensedesk.com
- Coverage: lanes A-D x EN (+ HE on lanes A-B) x Manager dashboard, User dashboard, All budgets, budget page; widths 360, 375, 768, 1024, 1440, 1920; scenarios V1-V6 from section 9
- Not covered: V7 (no billing banner on the QA company; order is structural - the bar sits after `AppHeader`, whose column holds the banner). V8 checked by `flutter build web --release --dart-define=ENV=prod` compiling; the Dev button is gated by the compile-time `AppConfig.isDev`, not opened in a prod browser.

| # | Lane | Lang | Screen | Severity | Finding | Status |
|---|---|---|---|---|---|---|
| 1 | A (manager, desktop) | EN | Manager dashboard | Minor | Count badge stretched to the pill's full height | Fixed (run 1) |
| 2 | B (manager, mobile) | EN/HE | All budgets | Major | Two-line budget name pushed its balance out of the 64px item | Fixed (run 1) |
| 3 | B (manager, mobile) | EN | Dev panel | Minor | Budgets-assigned picker overflowed at 375px; selected segment invisible (dev only) | Fixed (run 1) |
| 4 | A/B | HE | Budgets level 2 | Minor | English budget name on the Hebrew screen put its ellipsis at the start | Fixed (run 1) |
| 5 | B (manager, mobile) | EN | All screens | Minor | Existing `AppHeader` row overflows 0.2px at 360px (not this feature; same row as docs/bugs/app-header-overflows-on-mobile-in-support-session.md) | Open - existing bug |

Result: 5 findings - 1 open (existing), 4 fixed.
