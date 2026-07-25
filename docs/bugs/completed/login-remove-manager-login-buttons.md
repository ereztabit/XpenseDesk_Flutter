# Bug: Remove the manager login buttons from the login screen

> **Status: done**

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
shortcut on the login screen" (docs/completed/disable-dev-auto-login.md) — if
they are the same dev shortcuts, coordinate the two so the change is made once.
Ensure no dev login affordance reaches production.

## Resolution

Removed the two "DEV: Login as Admin" / "DEV: Login as User" `OutlinedButton`s
and the `_handleDevLogin` handler from `lib/screens/login_screen.dart`, and the
now-dead `tryToLoginDev` from `lib/services/auth_service.dart` (it was a
duplicate of `tryToLogin` hitting the same `/api/auth/try-login` endpoint).

No environment gate was needed: the normal `_handleLogin` flow already launches
the `magicLink` when the server returns one, so on dev (where the server returns
a magic link for valid emails) login continues to work by simply entering the
email and pressing Continue. On prod the server returns no magic link, so the
user is told to check their email.

This also closes the prod exposure noted in docs/pre-deployment-issues.md (the
dev buttons rendered unconditionally in PROD). Verified by the user. CR clean,
security review found no new findings, `flutter analyze` clean, `flutter build
web` succeeded.

Files: lib/screens/login_screen.dart, lib/services/auth_service.dart.
