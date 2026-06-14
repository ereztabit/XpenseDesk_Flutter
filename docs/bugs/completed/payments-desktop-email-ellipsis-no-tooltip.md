# Bug: Desktop email cell ellipsizes with no tooltip

> **Status: done**

## Resolution

The desktop email cell is wrapped in a `Tooltip` showing the full address on
hover (dash rows render plain, no tooltip). File:
`lib/widgets/payments/desktop_payments_row.dart`. Verified by user.

## Problem

On desktop the email column truncates with an ellipsis but provides no tooltip,
so the full address is unreadable.

## Reproduce Steps

1. Open the Payments Report on desktop with a long employee email.
2. Hover the truncated email.
   -- Expected: a tooltip showing the full email.
   -- Actual: ellipsis only; full address is not viewable.

## Suggested Fix

- `lib/widgets/payments/desktop_payments_row.dart`: wrap the ellipsized email
  `Text` in a `Tooltip(message: email)`.
- Note: once cells become selectable (see
  docs/bugs/payments-text-not-selectable-cross-app.md), the full value will also
  be copyable, but a tooltip is still the right hover affordance.
