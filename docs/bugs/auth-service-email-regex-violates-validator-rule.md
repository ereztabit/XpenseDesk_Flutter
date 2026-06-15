# Bug: AuthService.isValidEmail uses hand-rolled regex instead of email_validator

> **Status: new**

## Problem

`AuthService.isValidEmail` validates email format with a hand-rolled regular
expression. This violates the repo's mandatory rule (CLAUDE.md -> "Email
Validation"): all email validation must use the `email_validator` package, never
a regex. The regex (`^[^\s@]+@[^\s@]+\.[^\s@]+$`) is also weaker than the package
and will accept/reject addresses inconsistently with the rest of the app (e.g.
`EmailInputField`, onboarding), so a user can hit different validation verdicts on
different screens.

Secondary: the method is a private-by-intent helper (only used inside
`auth_service.dart`) but is declared public.

Found during the 2026-06-15 dead-code audit.

## Reproduce Steps

1. Open `lib/services/auth_service.dart`.
2. See `isValidEmail` (around line 49) using `RegExp(...)`.
   -- Expected: validation delegates to `EmailValidator.validate()`.
   -- Actual: a custom regex is used, and the method is public.

## Suggested Solution Approach

Make login email validation consistent with the rest of the app by routing it
through the same `email_validator` package used everywhere else.

## Suggested Fix

In `lib/services/auth_service.dart`:
- Add `import 'package:email_validator/email_validator.dart';`
- Replace the body with `EmailValidator.validate(email)`.
- Rename `isValidEmail` -> `_isValidEmail` (it's only called internally, at the
  `tryToLogin` path ~line 61 and the DEV-only `tryToLoginDev` path ~line 76).

No call sites outside the file, so the rename is contained.
