## Problem

The "Approve sheet" confirmation dialog shows generic, unhelpful text and contains
a word duplication bug.

Current text: "Approve all 2 items items on this sheet?"
  - "items items" is duplicated -- the unit variable and the l10n suffix both
    contribute the word "items" (approve_sheet_confirm_dialog.dart line 32 +
    approveSheetConfirmBodySuffix in app_en.arb line 601).
  - The text gives the manager no meaningful context before confirming an
    irreversible action.

Required text:
  Title:  "Approve sheet"
  Body:   "Approve expense of [total amount] for [employee name]?
           After approval you will no longer be able to edit."

## Reproduce Steps

1. Log in as a manager and open a sheet in WaitingForApproval.
2. Click "Approve sheet".
   -- Observe: dialog reads "Approve all 2 items items on this sheet?"
   -- Expected: dialog reads "Approve expense of [X] for [Name]? After approval
      you will no longer be able to edit."

## Suggested Solution Approach

Pass the total amount (formatted) and employee name into the dialog alongside
itemCount. Update the l10n strings to a single body string that embeds both values.
Add the warning sentence about no further edits.

## Suggested Fix

File: lib/widgets/sheet_review/approve_sheet_confirm_dialog.dart
  Add required parameters: employeeName (String), totalAmount (String).
  Replace the concatenated body string with a single l10n key that takes both
  as placeholders.

File: lib/l10n/app_en.arb
  Remove approveSheetConfirmBodyPrefix and approveSheetConfirmBodySuffix.
  Add:
    "approveSheetConfirmBody": "Approve expense of {amount} for {name}?\nAfter approval you will no longer be able to edit.",
    "@approveSheetConfirmBody": { "placeholders": { "amount": {}, "name": {} } }

File: lib/l10n/app_he.arb
  Same change in Hebrew.

File: lib/screens/sheet_review_screen.dart line 78:
  Pass totalAmount and employeeName from the sheet detail into the dialog.
