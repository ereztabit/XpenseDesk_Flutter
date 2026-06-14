# Bug: Amount column is too wide and the value should be centered

> **Status: done**

## Resolution

Narrowed the amount column (100 → 86) and centered the value and its header.
Files: `lib/widgets/payments/payments_table_columns.dart`,
`lib/widgets/payments/desktop_payments_row.dart`,
`lib/widgets/payments/desktop_payments_header_row.dart`. Verified by user.

## Problem

The amount column on the payments table is too large, and the amount value should
be centered within it.

## Reproduce Steps

1. Open the Payments Report.
2. Look at the Amount column.
   -- Expected: a tighter column width with the value centered.
   -- Actual: the column is oversized; the value is not centered.

## Suggested Fix

- Reduce the amount column width in
  `lib/widgets/payments/payments_table_columns.dart`.
- Center the amount cell content in
  `lib/widgets/payments/desktop_payments_row.dart` (and the mobile row cell if
  applicable, `lib/widgets/payments/mobile_payment_row.dart`).
