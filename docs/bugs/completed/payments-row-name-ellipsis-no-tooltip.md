# Bug: Employee name ellipsizes with no tooltip

> **Status: done**

## Resolution

The employee-name link is wrapped in a `Tooltip` showing the full name on hover
(desktop + mobile). Files: `lib/widgets/payments/desktop_payments_row.dart`,
`lib/widgets/payments/mobile_payment_row.dart`. Verified by user.

## Problem

Same issue as the email column (see
docs/bugs/completed/payments-desktop-email-ellipsis-no-tooltip.md): the employee
name truncates with an ellipsis when long, but shows no tooltip, so the full
name can't be read.

## Reproduce Steps

1. Open the Payments Report with a long employee name.
2. Hover the truncated name.
   -- Expected: a tooltip showing the full name.
   -- Actual: ellipsis only.

## Suggested Fix

- Wrap the employee-name link in `lib/widgets/payments/desktop_payments_row.dart`
  (and `lib/widgets/payments/mobile_payment_row.dart`) in a
  `Tooltip(message: row.employeeName)`.
