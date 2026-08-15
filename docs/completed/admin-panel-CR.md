# FS-1000 Admin Panel — Code Review

Reviewed 2026-08-14 against `.claude/commands/code-review.md`, on
`feature/fs-1000-admin-panel`, uncommitted working tree. Covers the admin shell
plus the companies-table sort and search added after the first login test.

## TL;DR

Three rounds. Round 1 found one Rule 1 blocker (`_HeaderRow` / `_CompanyRow`
embedded in the table file) and two nits. Round 2, after sort and search landed,
found two more Rule 1 violations of the same shape (`_SortableHeaderCell`,
`_CompaniesBody`). Round 3 found the biggest one, and the greps could never have
caught it: **the table was hand-built instead of reusing `StickyReportTable`**
(§3a). All findings are fixed — the audits below are the post-fix run. Rules
2–6 were otherwise clean throughout. A separate security review (Anthropic
`security-review`) returned no HIGH or MEDIUM findings.

## 1. File-size audit

| File | Lines | Verdict |
|------|-------|---------|
| `router.dart` | 282 | OK — route table, not a widget (Rule 1 exemption) |
| `widgets/auth_gate.dart` | 130 | OK — shrank by 28 (redirector extracted) |
| `widgets/admin/admin_header.dart` | 125 | OK |
| `widgets/admin/admin_companies_table_header.dart` | 78 | OK |
| `widgets/admin/admin_companies_sort_header_cell.dart` | 77 | OK |
| `widgets/admin/admin_companies_table.dart` | 110 | OK — was 199 |
| `widgets/admin/admin_company_table_row.dart` | 106 | OK |
| `widgets/admin/admin_companies_body.dart` | 36 | OK |
| `widgets/admin/admin_companies_search_field.dart` | 67 | OK |
| `widgets/admin/admin_company_status_badge.dart` | 65 | OK |
| `widgets/admin/admin_module_box.dart` | 104 | OK |
| `widgets/admin/admin_module_grid.dart` | 75 | OK |
| `widgets/admin/admin_auth_gate.dart` | 47 | OK |
| `widgets/route_redirector.dart` | 33 | OK |
| `screens/admin_companies_screen.dart` | 85 | OK — was 119 |
| `screens/admin_landing_screen.dart` | 62 | OK |
| `providers/admin_provider.dart` | 89 | OK |
| `models/admin_company_row.dart` | 85 | OK |
| `models/admin_companies_sort.dart` | 71 | OK |
| `models/user_info.dart` | 60 | OK |
| `services/admin_service.dart` | 69 | OK |
| `utils/admin_companies_utils.dart` | 74 | OK |
| `utils/admin_format_utils.dart` | 69 | OK |
| `utils/app_navigator.dart` | 39 | OK |
| `utils/post_login_navigator.dart` | 39 | OK |

Nothing over 200. No widget file over 130.

## 2. Embedded private classes — RESOLVED

Post-fix run over every changed file:

```
admin_companies_screen.dart:25   _AdminCompaniesScreenState  — allowed (state pair)
admin_landing_screen.dart:17     _AdminLandingScreenState    — allowed (state pair)
admin_companies_table.dart:27    _AdminCompaniesTableState   — allowed (state pair)
admin_companies_table.dart:70    _Rows                       — allowed (19-line ListView shim)
admin_companies_table.dart:89    _EmptyBody                  — allowed (21-line message helper)
admin_company_table_row.dart:25  _AdminCompanyTableRowState  — allowed (state pair)
admin_company_table_row.dart:91  _Cell                       — allowed (16-line padding helper)
admin_header.dart:27             _AdminHeaderState           — allowed (state pair)
admin_module_box.dart:25         _AdminModuleBoxState        — allowed (state pair)
admin_module_grid.dart:9         _AdminModule                — allowed (14-line data class)
route_redirector.dart:16         _RouteRedirectorState       — allowed (state pair)
```

Four extractions were made to get here:

