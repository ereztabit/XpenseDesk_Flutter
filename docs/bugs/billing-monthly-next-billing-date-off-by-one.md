# Bug: Billing page shows next billing date one day late for monthly plan

> **Status: new**

## Problem

After onboarding onto a monthly plan, the billing page displays a "next billing
date" that is one day later than it should be. The value stored in the database
appears to be correct, so this looks like a client-side display/parsing issue
(likely timezone / UTC-to-local off-by-one).

## Reproduce Steps

1. Onboard onto a monthly plan.
2. Open the billing page.
   -- Expected: next billing date matches the DB value.
   -- Actual: the displayed date is +1 day vs the DB value.

## Suggested Solution Approach

Display the same calendar date the server stores, with no timezone-induced
shift.

## Suggested Fix

Needs investigation. Likely a UTC date being converted to local time and tipping
over midnight. Review how the next-billing date is parsed and formatted on the
billing page — ensure the date is treated as a plain calendar date (no TZ
conversion) and formatted via the `format_utils.dart` company-locale helpers.
