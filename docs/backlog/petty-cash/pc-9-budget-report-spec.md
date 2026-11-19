# PC-9 - Payments & History (manager) / History (employee)

> Mission: FS-1021 (backend: BackEnd/XpenseDeskServer/docs/petty-cash/pc-9-budget-report.md). Plan: BackEnd/XpenseDeskServer/docs/petty-cash/00-plan.md

Status: FILED 2026-11-18, **reshaped 2026-11-19** (owner). Extends the existing
Payments report (`lib/screens/payments_report_screen.dart`) instead of a new
page; **absorbs FS-1022** (Monthly history). No Lovable round - it extends an
existing screen. Last slice of Petty Cash phase 1.

## Manager - "Payments & History"

- Rename the screen and its nav item: "Payments & History" / "תשלומים והיסטוריה".
- Lists every approved sheet, including ones with no payment ("No payment"
  status badge, no checkbox, no action) - backend half.
- Opens on payment status **"All"** for everyone (owner 2026-11-19); the status
  filter gains "No payment" / "ללא תשלום". The dashboard Awaiting Payment card
  still opens it on Pending.
- **Actions column fix (desktop):** Settle / Edit / view are not aligned today.
  Replace them with one vertical ⋮ menu per row (View, Settle or Edit) in a
  fixed-width column; the eye icon leaves the employee cell.
- **Mobile:** layout stays; Settle and Edit buttons get the same width and
  height.

## Employee - "History"

- New nav item "History" / "היסטוריה" (desktop header + mobile menu), same
  screen in an employee mode.
- Only their own sheets (server-scoped). Columns: sheet (type, name / cycle),
  amount (signed for budgets), payment status, approval date, payment date.
- Filters: sheet type, payment status, approval date, cycle. No employee filter.
- Can: filter, open the sheet, export the list, download PDF / Excel (PC-5).
  Cannot: select, Settle, Edit.
- Opening a sheet = `sheet_review_screen.dart` in a **read-only employee mode**
  for both types (owner 2026-11-19): same layout and PDF / Excel buttons, no
  approve / decline / line review; works with any module off.
- The employee "Digital archive" entry (`expenses-detail-report` ->
  `/employee/history/report`) is **removed for employees**; the route
  redirects to History. Managers keep the Digital archive.
- Works with the Monthly or Budgets module off.

## Built (2026-11-19, uncommitted on `feature/pc5-sheet-export`)

- Route `/manager/payments` = "Payments & History"; `/employee/history` =
  "History" (same `PaymentsReportScreen`, mode from `paymentsHistoryOnlyProvider`
  = not a manager). `/employee/history/report` redirects there.
- Opening a sheet from History: `/employee/history/sheet/<id>` =
  `SheetReviewScreen(readOnly: true)`; a line opens `/employee/expense/<id>`.
