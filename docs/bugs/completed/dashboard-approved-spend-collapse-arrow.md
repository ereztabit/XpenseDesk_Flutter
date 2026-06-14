# Bug: Approved-spend card should collapse via a top-corner arrow, not "הצג פירוט"

> **Status: done**

## Resolution

Moved the toggle to a chevron `IconButton` in the card's top-trailing corner
(top-left under RTL) and removed the bottom "show details" text. The expand
state was lifted to `SpendOverviewCard` (now `ConsumerStatefulWidget`);
`SpendOverviewBreakdown` is now body-only. Files:
`lib/widgets/manager_dashboard/spend_overview_card.dart`,
`lib/widgets/manager_dashboard/spend_overview_breakdown.dart`. Verified by user.

## Problem

The approved-spend box on the manager dashboard currently exposes its breakdown
through a "הצג פירוט" (show details) text toggle at the bottom. It should instead
use a collapse/expand arrow in the top-leading corner of the box (consistent with
a standard collapsible card), and drop the "הצג פירוט" text affordance.

## Reproduce Steps

1. Open the manager dashboard.
2. Look at the approved-spend card (the "הוצאות שאושרו" box).
   -- Expected: a collapse/expand arrow in the top-leading corner toggles the
      breakdown.
   -- Actual: a "הצג פירוט" text link at the bottom toggles it.

## Suggested Solution Approach

Replace the bottom "הצג פירוט / הסתר" text toggle with an arrow icon button
positioned in the top-leading corner of the card; keep the existing
expand/collapse state logic.

## Suggested Fix

- `lib/widgets/manager_dashboard/spend_overview_breakdown.dart`: the QA-added
  `_expanded` state + `showSpendBreakdown`/`hideSpendBreakdown` toggle stays;
  move the trigger to a top-leading `IconButton` (e.g. expand_more / expand_less,
  or a rotating chevron) and remove the bottom text toggle.
- Keep the lazy-compute behavior (only build `groupSpendBreakdown` when expanded).
- Note RTL: "top-left" in the screenshot is the top-trailing corner in LTR terms;
  use `Align`/`Positioned` with directional alignment so it lands correctly in
  both RTL and LTR.
