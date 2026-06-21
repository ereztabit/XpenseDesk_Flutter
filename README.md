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
| 2026-06-21 | v1.7 | New brand logo + fix payment-screen logo | Replace the old logo.png with xpensedesk-main-logo-trans.png across the app, ship the logo as a static asset on the payment (card authorize) pages so it resolves on prod, and remove the old logo.png. |
| 2026-06-21 | v1.7 | Plan-switch dialog: server-driven prices | Replace hardcoded plan prices/currency in the monthly/annual switch dialog with the company API's plan prices + currency symbol. Date/proration deferred to a backend follow-up. |
| 2026-06-21 | v1.7 | Hide transaction history (v2) | Hide the Billing History tab on the Company Config screen and defer it to v2; code kept in place. |
| 2026-06-21 | v1.7 | Remove manager login buttons | Remove the dev/manager quick-login buttons from the login screen so no dev login affordance reaches production. |
| 2026-06-21 | v1.6 | Branching & release method | Adopt develop/main trunk-and-release flow with start-feature / finish-feature / ship-feature skills; block search-engine indexing for the private app. |
