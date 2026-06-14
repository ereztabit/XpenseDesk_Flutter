# Bug: Edit dialog cannot revert a sheet back to awaiting payment

> **Status: new**

## Problem

The edit dialog for a processed sheet only lets the manager correct
date/reference/note — it does not allow reverting the status. A manager who
accidentally marked a sheet as processed has no way to say "this was a mistake,
it is still waiting for payment." Also the dialog title should read "Edit Sheets
Payment Status" (it currently reflects an edit-details-only intent).

Note: this reverses the earlier scope ruling (QA item 1: "only edit, no revert").
The user now wants revert back in, surfaced through the same edit dialog.

## Reproduce Steps

1. Mark a sheet as processed.
2. Open the edit dialog for that sheet.
   -- Expected: ability to set the status back to "awaiting payment", and a
      dialog title "Edit Sheets Payment Status".
   -- Actual: only date/reference/note are editable; no revert; title is
      edit-details only.

## Suggested Solution Approach

Bring revert back into the edit dialog as a status control. Reverting to awaiting
should clear/ignore the processed-only fields (date becomes optional). Title
becomes "Edit Sheets Payment Status".

## Suggested Fix

- `lib/widgets/payments/edit_payment_dialog.dart`: add a status toggle/control
  (Processed <-> Awaiting). When Awaiting is chosen, the processed-date field is
  no longer required.
- Service already supports status changes: `PaymentService.updatePayment(status:)`
  — call with `PaymentStatus.awaitingPayment` on revert.
- On revert under the Processed/All views, the row should update or leave the set
  per the existing in-place-removal vs refresh logic in
  `payments_report_screen.dart` (`_editRow`).
- Title: change `l10n.editPaymentTitle` to "Edit Sheets Payment Status" (EN) +
  the Hebrew equivalent in both ARB files.
- Re-validate the concurrency handling (`onConflict`) still holds for the revert
  path.
