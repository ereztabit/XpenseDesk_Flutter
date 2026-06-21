# Bug: Cancel-plan confirmation message is confusing during free / coupon-free period

> **Status: new**

## Problem

When a user cancels their plan while in a free trial or a coupon-driven free
period, the cancellation confirmation message is confusing — it does not clearly
explain what happens to the free period, when access ends, and whether anything
will be charged.

## Reproduce Steps

1. Be on a plan in a free trial or coupon-free period.
2. Initiate "cancel plan".
3. Read the confirmation dialog.
   -- Expected: a clear message stating the free period continues until its end
      date, no charge will occur, and what state the account moves to after.
   -- Actual: confusing wording that doesn't make the above clear.

## Suggested Solution Approach

Confirmation copy should be specific to the free/coupon state and reassure the
user about no charge and the effective end date.

## Suggested Fix

Needs investigation. Locate the cancel-plan confirmation dialog on the billing
page and add free-period-aware copy. New strings go through ARB (en + he) per
the localization rules — no hardcoded captions.
