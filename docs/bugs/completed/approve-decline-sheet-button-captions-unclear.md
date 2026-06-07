# Bug: Approve / Decline sheet button captions are unclear

> **Status: done**

## Resolution

Reworded the whole-sheet CTAs on the Sheet Review screen so they state what
will happen:
- Approve button: "Approve {count} expenses of {amount}" (pluralized; count +
  base-currency total), on both mobile and desktop.
- Decline button: "Return this sheet to user to edit" (icon changed to `undo`).
- On mobile the sticky-bar buttons now stack full-width so the longer captions
  never overflow; desktop keeps the inline Row.

Added `expenseCount` / `totalAmount` computed getters to `ExpenseSheetDetail`
(and removed the inline `.fold` from the approve handler). New ARB keys
(`expenseWordSingular`, `approveOfAmountConnector`, `returnSheetToUserCta`) in
EN + HE.

Files:
- `lib/widgets/sheet_review/sheet_review_actions.dart`
- `lib/screens/sheet_review_screen.dart`
- `lib/models/expense_sheet_detail.dart`
- `lib/l10n/app_en.arb`, `lib/l10n/app_he.arb`

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
