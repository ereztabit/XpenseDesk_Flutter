# Bug: Billing page shows next billing date one day late for monthly plan

> **Status: done**

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

## Root cause

Not a timezone issue — it was deliberate (wrong) client date math.
`_NextChargeBox` in `billing_current_plan_card.dart` computed the charge date via
`_firstChargeDateAfterTrial(trialEnd, freeMonths)`, which ended with
`base.add(const Duration(days: 1))` — an explicit +1 day. So a trial ending
1 Sep showed the charge on 2 Sep. (It also stacked free months onto trialEnd with
a month-add the code comment itself flagged as a rollover hack.)

Confirmed against the billing JSON: `subscription.startDate` = "2026-09-01" is the
real first-charge date, while the box showed 2 Sep.

## Fix

Removed `_firstChargeDateAfterTrial` and set the box's `chargeDate` to the
server's `subscription.startDate` (falling back to `trialEndDate` for older
payloads without it). `startDate` is the authoritative day the paid period begins
— already accounting for the trial and any free months — so no client date math
and no +1. File: lib/widgets/company_config/billing_current_plan_card.dart.

Shipped on `develop` as part of the v1.7 batch (no version bump). Analyze clean,
prod build green.
