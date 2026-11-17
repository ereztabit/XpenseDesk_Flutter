# PC-1 - Budgets (petty cash budget sheet) end to end - frontend spec

> Mission: FS-1012 (backend: BackEnd/XpenseDeskServer/docs/petty-cash/pc-1-budget-sheet.md). Plan: BackEnd/XpenseDeskServer/docs/petty-cash/00-plan.md
> **UX source (mandatory):** [pc-1-budgets-ux-handoff.md](pc-1-budgets-ux-handoff.md) - verbatim copy of the Lovable mock's hand-off spec. Same experience, no reinterpretation. When unsure, open the mock (Lovable "Expense Desk", 0c5b063f-74a7-4490-b75e-746f4a712bde).

Status: READY TO BUILD 2026-11-17, in three slices (S1-S3). Not started. PC-0
shipped. The sheet-type navigation bar is already built and shipped
(`docs/completed/sheet-type-nav-spec.md`). UI design is paused; anything not in
the hand-off is out of scope.

## Rules for every slice (user decisions 2026-11-17)

1. **Small, end to end, regressed.** One slice at a time. The next slice starts
   only after this one is banked on `develop` in both repos.
2. **Per slice:** backend first (SQL script -> API guide -> backend + tests),
   then Flutter -> `/code-review` + security review -> `/manual-qa` end to end
   (findings recorded in this file under the slice) -> `finish-feature` in each
   repo. Dark behind the Petty Cash flag.
3. **Branch:** `feature/pc1-sN-<slug>` in both repos, cut by
   `start-full-stack-feature`.
4. **The mock is the experience.** Layout, order, states and behaviour follow
   the hand-off. Visual tokens come from `AppTheme`, buttons from `AppButton`,
   formatting from `format_utils.dart` (see "Copy and formatting").
5. **Reuse, never invent.** Every element below names the existing widget it
   reuses or extends (add a parameter / mode). A new widget is allowed only
   where the table says "new" - and it copies the named pattern. Run the
   CLAUDE.md inventory staleness check first; record reuse in each CR (Rule 7).
6. **Captions** come only from the reviewed copy table below (EN + HE), no ARB
   placeholders (concatenate in the widget).

## Terms

Module on screen: **Budgets / תקציבים** (internal key `pettyCash`, API names
unchanged). One budget = **תקציב**. Statuses: Open, Awaiting approval,
Returned, Approved. "Monthly" for today's cycle sheets. Retired terms - do not
use: "Petty Cash" / "קופה קטנה" on screen, "תקציב מוגדר מראש", "standard
sheet", "group".

## Routes (Flutter)

The mock's React routes map onto the Flutter routes that already exist
(`AppRoutes.budgets`, `budgetPath`, `parseBudgetPath` in
`utils/app_navigator.dart`, `router.dart`):

| Mock | Flutter | Screen |
|---|---|---|
| `/manager/petty-cash` | `/budgets` (manager) | Budgets dashboard (B1) |
| `/manager/petty-cash/list?focus=&attention=1` | `/budgets/list` (+ same query params) | Budget list (B2) |
| `/manager/petty-cash/:id`, `/manager/my-expenses/petty-cash/:id`, `/employee/petty-cash/:id` | `/budgets/<id>` | Budget page (B4). Editable for the holder per status; read-only for anyone else |
| `.../petty-cash/:id/new` | existing new-expense route with the target budget sheet | New expense in budget mode |
| `/manager/petty-cash/report` | not built in PC-1 | The "Budgets report" button is **not shown** until PC-5 (no "designed later" pages in production) |

`BudgetsPlaceholderScreen` is replaced. Every route stays behind `AuthGate` and
the Petty Cash gate (config flag `CompanyConfiguration.isPettyCashEnabled` +
module switch `CompanyModuleKey.pettyCash` - the nav already uses the module
switch; add an `isPettyCashEnabledProvider` copying
`isBulkUploadEnabledProvider`).

## Reuse map (survey 2026-11-17 - re-verify each row when building)

All paths under `lib/`.

