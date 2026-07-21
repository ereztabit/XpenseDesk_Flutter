# Microsoft Login — Implementation & Lessons

How "Sign in with Microsoft" actually works in the Flutter web client, why it is
built the way it is, the problems we hit getting there, and the feature flags that
gate it. Companion to the original spec ([microsoft-login-flutter-guide.md](microsoft-login-flutter-guide.md)).

**Scope:** web only. Login only — existing XpenseDesk users. Unknown Microsoft
users are rejected by the backend (401) and shown a message. Magic-link email
login is untouched and remains the universal path.

---

## TL;DR

- We use **MSAL.js (`@azure/msal-browser` v5), bundled locally**, via a thin JS
  interop layer (`web/msal_interop.js`) exposed to Dart as `window.xdMsal`.
- We use the **redirect flow, not popup.** Popup is fundamentally broken here
  because Microsoft's login pages send `Cross-Origin-Opener-Policy`, which severs
  the browser's app↔popup link. See [Why redirect, not popup](#why-redirect-not-popup).
- The redirect **returns to `/auth/microsoft-callback`**, MSAL processes it and
  (by default) hands the finalized result back on the **login-request URL `/`**.
  We therefore consume the token in **app bootstrap** (`authBootstrapProvider`),
  not on the callback route.
- Everything is gated by two feature flags in `AppConfig`:
  `enableMicrosoftLogin` and `enableMicrosoftLoginLogs`.

---

## The flow (end to end)

1. **Login screen** (`lib/widgets/login/login_card.dart`) renders the
   "Sign in with Microsoft" button **only if** `AppConfig.instance.enableMicrosoftLogin`.
2. Tap → `MicrosoftAuthService.startSignInRedirect()` → `window.xdMsal.signInRedirect()`
   → MSAL `loginRedirect(...)`. **The whole tab navigates to Microsoft.** Nothing
   after this call runs (the page unloads).
3. User authenticates at Microsoft (their own Entra tenant — multitenant app
   registration, so no per-customer setup).
4. Microsoft redirects the tab back to
   `https://<origin>/auth/microsoft-callback#code=…&state=…`.
5. On that load, `msal_interop.js` (a `<head>` script) runs
   `handleRedirectPromise()`. With MSAL's default `navigateToLoginRequestUrl: true`,
   MSAL stores the response and **navigates the tab to the login-request URL `/`**
   (the page where `loginRedirect` was called).
6. On the **`/` load**, `handleRedirectPromise()` completes the **PKCE code→token
   exchange** (`POST https://login.microsoftonline.com/.../oauth2/v2.0/token`) and
   resolves with an `AuthenticationResult` containing the **Microsoft ID token**.
   The single-tab flow means the PKCE request cache (in `sessionStorage`) is present.
7. **`authBootstrapProvider`** (runs at app startup, i.e. on `/`) calls
   `getRedirectResult()`. If a token is present it calls
   `AuthService.microsoftLogin(idToken)` → **`POST /api/auth/microsoft-login`** →
   backend validates the token, finds the user by verified email, and returns our
   **session token** (same envelope as magic-link login). It is stored exactly
   where the magic-link session token is stored.
8. Bootstrap then runs normal session restore (`loadFromSession`), which finds the
   freshly stored token and populates `userInfoProvider`. **`AuthGate` on `/`**
   sees an authenticated user and redirects to the role's dashboard.
