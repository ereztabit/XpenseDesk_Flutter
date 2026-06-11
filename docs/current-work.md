# Current Work & TODO

## Currently Working On

- Employee GovId — **Features A + B shipped.** A: optional `govId` (תעודת זהות) at employee onboarding + self profile. B: admin edits an employee via the reused profile UI (shared `ProfileEditor` + `EditUserScreen`, pencil icon on Users rows, `/api/users/details` + `/api/users/admin-update`); onboarding pre-fills from `/me`. Closed the "cannot edit employee name" bug. Spec: docs/in-progress/employee-gov-id.md.
- Multi-currency expenses (docs/in-progress/multi-currency-expenses.md) — core + Follow-up 1 (server-driven currency list from `trackedCurrencies`) shipped. Remaining: Follow-up 2 — verify AI receipt scan handles foreign currency end to end (ISO code vs symbol, codes outside the list).

Open bugs (see `## report bugs (pending)` below)

The Expense Sheets transformation (stories 01–03) shipped; its record lives in
[docs/in-progress/ExpenseSheetsTransformation/](in-progress/ExpenseSheetsTransformation/README.md).


## TODO (Backlog)
- [ ] (optional) extract `sheet_bucket_card.dart`'s `_buildBody` loading/error/data switch into a `SheetBucketBody` widget file — file is now 178 lines (under the 200 cap after the B4 accordion refactor), so this is a nicety, not a size fix
- [ ] block-mode pre-gating on sheet approve/decline CTAs — surface `blockMode` into a provider so the CTA is gated before the call (currently handles the 403 gracefully). See docs/in-progress/ExpenseSheetsTransformation/03-SheetReview.md
- [ ] paginated "View all" screens for the manager dashboard bucket cards — cards show a "Showing 12 of N…" overflow notice until the paginated list screen ships. See docs/in-progress/ExpenseSheetsTransformation/README.md
- [ ] add logos to the authorize page
- [ ] we can remove the phone number and the country code from the authorization page
- [ ] review verbiage on the coupon code on the billing page (both during trial and after trial) — current wording is unclear

## report bugs (pending)

- [ ] Billing -- canceled annual subscription with coupon still shows as "about to renew" -- see docs/bugs/billing-canceled-annual-coupon-shows-about-to-renew.md
- [ ] Billing -- billing screen doesn't refresh after renewing a subscription -- see docs/bugs/billing-no-refresh-after-renewing.md
- [ ] Manager Dashboard -- top analysis/spend-overview widget disappeared (only a placeholder now) -- see docs/bugs/manager-dashboard-missing-analysis-widget.md
- [ ] Users module -- mobile layout looks too dense -- see docs/bugs/users-screen-mobile-layout-too-dense.md
- [ ] Users module -- back button looks different from the rest -- see docs/bugs/users-screen-back-button-inconsistent.md
- [ ] Expense Analysis -- should focus on previous cycle, not the current/active one -- see docs/bugs/expenses-analysis-default-to-previous-cycle.md
- [ ] Expense Analysis -- detail date range should use long "June 1 2026" format -- see docs/bugs/expenses-analysis-detail-date-long-format.md
- [ ] A1 (postponed) Expense editor -- calendar widget unstable / not cross-browser; likely already resolved (Material showDatePicker, firstDate correct, Flutter 3.41 CanvasKit-only) -- verify-first when resumed -- see docs/bugs/calendar-widget-unstable-cross-browser.md
- [ ] A2 Add employee -- multi-add affordance is invisible -- see docs/bugs/add-employee-multi-add-affordance-invisible.md
- [ ] A4c Add expense -- out-of-range invoice date should validate client-side -- see docs/bugs/invoice-date-out-of-range-client-validation.md

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
- [ ] Date pickers: first day of week by country (Israel = Sunday, others = Monday) -- post-MVP. See docs/in-progress/calendar-week-start-localization-spec.md
- [ ] preserve protected deep links through login so users who open a report or dashboard URL while logged out land on that exact page after authentication - see docs/in-progress/post-login-deep-linking-spec.md

## submit an expense

- [ ] multi-currency expenses — send `dynamicAmount`, base-currency display, live `/api/conversion/preview` hint. See docs/in-progress/multi-currency-expenses.md

## manager expenses report

- [ ] build the spend overview widget for manager and employee docs/in-progress/spend-overview-spec.md
- [ ] Missing invite users option after signup - quick onboarding flow to allow manager invite users

## management screens
- [ ] employee govId (תעודת זהות) + admin employee editing (name/language/govId); also closes the "cannot edit employee name" bug. See docs/in-progress/employee-gov-id.md
- [ ] we need to configure which categories are available
- [ ] we need to be able to delete pending users


## processes & other stuff

- [ ] spend history - user

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
