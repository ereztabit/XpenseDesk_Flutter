## Problem

On the company onboarding page (company_details_step.dart), the cycle day field is
rendered as a DropdownMenu<int> (line 399). It should be a set of radio buttons
instead, one per available day option (currently: 1, 2, 10, 15).

Additionally, the field label is a generic "onboardingCycleDay" string. It should
clearly explain to the user what this setting means in business terms -- i.e. that
this is the day of the month on which expenses are automatically submitted to the
manager for approval.

## Reproduce Steps

1. Start company onboarding.
2. Reach the company details step.
   -- Observe: cycle day is shown as a dropdown ("-- Select --").
   -- Observe: label gives no context about what the cycle day controls.

## Suggested Solution Approach

Replace the DropdownMenu<int> with a row (or wrapped row) of radio buttons, one per
option (1st, 2nd, 10th, 15th of the month). The currently selected day is highlighted.

Update the field label and add a subtitle explaining:
  "Monthly expenses cut-off day -- on this day, all expenses are automatically
   submitted to the manager for approval."

Both EN and HE l10n strings need to be updated.

## Suggested Fix

File: lib/screens/onboarding/steps/company_details_step.dart (lines 396-414)

Replace DropdownMenu<int> with a Wrap of radio-style tiles:
  Wrap(
    spacing: 8,
    children: [1, 2, 10, 15].map((day) =>
      ChoiceChip(
        label: Text('${l10n.onboardingCycleDayPrefix} $day'),
        selected: _selectedCutoverDay == day,
        onSelected: (_) => setState(() => _selectedCutoverDay = day),
      )
    ).toList(),
  )

Or use a Column of Radio<int> widgets if the design calls for a vertical layout.

File: lib/l10n/app_en.arb + app_he.arb
  Update "onboardingCycleDay" label to something like:
    EN: "Monthly cut-off day"
  Add a new subtitle key:
    EN: "On this day, all expenses are submitted to the manager for approval."
    HE: "בתאריך זה, כל ההוצאות נשלחות למנהל לאישור."
