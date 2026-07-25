# Disable the dev auto-login shortcut on the login screen

> **Status:** Planned — MVP.

## Problem

The login screen has two one-click "auto-login" shortcuts —
**"DEV: Login as Admin"** and **"DEV: Login as User"** — that skip the real
magic-link flow by calling `_handleDevLogin` → `AuthService.tryToLoginDev`.

These are intended for development only, but today they are gated **only by
`// DEV-ONLY` comments**, not by the build environment. The buttons render
unconditionally, which means they also appear in **PROD** builds. That's both a
security and a polish problem.

We want the auto-login behaviour:
- **Never present in PROD.**
- **Available on dev**, where it's a genuine time-saver — but ideally toggleable
  so we can still exercise the real magic-link login when testing that path.

## Current state

`lib/screens/login_screen.dart`:
- DEV-ONLY import (`url_launcher`) — lines 12–14.
- `_handleDevLogin(String email)` — lines 64–97 (calls `tryToLoginDev`, opens the
  returned magic link).
- DEV-ONLY UI block — lines 202–244: two `OutlinedButton`s wired to
  `_handleDevLogin('admin@xpensedesk.com')` / `('user@xpensedesk.com')`.

None of this is wrapped in an environment check — the comment markers are not
enforced by code.

`lib/config/app_config.dart` already loads the environment via
`--dart-define=ENV=...`; the gate should read from there (e.g. an `isProd` /
`environment` accessor) rather than `kReleaseMode`, so a prod-config build never
shows the shortcut even if compiled in debug.

## Proposed approach

1. Add/confirm an environment accessor on `AppConfig` (e.g. `isDev` / `isProd`).
2. Wrap the DEV-ONLY UI block so it renders **only when not PROD**. In PROD the
   buttons (and the `_handleDevLogin` path) are absent.
3. On dev, keep them available — optionally behind a small toggle so the real
   magic-link flow can be tested without the shortcut.
4. Keep the dev-only English captions as-is (they are debug affordances, never
   shown to real users) — but they must be inside the env gate.

## Open questions

- Toggle granularity: a simple "show on dev only" gate, or a runtime toggle on
  dev to flip between auto-login and the real flow?
- Should `AuthService.tryToLoginDev` itself be compiled out / no-op in PROD as a
  defense-in-depth measure, not just hidden in the UI?

## Done when

- A PROD-config build shows **no** dev auto-login buttons and no path to
  `tryToLoginDev`.
- Dev builds still have the auto-login shortcut (toggleable if we go that route).
