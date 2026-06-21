# Bug: Monthly/yearly plan transition shows wrong message, wrong prices, and wrong renewal date

> **Status: done** (Half 1 — prices. Dates deferred to a backend follow-up.)

## Problem

Switching between monthly and yearly billing is broken in two ways:

1. The transition confirmation message is bad and shows the wrong prices.
2. A yearly upgrade reports the wrong next renewal date — it does not credit the
   already-paid period (or the remaining free period), so the new date is
   miscalculated.

## Reproduce Steps

1. Be on a monthly plan (with some paid time and/or a free period remaining).
2. Upgrade to the yearly plan.
   -- Expected: a clear message with correct prices; the new renewal date
      accounts for the already-paid/remaining-free period (proration / credit).
   -- Actual: confusing message with wrong prices; renewal date ignores the
      already-paid or free period.

## Suggested Solution Approach

The transition copy must show the correct amounts, and the renewal date must
factor in any paid-but-unused time and remaining free period.

## Suggested Fix

Needs investigation, with a likely backend component for proration / credited
time. On the client, review the plan-switch confirmation dialog and where the new
renewal date is computed/displayed. Prices and dates use the company-locale
format helpers; strings via ARB. If the renewal-date / proration math is
server-owned, file a matching backend bug.

## Diagnosis

The offender is `lib/widgets/company_config/switch_plan_dialog.dart`. The entire
dialog body is fabricated client-side:

- `_UpgradeContent` (line ~196): `(300.0).toSmartCurrency(locale, 'USD')` —
  hardcoded annual price + hardcoded USD.
- `_DowngradeContent` (line ~258): `(30.0).toSmartCurrency(locale, 'USD')` —
  hardcoded monthly price + hardcoded USD.
- `_UpgradeContent` (line ~194-195): renewal date = `DateTime.now()` + 1 year —
  naive, ignores `subscription.startDate` / `endDate` / `freeMonthsRemaining`.

A second offender: the **upgrade prompt banner** on the Current Plan card
(`billing_current_plan_card.dart`, `_UpgradePromptBanner`) had the prices baked
into the ARB strings themselves — `billingUpgradeTitle` = "Switch to annual and
save $60/year" and `billingUpgradeSubtitle` = "$300/year · Takes effect
immediately" (hardcoded `$60`, `$300`, USD in both en + he). `$60` = monthly x 12
- annual; `$300` = annual price. Fixed by stripping the prices out of the ARB
keys (added `billingUpgradeSave`) and concatenating server-driven amounts in the
widget.

The real data is already on `CompanyInfo` (GET /api/company) and already used
correctly by the plan picker in the sibling `billing_current_plan_card.dart`
(`plans[i].price.toCurrencyWithSymbol(locale, company.currencySymbol)`):
`company.annualPlan?.price`, `company.monthlyPlan?.price`, `company.currencySymbol`.

## Scope (agreed)

Two halves, split by difficulty:

- **Half 1 — prices (this change, client-only):** wire the dialog to
  `companyProvider`; show `annualPlan.price` / `monthlyPlan.price` formatted with
  `currencySymbol`. Removes all hardcoded `300` / `30` / `'USD'`.
- **Half 2 — dates/proration (deferred, backend-dependent):** the "charged today",
  "renews on", and downgrade "effective on" values depend on credit for the
  already-paid period + remaining free months. The client can't compute these
  correctly and there is no pre-confirm preview. Filed as a backend bug for a
  switch-preview that returns projected charge + dates. Until then the upgrade
  renewal date stays naive (today + 1y) with a TODO referencing the backend bug.

## Resolution

Half 1 (prices) shipped on `develop`, verified by the user. Two surfaces fixed,
both now server-driven from `CompanyInfo` (GET /api/company):

- `lib/widgets/company_config/switch_plan_dialog.dart` — the switch confirmation
  dialog. Wired to `companyProvider`; annual/monthly amounts come from
  `company.annualPlan/monthlyPlan.price` formatted with `company.currencySymbol`.
  Removed hardcoded `300.0`, `30.0`, `'USD'`.
- `lib/widgets/company_config/billing_current_plan_card.dart` — the upgrade prompt
  banner. Prices were baked into the ARB strings; stripped them out (repurposed
  `billingUpgradeTitle`/`billingUpgradeSubtitle`, added `billingUpgradeSave`) and
  the banner now concatenates server-driven savings (`monthly x 12 - annual`) and
  annual price.

Verified: no currency symbols or price literals remain in either ARB file
(`app_en.arb` / `app_he.arb`). The only remaining price-derived literal is
`savePercent` ("Save 17%") on the plan-selection cards — left as a deliberate
rounded marketing label (not part of this bug).

Half 2 (charge/date proration) is deferred to the backend switch-preview bug:
`docs/bugs/billing-plan-switch-preview-charge-and-dates.md` in the server repo.

Shipped on `develop` as part of the v1.7 bug batch.

Files: lib/widgets/company_config/switch_plan_dialog.dart,
lib/widgets/company_config/billing_current_plan_card.dart, lib/l10n/app_en.arb,
lib/l10n/app_he.arb.
