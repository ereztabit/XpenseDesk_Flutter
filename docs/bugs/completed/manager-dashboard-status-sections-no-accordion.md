# Bug: Manager dashboard status sections don't collapse (no accordion)

> **Status: done**

## Resolution

The three sections on the Sheet Approvals screen (Pending review / Returned to
employee / Approved) are now a single-open accordion. Converted `SheetBucketCard`
from internal expand-state to parent-controlled (`expanded` + `onToggle`);
removed the old `initiallyExpanded` / `collapseWhenEmpty` auto-logic. The screen
owns a single `_expandedSection` (seeded from the arrival section, default
Pending) and toggling one header opens it and collapses the rest. Arriving from
a dashboard counter still draws the focus ring on the right section.

Bonus: `sheet_bucket_card.dart` dropped from 211 to 178 lines (now under the
200-line cap).

Files:
- `lib/widgets/manager_dashboard/sheet_bucket_card.dart`
- `lib/widgets/manager_dashboard/pending_review_card.dart`
- `lib/widgets/manager_dashboard/approved_card.dart`
- `lib/widgets/manager_dashboard/returned_to_employee_card.dart`
- `lib/screens/sheet_approvals_screen.dart`

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
