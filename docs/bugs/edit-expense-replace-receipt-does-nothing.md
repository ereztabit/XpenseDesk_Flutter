# Bug: "Replace receipt" on the edit expense screen does nothing

> **Status: new**

## Problem

On desktop, the edit expense screen shows a "Replace receipt" button on the
receipt image of an editable expense. Clicking it does nothing: no file picker,
no upload, no message. A user who attached the wrong receipt has no way to fix
it except deleting the expense and filing it again.

Found while building FS-1007 S3 (free receipts) on 2026-09-30. The UI/UX design
guide (backend `docs/bulk-upload/ui-ux-design-guide.md` §8.4) expects "Replace
receipt" to work "as for any expense", and on trial to use a free receipt. S3
left this button alone, because there was nothing to gate: it never scans.

## Reproduce Steps

1. Sign in as an employee (desktop width, 768 or wider).
2. Open any Pending expense on the current draft sheet (My expenses, then the
   pencil icon).
3. Click "Replace receipt" on the receipt image.
   -- Expected: a file picker opens; the new receipt is scanned and replaces the
      image (and, on trial, uses a free receipt).
   -- Actual: nothing happens.

The button is wired to an empty callback:
`lib/screens/employee_expense_detail_screen.dart` passes
`ExpenseModifyImagePanel(onReplace: () {})` in both layouts (desktop around
line 1371, mobile around line 1405). `UpdateExpenseRequest`
(`lib/models/update_expense_request.dart`) has no image field, so a replaced
image could not be saved even if it were picked.

## Suggested Solution

Either make it work (pick a file, scan it with `analyze-receipt`, keep the new
image URL, and save it with the expense; on trial it uses a free receipt and is
disabled at 0, like the new-expense Replace), or hide the button until it does.
The backend `PUT /api/expenses/{id}` has to accept an image URL for the first
option; check the API before choosing.
