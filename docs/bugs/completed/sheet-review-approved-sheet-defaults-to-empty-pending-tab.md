# Bug: Sheet Review of an approved sheet defaults to the empty Pending tab

> **Status: done**

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

## Manual QA

### Run 1 - 2026-11-17 (reproduction, before the fix)
- Branch / commit: develop @ bef87e2
- QA company: XpenseDesk Demo Company (dev); manager m@xpensedesk.com; employee e@xpensedesk.com
- Coverage: lane A (manager, desktop 1440) x EN x Sheet Approvals -> Sheet Review
- Setup: dev had no approved sheet in any company. e@ filed three expenses
  (merchant "QA repro - approved sheet tab"); the open cycle was closed with the
  dev-only `POST /api/test/backdate-current-cycle-end` + `/api/test/promote-cycle`
  (e@'s sheet -> Waiting for approval); m@ approved the sheet
  (2ae3966e-218b-4991-a8e9-40c8c46c39ba, 4 lines, all Approved).
- Data left: Demo company's June 2026 cycle closed and a new one opened; the
  sheet above is Approved / Awaiting payment; the promotion also submitted
  "Employee User"'s draft sheet (now in Pending review).

| # | Lane | Lang | Screen | Severity | Finding | Status |
|---|---|---|---|---|---|---|
| 1 | A (manager, desktop) | EN | Sheet Review | Major | Opening the approved sheet from Approvals -> Approved -> View selects the Pending tab (0) and shows "No expenses in this view."; Approved (4) holds every line | Fixed (run 2) |

Result: 1 finding - 1 open (the bug, reproduced).

### Run 2 - 2026-11-17 (after the fix)
- Branch / commit: feature/sheet-review-default-tab @ uncommitted
- QA company: XpenseDesk Demo Company (dev); manager m@xpensedesk.com
- Coverage: lane A (manager, desktop 1440) EN and lane B (manager, mobile 375)
  EN + HE x Sheet Review. Approved sheet 2ae3966e opened by URL and from
  Approvals -> Approved -> View (HE); Waiting-for-approval sheet 85000bea
  ("Employee User", 6 pending lines) as the regression check.
- Not covered: employee lanes - Sheet Review is manager-only. A sheet whose
  lines are all declined (no such sheet in dev); covered by the unit test
  `test/utils/sheet_initial_tab_test.dart`.
- Data left: as run 1; language switched in the UI only (not saved).

| # | Lane | Lang | Screen | Severity | Finding | Status |
|---|---|---|---|---|---|---|
| - | A, B (manager) | EN/HE | Sheet Review | - | Approved sheet opens on Approved (4) with its lines; pending sheet still opens on Pending (6); HE tabs RTL, Approved selected | Pass |

Result: clean. Console showed only dev-server startup noise (MIME / dwds websocket), no Dart exceptions.

## Fix

`SheetExpenseBuckets.initialTab` (`lib/utils/sheet_utils.dart`) picks the
opening tab: Pending while it has lines, otherwise the first non-empty bucket
(Approved, then Declined), Pending for an empty sheet.
`SheetReviewLineSection` uses it in `initState` unless `focusTab` is set; a tab
the manager picks is never overridden afterwards. Unit tests:
`test/utils/sheet_initial_tab_test.dart`.

## Resolution

Shipped in v1.44 (2026-11-17): fix commit 83bbf94, merged to develop as
98974bd, released to main as 6cd8d86. `SheetExpenseBuckets.initialTab`
(`lib/utils/sheet_utils.dart`) picks the opening tab and
`SheetReviewLineSection` uses it unless `focusTab` is set. Verified by manual
QA run 2.
