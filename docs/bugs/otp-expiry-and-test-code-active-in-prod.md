# Bug: OTP expiry unverified, and test code 1-6 still works in production

> **Status: new**

## Problem

Two related authentication-security concerns with the one-time password (OTP):

1. It is not verified that an OTP actually expires after one hour. Need to
   confirm expired codes are rejected.
2. The test/bypass code `1-6` (123456) still works in production. A hardcoded
   universal OTP must never be accepted in prod.

## Reproduce Steps

1. Request an OTP, wait past the intended expiry window (1 hour), then submit the
   real code.
   -- Expected: rejected as expired.
   -- Actual: unverified.
2. On production, enter `123456` as the OTP.
   -- Expected: rejected.
   -- Actual: accepted (test bypass active in prod).

## Suggested Solution Approach

OTP must expire as specified, and any test/bypass code must be disabled in
production builds/environments.

## Suggested Fix

This is primarily a backend concern (OTP generation, validation, expiry, and the
bypass code). File a matching backend bug per the CLAUDE.md backend-bug process
in `C:\Projects\XpenseDesk\BackEnd\XpenseDeskServer\docs\bugs\`. On the client,
confirm there is no dev-only OTP bypass leaking into the prod build.
