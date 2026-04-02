# Current Work & TODO

## Currently Working On

### Company Configuration — Billing Module
Spec: `docs/in-progress/company-configuration-spec.md` (§0.2)

- [ ] Story 1 — Tab shell (General / Billing / Billing History tabs)
- [ ] Story 2 — Billing overview read-only (Current Plan card)
- [ ] Story 3 — Payment method read-only (card info + status warnings)
- [ ] Story 4 — Billing information form (collapsible, save)
- [ ] Story 5 — Cancel subscription dialog
- [ ] Story 6 — Resume subscription dialog
- [ ] Story 7 — Switch plan dialog (upgrade / downgrade + cancel scheduled switch)
- [ ] Story 8 — Update payment card (Tranzila iframe)
- [ ] Story 9 — Billing History tab (transactions table)
- [ ] Onboarding → subscription flow (phase 1 done: company init + pending payment banner)
  - Phase 1 ✓ — `subscriptionStatus` added to `CompanyInfo`; `companyProvider` invalidated after OTP so dashboard sees fresh company data; amber `PendingPaymentBanner` in `AppHeader` for `PendingPayment` status
  - Phase 2 — build the subscription setup screens (plan selection, Tranzila payment, coupon)


## TODO (Backlog)
- [ ] add logos to the authorize page
- [ ] we can remove the phone number and the country code from the authorization page
- [ ] build the entire billing module

## report bugs (pending)


* onboarding bug - landing on dashboard with info of previous company after new signup

## general environment


- [ ] create a real privacy policy
- [ ] create a real terms and conditions
- [ ] need to replace the icon of the webpage
- [ ] when an api fails it keeps calling it on a loop - if you get 400/500 - stop with an error.
- [ ] login with google
- [ ] get zehut for customers in IL
- [ ] we need to be able to impersonate a user
- [ ] we need a admin view to see compaines usage
- [ ] we need to connect google analytics / GTM
- [ ] we need to translate better to hebrew
- [ ] preserve protected deep links through login so users who open a report or dashboard URL while logged out land on that exact page after authentication - see docs/in-progress/post-login-deep-linking-spec.md

## submit an expense


## user expenses report

- [ ] the ai strike through when ai didnt recognize the image is not clear - add explicit warning

## manager expenses report

- [ ] build the spend overview widget for manager and employee docs/in-progress/spend-overview-spec.md
* Missing rejection reason field for manager - new feature
* Missing invite users option after signup - quick onboarding flow to allow manager invite users

## management screens
- [ ] we need to configure which categories are available
- [ ] we need to be able to delete pending users


## processes & other stuff

- [ ] spend history - user
- [ ] billing area

---

## Tranzila Support — Open Questions

### SDK / Integration
- [ ] **Q1** — Inline field validation language: iframe validation messages (e.g. "invalid card number") always appear in Hebrew. Is there a param in `TzlaHostedFields.create()` or `fields.charge()` to control the language? `response_language` does not affect iframe UI strings.
- [ ] **Q2** — `force_txn_on_3ds_fail` security: can this be locked at the terminal level or in the `thtk` issuance so the client-side value cannot be overridden?
- [ ] **Q3** — 3DS test cards: dev terminal cannot complete any 3DS flow with `4907639999909022`, `4907639999990022`, `4918914107195005`. Does the terminal need explicit 3DS enrollment? What CVV/expiry to use?
- [ ] **Q4** — Phone number validation in `fields.charge()`: format of `phone_country_code` (`+972` vs `972`), min/max length of `phone_number`, does invalid phone fail the transaction or get ignored?

### Sandbox
- [ ] **Q5** — Need a sandbox terminal for development — we are hitting live transactions. `sandbox: false` is always correct per docs, so sandbox must be terminal-level. Please provision a sandbox terminal and provide test card numbers.

### Recurring Payments
- [ ] **Q6** — How to test the full charge flow (tokenization → recurring charge) without real transactions? Is there a sandbox/test endpoint for the charge API? Share API docs for charging a saved token.

### Billing Documents
- [ ] **Q7** — Can the system issue a Hebrew קבלה for Israeli customers and an English invoice for international customers? Per-transaction or terminal-level setting?
- [ ] **Q8** — Accountant requires separate document number sequences for Israeli vs. international transactions. Does Tranzila support separate numbering series, and if not, what is the recommended approach?

### Multi-Currency
- [ ] **Q9** — Can we charge Israeli companies in NIS and foreign companies in USD? Does this require separate terminals per currency, and can they operate under the same merchant account?

---
