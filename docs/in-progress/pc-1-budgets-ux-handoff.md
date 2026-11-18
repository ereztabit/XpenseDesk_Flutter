# Budgets (Petty Cash) — Build Hand-off Spec (copied from the Lovable mock)

> **Mandatory UX source for PC-1.** Verbatim copy of the Lovable app mock
> ("Expense Desk", project 0c5b063f-74a7-4490-b75e-746f4a712bde) file
> `public/petty-cash-budgets-dashboard-spec.md` at mock commit 44ddee4
> (2026-11-17). The Flutter build must give the same experience. Where this
> copy and the mock disagree, the mock wins — open it in Lovable.
> Mock route names and React component names below are the mock's; the Flutter
> routes and the widgets to reuse are mapped in
> [pc-1-budget-sheet-spec.md](pc-1-budget-sheet-spec.md). The copy table in §4
> is superseded by the reviewed copy table in that spec.

---

# Budgets (Petty Cash) — Build Hand-off Spec

> Single source of truth for the Budgets module as the mock behaves at commit 219e628. Supersedes `petty-cash-all-budgets-spec.md` and every earlier version of this file. The mock is the mandatory reference for the experience; this document describes it, it does not add design.

Internal key `pettyCash`; display name "Budgets" / "תקציבים". A budget is a fixed amount given to one holder (employee or manager) until an end date. The holder records expenses against it, then submits it for approval.

---

## 1. Overview and routes

| Route | Renders | Who | Notes |
|---|---|---|---|
| `/manager/petty-cash` | `BudgetsDashboard` (B1) | Manager | Always the dashboard. |
| `/manager/petty-cash/list?focus=submitted\|returned\|draft&attention=1` | `BudgetsList` (B2) | Manager | Both params optional. |
| `/manager/petty-cash/report` | `BudgetsReportPage` placeholder | Manager | "Budgets report" + "Designed in a later round". Not in scope. |
| `/manager/petty-cash/:budgetId` | `ManagerBudgetViewPage` → `EmployeeDashboard` in budget mode (B4) | Manager | Any holder's budget, opened from B2. Back link to `/manager/petty-cash/list`. **Read-only when the holder is not the current manager.** |
| `/manager/my-expenses/petty-cash/:budgetId` | `ManagerMyPettyCashBudgetPage` → `EmployeeDashboard` in budget mode (B4) | Manager (holder) | Manager's own budget. Editable per status rules. |
| `/manager/my-expenses/petty-cash/:budgetId/new` | `NewExpense` bound to the budget | Manager (holder) | |
| `/employee/petty-cash/:budgetId` | `EmployeeBudgetPage` → `EmployeeDashboard` in budget mode (B4) | Employee (holder) | |
| `/employee/petty-cash/:budgetId/new` | `NewExpense` bound to the budget | Employee (holder) | |
| Expense detail/edit (`/employee/expense/:id`, `/manager/my-expenses/:id`) | `EmployeeExpenseDetail` | Holder | Budget expenses return to their budget page (§2.5). |

Budget mode is a flag on the viewer (`budgetId`, `budgetReadOnly`, `backPath`). It reuses the My expenses screen; nothing about Monthly sheets changes.

**Read-only rules**
- Someone else's budget (manager viewing from B2): read-only list, no bottom bar, no add/edit/delete.
- Approved budget (any viewer): read-only, no bottom bar.
- Open (draft), Returned and Awaiting approval: editable by the holder (add / edit / delete / bulk upload).

Statuses (internal → label): `draft` → Open (badge "Draft"/"טיוטה"), `submitted` → Awaiting approval, `returned` → Returned, `approved` → Approved. Approved budgets are not "outstanding" and do not appear on B1/B2.

---

## 2. Screens

### 2.1 B1 — Budgets dashboard (`/manager/petty-cash`)

**Layout.** Same container as the Monthly dashboard (`page-container`, vertical gap 12px mobile / 16px desktop). Single column at every width.

