# Coupon-code verbiage review (billing)

> **Status:** Planned — copy-only, no logic change. Polish item.

## Problem

The coupon "free months" messaging doesn't clearly tell the customer **when they
will first be charged**, and it reads differently in two billing states. The
underlying date math is already correct — this is purely about wording.

## The mechanic (already correct)

A coupon grants **free months that stack on top of the trial**. First charge =
trial end **+** free months. So a user can have both a trial countdown and coupon
free-months active at once. See
`lib/widgets/company_config/billing_current_plan_card.dart` `_firstChargeDateAfterTrial`
(lines ~98-108).

## What's unclear

### During trial
The user sees disconnected messages that aren't tied together:
- Coupon apply: "Coupon accepted: 1 free month" (`coupon_section.dart` `_buildSuccessMessage`, ~line 131).
- Trial badge: "Free Trial - ends Apr 20, 2026 (13 days)".
- A "Next Charge" box with a date derived from trial-end + free months.

Nothing connects them into a single clear statement like "trial runs to X, then 1
free month, so your first charge is Y." "1 free month" reads like it might
replace/overlap the trial rather than extend it.

### After trial
Switches to a different component — `_FreeMonthsBanner` "N free months remaining"
(~line 180) — next to "Renews on" / "Next charge amount". Unclear whether "free
months" means no charge during those months, and how that squares with a shown
"next charge amount".

## Task

Rewrite the coupon/free-month strings and the trial/next-charge labels around them
so that in **both** states the customer clearly understands what the coupon does
and the exact date of their first real charge. Strings to revisit:
`couponAccepted`, `couponOneMonthFree`, `couponMonthsFree`, plus the trial /
next-charge labels (`billingNextCharge`, `billingRenewsOn`).

Pure wording — no logic change. Low priority relative to go-live blockers.
