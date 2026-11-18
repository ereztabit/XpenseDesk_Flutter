# PC-8 - Sheet settlement through the payment module

> Mission: FS-1020 (backend: BackEnd/XpenseDeskServer/docs/done/pc-8-settlement.md - the generic model and the business rules). Plan: BackEnd/XpenseDeskServer/docs/petty-cash/00-plan.md

Status: FILED 2026-11-18, rewritten 2026-11-18 (generic: any sheet type
settles through payments - Budgets now, Travel next). Not started.

**No Lovable design round** (owner, 2026-11-18): nothing here is a new screen.
Every item extends a screen and reuses its widgets; build it as such.

## Client part

| # | Where | Change | Reuses |
|---|---|---|---|
| F1 | Payments report | Columns Sheet type (Monthly / Budget) and Budget name + `#number`; Cycle filled for every type | the report table |
| F2 | Payments report | Direction per row: **To pay** / **To collect**; Processed reads **Paid** / **Collected** | the payment status pill |
| F3 | Payments report | Sheet-type filter, shown only when the company has more than one type enabled | the report's filter row |
| F4 | Payments report | Group by employee, net per employee per cycle (client grouping) | the report rows |
| F5 | Payments report + export | Totals split To pay / To collect - never one netted figure | the totals strip |
| F6 | Company dashboard | "Awaiting Payment" card shows To pay and To collect apart | the card |
| F7 | Budgets dashboard | Pending-settlement block: budgets awaiting settlement, To pay / To collect (count + amount), opens the report filtered to Budget | the dashboard's counter cards |
| F8 | Approved budget page | Payment badge + details (Awaiting / Paid / Collected, date, reference, note) | the Monthly sheet's payment display |

EN + HE captions for every new label. Written generically by sheet type, so
Travel later needs only its type caption.

## Manual test plan (PC-8)

Scenario matrix per `.claude/skills/manual-qa/SKILL.md` section 5a. Runs are
recorded under `## Manual QA` (section 7) below this plan.

**Lanes:** A = m@ desktop 1440x900, A2 = m@ desktop ~870 wide, B = m@ mobile
375x812, C = e@ desktop 1440, D = e@ mobile. QA company `XpenseDesk Demo
Company` (dev).

**Phases (4 role switches in total):**

| Phase | User / lanes | Runs |
|---|---|---|
| 1 | m@ - A, A2, B | T0, T1 (create every budget below) |
| 2 | e@ - C, D | T2 (lines + submit), T9 (Monthly expense + submit) |
| 3 | m@ - A, A2, B | T3a-T3d, T4-T8 (manager side), T10-T11, T13-T15, T17-T19, T20 (A, B), T21 |
| 4 | e@ - C, D | T7 (holder side), T3d follow-up, T16, T20 (C) |

**Preconditions (T0, lane A, read only):** Budgets module on and negative
balance allowed (D4) in `/manager/company-config?tab=modules`; one Open cycle -
note its long month (e.g. "November 2026" / "נובמבר 2026"); every "cycle" below
means that one. No older QA PC8 rows in Awaiting (else note them). Receipts from
`docs/test-receipts/`.

**Data (all created in T1, holder QA Employee unless noted):**

| Budget | Amount | Lines (phase 2) | Settlement | Used in |
|---|---|---|---|---|
| QA PC8 Over | ₪300 | ₪200 + ₪150 | pay ₪50 | backbone |
| QA PC8 Under | ₪500 | ₪300 + ₪100 (declined) | collect ₪200 | backbone |
| QA PC8 Exact | ₪200 | ₪200 | none | backbone |
| QA PC8 Ret | ₪200 | ₪150 | - (returned) | T3d |
| QA PC8 Own (holder QA Manager) | ₪100 | ₪120, added by m@ in T13 | pay ₪20 | T13 |
| QA PC8 Sp1 / Sp3 / Sp4 | ₪100 each | ₪80 | collect ₪20 | Approve button: HE (A), ~870 (A2), mobile (B) |
| QA PC8 Sp2 / Sp5 | ₪100 each | ₪60 + ₪60 (decline 1st) | collect ₪40 | last-line prompt: HE (A), mobile (B) |