**Elements, in order**
1. **Header row** — title "Budgets" (start). At the end: outline "Budgets report" button (desktop: icon + label; below 640px icon-only 44×44 with aria-label) → `/manager/petty-cash/report`; primary "+ New budget" (below 640px caption "New") → opens B3.
2. **Status counters** (copy of `SheetCountersRow`)
   - ≥640px: 3 equal cards in one row — Awaiting approval (Clock) · Returned (RotateCcw) · Open (Wallet). Big count, label under it. Awaiting with count > 0 is warning-styled (warning border, warning/5 fill, warning count) with eyebrow "needs review".
   - <640px: one card titled "Budgets by status", a 3-column mini table (icon, count, label, "View More ›" link per column).
   - Each tile/column → `/manager/petty-cash/list?focus=<status>`.
3. **Attention strip** (only when ≥1 budget needs attention) — full-width one-line button, min 44px, warning outline + warning/5 fill, AlertTriangle at start, chevron at end (mirrors in RTL). Text: "{n} need attention · {n} over budget · {n} overdue" — zero parts omitted. → `/manager/petty-cash/list?attention=1`.
4. **Spend card** — Wallet icon in a primary/10 circle; caption "Spent"; big "spent / total" and usage % (destructive when > 100%); `UsageBar`; caption "{n} open budgets · Balance {balance}" (balance destructive when negative). **All amounts here in whole shekels** (e.g. "122,095₪ / 197,000₪").

**States**
- Empty (no outstanding budgets): items 2–4 replaced by one card — Wallet icon, "No open budgets", primary "+ New budget".
- No attention budgets: strip hidden.

**Interactions** — see items above. Creating a budget: §2.3.

### 2.2 B2 — Budget list (`/manager/petty-cash/list`)

**Layout.** Sheet Approvals pattern. Single column.

**Elements, in order**
1. **Header row** — ghost back button (44px, ArrowLeft mirrors in RTL, aria "Back") → `/manager/petty-cash`, title "Budgets" (truncates). At the end: employee filter `Select` (~160px, Filter icon): "All employees" + holder names (alphabetical).
2. **Search row** — search field (44px, Search icon, placeholder "Search budget, #ID or employee", clear X when filled) + at its end the **Needs attention toggle**: warning outline button with AlertTriangle, label "Needs attention" (hidden below 640px) and a count pill (LTR). Pressed = solid warning fill, `aria-pressed=true`. Count = attention budgets after employee filter + search.
3. **Sections** — three collapsible cards in this order: Awaiting approval · Returned · Open. Header: title, "(count)", section balance total (destructive when negative), chevron (rotates when open).
4. **Rows inside a section**
   - **<768px — cards** (divided list): line 1 name (truncate) + muted "#number" and the balance at the end (destructive when negative, 2 decimals); line 2 holder name (max 40%), `UsageBar`, "%" (destructive when > 100%); line 3 (attention only) destructive reason with a 14px AlertTriangle: "Overdue {n} days · {amount} over"; line 4 status badge. ⋮ menu (44px) at the end. No extra border on attention cards.
   - **≥768px — table** with inner vertical borders (logical end borders, none on last column). Columns: # · Budget name (truncate, full name in title) · Employee · Status · Budget (initial + top-ups) · Spent · Balance · Used % · End date (dd/mm/yyyy) · ⋮. An attention budget gets a **second row** directly under it: one cell spanning all columns, destructive/5 fill, destructive 12px text, AlertTriangle + reason. The two rows have no border between them, hover together and both open the budget.
   - Row tap/click → `/manager/petty-cash/:budgetId`.
   - ⋮ menu: "Submit for approval" (Open/Returned only) → status Awaiting, toast "Submitted for approval"; "Delete" (destructive) → AlertDialog "Delete budget?" / body with the name / "Cancel" + "Delete budget" → toast "Budget deleted".

**Sorting inside a section:** attention first, then end date ascending.

