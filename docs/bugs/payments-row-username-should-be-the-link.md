# Bug: Make the employee name the clickable link, not the whole row

> **Status: new**

## Problem

The entire row is tappable to open the sheet, but nothing signals that. Users
can't tell how to reach the sheet detail. The employee name should be the
clickable element, styled as a link, so the affordance is obvious.

## Reproduce Steps

1. Open the Payments Report.
2. Try to find how to open a sheet's detail.
   -- Expected: the employee name looks like a link and opens the sheet.
   -- Actual: the whole row is tappable with no visual affordance; the name is
      plain text.

## Suggested Solution Approach

Move the open-sheet tap target onto the employee name and give it link styling
(color + pointer cursor on web). Remove (or keep secondary) the whole-row tap.

## Suggested Fix

- `lib/widgets/payments/desktop_payments_row.dart` and
  `lib/widgets/payments/mobile_payment_row.dart`: wrap the employee-name cell in
  an `InkWell`/`GestureDetector` wired to the existing `onRowTap` callback;
  style as a link (`AppTheme.primary`, pointer cursor on web).
- Decide whether the whole-row `onTap` stays (it can conflict with checkbox
  selection). Prefer the name as the sole navigation affordance.
