# CR -- Destroy company from the admin panel (FS-1005)

Spec: [destroy-company-spec.md](destroy-company-spec.md)

## TL;DR

Clean -- no blockers, no should-fix. Two new admin widgets (the destroy dialog
and its button), one title-row change on `AdminCompanyScreen`, one service
method (`AdminService.destroyCompany`), one pure util
(`AdminDestroyConfirmation.matches`, unit-tested), 11 ARB keys in EN and HE.

## 0. Reuse audit

Inventory check printed nothing:

```
for f in lib/widgets/*.dart; do grep -q "$(basename $f)" CLAUDE.md || echo "NOT IN INVENTORY: $(basename $f)"; done
(no output)
```

| New widget | Verdict |
|------------|---------|
| `AdminDestroyCompanyDialog` | New. Read and rejected: `LastActionConfirmDialog` (title + body + confirm only, no input field, per-expense wording) and `admin_impersonation_link_dialog.dart` (a link-open/copy fallback, no input). Neither has a typed-confirmation field, which is the whole point here. Reuses `AppButton` (ghost + destructive) and `ErrorAlert` for the failure line. |
| `AdminDestroyCompanyButton` | Thin wrapper around `AppButton` (destructive). Owns the dialog -> refresh -> snackbar -> back-to-list sequence so the screen does not. |

## 1. File-size audit

| File | Lines | Verdict |
|------|-------|---------|
| `lib/screens/admin_company_screen.dart` | 185 | OK |
| `lib/widgets/admin/admin_destroy_company_dialog.dart` | 184 | OK |
| `lib/widgets/admin/admin_destroy_company_button.dart` | 54 | OK |
| `lib/services/admin_service.dart` | service | OK |
| `lib/utils/admin_companies_utils.dart` | util | OK |

## 2. Embedded private classes

Only `_AdminDestroyCompanyDialogState`, the state pair of the public widget.

## 3. Inline logic

The typed-name rule is a pure function in `lib/utils/admin_companies_utils.dart`
(`AdminDestroyConfirmation.matches`), mirroring the server (trimmed,
case-sensitive). The errorCode -> message switch in the dialog is a small label
dispatcher, not derived-data math.

## 4. Currencies & captions audit

Caption grep on changed files: empty. All 11 new keys present in `app_en.arb`
and `app_he.arb`; no placeholders (the company name is its own `Text`).

## 5. Flutter hygiene

Grep for `withOpacity` / `EdgeInsets.only(left|right)` / `TextAlign.left|right` /
`arrow_back_ios` / raw `http.` / `DropdownButtonFormField`: empty. The warning
box uses `withAlpha(25)`.

## 6. Responsive overflow risk

Title row: `Expanded` company name + intrinsic-width `AppButton`, so the name
shrinks/wraps first; no fixed widths. Dialog content is a 440px `SizedBox` inside
`AlertDialog`, which already constrains to the viewport. Check on a phone width in
manual QA with a long Hebrew company name.

## 7. Recommended fix plan

Nothing to fix.
