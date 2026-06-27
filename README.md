# xpensedesk_flutter

XpenseDesk - an AI-powered expense approval tool for small businesses (Flutter web).

## Branching & release

Work flows `develop` (trunk) -> `main` (release/deploy). Pushing `main` deploys to
Azure Static Web Apps via CI. See [docs/branching-and-release.md](docs/branching-and-release.md).

## Feature log

Newest first. One row per feature. The row is inserted at `start-feature` (Version
`TBD`); the version is filled in at `finish-feature` when the build is bumped.

| Date | Version | Feature | Description |
|------|---------|---------|-------------|
| 2026-06-27 | v1.13 | Trial-period length as a config parameter | Make the free-trial length (currently hardcoded as 14 days in the plan-selection marketing copy) a frontend config value in app_config*.yaml, exposed via AppConfig. The trial copy is built by concatenation so the number comes from config, not a literal "14". The authoritative trialEndDate still comes from the backend; this only fixes the displayed copy. |
| 2026-06-25 | v1.12 | Terms of Service page (public, Hebrew RTL) | Ship the real Terms of Service as a public static page (web/legal/terms-he.html, styled to AppTheme) opened in a new tab from the header menu and the login footer; always Hebrew. Reachable via public URL with no login. Replaces the in-app iframe embed, which broke the header overlay menu on web (platform-view z-order). |
| 2026-06-22 | v1.11 | iOS install drawer: simpler steps + share-icon reference | Trim the iOS "Add to Home Screen" drawer to three steps (Share → Add to Home Screen → Add) — drop the redundant open-Safari/URL steps since iOS launches home-screen web clips full-screen regardless of browser, and show the iOS Share glyph beside step 1 so users can recognize the button. |
| 2026-06-21 | v1.10 | Android/Chromium native install trigger | Fire the browser's native install dialog ourselves via a captured beforeinstallprompt (index.html), so install isn't lost after Chrome's one-shot mini-infobar: an "Install app" menu item + (mobile) auto-drawer with an Install button. iOS manual "Add to Home Screen" drawer unchanged; hidden once installed. |
| 2026-06-21 | v1.10 | Trial-cancel rollback treated as success | Cancelling during the free trial before any charge rolls the opt-in back: the cancel API returns 200 success with data:null. Stop treating null data as an error; reload billing from GET /api/company/billing after any successful cancel and let it drive the trial vs CancellationRequest UI. |
| 2026-06-21 | v1.9 | iOS "Add to Home Screen" drawer | iOS has no native install prompt, so guide iPhone users with a bottom drawer: open Safari → go to app.xpensedesk.com → Share → Add to Home Screen. Auto-opens once (remembered when dismissed) + an "Add to Home Screen" menu item opens it on demand. iOS-only, hidden once installed; no effect on desktop/Android. |
| 2026-06-21 | v1.8 | Installable PWA (branded manifest + icons) | Make XpenseDesk installable to home screen / desktop: brand manifest.json (name, colors, orientation), generate branded + maskable app icons, polish index.html meta, and un-gitignore web/icons + manifest.json so they deploy. Native browser install prompt; no custom in-app button. |
| 2026-06-21 | v1.7 | Cancel notice uses trial-end date during trial | The cancel-subscription "active until" date showed subscription.endDate (a future paid period that never occurred) while on trial; use trialEndDate when the company is still in trial. |
| 2026-06-21 | v1.7 | Branded browser-tab favicon | Un-ignore web/favicon.png (it was gitignored so it never deployed), ship a 32x32 branded favicon, and cache-bust the icon link. PWA install icons/manifest deferred to the PWA task. |
| 2026-06-21 | v1.7 | Fix next-charge date off-by-one | The trial next-charge box added +1 day to the trial-end date, showing the charge a day late. Use the server's subscription.startDate (the real charge date) instead of client date math. |
| 2026-06-21 | v1.7 | Fix input-looking title on card page | Remove the meaningless "enter your card details" heading on the credit-card authorize page that was styled to look like a text input. Logo half of the bug was fixed by the brand-logo work. |
| 2026-06-21 | v1.7 | Downgrade banner shows monthly price | The pending-switch banner on the Current Plan card now shows the future-plan charge ("...at a cost of X") from futurePlan.chargeAmount in company currency, not just the date. |
| 2026-06-21 | v1.7 | Auto-apply typed coupon on Pay Now | If a coupon is typed but not applied, pressing Pay Now now auto-applies and validates it before charging; an invalid coupon blocks payment with an inline error. Covers onboarding + billing no-plan card. |
| 2026-06-21 | v1.7 | New brand logo + fix payment-screen logo | Replace the old logo.png with xpensedesk-main-logo-trans.png across the app, ship the logo as a static asset on the payment (card authorize) pages so it resolves on prod, and remove the old logo.png. |
| 2026-06-21 | v1.7 | Plan-switch dialog: server-driven prices | Replace hardcoded plan prices/currency in the monthly/annual switch dialog with the company API's plan prices + currency symbol. Date/proration deferred to a backend follow-up. |
| 2026-06-21 | v1.7 | Hide transaction history (v2) | Hide the Billing History tab on the Company Config screen and defer it to v2; code kept in place. |
| 2026-06-21 | v1.7 | Remove manager login buttons | Remove the dev/manager quick-login buttons from the login screen so no dev login affordance reaches production. |
| 2026-06-21 | v1.6 | Branching & release method | Adopt develop/main trunk-and-release flow with start-feature / finish-feature / ship-feature skills; block search-engine indexing for the private app. |
