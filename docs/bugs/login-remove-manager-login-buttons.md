# Bug: Remove the manager login buttons from the login screen

> **Status: new**

## Problem

The login screen has manager login buttons (dev/quick-login shortcuts). These
should be removed — they don't belong on the production login screen.

## Reproduce Steps

1. Open the login screen.
   -- Expected: no manager login shortcut buttons.
   -- Actual: manager login buttons are present.

## Suggested Solution Approach

Remove the manager login buttons entirely from the login screen.

## Suggested Fix

Locate the manager login buttons in the login screen widget and remove them.
Note this overlaps with the existing backlog item "disable the dev auto-login
shortcut on the login screen" (docs/in-progress/disable-dev-auto-login.md) — if
they are the same dev shortcuts, coordinate the two so the change is made once.
Ensure no dev login affordance reaches production.
