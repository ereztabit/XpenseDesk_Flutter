# Bug: Manager mobile cards have a huge gap (looks like only one card)

> **Status: new**

## Problem

On the manager mobile card layout there is a huge gap between cards, so you cannot
tell there is more than one card.

## Reproduce Steps

1. On mobile, open the manager dashboard card layout.
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
