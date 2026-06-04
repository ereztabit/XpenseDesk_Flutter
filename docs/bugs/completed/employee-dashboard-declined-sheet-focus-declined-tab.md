# Bug: Employee Dashboard -- Declined Sheet Should Focus the Declined Tab

## Problem

On the employee dashboard, when a Declined sheet is selected and it has declined
expenses, the status filter tabs open on the Pending tab. The user should instead
land on the Declined tab, because the declined expenses are exactly what they need
to act on (fix and resubmit).

The tabs default to Pending globally (a deliberate choice for Submitted sheets,
where Pending is the useful landing bucket). Declined sheets need a different
default: focus the Declined bucket when it has records.

## Reproduce Steps

1. Log in as an employee who has a Declined sheet with at least one declined expense.
2. Open the dashboard and select the Declined sheet.
3. Result: the filter tabs open on Pending.
4. Expected: the tabs open on Declined (the rejected bucket), so the declined
   expenses are shown first.

## Suggested Solution Approach

When the selected sheet is Declined and has declined expenses, default the active
filter tab to Declined on first display. Do not override the user's choice if they
then tap another tab.

## Suggested Fix

File: lib/widgets/employee_dashboard/employee_dashboard_body.dart

In the Declined branch (the `_tabbedExpenses(..., isDeclined: true)` path), set the
active tab to `FilterTab.rejected` when there is at least one declined expense, on
first entry only. Use a post-frame callback that sets
`selectedFilterTabProvider` to `FilterTab.rejected` if the current selection has not
been explicitly chosen for this sheet (mirror the one-shot default-selection guard
already used for sheet selection in `user_dashboard_screen.dart`).

Keep the global default (`FilterTab.pending`) for Submitted sheets unchanged -- this
is a Declined-sheet-specific landing rule, not a change to the global default.
