# Company modules + per-module categories

> Mission: FS-1010 (backend: BackEnd/XpenseDeskServer/docs/backlog/company-modules-and-categories-story.md)

Status: SHIPPED 2026-11-15 in v1.41 (Flutter half). **Designed in the Lovable app mock first**
(project 0c5b063f..., see root LOVABLE.md Part B) - the Flutter build follows the
agreed mock.

## The business case

XpenseDesk grows from one flow to three **modules**: Monthly expenses
(הוצאות חודשיות - today's cycles), Petty Cash (קופה קטנה) and Travel
(נסיעות לחו"ל). A company manager decides which modules the company uses and
configures each one. This mission is the configuration only: no petty cash
sheets, no trips, and employees see no change except category names coming from
the server.

The business rules (module rules, category rules, Travel tax keys, default sets)
are in the backend story - this spec does not repeat them.

## User flow (manager)

1. Company settings (`company_config_screen.dart`) -> new **Modules** section:
   three cards - Monthly, Petty Cash, Travel - each with its on/off state.
2. Monthly shows **on and locked**, with a short "can't be turned off yet" hint.
3. Turning Petty Cash or Travel on only flips the switch and shows a
   "Configure" button on the card; the module page opens from that button,
   never automatically.
4. Module page = settings + categories:
   - **Monthly**: categories only.
   - **Petty Cash**: "Allow negative balance" switch + categories.
   - **Travel**: categories only; each category shows its tax key.
5. Categories editor:
   - list sorted alphabetically in the user's language; inactive ones visibly
     marked (manager sees them, employees never do);
   - row = one line "<current-language name> / <other-language name>"
     (e.g. "אוכל וארוחות / Food & meals"), then inline icon buttons, no
     overflow menu:
     - active category: **Edit** + **Delete**. Delete always shows: with no
       expenses it deletes (confirm); with expenses it deactivates instead,
       and the confirm says so. One client action, the server decides - so
       the API should expose a single "delete" that returns which happened
       (deleted / deactivated);
     - inactive category: **Edit** + **Reactivate** (no confirm);
   - add: Hebrew name + English name (at least one), Travel also picks a tax key;
   - rename; deactivate / reactivate; delete only when unused (server decides,
     the client shows the error code's message);
   - Travel defaults: deactivate only - no rename, no delete, shown as locked.
6. Turning a module off: confirm dialog; the last active module cannot be turned
   off (Monthly is locked anyway in the MVP).

Employees: read only. Everything is manager-only.

## Client changes beyond the new screens

- `lib/models/expense_category.dart` is a hardcoded enum (ids 1-6 with HE/EN
  labels). It is replaced by the server's per-company Monthly list: expense
  form picker, expense detail, sheet review, analysis charts
  (`category_bar_chart.dart`) and the cycle report all read names from the
  server. Inactive categories are hidden from the picker but still render on
  existing expenses.
- After the backend migration, category ids are per company - nothing in the
  client may assume ids 1-6.
- Every new error is a flat `ApiErrorCodes` key with HE + EN copy.

## Out of scope

Petty Cash sheets, Travel trips, a destination picker on capture, turning
Monthly off, travel tax report, plan gating.

## Manual QA

### Run 1 - 2026-11-15
- Branch / commit: feature/company-modules @ uncommitted
- QA company: XpenseDesk Demo Company (dev); manager "Admin User"; employee user＠xpensedesk.com (both via qa-admin-1 "connect as")
- Coverage: manager desktop 1440 (EN + HE) and mobile 375 (EN, HE dialog); employee desktop (EN + HE) and mobile (EN). Screens: Modules list, Monthly / Petty Cash / Travel pages, add / edit / delete / deactivate / reactivate, Petty Cash setting, module on/off + confirm, employee dashboard rows, edit-expense category picker, employee blocked from the manager URL.
- Not covered: the used-category Delete -> Deactivate path on Monthly (Demo has no used Monthly category except the fallback; covered through Travel system categories instead); the new-expense picker (sits behind a receipt upload); lanes ran one after another with one admin rather than four in parallel.

| # | Lane | Lang | Screen | Severity | Finding | Status |
|---|---|---|---|---|---|---|
| 1 | A (manager, desktop) | EN | Edit expense (employee C) | Major | Opening an expense by direct URL showed "Select category": the dropdown resolved its label before the company categories loaded | Fixed (run 1) |
| 2 | C (employee, desktop) | HE | Edit expense | Major | Selected category label stayed English after switching to Hebrew | Fixed (run 1) |
| 3 | A (manager, desktop) | EN | Modules | Minor | Hovered "on" switch: thumb vanished into the track | Fixed (run 1) |
| 4 | A (manager, desktop) | EN | Modules | Minor | Locked Monthly switch looked identical to an active one | Fixed (run 1) |
| 5 | B (manager, mobile) | EN/HE | AppHeader (all screens, support session) | Major | Header row overflows 18-21px at 375px when the support chip is shown (`app_header.dart:303`) - not FS-1010 | Open - filed: docs/bugs/app-header-overflows-on-mobile-in-support-session.md |
| 6 | C (employee, desktop) | HE | Edit expense | Minor | Receipt panel overflows 2px in Hebrew (`employee_expense_detail_screen.dart:1383`, IntrinsicHeight) - not FS-1010 | Open - filed: docs/bugs/expense-detail-receipt-panel-overflows-in-hebrew.md |

Result: 6 findings - 2 open (both outside FS-1010), 4 fixed.

### Run 2 - 2026-11-15
- Branch / commit: feature/company-modules @ uncommitted
- QA company: XpenseDesk Demo Company (dev); manager m@xpensedesk.com, employee e@xpensedesk.com (direct sign-in)
- Coverage: the full category lifecycle across roles, desktop EN - manager adds Monthly "QA Taxi / מונית QA" -> employee picks it on an existing expense and saves -> manager deletes it: the confirm says it has expenses, the server deactivates it (Inactive badge + Reactivate) -> employee's expense still shows "QA Taxi" and its picker keeps it -> employee switches the expense to Software, reopens it: "QA Taxi" is no longer offered.
- Not covered: the new-expense picker (needs a file upload the browser pane can't do; the employee's seed expense was created with `POST /api/expenses`).

| # | Lane | Lang | Screen | Severity | Finding | Status |
|---|---|---|---|---|---|---|
| 7 | C (employee, desktop) | EN | Edit expense -> save | Minor | Blank page after save in debug builds: `AppHeader` calls setState in dispose. Was filed as docs/bugs/completed/app-header-setstate-in-dispose.md. The PUT succeeded (200). | Fixed (run 2, AppHeader.dispose) |

Result: lifecycle clean; 1 finding (a pre-existing bug), fixed and closed.
