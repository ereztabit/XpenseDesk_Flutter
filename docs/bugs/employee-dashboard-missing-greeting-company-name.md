# Bug: Employee dashboard missing greeting + company name header

> **Status: new**

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
