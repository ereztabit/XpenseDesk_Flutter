# Bug: Action cell doesn't read as a button — make it a small "edit" button

> **Status: done**

## Resolution

Replaced the per-row icon with a small "עריכה"/Edit `AppButton` on every row
(desktop + mobile), opening the unified edit dialog. Action column widened to 96
(desktop); mobile uses a fixed 76px slot matching the header spacer. The
per-row `onMarkProcessed` plumbing was collapsed into the single edit path.
Files: `lib/widgets/payments/desktop_payments_row.dart`,
`lib/widgets/payments/mobile_payment_row.dart`,
`lib/widgets/payments/payments_table_columns.dart`,
`lib/widgets/payments/mobile_payments_table.dart`, plus the table/view/screen
plumbing. Verified by user.

## Problem

The action affordance in the table (currently an icon) doesn't look like a
button, so it's unclear it's actionable. It should be a proper button with small
text — "עריכה" / "Edit".

## Reproduce Steps

1. Open the Payments Report.
2. Look at the per-row action.
   -- Expected: a small text button labeled "עריכה" / "Edit" that clearly reads
      as clickable.
   -- Actual: a bare icon that doesn't look like a button.

## Suggested Solution Approach

Replace the icon-only action with a small `AppButton` (text "עריכה"/"Edit"). For
awaiting rows this still triggers mark-processed; for processed rows it opens the
edit dialog. Confirm the desired label per state with the user (the user said
"Edit" — verify whether awaiting rows also show "Edit" or keep "Mark processed").

## Suggested Fix

- `lib/widgets/payments/desktop_payments_row.dart`: swap the `ActionIconButton`
  for a small/dense `AppButton` with localized text. Wire to `onEdit` (processed)
  / `onMarkProcessed` (awaiting) as today.
- Revisit the action column width in
  `lib/widgets/payments/payments_table_columns.dart` (it was shrunk to 64 for the
  icon) to fit a small text button.
- Mirror on mobile (`lib/widgets/payments/mobile_payment_row.dart`) if needed.
- New ARB key "Edit" / "עריכה" in both ARB files.
- Related: docs/bugs/payments-edit-allow-revert-status.md (the dialog this opens).
