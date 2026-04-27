# Current Plan Box — Visual & Behavioral Specification

This document describes how the **Current Plan** card in the Billing tab behaves across all subscription states. The card is the top-most element in the Billing tab and adapts its content based on the user's subscription lifecycle.

---

## Card Structure

The Current Plan card contains up to four visual zones, shown or hidden depending on state:

1. **Header row** — Title ("Current Plan") + status badge (right-aligned)
2. **Plan info box** — A compact read-only summary of the current plan or trial
3. **Next Charge box** — Upcoming billing details with inline actions
4. **External actions** — Resume button or annual upsell banner, rendered outside the info boxes but inside the card

---

## Status Badges

The header always shows "Current Plan" on the left. A status badge appears on the right:

| State | Badge Text | Style |
|---|---|---|
| Trial active | Trial | Amber background, amber text, amber border |
| Active subscription | Active | Green background, green text, green border |
| Cancelled subscription | Cancelled | Destructive background/text/border |
| No plan selected | *(no badge)* | — |

---

## State: No Plan Selected

When the user has no active subscription, the plan info box and next charge box are **replaced entirely** by an embedded plan selection widget. This widget allows the user to choose a plan and complete payment inline without leaving the Billing tab.

- The status badge row is hidden.
- The plan selector shows plan cards (Monthly $30, Annual $300), coupon input, and a "Proceed to Payment" button.
- If the user is in a trial, the plan selector displays remaining trial days and a note that the credit card will only be charged when the trial ends.

---

## State: Monthly Plan (Active)

### Plan Info Box
- **Text**: `Monthly Plan - Last charged $30 on [Date]`
- The plan name is bold; the charge detail is in muted text.

### Next Charge Box
- **Header**: "Next Charge" (no action buttons — switch to monthly is irrelevant)
- **Details**:
  - Plan: Monthly Plan
  - Date: [Next billing date]
  - Amount: $30

### External Actions
- **Annual upsell banner**: A highlighted row with a sparkle icon reading "Switch to annual and save $60/year" with subtitle "$300/year - Takes effect immediately". Clickable — opens the Switch Plan dialog.

---

## State: Annual Plan (Active)

### Plan Info Box
- **Text**: `Annual Plan - Last charged $300 on [Date]`

### Next Charge Box
- **Header**: "Next Charge" with a **"Switch to monthly"** button aligned right.
- **Details**:
  - Plan: Annual Plan
  - Date: [Next billing date]
  - Amount: $300

### External Actions
- None (no upsell banner since user is already on the higher-value plan).

---

## State: Cancelled Monthly

### Plan Info Box
- **Text**: `Monthly Plan` (bold, no charge detail)
- **Sub-text**: "Active until [End date]. After that, you will no longer have access." in muted, smaller text.

### Next Charge Box
- Hidden (subscription will not renew).

### External Actions
- **Resume subscription** button, centered, below the plan info box.

---

## State: Cancelled Annual

Identical to Cancelled Monthly, except:
- **Text**: `Annual Plan`
- End date reflects the annual billing cycle.

---

## State: Pending Switch (Annual → Monthly)

The user is on an active annual plan but has scheduled a switch to monthly at the end of the current billing cycle.

### Plan Info Box
- **Text**: `Annual Plan - Last charged $300 on [Date]`

### Next Charge Box
- **Header**: "Next Charge" with a **"Cancel plan switch"** button aligned right (allows undoing the scheduled switch).
- **Details** (reflect the upcoming monthly plan):
  - Plan: Monthly Plan
  - Date: [Annual period end date]
  - Amount: $30

### External Actions
- None.

---

## State: Monthly Plan (In Trial)

The user selected a monthly plan but is still within the 14-day free trial period.

### Plan Info Box
- **Text**: `Free Trial - ends [Trial end date] ([X] days)`
  - "Free Trial" is bold.
  - The date and day count are in amber text.

### Next Charge Box
- **Header**: "Next Charge" (no action buttons — plan switching is disabled during trial)
- **Details**:
  - Plan: Monthly Plan
  - Date: [Day after trial ends]
  - Amount: $30

### External Actions
- No annual upsell banner (plan switching disabled during trial).

---

## State: Monthly Plan (In Trial + Coupon)

The user selected a monthly plan, is in trial, and has applied a coupon code granting free months.

### Plan Info Box
- **Line 1**: `Free Trial - ends [Trial end date] ([X] days)` (same as trial state above)
- **Line 2**: `🏷️ 1 free month(s) applied until [Coupon end date]`
  - Displayed with a Tag icon in green.
  - The coupon end date is calculated as: trial end date + number of free months.

### Next Charge Box
- **Header**: "Next Charge" (no action buttons)
- **Details**:
  - Plan: Monthly Plan
  - Date: [Day after trial + free months end]
  - Amount: $30

### External Actions
- None.

---

## State: No Plan (In Trial)

The user skipped plan selection during onboarding and is using the 14-day trial without choosing a plan.

### Behavior
- Identical to **No Plan Selected** — the plan selector widget is embedded inline.
- The plan selector shows "You have X days left on your trial" and notes that the credit card will only be charged after the trial ends.

---

## Scenario Detection Logic

Each scenario is detected by combining fields from the Company API (`GET /api/company`) and the Billing API (`GET /api/company/billing`).

### Plan IDs

| planId | Name | Price | Cycle |
|--------|------|-------|-------|
| 1 | Annual | $300 | 12 months |
| 2 | Monthly | $30 | 1 month |
| 3 | Free | $0 | 1 month |

### Detection Table

