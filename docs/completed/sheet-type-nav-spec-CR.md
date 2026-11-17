# CR - Sheet-type navigation bar (FS-1012 nav slice)

Branch `feature/sheet-type-nav`, uncommitted. Reviewed 2026-11-17 against
`.claude/commands/code-review.md`.

## TL;DR

Clean. One new widget family (`lib/widgets/sheet_nav/`), a pure tree builder in
`lib/utils/sheet_nav_utils.dart` (13 unit tests), a provider, a dev-only preview,
two placeholder routes, the "Petty Cash" -> "Budgets" rename in the ARBs, and
`ManagerViewSwitcher` deleted. During the build: one file over 200 lines was split
(item icon, coming-soon tag, balance moved out), and four visual defects found in
the browser were fixed (stretched badge, clipped mobile balance, dev panel
overflow, bidi ellipsis on English budget names in Hebrew).

## 0. Reuse audit

Inventory check (`for f in lib/widgets/*.dart ...`): printed nothing.

| New widget | Verdict |
|---|---|
| `SheetTypeBar` (band + level switcher) | Replaces `ManagerViewSwitcher` (read; deleted - a two-pill fixed toggle, no levels, no data). `ModuleTabBar` read and rejected: a labels-only pill row (`List<String>` + active index, active pill tinted primary) for guarded in-page tabs; no icons, badges, balances, coming-soon state, sliding marker, stacked mobile layout or two levels. |
| `SheetNavTrack` (sliding marker) | No existing widget animates a marker under arbitrary children. `ModuleTabBar` rejected as above. |
| `SheetNavScrollRow` (h-scroll + fades) | `StickyReportTable` read and rejected: a data table shell (sticky header, visible scrollbars, SelectionArea); this is a single scrollable pill row with no scrollbar and edge fades. `RefreshableScrollView` is vertical pull-to-refresh. |
| `SheetNavItem`, `SheetNavBackButton` | `AppButton` read and rejected: fixed 12px radius, solid variants; the bar needs transparent pills with a stacked mobile layout and a 999 radius, and Back must be a neutral outlined circle (spec 5). |
| `SheetNavCountPill` | No shared count badge in `lib/widgets/`; `AiBadge` is the AI initialism only. |
| `SheetNavPlaceholderCard` | `ErrorAlert` is an error banner. Placeholder until PC-1 designs the pages. |
| `BudgetsPlaceholderScreen` | Follows the mandatory scaffold; uses `RouteRedirector`, `ConstrainedContent`, `AppHeader`, `AppFooter`. |

## 1. File-size audit

All new widget files under 200 lines (largest: `sheet_nav_item.dart` 178,
`sheet_nav_level_two.dart` 146, `sheet_nav_dev_sheet.dart` 142). Screen 94 lines.

## 2. Embedded private classes

`_Marker` (track, ~30 lines, styling) and `_OverrideRow` (dev panel, ~40 lines,
dev-only) - within the micro-helper exception. Everything else is a state pair.

## 3. Inline logic

Tree rules, route lookup, below-zero count and override resolution live in
`sheet_nav_utils.dart`; icons/captions/accents in `sheet_nav_display_utils.dart`.
The provider only wires sources. Widgets hold layout state only (hover, marker
rect, fades, Back toggle).

## 4. Currencies & captions audit

- Rule 3 grep: empty. Balances use `toCurrency(companyLocale, currencyCode)`.
- Rule 4 grep: empty. All new keys exist in `app_en.arb` and `app_he.arb`; no
  placeholders (`'$count ${l10n.sheetNavWaiting}'` is concatenated in the widget).

## 5. Flutter hygiene

Rule 5 grep: empty. Directional insets, `PositionedDirectional`, `Icons.arrow_back`
(auto-mirrors).

## 6. Responsive overflow risk

Checked in the browser at 360, 375, 768, 1024, 1440, 1920 (EN and HE): no
overflow from the bar. The only overflow seen is the existing `AppHeader` row at
360px (already filed: docs/bugs/app-header-overflows-on-mobile-in-support-session.md
covers the same row).

## 7. Fix plan

Nothing open.
