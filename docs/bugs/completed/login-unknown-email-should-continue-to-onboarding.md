# Bug: Login with an unregistered email dead-ends instead of continuing to onboarding

> **Status: done** — frontend half of full-stack mission **FS-1002**, banked on
> `develop` as v1.30 (2026-08-16). Backend half:
> `BackEnd/XpenseDeskServer/docs/bugs/try-login-cannot-signal-unknown-or-deactivated-user.md`

## Resolution

`POST /api/auth/try-login` no longer answers every address with the same neutral
200. An unregistered address returns `404 AuthUserNotFound`, and the login card
hands the visitor to the onboarding wizard carrying the email they typed —
pre-filled and still editable, since a typo is the other reason an address comes
back unknown. `tryToLogin()` returns a typed `TryLoginOutcome` so no widget reads
error strings.

Two neighbouring cases were separated out rather than folded in: a deactivated
**user** returns `403 AuthUserInactive` and a deactivated **company** returns
`403 CompanyInactive`, both shown as plain errors on the login screen and never
routed into signup. The company case was found during QA — try-login had never
looked at `Companies`, so those people received a working link into an account
where every following call 403s.

Also fixed here, both found by review rather than reported: a `NetworkException`
escaped `_handleLogin` and left the Continue button silently dead (offline, or a
rate-limited 429 with an empty body), and the sign-up `Row` overflowed by 16px at
narrow widths — now a `Wrap`.

Verified end to end against dev: 18 manual checks plus a 4-check regression round
(`fs-1002-manual-qa.md`, archived alongside this doc).

**Not in production yet.** Shipping is blocked on the `proc_CreateMagicLink`
migration being applied to `XpenseDesk-PRD` —
`BackEnd/XpenseDeskServer/docs/bugs/fs-1002-proc-createmagiclink-status.sql`.
Without it, prod's proc returns no `Status` column, the server falls back to
`NotFound`, and **every** login is told no account exists.

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

## Former blocker -- resolved, backend is doing its half

`POST /api/auth/try-login` used to return `200 OK` with
`"If the email exists, a magic link has been sent."` for **every** email, so the
client could not tell "sent" from "no such user" and no frontend-only fix
existed. The backend half of FS-1002 changes that. New contract:

| Case | HTTP | `errorCode` | Client does |
|---|---|---|---|
| Active user, link sent | 200 | -- | unchanged: "check your email" |
| No such email | 404 | `AuthUserNotFound` | hand off to onboarding with the typed email |
| User exists but deactivated | 403 | `AuthUserInactive` | plain error: account disabled, contact your admin |

Two decisions that were open here are now settled:

1. **Deactivated is its own case, not an unknown one.** This flow is for people
   who do not exist yet. A disabled account must not be walked into the signup
   wizard -- it gets an explicit error instead. (The backend needs a
   `proc_CreateMagicLink` change to tell the two apart at all; without it they
   are the same zero-row result.)
2. **Email enumeration: accepted, and it is not actually new.**
   `GET /api/onboarding/check-email` is already unauthenticated and already
   returns `data.exists` for any address. try-login becoming explicit exposes
   nothing an attacker cannot get more cheaply there. So `try-login` keeps its
   existing rate limit and no extra mitigation ships with this; the per-IP
   lockout story stays separate on the backend backlog.

`docs/api-guides/authentication_client_guide.md` still documents the old
"always returns success" contract and must be updated when this lands.

## Suggested Solution Approach

Login with an email that has no account is not an error state -- it is the start
of a signup. Route the person into onboarding, carrying the email they typed, so
they never retype it.

## What was built

- `lib/services/auth_service.dart` -- `tryToLogin()` returns a typed
  `TryLoginOutcome` (`linkSent` / `userNotFound` / `userInactive`) instead of the
  raw response map, so no widget reads error strings. An unrecognised
  `errorCode` still throws `AuthException`: better a visible error than silently
  walking someone into signup on a response we do not understand. No 401 is
  involved on this route, so the global unauthorized handler never fires and
  needs no suppression.
- `lib/widgets/login/login_card.dart` (`_handleLogin`) -- switches on the
  outcome. `userNotFound` calls `_startOnboardingWith()`, which resets the wizard
  (clearing anything left from an earlier session in this tab, exactly as the
  "Create account" button does), **then** seeds the email, then navigates.
- **The seed happens on the login screen, not through a pending provider.** The
  first cut mirrored `pendingMicrosoftOnboardingProvider`, but that shape only
  exists because the Microsoft token is produced by app bootstrap rather than by
  a widget. Here the login card can write `onboardingStateProvider` directly from
  its button handler -- outside any build -- which removed a provider, a consume
  method, and a real timing hazard: `PersonalDetailsStep` prefills its controller
  in its own `initState`, so a post-frame seed in `OnboardingScreen` would have
  landed a frame too late and the field would have rendered empty.
- **`pushNamed`, not `pushReplacementNamed`.** A well-formed typo
  (`erez@tabti.cloud`) passes validation and correctly comes back unknown, so the
  login screen must stay on the stack for the person -- or the browser Back
  button -- to return to.
- Deactivated account (`AuthUserInactive`) -- shown in the existing `ErrorAlert`
  via `_errorMessage`, using the new `loginAccountDeactivated` ARB key. Never
  routed to onboarding.
- The email stays **editable** in the wizard (a typo is the other reason an
  address comes back unknown), so it is not locked the way the Microsoft
  identity card locks it.
- Step 2 already handles the reverse case -- an email that turns out to be
  registered returns HTTP 409 and is shown on the email field via
  `setEmailConflictError` (`lib/providers/onboarding_provider.dart`). Unchanged;
  it is the safety net if the handoff is ever wrong.
- `emailNotRegistered` (dead in both ARB files, referenced nowhere) was deleted
  rather than repurposed -- the flow goes straight into the wizard with no
  interstitial to put it on.
