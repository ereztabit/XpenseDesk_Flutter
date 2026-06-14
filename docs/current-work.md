# Current Work & TODO

## Currently Working On

- Payment Status feature (manager payroll workspace) — Phases 1–8 + 10 SHIPPED & manual-QA passed; committed. Remaining: Phase 9 (edit/revert processed payments) — scope decision pending. Then a follow-up "payment-status fixes" pass for the minor UX/UI issues found in QA (list TBD from user). Plan + status board: docs/in-progress/payment-status-implementation-plan.md
- Multi-currency expenses (docs/in-progress/multi-currency-expenses.md) — core + Follow-up 1 (server-driven currency list from `trackedCurrencies`) shipped. Remaining: Follow-up 2 — verify AI receipt scan handles foreign currency end to end. Test kit ready: 6 synthetic receipts + matrix in docs/test-receipts/ (user scans them in dev).

Open bugs (see `## report bugs (pending)` below)

The Expense Sheets transformation (stories 01–03) shipped; its record lives in
[docs/in-progress/ExpenseSheetsTransformation/](in-progress/ExpenseSheetsTransformation/README.md).


## TODO (Backlog)
- [ ] block-mode pre-gating on sheet approve/decline CTAs — surface `blockMode` into a provider so the CTA is gated before the call (currently handles the 403 gracefully). See docs/in-progress/ExpenseSheetsTransformation/03-SheetReview.md
- [ ] disable the dev auto-login shortcut on the login screen (dev-only toggle; must never reach PROD). See docs/in-progress/disable-dev-auto-login.md
- [ ] add logos to the authorize page
- [ ] review verbiage on the coupon code on the billing page (both during trial and after trial) — current wording is unclear. Audit + task in docs/in-progress/coupon-verbiage-review.md

## report bugs (pending)

- [ ] Billing -- canceled annual subscription with coupon still shows as "about to renew" -- see docs/bugs/billing-canceled-annual-coupon-shows-about-to-renew.md
- [ ] Billing -- billing screen doesn't refresh after renewing a subscription -- see docs/bugs/billing-no-refresh-after-renewing.md
- [ ] App-wide -- screen text is not selectable/copyable (cross-cutting, discuss scope) -- see docs/bugs/payments-text-not-selectable-cross-app.md

## general environment

- [ ] create a real privacy policy
- [ ] create a real terms and conditions
- [ ] make the app installable as a PWA (branded manifest/icons, home-screen icon) — subsumes "replace the icon of the webpage". See docs/in-progress/pwa-installable-app.md
- [ ] when an api fails it keeps calling it on a loop - if you get 400/500 - stop with an error.
- [ ] login with google
- [ ] get zehut for customers in IL
- [ ] we need to be able to impersonate a user
- [ ] we need a admin view to see compaines usage
- [ ] we need to connect google analytics / GTM
- [ ] we need to translate better to hebrew
- [ ] Date pickers: first day of week by country (Israel = Sunday, others = Monday) -- post-MVP. See docs/in-progress/calendar-week-start-localization-spec.md
- [ ] preserve protected deep links through login so users who open a report or dashboard URL while logged out land on that exact page after authentication - see docs/in-progress/post-login-deep-linking-spec.md

## manager expenses report

- [ ] build the spend overview widget for manager and employee docs/in-progress/spend-overview-spec.md
- [ ] Missing invite users option after signup - quick onboarding flow to allow manager invite users

## management screens
- [ ] we need to configure which categories are available


## processes & other stuff

- [ ] spend history - user

---

## Tranzila Support — Open Questions

### SDK / Integration (still open)
- [ ] **Q2** — `force_txn_on_3ds_fail` security: can this be locked at the terminal level or in the `thtk` issuance so the client-side value cannot be overridden?

### Resolved
- **Q1** (Hebrew-only iframe validation language) — deferred to v2; fine for the Israel launch. Filed as a bug: docs/bugs/tranzila-iframe-validation-language-hebrew-only.md
- **Q3** (3DS testing) — there is no sandbox 3DS path; 3DS is tested on a **live terminal** with real cards. Accepted constraint — that's how Tranzila works.
- **Q4** (phone validation in `fields.charge()`) — not needed; dropped.
- **Q5** (sandbox terminal) — answered: sandbox is terminal-level, configured on Tranzila's end (no per-request flag).
- **Q6** (testing the recurring charge flow) — done.
- **Q7** (Hebrew receipt vs English invoice) — resolved, all good.
- **Q8** (separate document number sequences) — resolved, all good.
- **Q9** (charge IL in NIS / foreign in USD) — answered: a **dedicated terminal per country by lead currency** (IL, US, EU, …); not multiplexed through one terminal. Recorded in docs/completed/tranzila-card-tokenization.md.

---
