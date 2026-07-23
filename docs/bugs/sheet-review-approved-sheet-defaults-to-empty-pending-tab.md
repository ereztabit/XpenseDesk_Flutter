# Bug: Sheet Review of an approved sheet defaults to the empty Pending tab

> **Status: reviewed by me**

## Problem

When a manager reviews an already-approved sheet, the Sheet Review screen
opens with the Pending tab selected - but on an approved (terminal) sheet the
Pending bucket is empty by design (every line has already been decided). The
manager lands on an empty list and has to manually click the Approved tab to
see the content they came for.

Scope decision (user): do NOT hide the Pending tab - all three buckets stay
visible as designed. Only the default selection changes.

## Reproduce Steps

1. Open Manager Approvals (/manager-approvals).
2. In the Approved (last) section, click the eye icon on an approved sheet.
3. Sheet Review opens (e.g.
   /manager/sheet/35ff6715-f814-4a18-ab8f-0c807bf0f285).
   -- Expected: the Approved tab is selected and its lines are visible. All
      three tabs remain visible (including Pending at count 0).
   -- Actual: the Pending tab is selected, showing an empty list (count 0).

## Suggested Solution Approach

The default tab should reflect the sheet's state: a manager opening a
finalized sheet wants to see what was decided, not an empty work queue.
Pending-first is only the right default while the sheet still has lines to
act on.

## Suggested Fix

`lib/widgets/sheet_review/sheet_review_line_section.dart` line 48 hardcodes
the initial tab: `FilterTab _selectedTab = FilterTab.pending;`.

- Initialize the selected tab from the sheet status / counts: if the sheet is
  terminal (Approved), default to `FilterTab.approved`. A more general rule -
  default to Pending when the pending count > 0, otherwise to the first
  non-empty bucket - would also fix declined-heavy sheets.
- No change to `SheetReviewFilterTabs`
  (`lib/widgets/sheet_review/sheet_review_filter_tabs.dart`) - per user
  decision, all three tabs stay visible even at count 0; only the initial
  selection logic in the section changes.
