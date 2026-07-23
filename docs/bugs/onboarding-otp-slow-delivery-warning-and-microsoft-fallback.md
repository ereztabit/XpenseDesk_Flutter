# Bug: Onboarding OTP step - no guidance when the code is slow to arrive

> **Status: reviewed by me**

## Problem

On the email-registration onboarding flow, the pincode (OTP) email sometimes
takes a while to arrive - notably the first email to a mailbox, and most
often on Microsoft 365 mailboxes, where first delivery can take up to ~3
minutes. During that window the OTP step gives the user no feedback: they
stare at six empty boxes and a countdown with no idea whether something went
wrong. This is exactly the moment a new prospect abandons signup.

Two asks (scoped by user review):

1. After 30 seconds on the step with no code entered, show a reassuring
   warning: the first email can take time to arrive - up to ~3 minutes,
   especially on Microsoft 365 mailboxes.
2. Show a "Sign up with Microsoft" (SSO) option on this step ALWAYS - visible
   from the moment the step renders, not gated behind the 30-second timer -
   so the user can skip the pincode wait at any point.

Dropped from scope: "send the code again" - a resend button already exists
on this step (30s cooldown, re-calls the same submit endpoint); no change
needed there.

## Reproduce Steps

1. Start onboarding at /onboarding and register with an email address
   (pick a Microsoft 365 mailbox receiving its first XpenseDesk email).
2. Reach the pincode verification step and wait.
   -- Expected: a "Sign up with Microsoft" option is visible on the step from
      the start; after ~30 seconds a notice appears explaining first-time
      delivery can take up to ~3 minutes (especially on 365 mailboxes).
   -- Actual: no Microsoft option and no guidance; the user waits blind
      against a 10-minute countdown.

## Current State (code)

`lib/screens/onboarding/steps/otp_verification_step.dart`:

- A resend action already exists: a "resend" TextButton with a 30-second
  cooldown that re-calls `submitCompany` with the wizard state and swaps in
  the new otpKey. Out of scope here - keep as is.
- There is NO delayed-delivery warning and NO Microsoft SSO option on this
  step.

## Suggested Solution Approach

The Microsoft escape hatch is permanent: "Sign up with Microsoft" sits on the
OTP step from the start, so nobody has to wait out a slow mailbox. The
30-second timer only adds reassurance - a note that first-time delivery
(especially Microsoft 365) can take up to ~3 minutes, so the wait reads as
normal rather than broken.

## Suggested Fix

- Render a "Sign up with Microsoft" affordance on the OTP step permanently
  (from first paint), routing into the existing Microsoft onboarding flow
  (the no-OTP "Subscribe with Microsoft" path, shipped v1.22 on develop) -
  reusing the same button/flow used on the earlier onboarding step. Mind the
  feature flag gating (enableMicrosoftLogin) and what happens to the wizard
  state already collected (email/company details) when switching paths
  mid-flow.
- Add a 30-second one-shot timer to `_OtpVerificationStepState` (it already
  manages countdown + resend cooldown timers). When it fires with the step
  still unverified, render an info banner (muted/info styling, not an error)
  with the delivery-delay explanation (up to ~3 minutes, most likely on
  Microsoft 365 mailboxes).
- New strings go through the ARB flow (app_en.arb + app_he.arb) per repo
  rules.
