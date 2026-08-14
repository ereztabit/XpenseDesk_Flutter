# New Expense entry improvements

One feature covering three items that all land in the New Expense wizard
(`lib/screens/new_expense_screen.dart`) and its edit counterpart. They were
tracked separately; merged here because they touch the same screen and should
ship, and be regression-tested, as one pass.

Supersedes and replaces:

- `docs/backlog/expense-validation-gates-removal.md` (feature, `[Business][P2]`)
- `docs/bugs/ai-detected-amount-not-currency-formatted.md` (bug, `[LookAndFeel][P3]`)
- `docs/bugs/receipt-upload-zone-drag-and-drop-not-implemented.md` (bug, `[LookAndFeel][P3]`)

Those three files are removed; their full content is folded in below. On ship,
this doc moves to `docs/completed/` and the two bug parts are recorded here
rather than in `docs/bugs/completed/`.

---

## Part 1 - Validation gates removal (Business, P2)

### Problem / request

Expense entry (new expense + edit expense) currently requires amount, date,
merchant, and category before submit is allowed. Going forward, **price and
date are the only mandatory fields** - merchant, category, note, receipt ref
etc. all become optional.

### Scope

- `lib/screens/new_expense_screen.dart` - remove the `merchant` requirement
  from `_canAttemptSubmit`/`_canSubmit` (lines 214-221), drop the merchant
  `errorText`/required asterisk (the two merchant fields at lines ~1249 and
  ~1313), drop the category "shake + scroll to + `categoryRequired` reminder"
  behaviour and its required asterisk (`_shakeCategoryController` at line 72,
  the trigger at line 479, the two reminder blocks at ~1001-1034 and
  ~1326-1359). Amount + date remain required exactly as today.
- `lib/screens/employee_expense_detail_screen.dart` (edit expense) - same
  mandatory-field reduction for its validation gates.
- Server submit path (`ExpenseService.createExpense` / update expense request)
  - when `categoryId` is null at submit time, default it to `5` ("Other")
  instead of blocking submit or sending null.

### Open questions

- Confirm category id `5` maps to "Other" in `lib/models/expense_category.dart`
  before wiring the default.
- Confirm the backend accepts/expects a non-null categoryId on create (i.e.
  that the client-side default is the right layer, vs. the server defaulting
  it).

---

## Part 2 - AI "Detected details" amount is not currency-formatted (LookAndFeel, P3)

### Problem

After scanning a receipt with AI on the New Expense screen, the "Detected
details" (Hebrew: "פרטים שזוהו") summary card shows the detected amount as a
raw number followed by the ISO currency code, e.g. `1880.00 ILS`. Everywhere
else in the app amounts are shown with a thousands separator and the currency
symbol, so this card should show `₪1,880.00`.

Two formatting defects in one value:

1. No thousands grouping - `1880.00` instead of `1,880.00`.
2. Currency code instead of symbol - `ILS` instead of `₪` (and positioned
   after the number instead of the symbol-first convention used app-wide).

This also violates code-review rule #3: "No hardcoded currency symbols - every
amount uses `num.toCurrency(companyLocale, currencyCode)`".

### Reproduce steps

1. Log in as an employee and open the New Expense screen.
2. Upload a receipt image with an amount of 1,880.00 ILS (e.g. the demo
   "DEMO OFFICE SUPPLIES LTD" receipt) and let the AI scan complete.
3. Look at the amount field in the "Detected details" summary card.
   -- Expected: `₪1,880.00` (symbol + thousands-separated amount, formatted
      per the company locale, same as everywhere else in the app).
   -- Actual: `1880.00 ILS` (raw `toStringAsFixed(2)` plus the ISO code).

### Suggested fix

`_buildDetectedSummary` in `lib/screens/new_expense_screen.dart` (line 1166,
amount text around lines 1147-1151 of the pre-change file) builds the amount
text manually:

```dart
final amountText = result?.amount != null && result?.currencyCode != null
    ? '${result!.amount!.toStringAsFixed(2)} ${result.currencyCode}'
    : ...
```

Replace with the `CompanyCurrencyFormat` extension from
`lib/utils/format_utils.dart`, e.g.
`result!.amount!.toCurrency(companyLocale, result.currencyCode!)` - the
`companyLocale` is already passed into the method. Fallback for the code-less
branch (amount detected but no currency): plain
`toFormattedNumber(companyLocale)` keeps the grouping without inventing a
symbol.