**States**
- `focus` param: that section open, others collapsed, scrolled to, ringed in primary. No focus: all open.
- `attention=1`: toggle on → each section shows only its attention budgets.
- Empty section: "No budgets".
- Nothing matches (filter/search/toggle): card with Search icon, "No budgets match", outline "Clear search and filter" (clears search, employee and toggle).

### 2.3 B3 — New budget dialog

**Layout.** Same structure as `CategoryDialog`: centred `Dialog` (max-w-md) on desktop; bottom `Sheet` (rounded top, max 90vh, scrolls) below 768px. Fields 44px on mobile, 40px desktop.

**Elements, in order** — title "New budget"; Budget name (text); Employee (`Select` of non-disabled company users; the current manager suffixed " (me)"); Initial amount (₪) (numeric, LTR); End date (native date, LTR, min today); footer "Cancel" (outline) + "Create budget" (primary).

**Validation** (inline under each field, red; all shown after the first Create attempt; amount/date errors also appear live once a value is typed)
- Every field required → "Required".
- Amount > 0 → "Amount must be greater than 0".
- End date ≥ today → "End date can't be in the past".

**On create** — new budget: status Open, next number (= highest + 1, starting after 1000), spent 0, top-ups 0, balance = amount. Toast "Budget created". If the holder is the current manager, it is also added to the manager's own budgets (nav) and the app navigates to `/manager/my-expenses/petty-cash/:id`. Otherwise the user stays on B1.

### 2.4 B4 — Budget page (My expenses in budget mode)

The existing My expenses screen (`EmployeeDashboard`) bound to one budget. Same expense list (desktop `ExpensesTable`, mobile cards/carousel), same single + bulk upload, same expense detail. **Removed in budget mode:** cycle selector/widget, sheet dropdown, "My Expenses" title, header "+ New expense" button, returned-sheet alert, Monthly reopen banner.

**Layout.** Single column. Page has extra bottom padding (160px mobile / 96px desktop) so content scrolls clear of the fixed bottom bar.

**Elements, in order**
1. **Back link** (only from B2, i.e. `/manager/petty-cash/:id`) — "Back" with ArrowLeft (mirrors), 44px target → `/manager/petty-cash/list`.
2. **Header card — stat strip** (`BudgetHeaderCard`)
   - Row 1: budget name, full width, wraps on long names, muted "#1002" right after it (LTR island).
   - Row 2: status badge + muted 11px "Ends 31/12/2026" (dd/mm/yyyy).
   - Top border, then **4 equal columns** with thin logical separators: Budget · Spent · Left/Over budget · Ends. Labels 11px muted; values 15px semibold (14px below 640px), whole numbers with thousands separators, no currency sign, LTR, truncate if needed. Fits 375px.
     - Budget = initial + top-ups.
     - Third column: balance ≥ 0 → "Left" + value. Balance < 0 → label "Over budget" with a 12px TrendingDown icon (destructive), value = overrun **without minus**, destructive.
     - Fourth column: not overdue → "Ends" + "31/12". Overdue → label "Overdue" with a 12px CalendarClock icon (destructive), value "{n} days", destructive.
   - 4px `UsageBar` flush at the card's bottom edge, square corners.
3. **Status strip** (`BudgetStatusStrip`, directly below the card, full width, rounded, 1px border)
   - Awaiting approval: warning tint (warning/10 fill, warning/30 border), Clock icon (warning). Line 1 "Awaiting approval · sent 15 November 2026" (date = latest `submitted` history entry, long format); line 2 muted "You can still edit expenses".
   - Returned: destructive tint, Undo icon (destructive). Line 1 "Returned for changes · 10 November 2026" (latest `returned` entry); line 2 muted = the return reason.
   - Open / Approved: no strip.
