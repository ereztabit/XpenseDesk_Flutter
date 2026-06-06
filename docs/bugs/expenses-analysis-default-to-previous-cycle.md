# Bug: Expense analysis should focus on the previous cycle, not the current one

> **Status: new**

## Problem

The Expense Analysis screen opens on the current (active) cycle. The current
cycle is still open, so its numbers are partial and not meaningful for analysis.
We don't need to see the current cycle here -- the analysis should focus on the
previous (most recently closed) cycle.

## Reproduce Steps

1. Log in as a manager and open Expense Analysis.
2. Observe the master breakdown and the detail card.
   -- Expected: the analysis lands on the previous (closed) cycle; the still-open
      current cycle is not the focus (and ideally not shown).
   -- Actual: the screen auto-selects the active/current cycle and shows its
      partial data.

## Suggested Solution Approach

Default the analysis to the previous (most recent closed) cycle instead of the
active one. Confirm whether the current cycle should be hidden from the master
breakdown entirely or just not be the default selection.

## Suggested Fix

In `lib/screens/expenses_analysis_screen.dart`, `_runReport` (around lines
102-113) picks the default cycle as `summaryRows.where((r) => r.isActive)`. Change
the default to the most recent non-active cycle (i.e. the previous closed cycle).

Scope to confirm with the requester:
- Default selection only: keep all cycles in `MasterCard`
  (`lib/widgets/analysis/master_card.dart`) but auto-select the previous one.
- Hide current entirely: also filter out the active cycle from the rows passed to
  `MasterCard` / `DetailCard` so it never appears.
