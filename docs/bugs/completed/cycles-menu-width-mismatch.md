# Bug: Cycles Menu — Dropdown Width Doesn't Match the Trigger

## Problem

When opening the cycles (month) menu, the opened dropdown panel does not match the
width of the trigger/header it expands from. The popup is sized differently (too
narrow) instead of spanning the same width as the row it belongs to, which looks
misaligned and broken.

## Reproduce

1. Open the cycles menu (the month selector, e.g. "יוני 2026").
2. **Result:** The dropdown panel width does not fit / does not match the trigger
   width.
3. **Expected:** The dropdown panel has the same width as its trigger row.

## Suggested Solution

Constrain the cycles dropdown overlay to the trigger's width so the open menu lines
up with the row it expands from.

_(To be expanded.)_
