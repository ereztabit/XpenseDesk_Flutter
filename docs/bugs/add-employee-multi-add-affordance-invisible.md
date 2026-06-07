# Bug: "Add employee" multi-add affordance is invisible

> **Status: new**

## Problem

When adding an employee, it is not clear that you can add multiple employees in
this box. There is no visible affordance for adding another row.

## Reproduce Steps

1. Open the add-employee box.
2. Look for a way to add a second employee.
   -- Expected: an obvious "+ Add another employee" control.
   -- Actual: no visible affordance; multi-add is undiscoverable.

## Suggested Solution Approach

Make multi-add discoverable and reversible.

## Suggested Fix

- Render the employee inputs as a dynamic list (`ListView` / `Column` over a list
  of controllers). Below the last row, show an explicit text button
  `+ Add another employee`.
- Each added row gets its own remove (x) affordance so the action is reversible.
- Keep the first row always visible so the control is discoverable even with an
  empty form.
