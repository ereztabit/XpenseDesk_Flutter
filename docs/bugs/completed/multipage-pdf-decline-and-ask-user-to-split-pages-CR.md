# CR: Decline multi-page PDF receipts before upload

Reviewed change: `lib/utils/pdf_utils.dart` (new), `lib/screens/new_expense_screen.dart`,
`lib/l10n/app_en.arb`, `lib/l10n/app_he.arb`, `test/utils/pdf_utils_test.dart` (new),
`test/fixtures/*.pdf` (new), `pubspec.yaml` (+ `dart_pdf_reader ^2.2.0`).

## TL;DR

No blockers. The detection is sound and measured: `dart_pdf_reader` reads the real
page tree, so it is correct for PDFs that hide their page tree in a compressed
object stream (Word / Acrobat / Ghostscript), and it costs 165 ms on a 47 MB,
170-page batch — no spinner needed. Two should-fix items: the declined-upload
message concatenates a Hebrew sentence with a parenthesised Latin digit, which
Rule 6 forbids outright; and the change adds state and layout to a 2083-line
screen instead of extracting the upload step, which Rule 1 forbids (pre-existing
condition, worth its own task rather than a risky in-place refactor here).

## 1. File-size audit

| File | Lines | Verdict |
|------|-------|---------|
| `lib/utils/pdf_utils.dart` | 28 | PASS — single pure function, util module |
| `lib/screens/new_expense_screen.dart` | 2083 | **FAIL (pre-existing)** — 10x the 200-line ceiling. This change adds ~25 lines and one state field |
| `test/utils/pdf_utils_test.dart` | 130 | PASS — test file, not a widget |

## 2. Embedded private classes

Four private classes in `new_expense_screen.dart`, all pre-existing and none
touched by this change:

- `_NewExpenseScreenState` — allowed (state pair of the public widget)
- `_CornerBracketPainter`, `_DashedBorderPainter` — `CustomPainter`s, arguably
  extractable but not this change's business
- `_DateAutoFormatInputFormatter` — `TextInputFormatter`, belongs in `lib/utils/`

No new private classes added. The change reuses the existing shared `ErrorAlert`
widget rather than inventing a local one.

## 3. Inline logic

PASS. Page counting is a pure function on bytes and lives in
`lib/utils/pdf_utils.dart`; the screen only calls it and renders the outcome. No
derived-data math was added to the widget layer.

The `null` contract is deliberate and documented: `null` means "could not
determine", never "one page", so an unparseable file goes to the server instead
of being refused on a guess. The server remains the authoritative check.

## 4. Currencies & captions audit

**Rule 3 (currencies)** — clean:

```
$ grep -RIn "'\$'\|'₪'\|'€'\|'£'" lib/utils/pdf_utils.dart lib/screens/new_expense_screen.dart
(no output)
```

**Rule 4 (captions)** — the mandatory gate, run on every changed Dart file:

```
$ grep -nE "Text\('[A-Za-z]|tooltip:\s*'[A-Za-z]|hintText:\s*'[A-Za-z]|label:\s*'[A-Za-z]|labelText:\s*'[A-Za-z]" \
    lib/utils/pdf_utils.dart lib/screens/new_expense_screen.dart test/utils/pdf_utils_test.dart
(no output)
```

Both locales confirmed present for both new keys:

| Key | `app_en.arb` | `app_he.arb` |
|-----|--------------|--------------|
| `newExpenseMultiPagePdfDeclined` | line 468 | line 468 |
| `newExpenseMultiPagePdfPagesDetected` | line 469 | line 469 |

No ARB placeholder syntax; the page number is concatenated in the widget per
CLAUDE.md.

## 5. Flutter hygiene

Clean — zero hits for `withOpacity`, `EdgeInsets.only(left:|right:)`,
`TextAlign.left|right`, `arrow_back_ios|forward_ios`, `DropdownButtonFormField`
on the changed files. No raw `http.*` (this change makes no network calls).

