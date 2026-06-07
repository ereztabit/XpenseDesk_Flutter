# Bug: Calendar widget is unstable and not cross-browser

> **Status: new**

## Problem

The calendar / date-picker widget is very unstable. You cannot navigate back to
previous months, and it behaves differently on Opera and Edge than on Chrome. We
do not want to fail on technicalities, so we should consider switching to a more
robust calendar component.

## Reproduce Steps

1. Open the expense editor and tap the date field to open the calendar.
2. Try to page back to a previous month.
   -- Expected: smooth navigation back across months, identical across browsers.
   -- Actual: cannot navigate back; rendering/behavior differs on Opera and Edge
      vs Chrome.

## Suggested Solution Approach

Provide a stable, cross-browser date selection experience for adding expenses,
supporting at least 12 months of back-dating (see the out-of-range date bug).

## Suggested Fix

- Replace the current date-picker with a well-maintained, cross-browser package
  rather than patching the existing one. Candidates: built-in `showDatePicker` /
  `CalendarDatePicker` (Material), or a vetted package (`table_calendar`,
  `syncfusion_flutter_datepicker`).
- The "can't go to previous months" symptom usually means `firstDate` is set to
  `DateTime.now()`. Set `firstDate` far enough back to honor the 12-months-back
  business rule.
- Cross-browser differences on Flutter Web typically come from HTML vs CanvasKit
  renderer. Standardize the build on CanvasKit so rendering is identical across
  Chrome / Edge / Opera.
- Add a smoke test of date navigation (open -> page back a month -> pick a date)
  and run on Chrome, Edge, and Opera before sign-off.
