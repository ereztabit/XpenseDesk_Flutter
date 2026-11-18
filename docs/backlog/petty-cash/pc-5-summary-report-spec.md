# PC-5 - Sheet export: Download as PDF / Download as Excel

> Mission: FS-1016. Backend story + decisions: BackEnd/XpenseDeskServer/docs/petty-cash/pc-5-summary-report.md.
> **Implementation plan (all slices, limits, tests): BackEnd/XpenseDeskServer/docs/petty-cash/pc-5-implementation-plan.md.**
> PDF code source: the POC at `C:\Projects\QuestPdfPoc`.

Status: FILED 2026-11-16; scope agreed and POC done 2026-11-18; **plan written
2026-11-18**. Not started. **Monthly first** (S4), the approved budget page
after Monthly is done (S6). No Lovable round - both slices add two actions to
existing headers.

## What the user gets

On an **approved** sheet: **Download as PDF** and **Download as Excel** - two
files, built on the server in the company language with Israeli formats
(`18.11.2026`, `₪1,234.56`) and company-time timestamps. Not shown on any sheet
that is not Approved.

## S4 - the approved Monthly sheet page (`/manager/sheet/<id>`)

Facts (checked 2026-11-18): `SheetReviewScreen` (`lib/screens/sheet_review_screen.dart`,
511 lines) shows `SheetReviewHeaderCard` (`lib/widgets/sheet_review/sheet_review_header_card.dart`,
210 lines - already over the 200-line rule) with the status badge in its top row.
An Approved sheet renders no action block (`_canApproveSheet` false). Employees
have no page for an approved sheet - their downloads come with Monthly history
(FS-1022).

| # | Piece | Where | Notes |
|---|---|---|---|
| F1 | Header card gets an **`actions` slot** (like `BudgetHeaderCard.trailing`) | `sheet_review_header_card.dart` | Extract `_MetaItem` / `_DeclineCommentCallout` to their own files first so the card drops under 200 lines (Rule 1) |
| F2 | `SheetExportActions` widget: two `AppButton`s (`dense`, variant `normal`) - PDF (`Icons.picture_as_pdf_outlined`) and Excel (`ExcelDownloadIcon`), each with its own `isLoading` | `lib/widgets/sheet_export/sheet_export_actions.dart` | Shown only when status is Approved. Desktop: in the header's top row after the badge. Mobile (< 600): a `Wrap` row under the meta items, full-width buttons |
| F3 | `SheetExportService.download(sheetId, format)` -> `({bytes, fileName})` | `lib/services/sheet_export_service.dart` | `POST /api/expense-sheets/{id}/export {format}` |
| F4 | `ApiService.postBinaryWithStatus` returning status, headers, bytes; a 60 s timeout | `lib/services/api_service.dart` | Today's `postBinary` returns the body even on errors - errors must surface their `errorCode` |
| F5 | File name from `Content-Disposition` (server exposes it via CORS), fallback `sheet-export.pdf` / `.xlsx` | `lib/utils/sheet_export_utils.dart` | Pure function, unit-tested |
| F6 | Generalize the Blob/anchor download with a MIME parameter (`application/pdf`, xlsx) | `lib/services/excel_export_service.dart:93-110` | One helper, not a third copy (the cycle report has its own copy at `cycle_expenses_report_screen.dart:239-254`) |
| F7 | Errors -> SnackBar by `errorCode`: `SheetExportNotApproved`, `SheetExportTooLarge`, `SheetExportBusy`, `SheetExportFailed`, `ExpenseSheetNotFound`; anything else `genericErrorRetry` | `lib/utils/sheet_export_copy_utils.dart` | EN + HE per code |
| F8 | ARB keys: `sheetExportPdf`, `sheetExportExcel`, `sheetExportPreparing` (tooltip while the first build runs), the five error captions | `app_en.arb` / `app_he.arb` | No placeholders |

## S5 - platform admin

`AdminClearExportsButton` on the admin company screen next to Destroy
(`lib/screens/admin_company_screen.dart:142-156`): `AppButton(dense, normal)`,
asks via `ConfirmChoiceDialog`, calls `POST /api/admin/companies/{id}/sheet-exports/clear`,
SnackBar with the count. `AdminService.clearSheetExports`. ARB EN + HE.

## S6 (later) - the approved budget page

The same `SheetExportActions` in `BudgetHeaderCard.trailing` when the budget is
Approved (holder and managers).

## Unit tests (Flutter)

`sheet_export_utils_test.dart`: file name from `attachment; filename="..."`, from
`filename*=UTF-8''...`, missing header -> fallback per format;
`sheet_export_copy_utils_test.dart`: every error code -> its caption, unknown ->
generic.

## Manual test plan (PC-5, S4 + S5)

Scenario matrix per `.claude/skills/manual-qa/SKILL.md` section 5a, reviewed
before any lane runs. Runs are recorded under `## Manual QA` at the end of this
file.

**Lanes:** A = m@ desktop 1440x900, A2 = m@ desktop ~870, B = m@ mobile 375x812,
C = e@ desktop 1440 (absence checks), D = e@ mobile. Admin lane X = platform
admin desktop. QA company `XpenseDesk Demo Company` (dev), language switched
HE <-> EN in the company settings for T6.

**Data:** one approved Monthly sheet of QA Employee with 3+ lines (one foreign,
one with a long note), one Awaiting sheet, one Draft. Receipts are not stored
for QA-automation requests - the manual run uses real uploads through the app
so the PDF carries real receipt pages.

| # | Lane | Lang | Steps | Expected |
|---|---|---|---|---|
| T1 | A | HE | Open the approved sheet -> **Download as PDF** | Spinner on that button only; file `Monthly_<yyyy-MM>_<6>.pdf` downloads; opens: logo + company name, title, facts, numbered lines, Total; one grayscale receipt per page; footer site link + "printed" time in Israel time; dates `d.M.yyyy`, amounts `₪1,234.56` |
| T2 | A | HE | Same -> **Download as Excel** | `.xlsx` opens right-to-left; same lines; real dates `d.m.yyyy`; numeric amounts; Total |
| T3 | A | HE | Download the PDF again | Immediate; same file |
| T4 | A | HE | Print the PDF (browser print preview, A4) | Nothing clipped; one receipt per sheet of paper; small receipts not stretched, with the low-resolution note |
| T5 | A | EN | Switch UI language to EN, download PDF | Captions follow the **company** language, not the UI; formats stay Israeli |
| T6 | A | EN | Company language set to EN, admin clears exports (X), download again | English captions, left-to-right; formats still Israeli |
| T7 | A | HE | Open the Awaiting and the Draft sheets | No download actions |
| T8 | A2 | HE | ~870 wide | Buttons do not overflow the header; badge stays visible |
| T9 | B | HE | Mobile | Buttons wrap under the meta row, full width, tappable; download works |
| T10 | C, D | HE | Employee: dashboard, any reachable sheet view | No download actions anywhere (employee has no approved-sheet page yet) |
| T11 | A | HE | Disconnect the API (stop the server) -> click PDF | Localized error SnackBar, button usable again |
| T12 | X | HE | Admin company page -> **Clear stored sheet exports** -> Cancel; again -> Confirm | Cancel: nothing; Confirm: count SnackBar; next manager download rebuilds |
| T13 | A | HE | Browser back / reload on the sheet page after a download | Page intact; no repeated download |

**Visual sweep:** both widths, both languages, every new caption read in EN and HE.
