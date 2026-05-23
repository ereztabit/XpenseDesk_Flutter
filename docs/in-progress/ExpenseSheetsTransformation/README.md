# Expense Sheets Transformation — Story Index

Story-driven plan for adapting the Flutter client to the new sheet-centric approval model. Each file in this folder is a self-contained, end-to-end story we can build and verify in isolation.

## Background

- **Server contract (source of truth):** [`ExpenseSheetsEvolution.md`](ExpenseSheetsEvolution.md)
- **High-level audit + risks (still useful reference, but superseded by these stories for planning):** [`expense-sheets-implementation-plan.md`](expense-sheets-implementation-plan.md)

## Stories

| # | Story | Status |
|---|---|---|
| 01 | [Employee Dashboard](01-EmployeeDashboard.md) | **Ready to build — starting here** |
| 02 | [Manager Dashboard](02-ManagerDashboard.md) | Specced; blocked on server delivery of `GET /api/expense-sheets` (paged list endpoint) |
| 03 | Sheet Review (whole-sheet approve/decline + per-line review) | TBD — needed by story 02 row taps |

## Working conventions

- One story = one shippable slice (a PR or a tight series of PRs).
- Each story owns: UX spec, decisions resolved, decisions still open, model/provider/service additions, sequenced tasks, i18n keys, out-of-scope notes.
- If a story needs the server to change, the story calls it out with a **Server Contract Reconciliation** section. We don't silently work around mismatches.
- Numbering is for sequence only; later stories can renumber if priority shifts.
