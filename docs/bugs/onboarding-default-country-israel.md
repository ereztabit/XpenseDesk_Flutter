# Bug: Company Onboarding — Israel Should Be the Default Country

## Problem

During company onboarding, the country field starts empty and the user must
manually select a country. Israel should be pre-selected as the default, so the
user does not need to choose it in the common case.

## Reproduce

1. Start a new company onboarding.
2. Reach the company details step.
3. **Result:** Country is unselected; the user must pick it.
4. **Expected:** Israel is pre-selected by default (still changeable).

## Suggested Solution

Default the country selection to Israel on a fresh onboarding (no saved value),
including its derived defaults (currency, language, time zone). The user can still
change it.

_(To be expanded.)_
