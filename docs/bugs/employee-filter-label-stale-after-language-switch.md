# Bug: Employee filter keeps its old-language label after a language switch

> **Status: new**

## Problem

On Sheet Approvals (`/manager-approvals`), the employee filter dropdown keeps
the label it had when the screen loaded. A manager who switches the UI language
while on that screen sees the old language in the field - after switching to
Hebrew it still reads "All employees" in English on an otherwise Hebrew, RTL
screen. On mobile the English label is also cut off ("All employ...") because
the field is a fixed 160px.

Loading the screen directly in Hebrew is fine: "כל העובדים" shows in full. So
only a live language switch on that screen, or English on mobile, shows it.
Minor polish. Found 2026-11-17 during manual QA of the Sheet Review default tab
fix.

## Reproduce Steps

1. Sign in as a manager with the UI in English, open Sheet Approvals on a
   375px-wide viewport.
   -- Actual: the filter reads "All employ..." (cut off).
2. Without leaving the screen, switch the language to Hebrew from the menu.
   -- Expected: the filter reads "כל העובדים".
   -- Actual: it still reads "All employ..." in English.
3. Reload the page (or navigate away and back) in Hebrew.
   -- The filter now reads "כל העובדים" correctly.

## Suggested Solution Approach

Every caption follows the current UI language immediately, and the filter's
label fits on mobile in both languages.

## Suggested Fix

`EmployeeFilterDropdown` (`lib/widgets/manager_dashboard/employee_filter_dropdown.dart`)
is a Material `DropdownMenu` with `width: 160` and the "All employees" option
as `initialSelection`. `DropdownMenu` writes the selected entry's label into
its text field once and does not refresh it when the entries' labels change on
a locale switch - likely cause, not yet confirmed in code. Options: give the
`DropdownMenu` a `ValueKey` that includes the locale so it rebuilds on a
switch, or own a `TextEditingController` and reset its text on locale change.
For the width, let it size to content or widen it on mobile, keeping the
overflow-safe pattern from CLAUDE.md (no `expandedInsets` with an explicit
width).

Side note: `lib/l10n/app_he.arb` defines `allEmployees` twice (lines 522 and
648); remove the duplicate while there.
