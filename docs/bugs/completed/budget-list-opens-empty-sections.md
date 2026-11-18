# Bug: The budget list opens its empty sections

> **Status: done**

Found by the owner on prod, 2026-11-18 (v1.50).

## Problem

When the budget list loads, every section (Awaiting approval, Returned, Open)
is expanded, including the ones with no budgets in them. The manager sees
large "No budgets" cards before the budgets they came for, and has to scroll
or collapse them by hand. An empty section should load collapsed.

## Reproduce Steps

1. As a manager of a company with Budgets on, have budgets in only some
   sections (prod demo company: one Open budget, nothing Awaiting or Returned).
2. Open Budgets -> the list (`/budgets/list`, no `focus` in the address).
   -- Expected: only sections that hold budgets are expanded; Awaiting approval
      (0) and Returned (0) load collapsed, showing just their header and count.
   -- Actual: all three sections are expanded; Awaiting approval and Returned
      each show an empty "No budgets" card.

## Suggested Solution Approach

On first load, expand a section only if it has budgets. A `focus` from the
dashboard still opens that section. Once the manager opens or closes a section
by hand, keep their choice: no reshuffle on refresh, search or filter, and Back
from a budget still returns the list exactly as left (FS-1013).

## Suggested Fix

`lib/screens/budget_list_screen.dart:47` seeds
`_expanded = widget.focus == null ? BudgetSection.values.toSet() : {widget.focus!}`
in `initState`, before any data. Seed it instead the first time
`budgetsProvider` returns data: the sections with at least one budget, or
`{focus}` when a focus is given. Leave it alone after that, or after any user
toggle. Put the rule in `lib/utils/budget_utils.dart` (e.g.
`budgetInitiallyExpanded(budgets, focus)`) and unit-test it: empty sections
collapsed, focus wins, and all sections empty means all collapsed.

## Resolution

Fixed in the FS-1013 PC-2 fixes, shipped as v1.51 (2026-11-18). Verified in manual QA runs 4-4c. Commit e83c89d.
