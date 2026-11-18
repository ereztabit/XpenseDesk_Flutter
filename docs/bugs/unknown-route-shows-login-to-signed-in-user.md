# Bug: An unknown address shows the login screen to a signed-in user

> **Status: new**

Found in FS-1013 (PC-2) manual QA, 2026-11-18 (scenario Q16).

## Problem

A signed-in user who opens an address the app does not know - a mistyped
link, an old bookmark, `/budgets/not-a-guid` - lands on the login screen, as if
signed out. They are still signed in, but nothing on the screen says the page
does not exist or offers a way back to their dashboard.

## Reproduce Steps

1. Sign in (any role).
2. Type `https://<app>/some-unknown-route` (or `/budgets/not-a-guid`) in the
   address bar.
   -- Expected: a "page not found" message with a link to the user's
      dashboard, or a redirect to the dashboard.
   -- Actual: the login screen.

## Suggested Solution Approach

An unknown route for a signed-in user goes to (or links to) their own
dashboard; only a signed-out user sees login.

## Suggested Fix

Needs investigation: `lib/router.dart` - find the fallback for an unmatched
route (it appears to build the login screen unconditionally) and make it
session-aware (`/dashboard` for a manager, `/user/dashboard` for an employee).
Since FS-1013, `AppRoutes.parseBudgetPath` returns null for a non-GUID id, so
`/budgets/<garbage>` takes the same fallback.