`AppLocalizations.of(context)!` is read after an `await` but behind a `mounted`
guard, so `use_build_context_synchronously` stays clean. `flutter analyze`
reports 9 issues — byte-for-byte the pre-existing set tracked in
`docs/bugs/flutter-analyze-info-lints-cleanup.md`, none from this change.

## 6. Responsive overflow + RTL correctness

**Overflow:** low risk. `ErrorAlert` is an existing `Row` with `Expanded(Text)`
and wraps naturally; it sits in the same `Column` as the upload zone with no
intrinsic-width siblings. Nothing added inside an `Expanded(flex:)`.

**RTL — one real finding.** The declined message is built as:

```dart
_uploadError = '${l10n.newExpenseMultiPagePdfDeclined} '
    '(${l10n.newExpenseMultiPagePdfPagesDetected} $pages)';
```

In Hebrew this produces a right-to-left sentence followed by a parenthesised
label and a Latin digit. Rule 6 says plainly: do not concatenate mixed-direction
content into one string. Digits are weak-directional and trailing parentheses at
an RTL string boundary are exactly where bidi reordering misplaces glyphs. It may
well render acceptably in Chrome — but the rule exists because this codebase has
been bitten before, and a count in parentheses is not worth the risk.

## 7. Recommended fix plan

Each step is independently shippable.

**Step 1 — DECLINED by owner (2026-08-13): the caption stays as written.** The
page count is kept in the message and `newExpenseMultiPagePdfPagesDetected`
remains in use. Recorded here so the Rule 6 note is not re-raised as a new
finding next time. Original recommendation follows.

~~should-fix: drop the parenthesised count (Rule 6).~~
Set `_uploadError` to `l10n.newExpenseMultiPagePdfDeclined` alone. The sentence
already tells the user what to do; the page number is diagnostic detail they
cannot act on. Then delete the now-unused `newExpenseMultiPagePdfPagesDetected`
key from **both** ARB files — this repo already carries one dead key
(`emailNotRegistered`), and a second is a habit forming.

If the count is wanted, the alternative is to give `ErrorAlert` an optional
`detail` parameter and render it as its own `Text` run so each string keeps its
own direction. That is a shared-widget change affecting every current caller, so
it should not ride along with a bug fix.

**Step 2 — should-fix, separate task: extract the upload step (Rule 1).**
`new_expense_screen.dart` is 2083 lines and this change grew it. The step-0 block
(upload zone + declined-upload alert + Continue button) is a coherent
`lib/widgets/expenses/expense_upload_step.dart`. Deliberately NOT bundled here:
re-cutting the layout of a 2000-line screen is a bigger risk than the bug being
fixed, and it deserves its own verification pass. File it as a `Technical` item.

**Step 3 — nit: nothing runs the new tests.**
`test/` is the first test directory in this repo, so `flutter test` is not part of
any checked-in flow. Add it to the `finish-feature` checks, otherwise the
regression protection only exists when someone remembers to run it.

## Measurements recorded (so nobody re-derives them)

| Check | Result |
|-------|--------|
| 3-page Chrome PDF | 3 pages, 24 ms |
| 1-page Chrome PDF | 1 page, 3 ms |
| PDF 1.5, page tree inside a Flate-compressed object stream | 3 pages, 20 ms — `/Type /Pages` and `/Count` absent from the raw bytes, so a byte scan reads nothing |
| 85-image scanner batch, 47 MB | 170 pages, 165 ms. Cross-checked against the raw bytes: page-tree root says `/Count 170` with 85 `/Subtype /Image` objects (each image spills to a second page), and intermediate counts 2/8/42/64 confirm a multi-level tree was walked |
| PNG bytes / truncated PDF / empty bytes | all `null` (parser throws, we swallow) |
| Release web bundle `main.dart.js` | 4,739,241 -> 4,790,458 bytes (+51 KB, +1.1%) |
| `dart_pdf_reader` license | Apache-2.0, verified publisher, pure Dart, no native deps on the web path |