| Hand-off element | Reuse | Change needed |
|---|---|---|
| Sheet-type nav (Budgets, All budgets, own budgets with balance) | `widgets/sheet_nav/sheet_type_bar.dart:SheetTypeBar`, `providers/sheet_nav_provider.dart` | Feed real budgets instead of the dev preview (`sheet_nav_dev_provider.dart` stays dev-only); "All budgets" badge = attention count |
| B1 status counters (desktop 3 cards / mobile 1 card) | `widgets/manager_dashboard/counter_card.dart:CounterCard`, `sheet_counter_cards.dart:SheetCounterCards`, `sheets_summary_mobile_card.dart:SheetsSummaryMobileCard` | Labels, counts and taps become parameters (today hard-coded to Monthly); mobile card gets the per-column "View" link |
| B1 attention strip | `widgets/manager_dashboard/awaiting_payment_card.dart:AwaitingPaymentCard` (warning alert card) | Extract a data-driven shell (today reads `paymentsSummary`); one-line variant |
| B1 spend card | `widgets/manager_dashboard/spend_overview_card.dart:SpendOverviewCard` | Extract the shell (today reads the spend provider) |
| Usage meter (B1, B2, B4) | `widgets/manager_dashboard/spend_breakdown_bar.dart:SpendBreakdownBar` | Add the breach style: warning at >= 80%, limit tick + red striped overflow above 100% |
| B2 page (back + title + employee filter, collapsible sections, focus) | `screens/sheet_approvals_screen.dart:SheetApprovalsScreen(initialSection)`, `widgets/manager_dashboard/sheet_bucket_card.dart:SheetBucketCard`, `page_header_row.dart:ManagerPageHeaderRow`, `employee_filter_dropdown.dart:EmployeeFilterDropdown`, `mobile_sheet_bucket_list.dart`, `desktop_sheet_bucket_table.dart` | Budget rows/columns; title param; scroll-to-section (`ensureVisible`, missing today - fixes Monthly too); reason row under attention rows |
| B2 search | `widgets/admin/admin_search_field.dart:AdminSearchField` | none |
| B2 "Needs attention" toggle | `AppButton` (warning look via existing variant) | none - if no warning variant exists, use the existing filter-chip pattern of `employee_dashboard/status_filter_tab_button.dart` |
| B2 desktop table | `widgets/sticky_report_table.dart:StickyReportTable` | Second full-width reason row; inner vertical borders (rows stateless - see its doc comment) |
| Status badge | `widgets/employee_dashboard/sheet_status_badge.dart:SheetStatusBadge(statusId)` | none - same labels as Monthly (user decision 2026-11-17) |
| B3 New budget dialog | Adaptive pattern of `widgets/sheet_review/decline_sheet_dialog.dart:DeclineSheetDialog.show` (dialog desktop / bottom sheet mobile); fields `widgets/payments/dialog_text_field.dart:DialogTextField`, `widgets/payments/dialog_date_field.dart:DialogDateField`; employee picker `widgets/employee/employee_selector.dart:EmployeeSelector(singleSelect)` | Extract the adaptive show() into a shared helper (do not copy it a third time). Employee list must include managers (`companyEmployeesProvider` returns RoleId 2 only). `ExpenseAmountInputFormatter` caps at 10,000 - add a max parameter |
| B4 budget page | `screens/user_dashboard_screen.dart:UserDashboardScreen`, `widgets/employee_dashboard/employee_dashboard_body.dart`, `sheet_expenses_area.dart:SheetExpensesArea(isDraft, isReadOnly, canEdit, canDelete)`, `view_mode_toggle.dart` | Budget mode: hide cycle selector / sheet picker / "My expenses" header button / declined banner; target sheet = the budget |
| B4 header card (stat strip) | **New** `BudgetHeaderCard` - copies `widgets/sheet_review/sheet_review_header_card.dart:SheetReviewHeaderCard` layout + `CounterCard` label/value typography | The one genuinely new card |
| B4 status strip (Awaiting / Returned) | `DeclinedSheetBanner` (employee dashboard) | Add an awaiting (warning) variant; returned variant shows date + reason |
| B4 search | `AdminSearchField` | Merchant-or-amount filter on the loaded list |
| B4 bottom bar (+ Add expenses, green Submit) | `widgets/sheet_review/sheet_review_actions.dart:SheetReviewActions` + `SheetReviewStickyActionBar` (inline desktop, sticky mobile) | Budget actions: the My expenses "+ New Expense" button (primary; header top-right on desktop, sticky bar on mobile) + Submit (success). Monthly has no submit button today (it resubmits automatically) |
| B4 add expenses | `utils/new_expense_launcher.dart:startNewExpense`, `screens/new_expense_screen.dart(targetSheetId)`, `widgets/bulk_upload/bulk_upload_dialog.dart` | Target the budget sheet (single + bulk) |
| B4 Activity card | `widgets/sheet_review/sheet_activity_timeline.dart:SheetActivityTimeline(log)` | none - it already hides while the log is empty |
| Expense detail / new expense back | `screens/employee_expense_detail_screen.dart`, `new_expense_screen.dart`, `form_behavior_mixin.dart:handleBackNavigation` | A return-target parameter so budget expenses go back to `/budgets/<id>` (label "Back to budget"); nav bar hidden on editor screens |
| Manager approve / return (S3) | `screens/sheet_review_screen.dart` as it is today | Accept a budget sheet; no visual change (the budget review screen is not designed) |
| Formatting | `utils/format_utils.dart` (`toCurrency`, `toFormattedNumber`, `toCompanyDate`, `toLongDate`), `widgets/ltr_text.dart:LtrText` | A whole-number currency option for the "whole shekels" places |

