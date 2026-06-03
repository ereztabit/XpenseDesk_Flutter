# Bug: New Expense — Date Validation Error Shows in English While UI Is in Hebrew

## Problem

On the New Expense screen, when the expense date fails validation (too old), the
error message is displayed in **English** ("Expense date cannot be more than 12
months old.") even though the rest of the UI is in Hebrew. This is the raw server
message leaking through instead of a localized client string.

## Reproduce

1. Set UI language to Hebrew.
2. Open New Expense.
3. Enter / pick an expense date that is too far in the past.
4. Submit.
5. **Result:** English validation error appears below the form.
6. **Expected:** A localized (Hebrew) error message.

## Suggested Solution

- Surface a localized message, not the raw server text.
- **Better:** catch this validation on the **client before** submitting to the
  server — fail fast with the localized message and avoid the round-trip entirely.

_(To be expanded.)_