9. **Rejection:** if the backend returns 401 ("No XpenseDesk account for this
   Microsoft user"), bootstrap records it in `microsoftLoginErrorProvider`, and the
   login screen shows the localized "no account" message.

`/auth/microsoft-callback` itself renders only a **transient spinner**
(`MicrosoftCallbackScreen`) — MSAL moves the tab to `/` before it matters.

---

## Architecture / files

| File | Role |
|------|------|
| `web/msal-browser.min.js` | The official `@azure/msal-browser` v5 bundle (loaded, not built). |
| `web/msal_interop.js` | Glue. Inits MSAL once; runs `handleRedirectPromise()` on every load; exposes `window.xdMsal` = `{ signInRedirect, getRedirectResult, setLogsLive, dumpLog }`. Buffers diagnostic logs. |
| `web/index.html` | Loads the two scripts (`defer`, library before glue) in `<head>`. Boots Flutter normally on every route including the callback. |
| `lib/services/microsoft_auth_service.dart` | Dart wrapper over `window.xdMsal` (`dart:js_interop`): `startSignInRedirect()`, `getRedirectResult()`, `enableLiveLogs()`, `dumpLogs()`. |
| `lib/services/auth_service.dart` | `microsoftLogin(idToken)` → `POST /api/auth/microsoft-login`; stores session token; 401 → tagged `AuthException('…', errorCode: 'MicrosoftNoAccount')`. |
| `lib/providers/auth_provider.dart` | `authBootstrapProvider` consumes the redirect result and completes login; `microsoftLoginErrorProvider` carries a rejection reason to the login screen; `microsoftAuthServiceProvider`. |
| `lib/widgets/login/login_card.dart` | The button (feature-flagged) + "or" divider; shows the rejection message. |
| `lib/screens/microsoft_callback_screen.dart` | Transient spinner on `/auth/microsoft-callback`. |
| `lib/router.dart` | Bare route `/auth/microsoft-callback` → `MicrosoftCallbackScreen`. |

**API contract** (shared with the backend track): `POST /api/auth/microsoft-login`
`{ idToken }` → 200 `{ success, data: { sessionToken } }` (identical shape to
`/api/auth/login`) or 401 for unknown user / invalid token.

**MSAL config** (`msal_interop.js`): `clientId` and `authority`
(`…/organizations`, multitenant) are the app registration's **public** identifiers
(not secrets). `redirectUri = window.location.origin + '/auth/microsoft-callback'`
— derived at runtime so the same build works on `localhost:8080` (dev) and
`app.xpensedesk.com` (prod); **both are registered as SPA reply URLs in Entra.**
Scopes `openid profile email User.Read`. **PKCE, no client secret.**

---

## Why redirect, not popup

We started with the popup flow (`loginPopup`). It does not work reliably against
Microsoft here, and the root cause is not fixable from our side:

**Microsoft's login pages send `Cross-Origin-Opener-Policy`.** COOP puts the popup
in a different browsing-context group and **severs the link between the app window
(opener) and the popup.** MSAL's popup flow depends on the opener reading the auth
response off the popup (it polls the popup's URL — there is no `postMessage` relay;
`opener` appears literally zero times in the bundle). Once COOP cuts that link:

- the opener can never read the code back → sign-in never completes; and
- our own popup-close detection can't trust `popup.closed` either.

This is worst in exactly the locked-down corporate/M365 browsers this feature
targets. The redirect flow sidesteps all of it: **one tab the whole time** — no
popup, no opener, no COOP severing, and the PKCE request cache is present on return.

---

## Problems we hit (and the lesson each taught)

A chronological war-log so we don't repeat these.

1. **`createPublicClientApplication` doesn't exist in v5.** Our first glue called
   `msal.PublicClientApplication.createPublicClientApplication(...)`, which threw
   immediately (generic failure on every click). → Use
   `new msal.PublicClientApplication(cfg)` + `await app.initialize()`.

2. **Lazy init blocked the popup (`popup_window_error`).** Initializing MSAL
   *inside* the click handler meant `loginPopup()` ran only after `await
   initialize()`; that async gap consumed the click's user-activation and the
   browser blocked the popup. → **Initialize at load**, before any interactive call.

3. **Closing the popup hung the spinner.** MSAL's standard popup flow swallows the
   missing response when the user closes the window, so `loginPopup()` never
   settles. We added a popup-close watchdog… which then hit COOP (couldn't trust
   `popup.closed`). Another nail in the popup coffin.

4. **`interaction_in_progress` on the second attempt.** Abandoning MSAL's popup
   promise left its interaction lock set. (Worked around by clearing the stale
   `interaction.status` key — moot once we dropped popup.)

5. **Flutter booted on the callback path and ate the hash.** `web/index.html` had
   **two independent IIFEs**; our early `return` in the first only exited that IIFE,
   so the second still booted Flutter on `/auth/microsoft-callback`. Flutter routed
   the path to the login screen **and stripped the `#code=…` fragment**, so MSAL
   couldn't read it. → We later merged the guards; ultimately the redirect flow +
   booting normally made this a non-issue.

6. **`no_token_request_cache_error` in the popup.** `msal_interop.js` loads in the
   popup too; calling `handleRedirectPromise()` there threw because the popup's
   `sessionStorage` has no PKCE request cache (it lives in the opener). Another
   popup-only failure.

7. **The result arrives on `/`, not on the callback route.** Even after the token
   exchange succeeded, we landed on the login page with no backend POST. Console
   logs proved the token was obtained (`hasIdToken: true`) — but on the **`/` load**,
   because MSAL's default `navigateToLoginRequestUrl` returns the finalized result
   to the login-request URL. Nothing on `/` was reading it. → **Consume
   `getRedirectResult()` in `authBootstrapProvider`** (which runs on `/`), not on
   the callback screen. This was the key insight that made it work.

8. **`SelectableRegion` assertion → removed the app-wide `SelectionArea`.** A red
   screen with `_selectable == null is not true` kept appearing. Root cause: the
   app-wide `SelectionArea` in `AuthGate` (added for "select any text on any
   screen") trips a Flutter 3.41.2 framework bug — when a provider-driven rebuild
   re-inserts a widget that carries its own `SelectionContainer`
   (dropdown/menu/tooltip overlays use `SelectionContainer.disabled`) under the
   `SelectionArea`, `add()` asserts. It red-screens in debug and is an illegal
   double-registration in release. **Fix:** removed the app-wide `SelectionArea`
   from `AuthGate` (text selection is a nicety, not core UX). To restore selection
   later: scoped `SelectableText` on specific content, or re-add `SelectionArea`
   after a Flutter upgrade carrying the framework fix. Unrelated to auth, but
   surfaced during this work.

**Debugging method that finally cracked it:** stop guessing, **instrument every
step** (`console.log`/`debugPrint`), and make the callback a **diagnostic stop that
shows the token + claims without POSTing or redirecting.** The logs immediately
showed the token was fine and only the *consumption point* was wrong.

---

## Feature flags

Both live in `AppConfig` (`assets/config/app_config_<env>.yaml`) — **not**
`pubspec.yaml` (which isn't runtime-readable) — so they are per-environment.

```yaml
features:
  enableMicrosoftLogin: true|false      # show the button + process the redirect
  enableMicrosoftLoginLogs: true|false  # stream [xdMsal] diagnostics to the console
```

- **`enableMicrosoftLogin`** — gates the button + "or" divider in the login card,
  **and** the redirect-processing block in `authBootstrapProvider`. Off ⇒ the
  feature is invisible and inert. Shipped **dark** in prod (`false`); flip to
  `true` to launch.

- **`enableMicrosoftLoginLogs`** — turns on the `[xdMsal]` diagnostic logs. Meant
  for debugging Microsoft login **in production**: flip to `true`, redeploy,
  reproduce, read the browser console.

**How the log flag works (and why it's indirect):** the JS glue runs *before*
Dart/`AppConfig` loads, so it can't read the flag at emit time. The glue therefore
**always buffers** log lines into `window.xdMsalLog`, and only streams to the
console when `window.xdMsalLogsLive` is set. On startup, if the flag is on,
`authBootstrapProvider` calls `enableLiveLogs()` **and** `debugPrint(dumpLogs())` —
flushing the buffer so even the load-time lines (emitted before Dart booted) are
captured. Flag off ⇒ nothing reaches the console.

**Known minor cost:** because the redirect flow must process the return at page
load, `msal-browser.min.js` (~80 KB gzipped, cached) loads on every page even when
`enableMicrosoftLogin` is `false`. It no-ops. If zero dark-launch overhead is ever
required, env-template the `<script>` tags out — not currently done.

---

## Prerequisites (Entra app registration — already configured)

- Application (client) ID: `eb4d44fd-888c-4c12-9de2-ea25cf46a55f`
- Authority (multitenant work/school): `https://login.microsoftonline.com/organizations`
- Platform: **SPA** (auth-code + PKCE, no secret)
- Registered SPA reply URLs:
  - Dev: `https://localhost:8080/auth/microsoft-callback`
  - Prod: `https://app.xpensedesk.com/auth/microsoft-callback`

If the front-end origin ever changes (new dev port, new prod domain), register the
new origin + `/auth/microsoft-callback` as an SPA reply URL, or sign-in fails with
a redirect-mismatch (`AADSTS50011`).

---

## Testing notes

- **Dev must run on exactly `https://localhost:8080`** — that's the registered dev
  reply URL. A plain `flutter run` on a random http port fails with `AADSTS50011`.
- **Editing `web/index.html` needs a full `flutter run` restart** (it isn't
  hot-reloaded). `msal_interop.js` is served fresh on reload.
- **Hard-reload / clear site data after changes** — Flutter's service worker caches
  `index.html` and the JS, and can serve stale copies (this repeatedly masked fixes
  during development).
- A real, XpenseDesk-registered Microsoft account is required to see a *successful*
  login; unknown users get the "no account" message (this is correct).
