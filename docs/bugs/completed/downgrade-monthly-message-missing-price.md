# Bug: Downgrade-to-monthly message is missing the monthly price

> **Status: done**

## Problem

When downgrading to a monthly plan, a confirmation message is shown but it does
not include the price the user will pay each month. The user can't see what
they're agreeing to pay.

## Reproduce Steps

1. Be on a plan that can downgrade to monthly (e.g. yearly).
2. Initiate the downgrade to monthly.
3. Read the confirmation message.
   -- Expected: the message states the monthly amount that will be charged going
      forward.
   -- Actual: the message has no monthly price.

## Suggested Solution Approach

Include the monthly billing amount in the downgrade confirmation copy.

## Suggested Fix

Needs investigation. Locate the downgrade-to-monthly confirmation dialog and add
the monthly price, formatted via `num.toCurrency(companyLocale, currencyCode)`.
String scaffolding via ARB (en + he) with the amount concatenated in the widget
layer (no ARB placeholders).

## Implementation

The surface the user flagged is the **pending-switch banner** on the Current Plan
card (`billing_current_plan_card.dart`, `_PendingSwitchBanner`) shown after a
downgrade is scheduled — its caption read "Your plan will switch to monthly on
{date}" with no price. The amount is already on `futurePlan.chargeAmount`.

Added ARB key `billingPendingSwitchCost` ("at a cost of" / "בעלות של") and the
banner now renders "{billingPendingSwitchTo} {plan} {billingPendingSwitchCost}
{amount}" on line 1 (amount = `futurePlan.chargeAmount` formatted with the
company `currencySymbol` via `toCurrencyWithSymbol`), date on line 2. Generic for
both directions (also shows the price for a scheduled annual switch). No ARB
placeholders; amount concatenated in the widget.

Target caption (he): "התכנית שלך תעבור ל חודשית בעלות של ₪XX" + "ב [תאריך]".

## Resolution

Shipped on `develop`, verified by the user. `_PendingSwitchBanner` in
`billing_current_plan_card.dart` now appends the future-plan charge to its first
line: "{billingPendingSwitchTo} {plan} {billingPendingSwitchCost} {amount}",
amount = `futurePlan.chargeAmount.toCurrencyWithSymbol(locale, currencySymbol)`
(company currency from `companyProvider`). Added ARB key
`billingPendingSwitchCost` (en + he). CR clean, security review clean (display
only), analyze clean, prod build green. Part of the v1.7 batch (no version bump).

Files: lib/widgets/company_config/billing_current_plan_card.dart,
lib/l10n/app_en.arb, lib/l10n/app_he.arb.
