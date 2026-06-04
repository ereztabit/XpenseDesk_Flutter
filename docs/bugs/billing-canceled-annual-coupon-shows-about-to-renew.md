# Bug: Canceled Annual Subscription With Coupon Still Shows "About to Renew"

## Problem

A company that subscribed to the annual plan using a coupon code and then
canceled its subscription still shows as "about to renew" on the billing screen.
A canceled subscription must clearly read as canceled, never as renewing -- the
coupon path appears to skip or override the canceled-state display logic.

## Reproduce Steps

1. Create a new company.
2. End its trial.
3. Subscribe to the annual plan using a coupon code.
4. Cancel the subscription.
5. Open the billing screen (Company Config -> billing).
   -- Expected: subscription shows as canceled (will end on <date>, not renewing).
   -- Actual: still displays as "about to renew".

## Suggested Solution Approach

The plan-status text should derive from the cancellation state first, regardless
of how the subscription was created (coupon or not). A canceled subscription with
a coupon should fall through the same "canceled / ends on <date>" branch as a
canceled subscription without a coupon.

## Suggested Fix

Investigate (not yet pinned to a line):
- `lib/widgets/company_config/billing_current_plan_card.dart` -- the renew vs.
  canceled status text. Confirm the canceled branch is reached when a coupon is
  present (the coupon/discount fields may be short-circuiting the status logic).
- `lib/models/company_billing.dart` -- the field(s) that distinguish "renewing"
  from "canceled" (e.g. a cancel-at-period-end / next-charge flag). Verify the
  server payload sets the canceled flag for the coupon path, and that the model
  maps it.
- `lib/providers/billing_provider.dart` -- confirm the screen reads the canceled
  state from the freshest payload.

Likely root cause is on the server side (the canceled flag / next-charge fields
not being set for a coupon-discounted annual subscription); confirm via the API
billing payload before changing client display logic.
