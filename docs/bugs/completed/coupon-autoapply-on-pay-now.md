# Bug: Coupon code typed but not applied should auto-apply on "Pay Now"

> **Status: done**

## Problem

On the billing/checkout page a user can type a coupon code into the field but not
press "Apply", then press "Pay Now". Today the payment proceeds without the
coupon, so the user loses the discount they intended.

## Reproduce Steps

1. Go to the billing/checkout page.
2. Type a valid coupon code in the coupon field but do NOT press "Apply".
3. Press "Pay Now".
   -- Expected: the system auto-applies the typed coupon, verifies it succeeded,
      and charges the discounted amount (or surfaces an error if invalid).
   -- Actual: the coupon is ignored and full price is charged.

## Suggested Solution Approach

Treat a non-empty coupon field as intent to use the coupon. On "Pay Now",
apply + validate the coupon before charging; block the charge and show an error
if the coupon is invalid.

## Suggested Fix

Needs investigation. In the Pay Now handler, if the coupon input is non-empty and
not yet applied, run the apply/validate path first and only proceed to charge on
success. Reflect the applied discount in the confirmed amount.

## Implementation

The typed text lived in `CouponSection`'s private controller, so the parent's
pay handler couldn't see it. Approach: expose a public `applyPendingCoupon()` on
`CouponSection` (reuses its existing validate/lock/fail logic) and invoke it via
a `GlobalKey<CouponSectionState>` at the top of each pay handler, before the
Tranzila payment popup opens.

- `lib/widgets/plan_selection/coupon_section.dart`: made the state class public
  (`CouponSectionState`) and added `Future<bool> applyPendingCoupon()` — returns
  true when safe to proceed (already applied / nothing typed / blocked), false
  when a typed coupon is invalid.
- `lib/screens/onboarding/steps/plan_selection_step.dart` and
  `lib/widgets/company_config/billing_current_plan_card.dart` (`_NoPlanCard`):
  hold a `GlobalKey<CouponSectionState>`, pass it to `CouponSection`, and call
  `applyPendingCoupon()` in `_handleProceed`. On invalid (false) -> abort, keep
  the user on the form; the section already shows the inline "invalid coupon"
  error. **Decision (user): invalid coupon blocks payment** rather than charging
  full price.

Both pay surfaces (onboarding + billing no-plan card) are covered.

## Resolution

Shipped on `develop`, verified by the user. `applyPendingCoupon()` on
`CouponSection` (public state `CouponSectionState`) is invoked via a
`GlobalKey<CouponSectionState>` at the top of `_handleProceed` in both
`plan_selection_step.dart` and `billing_current_plan_card.dart` (`_NoPlanCard`),
before the Tranzila popup opens. Invalid typed coupon blocks payment and shows
the inline error (user's decision). CR clean, security review clean,
`flutter analyze` clean on the touched files, prod build green. Part of the v1.7
bug batch (no version bump).

Files: lib/widgets/plan_selection/coupon_section.dart,
lib/screens/onboarding/steps/plan_selection_step.dart,
lib/widgets/company_config/billing_current_plan_card.dart.
