## Problem

Two issues with the Decline sheet dialog.

1. No character limit on the comment field.
   The backend enforces a 200-character limit on the decline comment
   (ExpenseSheetDeclineCommentRequired / validation in the API). The Flutter TextField
   has no maxLength set (decline_sheet_dialog.dart line 97), so the manager can type
   an unlimited comment and only discover the limit when the API rejects it with a
   400 error. The limit should be enforced in the UI with a visible counter.

2. No explanation of what happens after decline.
   The dialog shows only a title and a comment field. The manager gets no context
   about the consequences of declining. The dialog should explain that the employee
   will be notified and will be able to correct the sheet and resubmit.
   The employee name should be shown so the action feels personal and deliberate.

## Reproduce Steps

1. Open a sheet in WaitingForApproval as a manager.
2. Click "Decline sheet".
   -- Observe: dialog shows only "Decline sheet" title + comment field.
      No explanation text. No character counter (issue 2).
3. Type more than 200 characters in the comment field and click Decline.
   -- Observe: API returns 400. Error is shown after the fact (issue 1).

## Suggested Solution Approach

1. Add maxLength: 200 to the TextField and set maxLengthEnforcement to enforced.
   Flutter will render a live character counter automatically.

2. Pass the employee name into the dialog. Add a subtitle line below the title:
   "[Employee Name] will be notified and will be able to correct and resubmit
   the sheet."

## Suggested Fix

File: lib/widgets/sheet_review/decline_sheet_dialog.dart

  Add employeeName parameter to DeclineSheetDialog and pass it from the call site
  (sheet_review_screen.dart).

  TextField (line 97): add
    maxLength: 200,
    maxLengthEnforcement: MaxLengthEnforcement.enforced,

  Below the title Text (after line 87), add employee context:
    Text(
      "[employeeName] will be notified and will be able to correct and resubmit.",
      style: TextStyle(fontSize: 13, color: AppTheme.mutedForeground),
    )

File: lib/screens/sheet_review_screen.dart
  Pass sheet.createdByName (or equivalent) into DeclineSheetDialog.show().

File: lib/l10n/app_en.arb + app_he.arb
  Add a new l10n string for the subtitle with an {employeeName} placeholder.
