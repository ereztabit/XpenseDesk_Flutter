# Bug: Manager dashboard status sections don't collapse (no accordion)

> **Status: new**

## Problem

On the manager dashboard, clicking Approved / Declined / Pending should open only
the selected area and collapse the others. Today they do not behave as an
accordion.

## Reproduce Steps

1. As a manager, open the dashboard with the Approved / Declined / Pending
   sections.
2. Tap one section header.
   -- Expected: only the tapped section opens; the others collapse.
   -- Actual: sections do not collapse to a single open one.

## Suggested Solution Approach

Single-open accordion behavior across the three status sections.

## Suggested Fix

- Track a single `selectedSection` in state; tapping a header sets it and
  collapses the rest.
- Use `ExpansionPanelList` (with `expansionCallback`) or `ExpansionTile` driven by
  shared state so only one is open at a time.
