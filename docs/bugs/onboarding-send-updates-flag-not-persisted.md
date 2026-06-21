# Bug: Onboarding "send me updates" flag may not persist to the server

> **Status: new**

## Problem

During onboarding the user can tick a "send me updates" / marketing-consent
checkbox. It is not confirmed that this value is actually stored on the server —
it may be collected in the UI and silently dropped on submit.

## Reproduce Steps

1. Start a fresh onboarding flow.
2. Tick the "send me updates" checkbox.
3. Complete onboarding.
   -- Expected: the consent value is sent in the onboarding/company-create
      payload and persisted server-side; reloading or re-fetching the
      user/company shows the flag set.
   -- Actual: unverified — suspect the flag is never sent or never stored.

## Suggested Solution Approach

Make the marketing-consent choice durable so it can drive future email sends and
satisfy consent records.

## Suggested Fix

Needs investigation. Trace the onboarding checkbox through the form state,
the onboarding/company-create service call, and the API payload:
- Confirm the field is included in the request body sent via `ApiService`.
- Confirm the backend persists it and returns it on subsequent fetches.
- If the field is missing from the DTO/model, add it end to end.
This likely has a backend component — if the API has no field for it, file a
matching backend bug per the CLAUDE.md backend-bug process.
