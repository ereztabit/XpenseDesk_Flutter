# Bug: Coupon code typed but not applied should auto-apply on "Pay Now"

> **Status: new**

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
