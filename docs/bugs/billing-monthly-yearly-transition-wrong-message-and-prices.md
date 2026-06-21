# Bug: Monthly/yearly plan transition shows wrong message, wrong prices, and wrong renewal date

> **Status: new**

## Problem

Switching between monthly and yearly billing is broken in two ways:

1. The transition confirmation message is bad and shows the wrong prices.
2. A yearly upgrade reports the wrong next renewal date — it does not credit the
   already-paid period (or the remaining free period), so the new date is
   miscalculated.

## Reproduce Steps

1. Be on a monthly plan (with some paid time and/or a free period remaining).
2. Upgrade to the yearly plan.
   -- Expected: a clear message with correct prices; the new renewal date
      accounts for the already-paid/remaining-free period (proration / credit).
   -- Actual: confusing message with wrong prices; renewal date ignores the
      already-paid or free period.

## Suggested Solution Approach

The transition copy must show the correct amounts, and the renewal date must
factor in any paid-but-unused time and remaining free period.

## Suggested Fix

Needs investigation, with a likely backend component for proration / credited
time. On the client, review the plan-switch confirmation dialog and where the new
renewal date is computed/displayed. Prices and dates use the company-locale
format helpers; strings via ARB. If the renewal-date / proration math is
server-owned, file a matching backend bug.