## Slices

### S1 - A budget exists

Builds: Petty Cash gate provider; budgets dashboard (counters, attention strip,
spend card, empty state); budget list (header, employee filter, search,
attention toggle, sections with focus, mobile cards, desktop table with reason
rows); New budget dialog; nav fed with real budgets. Budget rows open a budget
page shell (header card only) until S2. **Not in S1:** the row ⋮ menu (submit
on behalf, delete) - PC-2.

Manual QA (end to end, 375px + desktop, EN + HE):
- Flag off -> no Budgets in the nav, routes refuse. Flag on -> Budgets appears.
- Create a budget for an employee and for yourself; validation messages (empty
  fields, amount 0, past date); own budget opens its page and appears in the
  nav with its balance.
- Dashboard counts add up to the number of open budgets; attention strip
  appears for an overdue or negative budget (seed via DB) and opens the list
  filtered.
- List: focus from each counter opens and scrolls to the section; employee
  filter, search by name / #number / employee, attention toggle, clear.
- Monthly dashboard, approvals and My expenses unchanged (regression).

User decisions during S1 build / QA (2026-11-17) - they override the mock:
- Budget names are unique per company, any status (only a deleted budget
  frees a name); duplicate = its own error (`BudgetNameAlreadyExists`).
- Open budget badge reads "Draft / טיוטה", same as Monthly.
- No decimals in the Budgets overviews: whole currency units
  (`toWholeCurrency`) on the dashboard, list, table, section totals, reason
  line and nav. **The budget page shows exact amounts** (user decision
  2026-11-17, replaces "no decimals anywhere"): the header's Budget / Spent /
  Left-or-Over and the balance refusal ("Left: ₪2,323.10") use `toCurrency`,
  like the expense lines under them.
- The budget page header strip shows the currency symbol, and the header shows
  the holder's name.
- The "Needs attention" toggle is shown only when at least one budget needs
  attention (or while it is on).
- The Budgets dashboard opens like the Monthly one: greeting + team line
  (`DashboardGreeting`, `TeammatesStrip` / `InviteBlock`) - Budgets may be the
  company's only module.
- The desktop list table keeps a 1,100px minimum and scrolls sideways when
  the page is narrower - columns are never squeezed.
- For S2: a manager can add expenses to any holder's budget (as on Monthly
  sheets) - someone else's budget is NOT read-only for a manager. Replaces the
  hand-off's "read-only for anyone else".

### S2 - Spend from a budget (single + bulk)

Builds: budget page = My expenses in budget mode (header card complete,
search, expense list, "+ New Expense"); new expense and bulk
upload target the budget; back-to-budget from the editor; nav bar hidden in the
editor; negative-balance refusal message. A manager can add to any holder's
budget (user decision 2026-11-17, replaces "someone else's budget read-only").

