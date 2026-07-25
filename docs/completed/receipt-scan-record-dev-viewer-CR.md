# CR — Receipt Scan Record Viewer (dev only)

Reviews the change implementing [receipt-scan-record-dev-viewer.md](receipt-scan-record-dev-viewer.md).

## TL;DR

Clean against all six rules. Both new files are small and single-purpose, the
caption gate returns zero, and all three ARB keys exist in EN **and** HE (verified
in the generated Hebrew delegate, so no silent key-name fallback). `flutter analyze`
reports 9 issues — exactly the pre-existing count in
`docs/bugs/flutter-analyze-info-lints-cleanup.md`, so this change adds none. Dev and
prod web builds both compile. One **should-fix** was found and **has been applied**
(§3): the "prefer expenseId" precedence had been encoded in the widget while the
service enforced mutual exclusivity, splitting one rule across two layers. Two nits
left open by decision — cosmetic on a dev-only tool.

## 1. File-size audit

| File | Lines | Verdict |
|------|-------|---------|
| `lib/services/json_viewer_service.dart` | 38 | ✅ new |
| `lib/widgets/expenses/dev_scan_record_button.dart` | 92 | ✅ new, well under 200 |
| `lib/config/app_config.dart` | 99 | ✅ +5 |
| `lib/services/api_service.dart` | 235 | ✅ service, grouped HTTP verbs (Rule 1 exception) |
| `lib/services/expense_service.dart` | 799 | ✅ service (Rule 1 exception) |
| `lib/screens/employee_expense_detail_screen.dart` | 1268 | ⚠️ pre-existing — this change adds 3 lines |
| `lib/screens/new_expense_screen.dart` | 2057 | ⚠️ pre-existing — this change adds 10 lines |

Both screens were already far over the 200-line target before this change. Not
introduced here and not in scope to fix; noted so it is not mistaken for new debt.

## 2. Embedded private classes

```
lib/widgets/expenses/dev_scan_record_button.dart:30:class _DevScanRecordButtonState extends ConsumerState<DevScanRecordButton>
```

Only the conventional state pair — explicitly allowed by Rule 1. No substantial
private widgets introduced.

## 3. Inline logic

The HTTP call lives in `ExpenseService.fetchScanRecord`; the blob/tab mechanics live
in `JsonViewerService`. The widget only composes and renders. No derived-data math,
no `.where`/`.fold` chains in `build()`.

**should-fix — precedence split across two layers. ✅ FIXED.** The widget computed
which route to use:

```dart
final usingExpenseId = widget.expenseId?.isNotEmpty ?? false;
... fetchScanRecord(
      expenseId: usingExpenseId ? widget.expenseId : null,
      fileUrl: usingExpenseId ? null : widget.fileUrl,
    );
```

while the service threw when both or neither were supplied. So "prefer expenseId
once the expense exists" — an API rule from the spec — lived in the widget, and the
service rejected the most natural call (`pass both, let it choose`). The next caller
that forwarded both would get a runtime `ExpenseException` for reasonable-looking
code.

**Applied:** `fetchScanRecord` now accepts both and applies the precedence itself,
throwing only when neither is supplied. The widget forwards both fields and holds no
routing logic:

```dart
final record = await ref.read(expenseServiceProvider).fetchScanRecord(
      expenseId: widget.expenseId,
      fileUrl: widget.fileUrl,
    );
```

Re-verified after the fix: `flutter analyze` still 9 (pre-existing only),
`flutter build web` ✅.

## 4. Currencies & captions audit

Rule 3 — no amounts rendered by this change. Grep clean:

```
$ grep -nE "'\$'|'₪'|'€'|'£'" lib/services/json_viewer_service.dart lib/widgets/expenses/dev_scan_record_button.dart
(no output)
```

Rule 4 — **mandatory gate, zero findings**:

```
$ grep -nE "Text\('[A-Za-z]|tooltip:\s*'[A-Za-z]|hintText:\s*'[A-Za-z]|label:\s*'[A-Za-z]|labelText:\s*'[A-Za-z]" \
    lib/services/json_viewer_service.dart lib/widgets/expenses/dev_scan_record_button.dart
(no output)
```

