# Bug: Cancel-plan confirmation message is confusing during free / coupon-free period

> **Status: done**

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

## Root cause

The confusing part was a wrong date. The danger-zone notice and the cancel dialog
both showed "your subscription stays active until {date}" using
`subscription.endDate`. For a company still in trial with a commitment, the JSON
has `subscription.endDate` = the end of the *first paid period* (e.g. 1 Oct) — but
that paid period never starts if the user cancels during the trial. While
`company.isInTrial` is true (trialEndDate e.g. 1 Sep), access actually ends at the
trial end, not the never-charged paid period's end. So it showed 1 Oct instead of
1 Sep.

## Fix

`BillingDangerZoneCard` now takes an `accessUntilDate` instead of the raw
subscription. The caller in `company_config_screen.dart` computes it:
`isInTrial && trialEndDate != null ? trialEndDate : subscription.endDate`. That
date flows into both the danger-zone notice and the `CancelSubscriptionDialog`
(which already renders the passed `endDate`). No new strings needed — the wording
was fine; the date was wrong.

Files: lib/widgets/company_config/billing_danger_zone_card.dart,
lib/screens/company_config_screen.dart.

Shipped on `develop` as part of the v1.7 batch (no version bump). Analyze clean,
prod build green.
