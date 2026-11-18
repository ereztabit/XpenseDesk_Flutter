# PC-2 - Budget sheet manager control + audit

> Mission: FS-1013 (backend: BackEnd/XpenseDeskServer/docs/petty-cash/pc-2-manager-control.md - decisions, API rules, error codes). Plan: BackEnd/XpenseDeskServer/docs/petty-cash/00-plan.md. API: [budgets-api-guide.md](../api-guides/budgets-api-guide.md)

Status: IN PROGRESS 2026-11-18 on `feature/pc2-manager-control`.

No Lovable design round (user decision 2026-11-18): every piece reuses an
existing widget. Top-up is dropped. The B2 row menu and delete dialog follow
the mock as recorded in
[pc-1-budgets-ux-handoff.md](../completed/pc-1-budgets-ux-handoff.md) §2.2.

## Requirements

| # | Requirement | Reuses |
|---|---|---|
| F1 | **Edit budget** - manager, budget not Approved: an "Edit" button on the budget page header card (desktop next to "+ New expense"; mobile in the card's top row) opens the New budget dialog in edit mode, prefilled. Title "Edit budget", button "Save". Past end date is only an error when it was changed. | `NewBudgetDialog` + `NewBudgetFormFields` (edit mode) |
| F2 | **Negative amount** - when the new amount is below "spent": negatives allowed -> confirm "The balance will be {amount} below zero. Save anyway?"; not allowed -> the server's `BudgetAmountBelowSpent` shows in the dialog. | `showAppConfirmDialog` / the dialog's `ErrorAlert` |
| F3 | **Row menu** on the budget list (table ⋮ column and mobile card ⋮): "Submit for approval" (Draft / Returned only) and "Delete" (destructive). Submit -> toast "Submitted for approval". | the user-management row menu pattern |
| F4 | **Delete** - confirm "Delete budget?" / "\"{name}\" and all its expenses will be removed. Recovery is possible only through support." / Cancel + "Delete budget" -> toast "Budget deleted", list refreshes. | app confirm dialog (destructive) |
| F5 | **Line review** - a manager who is not the holder sees the budget's expenses as the review line list (Pending / Approved / Declined tabs, approve / decline / edit / delete per line) while the budget is not Approved. The holder keeps today's My-expenses list. | `SheetReviewLineSection` + the review screen's line handlers |
| F6 | **Activity** - shown once the log has more than one entry (was: after the first submission). New entries: "Name changed: {old} -> {new}", "Holder changed: {old} -> {new}", "End date changed: {old} -> {new}", "Amount changed: {old} -> {new}", "Expense approved: {merchant} {amount}", "Expense declined: {merchant} {amount}". Status strips and the "sent" / "returned" dates read status entries only. | `SheetActivityTimeline` / `...Entry` |
| F7 | Every refusal code of the API guide maps to its own EN + HE caption. | `budgetErrorText` |

## Bugs folded in (filed for PC-2)

- [budget-balance-error-uses-user-currency.md](../bugs/budget-balance-error-uses-user-currency.md)
- [budget-id-from-url-not-validated.md](../bugs/budget-id-from-url-not-validated.md)
- [approved-budget-page-has-no-way-back-for-holder.md](../bugs/approved-budget-page-has-no-way-back-for-holder.md)

## Copy (EN / HE)

| Key | EN | HE |
|---|---|---|
| budgetsEdit | Edit | עריכה |
| budgetsEditTitle | Edit budget | עריכת תקציב |
| budgetsSave | Save | שמירה |
| budgetsSavedToast | Budget updated | התקציב עודכן |
| budgetsNegativeTitle | Balance below zero | יתרה שלילית |
| budgetsNegativeBody | The balance will be {amount} below zero. Save anyway? | היתרה תהיה {amount} מתחת לאפס. לשמור בכל זאת? |
| budgetsMenu | Budget actions | פעולות תקציב |
| budgetsSubmit | Submit for approval | הגשה לאישור |
| budgetsDelete | Delete | מחיקה |
| budgetsDeleteTitle | Delete budget? | מחיקת התקציב? |
| budgetsDeleteBody | "{name}" and all its expenses will be removed. Recovery is possible only through support. | "{name}" וכל ההוצאות שלו יימחקו. שחזור אפשרי רק דרך התמיכה. |
| budgetsDeleteConfirm | Delete budget | מחיקת תקציב |
| budgetsDeleted | Budget deleted | התקציב נמחק |
| budgetsEvRenamed | Name changed | השם שונה |
| budgetsEvHolder | Holder changed | המחזיק הוחלף |
| budgetsEvEndDate | End date changed | תאריך הסיום שונה |
| budgetsEvAmount | Amount changed | הסכום שונה |
| budgetsEvLineApproved | Expense approved | הוצאה אושרה |
| budgetsEvLineDeclined | Expense declined | הוצאה נדחתה |
| budgetsErrAmountBelowSpent | The amount is lower than what was already spent, and this company doesn't allow a negative balance. | הסכום נמוך ממה שכבר נוצל, והחברה לא מאפשרת יתרה שלילית. |

## Manual QA

### Scenario map (FS-1013)

Lanes per the `manual-qa` skill: A manager desktop, B manager mobile, C employee
desktop, D employee mobile; every screen EN then HE. QA company: XpenseDesk Demo
Company (dev), m@ / e@xpensedesk.com. Data created through the UI in lane A.

| # | Lanes | Scenario | Expect |
|---|---|---|---|
| Q1 | A, B | Budget list: row ⋮ on a Draft / Returned budget | "Submit for approval" + "Delete"; on Awaiting only "Delete"; 32px button, no overflow at desktop and 375px |
| Q2 | A | ⋮ Submit for approval on e@'s Draft budget | toast "Submitted for approval"; row moves to Awaiting; the budget page shows Awaiting; Activity shows "Submitted for approval" by the manager |
| Q3 | A, B | ⋮ Delete -> dialog "Delete budget?" with the name -> Cancel, then Delete budget | Cancel keeps it; Delete -> toast "Budget deleted", row gone, counters update; opening its old link -> "This budget no longer exists" |
| Q4 | A | Budget page (e@'s budget): "Edit" -> dialog prefilled, title "Edit budget", button "Save" | all four fields prefilled; Save without changes closes, no new Activity entry |
| Q5 | A | Edit name, holder (to m@ -> back), end date, amount -> Save | toast "Budget updated"; header shows new values; Activity card appears with one entry per change, "old -> new" (dates/amounts formatted, arrow mirrored in HE) |
| Q6 | A | Edit amount below spent, company does NOT allow negative | inline error "The amount is lower than what was already spent..." (EN + HE); nothing saved |
| Q7 | A | Same with the setting allowing negative (company config -> modules) | confirm "Balance below zero" / "The balance will be X below zero." -> Continue saves; header shows the negative balance in red; Cancel saves nothing |
| Q8 | A | Edit: a past end date typed into a changed date | date error; an overdue budget can still be renamed without touching its date |
| Q9 | A, B | Manager on e@'s Awaiting budget: line list is the review list (Pending / Approved / Declined tabs) | approve one line -> moves to Approved, budget still Awaiting; decline -> Declined, spent drops; Activity "Expense approved/declined: merchant amount" |
| Q10 | A | Re-approve a declined line that no longer fits (negatives off) | snackbar with the "more than what's left" message and the budget's balance |
| Q11 | A | Tap a line in the review list | opens the manager expense editor; Back returns to the budget page refreshed |
| Q12 | A | Approve the whole budget | Edit button and line actions gone; ⋮ gone (budget leaves the list) |
| Q13 | C, D | e@ on own budget: no Edit button, no ⋮ (no list access), My-expenses list unchanged | role leak = Blocker |
| Q14 | C, D | e@ opens own approved budget by link | "Back" shown, goes to the employee dashboard (bug fix) |
| Q15 | C | e@ adds an expense that exceeds the balance | error amount in the budget's currency (bug fix) |
| Q16 | C | `/budgets/not-a-guid` typed in the address bar | not a budget page (no API call with the raw segment) - bug fix |
| Q17 | C, D | e@'s budget after a manager edit | Activity visible with the edits; a fresh budget with only "created" shows no Activity |
| Q18 | all | HE pass of every screen above | no English, RTL correct, amounts / dates / emails LTR |

(runs recorded below by `/manual-qa`)

### Run 1 - 2026-11-18
- Branch / commit: feature/pc2-manager-control @ f457912 + uncommitted
- QA company: XpenseDesk Demo Company; manager m@xpensedesk.com; employee e@xpensedesk.com
- Coverage: lanes A-D x EN/HE x budget list (table + mobile cards, row menu, delete dialog), budget page (manager review list, holder list, approved), Edit budget dialog / sheet, negative-balance confirm, company config modules, new expense on a budget, expense editor; Q1-Q17 run, Q18 HE pass on list, menu, delete dialog, budget page, Edit dialog + BudgetAmountBelowSpent error, Activity
- Not covered: Q15 cannot tell the bug fix apart - company and e@ are both ILS (error showed "Left: ₪50.00"); HE not checked for the Q7 confirm dialog and the Q10 snackbar; Q2 submit and Q3 real delete on desktop only (mobile: menu + dialog + Cancel); Q16 shows the login screen to a signed-in user - same for any unknown route (`/some-unknown-route`), not PC-2
- Data changed: budgets QA PC2 Review #1005 (approved, 1 line declined), QA PC2 Edited #1007 (amount 50, line declined), QA PC2 Fresh #1008 (no lines), QA PC2 Delete #1006 (deleted); "QA Mine" renamed "QA Mine PC2" (Q8); PettyCash AllowNegativeBalance toggled and restored to on

| # | Lane | Lang | Screen | Severity | Finding | Status |
|---|---|---|---|---|---|---|
| 1 | A, C, D | EN + HE | Budget page - approved list / holder My-expenses | Major | A declined line shows with no Declined status: approved #1005 lists ₪60.00 + ₪87.50 while Spent is ₪87.50; e@'s draft #1007 lists ₪100.00 while Spent is ₪0.00 and the button reads "Submit ₪0.00 for approval" | Fixed (run 2) |
| 2 | A | EN | Budget page -> tap line -> expense editor -> Back | Major | Console: Riverpod "setState() or markNeedsBuild() called during build" (UncontrolledProviderScope, built in _OverlayEntryWidget, via `_updateTickerMode`) on every return; the page itself refreshes fine. Not checked whether Monthly review does the same | Fixed (run 2) |
| 3 | A | EN | Budget list - Open / Awaiting tables at 1440 | Major | Table overflows: the ⋮ column is reachable only after horizontal scroll, and `#1005` is cut to `#10…` (Q1 expects no overflow at desktop) | Fixed (run 2) |
| 4 | B | EN + HE | Budget page - manager review list, mobile | Minor | Default card view shows only Edit per line; approve / decline / delete appear only after switching to the compact view | Won't fix - Monthly review widget design; swiping a card reveals Decline / Delete (run 2) |
| 5 | A | EN + HE | Budget page - review list status pill | Minor | Status pill wraps mid-word at 1440: "Pen/ding", "Appro/ved", "Decl/ined", "ממת/ין" | Fixed (run 2) |
| 6 | A | EN | Edit budget - Save with no changes | Minor | Sends PUT and shows "Budget updated" although nothing changed (server writes no audit row, so no Activity entry) | Fixed (run 2) |

Result: 6 findings - 6 open, 0 fixed.

### Run 2 - 2026-11-18
- Branch / commit: feature/pc2-manager-control @ f457912 + uncommitted (fix round after run 1, dev server restarted)
- QA company: XpenseDesk Demo Company; manager m@xpensedesk.com; employee e@xpensedesk.com
- Coverage: re-check of run 1 findings 1-6 in their lanes + HE - lane A (list at 1440, budget page review list, Edit dialog, expense editor Back), lane B (mobile card swipe), lane C (e@ approved #1005, desktop), lane D (e@ approved #1005, mobile HE); Q7 and Q10 in HE
- Not covered: the name-column tooltip for long names (no QA budget has a name long enough to truncate)
- Data changed: #1007 line re-approved (Spent ₪100 on a ₪50 budget); PettyCash AllowNegativeBalance toggled and restored to on

| # | Lane | Lang | Screen | Severity | Finding | Status |
|---|---|---|---|---|---|---|
| - | A, C, D | EN + HE | Budget page - holder / approved list | - | Run 1 #1: Pending / Approved / Declined tabs show once a line is decided, open on the first non-empty tab, declined line under Declined, empty tab "No expenses in this view." / "אין הוצאות בתצוגה זו."; pending-only budget (#1004) shows no tabs | Verified |
| - | A | EN + HE | Review list -> editor -> Back | - | Run 1 #2: no "called during build" error after Back (EN and HE); page refreshes | Verified |
| - | A | EN + HE | Budget list at 1440 | - | Run 1 #3: no horizontal scroll, ⋮ visible, `#1002` / `#1007` in full | Verified |
| - | A | EN + HE | Review list status pill | - | Run 1 #5: "Declined" / "Approved" / "נדחה" on one line (page 1100 wide) | Verified |
| - | A | EN | Edit budget - Save with no changes | - | Run 1 #6: dialog closes, no PUT, no toast | Verified |
| - | B | EN | Review list, mobile cards | - | Run 1 #4: swiping a card reveals Decline / Delete (Monthly widget design) | Noted |
| - | A | HE | Q7 / Q10 | - | Q10 HE snackbar "ההוצאה גבוהה מהיתרה בתקציב. נותרו ₪50.00"; Q7 HE confirm "יתרה שלילית" / "היתרה תהיה ₪60.00 מתחת לאפס. לשמור בכל זאת?", Cancel saved nothing (no PUT) | Verified |

Result: clean - run 1 findings 1, 2, 3, 5, 6 fixed; 4 kept by design; no new findings.

### Run 3 - 2026-11-18
- Branch / commit: feature/pc2-manager-control @ f457912 + uncommitted (user-feedback round: F1-F5; backend allows end date up to 30 days back)
- QA company: XpenseDesk Demo Company; manager m@xpensedesk.com
- Coverage: lane A (manager desktop) EN + HE - New / Edit budget dialogs, budget list table, row ⋮ Edit, budget page Activity, list Back + browser back; lane B (manager mobile width) EN - card ⋮ Edit, list Back + browser back with a collapsed section and scroll
- Not covered: lanes C / D (no employee-facing change); the client "End date can't be more than 30 days ago" error - the picker greys out 31+ days back (Oct 18 disabled, Oct 19 pickable), so the check can't be reached from the UI; the 1440x900 lane A size - the pane was narrowed and resized during the run (the app cleared the 1440 emulation twice and 1440 rendered unreadably small), so lane A ran at 800x700 (still the desktop layout) and the list table was read at 1440 through the semantics tree
- Note on run 2: its "no PUT" checks (#6 untouched Save, Q7 Cancel) filtered network requests by the text "PUT", which matches URLs, not methods - weak evidence. Re-checked here properly: an untouched Save sent no request for that budget
- Data changed: created QA PC2 Past #1009 (end 10/19/2026, 30 days back; amount then edited 1,500 -> 1,600); #1007 amount 1,500 -> 2,500; #1008 amount 50 -> 2,500 and end date 11/30 -> 10/19/2026

| # | Lane | Lang | Screen | Severity | Finding | Status |
|---|---|---|---|---|---|---|
| - | A, B | EN + HE | New / Edit budget dialog - amount | - | F1: digits left in EN, right in HE; Edit prefills "1,500" / "50"; typing 2500 shows "2,500"; untouched Save sends no PUT | Verified |
| - | A | EN + HE | Budget list table - Spent | - | F2: "₪100 (7%)" / "₪0 (0%)"; RTL order and parentheses correct in HE | Verified |
| - | A, B | EN + HE | List row ⋮ / mobile card ⋮ - Edit | - | F3: first item Edit opens the dialog prefilled; Save -> "Budget updated" / "התקציב עודכן", row shows the new amount and balance | Verified |
| - | A | EN + HE | Date picker / create / edit | - | F4: Oct 19 (30 days back) pickable, Oct 18 greyed; budget created with it; edit to 19.10.2026 saved, Activity shows "End date changed 30.11.2026 -> 19.10.2026" and the amount change | Verified |
| - | A, B | EN + HE | List -> budget -> Back / browser back | - | F5: collapsed section, scroll position and UI language kept on both Back paths; long-name tooltip shows on hover | Verified |

Result: clean.