Note: the summary card intentionally shows the *detected* currency (which may
be foreign), so the symbol must be derived from `result.currencyCode`, not
from the company base currency.

---

## Part 3 - Upload zone promises drag-and-drop that does not exist (LookAndFeel, P3)

### Problem

Step 1 of the New Expense wizard shows a dashed-border upload box captioned
"Drag or click to upload" (Hebrew: "גרור או לחץ להעלאה"). Clicking works, but
dragging a file onto the box does nothing at all - no highlight, no drop
feedback, and the file is not accepted. On the web the browser may even
navigate away from the app to open the dropped file, losing whatever the user
had typed.

The caption promises a capability that was never implemented, so users try it,
fail, and lose confidence in the wizard.

### Reproduce steps

1. Log in and open New Expense (step 1 - Upload Receipt).
2. Note the caption inside the dashed box: "Drag or click to upload".
3. Drag a JPG, PNG, or PDF from the desktop / file explorer over the dashed box.
   -- Expected: the box highlights while the file is over it, and on release the
      receipt is loaded and previewed exactly as if it had been picked by click.
   -- Actual: no highlight, nothing is accepted. The drop falls through to the
      browser, which may open the file in the tab and discard the wizard state.
4. Click the same box and pick the same file.
   -- Actual: works correctly. Only the drag path is broken.

### Suggested solution approach

Make the upload box actually accept dropped files, so the caption is truthful.
Dragging should be fully equivalent to clicking: same accepted types
(jpg / jpeg / png / pdf), same preview, same validation and error messages.
Only one file is accepted - if several are dropped, take the first and say so,
or reject the drop with a clear message.

The drop must also be visually obvious: highlight the box while a file hovers
over it, using the existing hover styling.

### Suggested fix

The upload box (`_buildUploadZone`, line 594) wraps only a `MouseRegion` +
`GestureDetector(onTap: _pickFile)`. There is no drop target anywhere in the
tree, and no drag-and-drop package in `pubspec.yaml` - so this is a missing
feature, not a regression.

1. **Extract the file-ingest logic.** `_pickFile` (line 232) currently does two
   things: opens a `web.HTMLInputElement` picker, and then loads the chosen
   file (bytes, PDF blob URL + platform view registration, image dimensions,
   state update). Split the second half into a single
   `Future<void> _loadFile(web.File file)` so both the click path and the drop
   path share it. Keep the existing `_revokePdfBlob()` call and the `mounted`
   guards.
2. **Add a real drop target.** The app runs on web and already talks to
   `package:web` / `dart:js_interop` here, so the lowest-risk option is to
   handle the DOM drag events (`dragenter` / `dragover` / `dragleave` / `drop`)
   and call `preventDefault()` on them - that is also what stops the browser
   from navigating away on a stray drop. Alternatively adopt a drag-and-drop
   package (e.g. `super_drag_and_drop`) if we want the same behaviour on native
   builds later. Needs a short investigation to pick one; do not assume the
   package route works on web without checking.
3. **Reuse the hover visuals.** `_isHovering` (line 48) already drives the
   dashed border colour and background tint. Feed the drag-over state into the
   same flag (or a sibling `_isDragOver`) so no new styling is introduced.
4. **Filter by type on drop.** The click path constrains types via
   `input.accept = '.jpg,.jpeg,.png,.pdf'`. A drop bypasses that, so validate
   the dropped file's extension / MIME type explicitly and show a localized
   error for anything else. Add the ARB keys to `app_en.arb` and `app_he.arb`
   first.
5. Do the same on the "replace file" path - the button at line 972 also calls
   `_pickFile`, and once a receipt is loaded the preview area should accept a
   dropped replacement too.

Fallback if drag-and-drop is judged not worth building: the *minimum* fix is to
change `newExpenseUploadSubtitle` in both ARB files to promise only what works
("Click to upload" / "לחץ להעלאה"). Shipping a caption that lies is the actual
defect.

---

## Cross-cutting note

`new_expense_screen.dart` is 2083 lines, far past the 200-line rule. Part 1
deletes code from it and Part 3 adds to it; the upload zone and its file-ingest
logic are the natural extraction target
(`lib/widgets/expenses/receipt_upload_zone.dart`), and the detected-summary
card of Part 2 is a second one
(`lib/widgets/expenses/ai_detected_summary_card.dart`). Extract as part of this
work rather than growing the screen further.

## Manual QA

Numbered tests in
[new-expense-entry-improvements-QA.md](new-expense-entry-improvements-QA.md) —
round 2, after the two round-1 findings below.