Two parts, each with its own CR + QA, on the S1 branch (user decision
2026-11-17):
- **S2a - single expenses:** budget page with its expense list, search and
  bottom bar; single new expense, edit and delete on a budget; Budgets-module
  categories; back to budget; negative-balance refusal; employees see their
  own budgets in the nav.
- **S2b - bulk upload:** bulk upload from the budget page lands in it.
  Aligned with My expenses, nothing new (user decision 2026-11-17): mobile
  "+ New Expense" -> the same choice sheet, "Several receipts" now live; desktop
  gets the My expenses drop strip, free-receipts meter / used-up callout and
  progress strip under the header card - the block is lifted out of
  `MyExpensesHeader` into `BulkUploadEntryArea` and used by both pages. The
  bulk dialog is reused as is, with the budget id passed to the send. Filed
  receipts refresh the budget's list and Spent / Left like My expenses.
  Free receipts: a budget's expenses use the holder's (single and bulk);
  a manager refused for the holder sees "The budget holder has no free
  receipts left" / "...doesn't have enough..." (new captions, below). A
  receipt the budget refuses (over the balance) shows "More than what's left
  in the budget" in the notifications panel.

Nav (user decision 2026-11-17): the sheet-type nav opens on level 1 (the types
row: Monthly expenses / Budgets) on every landing page; level 2 (a type's
pages) shows only after the user picks a type there, and "back" returns to
level 1.

Manual QA:
- Add single and bulk expenses to a budget; balance, Spent, Left / Over budget
  update on the page, list, dashboard and nav.
- An expense that takes the balance below zero is refused with the balance
  shown; editing an amount upward likewise.
- Category picker shows only the Budgets module's active categories.
- Back / save / delete from an expense returns to the budget.
- Manager opens another holder's budget from the list: "Back" to the list, and
  can add / edit / delete its expenses (user decision 2026-11-17). Another
  employee cannot reach it.
- Monthly: new expense and bulk upload from My expenses still land on Monthly.

### S3 - Submit and review

Builds: green "Submit X for approval" in the bottom bar; Awaiting / Returned
status strips; editing allowed while awaiting; Activity card; manager approves
or returns (with reason) on the existing sheet review screen; Approved =
read-only, bar hidden.

Manual QA:
- Holder submits -> Awaiting strip with the date, still editable; Activity
  shows created + submitted.
- Manager returns with a reason -> Returned strip with the reason; holder
  edits and resubmits.
- Manager approves -> Approved, read-only, gone from the dashboard and list.
- A manager holding a budget submits -> approved on submit (Monthly rule).

## Copy and formatting (reviewed 2026-11-17)

Reviewed against the product context with fresh eyes. Changes from the mock
are marked **changed**; the reason is in the last column. ARB keys get a
`budgets` prefix when built; strings with a value are built by concatenation.

### Formatting

- Amounts use `toCurrency(companyLocale, currency)` like every other screen,
  not the mock's hand-made suffix format. Places the mock shows whole shekels
  (dashboard spend card, budget header strip, Submit caption) use a
  whole-number option of the same helper.
- Dates via `toCompanyDate` (short) / `toLongDate` (status strips, Activity).
- Every amount, count, %, #number and date is an LTR island (`LtrText` or
  `TextDirection.ltr`).
- Day counts: 1 -> "1 day" / "יום אחד", 2 -> "2 days" / "יומיים", n -> "n days" / "n ימים".

### Captions