### Scenarios - the owner's flow (backbone, in order)

| # | Lane | Lang | Steps | Expected |
|---|---|---|---|---|
"Panel check" = go to `/budgets` by in-app navigation (menu / sheet-type bar,
no reload) and read the "Budgets awaiting settlement" panel.

| T1 | A | EN | `/budgets` -> **New budget** for every row of the Data table | Draft budgets with `#number`; panel present, all clear ("Nothing to settle — you're done"); no payment strip on a Draft budget page |
| T2 | C, D | EN | `/budgets` -> each QA budget except Own -> new expense with a test receipt per line -> **Submit ₪X for approval** (Sp4 / Sp5 from lane D) | Toast "Submitted for approval"; strip "Awaiting approval"; no payment strip, no settlement text on the employee side |
| T3a | A | EN | QA PC8 Over -> **Approve** -> **Cancel**; Approve again -> confirm; panel check | Confirm body ends "To pay ₪50.00 to QA Employee - in the payments of <cycle long month>"; Cancel: still Awaiting, no Payments row; confirm: toast Approved; panel now "To pay 1 budget ₪50.00" |
| T3b | A | EN | QA PC8 Under -> **Decline** the ₪100 line, **Approve** the ₪300 line (last pending) -> confirm; panel check | "All expenses reviewed" prompt adds "To collect ₪200.00 from QA Employee - in the payments of <cycle>" (declined line counted); budget Approved; panel adds "To collect 1 budget ₪200.00" |
| T3c | A | EN | QA PC8 Exact -> **Approve** | Confirm adds "Nothing to settle - the budget is fully used."; Approved; no payment strip; panel unchanged |
| T3d | A, then C | EN | QA PC8 Ret -> **Return** with a reason; panel check. Phase 4 (C): edit the line to ₪160 -> **Submit** | Returned strip with the reason; no payment strip; no Payments row; panel unchanged. Employee can edit the line and resubmit -> Awaiting approval, still no payment strip / row |
| T4 | A | EN | `/manager/payments`, Payment Status = Awaiting Payment, **Search** | Over: Sheet type "Budget" + "QA PC8 Over #<n>", Cycle = long month, ₪50.00 + "To pay", badge "Awaiting Payment"; Under: ₪200.00 + "To collect" (purple, no minus); Exact and Ret absent. Found caption "(N - To pay a - ₪X  /  To collect b - ₪Y)" never one netted sum |
| T5 | A | EN | **Advanced filters** -> Employee = QA Employee; **Sheet type** = Budget -> **Search** -> **Select All** -> **Mark as Processed** -> clear date -> confirm; set date + note -> confirm; panel check | Only Over + Under (spares not yet approved); bulk bar "2 sheets - To pay 1 - ₪50.00 / To collect 1 - ₪200.00", dialog summary same; empty date -> "Processed date is required.", no POST; toast "Processed ...", rows leave in place; panel all clear |
| T6 | A | EN | Payment Status = Processed, same filters -> **Export All** -> download the .xlsx and read it with a script (openpyxl, `python -I`) | Columns add Sheet type, Budget, Direction; column F (Amount) signed: Over +50, Under **-200**; totals as two rows **To pay** 50 / **To collect** 200, no netted total |
| T7 | A (phase 3), C (phase 4) | EN | Open Over, Under, Exact pages before and after T5 | Over / Under: strip under the header card - "Payment Status", Awaiting Payment -> **Paid** / **Collected**, reference (after processing), "Payment cycle <long month>", "Processed on <company date>", right side "To pay ₪50.00" / "To collect ₪200.00" (purple). Exact: no strip, no empty band. Holder (C): same strip SHOWN |
| T8 | A | EN | Before / after T5: panel and `/dashboard` "Awaiting Payment" card; **View Report** / **View History** on each | Before: panel "To pay 1 budget ₪50.00" / "To collect 1 budget ₪200.00"; company card same split in "sheets" (plus Monthly). After: panel all clear; card Monthly only. Panel View Report -> Payments with Awaiting + Sheet type Budget; card View Report -> Awaiting, Sheet type All |

