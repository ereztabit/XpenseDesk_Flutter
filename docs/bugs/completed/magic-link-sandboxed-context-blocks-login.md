# Bug: Magic-link login fails in sandboxed / in-app browser contexts (blank page)

> **Status: done**

## Resolution

Root cause turned out to be **external**: a browser extension (Torii, a
SaaS-management/discovery tool) running in the reporter's Chrome profile injects a
`Content-Security-Policy: sandbox` onto the page response. That makes the page a
top-level but opaque, sandboxed origin (`self.origin === 'null'`), which blocks
localStorage/IndexedDB/cookies and the service worker — so login could not
complete and the app originally showed a blank page.

Confirmed by process of elimination:
- Production sends no sandbox/CSP header (verified via curl).
- The site boots normally in a clean browser and in Incognito (extensions off).
- The reporter's console showed `window.top === window.self` (top-level) yet
  `self.origin === 'null'` and `localStorage` throwing "sandboxed and lacks the
  'allow-same-origin' flag" — the signature of a client-side CSP-sandbox
  injection. Incognito (extensions disabled) logs in fine.

So this is not an app defect. Not fleet-wide — it affects only profiles running
such a page-sandboxing extension. User workaround: use Incognito, or disable the
extension for app.xpensedesk.com.

We still shipped a genuine improvement (v1.19), which stays in place:
- `web/flutter_bootstrap.js` — feature-detects the service worker so the
  SecurityError no longer aborts boot.
- `web/index.html` — detects the opaque-origin context and shows an actionable
  "open this link in your browser" overlay instead of a blank white page.

A follow-up "clickable link" tweak was explored and discarded: a `target="_blank"`
link cannot escape a sandboxed context (popups are blocked or inherit the sandbox),
so it adds no value here. No further code change; prod remains at v1.19.

## Problem

PRODUCTION — users cannot log in. Clicking the magic link
(`https://app.xpensedesk.com/login?token=...`) lands on a blank page. Console shows:

```
Uncaught (in promise) SecurityError: Failed to read the 'serviceWorker' property
from 'Navigator': Service worker is disabled because the context is sandboxed and
lacks the 'allow-same-origin' flag.
  loadServiceWorker @ flutter.js
  load @ flutter.js
  (anonymous) @ flutter_bootstrap.js
```

This happens when the link is opened inside a context that is sandboxed WITHOUT
`allow-same-origin` — i.e. an email client's in-app browser / link preview
(Outlook reading-pane preview, webmail/Teams/Slack in-app browsers, Safe-Links
detonation frames). Because magic links are, by definition, clicked from email,
a large share of users can hit this.

## Root Cause

Confirmed by reading the shipped `flutter.js` (Flutter 3.41.2):

- `loadServiceWorker` guards with `"serviceWorker" in navigator`. The `in`
  operator only checks property existence on `Navigator.prototype` — it does not
  invoke the getter — so it returns `true` even in a sandboxed/opaque-origin
  context.
- It then *reads* `navigator.serviceWorker` (the getter), which throws
  `SecurityError` **synchronously**.
- The caller is `await loader.loadServiceWorker(e).catch(...)`, but a synchronous
  throw never yields a promise, so `.catch()` never runs. The throw propagates
  out of the async `load()` as an unhandled rejection ("Uncaught (in promise)").
- Crucially, this happens **before** `main.dart.js` is injected, so the Flutter
  engine never boots -> blank page.

Not a hosting issue: production sends no `Content-Security-Policy: sandbox` and no
`X-Frame-Options`. The sandbox is imposed by the opening context, not by us.

Secondary consequence: "lacks allow-same-origin" means an opaque origin, where
same-origin storage (`localStorage`/IndexedDB, where the session token is kept)
also throws. So even if the app booted, login could not complete in that context.

## Reproduce Steps

1. Open the magic link inside an email client that renders it in a sandboxed
   in-app preview (no `allow-same-origin`).
   -- Expected: app loads and completes sign-in, or clearly tells the user what
      to do.
   -- Actual: blank page; `SecurityError` in console; app never boots.

Note: opening the same URL directly in a normal browser tab works — that context
is not sandboxed.

## Suggested Fix (implemented)

Two-part frontend fix (this repo owns `web/`):

1. Boot resilience — `web/flutter_bootstrap.js` (custom bootstrap, Flutter
   template tokens): feature-detect the service worker by actually touching the
   getter inside `try/catch`, and only pass `serviceWorkerSettings` when it is
   safe. Normal browsers keep the PWA service worker; sandboxed contexts boot
   without it instead of throwing and aborting boot.

2. Opaque-origin guidance — `web/index.html`: before booting Flutter, detect an
   opaque origin (`self.origin === 'null'` or a `localStorage` access that
   throws). If detected, skip Flutter boot entirely and show a bilingual
   (EN/HE) overlay instructing the user to open the link in a real browser
   (Chrome/Safari/Edge), with the URL rendered as selectable text. Storage and
   cross-origin requests are unusable in that context, so booting the SPA there
   cannot succeed — routing the user to a real browser is the only reliable fix.

Files:
- web/flutter_bootstrap.js (new)
- web/index.html (sandbox-notice overlay + conditional bootstrap injection)

Verified: `flutter build web --release` succeeds; generated
`build/web/flutter_bootstrap.js` has all template tokens resolved and the guard
intact; overlay present in `build/web/index.html`.

## Follow-ups / Open Questions

- Confirm which email client(s) users actually use so we can quantify blast
  radius and, if possible, adjust the magic-link email to encourage
  "open in browser".
- Backend angle (optional): a lightweight server-rendered landing for the
  magic-link step would avoid depending on the SPA booting inside hostile
  contexts. File as a separate backend item if we pursue it.