- Desktop row: select box, name + pill, amount, ⋮ menu (`payment_row_menu.dart`:
  View; Settle or Edit), then the reference columns. History: "Sheet" column
  (budget name #number or "Monthly") instead of the employee, no gov ID, menu =
  View only. Phone History: no select column, no Settle / Edit, an Excel export
  button (`history_export_button.dart`) by the filter badge.
- "No payment" rows: grey pill, amount as sent (0), no checkbox, no Settle /
  Edit; a budget with nothing owed has no cycle (dash). Status filter shared by
  card and dialog (`payment_status_filter_dropdown.dart`), All / Pending /
  Processed / No payment. Every list call sends `includeNoPayment=true`.
- Landing filter All (`PaymentsFilter.defaults`); the dashboard Awaiting card and
  the Budgets panel tiles still pass Pending.

## Owner QA round 1 (2026-11-19) - supersedes the matching lines above

1. **Sign-in lands on Budgets** when the user has Budgets and Monthly shows no
   badge; otherwise it lands on the Monthly dashboard (D43; magic link via
   `completePostLogin`, Microsoft sign-in and a reopened app via `/home`;
   `sheetNavLandingRoute` decides, and it waits at most 4 s on the
   counts).
2. **No ⋮ menu.** A Pending row has a select box, a Closed row has Edit in the
   same place, and the eye sits next to it (`payment_row_select_cell.dart`).
   There is no per-row Settle: select, then Settle from the bulk bar. The phone
   works the same way (D35).
3. **One word per state:** Settle / התחשבנות for the action, Closed / סגור for
   the done state. Paid, Charged, Returned and Processed are gone, including
   in the Excel file ("Closed Date"). D42 replaces the earlier "Returned"
   wording.
4. **The status is plain text in its own sortable column**, with no pill
   (`payment_status_cell.dart`). The sheet's payment box keeps its badge.
5. **Phone:** no Settle / Edit buttons on rows. A status toggle (All / Pending
   / Closed / No payment) above the table applies in one tap
   (`payment_status_toggle.dart`). The cards carry no status text, because
   the toggle holds it (owner, same round).
6. **Manager menu has "Payments" and "History":** `/manager/payments` opens on
   Pending (the dashboard card leads here), and `/manager/history` opens on
   All. The title follows the route, and Reset returns to the entry's own
   status. The employee keeps "History". History opens sorted by approval
   date, newest first, and Payments by employee A-Z (owner, same day).

## QA

Manager + employee x desktop + mobile, EN + HE; module off; an employee cannot
reach another employee's sheet by URL.

### QA matrix (manual-qa section 5a)

**1. State x role - where each action must NOT appear**

| Row status | Manager (A/B) | Employee, own row (C/D) | Employee, someone else's |
|---|---|---|---|
| Pending (Awaiting) | checkbox; ⋮ View + Settle (desktop) / Settle button (phone) | no checkbox, ⋮ View only / no button | not listed; URL `/employee/history/sheet/<id>` -> "not found" |
| Processed | no checkbox; ⋮ View + Edit / Edit button | no checkbox, View only | not listed; URL -> "not found" |
| No payment | no checkbox; ⋮ View only / no button | View only | not listed; URL -> "not found" |
| Not approved (Draft / Awaiting approval / Returned) | not listed | not listed | not listed |

**2. Parity with the screens it copies** - Payments (PC-8 / FS-1025): select all,
bulk bar (net amount), Settle dialog, Edit dialog, Export All, export selected,
total row, paging notice, sort on every column, sheet-type filter with Budgets
off (D39), amount info tooltip; sheet review (approved sheet): no tabs, PDF /
Excel in the header (desktop) / back row (phone), payment strip, Activity.

**3. Cross-role follow-through** - manager settles a budget in A -> employee D
sees it "Paid"/"Collected" in History; manager edits it back to Pending -> C
sees Pending.

**4. Visual sweep** - 1440 and ~870: the ⋮ column, every pill (Pending / Paid /
Collected / No payment) on one line, amounts with ₪ and minus, "Sheet" column,
dash for no cycle.

**5. Language per screen** - EN -> HE on Payments & History, History, the
filter card / dialog (status entries incl. "ללא תשלום"), the ⋮ menu items, the
read-only sheet.

**6. Navigation** - each screen: menu (desktop + phone), URL, dashboard card
(manager, lands on Pending), Back in app and browser; old URL
`/employee/history/report` -> History; a manager on `/employee/history` -> own
home; an employee on `/manager/payments` -> no access.

**7. Hebrew fit** - zoom in HE at 1440 / 870 / 375: "פעולות" header, the menu
items, "תשלומים והיסטוריה" / "היסטוריה" titles and menu entries, "ללא תשלום"
pill and dropdown entry, "גיליון" header, the phone Settle / Edit button.

**8. Module OFF** - Budgets off: manager and employee still list, open (read-only
review) and download PDF / Excel of an approved budget; Budgets back on after.

**9. Free-text limits** - no new free-text input (Settle / Edit dialogs
unchanged).

**Added after the matrix review (2026-11-19)**

- 1 - Each status above for both types: Monthly; budget to pay (+); budget to
  return (red minus). Employee typing `/employee/history/sheet/<id>` of their
  own sheet that is not approved yet: shows it, no approve / decline / add /
  line actions. Export list (desktop Export All, phone export button): the
  file holds only the employee's rows. PDF / Excel on the read-only sheet.
  A line opened from it (`/employee/expense/<id>`) is not editable.
- 2 - What the employee's Digital archive gave them (filter, open, export)
  is all in History. History filters: status, sheet type, approval date,
  cycle, payment (processed) date; no employee filter; same set in the phone
  dialog.
- 3 - Manager approves a sheet -> it appears in the employee's History
  (Pending). A budget settled to zero reads "No payment" for both roles.
- 4 - Approval-date and payment-date columns; a long budget name in "Sheet"
  at ~870 (ellipsis + tooltip); the read-only sheet at 1440 / 375.
- 5 / 7 - The phone History export button; the phone filter dialog; the
  read-only sheet's PDF / Excel buttons; the status dropdown width with
  "ללא תשלום".
- 6 - The Budgets dashboard panel tiles land on Pending + Budget. The
  read-only sheet opened from the list, by URL, after refresh: Back returns to
  History with its filter kept. A manager on `/employee/history/sheet/<id>` ->
  own home; an employee on `/manager/sheet/<id>` -> no access. Digital
  archive gone from the employee's desktop and phone menus, still there for
  the manager. The History menu entry is highlighted on History.
- 8 - Monthly cannot be turned off (the module is locked) - not applicable.
  With Budgets off: the sheet-type filter stays (D39), History stays in the
  menu, the Budgets dashboard tiles are gone.
- Copy rule - no confirm / destructive text changed; "No payment" pill text
  only (no tooltip).

## Manual QA

### Run 1 - 2026-11-19
- Branch / commit: feature/pc5-sheet-export @ uncommitted (PC-9 on top of PC-5 + FS-1025)
- QA company: XpenseDesk Demo Company; manager m@xpensedesk.com; employee e@xpensedesk.com
- Before QA: backend CR + security (clean after fixes), Flutter CR + security
  (2 blockers fixed: desktop History still offered select / Settle / Edit;
  Export All offered Settle to an employee), backend suite 772/772, Flutter
  291 tests, analyzer clean.
- Coverage: A manager 1440 + 870 EN/HE (list, ⋮ menu per status, Settle dialog
  opened + cancelled, status filter incl. No payment, Reset -> All, select all
  + bulk bar, Export All, menu labels, dashboard Awaiting card -> Pending +
  Monthly, View -> budget page -> Back); B manager 375 EN (rows, Settle / Edit
  same size, No payment row has no button / checkbox, filter dialog); C employee
  1440 EN/HE (menu: History, no Digital archive; History list own sheets only,
  ⋮ = View only, no checkboxes / gov ID, advanced filters without Employee,
  Export All, read-only sheet: no decisions, PDF download, line opens
  read-only, Back; old `/employee/history/report` -> History; employee on
  `/manager/payments` -> own dashboard; another employee's sheet by URL ->
  404, "not found"); D employee 375 EN/HE (rows, export button, filter dialog
  without Employee, phone menu); Budgets OFF: A list + budget view, C History +
  read-only budget + PDF, D list. API check: an employee sending another
  `userId` still gets only their 13 sheets.
- Not covered: cross-role write (manager settles -> employee sees Paid) - it
  writes payment data on the shared QA users; manager HE on 375; opening the
  downloaded Excel / PDF files.

| # | Lane | Lang | Screen | Severity | Finding | Status |
|---|---|---|---|---|---|---|
| 1 | A | EN | Payments & History | Major | The total row added up "No payment" rows (pre-PC-8 budgets with a computed gap: -₪3,125.60 over 5 No payment sheets) while the server and Excel totals leave them out | Fixed (run 1) - `PaymentTotals.of` skips them; re-checked: ₪0.00 |
| 2 | C | EN | Read-only sheet by URL (another employee's) | Major | Server 404 retried forever (default Riverpod retry) - endless spinner, "not found" never shown; same on `/manager/sheet/<unknown>` | Fixed (run 1) - `sheetDetailRetry` stops on not-found; re-checked: one 404, "This sheet no longer exists." |
| 3 | D | EN | Not-found view (History) | Minor | Its button read "Back to approvals" for an employee | Fixed (run 1) - reads "Back", goes to History |

Result: 3 findings - 0 open, 3 fixed.

### Run 2 - 2026-11-19 (owner decision D42)
- Change: money an employee gave back reads "Returned" / "הוחזר" for them
  (History pill and their sheet's payment box); managers keep "Charged".
- Coverage: C employee 1440 EN + HE - History pill on a settled budget the
  employee returned money on; HE fits on one line. Unit test for both wordings.

Result: clean.

### Run 3 - 2026-11-19 (owner QA round 1 fixes)
- Branch / commit: feature/pc5-sheet-export @ ce9bd62 + uncommitted round-1 fixes
- Before QA: backend suite 772/772, Flutter 296 tests, analyzer clean (9 old
  infos). CR + security review: no security findings; 4 should-fix fixed
  (Back between Payments and History kept the other filter; Closed links
  opened "Payments"; Microsoft sign-in / reopened app skipped the landing -
  now via `/home`; phone Reset ignored the entry) plus 3 nits.
- Coverage: A manager 1440 EN/HE - sign-in lands on Budgets (Monthly had no
  badge; with Budgets off it lands on Monthly); menu Payments + History;
  Payments opens on Pending, History on All; Closed row Edit opens the dialog
  (Pending / Closed, "Closed Date") and cancels; No payment row has the eye
  only; status column sorts Pending first; HE headers on one line. B manager
  375 EN - toggle All / Pending / Closed / No payment applies at once; Closed
  rows show Edit; selecting a Pending row gives "Settle 1 sheet" in the bulk
  card; menu Payments / History. C employee 1440 EN - History, eye only, plain
  status. D employee 375 EN - sign-in lands on their budget; History cards
  have no status text, no buttons, toggle on top. Budgets OFF: manager History
  lists and works; `/` lands via `/home`; Payments -> History -> Back shows
  Payments on Pending again. Budgets left OFF for the Demo company, as found.
- Not covered: settling or editing for real (it writes payment data on the
  shared QA users); opening the Excel file to read the new captions (covered
  by the backend tests).

Result: clean.

### Run 4 - 2026-11-19 (History sort)
- Change: History opens on Approved Date, newest first; Payments stays
  employee A-Z. Unit test added (297 tests).
- Coverage: C employee 1440 EN - History opens newest first (11/19 rows on
  top), the Approved Date header shows the down arrow, and Search keeps it.

Result: clean.