| # | Scenario | Company API | Billing API |
|---|----------|-------------|-------------|
| 1 | No plan | `isInTrial == false` | `subscription == null` |
| 2 | No plan (trial) | `isInTrial == true` | `subscription == null` |
| 3 | Monthly active | `subscriptionStatus == "Active"`, `isInTrial == false` | `planId == 2` |
| 4 | Annual active | `subscriptionStatus == "Active"`, `isInTrial == false` | `planId == 1` |
| 5 | Cancelled monthly | `subscriptionStatus == "Inactive"` | `planId == 2` |
| 6 | Cancelled annual | `subscriptionStatus == "Inactive"` | `planId == 1` |
| 7 | Pending switch | `subscriptionStatus == "Active"` | `planId == 1`, `futurePlan != null` |
| 8 | Monthly in trial | `isInTrial == true` | `planId == 2`, `freeMonthsRemaining == 0` |
| 9 | Monthly trial + coupon | `isInTrial == true` | `planId == 2`, `freeMonthsRemaining > 0` |

### Key data fields used

- **Last charge date**: `billing.paymentMethod.lastTransactionDate` (null for trial/first-time users — hide charge detail when null)
- **Next charge date**: `billing.subscription.endDate`
- **Next charge amount**: `billing.subscription.nextChargeAmount`
- **Trial end date**: `company.trialEndDate`
- **Trial days remaining**: computed from `company.trialEndDate`
- **Coupon end date**: `company.trialEndDate` + `subscription.freeMonthsRemaining` months
- **Subscription start date**: `billing.subscription.startDate`

---

## Summary Table

| State | Badge | Plan Info | Coupon Line | Next Charge | Actions in Next Charge | External Actions |
|---|---|---|---|---|---|---|
| No plan | — | Plan selector widget | — | — | — | — |
| No plan (trial) | — | Plan selector widget (with trial info) | — | — | — | — |
| Monthly | Active | Plan + last charge | — | ✅ | — | Annual upsell banner |
| Annual | Active | Plan + last charge | — | ✅ | Switch to monthly | — |
| Cancelled monthly | Cancelled | Plan + end date warning | — | — | — | Resume subscription |
| Cancelled annual | Cancelled | Plan + end date warning | — | — | — | Resume subscription |
| Pending switch | Active | Plan + last charge | — | ✅ (shows monthly) | Cancel plan switch | — |
| Monthly (trial) | Trial | Free Trial + end date | — | ✅ | — | — |
| Monthly (trial+coupon) | Trial | Free Trial + end date | ✅ with end date | ✅ (date after all free periods) | — | — |

---

## Implementation Steps

### Step 1 — Model: add `startDate` to `BillingSubscription`
- File: `lib/models/company_billing.dart`
- Add `startDate` (DateTime) field + fromJson parsing
- Build

### Step 2 — Add l10n keys for trial/plan info states
- Files: `lib/l10n/app_en.arb`, `lib/l10n/app_he.arb`
- New keys: trial badge, free trial label, "ends" prefix, "days" suffix, "Last charged" prefix, "on" connector, trial note for NoPlanCard, trial charge note
- `flutter pub get` + build

### Step 3 — Pass `CompanyInfo` into `BillingCurrentPlanCard`
- Files: `lib/widgets/company_config/billing_current_plan_card.dart`, `lib/screens/company_config_screen.dart`
- `BillingCurrentPlanCard` needs `CompanyInfo` to detect trial state
- Watch `companyProvider` inside widget or pass from screen
- Propagate to `_PlanCard` and `_NoPlanCard`
- Build

### Step 4 — Add Trial badge + trial Plan Info Box to `_PlanCard`
- File: `lib/widgets/company_config/billing_current_plan_card.dart`
- Add `_TrialBadge` (amber style)
- When `isInTrial == true` and subscription exists: show "Free Trial - ends [date] (X days)" in amber
- When `isInTrial == true` and `freeMonthsRemaining > 0`: show coupon line with tag icon
- When NOT in trial: show "Plan Name - Last charged $X on [Date]" (use `paymentMethod.lastTransactionDate`, hide charge detail when null)
- Build

### Step 5 — Disable trial-restricted actions in `_PlanCard`
- File: `lib/widgets/company_config/billing_current_plan_card.dart`
- When `isInTrial == true`: hide annual upsell banner, hide switch-to-monthly button in next charge header
- Next charge box still shows but with no action buttons
- Build

### Step 6 — Add trial info to `_NoPlanCard`
- File: `lib/widgets/company_config/billing_current_plan_card.dart`
- When `isInTrial == true`: show "You have X days left on your trial" + note about charging after trial ends
- Build

### Step 7 — Switch plan detection from `planName` to `planId`
- File: `lib/widgets/company_config/billing_current_plan_card.dart`
- Replace all `planName.toLowerCase() == 'monthly'` checks with `planId == 2`
- Replace all `planName.toLowerCase() == 'annual'` checks with `planId == 1`
- Build

### Step 8 — Final build + test walkthrough

---

## Behavioral Rules

1. **Trial restrictions**: While in trial, the user cannot switch plans (no "Switch to monthly/annual" buttons) and cannot cancel the plan. They may only cancel the subscription from the Danger Zone section below.
2. **Coupon display**: The coupon line with Tag icon only appears in the trial+coupon combination state. It is not shown for active subscriptions with remaining free months.
3. **Next charge date calculation**: When trial and/or coupon are active, the next charge date accounts for all free periods (trial days + free months) before the first actual billing event.
4. **Resume flow**: The centered "Resume subscription" button appears only for cancelled subscriptions, outside the plan info box for visual hierarchy.
5. **Annual upsell**: The upsell banner only appears for active monthly subscriptions that are not in trial.