## Round-8 QA finding (fixed)

7. **The upload box promised a drag on a touch device.** Part 3 made the
   caption truthful on desktop but left it lying on a phone, where there is
   nothing to drag and there *is* a camera. `ReceiptUploadZone` now switches on
   `context.isMobile`: a camera glyph instead of the cloud, and
   `newExpenseUploadSubtitleMobile` ("Tap to upload or snap a photo" /
   "הקישו להעלאה או לצילום הקבלה"). Width-based, matching the rest of the app's
   responsive logic — a narrow desktop window therefore gets the mobile wording
   too, which is the accepted trade for not introducing a touch-detection
   pattern the codebase does not have.

   Open dependency: QA test 1 checks whether iOS Safari actually offers the
   camera for an extension-only `accept` list. If it does not, the fix is to add
   MIME types to `accept` in `_pickFile` — not to weaken this copy.

## Round-7 QA finding (fixed)

6. **The edit-expense screen had no validation feedback at all.** Clearing the
   amount there just greyed out "Update Expense Details" — no red border, no
   message, no shake, and the required asterisks were decoration. The New
   Expense treatment is now mirrored in
   `employee_expense_detail_screen.dart`: `_flagMissingMandatoryFields()`,
   `ShakeOnDemand` around the amount and date fields, `errorText` plumbed
   through `_buildTextField`, and a hand-built error border + message on the
   date field (it is an `InkWell`, not a `TextFormField`, so it gets none of
   that for free). The update button now stays enabled while the form is dirty
   so pressing it can point at the gap. `_approve()` in manager edit mode gets
   the same gate — it saved the form first and would have thrown on
   `_selectedDate!` with an empty date.

## Round-6 QA finding (fixed)

5. **Validation messages were clipped to one line.** In English the amount
   field sits beside the currency dropdown, so "Amount is required" rendered as
   "Amount is re..." — Flutter's `InputDecoration` defaults `errorMaxLines` to 1.
   Fixed at the theme (`errorMaxLines: 3` in `app_theme.dart`), so every form in
   the app wraps its validation text instead of ellipsing it. Hebrew never
   showed it: "נדרש סכום" fits.

## Round-4 QA finding (fixed)

4. **A partial scan hid the field the user had to fill.** When the AI read the
   merchant, date and receipt # but missed the amount, the read-only summary
   showed `—` and the only way in was the "Modify" button. `_analyze()` now
   checks `ReceiptAnalysisResult.isMissingMandatoryFields` and opens the panel
   in edit mode with `_hasAttemptedSubmit` pre-set, so the empty mandatory field
   arrives already red with its required-field error. Such a record is no longer
   marked `isAiData` — a hand-typed mandatory value means it is not a pure AI
   record. Covered by `test/models/receipt_analysis_result_test.dart`.

## Round-2 QA finding (fixed)

3. **A drop on a PDF preview opened the file in the frame.** The preview is a
   `<iframe>` running the browser's PDF viewer — its own browsing context, so
   the drag events never reach the parent document and the document-level drop
   handler could not see them. The iframe is now `pointer-events:none`, which
   sends the drop through to the drop target; the preview gained an
   "open in a new tab" button so the (single-page) PDF can still be read in
   full.

## Round-1 QA findings (fixed)

1. **A scan that reads nothing showed a summary of blanks.** The fast-track
   read-only "Detected details" card appeared with every value `—`, forcing the
   user to press "Modify" before typing anything. `ReceiptAnalysisResult` now
   exposes `hasNoDetectedFields`, and `_analyze()` routes an empty-but-successful
   scan down the same path as a failed one: the plain full form.
2. **Empty mandatory fields only greyed out "Finish".** Requested behaviour is
   the shake the category field used to do. "Finish" now stays enabled and
   `_flagMissingMandatoryFields()` opens the AI panel if the field is hidden,
   shakes Amount and/or Date via the new `ShakeOnDemand` widget, shows the
   required-field error and scrolls it into view.

## Done means

- Amount + date are the only gates on new and edit expense; category defaults
  to "Other" on submit when left blank; no shake reminder, no merchant
  asterisk.
- The detected-details amount reads `₪1,880.00` (detected currency, company
  locale) in both languages.
- Dropping a jpg/png/pdf on the upload box loads it exactly like clicking does,
  the box highlights during the drag, a stray drop never navigates the tab
  away, and a wrong file type shows a localized error.
- `flutter analyze` clean for the touched files, `flutter build web` passes,
  and a `/code-review` pass is done.
