# Microsoft Onboarding (SSO, no OTP) - Flutter Client Guide

Add an "or - Subscribe with Microsoft" option to step 1 of the onboarding wizard.
The user signs in with Microsoft, comes back with a validated identity, and completes
onboarding WITHOUT the OTP verification step - one API call creates the company and
returns a session token.

Companion backend doc: microsoft-onboarding-story.md
Both tracks share the same API contract (see "API contract") and can be built in
parallel. This guide builds on microsoft-login-flutter-guide.md - the MSAL setup,
app registration, and callback route from the login feature are all REUSED; nothing
new is needed on Azure.

---

## What the client does (flow)

The wizard today: 1 You -> 2 Company -> 3 Verification -> 4 Plans -> 5 Payment.
The Microsoft path enters at step 1 and SKIPS step 3 (Verification) entirely.

1. Step 1 of the onboarding wizard shows, below the existing name/email form,
   an "or" divider and a "Subscribe with Microsoft" button
   (Hebrew: "הרשמה עם Microsoft").
2. On tap: start the MSAL interactive sign-in (same MSAL client as login) and pass
   `state: "onboarding"`. The state parameter is how the shared callback knows this
   sign-in started from onboarding and not from the login screen.
3. Microsoft redirects back to the existing `/auth/microsoft-callback` route. The MSAL
   redirect handler there returns the ID token AND echoes back the state.
4. The callback handler branches on state:
   - `state == "login"` (or absent): existing login behavior, unchanged.
   - `state == "onboarding"`: continue below.
5. FIRST, call the existing `POST /api/auth/microsoft-login` with the token:
   - 200 -> this person already has an account. Store `data.sessionToken` and enter
     the app. Do NOT continue onboarding. (This check runs at the callback, right
     after sign-in - never let an existing user fill four wizard steps and then fail.)
   - 401 -> new user. Continue the wizard in "Microsoft mode".
6. Microsoft mode, step 1: replace the editable name/email form with:
   - An **identity card**: avatar (initial), full name + email from the token
     claims (`name`, `preferred_username`), a "Signed in with Microsoft" badge
     with a verified checkmark, and a trailing **"Use a different account"** link.
     The email lives ONLY in this card and is read-only - the server takes email
     from the token it validates, never from the form.
   - Below the card, an **editable Full Name field**, prefilled from the `name`
     claim. Token display names are often formatted oddly ("Morgan, Alex"), so
     the user may correct it. This value IS sent to the server (see contract).
   - The user still ticks terms + marketing consent - SSO proves identity, not
     consent. Continue stays disabled until terms are accepted, as today.
   - "Use a different account" RESTARTS the flow: drop the acquired tokens
     (clear the MSAL cached account), exit Microsoft mode, and return to the
     plain step 1 form (empty, fully editable). From there the user starts over -
     fill the form manually or tap the Microsoft button again.
7. Steps 2 continues as normal (company details). Step 3 (Verification/OTP) is
   skipped in Microsoft mode.
8. Where the OTP path would call `/onboarding/company` and then `/verify-otp`, the
   Microsoft path makes ONE call: `POST /api/onboarding/sso` (contract below) with
   the ID token + all collected company fields.
9. On 200: store `data.sessionToken` exactly where it is stored after verify-otp
   today, then proceed to Plans/Payment exactly as the OTP path does. Everything
   downstream is unchanged.

---

## Prerequisites - all already in place from the login feature

