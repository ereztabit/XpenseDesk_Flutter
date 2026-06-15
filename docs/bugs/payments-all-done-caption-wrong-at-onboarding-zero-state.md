# Bug: "Payments all done" caption is wrong on a fresh (all-zeros) dashboard

> **Status: new**

## Problem

On the manager dashboard, the awaiting-payment summary shows an "all clear / all
done" message even when the company is brand new and in the onboarding/empty state
(every counter is zero). That is misleading: nothing is awaiting payment because no
sheets exist yet, not because the manager has finished paying everything. A first-
time user reads "all done" as if they already completed work they never started.

## Reproduce Steps

1. Sign in as a manager of a brand-new company (no cycles, no sheets, all
   dashboard counters at 0 - the onboarding state).
2. Look at the awaiting-payment area on the manager dashboard.
   -- Expected: a neutral empty/onboarding message (e.g. "Nothing to pay yet" or
      no "all done" framing at all).
   -- Actual: shows the "all clear / all done" caption as if payments were
      completed.

## Suggested Solution Approach

Distinguish "zero because finished" from "zero because nothing exists yet". In the
onboarding/empty state the caption should not claim completion.

## Suggested Fix

Look at `lib/widgets/manager_dashboard/awaiting_payment_card.dart` - the
`awaitingPaymentAllClear` / `awaitingPaymentAllClearHint` strings render whenever
the awaiting count is 0. Gate the "all clear" wording behind "there has been at
least some activity" (e.g. total sheets/cycles > 0); otherwise show an onboarding-
appropriate empty caption. New ARB keys may be needed (add to both `app_en.arb`
and `app_he.arb` per the localization rule). Confirm whether the same all-zeros
problem affects the other dashboard summary cards (e.g. approved/pending) while in
there.
