# Bug: A declined expense cannot be resubmitted without editing a field

> **Status: new**

## Problem

An employee whose sheet was declined opens one of the declined expenses to send
it back to the manager. The expense is fine as it is -- nothing needs
correcting (the manager returned the sheet for a different reason, or asked
about it and they sorted it out verbally). The save/update button is greyed
out and stays greyed out. Nothing on the screen says why, and nothing says what
to do. It reads as "this screen is blocked" and the employee is stuck.

The only way through is to change some field -- retype the merchant, nudge the
amount -- which is both stupid and dangerous: the workaround is to falsify a
value in order to get a button to light up.

The server has no such requirement. `proc_UpdateExpense` accepts identical
values on a Declined line of a Declined sheet and still resets it to Pending
(`@ResetToPending = 1`), which is exactly what the employee wants. The block is
purely client-side.

Reported 2026-09-04 (logged in as Sahar, on a declined sheet).

## Reproduce Steps

1. Sign in as a manager, decline an employee's sheet (any comment).
2. Sign in as that employee, open the declined sheet, tap a declined expense.
3. Do not change anything. Look at the save / update button.
   -- Expected: the employee can resubmit the line as-is (it is Declined; the
      act of resubmitting is the change), or at minimum the screen says why the
      button is disabled and what to do.
   -- Actual: the button is disabled with no explanation. The screen looks
      broken. The only workaround is to edit an unrelated field.

## Suggested Solution Approach

Resubmitting a declined line is an action in its own right, not a side effect
of editing it. A declined expense the employee stands behind must be
resubmittable without touching a single field.

Note the overlap with **FS-1003** (`docs/backlog/add-expenses-to-non-approved-sheet-spec.md`):
that mission adds a whole-sheet "Submit for approval" that clears every
declined line at once, which removes most of the need to open a line at all.
This bug is still real and should be fixed independently -- a disabled button
with no explanation is wrong regardless -- but if FS-1003 lands first, the
per-line fix can be the smaller of the two options below.

## Suggested Fix

The gate is `_isDirty` on the CTA in
`lib/screens/employee_expense_detail_screen.dart` (lines 1030 and 1065:
`onPressed: _isDirty && !_isSaving && _conversion.canSave ? _save : null`).
`_isDirty` (line 132) compares every field against the baseline captured on
load; an untouched form is never saveable. That gate is correct for a Draft
expense -- saving an unchanged line there does nothing -- but wrong for a
Declined line, where saving is what resets it to Pending and moves the sheet
along.

Two options:

1. **Smallest fix:** drop the `_isDirty` requirement when the line is Declined
   on a Declined sheet -- i.e. when `SheetPermissions.canEditExpense` allows
   the edit *and* `expenseStatusId == declined`. The existing pre-resubmit
   confirmation (line 313) already explains what saving does, so the employee
   is not surprised.
2. **Clearer:** in that same state, relabel the CTA from "Save" to "Resubmit"
   and always enable it (subject to `_canSave` / conversion state). The button
   then names the action the employee is actually taking.

Prefer 2 -- it also fixes the wording, which is the other half of why the
screen reads as blocked.

Either way: no disabled CTA without a reason next to it. If the button must
stay disabled in some state (mandatory field empty, FX conversion in flight),
the screen has to say so.
