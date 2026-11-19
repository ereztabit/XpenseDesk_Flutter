# PC-5 - Sheet export: Download as PDF / Download as Excel

> Mission: FS-1016. Backend story + decisions: BackEnd/XpenseDeskServer/docs/done/pc-5-summary-report.md.
> **Implementation plan (all slices, limits, tests): BackEnd/XpenseDeskServer/docs/petty-cash/pc-5-implementation-plan.md.**
> PDF code source: the POC at `C:\Projects\QuestPdfPoc`.

Status: FILED 2026-11-16; scope agreed and POC done 2026-11-18; plan written
2026-11-18. **Built 2026-11-19 on `feature/pc5-sheet-export`** - S4, S5 and S6
together (owner: both scopes in this mission). Not committed. No Lovable round -
both slices add two actions to existing headers.

As built (differs from the plan below):
- Monthly: the actions sit after the badge from desktop width (>= 768); below
  that they get their own full-width row under the meta row. Kept out of the
  header's selection area (`SelectionContainer.disabled`).
- Budget (S6): in `BudgetHeaderCard`'s **footer** (under the spend bar, where the
  decision buttons were - empty once approved), not `trailing`.
- Tests: one file, `test/utils/sheet_export_utils_test.dart` (file name, formats,
  every error caption EN + HE).
- A rate-limit refusal (429, no body) shows the "busy" caption.

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
have no page for an approved sheet - their downloads come with PC-9 History
(D33).

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
| T1 | A | HE | Open the approved sheet -> **Download as PDF** | Spinner on that button only; file `Monthly_<yyyy-MM>_<6>.pdf` downloads; opens: logo + company name, title, facts, numbered lines, Total; one grayscale receipt per page; footer site link + "Created at" time in Israel time (D36); dates `d.M.yyyy`, amounts `₪1,234.56` |
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

### Scenario matrix (skill section 5a, written 2026-11-19 before the run)

**1. State matrix - where the downloads must NOT appear**

| Screen | Status | m@ (manager) | e@ (owner / holder) | other employee |
|---|---|---|---|---|
| Monthly `/manager/sheet/<id>` | Draft | absent | no access (manager route) | no access |
| Monthly | Awaiting | absent (approve / decline shown) | no access | no access |
| Monthly | Returned (Declined) | absent | no access | no access |
| Monthly | Approved | **shown** | no access (no employee page yet, FS-1022) | no access |
| Budget `/budgets/<id>` | Draft | absent | absent | no access |
| Budget | Awaiting | absent (review actions shown) | absent | no access |
| Budget | Returned | absent | absent | no access |
| Budget | Approved | **shown** | **shown** (holder) | no access |
| Admin company page | - | platform admin only: Clear button | - | - |

**2. Parity with the flows these pages already have:** Monthly - status badge, approve /
decline block (still only on Awaiting / Returned), payment strip, line tabs, activity, Back.
Budget - Edit, + New expense, review actions (Awaiting), settlement panel / status strip,
activity, Back. Each must look and behave as before on the same statuses.

**3. Cross-role follow-through:** after the manager approves a budget (or uses one already
approved), e@ (holder) opens it -> downloads shown and work; e@ on a Draft / Awaiting
budget -> absent. Downloaded files follow the **company** language for both roles.

**4. Visual sweep at 1440 and ~870:** header row (title, badge, two buttons, no squeeze),
budget footer buttons, spinner on the clicked button only, hover state, mobile 375 stacked.

**5. Language switch per screen:** EN -> HE on the Monthly page, the budget page and the
admin page; button captions, tooltip, error SnackBars, confirm dialog follow the UI language.

**6. Navigation:** Monthly page by URL, from the approvals list, from the dashboard; budget by
URL, from the budgets list, as the holder; in-app Back and browser back after a download -
no repeated download (T13).

**Copy rule:** the clear dialog says the files are deleted and rebuilt on the next download -
true (only stored copies go; sheets untouched).

**Added after the matrix review (2026-11-19):**

