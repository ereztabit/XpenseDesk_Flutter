# PC-QA-1 - Budget page QA comments (bundle of 9)

> Mission: FS-1025 (backend: BackEnd/XpenseDeskServer/docs/petty-cash/pc-qa-1-budget-page-qa.md). Guide: BackEnd/XpenseDeskServer/docs/petty-cash/budgets-guide.md

Status: FILED 2026-11-19. Not started. **Next after PC-5 (FS-1016), before
anything else moves forward.**

Owner QA pass on the budget page. Numbers match the backend story.

1. **Needs attention bulk upload section missing.** The budget page lacks the
   "Needs attention" bulk upload section the Monthly sheet has. Reuse the
   Monthly widget as is.
2. **Upload progress leaks to other budgets.** While a bulk upload runs on one
   budget, every other budget the user opens also shows it as uploading. Show
   the progress only on the budget being uploaded to (key it by sheet id).
3. **Bell opens the wrong page.** Header bell -> "Processing complete" for a
   budget upload lands on the Monthly sheet. It must open the budget the upload
   was for.
4. **Manager has no Submit on an employee's budget.** A manager opening an
   employee's budget does not see "Submit for approval". The server supports
   submitting on the holder's behalf (guide section 2) - show the button
   (Draft / Returned).
5. **Invitation email (missing feature, backend).** Holder gets an email when a
   manager opens a budget for them. No client work beyond copy review.
6. **Policy violations block submit.** Rules: receipt date later than the
   budget's end date; no amount. A violating line sits under Needs attention
   with its reason, and Submit is disabled while any exists. The server also
   refuses (flat error codes per rule) - show each code's own message. Lines
   can become violations when the end date is moved earlier.
7. **Search bar spacing.** The search bar floats above the table with a gap.
   Consolidate it into the table object, directly above its header.
8. **Limit reached.** When the company does not allow a negative balance and
   the balance is zero or below: Add expense is grayed out and the bulk upload
   section disappears. With negatives allowed, nothing changes.
9. **Submit arrow direction.** The arrow on "Submit for approval" points the
   wrong way. It must point forward in reading direction - right in English,
   left in Hebrew.

## Added 2026-11-19 - approved Monthly sheet (client only)

Seen on Sheet review of an approved Monthly sheet (manager view).

10. **Drop the Status column on an approved sheet.** Every line on an
    approved sheet reads "Approved" (D24: an approved sheet lists only its
    approved lines), so the column carries no information. Remove it on the
    approved Monthly sheet, and on the approved budget too, for the same
    reason.
11. **Payment status box needs a design.** The box is mostly empty white
    space: an icon and a "Pending" pill on one side, "Total" on the other,
    nothing in between. Its edges also don't line up with the header card
    and the table around it. The total it shows is the same as the header's
    Total. Redesign it as an organized summary of the payment, aligned with
    the cards around it. Design it in the Lovable app mock first. Use the
    same box for the approved budget's payment status (PC-8 / D16).
12. **Mobile: back + title row wastes space.** On mobile, the "<- Sheet
    review" row takes a full row and its trailing half is empty. The sheet
    card below is pushed down, so the first line card only starts mid-screen.
    Make the top tighter: fold the back arrow and the title into one compact
    row with the sheet card, or put that row's empty half to use, e.g. for
    the PDF / Excel downloads that now take their own row inside the card.
    Same on the budget page. On mobile the line cards also each carry an
    "Approved" pill on an approved sheet; drop it with item 10.

## Added 2026-11-19 - Payments report (client only)

Found in PC-5 manual QA run 2 (`docs/in-progress/pc-5-summary-report-spec.md`).

13. **Filter dropdowns stay English after a language switch.** On the desktop
    Payments filter card, switching EN -> HE from the header leaves the
    Payment status and Sheet type dropdowns showing "Pending" / "All" in
    English. Every control must re-render in the new language (the mobile
    filter dialog already does).

