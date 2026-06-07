# Bug: Disable Currency Selection on Onboarding (MVP — ILS only)

> **Status: done**

## Problem

The onboarding company-details step lets a new company pick its base currency
from a dropdown (under "Modify defaults"). For the MVP only ILS is supported end
to end, so allowing any other currency to be selected sets a base currency the
rest of the product can't yet handle. The field should be disabled until
multi-currency support ships.

## Reproduce Steps

1. Start the onboarding flow and reach the company-details step.
2. Expand the country-defaults panel ("Modify defaults").
3. Open the Currency dropdown.
   -- Expected: currency is fixed (ILS, the country default for Israel) and not
      changeable during the MVP.
   -- Actual: the user can select any supported currency.

## Suggested Solution Approach

Keep the currency visible (so the user sees their base currency) but make it
non-editable for now. The default already resolves from the selected country
(ILS for Israel), so no behavior changes besides removing the ability to change
it. Re-enable when multi-currency lands — see
docs/in-progress/multi-currency-expenses.md.

## Suggested Fix

In `lib/screens/onboarding/steps/company_details_step.dart`, the currency
`DropdownMenu<String>` is inside the `_DefaultsPanel` widget (around lines
647-661). Set `enabled: false` on that `DropdownMenu` so it renders the resolved
currency but cannot be changed. The auto-fill logic that sets
`_selectedCurrencyCode` from the country default stays as-is, so submission still
sends the correct base currency.

Note: this is a UI-disable only. Do not remove the field or the
`onCurrencyChanged` plumbing — it should be trivially re-enabled when
multi-currency support is implemented.

## Resolution

Added `enabled: false` to the currency `DropdownMenu<String>` in the
`_DefaultsPanel` widget in
`lib/screens/onboarding/steps/company_details_step.dart` (with a comment
pointing at docs/in-progress/multi-currency-expenses.md for re-enabling). The
currency stays visible (greyed) showing the country default (ILS for Israel),
and the auto-fill plumbing (`_selectedCurrencyCode`, `onCurrencyChanged`) is
untouched, so onboarding still submits the correct base currency. Verified by
the user in the browser. `flutter build web` passed.
