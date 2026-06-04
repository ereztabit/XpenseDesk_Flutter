## Problem

The country dropdown on the onboarding company details step allows the user to
change the country away from Israel. For now, only Israel is supported, so the
field should be disabled -- showing Israel as the selected value but not allowing
changes.

## Reproduce Steps

1. Start company onboarding.
2. Reach the company details step.
3. Click the country dropdown.
   -- Observe: all countries are listed and selectable.
   -- Expected: the dropdown is disabled; Israel is shown but cannot be changed.

## Suggested Fix

File: lib/screens/onboarding/steps/company_details_step.dart (line 326-340)

The DropdownMenu<String> for country already has an initialSelection.
Add enabled: false to lock it:

  DropdownMenu<String>(
    initialSelection: _selectedCountryCode,
    enabled: false,      // <-- add this
    expandedInsets: EdgeInsets.zero,
    ...
  )

When more countries are supported, remove this flag.
