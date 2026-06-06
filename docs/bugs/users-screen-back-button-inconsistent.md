# Bug: Users module back button looks different from the rest

> **Status: new**

## Problem

The "Back to dashboard" button on the Users / team management screen does not
look like the back buttons on the other screens (Profile, Company Config, New
Expense, Sheet Approvals, etc.). It feels visually inconsistent.

## Reproduce Steps

1. Open the Users screen and note the back button.
2. Open another screen with a back button (e.g. Profile or Company Config).
   -- Expected: the back button looks and sits the same across all screens.
   -- Actual: the Users screen back button looks different (placement / spacing).

## Suggested Solution Approach

Make the Users back button match the standard pattern used everywhere else.

## Suggested Fix

In `lib/screens/users_screen.dart` the back button is wrapped in an
`Align(alignment: AlignmentDirectional.centerStart)` and the parent `Column` does
not set `crossAxisAlignment: CrossAxisAlignment.start`. The reference screens
(e.g. `lib/screens/profile_screen.dart`, `lib/screens/company_config_screen.dart`)
place the `AppButton` directly as the first child of a
`CrossAxisAlignment.start` Column with no `Align` wrapper, followed by a standard
`SizedBox(height: 16)`.

Needs visual confirmation, but the likely fix is to drop the `Align` wrapper, add
`crossAxisAlignment: CrossAxisAlignment.start` to the screen's `Column`, and match
the standard spacing so the button aligns and renders identically to the others.