### Scenarios - Monthly sanity

"As before" (Budgets OFF) = exactly the pre-PC-8 screens; checked in T15.

| # | Lane | Lang | Steps | Expected |
|---|---|---|---|---|
| T9 | C (phase 2) | EN | `/employee/new-expense` (receipt) -> Monthly sheet -> **Submit** | As before |
| T10 | A | EN | `/manager-approvals` -> the sheet -> **Approve** | Confirm "Approve expense of ₪X for QA Employee? / After approval ..." - **no** settlement line; sheet strip: Awaiting Payment, "Total" (not To pay), no Payment cycle row |
| T11 | A | EN | Budgets ON: `/manager/payments`, Sheet type = Monthly -> the Monthly row -> process it | Column "Monthly" (no budget line), "To pay" under the amount, badge Awaiting Payment -> **Paid**; caption without "To collect" |

### Scenarios - other cover

| # | Lane | Lang | Steps | Expected |
|---|---|---|---|---|
| T13 | A | EN | `/budgets` -> QA PC8 Own -> line ₪120 -> **Approve** -> **Cancel**; Approve -> confirm; panel check | Confirm: "Approve expense of ₪120.00 for QA Manager?", "After approval you will no longer be able to edit.", "To pay ₪20.00 to QA Manager - in the payments of <cycle>". Cancel: not approved, no Payments row. Confirm: toast Approved; Payments row QA Manager / Budget / ₪20 To pay; strip on the page; panel "To pay 1 budget ₪20.00" |
| T14 | A | EN | Payments, Processed: QA PC8 Under -> **Edit** -> change date + note -> save; panel check; Edit -> **Awaiting Payment** -> save; panel check; re-process; panel check | Dialog summary "To collect ₪200.00"; toast "Payment status updated"; revert: row Awaiting / To collect, budget strip Awaiting (no stale "Collected"), panel shows "To collect 1 budget ₪200.00" without reload, company card counts it; re-process: Collected, panel back |
| T15 | A, B | EN | 1. Budgets ON: Sheet type in filter card (A) and **Filters** dialog (B): All / Monthly / Budget. 2. Process every Awaiting QA budget row. 3. Modules -> Budgets **off** -> Payments, Status All. 4. Lane B: same list. 5. Select only the Monthly row -> **Export** -> read the .xlsx with the script. 6. Monthly row -> **Edit** -> Awaiting Payment -> `/dashboard` card -> re-process -> card. 7. Budgets back **on** -> Payments | 1: shown. 3: no Sheet type control, no Sheet type column; Monthly row amount without "To pay"; badge "Processed" (not Paid); previously approved budget rows still listed (data stays), "To collect" still shown on them. 4: mobile subtitle = cycle only. 5: the 9 original columns + single Total row. 6: card single line "1 sheet ₪X", no To pay / To collect labels; after re-process all clear. 7: column, To pay, Paid / Collected back |
| T16 | C, D (phase 4) | EN+HE | Own budgets list and each approved budget page; type `/manager/payments` by hand | No Approve / Return / Edit; approved lines locked; payment strip SHOWN on own approved budgets (Paid / Collected, cycle, amount); Payments URL -> no access |
| T17 | A, A2, B | HE | Switch EN -> HE **on each screen**: Sp1 **Approve** confirm (A), Sp2 decline + last-line prompt (A), budget strip, Payments (filter card, Filters dialog, Sheet type + Employee dropdowns, rows, caption, bulk bar, Mark / Edit dialogs), panel, company card | "לתשלום" / "לגבייה", "שולם" / "נגבה", "סוג גיליון", "תקציב" / "חודשי", "מחזור תשלום", "תקציבים ממתינים להסדרה", "לטובת" / "מאת" / "בתשלומי"; dropdowns re-render ("הכל", employee filter not stuck in EN); `#number`, amounts, dates intact in RTL (`#1004` not `1004#`, ₪ side); no EN, no raw keys |
| T18 | A, A2 | EN+HE | ~870 (A2): Sp3 **Approve** confirm; then sweep at 1440 and ~870: Payments table, strip, panel, card | Confirm fits, settlement line wraps; one-line badges; "To collect" not clipped; budget name ellipsis + tooltip; table scrolls sideways with scrollbar at 870; currency on every amount |
| T19 | B, D | EN+HE | Mobile (B): Sp4 **Approve** confirm, Sp5 decline + last-line prompt; Payments rows (subtitle "QA PC8 Sp4 #n - <cycle>" with Budgets on), Filters dialog with Sheet type, bulk selection card, Mark / Edit dialogs, budget strip, panel, dashboard card. D: own strip | Both prompts show the settlement line and fit 375x812, buttons reachable; no overflow / horizontal scroll; split text wraps; no RenderFlex errors |
| T20 | A, B, C | EN | Payments fresh by URL, from the menu, from each **View Report** / **View History**; approved budget page fresh by URL, from `/budgets/list`, from the dashboard; C: own approved budget by URL, from its list and dashboard; in-app Back and browser back from each | URL / menu keep the session filter; CTAs pre-set status (+ Budget from the panel), still shown after Back; strip present on a fresh load; Back returns to the opener |
| T21 | A | EN | Copy check | "no longer be able to edit" true for budgets; "Nothing to settle - the budget is fully used." only on exact; Mark as Processed is revertible via Edit and no message says otherwise |