| Where | English | Hebrew | Note |
|---|---|---|---|
| Module / nav | Budgets | תקציבים | |
| Nav level 2 | All budgets | כל התקציבים | |
| B1 header | New budget | תקציב חדש | Mobile caption: New / חדש |
| B1 counters | Awaiting approval · Returned · Open | ממתינים לאישור · הוחזרו · פתוחים | |
| B1 mobile card title | Budgets by status | תקציבים לפי סטטוס | |
| B1 eyebrow (awaiting > 0) | Needs review | דורש בדיקה | existing key |
| B1 mobile column link | View | צפייה | **changed** from "View More / צפה עוד" - imperative Hebrew breaks the gender-neutral rule |
| B1 attention strip | {n} need attention · {n} over budget · {n} overdue | {n} דורשים טיפול · {n} בחריגה · {n} באיחור | zero parts omitted |
| B1 spend card | Spent · {n} open budgets (1: "1 open budget") · Balance | נוצל · {n} תקציבים פתוחים (1: "תקציב פתוח אחד") · יתרה | singular added by user decision 2026-11-17 |
| B1 empty | No open budgets | אין תקציבים פתוחים | + New budget button |
| B2 title / back | Budgets / Back | תקציבים / חזרה | **changed** back from "חזור" (imperative) |
| B2 filter | All employees | כל העובדים | |
| B2 search | Search budget, #number or employee | חיפוש | **changed** "#ID" -> "#number"; Hebrew shortened to "חיפוש" (user decision 2026-11-17, the full hint was cut at 375px) |
| B2 toggle | Needs attention | דורשים טיפול | |
| B2 sections | Awaiting approval · Returned · Open | ממתינים לאישור · הוחזרו · פתוחים | |
| B2 columns | # · Budget name · Employee · Budget · Spent · Balance · End date | # · שם התקציב · עובד · תקציב · נוצל · יתרה · תאריך סיום | **changed** (user decision 2026-11-17): Used % rides in the Spent cell ("₪300  30%"), no column of its own; name cut at 40 characters + "…", full name in a tooltip; columns sized for amounts up to 10,000. Status column dropped (user decision 2026-11-17: each section names the status; the badge overflowed the card) |
| B2 reason row | Overdue {n} days · Over by {amount} | באיחור {n} ימים · חריגה של {amount} | **changed** "{amount} over" -> "Over by {amount}" so both languages read value-last (no placeholders) |
| B2 empty section | No budgets | אין תקציבים | |
| B2 no match | No budgets match · Clear search and filter | לא נמצאו תקציבים תואמים · ניקוי חיפוש וסינון | |
| B3 title | New budget | תקציב חדש | |
| B3 fields | Budget name · Employee · Initial amount · End date | שם התקציב · עובד · סכום התחלתי · תאריך סיום | **changed** amount label drops "(₪)" - the currency comes from the company |
| B3 self | (me) | (אני) | |
| B3 buttons | Cancel · Create budget | ביטול · יצירת תקציב | |
| B3 validation | Required · Amount must be greater than 0 · End date can't be in the past | שדה חובה · הסכום חייב להיות גדול מ-0 · תאריך הסיום לא יכול להיות בעבר | |
| B3 toast | Budget created | התקציב נוצר | |
| Status badge | Draft · Awaiting approval · Returned · Approved | טיוטה · ממתין לאישור · הוחזר · אושר | Same as Monthly (user decision 2026-11-17): `SheetStatusBadge` reused unchanged, existing keys |
| B4 header columns | Budget · Spent · Left / Over budget · Ends / Overdue | תקציב · נוצל · נותר / חריגה · סיום / באיחור | |
| B4 header | Ends {date} | סיום {date} | |
| B4 awaiting strip | Awaiting approval · sent {date} / You can still edit expenses | ממתין לאישור · נשלח ב-{date} / עדיין אפשר לערוך הוצאות | |
| B4 returned strip | Returned for changes · {date} / {reason} | הוחזר לתיקונים · {date} / {reason} | |
| B4 search | Search merchant or amount | חיפוש לפי ספק או סכום | |
| B4 view toggle | View | צפייה | existing key |
| B4 empty list | No expenses in this budget yet / Add a receipt to start using the budget. | עדיין אין הוצאות בתקציב / אפשר להוסיף קבלה כדי להתחיל להשתמש בתקציב. | **changed** from "Welcome aboard! / Click…" - a first-login greeting and an imperative Hebrew sentence on a budget page |
| B4 bar | New Expense · Submit {amount} for approval | הוצאה חדשה · הגשת {amount} לאישור | **changed** (user decision 2026-11-17): the My expenses "+ New Expense" button as is (primary, existing `newExpense` key) - top-right of the header card on desktop, sticky bar on mobile; on mobile it opens the same One receipt / Several receipts sheet (Several receipts live since S2b) |
| B4 submit toast | Submitted for approval | הוגש לאישור | |
| B4 Activity | Activity · Budget created · Submitted for approval · Returned for changes · Approved | פעולות · התקציב נוצר · הוגש לאישור · הוחזר לתיקונים · אושר | Top-up event comes with PC-2 |
| Editor back | Back to budget | חזרה לתקציב | |