4. **Search row** (only when the budget has ≥1 expense) — 36px input, Search icon at start, clear X at end, placeholder "Search merchant or amount". Mobile: flex-1; desktop: max 320px. Matches merchant name OR amount substring ("60" matches 60, 60.5, 160). No result counter. At the inline end of the row (mobile only, when editable and there are expenses): the list/carousel view toggle, 36×36 outline icon button (List / GalleryVertical), aria "View".
5. **Expense list** — existing component. Amounts in budget mode show "X.XX₪" (2 decimals, ILS suffix). Empty state is the existing one (Sparkles, "Welcome aboard!" + description, "+ New Expense" when allowed).
6. **Activity card** (`BudgetActivity`) — hidden until the budget has at least one `submitted` event. Title "Activity". Vertical timeline, oldest first: 10px filled primary dot, thin connecting line; per entry bold event name, muted "{actor} · {17 November 2026}", optional muted reason (returns). Events: "Budget created", "Top-up {amount}", "Submitted for approval", "Returned for changes", "Approved".
7. **Bottom action bar** (`BudgetActionBar`) — fixed to viewport bottom, full width, background, top border, small shadow, 12px padding, inside the page container. Mobile: buttons stacked full width (gap 8px). ≥768px: side by side, end-aligned. Buttons 44px.
   - "+ Add expenses" — outline, primary border and text, medium weight. Desktop → new-expense page for this budget; mobile → existing single/bulk choice sheet. Disabled when adding is not allowed.
   - "Submit {8,517₪} for approval" — green (success fill, success-foreground text, hover success/90), Send icon. Amount = live spent, whole shekels, LTR island. Shown for Open and Returned only. Tap → status Awaiting approval, appends a `submitted` history entry (actor = holder, today), toast "Submitted for approval".
   - Awaiting approval: only "+ Add expenses".
   - Approved, or someone else's budget: bar not rendered (and bottom padding unused).

**States summary**

| State | Header card | Status strip | Bottom bar | Editing |
|---|---|---|---|---|
| Open | normal | — | Add + Submit | yes |
| Awaiting approval | normal | warning, sent date | Add only | yes |
| Returned | normal | destructive, date + reason | Add + Submit | yes |
| Approved | normal | — | none | no |
| Someone else's (B2) | normal + Back link | per status | none | no |
| Over budget | 3rd column "Over budget", destructive, TrendingDown; meter red striped overflow | — | unchanged | per status |
| Overdue | 4th column "Overdue", "{n} days", CalendarClock | — | unchanged | per status |
| No expenses | normal | per status | per status | search row hidden; existing empty state |
| Search no results | normal | per status | per status | list empty |

### 2.5 Expense editor for budget expenses
- Single new expense (`…/petty-cash/:budgetId/new`) and bulk upload create expenses tagged with the `budgetId` (no Monthly sheet id), currency ILS.
- Budget expenses never appear in Monthly sheets, Monthly totals, spend overviews or Monthly reports.
- Expense detail/edit and new expense: back link "Back to budget" returns to the budget page the user came from (router state), fallback derived from the expense's `budgetId` (`/manager/my-expenses/petty-cash/:id` or `/employee/petty-cash/:id`). Save and delete also return there. Monthly expenses keep "Back to Dashboard".
- The sheet-type nav bar is hidden on all expense editor pages (Monthly and budgets alike).

### 2.6 Sheet-type nav — budget-specific parts (full nav spec: `sheet-type-nav-spec.md`)
- Level 1 "Budgets" pill (mobile short label "Budgets"); badge for managers = All budgets attention count.
- Level 2 for Budgets: Back · "All budgets" (managers only, wallet icon, → `/manager/petty-cash`) · one item per budget held by the current user: dot (success; destructive when balance < 0) + name + live balance on a second line (LTR, 2 decimals, destructive when < 0).
- "All budgets" badge = outstanding budgets that are negative OR overdue (red when > 0).
- "All budgets" stays highlighted on B1, B2, the report page and `/manager/petty-cash/:id`; the user's own budget item is highlighted on its budget page.
- Mobile: "All budgets" / "כל התקציבים" always in full on ONE line (button widens, min 88px; never wrapped or shortened). Budget items wrap name to max 2 lines (max 120px) with the balance always visible.
- Scrolling row: the active budget scrolls into view horizontally; the first level-2 item ("All budgets", or "Team expenses" on Monthly) is never left half-cut — it is either fully revealed (when the active item still fits) or scrolled fully out.
- Desktop budget pills: name max 180px with ellipsis, full name in title/aria-label.

