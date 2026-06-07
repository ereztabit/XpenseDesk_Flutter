# Bug: Employee dashboard missing greeting + company name header

> **Status: done**

## Resolution

Relocated the existing `DashboardGreeting` widget from
`lib/widgets/manager_dashboard/` to the shared `lib/widgets/` root (it already
reads name + company from `userInfoProvider`, so it was never manager-specific)
and rendered it on the employee dashboard, matching the manager dashboard.

Files:
- `lib/widgets/dashboard_greeting.dart` (moved from manager_dashboard/).
- `lib/screens/manager_dashboard_screen.dart` — updated import.
- `lib/screens/user_dashboard_screen.dart` — renders `DashboardGreeting`.

## Problem

The employee dashboard should have the same greeting and company-name header as
the manager dashboard, but it does not.

## Reproduce Steps

1. Log in as a manager and view the dashboard header (greeting + company name).
2. Log in as an employee and view the dashboard.
   -- Expected: the same greeting + company-name header.
   -- Actual: the employee dashboard is missing it.

## Suggested Solution Approach

Presentation-only change; both screens already receive user/company context.

## Suggested Fix

- Extract the manager dashboard's greeting/company-name header into a shared
  widget (e.g. `DashboardHeader(userName, companyName)`) and render it on the
  employee dashboard too.