### Error messages (one `ApiErrorCodes` key each - backend owns the codes)

| Case | English | Hebrew |
|---|---|---|
| Budget name missing | Enter a budget name | יש להזין שם לתקציב |
| Name taken by another budget of the company, any status (user decision 2026-11-17; caption added in build, not yet reviewed) | A budget with this name already exists | כבר קיים תקציב בשם הזה |
| Employee missing | Choose an employee | יש לבחור עובד |
| Employee not active | This employee isn't active in the company | העובד אינו פעיל בחברה |
| Amount not above 0 | Amount must be greater than 0 | הסכום חייב להיות גדול מ-0 |
| End date in the past | End date can't be in the past | תאריך הסיום לא יכול להיות בעבר |
| Budget not found / deleted | This budget no longer exists | התקציב הזה כבר לא קיים |
| Budget approved (closed) | This budget is approved and closed | התקציב אושר ונסגר |
| Expense takes the balance below zero | This expense is more than what's left in the budget. Left: {balance} | ההוצאה גבוהה מהיתרה בתקציב. נותרו: {balance} |
| Category not in the Budgets module | This category isn't available for budgets | הקטגוריה הזו אינה זמינה לתקציבים |
| Budgets not enabled | Budgets aren't enabled for your company | תקציבים אינם פעילים בחברה שלך |
| Manager files into a budget whose holder has no free receipts left (S2b; caption added in build, not yet reviewed) | The budget holder has no free receipts left. | לבעל/ת התקציב לא נותרו קבלות חינם. |
| Manager's batch bigger than the holder's free receipts left (S2b; not yet reviewed) | The budget holder doesn't have enough free receipts left for this batch. Remove some receipts and try again. | לבעל/ת התקציב לא נותרו מספיק קבלות חינם לשליחה הזו. אפשר להסיר חלק מהקבלות ולנסות שוב. |
| A batch receipt over the balance, in the notifications panel (S2b; not yet reviewed) | More than what's left in the budget | גבוה מהיתרה בתקציב |
| Submit not allowed in this status | This budget can't be submitted right now | אי אפשר להגיש את התקציב כרגע |
| Return without a reason | Write why the budget is being returned | יש לכתוב למה התקציב מוחזר |
| Not the holder / no access | You don't have access to this budget | אין לך גישה לתקציב הזה |

Not ported (mock-only or later slices): report button and page, row ⋮ menu
(submit on behalf, delete), top-up event, Dev Data controls, seed data, the
mock's live-spent simulation.

## Out of scope

Same as the backend story: top-up, edits, holder change, line review, delete
(PC-2); moving expenses (PC-3); unified dashboard (PC-4); report (PC-5);
notifications (PC-6).

## Manual QA

### Run 1 - 2026-11-17 (S1)
- Branch / commit: feature/pc1-s1-budget-exists @ uncommitted
- QA company: XpenseDesk Demo Company; manager m@xpensedesk.com; employee e@xpensedesk.com
- Coverage: manager desktop (800-1280px) + mobile 375 x EN/HE x budgets
  dashboard, list (focus, filter, search, no-match/clear, attention toggle),
  New budget dialog (validation, create for employee / self, duplicate name),
  budget page shell (own + someone else's), nav; employee desktop x EN
  (no Budgets, URLs bounce, Monthly My expenses); flag off (nav + routes);
  Monthly regression (dashboard counters, payment dialog date in HE).
- Attention states (overdue / over budget / awaiting / returned) cannot be
  produced in S1 without expenses or SQL: covered by rewriting the
  `/api/budgets` response in the browser (fetch patch, nothing written).
- Data created: budgets "QA Events" #1001 (holder QA Employee, 2,500, ends
  30/11/2026) and "QA Mine" #1002 (holder QA Manager, 1,000, ends 17/11/2026).
  Demo company Budgets flag switched on (was off) and left on.
- Not covered: past end date via the API (the picker blocks it; Reqnroll
  covers `BudgetEndDateInPast`); name over 100 chars (the field caps it).

