# Bug: Expense Editor -- Calendar (Date Picker) Not Loaded

## Problem

On the expense editor, when the user taps the expense date field, the calendar
date picker does not load -- it either fails to open or opens without rendering
a usable calendar. The user cannot pick or change the expense date.

## Reproduce Steps

1. Log in as an employee.
2. Open an editable expense (a Pending expense on the current Draft sheet).
3. Tap the expense date field to change the date.
4. Result: the calendar does not load.
5. Expected: a month calendar opens, positioned on the current expense date,
   allowing the user to select a date within the allowed window.

## Suggested Solution Approach

Tapping the date field should always open a working calendar, positioned on the
current expense date and bounded by the same date window the business allows for
reporting an expense.

## Suggested Fix

Primary suspect -- `lib/screens/employee_expense_detail_screen.dart`, `_pickDate()`
(approx. lines 145-160):

- The `initialDate` guard only clamps the LOWER bound:
  `initialDate = _selectedDate.isAfter(firstDate) ? _selectedDate : firstDate`.
  It does not clamp the UPPER bound against `lastDate` (`now`). If `_selectedDate`
  is after `now` (e.g. a future-dated or mis-parsed expense), `showDatePicker`
  violates its assertion `initialDate <= lastDate` and the calendar fails to load.
  Fix: clamp `initialDate` into the closed range `[firstDate, lastDate]`.

- The employee `firstDate` window is `now - 180 days` (6 months), which
  contradicts the adopted 12-month reporting policy (server `ExpenseDateTooOld`
  and the New Expense screen both use 12 months). An expense that is 6-12 months
  old cannot be displayed or re-selected. Align the window to 12 months
  (`DateTime(now.year - 1, now.month, now.day)`).

Secondary checks:

- Localization delegates are present in `lib/main.dart`
  (`GlobalMaterialLocalizations.delegate`, etc.) and both `en` and `he` are in
  `supportedLocales`, so a missing-delegate cause is unlikely -- but confirm the
  picker renders correctly under the Hebrew (RTL) default locale.

- The same `showDatePicker` pattern exists in
  `lib/screens/new_expense_screen.dart` and
  `lib/widgets/expenses/mobile_expense_modal.dart`; once the editor fix is
  confirmed, apply the same `initialDate` clamping there for consistency.

Note: confirm the exact symptom (picker does not open at all vs. opens blank)
during the fix, as it narrows the root cause between the items above.
