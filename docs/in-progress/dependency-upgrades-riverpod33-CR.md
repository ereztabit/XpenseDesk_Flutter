# CR — Dependency upgrades + Riverpod 3.3 build-phase fix

## TL;DR

Toolchain/dependency refresh (Flutter 3.41.2 -> 3.44.7, all pub packages current,
package_info_plus 8 -> 10) plus the resulting fix: Riverpod 3.3 forbids
`ref.invalidate` during the build phase, which crashed every screen using the
invalidate-on-entry pattern in `didChangeDependencies`. A new shared extension
`ref.invalidateOnEntry` (lib/utils/ref_utils.dart) defers the invalidation to a
post-frame callback, skipping not-yet-alive non-family providers so a first visit
still fetches exactly once. Six screens converted. Zero findings on all audits.

## 1. File-size audit

| File | Lines | Verdict |
|------|-------|---------|
| lib/utils/ref_utils.dart (new) | 30 | OK |
| lib/screens/edit_user_screen.dart | 174 | OK |
| lib/screens/manager_dashboard_screen.dart | 160 | OK |
| lib/screens/sheet_approvals_screen.dart | 171 | OK |
| lib/screens/user_dashboard_screen.dart | 190 | OK |
| lib/screens/sheet_review_screen.dart | 410 | Pre-existing overage; this diff adds 2 lines |
| lib/screens/company_config_screen.dart | 902 | Pre-existing overage; this diff adds 2 lines |

## 2. Embedded private classes

None added.

## 3. Inline logic

None added — the deferral/liveness logic lives in `lib/utils/ref_utils.dart`
(Rule 2 compliant: shared helper in utils, screens just call it).

## 4. Currencies & captions audit

Clean. Caption gate grep on all touched files returned zero matches (no
user-visible strings in this change).

## 5. Flutter hygiene

Clean. Diff-wide grep for `withOpacity`, `EdgeInsets.only(left|right)`,
`TextAlign.left|right`, `arrow_back_ios`, raw `http.*`,
`DropdownButtonFormField`: zero matches in added lines.

## 6. Responsive overflow risk

No layout changes.

## 7. Recommended fix plan

Nothing to fix. One accepted behavior nuance: family-wide invalidations
(manager dashboard / sheet approvals buckets) cannot be liveness-checked, so
their very first entry costs one redundant fetch. Documented in ref_utils.dart.
