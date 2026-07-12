# Bug: Onboarding plan picker — annual plan missing "2 months free" savings label

> **Status: new**

## Problem

On the onboarding page where the user picks their program (plan selection step),
the yearly/annual plan is presented with no explanation of its value versus the
monthly plan. There is no label telling the user the annual plan effectively
includes 2 months free (~16% discount). Users have no visible reason to prefer
the annual plan.

For comparison, the billing screen inside company config already shows a
"Best Value" badge and a savings label on the annual card — the onboarding
picker does not, so the two surfaces are inconsistent.

## Reproduce Steps

1. Start the onboarding flow and reach the "pick your program" / plan selection
   step.
2. Look at the annual (yearly) plan card next to the monthly card.
   -- Expected: the annual card shows a savings/value hint, e.g. a "Best Value"
      badge and a "2 months free (16% discount)" style label.
   -- Actual: the annual card shows only price and period, with no savings or
      value explanation.

## Suggested Solution Approach

Surface the annual plan's value on the onboarding picker the same way the billing
screen does: a badge and a savings label on the annual card, so the discount is
obvious at decision time.

## Suggested Fix

`PlanCard` (lib/widgets/plan_selection/plan_card.dart) already supports
`badgeLabel` and `savingsLabel`, but the onboarding step does not pass them.

In [plan_selection_step.dart:233](lib/screens/onboarding/steps/plan_selection_step.dart)
the `PlanCard(...)` is constructed without `badgeLabel` / `savingsLabel`. Mirror
what the billing card does at
[billing_current_plan_card.dart:1179](lib/widgets/company_config/billing_current_plan_card.dart:1179):

```dart
badgeLabel: plans[i].isAnnual ? l10n.bestValue : null,
savingsLabel: plans[i].isAnnual ? l10n.savePercent : null,
```

Note: the requested wording is "2 months free (16% discount)". The existing
`savePercent` ARB string is currently "Save 17%" (app_en.arb:578). Decide with
the user whether to reuse `savePercent`, tweak it, or add a new ARB key (e.g.
`annualMonthsFree`) so the onboarding label reads "2 months free (16% discount)".
Add both English and Hebrew ARB strings before wiring the widget.