| # | Lane | Lang | Screen | Severity | Finding | Status |
|---|---|---|---|---|---|---|
| 1 | Manager desktop | EN/HE | List table | Major | Columns squeezed: # column empty, amounts and status badge clipped, unreadable | Fixed (1,100px min width, sideways scroll, roomier cells) |
| 2 | Manager both | EN | Nav | Major | "All budgets" not tappable from the list or someone else's budget | Fixed (run 1 retest) |
| 3 | Manager both | EN/HE | Budget page | Major | Header strip without currency; holder name missing (user) | Fixed |
| 4 | Manager both | EN/HE | All Budgets amounts | Minor | Decimals not needed (user) | Fixed - whole units everywhere |
| 5 | Manager both | EN/HE | List | Minor | "Needs attention" toggle shown with 0 (user) | Fixed - hidden at 0 |
| 6 | Manager mobile | EN/HE | List rows | Minor | Balance mid-row instead of at the row end | Fixed |
| 7 | Manager mobile | EN | List header | Minor | "All employees" clipped in the filter | Fixed (180px) |
| 8 | Manager mobile | EN | New budget | Minor | "EMPLOYEE" label in filter style, unlike the other labels | Fixed |
| 9 | Manager mobile | HE | List search | Minor | Search hint ellipsised at 375px ("...או עו") | Fixed - Hebrew hint is now "חיפוש" (user) |
| 10 | Manager | EN | Dashboard | Minor | "1 open budgets" (plural for one) - copy table has the plural only | Fixed - singular caption added (user) |

Result: 10 findings - 0 open, 10 fixed.

### Run 2 - 2026-11-17 (S1 retest after fixes)
- Branch / commit: feature/pc1-s1-budget-exists @ uncommitted
- Coverage: manager desktop + 375px x EN/HE - every run-1 fix re-checked on
  screen; plus the user's additions: greeting + team line on the Budgets
  dashboard, "1 open budget" / "תקציב פתוח אחד", Hebrew search hint "חיפוש".
- Post-QA CR (the QA-fix delta): 2 nits, both fixed ("₪12,345" doc example;
  over budget judged on the whole-unit balance, so "₪0" is never red).

Result: clean.

