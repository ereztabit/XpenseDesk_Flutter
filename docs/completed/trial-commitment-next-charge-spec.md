# Trial Commitment — Next Charge Box

Extends the Current Plan card to handle the case where a user is **still inside the 14-day trial** but has already **committed to a paid plan** (Monthly or Annual) and saved a payment method. The first real charge will fire at trial-end.

This was previously out of scope: the existing trial branch in `_PlanInfoBlock` renders only the "Free Trial – ends … (X days)" line and the optional coupon line, with no upcoming-charge details.

---

## Trigger State

| Field | Value |
|---|---|
| `company.isInTrial` | `true` |
| `billing.subscription` | non-null |
| `subscription.subscriptionStatusName` | `Active` |
| `subscription.planId` | `1` (Annual) or `2` (Monthly) |
| `paymentMethod.lastTransactionDate` | `null` (never charged yet) |

The detection key is `isInTrial && subscription != null && subscription.isActive`.
`lastTransactionDate == null` is informational — it confirms the first charge hasn't fired, but the trial flag is the primary discriminator.

---

## Visual

The card already renders the **Trial badge** (header, right-aligned) and the **Free Trial – ends … (X days)** line (with optional coupon line) inside the existing tinted info box. This step adds a **second tinted box** below that one: the **Next Charge box**.

```
┌─ Current Plan ─────────────────────────────  Trial ──┐
│                                                       │
│  ┌───────────────────────────────────────────────┐   │
│  │ Free Trial - ends May 11, 2026 (14 days)      │   │
│  │ 🏷️ N free month(s) applied until …  (if coupon)│  │
│  └───────────────────────────────────────────────┘   │
│                                                       │
│  ┌───────────────────────────────────────────────┐   │
│  │ Next Charge                                   │   │
│  │ ──────────────────────────────────────────── │   │
│  │ Plan     Monthly Plan / Annual Plan           │   │
│  │ Date     <trialEnd + 1 day>                   │   │
│  │ Amount   $30 / $300                           │   │
│  └───────────────────────────────────────────────┘   │
│                                                       │
└───────────────────────────────────────────────────────┘
```

No action buttons inside the Next Charge box (plan-switching is disabled during trial). No upsell banner, no resume button — those rules from the existing trial branch are unchanged.

---

## Field Mapping

| UI label | Source | Notes |
|---|---|---|
| **Plan** | `subscription.planId` → `l10n.billingPlanMonthly` / `l10n.billingPlanAnnual` | Same `_planDisplayName()` helper already used by `_PlanCard` |
| **Date** | `company.trialEndDate + 1 day` | **NOT** `subscription.endDate`. During trial, `subscription.endDate` represents the end of the *full* paid cycle (e.g. trial start + 1 year for annual), not the first-charge date. |
| **Amount** | `subscription.nextChargeAmount.toSmartCurrency(locale, 'USD')` | Same formatter used elsewhere in the card |

If a coupon is also active (`freeMonthsRemaining > 0`), the date becomes `trialEndDate + freeMonthsRemaining months + 1 day`. Reuse the date math from `_buildCouponLine()` and add a day; or — preferred — push this calculation to the backend and surface a single `firstChargeDate` field on `BillingSubscription` to avoid the client-side month-rollover edge case (Jan 31 + 1 month → Mar 3).

---

## Why `subscription.endDate` is the wrong source

Sample payload from a freshly-committed annual-during-trial:

```json
"subscription": {
  "planId": 1,
  "subscriptionStatusName": "Active",
  "startDate": "2026-05-11T17:37:01.733",
  "endDate":   "2027-05-11T17:37:01.733",
  "nextChargeAmount": 300.00
},
"paymentMethod": {
  "lastTransactionDate": null
}
```

`endDate` is exactly one year after `startDate` (the trial-start moment), not one year after the first charge. Using `endDate` would tell the user "you'll be charged on May 11, 2027" — wrong. The first charge actually happens at trial-end (`company.trialEndDate + 1 day` = May 12, 2026), and `endDate` becomes the *renewal* date after that.

---

## Implementation Steps

### Step 1 — Extract Next Charge into its own widget
- File: `lib/widgets/company_config/billing_current_plan_card.dart`
- New private widget `_NextChargeBox` (StatelessWidget) — own tinted container, "Next Charge" header, divider, three `_InfoRow`s.
- Constructor: `planDisplayName`, `chargeDate`, `chargeAmount`, `locale`, `l10n`, optional `trailingAction` (Widget?) for the existing "Switch to monthly" / "Cancel plan switch" buttons in the active flows.
- Refactor the active-state branch in `_PlanInfoBlock.build` to use `_NextChargeBox` instead of inline `_InfoRow`s. Behavior unchanged for active states.
- Build.

### Step 2 — Render `_NextChargeBox` in the trial branch
- Trial branch in `_PlanInfoBlock.build` ends after `_buildCouponLine()`. Add `_NextChargeBox` directly below it (still inside the same `Column`), gated on `subscription.isActive` (skip if cancelled-during-trial — shouldn't happen but defensive).
- Date computation: `_computeFirstChargeDate(company.trialEndDate, subscription.freeMonthsRemaining)` → trialEnd + N months + 1 day. Put helper at file-private scope.
- Build.

### Step 3 — Visual split into two boxes
- The current `_PlanInfoBlock` is one tinted container holding everything. Decide one of:
  - (a) Keep `_PlanInfoBlock` as the trial/active info box and have `_PlanCard` render `_NextChargeBox` as a sibling below it. Cleaner separation, matches the spec's "four zones" model.
  - (b) Keep both inside `_PlanInfoBlock` with a `SizedBox(height: 12)` between containers. Lower diff.
- Prefer (a). Move the active-state `_NextChargeBox` call out of `_PlanInfoBlock` up to `_PlanCard` so both trial and active states use the same sibling pattern.
- Build.

### Step 4 — l10n
- No new strings expected — `billingNextCharge`, `billingPlanMonthly`, `billingPlanAnnual` already exist. Verify before assuming. If the Next Charge box gets a "Plan" / "Date" / "Amount" row label set, those keys (`billingNextChargePlan`, `billingNextChargeDate`, `billingNextChargeAmount`) need to be added to en + he.
- `flutter pub get` if keys added.

### Step 5 — Manual walkthrough
- Monthly + trial, no commitment yet (subscription == null) → `_NoPlanCard` path, unchanged.
- Monthly + trial, committed → trial info box + Next Charge box ($30, trialEnd+1).
- Annual + trial, committed → trial info box + Next Charge box ($300, trialEnd+1).
- Monthly + trial + coupon → trial info + coupon line + Next Charge box ($30, trialEnd + N months + 1).
- Active monthly / active annual / cancelled / pending switch → unchanged.

---

## Out of Scope

- Backend `firstChargeDate` field — flagged as preferred but not blocking. Filed separately if pursued.
- Date-add safety helper for end-of-month edge cases — addressed only if the backend doesn't take over the calculation.
- Visual restyling of the existing active-state Next Charge rendering beyond the `_NextChargeBox` extraction.