Both locales verified, including the generated delegate:

```
devViewScanRecord:   en=1 he=1
devNoScanRecord:     en=1 he=1
devScanRecordFailed: en=1 he=1
lib/generated/l10n/app_localizations_he.dart: 3 getters
```

Hand-checked the strings greps miss:

- Both `SnackBar`s take localized text. The failure one is
  `'${l10n.devScanRecordFailed}: $e'` — localized caption plus the raw exception.
  **nit:** `$e` is untranslated server/exception text. Acceptable for a dev-only
  debug tool where the raw error is the point, and it is concatenation per the
  no-ARB-placeholders rule.
- `'scan-record.json'` is a filename, not a caption. `'application/json'`, `'a'`,
  `'_blank'` are web API values.
- No ARB `{placeholder}` syntax used.

## 5. Flutter hygiene

```
$ grep -nE "withOpacity|EdgeInsets\.only\((left|right):|TextAlign\.(left|right)|arrow_back_ios|arrow_forward_ios|DropdownButtonFormField|http\." \
    lib/services/json_viewer_service.dart lib/widgets/expenses/dev_scan_record_button.dart
(no output)
```

- No raw `http.*` — the new GET goes through `ApiService.getWithStatus`, which
  mirrors the existing `postWithStatus` / `putWithStatus` shape.
- `EdgeInsets.only(top: 8)` is on the vertical axis, so the directional rule
  (`left`/`right` → `start`/`end`) does not apply.
- New web code uses `package:web` + `dart:js_interop`, **not** `dart:html`, so it
  does not join the four files blocking wasm builds.
- `AppButton` used rather than a raw `ElevatedButton`.

## 6. Responsive overflow risk

- `DevScanRecordButton` is `dense`, intrinsic-width, and sits as a plain child of a
  `Column` — no `Expanded(flex:)` on intrinsic content, so the Rule 6 overflow shape
  does not apply.
- `employee_expense_detail_screen` desktop: the button is added inside the existing
  `IntrinsicHeight` → `Expanded` → `Column(crossAxisAlignment: .end)`. It adds
  height to a column that in manager mode also holds a `Spacer`, which absorbs it.
  Worth an eyeball at `< 768` in manager mode.
- `new_expense_screen` desktop: `ExpenseCreateImagePanel` is now wrapped in a
  `Column(crossAxisAlignment: .start)`; the panel is `width: double.infinity` with a
  fixed height, so the wrap is layout-neutral.
- RTL: alignment comes from `CrossAxisAlignment.start`/`.end` (directional) and
  `EdgeInsets.only(top:)`. `Icons.bug_report_outlined` is not a `matchTextDirection`
  glyph, so no mirroring concern. No mixed-direction string concatenation.

**nit** — `'scan-record.json'` is a fixed filename. Opening records for several
receipts gives identically-named tabs/downloads; including the expense id or
`createdAtUtc` would make them distinguishable.

**nit** — the widget's `catch (e)` also catches `UnauthorizedException`. Harmless in
practice: `ApiService` fires the global `onUnauthorized` handler before throwing, so
session expiry still routes to login — the snackbar is just redundant noise on the
way out.

## 7. Recommended fix plan

1. ✅ **APPLIED** — moved the expenseId-over-fileUrl precedence into
   `ExpenseService.fetchScanRecord`: accepts both, prefers `expenseId`, throws only
   when neither is supplied. Widget simplified to forward both fields.
2. ⏸️ **nit, not taken** — include the expense id in the JSON filename.
3. ⏸️ **nit, not taken** — rethrow `UnauthorizedException` instead of snackbaring it.

(2) and (3) were left as-is by decision: cosmetic on a dev-only tool.

## Verification run

| Check | Result |
|-------|--------|
| `flutter analyze` (whole repo) | 9 issues — matches pre-existing count, none new |
| `flutter build web` (dev) | ✅ built |
| `flutter build web --dart-define=ENV=prod` | ✅ built |
| Endpoint round-trip against a live backend | ❌ **not verified** — needs a running server + a scanned receipt |