### Run 3 - 2026-11-17 (S2a - single expenses)
- Branch / commit: feature/pc1-s1-budget-exists @ uncommitted (S2a on top of cddd532)
- QA company: XpenseDesk Demo Company; manager m@xpensedesk.com; employee e@xpensedesk.com
- Coverage: manager 375px EN (own budget: empty state, add, edit, over the
  balance, delete, search; another holder's budget: add with no category);
  employee 375px EN/HE (nav, own budget, someone else's budget refused,
  Monthly new expense unchanged); desktop 1280 HE (budget page table + bar).
- Receipts: drawn on a canvas in the page and handed to the app's file picker
  (patched `click()` of the file input, in memory only) - the real AI scan ran
  on them.
- The over-balance refusal was tested by switching the company's "allow
  negative balance" off for the test; it was on (since 15/11) and is restored.
- Data created: QA Mine #1002 - Super Pharm 300 (Refreshments); QA Events #1001
  - Cafe Aroma 64 (Budgets "Other", added by the manager); e@ Monthly
  November - Monthly Taxi 42 (Travel).
- Not covered: swipe-left delete on the mobile card - the browser tool's mouse
  drag does not make a touch fling (the card only shifts); delete was tested
  through the list's delete icon. The carousel swipe is the unchanged Monthly
  widget.

| # | Lane | Lang | Screen | Severity | Finding | Status |
|---|---|---|---|---|---|---|
| 1 | Employee mobile | EN | Nav | Major | A type with a single page (Monthly = My expenses) showed one lone item behind a back arrow (user) | Fixed - shows the types row (Monthly / Budgets) |
| 2 | Employee mobile | EN | Budget page | Blocker | Someone else's budget by URL spun forever: Riverpod 3 retried the 403 in a loop | Fixed - flat-code refusals are not retried; "You don't have access to this budget" |
| 3 | Manager mobile | EN | New expense | Minor | The balance refusal stays shown after lowering the amount, until the next save | Open - same as every save error on this screen (Monthly too) |

Result: 3 findings - 1 open (minor), 2 fixed. Every S2a scenario passes:
budget empty state, add (Budgets categories only, back to budget, header and
nav refresh), edit, over-balance refusal with "Left: ₪700", delete, search
(merchant / no match), manager adds to an employee's budget (default "Other"),
employee nav + own budget, access refused, Monthly expense still Monthly, HE
RTL, desktop table.

### Run 4 - 2026-11-17 (S2a - user review round)
- Branch / commit: feature/pc1-s1-budget-exists @ uncommitted
- QA company: XpenseDesk Demo Company; manager m@xpensedesk.com
- Coverage: manager desktop 1440 EN (landing nav, budget list table, budget
  page); manager 375px EN/HE (budget page, choice sheet, My expenses sheet).
- Not covered: employee lanes (no role-specific change this round).

| # | Lane | Lang | Screen | Severity | Finding | Status |
|---|---|---|---|---|---|---|
| 1 | Manager desktop | EN | Landing nav | Major | Manager landing opened on Monthly's level 2 - no way to Budgets (user) | Fixed - every landing opens on level 1 |
| 2 | Manager desktop | EN | Budget list | Minor | Table scrolled sideways inside the card; Used % took a column (user) | Fixed - Used % in the Spent cell, name 40 chars, Status column dropped, fits the card |
| 3 | Manager both | EN/HE | Budget page | Major | "Add expenses" grey button, no choice sheet, at the bottom on desktop (user) | Fixed - My expenses "+ New Expense": header top-right on desktop, sticky bar + same choice sheet on mobile, "Several receipts" = Coming soon |

Result: 3 findings - 3 fixed. My expenses' sheet still offers Several receipts;
no console errors.

### Run 5 - 2026-11-17 (S2b - bulk upload into a budget)
- Branch / commit: feature/pc1-s1-budget-exists @ uncommitted (S2b on top of a43c189)
- QA company: XpenseDesk Demo Company; manager m@xpensedesk.com
- Coverage: manager 375px EN (employee's budget QA Events: New Expense ->
  Several receipts -> 2 receipts sent, filed live into the budget, owned by
  the employee); manager desktop EN/HE (own budget QA Mine: drop strip ->
  1 receipt over the balance refused, notifications panel); My expenses
  desktop regression (drop strip unchanged).
- Receipts: canvas-drawn, handed to the file picker (patched `click()`); the
  real AI read them. The over-balance case switched "allow negative balance"
  off for the test; it was on and is restored.
- Data created: QA Events #1001 - Cafe Lamed 38, Office Depot IL 74.90 (bulk,
  by the manager, owned by QA Employee).
- Not covered in the app: the holder free-receipt refusals - the Demo company
  is on a paid plan (no limit); covered by `BudgetFreeReceipts.feature` (11
  scenarios). Employee lanes - same widgets and calls as the manager's own
  budget.

| # | Lane | Lang | Screen | Severity | Finding | Status |
|---|---|---|---|---|---|---|
| 1 | Manager desktop | EN/HE | Notifications | Major | A receipt the budget refused (over the balance) read "Couldn't read: heater_receipt.png" - the receipt was read fine | Fixed - listed under its reason: "More than what's left in the budget: heater_receipt.png" / "גבוה מהיתרה בתקציב: ..." |

Result: 1 finding - fixed. Bulk into a budget files every receipt there, Spent
/ Left and the list refresh live, no console errors.

### Run 6 - 2026-11-17 (budget page amounts with decimals)
- Branch / commit: feature/pc1-s1-budget-exists @ uncommitted
- Coverage: manager 375px EN, budget page QA Events (real figures, then a
  forced 5-digit response in memory: ₪12,345.67 / ₪10,176.90 / ₪2,168.77).

| # | Lane | Lang | Screen | Severity | Finding | Status |
|---|---|---|---|---|---|---|
| 1 | Manager mobile | EN | Budget page | Major | Header rounded to whole shekels (₪177 spent of lines summing ₪176.90) (user) | Fixed - exact amounts, decimals shown |
| 2 | Manager mobile | EN | Budget page | Minor | A long amount with decimals would be cut with "…" in a quarter-width column | Fixed - the value shrinks to fit, no digit hidden |

Result: 2 findings - 2 fixed.