## Added 2026-11-19 - owner QA round 3 (after the checklist)

14. Admin company page: "Clear stored sheet exports" below Billing, like the other sections.
15. Needs action: each line's reason inside its own row / card, no summary list; a
    shorter title that fits mobile - Monthly too.
16. A budget's end date can be set up to 6 months back (server + proc script).
17. Submit when blocked looks disabled (not just gray); tapping it anyway shakes the
    Needs action card.
18. A manager on a Returned budget can clearly resubmit (the Submit beside Approve read
    as disabled).
19. Budget page: the end date shows the year (15.12.2026, not 15.12).
20. "+ New Expense" blocked at the limit looks disabled - disabled buttons in general.
21. Mobile, Awaiting budget: the awaiting-approval banner moves into the back row's free
    end (where approved budgets show the downloads).
22. Every Excel file prints "Fit Sheet on One Page" (server and app-built).
23. Budget settlement wording (HE): "לחייב את העובד" / "לשלם לעובד" instead of
    "להחזר מהעובד" / "לתשלום לעובד".
24. PDF: totals align toward the amount (left in RTL).
25. PDF: long notes truncated; text only - no markup or control characters.
26. Payments info tooltip stays when budgets are off (history stays), saying it is for
    budgets.
27. Budgets off: the Payments eye on a budget row opens the sheet, not the dashboard.
28. Sheet review opened from Payments: the back button says "Back", not "Back to approvals".
29. Payments: "Process" becomes "Settle" / "התחשבנות".

## Done when

- All twelve verified

- All thirteen verified on desktop and mobile, Hebrew and English (QA clicks every
  control).

## Build (2026-11-19, on `feature/pc5-sheet-export` - owner's call)

