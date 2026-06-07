# Bug: Out-of-range invoice date only fails at submit (no client-side validation)

> **Status: new**

## Problem

If you upload an invoice with a date older than 12 months, you only get an error
on submit, and the error comes from the backend. It would be better to validate
client-side and highlight the date field with the validation message before
submission.

## Reproduce Steps

1. Add an expense and set/upload an invoice with a date older than 12 months.
2. Submit.
   -- Expected: inline validation on the date field the moment the date is set,
      with Submit disabled while invalid.
   -- Actual: no feedback until submit; the error comes back from the backend.

## Suggested Solution Approach

Own the out-of-range UX on the client; keep the backend rule as a safety net.

## Suggested Fix

- Add a client-side validator on the date field rejecting dates older than 12
  months (calendar-month comparison preferred over a fixed 365-day window).
- Surface the message inline via the field's `errorText` / `FormFieldState` the
  moment the date is picked or parsed from the uploaded invoice -- not on submit.
- Disable Submit while the date is invalid so the backend round-trip never
  happens for this case.
- Note: relates to the calendar `firstDate` range in
  docs/bugs/calendar-widget-unstable-cross-browser.md.