---

## 3. Reused components (mock)

| Element | Reuses / extends | What was added |
|---|---|---|
| B1 page shell | Monthly `ManagerDashboard` V2 layout | Budget data only. |
| B1 status counters (`BudgetCountersRow`) | Copy of `SheetCountersRow` (desktop cards + mobile mini-table card) | Budget statuses; exclusive counts. |
| B1 attention strip (`BudgetAttentionCard`) | `AwaitingPaymentCard` (warning alert card), compacted to one line | Composite "need attention · over · overdue" text. |
| B1 spend card (`BudgetSpendCard`) | Dashboard spend figure card (`SpendOverviewCompare` / Approved Spend card) | Uses `UsageBar`; whole-shekel formatter. |
| B1 empty state | Existing empty-card pattern | — |
| B2 page | Monthly Sheet Approvals / `ManagerDashboard` collapsible sections, header with back + employee `Select` | Budget columns, attention toggle, reason row. |
| B2 desktop table | Spreadsheet table pattern of `ExpensesTable` / cycle report | Inner vertical borders, second "reason" row. |
| B2 mobile cards | Mobile expense card list pattern | Usage bar + reason line. |
| B2 row menu / delete | `DropdownMenu` + `AlertDialog` (as in user management / sheets) | — |
| Status badge (`BudgetStatus`) | `SheetStatusBadge` | "Returned" uses the existing rejected tone. |
| B3 dialog (`NewBudgetDialog`) | `CategoryDialog` (Dialog desktop / bottom Sheet mobile) | Budget fields + validation. |
| B4 page | `EmployeeDashboard` (My expenses) via `ViewerContext` budget mode | No cycle; header card, status strip, search, activity, bar. |
| B4 expense list | `ExpensesTable` (desktop), mobile cards/carousel | ILS formatting in budget mode. |
| B4 add expenses | `NewExpense`, `BulkUploadDialog`, mobile single/bulk choice sheet | `budgetId` tagging. |
| B4 search | Search input pattern from B2 / reports | Merchant-or-amount match. |
| Expense detail back | `EmployeeExpenseDetail` | "Back to budget" target. |
| Nav items | `SheetTypeNav` | Budget items, attention badge. |

**Genuinely new (closest existing pattern copied)**
- `BudgetHeaderCard` stat strip — copies the dashboard counter cards' label/value typography and the Monthly cycle widget card.
- `BudgetStatusStrip` — copies the billing alert banner / `AwaitingPaymentCard` tinted alert pattern.
- `BudgetActionBar` — copies the product's sheet-screen sticky footer (mobile new-expense submit bar).
- Activity trail (`BudgetActivity`) — copies the billing history list layout as a vertical timeline.
- `UsageBar` — breach-style meter: fill (warning at ≥80%), at > 100% a limit tick plus red striped overflow; copies the `Progress` bar.

---

## 4. Copy (mock dictionary — superseded by the reviewed table in pc-1-budget-sheet-spec.md)

