# Pre-Deployment Issues — Production Readiness

> Compiled 2026-06-15 from a code/config review of the Flutter web app.
> Work top-down: hard blockers first, then build/config verification, then
> strongly-recommended fixes. Check items off as they are handled.

---

## Hard blockers (must fix before any prod build)

- [x] **RESOLVED 2026-07-25 — Dev auto-login is not environment-gated.**
  Originally: the "DEV: Login as Admin" / "DEV: Login as User" buttons in
  `lib/screens/login_screen.dart` rendered unconditionally, so in production
  anyone on the login page got one-click admin access via `tryToLoginDev`,
  which returned the magic link.
  **Resolved by deletion rather than by gating** — the buttons, the handler and
  the `tryToLoginDev` service path were all removed (shipped v1.7, "Remove the
  manager login buttons"). Verified 2026-07-25: `lib/` has zero matches for
  `tryToLoginDev` / `loginDev` / `autoLogin` / `devLogin`, and
  `login_screen.dart` contains no DEV block at all.
  Note the original doc's optional "keep it on dev behind a toggle" was dropped;
  there is no dev-only login shortcut in any environment now.
  Record: `docs/completed/disable-dev-auto-login.md`.

No known hard blockers remain.

---

## Build & config — must verify before/at deploy

- [ ] **Build with `--dart-define=ENV=prod`.**
  `AppConfig.environment` defaults to `'dev'` (`lib/config/app_config.dart:17`).
  If the deploy pipeline omits the flag, prod loads `app_config_dev.yaml` →
  backend `https://127.0.0.1:7223` and the dev payment terminal. Confirm the
  release build/CI passes `ENV=prod`.

- [ ] **Verify Tranzila payment config in `assets/config/app_config_prod.yaml`.**
  Currently:
  - `use3ds: false` — the completed Tranzila tokenization doc described prod with
    **3DS = true**. Confirm with Tranzila whether 3DS must be on for live cards
    (regulatory / chargeback exposure), and flip if so.
  - `tranzilaTerminal: xpensedesk` — confirm this is the real production terminal
    name. A wrong terminal means failed or misrouted real charges.

- [ ] **Confirm prod API base URL** `https://api.xpensedesk.com` is live, has a
  valid TLS cert, and CORS allows the deployed web origin.

---

## Strongly recommended before real users

- [ ] **Cross-tenant stale-data bug** — after switching company, the previous
  tenant's user list (and other cached data) leaks into the new session. Privacy
  issue; treat as a launch blocker rather than a normal bug.
  See `docs/bugs/stale-data-after-switching-company.md`.

- [ ] **API retry loop on 400/500** — a failing API keeps getting called in a
  loop instead of surfacing an error; can hammer the backend under failure.
  (Backlog item in `current-work.md`.)

- [ ] **Real Privacy Policy and Terms & Conditions** — currently placeholders, and
  the app takes payments. (Backlog items.)

- [ ] **Correct logo / favicon** — browser tab + PWA icons still use the default.
  See `docs/bugs/incorrect-logo-favicon.md`.

---

## Checked — no action needed

- No raw `print()` calls leaking to the browser console.
- Tranzila/billing code already branches correctly on `AppConfig.environment`
  (`tranzila_popup_service.dart`, `billing_payment_method_card.dart`).
- Dead-code audit complete (build green) — see
  `docs/completed/dead-code-audit-2026-06-15.md`.

---

## Nice-to-have (post-launch, not blocking)

- Better Hebrew translation pass.
- PWA installability (branded manifest/icons) — overlaps with the favicon fix.
  See `docs/completed/pwa-installable-app.md`.
