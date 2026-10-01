# Admin free plan (design partner)

> Mission: FS-1008 (backend: BackEnd/XpenseDeskServer/docs/admin-panel/admin-free-plan-story.md)

API: [admin-free-plan-api-guide.md](../api-guides/admin-free-plan-api-guide.md).

## Goal

A support agent can put a company on the free plan - full access, no card, no
charge, nothing at Tranzila - and take it off again. The customer on it sees
no payment banner and no free-receipt cap.

## Admin panel

- Company page, Configuration tab: a **Billing** card under Features
  (`AdminFreePlanCard`). One button, whichever applies: **Set free plan**
  (primary) or **Clear free plan** (destructive), each behind a confirm dialog
  (`ConfirmChoiceDialog`). Status line: "On the free plan" / "Not on the free
  plan".
- State comes from the companies overview row (`isFreePlan`); after an action
  the server's answer wins and the overview reloads quietly
  (`AdminCompaniesNotifier.refreshQuietly`, no title flicker).
- Refusals map to their own strings: `AdminFreePlanCompanyPays`,
  `AdminFreePlanAlreadySet`, `AdminFreePlanNotSet`; `AdminCompanyNotFound`
  goes back to the companies list.
- Companies table: a teal **Free plan** status pill (`AdminCompanyDisplayStatus.freePlan`),
  sorted right after Active.

## Customer app

- `CompanyInfo.isFreePlan` from `GET /api/company`.
- Billing banner: none on the free plan, trial or not
  (`resolveBillingBannerType`, extracted to `lib/utils/billing_banner_utils.dart`
  and unit-tested).
- Billing tab: `BillingFreePlanCard` replaces the plan card; the payment-method
  and cancel (danger zone) cards are hidden - nothing at Tranzila backs the plan.
- Free receipts: nothing to change - the server returns `isLimited: false`.

## Tests

`test/utils/billing_banner_utils_test.dart` - no banner on the free plan (after
and during the trial), every other banner unchanged, and the admin row's
display status.
