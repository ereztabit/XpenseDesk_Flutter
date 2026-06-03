# Bug: Edit Expense — Cancel Button Has Wrong Hebrew Caption

## Problem

When editing an expense, the Cancel button shows the wrong Hebrew caption: it reads
**"התעלם"** (ignore/dismiss) when it should read **"בטל"** (cancel). Likely the
wrong ARB key is being used for this button.

## Reproduce

1. Set UI language to Hebrew.
2. Edit an expense.
3. **Result:** The cancel button reads "התעלם".
4. **Expected:** The cancel button reads "בטל".

## Suggested Solution

Use the correct "cancel" localization key ("בטל") for the edit-expense cancel
button instead of the dismiss/ignore key.

_(To be expanded.)_