| Was | Now |
|-----|-----|
| `_HeaderRow` in `admin_companies_table.dart` | `admin_companies_table_header.dart` |
| `_CompanyRow` in `admin_companies_table.dart` | `admin_company_table_row.dart` |
| `_SortableHeaderCell` in the header file | `admin_companies_sort_header_cell.dart` |
| `_CompaniesBody` in the screen | `admin_companies_body.dart` |

The `_flex*` constants the header and rows share moved onto
`AdminCompaniesColumns` in `admin_companies_table_header.dart`, so column widths
have one definition rather than two that can drift.

`widgets/section_table.dart` carries the same `_BodyRow` shape. It is
pre-existing and untouched by this change — flagged as a separate cleanup rather
than widening scope here.

## 3a. Reuse — the table was rebuilt instead of reused

**The most substantive finding of the review, and no grep in this file would
have surfaced it.** The first cut of `AdminCompaniesTable` hand-rolled a
`LayoutBuilder` + min-width + horizontal `SingleChildScrollView`. That is a
worse reimplementation of `widgets/sticky_report_table.dart`, which the Cycle
Expenses report already uses and which additionally provides:

| | Hand-rolled | `StickyReportTable` |
|---|---|---|
| Sticky header while rows scroll | ✗ header scrolled away with the page | ✓ |
| Visible scrollbars (both axes) | ✗ | ✓ |
| Selectable body text (`SelectableScope`) | ✗ — an admin could not copy a company name | ✓ |
| Loading / error states | re-implemented on the screen | ✓ built in |

Fixed: the table is now `Card(clipBehavior: Clip.antiAlias, child:
StickyReportTable(...))`, matching `cycle_expenses_report_screen.dart:798`.
Consequences of adopting it, all deliberate:

- **Fixed pixel column widths replace flex.** `StickyReportTable` needs a
  definite `minWidth` to decide when to scroll, and header and body must align
  under that shared scroll. `AdminCompaniesColumns` now holds widths and derives
  `minTableWidth` from their sum — same shape as the report's `_colWidths`.
- **The screen no longer page-scrolls.** The table needs a bounded height, so
  `AdminCompaniesScreen` uses `Expanded` → `ConstrainedContent` rather than the
  standard `Expanded` → `SingleChildScrollView` → `ConstrainedContent`. This is
  a documented deviation with precedent (`cycle_expenses_report_screen.dart:574`)
  and is called out in the screen's own doc comment.
- The sort-caret treatment was aligned to the report's header cell (12px
  semibold label, 12px caret, `unfold_more` when unsorted) so the two tables
  read as one component. The cell divider uses `BorderDirectional(end:)` rather
  than the report's physical `Border(right:)` — the report's is an RTL bug this
  change chose not to inherit.

`widgets/section_table.dart` — the collapsible card table — was also considered
and correctly rejected: it is a summary-section component with its own
expand/collapse chrome and no horizontal scrolling, which is not what a
data-dense report table needs.

### Reusing the shell means reusing the row shape too

Adopting the shell also adopted its `SelectableScope`, and this assertion
appeared:

```
Assertion failed: selectable_region.dart:1906
_selectable == null is not true
```

That is the framework assertion both `selectable_scope.dart` and `auth_gate.dart`
carry NOTE comments about — still live in Flutter 3.44.7.

**First attempt was wrong.** It blamed provider-driven body re-insertion and
added a `selectable` opt-out to `StickyReportTable`, turning selection off for
this table. That defeated the point of the reuse: copy-pasting the textual
columns is how these reports are used.

**Actual cause.** `AdminCompanyTableRow` was a `StatefulWidget` calling
`setState` on hover. Inside a `SelectionArea`, that re-registers the row's `Text`
selectables on every mouse move — the documented trigger, fired continuously
rather than occasionally. The Cycle Expenses report never hits it because its
rows are **stateless**, using zebra striping (`isEven ? muted.withAlpha(25) :
null`) instead of a hover tint.

