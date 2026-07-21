# Microsoft Login - Flutter Client Guide

Add a "Sign in with Microsoft" button to the LOGIN screen. The app performs an
interactive Microsoft sign-in, gets an ID token, and posts it to the backend, which
returns our normal session token. Login only - existing users; unknown users are
rejected by the server with a 401.

Companion backend doc: microsoft-login-story.md
Both tracks share the same API contract (see "API contract") and can be built in
parallel.

---

## What the client does (flow)

1. User taps "Sign in with Microsoft" on the login screen.
2. MSAL runs the interactive sign-in against Entra (popup or full-page redirect;
   on redirect the browser returns to /auth/microsoft-callback).
3. The app receives an ID token from Microsoft.
4. The app POSTs { idToken } to /api/auth/microsoft-login.
5. Backend validates the token, finds the user by verified email, returns a session
   token in the SAME shape as the magic-link login response.
6. The app stores data.sessionToken exactly where the magic-link session token is
   stored today and proceeds into the app. No other authenticated-call changes.
7. If the server returns 401 (no account / invalid token), show a friendly message
   ("No XpenseDesk account for this Microsoft user").

---

## Prerequisites (from the Azure app registration)

Already configured on the backend/Azure side:
- Application (client) ID: eb4d44fd-888c-4c12-9de2-ea25cf46a55f
- Directory (tenant) ID:   440b8720-6802-450c-a1dc-c8686f6012f5
- Authority (multitenant work/school): https://login.microsoftonline.com/organizations
- Delegated permissions openid, profile, email, User.Read - admin consent granted.

Platform: WEB ONLY. No iOS / Android at this time. The app registration uses the
SPA (single-page application) reply-URL type, which gives auth-code + PKCE with no
client secret - correct for Flutter web.

Redirect URIs (DONE - already registered on the app registration as SPA reply URLs):
- Dev:  https://localhost:8080/auth/microsoft-callback
- Prod: https://app.xpensedesk.com/auth/microsoft-callback

Redirect page: the app owns a route at /auth/microsoft-callback and runs the MSAL
redirect handler there. If the front-end origin ever changes (new dev port, new prod
domain), register the new origin + /auth/microsoft-callback on the app registration -
otherwise sign-in fails with a redirect-mismatch error.

---

## Implementation steps

1. Add an MSAL-for-web package
   - Web only: use MSAL.js (via a Flutter web interop wrapper) or a maintained
     Entra OIDC-for-web package that does auth-code + PKCE against a SPA reply URL.
     No mobile plugins needed.

2. Configure the client
   - clientId: eb4d44fd-888c-4c12-9de2-ea25cf46a55f
   - authority: https://login.microsoftonline.com/organizations
   - redirectUri: derive from the runtime origin, do NOT hard-code -
       redirectUri = Uri.base.origin + "/auth/microsoft-callback"
     This makes the same build work on localhost:8080 (dev) and app.xpensedesk.com
     (prod); both origins are already registered in Entra, so Entra accepts whichever
     origin the app is running on.
   - scopes: ["openid", "profile", "email"] (User.Read is fine to include)
   - PKCE; NO client secret in the app.

3. Add the button
   - "Sign in with Microsoft" (Hebrew: "המשך עם Microsoft") on the login screen,
     alongside the existing magic-link entry.

4. Wire the flow
   - On tap: run interactive sign-in, obtain the ID token.
   - POST it to the backend (see contract). On 200, store data.sessionToken via the
     existing session storage. On 401, show the "no account" message.

5. Errors and edge cases
   - User cancels sign-in: no-op, return to the login screen.
   - Redirect-mismatch / config error: developer-facing log; verify the redirect URI
     is registered.
   - 401 from backend: friendly "no account for this Microsoft user" message.

---

## API contract (shared with the backend track)

Request:

    POST /api/auth/microsoft-login
    Content-Type: application/json

    { "idToken": "<Microsoft ID token JWT>" }

Success (200) - identical shape to POST /api/auth/login:

    {
      "success": true,
      "message": "Login successful.",
      "data": { "sessionToken": "<session token>" }
    }

Unknown user, or invalid/expired token (401):

    {
      "success": false,
      "message": "..."
    }

Store data.sessionToken exactly where the magic-link session token is stored today.
Everything downstream already speaks "session token" - nothing else changes.

---

## Notes

- The whole point of Microsoft login is to remove the emailed-code round trip for
  corporate (M365) mailboxes, whose Defender scanning delays the first email. Those
  users are in their own Entra tenants - the multitenant registration is what lets
  them sign in without any per-customer setup.
- Magic-link email login stays as the universal fallback for non-Microsoft users.
- The first sign-in from a locked-down customer org may show a one-time consent
  prompt; that is expected with multitenant and needs no client change.