| Key | English | Hebrew |
|---|---|---|
| modulesPettyCash | Budgets | תקציבים |
| sheetNavPettyCashShort | Budgets | תקציבים |
| sheetNavPettyAll | All budgets | כל התקציבים |
| sheetNavBack | Back | חזרה |
| sheetNavTeam | Team expenses | הוצאות הצוות |
| sheetNavMy | My expenses | ההוצאות שלי |
| sheetNavComingSoon | Coming soon | בקרוב |
| budgetsNew | New budget | תקציב חדש |
| budgetsNewShort | New | חדש |
| budgetsReport | Budgets report | דוח תקציבים |
| budgetsReportBody | Designed in a later round | יעוצב בסבב מאוחר יותר |
| budgetsEmptyTitle | No open budgets | אין תקציבים פתוחים |
| budgetsBCountersTitle | Budgets by status | תקציבים לפי סטטוס |
| budgetsTileAwaiting | Awaiting approval | ממתינים לאישור |
| budgetsTileReturned | Returned | הוחזרו |
| budgetsTileOpen | Open | פתוחים |
| dashV2NeedsReview | needs review | דורש בדיקה |
| viewMore | View More | צפה עוד |
| budgetsBannerNeed | {n} need attention | {n} דורשים טיפול |
| budgetsBannerOver | {n} over budget | {n} בחריגה |
| budgetsBannerOverdue | {n} overdue | {n} באיחור |
| budgetsSpent | Spent | נוצל |
| budgetsBOpenCaption | {n} open budgets | {n} תקציבים פתוחים |
| budgetsColBalance | Balance | יתרה |
| back | Back | חזור |
| budgetsBAllEmployees | All employees | כל העובדים |
| budgetsSearchPlaceholder | Search budget, #ID or employee | חיפוש לפי תקציב, מספר או עובד |
| budgetsTileAttention | Needs attention | דורשים טיפול |
| budgetsBSectionEmpty | No budgets | אין תקציבים |
| budgetsNoResults | No budgets match | לא נמצאו תקציבים תואמים |
| budgetsClearFilters | Clear search and filter | ניקוי חיפוש וסינון |
| budgetsColName | Budget name | שם התקציב |
| budgetsColEmployee | Employee | עובד |
| budgetsColStatus | Status | סטטוס |
| budgetsColBudget | Budget | תקציב |
| budgetsColSpent | Spent | נוצל |
| budgetsColUsed | Used % | % ניצול |
| budgetsColEnd | End date | תאריך סיום |
| budgetsOverdue | Overdue {n} days | באיחור {n} ימים |
| budgetsOver | {amount} over | חריגה של {amount} |
| budgetsMenu | Budget actions | פעולות תקציב |
| budgetsSubmit | Submit for approval | הגשה לאישור |
| budgetsSubmittedToast | Submitted for approval | הוגש לאישור |
| budgetsDelete | Delete | מחיקה |
| budgetsDeleteTitle | Delete budget? | מחיקת התקציב? |
| budgetsDeleteBody | "{name}" and all its expenses will be removed. Recovery is possible only through support. | see dictionary (same meaning) |
| budgetsDeleteConfirm | Delete budget | מחיקת תקציב |
| budgetsCancel | Cancel | ביטול |
| budgetsDeleted | Budget deleted | התקציב נמחק |
| budgetsFieldAmount | Initial amount (₪) | סכום התחלתי (₪) |
| budgetsMe | (me) | (אני) |
| budgetsErrRequired | Required | שדה חובה |
| budgetsErrAmount | Amount must be greater than 0 | הסכום חייב להיות גדול מ-0 |
| budgetsErrDate | End date can't be in the past | תאריך הסיום לא יכול להיות בעבר |
| budgetsCreate | Create budget | יצירת תקציב |
| budgetsCreatedToast | Budget created | התקציב נוצר |
| budgetsStatusReturned | Returned | הוחזר |
| sheetStatusDraft | Draft | טיוטה |
| sheetStatusAwaiting | Awaiting approval | ממתין לאישור |
| sheetStatusApproved | Approved | אושר |
| budgetsEnds | Ends {date} | סיום {date} |
| bpBack | Back | חזרה |
| bpLeft | Left | נותר |
| bpOverBudget | Over budget | חריגה |
| bpEndsCol | Ends | סיום |
| bpOverdueCol | Overdue | באיחור |
| bpDays | {n} days | {n} ימים |
| bpAwaitingSent | Awaiting approval · sent {date} | ממתין לאישור · נשלח ב-{date} |
| bpStillEdit | You can still edit expenses | עדיין אפשר לערוך הוצאות |
| bpReturnedOn | Returned for changes · {date} | הוחזר לתיקונים · {date} |
| bpSearch | Search merchant or amount | חיפוש לפי ספק או סכום |
| view | View | צפייה |
| bpAddExpenses | Add expenses | הוספת הוצאות |
| bpSubmitAmount | Submit {amount} for approval | הגשת {amount} לאישור |
| bpActivity | Activity | פעולות |
| bpEvCreated | Budget created | התקציב נוצר |
| bpEvTopup | Top-up {amount} | טעינה {amount} |
| bpEvSubmitted | Submitted for approval | הוגש לאישור |
| bpEvReturned | Returned for changes | הוחזר לתיקונים |
| bpEvApproved | Approved | אושר |
| bpBackToBudget | Back to budget | חזרה לתקציב |
| employeeEmptyStateTitle | Welcome aboard! | ברוכים הבאים! |
| employeeEmptyStateDesc | Click "New Expense" to upload your first receipt. | לחץ על "הוצאה חדשה" כדי להעלות את הקבלה הראשונה שלך. |
| newExpense | New Expense | הוצאה חדשה |

