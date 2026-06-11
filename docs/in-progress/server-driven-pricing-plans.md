# Server-driven pricing plans

> **Status:** Planned — **blocked on server (API is WIP)**.

## Problem

Plan prices are currently hardcoded in client config. The onboarding plan
selection and the billing tab read `AppConfig.instance.monthlyPrice` /
`annualPrice` (from `assets/config/app_config*.yaml` → `billing.monthlyPrice` /
`billing.annualPrice`). Changing a price means shipping a new build per
environment.

Prices (and the plan catalog) should come from the server so pricing can change
without a client release and stay consistent across web/mobile.

## Current state (to be replaced)

- `lib/config/app_config.dart` — `monthlyPrice` / `annualPrice` getters read from
  bundled YAML.
- `lib/screens/onboarding/steps/plan_selection_step.dart` — renders
  `price: '$${config.monthlyPrice}'` / `'$${config.annualPrice}'`.
- `lib/widgets/plan_selection/plan_card.dart` — receives `price` as a string.
- `lib/widgets/company_config/billing_current_plan_card.dart` — billing-tab plan
  display.

## Proposed approach

1. Add a `PricingPlan` model (`lib/models/`) — plan id, name, interval
   (monthly/annual), amount, currency code, trial terms, feature flags.
2. Add a fetch method on `ApiService` and a `pricing_service.dart` /
   `pricing_provider.dart` (`FutureProvider`) to load the plan catalog.
3. Replace the `AppConfig` price getters at the call sites above with the
   provider; keep YAML values only as a last-resort fallback if the API fails.
4. Format amounts via `num.toCurrency(companyLocale, currencyCode)` — drop the
   hardcoded `'$'` prefix in `plan_selection_step.dart`.

## Server dependency / open questions

- API contract is **WIP** — endpoint path, shape, and whether the catalog is
  per-company (currency, locale) or global is TBD.
- Confirm currency: does the server return the amount + ISO currency code so the
  client can format per company locale?
- Confirm whether trial length and coupon eligibility ride on the plan payload.

## Done when

- No plan price is read from `AppConfig` / YAML in the UI.
- Onboarding Step 4 and the billing tab render prices from the server catalog.
- Amounts formatted via `format_utils`, no hardcoded currency symbol.
