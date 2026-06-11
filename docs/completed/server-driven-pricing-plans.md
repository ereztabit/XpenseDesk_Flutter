# Server-driven pricing plans

> **Status:** SHIPPED & confirmed. Onboarding Step 4 and the billing tab read
> prices from the `plans` array on GET /api/company, render with the company
> `currencySymbol`, subscribe by `billingPlanId`, and refetch the company before
> the onboarding prices screen. Hardcoded AppConfig/YAML prices removed. Plan
> selection/derivation centralized on `CompanyInfo.defaultPlan` / `displayPlans`.

## API contract (delivered — B7)

`GET /api/company` (the profile already loaded after sign-in) now includes a
top-level `plans` array — the purchasable subscription plans with current prices:

```
"plans": [
  { "billingPlanId": 1, "name": "Annual",  "price": 10.00, "billingCycleMonths": 12 },
  { "billingPlanId": 2, "name": "Monthly", "price": 1.00,  "billingCycleMonths": 1 }
]
```

Rules:
- `billingPlanId` is the id used when subscribing/switching (1 = Annual, 2 = Monthly).
- The **Free plan is intentionally absent** — it's an internal trial state, never
  purchasable. Don't render it.
- **No currency field** — IL-only for now; prices are flat shekel amounts. Render
  with the company's existing `currencySymbol` from the same response.
- Comes in the response we already fetch — **no extra API call**.
- Onboarding: ensure the company API is (re)fetched **before** the prices screen
  (Step 4) so plans/prices are present.
- Price changes are backend-only from now on — no app release required.

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