| # | Lane | Check |
|---|---|---|
| R1 | A | Statuses are 1-4 only (Draft / Awaiting / Approved / Returned); an Approved budget whose payment is Processed still shows the downloads |
| R2 | A | Approved Monthly parity: line tabs, payment strip, activity, Back work with the buttons; Approved budget: settlement panel / status strip, no Edit / + New expense |
| R3 | A, B | Budget footer buttons at 1440, ~870, 375 in EN and HE; admin Clear button + dialog at ~870 and 375 |
| R4 | A | Language switch on the budget page and the admin page: captions, tooltip, SnackBars (count + error), dialog buttons |
| R5 | A | Budget by URL, from the budgets list; Monthly from the approvals list; in-app Back + browser back |
| R6 | C, D | e@ as holder: Approved budget -> shown and both files download; Draft / Awaiting own budget -> absent; `/manager/sheet/<id>` by URL -> no access |
| R7 | A | m@ (a manager, not platform admin) opens the admin URL -> blocked |
| R8 | A | Double-click a button -> one request (the other button disabled while one runs) |
| R9 | X | Clear with nothing stored -> "Stored files deleted: 0" |
| R10 | A | Failure path (T11) for Excel too |

Out of scope: a platform admin on company pages (refused everywhere); another company's
manager (API test A6 covers the 404).

## Code review (2026-11-19)

