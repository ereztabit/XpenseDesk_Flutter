# CR — New Expense entry improvements

Reviewed against `.claude/commands/code-review.md` rules 1-6. Re-run after the
seven QA findings, over the final change set.
Implementation doc: `new-expense-entry-improvements.md`.
QA: `new-expense-entry-improvements-QA.md` — all rounds passed, desktop and
mobile.

## TL;DR

No blockers. Every grep gate is clean, `flutter analyze` reports only the 9
pre-existing info lints (tracked in
`docs/bugs/flutter-analyze-info-lints-cleanup.md`), `flutter test` is 15/15
(6 pre-existing + 9 new model tests) and `flutter build web` passes. The one
carried-over debt is the two screen files, both far over the 200-line rule
before this work started and still over it after — `new_expense_screen.dart`
went 2083 -> 1981 despite gaining drag-and-drop and the shake behaviour, because
three widgets came out of it.

## 1. File-size audit

| File | Lines | Verdict |
|------|-------|---------|
| `lib/screens/new_expense_screen.dart` | 1981 | Over 200 — pre-existing; net -102 this pass. See S1 |
| `lib/screens/employee_expense_detail_screen.dart` | 1345 | Over 200 — pre-existing; +77 for the validation UI it never had. See S1 |
| `lib/widgets/web_file_drop_region.dart` | 190 | Pass |
| `lib/widgets/expenses/receipt_upload_zone.dart` | 158 | Pass |
| `lib/widgets/expenses/ai_detected_summary_card.dart` | 111 | Pass |
| `lib/widgets/shake_on_demand.dart` | 60 | Pass |
| `lib/models/receipt_analysis_result.dart` | 56 | Pass |
| `lib/theme/app_theme.dart` | one line added | Pass |

## 2. Embedded private classes

Only state pairs and permitted micro-helpers remain in the touched files:

```
_NewExpenseScreenState, _EmployeeExpenseDetailScreenState,
_WebFileDropGuardState, _WebFileDropRegionState, _ReceiptUploadZoneState,
_ShakeOnDemandState                          state pairs — allowed
_DocumentDragListener (26 lines)             DOM plumbing for the two widgets above
_Cell (21), _SummaryTile                     styling micro-helpers — rule-1 exception
_CornerBracketPainter, _DateAutoFormatInputFormatter   pre-existing, untouched
```

`_DashedBorderPainter` moved out of the screen into `receipt_upload_zone.dart`
beside its only caller, as public `DashedBorderPainter`.

## 3. Inline logic

- Both scan-routing rules are on the model, not the screen:
  `ReceiptAnalysisResult.hasNoDetectedFields` and `.isMissingMandatoryFields`,
  covered by `test/models/receipt_analysis_result_test.dart` (9 tests including
  the zero-amount and unparsable-date edges).
- Amount formatting goes through `format_utils` (`toCurrency` /
  `toFormattedNumber`), not string building in the widget.
- File ingest is one `_loadFile(web.File)` shared by the click and drop paths.
- Drag hit-testing lives in `WebFileDropRegion`; the shake animation lives in
  `ShakeOnDemand`. Neither is screen code any more.
- Still on the screen and untouched by this work: `_parseDateInput`,
  `_isoToDisplayDate`, `_dateFormatHint`, `_formatAmount` — pure date/amount
  helpers that belong in `lib/utils/`. See N2.

## 4. Currencies & captions audit

Run over all eight changed/added Dart files:

```
$ grep -nE "Text\('[A-Za-z]|tooltip:\s*'[A-Za-z]|hintText:\s*'[A-Za-z]|label:\s*'[A-Za-z]|labelText:\s*'[A-Za-z]" <files>
(no matches)
$ grep -nE "'\$'|'₪'|'€'|'£'" <files>
(no matches)
$ grep -nE "\{[a-zA-Z]+\}" lib/l10n/app_en.arb lib/l10n/app_he.arb      # ARB placeholders
(no matches)
$ grep -c '":' lib/l10n/app_en.arb lib/l10n/app_he.arb                   # key parity
app_en.arb:734   app_he.arb:734
```

Keys added: `newExpenseUnsupportedFileType`, `newExpenseSingleFileOnly`,
`newExpenseUploadSubtitleMobile` — all three in both locales. Keys removed:
`merchantRequired`, `categoryRequired` — gone from both, no remaining callers.
`'—'` in the summary card is the em-dash placeholder, allowed by rule 4.

## 5. Flutter hygiene

```
$ grep -nE "withOpacity|EdgeInsets\.only\((left|right)|TextAlign\.(left|right)|arrow_(back|forward)_ios|DropdownButtonFormField|http\." <files>
(no matches)
```

Alpha values throughout (`withAlpha(102)`, `withAlpha(128)`),
`EdgeInsetsDirectional` for the new date error message, no raw `http.*`.

## 6. Responsive overflow risk

- `ReceiptUploadZone` is a centered `Column`, no `Row` — no new overflow
  surface. Mobile switches icon and caption on `context.isMobile`; the caption
  is `TextAlign.center` so the longer mobile string wraps cleanly.
- The preview drop highlight is a `foregroundDecoration` — paints over, adds no
  layout box.
- `errorMaxLines: 3` on the global `InputDecorationTheme` makes validation text
  wrap instead of ellipsing; this is what fixed "Amount is re...". It affects
  every form in the app — checked on mobile during QA.
- `ShakeOnDemand` uses `Transform.translate`, which does not affect layout, so
  it cannot introduce an overflow stripe.
- Verified at narrow (<600) and tablet (<768) widths and on a phone.

## 7. Findings

**S1 (should-fix, carried over)** — both screen files are far over 200 lines.
`new_expense_screen.dart` shrank despite gaining features; the remaining
extractions are the step-2 forms, the scanning overlay and the preview block.
`employee_expense_detail_screen.dart` has never been decomposed. Both are
bigger than this feature and should be their own task.

**N1 (nit)** — `_optionalLabel` and `_requiredLabel` on the New Expense screen
differ only by the asterisk span; they could be one
`_fieldLabel(String, {bool required})`.

**N2 (nit, pre-existing)** — the date parse/format helpers on the screen state
belong in a `lib/utils/expense_date_utils.dart`.

## 8. Recommended fix plan

1. Ship as-is. Every rule is satisfied for the changed surface and QA is green
   on desktop and mobile.
2. Optional, 2-line: fold N1 into one label helper.
3. Separate task, not this feature: S1 + N2 — decomposing the two screens.
