# Billing Feature — Bug List

Bugs to fix before the billing feature is complete.

---

## API Context — Company Endpoint Fields

The `/api/company` response now includes these subscription fields:

```json
{
  "subscriptionStatus": "PendingPayment",
  "blockMode": "None",
  "trialEndDate": "2026-04-20T07:15:39.84",
  "isInTrial": true,
  "hasCardOnFile": false
}
```

### Subscription statuses

| Value | Description |
|-------|-------------|
| `PendingPayment` | Signed up but never completed payment — in trial |
| `Active` | Subscription is active and renewing |
| `Inactive` | Subscription has lapsed, access no longer granted |
| `Expired` | Legacy value — treated same as Inactive |
| `CancellationRequest` | Cancellation requested; access continues until period end, won't renew |

### New fields

| Field | Type | Description |
|-------|------|-------------|
| `trialEndDate` | datetime | When the trial period ends (every company gets a trial — currently 14 days, configurable server-side) |
| `isInTrial` | bool | Company is currently in trial mode |
| `hasCardOnFile` | bool | A credit card has been saved for this company |
| `blockMode` | string | Out of scope for now — future feature |

### Banner state derivation from API fields

| Banner State | Condition |
|-------------|-----------|
| Trial active (amber) | `isInTrial == true` && `trialEndDate` is in the future |
| Trial expired (red) | `isInTrial == true` && `trialEndDate` is in the past |
| Subscription expired (red) | `subscriptionStatus == "Expired"` |
| Cancellation pending (amber?) | `subscriptionStatus == "CancellationRequest"` (TBD — not in banner spec yet) |
| No banner | `subscriptionStatus == "Active"` && not in trial |

### Card banner derivation from billing API (`GET /api/company/billing`)

`BillingPaymentMethod.paymentMethodStatusId`:
| Status ID | Name | Banner |
|-----------|------|--------|
| 1 | Active | No card banner |
| 2 | Declined | Card bounced (red) |
| 3 | ExpiringSoon | Card expiring soon (amber) |
| 4 | Expired | Card expired (red) |

Priority within card banners: Declined > Expired > ExpiringSoon.
Card banners only apply when `hasCardOnFile == true`. When `hasCardOnFile == false` (trial/pending payment), `paymentMethod` is `null` in the billing API response — skip card banner logic entirely.

---

## Bug 1: Company Config does not fetch billing data on entry

**Problem:** When navigating to the Company Configuration screen, the billing API is not called. The billing tab shows stale data from whatever was last loaded (or nothing if it's the first visit).

**Expected:** On entering the Company Config screen (or at least when switching to the Billing tab), the app should call the billing API to fetch up-to-date subscription/plan/payment data.

**Where:** `lib/screens/company_config_screen.dart` — `initState` has no billing data fetch. The billing provider likely needs to be invalidated or explicitly refreshed on screen entry.

---

## Bug 2: "Complete subscription" banner button does not navigate to billing tab

**Problem:** Clicking the action button in the amber `PendingPaymentBanner` navigates to `/manager/company-config` with `arguments: {'tab': 'billing'}`, but the screen doesn't land on the billing tab. The user sees the General tab instead.

**Expected:** The banner button should navigate directly to the Billing tab in Company Configuration.

**Where:** `lib/widgets/header/pending_payment_banner.dart` sends `arguments: {'tab': 'billing'}`, but the screen/router is not reading those arguments and converting them to `initialTab: 2` (or whichever index the billing tab is).

---

## Bug 3: Implement billing-alert-banners per spec

**Problem:** The current `PendingPaymentBanner` is a single hardcoded amber banner for the old `PendingPayment` status. It needs to be reworked to use the new API fields and support multiple banner states per the spec (`docs/in-progress/billing-alert-banners-spec.md`).

### What needs to change:

#### Model updates (`lib/models/company_info.dart`)
- Add `trialEndDate` (DateTime?), `isInTrial` (bool), `hasCardOnFile` (bool)
- Add computed getters: `trialDaysRemaining`, `isTrialExpired`
- Keep `subscriptionStatus` — `PendingPayment` is still a valid value from the API

#### All banner states (company API + billing API)

| State | Source | Color | Dismissible | Button | Destination |
|-------|--------|-------|-------------|--------|-------------|
| Trial active | Company: `isInTrial` + `trialEndDate` future | Amber | Yes (session) | "Complete payment" | `/complete-payment` |
| Trial expired | Company: `isInTrial` + `trialEndDate` past | Red | No | "Complete payment" | `/complete-payment` |
| Subscription expired | Company: `subscriptionStatus == "Expired"` | Red | No | "Reactivate" | `/complete-payment` |
| Card declined/bounced | Billing: `paymentMethodStatusId == 2` | Red | No | "Manage payment" | Company config billing tab |
| Card expired | Billing: `paymentMethodStatusId == 4` | Red | No | "Manage payment" | Company config billing tab |
| Card expiring soon | Billing: `paymentMethodStatusId == 3` | Amber | Yes (session) | "Manage payment" | Company config billing tab |

#### Other requirements from spec
- Dismiss `X` button on amber banners (session-only state)
- No dismiss on red banners
- Priority: trial banners and card banners are mutually exclusive (trial = no card on file)
- RTL: use `start`/`end` not `left`/`right`
- Responsive: wrap on narrow viewports

---

## Fix Order

1. **Bug 3 model update** — add new fields to `CompanyInfo` first (unblocks everything)
2. **Bug 1** — billing API fetch on company config entry
3. **Bug 2** — fix banner button navigation to billing tab
4. **Bug 3 banners** — rework `PendingPaymentBanner` to support all Phase 1 states