Fix: the row is now stateless and striped, mirroring
`cycle_expenses_report_screen._buildDataRow`. Selection is on, and the opt-out
was reverted — `sticky_report_table.dart` is byte-identical to HEAD, so the
report screen carries no risk from this change. Per-row `ValueKey`s were dropped
too: with no row state there is nothing for a key to preserve, and a changing key
forces exactly the subtree re-insert this table must avoid.

**Lesson:** reusing a shared shell means adopting its constraints on the content
you put inside it, not just its chrome. The hover tint looked like an
independent styling choice; it was incompatible with the shell.

## 3. Inline logic

Clean. Derived state lives outside widgets:

- `AdminCompaniesQuery` (`utils/admin_companies_utils.dart`) owns all filtering
  and sorting — no `.where` / `.sort` chain appears in any `build()`.
- `AdminCompaniesSort.toggled` and `AdminCompanySortColumn.defaultAscending`
  (`models/admin_companies_sort.dart`) own the header-tap semantics.
- `AdminCompanyRow.displayStatus` collapses `isActive` + `paymentStatus` on the
  model, per CLAUDE.md's "computed properties as getters".
- `_israelUtcOffset` / `_lastSundayOfMonth` are pure functions in
  `utils/admin_format_utils.dart`.
- HTTP is confined to `AdminService`, which goes through `ApiService`.

Two sort decisions worth their comments, both tested:

- Payment-status sort keys off `displayStatus.sortRank`, not the raw wire
  string. A deactivated company reports `PendingPayment`, so sorting the raw
  value would file suspended tenants next to signups that never paid.
- Ties break on `creationDate` descending. Dart's `sort` is not stable, so
  without it equal-count rows would reshuffle between rebuilds.

## 4. Currencies & captions audit

Rule 4 is the mandatory gate — grep output pasted, not asserted. Run over all
changed Dart files:

```
$ grep -nE "Text\('[A-Za-z]|tooltip:\s*'[A-Za-z]|hintText:\s*'[A-Za-z]|label:\s*'[A-Za-z]|labelText:\s*'[A-Za-z]|'(\$|₪|€|£)'" <changed files>
(no matches)
```

All 24 ARB keys verified present in **both** `app_en.arb` and `app_he.arb`; no
`{placeholder}` syntax in any of them. The table renders no amounts, so Rule 3
has no `toCurrency` call to check.

Concatenation eyeball (greps miss these):

- `'${visible.length} ${l10n.adminCompaniesCountLabel}'` — digit + localised
  noun, same shape as the existing `'${cycle.daysRemaining} ${l10n.cycleDays}'`.
- `'${l10n.adminCompaniesSortBy} $label'` — header tooltip, both halves
  localised, so no mixed-direction run.
- `AdminCompanyStatusBadge` renders the raw server `paymentStatus` verbatim in
  its `unknown` branch. Deliberate: a diagnostic escape hatch for a contract
  change, not a caption. All four known states are localised.

## 5. Flutter hygiene

Clean:

```
$ grep -nE "withOpacity|EdgeInsets\.only\((left|right)|TextAlign\.(left|right)|arrow_(back|forward)_ios|DropdownButtonFormField|http\." <changed files>
(no matches)
```

`flutter analyze`: 9 issues, all pre-existing info-level lints in untouched files
(tracked in `docs/bugs/flutter-analyze-info-lints-cleanup.md`). Zero from this
change. `flutter test`: 33 passing, 27 of them new. `flutter build web`: green.

## 6. Responsive overflow risk

| Surface | Risk | Verdict |
|---------|------|---------|
| `AdminCompaniesTable` | 5 columns at narrow widths | Floors at 710px (sum of `AdminCompaniesColumns.all`) inside `StickyReportTable`'s horizontal scroll — cells never crush |
| Sort header cell | Long localised label + caret | Label is `Expanded` with `TextOverflow.ellipsis`, so it clips rather than pushing the caret out |
| `AdminHeader` Row | Disconnect + language switcher + logo at 320px | **Was wrong in round 3 — see §6a.** Now: icon-only disconnect below 600px, and the trailing group is the Row's only flexible child, so the logo shrinks rather than overflows |
| `AdminModuleGrid` | Fixed 320px tile below a 320px viewport | Falls back to `constraints.maxWidth` |
| Search field | — | Full-width `TextField`, no Row to overflow |

