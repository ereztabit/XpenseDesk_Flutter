# Expense Sheets Transformation — Story Index

Story-driven plan for adapting the Flutter client to the new sheet-centric approval model. Each file in this folder is a self-contained, end-to-end story we can build and verify in isolation.

## Background

- **Server contract (source of truth):** [`ExpenseSheetsEvolution.md`](ExpenseSheetsEvolution.md)
- **High-level audit + risks (still useful reference, but superseded by these stories for planning):** [`expense-sheets-implementation-plan.md`](expense-sheets-implementation-plan.md)

## Stories

| # | Story | Status |
|---|---|---|
| 01 | [Employee Dashboard](01-EmployeeDashboard.md) | ✅ **Shipped** — built end-to-end, CR'd ([CR](01-EmployeeDashboard-CR.md)), build clean |
| 02 | [Manager Dashboard](02-ManagerDashboard.md) | ✅ **Shipped** — built end-to-end against the live server endpoint, CR'd ([CR](02-ManagerDashboard-CR.md)), build clean. Row tap → Sheet Review is a placeholder snackbar until story 03 |
| 03 | [Sheet Review](03-SheetReview.md) | ✅ **Shipped** — whole-sheet approve/decline + per-line review + activity timeline, verified against live server, CR'd ([CR](03-SheetReview-CR.md)), build clean. Block-mode pre-gating deferred (handles 403 gracefully) |

### Done in stories 01 + 02 (manual UI verification by the user, iterating)

- Employee dashboard fully replaced (picker, returned-sheets alert, declined banner, filter tabs, responsive expense list).
- Manager dashboard fully replaced (three buckets: Pending review / Returned to employee / Approved; employee filter; Spend Overview placeholder).
- Shared `lib/utils/sheet_utils.dart` (selection / bucket math / permissions) + shared widgets (`AiBadge`, `ActionIconButton`).
- `/code-review` skill created + made mandatory in CLAUDE.md.

### Still open (tracked, not blocking)

- **Spend Overview** — soft-degraded one-line placeholder on the manager dashboard. Real widget exists but is expense-list-centric; making it sheet-aware is its own story.
- **Paginated "View all" screens** — the bucket cards show an overflow notice ("Showing 12 of N…") instead of a clickable link until the paginated list screen ships.
- **Hebrew copy** — best-effort throughout; pending a native review pass.

## Working conventions

- One story = one shippable slice (a PR or a tight series of PRs).
- Each story owns: UX spec, decisions resolved, decisions still open, model/provider/service additions, sequenced tasks, i18n keys, out-of-scope notes.
- If a story needs the server to change, the story calls it out with a **Server Contract Reconciliation** section. We don't silently work around mismatches.
- Numbering is for sequence only; later stories can renumber if priority shifts.
