# Backlog

This file is our state of mind: everything open, nothing left behind. **Nothing is
in progress right now.**

- **Start work on an item** → move its line into a `## Currently Working On`
  section at the top of this file, and move its spec into `docs/in-progress/`.
- **Finish and ship it** → delete the line from this file entirely and move its
  spec to `docs/completed/`. Shipped work leaves no trace here; the record is the
  `README.md` feature-log row plus `docs/completed/` (closed bugs go to
  `docs/bugs/completed/`).
- **Stop working on it, or ditch it** → move the line back to a backlog section
  below and its spec back to `docs/backlog/`. Nothing stays parked in
  `## Currently Working On` or in `docs/in-progress/`.

So: `docs/in-progress/` holds specs for what we are working on **right now** and
is empty when we are not; `docs/backlog/` holds specs for open features we are not
working on; `docs/completed/` holds shipped ones; bugs live in `docs/bugs/`.

Production readiness: see docs/pre-deployment-issues.md — no hard blockers remain.

## TODO (Backlog)

- [ ] AI receipt scan — support foreign-currency receipts end to end (scan a USD/EUR invoice → foreign expense with base-currency conversion). Multi-currency itself is shipped and verified; this is the remaining AI-scan feature. Spec + open questions: docs/backlog/multi-currency-expenses.md (Follow-up 2). Test kit ready: 6 synthetic receipts + matrix in docs/test-receipts/
- [ ] block-mode pre-gating on sheet approve/decline CTAs — surface `blockMode` into a provider so the CTA is gated before the call (currently handles the 403 gracefully). See docs/completed/ExpenseSheetsTransformation/03-SheetReview.md
- [ ] add logos to the authorize page
- [ ] review verbiage on the coupon code on the billing page (both during trial and after trial) — current wording is unclear. Audit + task in docs/backlog/coupon-verbiage-review.md

## report bugs (pending)

- [ ] Onboarding plan picker -- annual plan missing "2 months free (16% discount)" savings label -- see docs/bugs/onboarding-annual-plan-missing-savings-label.md
- [ ] Billing -- canceled annual subscription with coupon still shows as "about to renew" -- see docs/bugs/billing-canceled-annual-coupon-shows-about-to-renew.md
- [ ] Billing -- billing screen doesn't refresh after renewing a subscription -- see docs/bugs/billing-no-refresh-after-renewing.md
- [ ] AuthService email validation uses regex instead of email_validator package -- see docs/bugs/auth-service-email-regex-violates-validator-rule.md
- [ ] Payments "all done" caption is wrong on a fresh all-zeros dashboard (onboarding state) -- see docs/bugs/payments-all-done-caption-wrong-at-onboarding-zero-state.md
- [ ] Stale data (users list) after switching company -- previous tenant's data leaks into new session -- see docs/bugs/stale-data-after-switching-company.md
- [ ] flutter analyze reports 9 pre-existing info-level lints (4 dart:html deprecations also block wasm) -- see docs/bugs/flutter-analyze-info-lints-cleanup.md
- [ ] Sheet Review of an approved sheet defaults to the empty Pending tab (should default to Approved) -- see docs/bugs/sheet-review-approved-sheet-defaults-to-empty-pending-tab.md
- [ ] Onboarding OTP step -- always-visible Microsoft signup option + slow-delivery warning after 30s (365 mailboxes up to ~3 min) -- see docs/bugs/onboarding-otp-slow-delivery-warning-and-microsoft-fallback.md
- [ ] AI receipt scan -- "Detected details" card shows raw amount + ISO code ("1880.00 ILS") instead of "₪1,880.00" -- see docs/bugs/ai-detected-amount-not-currency-formatted.md
- [ ] "Add employee" multi-add affordance is invisible -- see docs/bugs/add-employee-multi-add-affordance-invisible.md
- [ ] Out-of-range invoice date only fails at submit (no client-side validation) -- see docs/bugs/invoice-date-out-of-range-client-validation.md
- [ ] Manager Dashboard missing the top analysis widget -- see docs/bugs/manager-dashboard-missing-analysis-widget.md
- [ ] Users module back button looks different from the rest -- see docs/bugs/users-screen-back-button-inconsistent.md
- [ ] Users module looks too dense on mobile -- see docs/bugs/users-screen-mobile-layout-too-dense.md
- [ ] (deferred) Calendar widget is unstable and not cross-browser -- postponed, see docs/bugs/calendar-widget-unstable-cross-browser.md
- [ ] (deferred to v2) Tranzila hosted-fields validation messages are always Hebrew -- fine for the Israel launch, see docs/bugs/tranzila-iframe-validation-language-hebrew-only.md

## general environment

- [ ] when an api fails it keeps calling it on a loop - if you get 400/500 - stop with an error.
- [ ] login with google
- [ ] we need to be able to impersonate a user
- [ ] we need an admin view to see companies usage
- [ ] we need to translate better to hebrew
- [ ] Date pickers: first day of week by country (Israel = Sunday, others = Monday) -- post-MVP. See docs/backlog/calendar-week-start-localization-spec.md
- [ ] preserve protected deep links through login so users who open a report or dashboard URL while logged out land on that exact page after authentication - see docs/backlog/post-login-deep-linking-spec.md

## manager expenses report

- [ ] build the spend overview widget for manager and employee -- manager card is live; the employee side and the approvals-screen slot are still placeholders. See docs/backlog/spend-overview-spec.md

## management screens

- [ ] we need to configure which categories are available

## processes & other stuff

- [ ] spend history - user

## Tranzila support — open questions

- [ ] **Q2** — `force_txn_on_3ds_fail` security: can this be locked at the terminal level or in the `thtk` issuance so the client-side value cannot be overridden? (Answered questions are recorded in docs/completed/tranzila-card-tokenization.md, not here.)
