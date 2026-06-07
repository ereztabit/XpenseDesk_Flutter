# Bug: Manager mobile cards have a huge gap (looks like only one card)

> **Status: done**

## Problem

On the Sheet Review screen (mobile), there is a huge gap between expense cards,
so you cannot tell there is more than one card.

## Reproduce Steps

1. On mobile, open a sheet that is awaiting approval (so the expense lines render
   as swipeable action cards).
2. Scroll the cards.
   -- Expected: a small consistent gap; the next card peeks into view.
   -- Actual: a huge gap makes it look like there is only one card.

## Suggested Solution Approach

Cards should be content-sized with a small fixed gap so the stack is obviously
scrollable.

## Suggested Fix

- Inspect the list/grid spacing. Likely cause: a fixed-height container, a stray
  `SizedBox`, or `childAspectRatio` forcing each card to fill the viewport.
- Replace with content-sized cards and a small fixed gap (`separatorBuilder` /
  `Wrap` spacing ~8-12 px) so the next card peeks into view.

## Resolution

Root cause: `ManagerSwipeableExpenseCard` wrapped each card in
`ConstrainedBox(maxHeight: 600)` + `OverflowBox`. The 600px value is only needed
for the fly-away dismiss animation, but at rest — inside the vertically-unbounded
scroll list — it forced every card into a fixed 600px slot (~400px of dead space
after ~200px of content).

Replaced the fixed-height box with `ClipRect` + `Align(heightFactor:)`, which
collapses relative to the card's actual content height. Resting cards are now
content-sized (tight ~8px gaps); the dismiss animation still collapses smoothly.
Also removed the dead `_dismissTranslate` notifier.

Files:
- `lib/widgets/expenses/manager_swipeable_expense_card.dart`.
