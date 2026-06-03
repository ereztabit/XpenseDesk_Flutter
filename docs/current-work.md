# Current Work & TODO

## Currently Working On


- **Expense Sheets transformation** — server has shipped sheet-centric approvals (Story 1, Part 2). Building the Flutter UX + activating the new APIs, story by story.
  - Server discovery: [docs/in-progress/ExpenseSheetsTransformation/ExpenseSheetsEvolution.md](in-progress/ExpenseSheetsTransformation/ExpenseSheetsEvolution.md)
  - Stories folder: [docs/in-progress/ExpenseSheetsTransformation/](in-progress/ExpenseSheetsTransformation/README.md)
  - ✅ [01 — Employee Dashboard](in-progress/ExpenseSheetsTransformation/01-EmployeeDashboard.md) — shipped, CR'd, build clean. Under manual UI verification.
  - ✅ [02 — Manager Dashboard](in-progress/ExpenseSheetsTransformation/02-ManagerDashboard.md) — shipped against the live `GET /api/expense-sheets` endpoint, CR'd, build clean. Under manual UI verification.
  - ✅ [03 — Sheet Review](in-progress/ExpenseSheetsTransformation/03-SheetReview.md) — whole-sheet approve/decline + per-line review + activity timeline. Verified against live server, CR'd, build clean. Under manual UI verification.
  - Deferred follow-up: block-mode pre-gating on approve/decline CTAs (currently handles the 403 gracefully; pre-gating needs `blockMode` surfaced into a provider — cross-cutting).

Open bugs (see `## report bugs (pending)` below)


## TODO (Backlog)
- [ ] we have removed CycleId from the /me api - just making sure you are not using it.
- [ ] add logos to the authorize page
- [ ] we can remove the phone number and the country code from the authorization page
- [ ] review verbiage on the coupon code on the billing page (both during trial and after trial) — current wording is unclear

## report bugs (pending)

- [ ] Employee dashboard empty state not centered on mobile -- see docs/bugs/employee-dashboard-empty-state-not-centered-mobile.md
- [ ] Manager sheet review desktop layout -- content too narrow, date column wraps, invisible row borders, no edit icon -- see docs/bugs/manager-sheet-review-desktop-layout-issues.md
- [ ] Employee cannot edit a declined expense -- _isEditable only checks isPending, misses Declined status on Declined sheet -- see docs/bugs/employee-cannot-edit-declined-expense.md
- [ ] Decline sheet dialog -- no 200-char limit enforced in UI, missing employee name and post-decline explanation -- see docs/bugs/decline-sheet-dialog-char-limit-and-missing-context.md
- [ ] Approve sheet dialog -- wrong text, word duplication ("items items"), missing amount and employee name, missing edit-lock warning -- see docs/bugs/approve-sheet-dialog-wrong-text.md
- [ ] Manager expense detail edit mode -- no cancel button, approve/decline active during edit, date shows wrong format -- see docs/bugs/manager-expense-detail-edit-mode-issues.md
- [ ] Sheet review -- no prompt after all expenses reviewed: auto-approve when all approved, show resolution dialog when some declined -- see docs/bugs/sheet-review-no-prompt-after-all-expenses-reviewed.md
- [ ] Employee dashboard expense list -- 4 issues: missing status tabs on Submitted sheets, mobile approved expense opens in edit mode (wrong param in carousel), swipe-to-delete missing for declined expenses, status pill missing from desktop table -- see docs/bugs/employee-dashboard-expense-list-issues.md
- [ ] New Expense — date validation error shows in English while UI is in Hebrew (should be localized + ideally caught client-side before server). See docs/bugs/new-expense-date-validation-english-in-hebrew-ui.md
- [ ] Onboarding country selector -- disable it for now (Israel only); re-enable when multi-country is supported -- see docs/bugs/onboarding-country-selector-disable-for-now.md
- [ ] Onboarding cycle day -- should be radio buttons, label should explain it is the monthly expense submission date -- see docs/bugs/onboarding-cycle-day-should-be-radio-buttons.md
- [ ] Manager navigation menu — no link to the main dashboard; add one. See docs/bugs/manager-nav-missing-main-dashboard-link.md
- [ ] User dashboard (mobile) — missing the layout/table toggle. See docs/bugs/user-dashboard-mobile-missing-layout-toggle.md
- [ ] Edit expense — cancel button shows wrong Hebrew caption ("התעלם" should be "בטל"). See docs/bugs/edit-expense-cancel-button-wrong-hebrew-caption.md
- [ ] Remove the receipt number from the card layout. See docs/bugs/remove-receipt-number-from-card-layout.md
- [ ] canceled annual subscription with coupon still shows as "about to renew" on the billing screen
  - Reproduce:
    1. create a new company
    2. end its trial
    3. subscribe to annual with coupon code
    4. cancel subscription
  - Expected: subscription shows as canceled
  - Actual: still displays as about to renew
- [ ] after renewing a subscription, the billing screen doesn't refresh to reflect the new state

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