### Parity with Monthly (rule 2) - check each on budget rows

Covered: approve confirm (amount, holder, edit warning) T3a/T13; last-line
prompt T3b; payment strip (badge, reference, Processed on) T7; Mark as Processed
date-required + note T5; Edit / revert T14; in-place removal under Awaiting,
refetch under All / Processed T5/T14; card all clear + View History T8.

Not covered (backend tests cover the API): export offering to mark the exported
rows processed, the 100-row selection cap, the conflict refresh ("Some sheets
are no longer awaiting payment ...").

### State x role matrix (budget)

M = manager (lane A/B), H = holder employee (C/D), O = other employee (no third
QA user - checked only via the URL guard).

| Item | Draft | Awaiting | Returned | Approved, non-zero, awaiting pay | Approved, processed | Approved, zero |
|---|---|---|---|---|---|---|
| Settlement line in approve confirm / last-line prompt | M, H absent | M shown, H absent | M shown, H absent | - | - | - |
| Payment strip on budget page | M, H absent | M, H absent | M, H absent | M shown, H shown | M shown, H shown | M, H absent |
| Row in Payments | absent | absent | absent | M shown (Awaiting) | M shown (Paid / Collected) | absent |
| Edit (payment) on the row | - | - | - | M shown | M shown (revert) | - |
| Budgets panel / dashboard card count | no | no | no | yes (pay / collect apart) | no | no |
| Holder edits lines | yes | yes | yes (T3d) | no (locked) | no | no |
| Payments screen access | H, O: no access by URL (T16) | | | | | |

H shown = expectation pending owner confirmation (Monthly never shows the
employee a payment status).

## Manual QA

### Run 1 - 2026-11-18
- Branch / commit: feature/pc8-story-generic-settlement @ uncommitted
- QA company: XpenseDesk Demo Company; manager m@xpensedesk.com; employee e@xpensedesk.com
- Coverage: manager 1440 EN (T1-T8, T13, T3d, T9-T10, T15), manager ~870 HE (approve confirm, strip, company card, Payments), manager mobile EN (Payments, Budgets panel, approve confirm), employee mobile EN (settled strip, returned budget resubmit, Payments URL refused, API 403).
- Data: budgets PC8 Over/Under/Exact/Narrow (approved), PC8 Mine (manager's own, approved), PC8 Return (returned, resubmitted), PC8 HE/Mobile (awaiting); Over + Under processed; one Monthly sheet (Employee User, June) approved and processed. Budgets module turned off and back on.
- Excel: the bulk export was read in the page - Under -200 Collect, Over 200 Pay, To pay 200, To collect -200 (never netted).
- Not covered: the new-expense form (needs a receipt upload, which the built-in browser cannot do - lines were filed through the same API); employee desktop lane; mobile screenshots of open dialogs (capture tool crops at device ratio 2 - the mobile confirm was seen opening with its settlement line).

| # | Lane | Lang | Screen | Severity | Finding | Status |
|---|---|---|---|---|---|---|
| 1 | B (manager, mobile) | EN | Budgets panel / payments card | Major | To pay + To collect lines overflowed by 27px at 375 wide | Fixed (lines wrap; widget test awaiting_payment_amounts_test) |
| 2 | A (manager, 1440) | EN | Monthly dashboard payments card | Major | After approving a budget the card kept the old counts until a reload | Fixed (refreshed after budget approval; checked in the HE run) |
| 3 | A (manager, 1440) | EN | Payments | Minor | With Budgets on, the table needs a horizontal scroll at 1440 (the Sheet type column); Edit sits under the scrollbar edge | Fixed (run 2: columns resized, fits 1440) |
| 4 | A / A2 | EN, HE | Budget approve confirm | Minor | Title and body reuse the Monthly copy ("Approve sheet", "Approve expense of") on a budget | Fixed (run 2: "Approve budget") |
| 5 | D (employee, mobile) | EN | Settled budget strip | Minor | The holder reads "To collect" (the company's side) on money they return | Fixed (run 2: holder reads "To return", owner D16) |

Pre-existing, not PC-8 (follow-ups): a Riverpod "setState during build" from BudgetsTeamRow on the Budgets dashboard; the Monthly payments card is stale after a Monthly sheet approval until reload.

Result: 5 findings - 0 open, 5 fixed (3 in run 2).

### Run 2 - 2026-11-18
- Branch / commit: feature/pc8-story-generic-settlement @ uncommitted
- Coverage: re-check of findings 3-5 - manager 1440 EN (Payments table, budget approve confirm), employee mobile EN (settled budget strip).

Result: clean.

### Run 3 - 2026-11-18 (owner's Payments screen review)
- Branch / commit: feature/pc8-story-generic-settlement @ uncommitted
- Coverage: manager 1440 EN and mobile 375 EN - Payments list, caption, row action, bulk bar / strip. Decisions in budgets-guide D17.

| # | Lane | Lang | Screen | Severity | Finding | Status |
|---|---|---|---|---|---|---|
| 6 | owner | - | Payments | Major | Email column not needed | Fixed (removed) |
| 7 | owner | - | Payments | Major | Money to collect should read "To charge" (לגבות), red with a minus | Fixed |
| 8 | owner | - | Payments | Major | Row action should be "Process" | Fixed (Edit stays on processed rows) |
| 9 | owner | - | Payments bulk bar | Major | Export / Mark as Processed unreadable on the green background | Fixed (white card, Process primary) |
| 10 | owner | - | Payments | Minor | "Awaiting Payment" badge too long | Fixed ("Pending") |
| 11 | owner | - | Payments mobile | Major | Row layout unclear; caption should be "N sheets found: +X" | Fixed (two-line rows, signed-net caption) |
| 12 | owner | - | Payments mobile | Minor | Bulk card wastes space; Export All redundant | Fixed (one-row strip; Export All removed on mobile) |

Not covered: Hebrew on screen for the new captions (unit-tested), long budget subtitles wrapping to a second line (changed after the browser check).

| 13 | owner | - | Payments mobile + desktop | Major | "Process" looked like a status pill next to "Pending" | Fixed (status is plain text on mobile; Process is a 32px button with a check icon) |

| 14 | owner | - | Payments | Major | Status not in place; Process far right with no caption | Fixed (status pill beside the name; columns: name + pill, amount, Process, sheet type, cycle, approved date, processed date, gov ID) |
| 15 | owner | - | Payments | Minor | "Sheets found" caption replaced by a total row; sort by sheet type | Fixed (Total row under desktop table and mobile list; Sheet type header sortable) |

| 16 | owner | - | Monthly dashboard | Blocker | The Monthly Awaiting Payment card counted budgets (To pay / To charge) | Fixed (card restored; Monthly-only summary; its report opens on Monthly) |
| 17 | owner | - | Budgets dashboard | Minor | Settlement banner was text-heavy | Fixed (two tiles: To pay green, To charge red with minus) |

| 18 | owner | - | Payments bulk strip | Minor | Bulk strip did not read as a bulk action | Fixed ("Process N sheets"; Export and Process at the row button size; desktop bar says "Process N sheets" too) |

| 19 | owner | - | Payments mobile bulk bar | Minor | Bulk bar wasted space and looked improvised | Fixed (one tinted row: count bubble, "N sheets selected" + signed amount, icon Export, "Process N sheets") |

| 20 | owner | - | Payments bulk bar | Minor | Export icon did not say it is an Excel file | Fixed (drawn Excel tile with a down-arrow badge, mobile and desktop) |

| 21 | owner | - | Payments dialogs (mobile) | Major | Mark-as-processed summary overflowed by 36px; I had never opened it on mobile | Fixed (summary is one signed net; Wrap; widget test fails on the old code) |
| 22 | owner | - | Excel export | Major | Two total rows; status shown as the code name; same file name each day overwrote downloads | Fixed (one signed Total; "Awaiting Payment"; timestamped file name) |
| 23 | owner | - | Payments | Minor | Plus sign on positive totals | Fixed (minus only when negative) |
| 24 | owner | - | Payment dialog | Minor | "Edit Sheets Payment Status" wrapped on mobile | Fixed ("Payment Status") |
| 25 | B (mobile) | EN | Payments bulk bar | Minor | Negative selection amount not red | Fixed |
| 26 | A2 (~900) | EN | Payments | Major | Name link on a budget row opened the Monthly sheet review | Fixed (opens the budget page) |

### Run 4 - 2026-11-18 (every control, both sizes)
- Coverage: mobile 375 EN + HE and desktop ~900 EN + HE: filter dialog (all dropdowns, Search, Reset), select all, bulk Export (+ offer dialog), bulk Process, date picker, X close, row Process, row Edit (processed view), status toggle, sort Amount / Sheet type, name link and Back, mobile menu + language switch, Export All (file read: single Total, "Awaiting Payment"), advanced filters, Reset. Console read after every action: no errors.
- Not covered: 1440 in the pane this run (too narrow to read; checked earlier this session).

| 27 | A (manager) | EN | Monthly dashboard card | Minor | Card stayed stale after a Monthly sheet approval (pre-existing, now on the Monthly summary) | Fixed (refreshed after approval; re-checked: 2 -> 3 sheets with no reload) |
| 28 | A (manager, Budgets off) | EN | Payments | Major | From the Monthly card, a Monthly-only company saw a "Sheet type: Monthly" filter | Fixed (the card filters by sheet type only when budgets are paid too) |

### Run 5 - 2026-11-18 (Monthly sanity, end to end)
- Employee files a Monthly expense in the UI (receipt dropped on the upload step, AI read 96.50 / Cafe Aroma) -> cycle closed with the dev endpoints (backdate-current-cycle-end + promote-cycle) -> manager reviews and approves (Monthly confirm, no settlement line) -> Monthly card (Monthly only) -> Payments filtered to Monthly -> select, Export (file: 9 original columns, "Awaiting Payment", one Total = SUM) -> Mark processed -> card refreshed. Repeated with Budgets off: no Budgets tab, no sheet-type filter, approve -> card refresh -> row Process -> Processed. API: Monthly sheets keep no payment cycle and no settlement.
- Data: the QA company's cycle was closed twice on dev; Budgets was switched off and back on.
- Not covered: the employee sheet picker shows only the current cycle (unchanged by PC-8).

Result: 28 findings - 0 open.
