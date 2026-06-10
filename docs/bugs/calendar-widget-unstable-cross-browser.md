# Bug: Calendar widget is unstable and not cross-browser

> **Status: new (postponed — future bug fix)**

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

## Investigation notes (2026-06, postponed)

Investigated but deferred by request. Findings for whoever picks this up:

- The date picker is **Flutter's built-in Material `showDatePicker`** — not a
  custom widget and not a package (nothing calendar-related in `pubspec.yaml`).
  Used in 3 places: `lib/screens/new_expense_screen.dart`,
  `lib/widgets/expenses/mobile_expense_modal.dart`,
  `lib/screens/employee_expense_detail_screen.dart`.
- `firstDate` is already set **12 months back** (employees) / 5 years
  (managers) — NOT `DateTime.now()`. So the "can't navigate to previous months"
  hypothesis above does not match the current code; back-navigation range is
  correct. `initialDate` is also clamped into `[firstDate, lastDate]` (the
  load-failure assert was a separate bug, already closed).
- The project is on **Flutter 3.41.2**. As of Flutter 3.29 the HTML web renderer
  was removed; web is **CanvasKit-only**, which renders identically across
  Chrome / Edge / Opera (all Chromium). The single biggest historical cause of
  "differs per browser" no longer exists on this version.
- Conclusion: this report is likely **already resolved** by the earlier
  firstDate/clamp fixes + the Flutter upgrade. Recommended first step when
  resumed is to **verify on current build across the 3 browsers**, not to
  replace the widget. Only consider a package (e.g. `table_calendar`, MIT) if a
  makeover wants an *inline* calendar UX — that's a design decision, not a bug
  fix, and means re-owning RTL / company-locale / the 12-month rule / theming
  by hand. (Syncfusion has commercial-licensing implications — avoid unless
  vetted.)
