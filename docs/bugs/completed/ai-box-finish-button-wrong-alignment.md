# Bug: AI box "Finish" button is aligned to the wrong side

> **Status: done**

## Resolution

The Finish (submit) button was wrapped in `Align(alignment: Alignment.centerLeft)`
— a hardcoded physical-left that, in Hebrew/RTL, placed it on the opposite edge
from the rest of the form. Changed to `AlignmentDirectional.centerStart` so it
follows reading direction (start = right in RTL, left in LTR).

Files:
- `lib/screens/new_expense_screen.dart` — `_buildActionButtons` alignment.

## Problem

In the AI box when adding an expense, the Finish button is aligned to the opposite
side from the rest of the action buttons.

## Reproduce Steps

1. Add an expense and open the AI detected-details box.
2. Observe the action buttons row.
   -- Expected: all action buttons follow a consistent alignment.
   -- Actual: Finish sits on the opposite edge from the others.

## Suggested Solution Approach

The action buttons should follow one consistent alignment / primary-secondary
split.

## Suggested Fix

- Group all action buttons in a single `Row` with a consistent
  `MainAxisAlignment` (all trailing/`end`, or a clear primary/secondary split).
- Remove the stray `Spacer` / alignment override that pushes Finish to the
  opposite edge.