Flutter CR (`.claude/commands/code-review.md`): 2 should-fix (actions inside the
header's selection area; actions squeezing the title at 600-768) + nits (destructive
confirm, 429 -> busy, Hebrew spelling, status logic into `budgetIsApproved`, import
order, this spec's status) - all fixed. Reuse: `AppButton`, `ExcelDownloadIcon`,
`ConfirmChoiceDialog`, `ExcelExportService.downloadBytes` (generalized, no third copy).
`flutter analyze`: no new issues. `flutter test`: 264 green.

## Owner QA changes - Payments report (2026-11-19)

1. **View a sheet from the report.** An eye (`PaymentViewSheetButton`, reuses
   `ActionIconButton`, tooltip "View sheet") next to each row's checkbox, desktop and
   mobile. It pushes the Monthly review or the budget page on top of the report, so
   Back (in-app or browser) returns to it with the filter, sort, selection and scroll
   untouched and no refetch.
2. **No "To pay / To charge" caption under amounts.** Instead an info icon by the
   **Amount** header (`PaymentsAmountInfoIcon`): "a negative amount on a budget means
   the employee returns money to the company". Shown only when budgets are on
   (`isPettyCashEnabledProvider`); tap on touch, hover on desktop.

CR (same rules): reuse - `ActionIconButton`; the info icon is not container-shaped and
no shared info-tooltip widget exists (inventory check empty). Greps (captions,
currencies, hygiene, private classes) empty; all files under 200 lines. 1 should-fix
fixed: the 14px info icon got a 26px tap target. `flutter analyze` clean, `flutter
test` 264 green.

### Owner QA round 2 (2026-11-19)

| # | Owner comment | Change |
|---|---|---|
| 1 | Process column has no header | Desktop header caption "Actions" / "פעולות" |
| 2 | Desktop export buttons: no new look | Bulk-bar Export uses Export All's download icon; the Excel glyph stays on mobile |
| 3 | "טיפול ב-6 גליונות" | Bulk label prefix key (`טיפול ב-` + number, no space) |
| 4 | Monthly downloads bigger; pill on the name | Standard `AppButton` size; the status pill follows the sheet name, downloads in the trailing top corner |
| 5 | Budget downloads in the same place and size | Trailing top corner of the budget header (under the status row below desktop width) |
| 5a | Mobile: downloads side by side, same height, centred | Below 600px: compact "PDF" / "Excel", one line, centred (Monthly and budget) |
| 6 | Approved sheets: no Pending / Approved / Declined tabs | Approved Monthly sheet and approved budget list only their approved lines, no tabs |
| 7 | Excel: company name cut, column B narrow, print landscape | Rows 1-2 span the table, aligned right (HE) / left (EN); column B 24; every Excel file prints landscape (backend `ExcelPageSetup`; client-built files via `xlsx_utils.dart`) |

CR (independent reviewer, same rules) + security review of rounds 1-2: 1 blocker fixed (the
landscape zip patch broke the server-built Payments xlsx, whose XML is `x:`-prefixed - now only
client-built files are patched, and the patch is prefix-aware, with a test); fit-to-one-page
dropped (owner asked landscape only); 1 nit fixed. Rejected: an ICU plural key for the bulk
label (house rule: no ARB placeholders). Security review: no findings. Backend unit + API
suite and `flutter test` green.

#### QA matrix - run 2 (written before the run)

Lanes: A manager 1440, A2 manager ~870, B manager 375, C employee (holder) 1440, D employee 375; EN + HE on each screen.

| # | Screen | Check | Where it must NOT appear |
|---|---|---|---|
| Q1 | Payments | Eye on every row (Pending and Processed) opens the Monthly review / the budget page; in-app Back and browser back keep filter, sort, selection, scroll; no refetch | Employee: `/manager/payments` refused |
| Q2 | Payments | No "To pay / To charge" under amounts; info icon by Amount, tooltip EN/HE | Budgets off: no icon (not testable on the shared QA company - provider gate) |
| Q3 | Payments | "Actions" / "פעולות" header over Process / Edit | Mobile has no header row for it |
| Q4 | Payments | Desktop bulk Export = download icon like Export All; mobile keeps the Excel glyph | - |
| Q5 | Payments | HE bulk label "טיפול ב-N גליונות" (desktop bar, mobile card) | - |
| Q6 | Payments | Every control: filters, Search, Reset, sort, select all, Process / Edit dialogs (Cancel only - no saves), Export All, bulk Export | - |
| Q7 | Monthly sheet (Approved) | Pill right after the name; PDF / Excel standard size in the trailing corner (1440, 870), stacked full width at 375; no tabs; only approved lines | Draft Monthly sheet: tabs kept, no downloads |
| Q8 | Budget (Approved) | Downloads in the trailing top corner (1440), under the status row (870, 375); same size as Monthly; no tabs; only approved lines - manager and holder | Draft / Awaiting / Returned budgets: no downloads, tabs as before |
| Q10 | Monthly sheet (Approved), employee owner | No tabs, approved lines only, downloads shown | Draft Monthly as employee: tabs kept, no downloads |
| Q11 | Budget (Approved) parity with Approved Monthly | No approve / decline on lines, no Edit / + New expense, payment strip, activity and totals as before | Draft / Awaiting / Returned: tabs and actions unchanged |
| Q12 | Payments visual sweep 1440 + 870 | Zoom Actions header, eye by the checkbox, bulk bar, pills one line, amount + info icon, HE alignment | Mobile: no Actions header |
| Q13 | Language switch per screen | EN -> HE on Payments, Approved Monthly, Approved budget: filters, "View sheet" and info tooltips, download captions | Any English left in HE |
| Q14 | Navigation | Approved sheet / budget by fresh URL, from the payments eye, as holder: no tabs from the first frame; in-app Back + browser back. Eye -> browser refresh -> Back: report loads, no crash | - |
| Q9 | Excel | Sheet Excel EN + HE: rows 1-2 span A:I, aligned right (HE) / left (EN); column B wide; landscape. Payments export opens (well-formed) and is landscape. Analysis export (client-built) landscape | - |

## Manual QA

### Run 1 - 2026-11-19
- Branch / commit: feature/pc5-sheet-export @ uncommitted (both repos); exports in the private `sheet-exports` container
- QA company: XpenseDesk Demo Company; manager m@xpensedesk.com; employee e@xpensedesk.com; platform admin
- Coverage: lanes A (1440), A2 (~870), B (375) as m@; C as e@ (holder); X as platform admin; EN + HE;
  Monthly sheet page, budget page (Draft / Awaiting / Returned / Approved), admin company page.
  T1-T3, T7 (Draft), T8, T9, T11 (+ R10 Excel), T12, T13, R1-R9.
- Not covered: Monthly Awaiting / Returned (no such sheet in the QA company - needs a cycle close;
  the code gates on Approved only, API test A7 covers the refusal); T4 printing on paper; T6
  (company language EN - not switched on the shared QA company; captions per language are unit-tested).

| # | Lane | Lang | Screen | Severity | Finding | Status |
|---|---|---|---|---|---|---|
| 1 | B (admin, mobile) | EN / HE | Admin company page | Major | The new Clear button squeezed the company name into a one-letter column; RenderFlex overflow | Fixed (run 1): title row is a Wrap - actions drop under the name; rechecked 1440 and 375, no overflow |

Checked clean: downloads absent on Draft / Awaiting / Returned budgets and the Draft Monthly sheet,
shown on Approved for manager and holder; both files 200 from the UI (holder too); double-click +
Excel during a PDF build = one request; API stopped -> localized SnackBar, buttons usable again
(PDF and Excel); HE RTL header / footer / mobile stack; ~870 header not squeezed; parity (payment
strip, tabs, activity, no Edit / + New expense on Approved); approvals list -> sheet -> browser back;
manager on the admin URL -> dashboard; employee on `/manager/sheet/<id>` -> dashboard; admin Cancel
sends nothing, Confirm "Stored files deleted: 3", again "0"; destructive confirm button; HE dialog fits 375.

Result: 1 finding - 0 open, 1 fixed.

### Run 2 - 2026-11-19 (owner QA rounds 1-2)
- Branch / commit: feature/pc5-sheet-export @ uncommitted (both repos)
- QA company: XpenseDesk Demo Company; manager m@xpensedesk.com; employee e@xpensedesk.com
- Coverage: matrix Q1-Q14 - lanes A (1440), A2 (~774, the pane width), B (375) as m@; C (~774) and D (375) as e@; EN + HE per screen; Payments, Approved Monthly sheet, Approved budget (#1013 with a declined line, #1016, own #1019), Returned budget #1007, expenses analysis. Excel files read from the API / captured blobs and checked as XML (merge, alignment, widths, orientation, well-formed).
- Not covered: budgets-off company (info icon hidden - provider gate, not switchable on the shared QA company); company language EN for the sheet Excel (unit-tested); an employee has no Monthly sheet page (Q10 n/a); the info tooltip on a real touch tap (emulation sends mouse events).

| # | Lane | Lang | Screen | Severity | Finding | Status |
|---|---|---|---|---|---|---|
| 1 | A | EN | Budget / Monthly downloads | Blocker | An export stored before this change was still served in the old layout (cut company name, portrait) | Fixed (run 2): `SheetExportLimits.FormatVersion` 1 -> 2, old files ignored; #1015 rebuilt and rechecked |
| 2 | B | EN / HE | Monthly sheet, budget (mobile) | Major | Downloads stacked full width; then compact but unequal height and not centred (owner, during the run) | Fixed (run 2): "PDF" / "Excel" compact, side by side, centred; Excel glyph fitted to the PDF icon's 16px box - rechecked 375 and 1440 |
| 3 | A2 | HE | Payments (desktop filters) | Minor | After a live EN -> HE switch the Payment status / Sheet type dropdowns keep "Pending" / "All" in English (pre-existing; the mobile filter dialog is Hebrew) | Open |
| 4 | A | EN | Payments | Minor | The first click right after closing a Payments dialog is sometimes ignored (seen twice: Process, eye); the second works (pre-existing dialogs) | Open |

Checked clean: eye opens Monthly review / budget page; in-app Back and browser back keep filter, sort, selection, scroll and language, no refetch; eye -> refresh -> back lands on a loaded page; employee on `/manager/payments` -> dashboard; "Actions" / "פעולות" header; no direction caption; info tooltip EN / HE; desktop bulk Export download icon, mobile Excel glyph; "טיפול ב-6 גליונות" (desktop bar, mobile card); Process dialogs (bulk + row) open and cancel, nothing saved; mobile filter dialog in HE; Approved Monthly: pill on the name, standard downloads in the trailing corner, no tabs; approved budgets: downloads top trailing (top-left in HE), no tabs, declined line hidden (#1013 shows 1 of 2), no Edit / + New expense - manager and holder; Returned budget keeps tabs and actions, no downloads; Excel: rows 1-2 merged A:I, column B 24.7, landscape (sheet, Payments server export, both analysis exports), all well-formed; console: no exceptions or overflows (only dev-server / API restart noise). Backend 744/744 and `flutter test` 269 green after the last change.

Result: 4 findings - 2 open (minor, pre-existing), 2 fixed.
