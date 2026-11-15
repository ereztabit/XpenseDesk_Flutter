# Bug: Expense detail receipt panel overflows by 2px in Hebrew

> **Status: new**

## Problem

On the employee "edit expense" screen at desktop width, switching the UI to
Hebrew makes the receipt panel column 2px too tall for its box. A thin
yellow-and-black overflow stripe appears under the receipt image. Visual
polish only - nothing is hidden that matters, and English is not affected.

Found in FS-1010 manual QA, 2026-11-15 (spec docs/completed/company-modules-and-categories-spec.md, Manual QA run 1, finding 6).

## Reproduce Steps

1. Sign in as an employee (dev: e@xpensedesk.com) at desktop width (1440x900).
2. Open any existing expense for editing.
3. Switch the header language to Hebrew.
   -- Expected: the receipt panel fits.
   -- Actual: an overflow stripe under the receipt panel; the debug console
      shows "A RenderFlex overflowed by 2.0 pixels on the bottom" from the
      Column in lib/screens/employee_expense_detail_screen.dart (~line 1390,
      the Expanded column holding ExpenseModifyImagePanel), inside an
      IntrinsicHeight Row.

## Suggested Solution Approach

The receipt panel should size to its content in both languages.

## Suggested Fix

The layout is `IntrinsicHeight` -> `Row` -> `Expanded(Column)`, the pattern the
CR rules flag (Rule 6: IntrinsicHeight + Expanded + text sub-pixel overflows
under dart2js). The Hebrew font's taller line height makes the right column 2px
taller than the left. Drop the `IntrinsicHeight` and size the panel without it
(or let the right column scroll / clip), then re-check in EN and HE.