No `IntrinsicHeight` anywhere. No icon-button columns, so the
`Expanded(flex:)`-vs-`SizedBox(width:)` trap does not apply.

**RTL:** `Icons.arrow_back` (back to modules) and `Icons.arrow_forward` (module
"Open") are both navigational, so auto-mirroring is wanted. The sort carets are
`arrow_upward` / `arrow_downward` — vertical, unaffected by direction, and they
mean up/down rather than a reading direction. `AlignmentDirectional` throughout;
no `left`/`right` anywhere.

## 6a. The overflow this review said would not happen

Round 3 of this CR asserted the header "fits — ~260px of content inside 320px
minus 48px padding". It did not. On mobile it threw:

```
A RenderFlex overflowed by 26 pixels on the right.
admin_header.dart:85 Row
```

The estimate treated the logo as roughly its 24px height. It is
**135.6px wide** — a 452×80 asset scaled to height 24. Actual widths from the
render dump: disconnect 116.9 + gap 12 + language picker 81.5 + logo 135.6 =
346 in a 320 box.

Two fixes, one for the symptom and one for the class of bug:

1. Below 600px the disconnect drops to an icon-only `ActionIconButton` (32px),
   which is what the width budget actually affords.
2. The Row is now two `spaceBetween` groups with the **trailing group as its
   only flexible child**, so the logo shrinks into whatever is left instead of
   overflowing. A `Spacer` cannot be used alongside that `Flexible` — the two
   would split the free space and shrink the logo even when it fits.

Post-fix budget at a 375px viewport (content 327): 32 + 8 + 81.5 + 135.6 =
257.1, with 70px of headroom; and below ~280px the logo scales rather than
overflowing.

**Lesson, alongside the reuse pass in §7:** an intrinsically-sized asset in a
`Row` has a width the code never states. Estimating it from the dimension that
*is* stated is guessing. Either measure the asset or make the layout
structurally incapable of overflowing — this now does both.

## 6b. Verification status

RTL and desktop are **confirmed good by the user**.

Two distinct exceptions were reported on mobile, in this order:

| Exception | Status |
|---|---|
| `selectable_region.dart:1906  _selectable == null is not true` | Root cause found (hover `setState` under `SelectionArea`) and removed — the row is stateless now. **Not re-confirmed on device.** |
| `admin_header.dart:85  RenderFlex overflowed by 26 pixels` | Cause identified from the render dump, fixed in §6a. **Not re-confirmed on device.** |

Do not treat either as closed until a clean mobile load is observed. Also worth
one deliberate check: hover a row and drag-select a company name, which is the
exact interaction both fixes touch.

## 7. Outstanding

Nothing in this change. All Rule 1 findings fixed, the reuse finding in §3a
fixed, and the two round-1 nits (dead `kAdminCurrencyCode`, redundant `isNarrow`
check in the module grid) fixed.

Two pre-existing items surfaced by this review, both left alone and worth
filing separately:

1. `widgets/section_table.dart` carries the `_BodyRow` shape Rule 1 names as a
   violation.
2. `cycle_expenses_report_screen.dart`'s header cell uses a physical
   `Border(right:)`, which sits on the wrong side in Hebrew. The admin table
   uses `BorderDirectional(end:)` instead of inheriting it.

## Lesson for the next review

Rules 1–6 are all greppable, and all six passed on a table that should not have
existed. **Add a reuse pass to the CR method**: before writing a new
container-shaped widget (table, card shell, scroll region), grep
`lib/widgets/*.dart` for an existing shared one and record in the CR either
which was reused or why none fit. §3a is what that pass would have caught on
day one.

## Sign-off

Rules 1–6: **clean** after the extractions in §2 and the reuse refactor in §3a.
Greps pasted per the Rule 4 gate. Security review: no HIGH/MEDIUM findings.
