# Bug: Login-link sign-in races the startup session restore

> **Status: done**

## Problem

When the app opens on `/login?token=<loginToken>` in a browser that still holds an
OLD session token, the old session and the new login link fight each other. The
user either sees an error right after signing in, or lands in the WRONG account.

This hits every login link: the emailed magic link, and the new tab the marketing
website (xpensedesk.com) opens after its signup popup. It is not specific to the
website. The website just makes it common: people sign up on a device where they
were already logged in to the app.

What happens at startup, in parallel:

- `authBootstrapProvider` -> `UserInfoNotifier.loadFromSession()` finds the OLD
  stored token and calls `GET /api/users/me` with it.
- `LoginCallbackScreen` redeems the NEW link (`POST /api/auth/login`), stores the
  new session token, then calls `GET /api/users/me` through `completePostLogin`.

Two outcomes:

1. **Old session invalid** (expired, company deleted, logged out elsewhere): its
   `/api/users/me` returns 401. The global handler `ApiService.onUnauthorized`
   (`lib/main.dart:51-56`) then calls `handleUnauthorized()` and
   `clearSessionToken()`, which can wipe the NEW token that was just stored, and
   navigates to `/`. The user sees an error right after a successful sign-in. A
   refresh works, because the link token stays redeemable for 5 minutes and the
   old token is gone by then.
2. **Old session still valid**: its `/api/users/me` returns the OLD account, and
   that races the new account's response. Whichever arrives last wins, so the app
   can show the previous account after signing in with a new link. See also
   docs/bugs/stale-data-after-switching-company.md (the same family: previous
   session data leaking into the new one).

Evidence, prod ApiLog 2026-09-26 (UTC):

- iPhone, website signup: 15:36:03 `POST /api/auth/login` 200, then in the same
  second `GET /api/users/me` 401 and `GET /api/users/me` 200. The user saw an error;
  a refresh at 15:36:16 signed in fine.
- Windows desktop, website signup: 15:24:08 `POST /api/auth/login` 200, plus two
  `GET /api/users/me` 200 in the same second returning two DIFFERENT accounts: an
  older test account (the browser's previous session) and the newly signed-up one.

## Reproduce Steps

1. In a browser, sign in to the app as account A (any sign-in method).
2. In the same browser, open a login link for account B:
   `https://app.xpensedesk.com/login?token=<B's login token>`. Use try-login with B's
   email, or sign up B from the xpensedesk.com popup.
   -- Expected: the app signs in as B and shows B's dashboard.
   -- Actual: A and B race. The app may show A's details or data after the B login.
3. 401 variant: repeat step 1, then invalidate A's session (e.g. delete A's company
   or its session), then open B's link.
   -- Expected: signed in as B.
   -- Actual: error after sign-in; the stored token is cleared and the app jumps to `/`.
      A refresh on the same link works.

## Suggested Solution Approach

A login link in the URL always wins. The app should never restore or act on the
previous session while it is redeeming a link, and a failure of the OLD session
must never end the NEW one.

## Suggested Fix

**Skip the startup session restore on a login-link load.** In
`authBootstrapProvider` (`lib/providers/auth_provider.dart`), when the startup URL
(`Uri.base`) is `/login` with a non-empty `token` param, do not call
`loadFromSession()`. The link's own flow (`LoginCallbackScreen` ->
`completePostLogin`) stores the new token and sets the user, so the old session is
never loaded and can neither 401 nor overwrite the new account. Leave the
Microsoft redirect step that runs before it unchanged.

The old token is NOT cleared. If the link fails (expired, already used), the
previous session stays signed in. Two small pieces make that true:

- `AuthService.login` (`lib/services/auth_service.dart`) sends the redemption with
  `suppressUnauthorized: true`, as `microsoftLogin` already does. A bad link is a
  401, and the global handler would otherwise clear the CURRENT session (on a
  support-connect link: the agent's own) and jump to `/` with no message. It now
  throws `AuthException(errorCode: 'LoginLinkInvalid')`, which
  `LoginCallbackScreen` shows as the existing `invalidLoginLink` string.
- "Back to login" on the failure card runs `loadFromSession()` before going to
  `/`, since the link load skipped it. A still-valid old session lands back in
  its dashboard; no session lands on the login form.

`/login?token=` is only ever reached as a fresh page load (emailed link, website
new tab, and the `@xpensedesk.com` shortcut, which opens it with
`launchUrl(..., externalApplication)`), so checking `Uri.base` at startup is enough.

### Investigation findings (2026-09-26)

- Confirmed: `MyApp.initState` starts `authBootstrapProvider` and
  `LoginCallbackScreen.initState` starts the link redemption, with nothing
  ordering them. MSAL initialises at page load, before Dart boots
  (`web/msal_interop.js`), so the Microsoft step does not delay the restore: its
  `GET /api/users/me` goes out with the OLD token before `POST /api/auth/login`
  returns. Matches the prod log.
- The global 401 handler is not the only thing that clears the token:
  `_loadFromSessionInternal`'s `catch` clears it on ANY failure (401, network
  error). Its success path sets `state` with no check, which is outcome 2: the
  header and role show account A while every API call sends B's token, and
  `AuthGate` re-evaluates against A's role.
- So guarding only `onUnauthorized` (an earlier idea for this doc) would not fix
  the bug. The fix above closes both outcomes on its own.

### Follow-ups (not in this fix)

- **Hardening:** ignore a response to a request sent with a token that is no
  longer the stored one, in `_loadFromSessionInternal` (success and catch) and in
  the `onUnauthorized` wiring (pass the request's token to the callback). Protects
  any in-flight request that races a session change.
- **Cross-tab:** `SharedPreferences` (legacy API) caches the token per tab, but
  its writes and removes go straight to localStorage, which all tabs share. An old
  tab still on account A that gets a 401 removes B's token for every tab; the new
  tab works until a refresh, then is signed out. A token-compare guard in the old
  tab compares against its own stale cache, so it does not catch this. Not filed.

## Resolution

Shipped in v1.33 (develop finish commit, 2026-09-26), exactly as the Suggested Fix
above:

- `lib/providers/auth_provider.dart`: `authBootstrapProvider` returns before
  `loadFromSession()` when `AppRoutes.isLoginLink(Uri.base)`.
- `lib/utils/app_navigator.dart`: new `AppRoutes.loginCallback` and
  `AppRoutes.isLoginLink` (tests: `test/utils/app_navigator_test.dart`);
  `lib/router.dart` uses the constant.
- `lib/services/auth_service.dart`: `login()` suppresses the global 401 handler and
  throws `AuthException(errorCode: 'LoginLinkInvalid')`.
- `lib/screens/login_callback_screen.dart`: shows `invalidLoginLink` for that
  code; "Back to login" restores the old session first.

Side effect: a support-connect tab (FS-1001, same `/login?token=` route) no longer
restores the agent's own session in parallel.

CR and security review: login-link-races-startup-session-restore-CR.md (clean).

Verified by the owner on local dev (release build), 2026-09-26: wrong account
(A then B's link), stale old token (no error), bad link keeps the session, and
support connect.