---

## 5. Business rules shown in the UI
- **Budget total** = initial amount + top-ups. **Balance** = total − spent. **Used %** = spent / total, rounded.
- **Outstanding** = status ≠ Approved. Only outstanding budgets appear on B1/B2.
- **Overdue** = outstanding and today is after the end date; days = whole days since the end date.
- **Needs attention** = outstanding AND (balance < 0 OR overdue). Drives the B1 strip, the B2 toggle/reason rows and the nav badge.
- **Status counts are exclusive**: Awaiting + Returned + Open = number of outstanding budgets. Attention is a flag across statuses, not a status.
- **Editing allowed until Approved**: Open, Returned and Awaiting approval are editable by the holder; Approved and other holders' budgets are read-only.
- **Submit** allowed from Open and Returned; result is Awaiting approval plus a history entry.
- **Submit amount** = live spent (including expenses added since).
- **Whole shekels** (no decimals): B1 spend card, B4 header strip, submit caption. Everywhere else: 2 decimals (B2 balances, nav balances, expense amounts).
- **Currency suffix**: "1,234.00₪" — symbol after the number. Header-strip values carry no symbol.
- **LTR islands**: amounts, counts, percents, #numbers, dates and file names render LTR inside RTL text.
- **RTL**: logical spacing/alignment only; back arrows and chevrons mirror.
- **Isolation**: budget expenses carry `budgetId`, never a Monthly sheet id; they never count toward Monthly.
- **New budget validation**: all fields required; amount > 0; end date today or later.

---

## 6. Mock-only behaviour — do NOT build
- Dev Data panel controls: "Budgets assigned to me" (0–5), "All budgets: empty state", "Budgets below zero", badge number overrides, module switches (Monthly/Budgets/Travel). The Dev Data button lifting above the bottom bar is mock-only too.
- Seed data: budgets, holders and the 50 "Events" expenses / 3–6 expenses on other holders' budgets; end dates and history dates relative to today (`daysFromToday`).
- Live-spent simulation: stored seed spent + expenses added in the session (`useLiveBudgets`); `bseed-` id convention.
- Mock history generation: `created` 60 days ago, `topup` 30 days ago, `submitted` 10 days ago, `returned` 7 days ago with a fixed reason, `approved` 5 days ago — derived from status.
- Client-side budget numbering (highest + 1), create/submit/delete done in memory, toasts as the only confirmation.
- B2 row menu "Submit for approval" by the manager on any budget (prototype shortcut).
- Report page and approve/return actions for managers are placeholders / not designed.
