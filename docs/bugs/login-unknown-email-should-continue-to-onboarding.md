# Bug: Login with an unregistered email dead-ends instead of continuing to onboarding

> **Status: new**

## Problem

A visitor who is not a customer yet types their email on the login screen and
presses "Continue". They are told to go check their inbox for a magic link that
will never arrive, because no account exists for that email. There is no hint
that they need to sign up, and no way forward from that screen except noticing
the small "Create account" link.

That is the single most likely first interaction a new prospect has with the
product, and it ends in a wait for an email that never comes.

Expected: when login fails because the user does not exist, take them straight
into the onboarding wizard with the email they already typed pre-filled, so they
continue signing up instead of starting over.

This is what the Microsoft sign-in path already does: an unknown Microsoft user
is handed off to the wizard and continues in Microsoft mode
(docs/completed/microsoft-onboarding-flutter-guide-CR.md). The email /
magic-link path has no equivalent.

## Reproduce Steps

1. Open the app logged out, at the login screen.
2. Type an email address that has no XpenseDesk account (e.g.
   `nobody+test@example.com`) and press Continue.
   -- Expected: land on the onboarding wizard, step 1, with the email field
      already filled with `nobody+test@example.com`.
   -- Actual: a green "check your email for the magic link" message. No email is
      ever sent, no error, no route to signup.
3. Same flow with a registered email -- the magic link arrives as normal
   (unchanged by this bug).

## Blocker -- backend cannot currently tell us

`POST /api/auth/try-login` returns `200 OK` with
`"If the email exists, a magic link has been sent."` for **every** email, whether
or not the account exists. This is deliberate: it prevents email enumeration.
See docs/api-guides/authentication_client_guide.md ("Always returns success --
This prevents email enumeration attacks").

So the client literally cannot distinguish "sent" from "no such user" today, and
no frontend-only fix exists. Two consequences to decide on before implementing:

1. **A backend change is required** -- the endpoint must expose, in some form,
   that the email is unknown (for example a distinct `errorCode`
   `AuthUserNotFound`, or a `userExists: false` flag in `data`).
2. **It reopens email enumeration on purpose.** Any visitor could probe
   addresses and learn which ones are registered, since the response now differs.
   That is the trade-off being accepted for the signup funnel. Worth confirming
   with the backend before building; a rate limit on `try-login` per IP is the
   usual mitigation and should probably ship with it.

If we are not willing to accept enumeration, the fallback is a UX-only fix:
change the success message to say "if you do not have an account yet, sign up"
with a prominent link that carries the typed email into the wizard. That keeps
the 200-always contract and still gives the prospect a way forward.

## Suggested Solution Approach

Login with an email that has no account is not an error state -- it is the start
of a signup. Route the person into onboarding, carrying the email they typed, so
they never retype it.

## Suggested Fix

Backend first (see blocker above), then on the client:

- `lib/services/auth_service.dart` -- `tryToLogin()` currently returns the raw
  response map and never inspects it. Surface the new unknown-email signal as a
  typed outcome rather than making the widget read magic strings out of the map.
- `lib/widgets/login/login_card.dart:52` (`_handleLogin`) -- on the unknown-email
  outcome, stash the typed email and
  `Navigator.pushReplacementNamed('/onboarding')` instead of setting
  `_successMessage`. Mirror the existing Microsoft handoff in the same file
  (`login_card.dart:40`), which reads a pending provider and redirects.
- `lib/providers/auth_provider.dart` -- add a `pendingOnboardingEmailProvider`
  alongside `pendingMicrosoftOnboardingProvider:135`, same shape (`String?` with
  `set` / `clear`).
- `lib/screens/onboarding/onboarding_screen.dart` -- consume and clear that
  provider in `initState` / the post-frame callback, seeding
  `onboardingProvider`'s `email` field. Unlike Microsoft mode the email must
  stay **editable** here (the person may have simply typo'd it), so do not lock
  the field the way the Microsoft identity card does.
- Step 2 already handles the reverse case -- an email that turns out to be
  registered returns HTTP 409 and is shown on the email field via
  `setEmailConflictError` (`lib/providers/onboarding_provider.dart:249`). No
  change needed there; it is the safety net if the handoff is ever wrong.
- Dead string to reuse or delete: `emailNotRegistered` exists in both
  `lib/l10n/app_en.arb:19` and `lib/l10n/app_he.arb:19` but is referenced
  nowhere in `lib/`. Either use it for a brief interstitial ("this email is not
  registered -- let's get you set up") or remove it.
