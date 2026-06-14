# Bug: Remove the accounting batch-ID field and fix the comment placeholder

> **Status: new**

## Problem

The mark-processed / edit dialogs include a "מזהה אצווה חשבונאית (אופציונאלי)"
(accounting batch ID / reference) field that is not needed. It should be removed.
Separately, the placeholder text inside the comment/note field also needs
attention (remove / fix it).

## Reproduce Steps

1. Open the mark-as-processed dialog (single or bulk) or the edit dialog.
   -- Expected: no accounting-batch-ID field; the comment field has an
      appropriate placeholder.
   -- Actual: an unnecessary "מזהה אצווה חשבונאית (אופציונאלי)" field is shown;
      the comment placeholder needs revising.

## Suggested Solution Approach

Drop the reference/batch-ID input entirely from the payment dialogs and stop
sending it. Review and correct the comment field's placeholder.

## Suggested Fix

- Reference field: `l10n.referenceIdField` / `l10n.referenceIdPlaceholder`,
  rendered via `DialogTextField` in
  `lib/widgets/payments/mark_processed_dialog.dart` and
  `lib/widgets/payments/edit_payment_dialog.dart`. Remove the field and stop
  passing `reference` to `PaymentService.updatePayment` /
  `processPayments` / `bulkUpdatePayments`.
- Confirm the API treats `reference` as optional (it is — it was sent as
  optional); removing it client-side is safe.
- Comment placeholder: `l10n.notePlaceholder` — confirm intended copy with the
  user, then update in both ARB files (or remove the hint).
- Retire now-unused ARB keys.
