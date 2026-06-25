# Bug: flutter analyze reports 9 pre-existing info-level lints

> **Status: new**

## Problem

`flutter analyze` exits non-zero (exit code 1) because of 9 outstanding
info-level lints across the codebase. None are errors or warnings, and none
were introduced by recent feature work, but they make the analyzer noisy and
cause `finish-feature`'s "analyze must be clean" gate to need a manual override
every release. Four of them are `dart:html` deprecations that also block
WebAssembly (wasm) builds (they show up in the `flutter build web` wasm dry-run
findings).

## Reproduce Steps

1. Run `flutter analyze` from the repo root.
   -- Expected: "No issues found!"
   -- Actual: "9 issues found." (exit code 1)

## Full list (as of v1.12)

dart:html deprecation -- `deprecated_member_use` (also blocks wasm builds):
1. lib/providers/pwa_provider.dart:2:1
2. lib/services/tranzila_popup_service.dart:4:1
3. lib/utils/pwa_utils.dart:2:1
4. lib/widgets/company_config/billing_payment_method_card.dart:4:1

use_null_aware_elements:
5. lib/screens/cycle_expenses_report_screen.dart:780:27
6. lib/screens/employee_expense_detail_screen.dart:998:9

unnecessary_underscores:
7. lib/widgets/company_config/billing_information_card.dart:297:34
8. lib/widgets/header/billing_alert_banner.dart:49:18

use_build_context_synchronously:
9. lib/widgets/company_config/billing_payment_method_card.dart:78:43

## Suggested Solution Approach

Get `flutter analyze` back to a clean, zero-issue baseline so the release gate
is meaningful again and wasm builds become possible.

## Suggested Fix

Fix in groups, smallest risk first:

- `unnecessary_underscores` (2) and `use_null_aware_elements` (2) -- trivial,
  mechanical edits the analyzer can auto-fix (`dart fix --apply`). No behavior
  change.
- `dart:html` deprecations (4) -- migrate `import 'dart:html'` usages to
  `package:web` + `dart:js_interop` (the project already depends on `web:
  ^1.1.1` and uses it in new_expense_screen.dart). This is the largest piece
  and the one that unlocks wasm; do it per file (pwa_provider, pwa_utils,
  tranzila_popup_service, billing_payment_method_card) and re-test the PWA
  install + Tranzila popup flows.
- `use_build_context_synchronously` at billing_payment_method_card.dart:78 --
  the only one with possible real-bug significance: a `BuildContext` is used
  after an `await`. Inspect whether a `mounted` guard is missing before deciding
  it is purely cosmetic.

Recommend running `dart fix --apply` for the mechanical four first, then
handling the dart:html migration and the build-context guard as deliberate
changes with a quick manual test of the affected flows.
