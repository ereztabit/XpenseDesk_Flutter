# Bug: Approve / Decline sheet button captions are unclear

> **Status: new**

## Problem

The approve-sheet / decline-sheet button captions are not clear. Suggested copy:
"Approve 2 expenses of $1,900" and "Return this sheet to user to edit".

## Reproduce Steps

1. As a manager, open the approve sheet and the decline sheet.
2. Read the action button captions.
   -- Expected: dynamic, descriptive captions (count + amount; clear decline
      wording).
   -- Actual: generic captions that do not convey what will happen.

## Suggested Solution Approach

Build the captions from data already in the sheet payload so the manager sees
exactly what they are approving.

## Suggested Fix

- Build the approve label from the count of expenses and the summed amount
  (e.g. `Approve {count} expenses of {currency}{total}`).
- Reword decline to `Return this sheet to user to edit`.
- Use existing localization + `num.toCurrency(companyLocale, currencyCode)` so
  the amount renders correctly and pluralization (`1 expense` vs `2 expenses`) is
  handled.
- Note: prior related work closed in
  docs/bugs/completed/approve-sheet-dialog-wrong-text.md and
  docs/bugs/completed/decline-sheet-dialog-char-limit-and-missing-context.md.
