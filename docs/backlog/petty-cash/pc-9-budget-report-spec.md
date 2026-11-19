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
- Can: filter, open the read-only sheet, export the list, download PDF / Excel
  (PC-5). Cannot: select, Settle, Edit.
- The employee "Digital archive" entry (`expenses-detail-report` ->
  `/employee/history/report`) is **removed for employees**; the route
  redirects to History. Managers keep the Digital archive.
- Works with the Monthly or Budgets module off.

## QA

Manager + employee x desktop + mobile, EN + HE; module off; an employee cannot
reach another employee's sheet by URL.
