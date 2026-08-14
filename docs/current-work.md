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

## Tags

Every open line starts with a category and a priority: `[Category][P#]`. New
items get both when they are filed — an untagged line is an unfinished line.

| Category | Means |
|----------|-------|
| `Business` | product behavior, business rules, billing, signup funnel |
| `Security` | auth, tenant isolation, payment safety, data exposure |
| `Technical` | code health, architecture, build and tooling, performance |
| `LookAndFeel` | visual polish, layout, captions, wording, UX defaults |

| Priority | Means |
|----------|-------|
| `P1` | hurting a real customer now, or money / data correctness — fix next |
| `P2` | real friction with no acceptable workaround — fix soon |
| `P3` | polish, cleanup, or nice-to-have — fix when convenient |

One category per line: pick the dominant one. When an item is security-sensitive
without being primarily a security defect (user impersonation, for example), say
so in its spec rather than double-tagging here.

## TODO (Backlog)

- [ ] [Business][P2] AI receipt scan — support foreign-currency receipts end to end (scan a USD/EUR invoice → foreign expense with base-currency conversion). Multi-currency itself is shipped and verified; this is the remaining AI-scan feature. Spec + open questions: docs/backlog/multi-currency-expenses.md (Follow-up 2). Test kit ready: 6 synthetic receipts + matrix in docs/test-receipts/
- [ ] [Technical][P2] Nothing runs `flutter test` — the suite added in v1.26 (`test/utils/pdf_utils_test.dart`, 6 tests over PDF page counting) only protects when someone runs it by hand, so it will rot silently. Add it to the `finish-feature` checks, and to CI alongside the web build
- [ ] [Technical][P3] block-mode pre-gating on sheet approve/decline CTAs — surface `blockMode` into a provider so the CTA is gated before the call (currently handles the 403 gracefully). See docs/completed/ExpenseSheetsTransformation/03-SheetReview.md
- [ ] [LookAndFeel][P3] add logos to the authorize page
- [ ] [Business][P2] review verbiage on the coupon code on the billing page (both during trial and after trial) — current wording is unclear. Audit + task in docs/backlog/coupon-verbiage-review.md

## report bugs (pending)

- [ ] [Business][P1] Onboarding OTP step -- always-visible Microsoft signup option + slow-delivery warning after 30s (365 mailboxes up to ~3 min) -- see docs/bugs/onboarding-otp-slow-delivery-warning-and-microsoft-fallback.md
- [ ] [Security][P1] Stale data (users list) after switching company -- previous tenant's data leaks into new session -- see docs/bugs/stale-data-after-switching-company.md
- [ ] [Business][P1] Billing -- canceled annual subscription with coupon still shows as "about to renew" -- see docs/bugs/billing-canceled-annual-coupon-shows-about-to-renew.md
- [ ] [Business][P2] Onboarding plan picker -- annual plan missing "2 months free (16% discount)" savings label -- see docs/bugs/onboarding-annual-plan-missing-savings-label.md
- [ ] [LookAndFeel][P2] Billing -- billing screen doesn't refresh after renewing a subscription -- see docs/bugs/billing-no-refresh-after-renewing.md
- [ ] [Business][P2] Login with an unregistered email dead-ends on "check your email" instead of continuing to onboarding with that email pre-filled (needs a backend change; reopens email enumeration) -- see docs/bugs/login-unknown-email-should-continue-to-onboarding.md
- [ ] [Business][P2] Manager Dashboard missing the top analysis widget -- see docs/bugs/manager-dashboard-missing-analysis-widget.md
- [ ] [LookAndFeel][P2] Sheet Review of an approved sheet defaults to the empty Pending tab (should default to Approved) -- see docs/bugs/sheet-review-approved-sheet-defaults-to-empty-pending-tab.md
- [ ] [Business][P3] Out-of-range invoice date only fails at submit (no client-side validation) -- see docs/bugs/invoice-date-out-of-range-client-validation.md
- [ ] [LookAndFeel][P3] Payments "all done" caption is wrong on a fresh all-zeros dashboard (onboarding state) -- see docs/bugs/payments-all-done-caption-wrong-at-onboarding-zero-state.md
- [ ] [LookAndFeel][P3] Dates and amounts follow the UI language, not the company locale -- an Israeli company read in English shows 7/24/2026 instead of 24.7.2026. Root cause is one provider, blast radius is every screen with a date or amount -- see docs/bugs/dates-and-amounts-follow-ui-language-not-company-locale.md
- [ ] [LookAndFeel][P3] "Add employee" multi-add affordance is invisible -- see docs/bugs/add-employee-multi-add-affordance-invisible.md
- [ ] [LookAndFeel][P3] Users module back button looks different from the rest -- see docs/bugs/users-screen-back-button-inconsistent.md
- [ ] [LookAndFeel][P3] Users module looks too dense on mobile -- see docs/bugs/users-screen-mobile-layout-too-dense.md
- [ ] [Technical][P3] AuthService email validation uses regex instead of email_validator package -- see docs/bugs/auth-service-email-regex-violates-validator-rule.md
- [ ] [Technical][P3] flutter analyze reports 9 pre-existing info-level lints (4 dart:html deprecations also block wasm) -- see docs/bugs/flutter-analyze-info-lints-cleanup.md
- [ ] [Technical][P3] Startup frame throws a RenderFlex overflow at a 1x1 viewport -- debug-only console noise on all 17 screens, no user impact; real fix is a shared AppScaffold -- see docs/bugs/startup-frame-renderflex-overflow-at-1x1-viewport.md
- [ ] [Technical][P3] (deferred) Calendar widget is unstable and not cross-browser -- postponed, see docs/bugs/calendar-widget-unstable-cross-browser.md
- [ ] [LookAndFeel][P3] (deferred to v2) Tranzila hosted-fields validation messages are always Hebrew -- fine for the Israel launch, see docs/bugs/tranzila-iframe-validation-language-hebrew-only.md

## general environment

- [ ] [Technical][P1] when an api fails it keeps calling it on a loop - if you get 400/500 - stop with an error.
- [ ] [Business][P2] we need to be able to impersonate a user (security-sensitive: needs an access + audit design before it is built)
- [ ] [LookAndFeel][P2] we need to translate better to hebrew
- [ ] [Business][P3] login with google
- [ ] [Business][P3] we need an admin view to see companies usage
- [ ] [LookAndFeel][P3] Date pickers: first day of week by country (Israel = Sunday, others = Monday) -- post-MVP. See docs/backlog/calendar-week-start-localization-spec.md
- [ ] [Business][P3] preserve protected deep links through login so users who open a report or dashboard URL while logged out land on that exact page after authentication - see docs/backlog/post-login-deep-linking-spec.md

## manager expenses report

- [ ] [Business][P2] build the spend overview widget for manager and employee -- manager card is live; the employee side and the approvals-screen slot are still placeholders. See docs/backlog/spend-overview-spec.md

## management screens

- [ ] [Business][P2] we need to configure which categories are available

## processes & other stuff

- [ ] [Business][P3] spend history - user

## Tranzila support — open questions

- [ ] [Security][P1] **Q2** — `force_txn_on_3ds_fail` security: can this be locked at the terminal level or in the `thtk` issuance so the client-side value cannot be overridden? (Answered questions are recorded in docs/completed/tranzila-card-tokenization.md, not here.)