- MSAL client config (clientId eb4d44fd-888c-4c12-9de2-ea25cf46a55f, authority
  https://login.microsoftonline.com/organizations, PKCE, no secret).
- redirectUri derived from the runtime origin:
  `Uri.base.origin + "/auth/microsoft-callback"` - works on localhost:8080 (dev) and
  app.xpensedesk.com (prod); both are registered in Entra.
- The `/auth/microsoft-callback` route and its MSAL redirect handler.

Nothing new to register on Azure for this feature. Do NOT add a second callback
route (e.g. /auth/microsoft-callback-onboarding) - the state parameter carries the
login-vs-onboarding bit through the one shared callback.

---

## Implementation steps

1. **State on sign-in.** Pass `state: "onboarding"` when starting the interactive
   sign-in from the wizard; the login-screen button keeps its current behavior
   (no state, or `state: "login"`). MSAL echoes state back in the redirect result -
   read it in the callback handler and branch. State is client-side routing data
   only; it is NEVER sent to the backend.

2. **Existing-account check at the callback.** In the onboarding branch, call
   `POST /api/auth/microsoft-login` immediately (step 5 above) and route on the
   result before showing any further wizard UI.

3. **Identity card + editable name.** In Microsoft mode, render the identity
   card (avatar, name, email, "Signed in with Microsoft" verified badge,
   "Use a different account" link) in place of the email field, and an editable
   Full Name field prefilled from the `name` claim below it. Keep terms +
   marketing consent active. Heading and subtitle are unchanged from the
   regular step 1.

4. **Skip Verification.** In Microsoft mode the wizard goes step 2 -> step 4
   directly, and the Verify step is REMOVED from the step indicator - it shows
   three steps: You -> Company -> Plan.

5. **Single submit call.** Collect the same fields the OTP path collects (minus
   email, which comes from the token) plus the editable full name, and POST them
   with the token to `/api/onboarding/sso`. On 200, reuse the exact
   post-verify-otp session handling.

6. **Token freshness before submit.** Microsoft ID tokens live about 1 hour. The
   user may park on a wizard step. Immediately before the `/onboarding/sso` call,
   silently re-acquire the token (MSAL `acquireTokenSilent`) and send the fresh one.
   If silent acquisition fails, run the interactive sign-in again with
   `state: "onboarding"`.

7. **Errors and edge cases.**
   - User cancels the Microsoft sign-in: stay on wizard step 1, form still usable.
   - 401 from `/onboarding/sso` (expired/invalid token): re-acquire (step 6), retry
     once; if it persists, friendly error + offer the email/OTP path.
   - 409 from `/onboarding/sso` (email already registered - can happen in a race):
     route to login with a "you already have an account" message.
   - 400: show the validation message; these are form-level issues.
   - Redirect-mismatch / config errors: developer-facing log, same as login.

---

## API contract (shared with the backend track)

Request:

    POST /api/onboarding/sso
    Content-Type: application/json

    {
      "provider": "Microsoft",
      "idToken": "<Microsoft ID token JWT>",
      "fullName": "Alex Morgan",
      "companyName": "Acme Corp",
      "countryCode": "IL",
      "currencyCode": "ILS",
      "cutoverDay": 1,
      "languageId": null,
      "timeZoneId": null,
      "accountantEmail": null,
      "isMarketingConsent": true
    }

Field notes:
- `provider`: fixed string "Microsoft" for now ("Google" will be added later - same
  endpoint, same fields).
- `idToken`: the raw Microsoft ID token JWT from MSAL.
- `fullName`: the user-editable name from the form (prefilled from the token's
  `name` claim, user may have corrected it). The server uses this value; if
  empty/whitespace, the server falls back to the token's `name` claim.
- Company fields: identical meaning to the existing `/onboarding/company` fields.
- There is NO `email` - the server takes it from the validated token. Sending it
  does nothing.

Success (200) - identical shape to `/onboarding/verify-otp`:

    {
      "success": true,
      "message": "Company created successfully",
      "data": { "sessionToken": "..." }
    }

Store `data.sessionToken` exactly as after verify-otp, then `GET /api/users/me` and
continue to Plans/Payment.

Errors:

| HTTP | Meaning                              | Client action                        |
|------|--------------------------------------|--------------------------------------|
| 400  | Validation failed (form fields)      | Show message on the form.            |
| 401  | Invalid/expired/untrusted ID token   | Silent re-acquire, retry once.       |
| 409  | Email already registered             | Route to login.                      |
| 500  | Server error                         | Generic error, allow retry.          |

---

## Notes

- The email/OTP onboarding path stays fully intact as the universal fallback -
  the Microsoft button is additive.
- CONTRACT CHANGE vs. the original story: `fullName` was added to the
  `/onboarding/sso` request (editable in the UI). The backend track
  (microsoft-onboarding-story.md) must accept it, with token-`name` fallback.
- The whole point: corporate (M365) users never wait on a Defender-delayed OTP
  email, and never type a code - identity is proven by the Microsoft sign-in.
- First sign-in from a locked-down customer org may show a one-time consent prompt;
  expected with the multitenant registration, no client change needed.

## Security note for the backend - account matching (nOAuth)

With a multitenant registration, the `email`/`preferred_username` claims in the
token are controllable by the customer tenant's own admin, so they are NOT proof
of identity: a hostile tenant admin can set a user's email claim to a victim's
address and, if the server matches on it, take over that account (the nOAuth
abuse pattern).

Match accounts by the validated `oid` + `tid` pair (immutable object id +
tenant id) and never by the unverified email claim. The claim is fine for
display or for pre-filling a form; it is not an identifier.

Shipped: v1.22 (2026-07-22).