| # | Client change |
|---|---|
| 1 | Budget page: unreadable bulk lines (and #6 policy lines) in the Monthly amber Needs action card (`NeedsActionSection`, reused) while the budget is editable |
| 2 | Progress strip shows only batches filed into this budget (My expenses: Monthly batches only) - batch `expenseSheetId` |
| 3 | Bell card of a budget batch opens `/budgets/{id}` (needs the owner-applied SQL script; until then batches read as Monthly) |
| 4 | A manager gets "Submit for approval" on an employee's Draft / Returned budget (beside Approve on Returned) |
| 6 | Lines with `policyViolations` sit in Needs action with "merchant: reason"; Submit disabled while any line needs action; submit refusals have their own message |
| 7 | Desktop: the search sits inside the table card, above its header; a search miss keeps it there |
| 8 | No negative balance allowed and balance <= 0: "+ New Expense" grayed, bulk upload section hidden |
| 9 | Submit arrow `arrow_forward` (mirrors in Hebrew) |
| 10 | Approved Monthly sheet: no Status column, no per-line pills (desktop table, mobile cards, compact rows); approved budget: no card pills |
| 11 | Partial: the payment status strips now line up with the cards (the redesign waits for the Lovable mock) |
| 12 | Mobile: PDF / Excel move into the back / title row's empty end (Monthly and budget); tighter top spacing |
| 13 | Payments dropdowns rebuild on a language switch |

### QA matrix (written before the run)

| # | Check | Must NOT appear |
|---|---|---|
| Q1 | Budget with an action-required / policy line: amber card with reasons, Submit disabled (holder + manager) | Approved / Awaiting budget: no amber card |
| Q2 | Progress strip on budget A while B uploads | Not on budget B, not on My expenses for a budget batch |
| Q3 | Bell -> budget batch opens the budget (only after the SQL script) | - |
| Q4 | Manager on an employee's Draft budget: Submit; Returned: Submit + Approve | Employee non-holder: nothing; Approved: nothing |
| Q7 | Desktop search inside the table; typing a miss keeps the search, "No expenses found" | Mobile: search row unchanged |
| Q8 | No-negative company, budget at 0: Add grayed, no bulk strip | Negatives allowed: unchanged |
| Q9 | Submit arrow right (EN), left (HE) | - |
| Q10 | Approved Monthly / budget: no Status column / pills | Draft / Awaiting / Returned: Status column and pills kept |
| Q11 | Payment strip edges flush with the header card and table, 1440 + 375 | - |
| Q12 | Mobile 375 EN + HE: back row holds PDF / Excel, no overflow | Desktop: downloads stay in the card |
| Q13 | Payments: EN -> HE switch re-labels both dropdowns | - |

CR (independent reviewer, both repos) + security review: no blockers, 3 should-fix fixed -
the progress strip keeps old behavior while the server sends no batch target; Submit and
Approve sit side by side on desktop; a manager-approved line never lands in Needs action
(server: `BudgetPolicy` skips approved lines too, with a test). Security review: no findings.
Backend 754 passed / 0 failed / 2 skipped (item 3 tests, `@ignore` until the SQL script);
`flutter test` 278 green.

## Manual QA

### Run 1 - 2026-11-19
- Branch / commit: feature/pc5-sheet-export @ uncommitted (both repos)
- QA company: XpenseDesk Demo Company; manager m@xpensedesk.com; employee e@xpensedesk.com
- Coverage: manager 1440 + 375, employee (holder) 1440; EN + HE; budgets #1020 (Draft, 6 unreadable lines), #1009 (Draft, line after end date), #1007 (Returned), #1013 (Approved), approved Monthly sheet, Payments.
- Not covered: Q2 (needs a live bulk upload - not run on the shared users), Q3 (waits for the SQL script), Q8 (the QA company allows negative balances; changing it is a write - unit-tested), Q4 negative "employee non-holder" (existing 403, unchanged).

| # | Lane | Lang | Screen | Severity | Finding | Status |
|---|---|---|---|---|---|---|

Checked clean: Q1 amber card with reasons + Submit disabled (manager and holder); Q4 manager Submit on an employee's Draft, Submit beside Close on Returned; Q7 search in the table, a miss keeps it with "No expenses found"; Q9 arrow right EN / left HE; Q10 no Status column (desktop), no pills (cards and compact rows), Returned keeps tabs + Status; Q11 strips flush with the cards (1440, 375); Q12 PDF / Excel in the mobile back row, EN + HE, Monthly + budget, PDF still downloads (200); Q13 dropdowns relabel and open in HE; console: no exceptions or overflows.

Result: clean (run 1; Q2, Q3, Q8 not covered).

### Round 3 QA matrix (written before run 2)

| # | Check | Must NOT appear |
|---|---|---|
| R14 | Admin company > Configuration: "Stored sheet exports" card under Billing; Clear -> Cancel / Confirm count | Title row: no Clear button |
| R15 | Budget + Monthly: each flagged line shows its reason in its row (desktop) / card and compact row (mobile); card title "Expenses to fix" / "הוצאות לתיקון" fits 375 | No reasons summary list; clean lines show no note |
| R16 | End date 6 months back accepted, 7 refused (client picker + server, after the script) | - |
| R17 | Blocked Submit looks disabled (faded green, not-allowed cursor); tapping it shakes the amber card | An enabled Submit never shakes anything |
| R18 | Manager on a Returned budget: purple Submit beside green Approve, both look active | - |
| R19 | Budget header "Ends" shows dd.mm.yyyy, fits 375 | - |
| R20 | Disabled buttons app-wide read as disabled (Add at limit, Payments bulk while exporting) | A loading button never fades |
| R21 | Mobile Awaiting budget: amber chip in the back row, no strip below; tap shows the "can still edit" tooltip | Desktop: strip unchanged; Returned: strip unchanged |
| R22 | Excel (sheet, Payments, Analysis): landscape, fit to one page, opens without repair | - |
| R23 | Sheet export HE settlement: "לשלם לעובד" / "לחייב את העובד" | Old wording anywhere in the files |
| R24 | PDF HE totals sit beside the amount (left); EN on the right; Excel the same | - |
| R25 | Long / hostile note: PDF and Excel show capped plain text | - |
| R26 | Payments info icon shown with budgets off too; text starts "Budgets only" / "לתקציבים בלבד" | - |
| R27 | Budgets off: Payments eye on a budget row opens the sheet review, no downloads there | Never the team dashboard |
| R28 | Sheet review from Payments: "Back" / "חזור"; from a deep link: "Back to approvals" | - |
| R29 | Payments: "Settle" / "התחשבנות" buttons; bulk "Settle N sheets" / "התחשבנות ב-N גליונות" | "Process" / "טיפול" on those buttons |

Round 3 CR (independent reviewer, both repos) + security review: no blockers. Fixed: hidden
bidi characters written as char codes in a unit test, plus the PDF document disposed; `GO`
after each banner in all three prod scripts (comments no longer land inside procs);
shake counter auto-disposes; budget back row's trailing part flexible. Kept on purpose:
Excel fit to one page (owner's words). Security review: no findings. Found while fixing: a
note test that passed by accident (culture-aware compare ignores bidi marks) - now ordinal.
Backend 766/766 (6-month scenario included), unit tests green; `flutter test` 280.

### Run 2 - 2026-11-19 (round 3)
- Branch / commit: feature/pc5-sheet-export @ uncommitted (both repos)
- QA company: XpenseDesk Demo Company; manager m@, employee e@, platform admin qa-admin-1@
- Coverage: R14-R29; manager 1440, employee 1440 + 375, EN + HE; budgets #1018 (returned, end date moved 5 months back, then restored), #1017 (Awaiting), #1013 / #1016 / #1020 (Approved), Payments, Analysis, admin company page.
- Data changed and restored: #1018 returned -> end date 19.06.2026 -> back to 15.12.2026 -> submitted for the holder (Awaiting again; its activity keeps the trail); "Allow negative balance" off -> on; Budgets module off -> on; stored sheet exports cleared (14 files - they rebuild on the next download).
- Not covered: the shake animation itself (a widget test proves the tap reaches it; the wobble is the app's existing ShakeOnDemand); R25 long / hostile note on a real line (unit tests cover PDF + Excel); tooltips on a real touch tap.

| # | Lane | Lang | Screen | Severity | Finding | Status |
|---|---|---|---|---|---|---|
| 1 | Manager | EN | Returned budget (someone else's) | Major | A blocked Submit had nothing to shake and the review rows did not say why | Fixed (run 2): reason in the review rows (desktop, compact, cards) and the review list shakes |
| 2 | Manager | EN | Sheet review of a budget (budgets off) | Minor | Blank title - a budget has no cycle | Fixed (run 2): shows "Budget" |

Checked clean: R14 card under Billing, Cancel / Confirm ("Stored files deleted: 14"), title row only Destroy; R15 reason inside rows / cards / compact rows (holder and manager), "Expenses to fix" / "הוצאות לתיקון" fits 375, no summary; R16 7 months "Out of range", 5 months saved, back to 15.12 clears the flag; R17 blocked Submit faded (green / purple), no submit request; R18 purple Submit beside green Approve, Submit on behalf -> Awaiting; R19 header dates with year (1440, 375); R20 disabled Decline (faded pink), "+ New Expense" faded at the limit, no bulk strip; R21 mobile Awaiting chip, no strip; desktop strip unchanged; R22 sheet / Payments / Analysis Excel: landscape + fit to page, well-formed; R23 "לחייב את העובד" / "לשלם לעובד", old wording gone; R24 HE PDF totals beside the amount; R26 icon with budgets off, "Budgets only"; R27 budgets off -> sheet review, no downloads; R28 "Back" from Payments, "Back to approvals" by deep link; R29 "Settle" / "Settle 1 sheet". Console: no exceptions.

Result: 2 findings - 0 open, 2 fixed.
