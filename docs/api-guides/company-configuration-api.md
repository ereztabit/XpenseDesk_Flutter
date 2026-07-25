# Company Configuration - API Specification


This document defines all API endpoints, request/response models, and enums required to support the Company Configuration screen. It covers three tabs: General, Billing, and Billing History (Transactions).

> All endpoints require Authorization: Bearer token and are scoped to the authenticated user's company via the CompanyId claim. Unless noted, only users with RoleId = 1 (Manager) may call these endpoints.

> **Stored procedures:** All database access is implemented via stored procedures. The full SQL definitions live in the **backend** repo, not here: `C:\Projects\XpenseDesk\BackEnd\XpenseDeskServer\docs\company-configuration-stored-procedures.md`.

---

## DB Tables

### Companies (alterations - fields to add)

| Column | Type | Notes |
|--------|------|-------|
| BillingName | nvarchar(200) | Billing contact name or company legal name; nullable |
| TaxId | nvarchar(50) | VAT / tax registration number; nullable |
| BillingAddress | nvarchar(500) | Full billing address; nullable |
| BillingPhone | nvarchar(50) | Billing contact phone; nullable |

---

### BillingPlan

| Column | Type | Notes |
|--------|------|-------|
| BillingPlanId | int | PK, identity |
| Name | nvarchar(100) | e.g., "Monthly", "Annual", "Free" |
| IsActive | bit | Whether the plan is available for selection |
| Price | decimal(10,2) | Price in USD; 0.00 for the Free plan |
| BillingCycleMonths | int | Billing interval - 1 for Monthly/Free, 12 for Annual |

### SubscriptionStatus (lookup)

| SubscriptionStatusId | Name | Description |
|----------------------|------|-------------|
| 1 | Active | Subscription is active and renewing |
| 2 | Expired | Subscription has lapsed and access is no longer granted |
| 3 | CancellationRequest | Cancellation requested; access continues until period end, will not renew |

### PaymentMethodStatus (lookup)

| PaymentMethodStatusId | Name | Description |
|-----------------------|------|-------------|
| 1 | Active | Card is valid |
| 2 | Declined | Last charge was declined / bounced |
| 3 | ExpiringSoon | Card expires within 3 months |
| 4 | Expired | Card expiry date has passed |

### BillingTransactionStatus (lookup)

| BillingTransactionStatusId | Name | Description |
|----------------------------|------|-------------|
| 1 | Paid | Charge succeeded |
| 2 | Failed | Charge failed |
| 3 | Free | No charge applied (free month or promo) |

### SubscriptionChangeLog

Append-only log table - no foreign key constraints.

| Column | Type | Notes |
|--------|------|-------|
| SubscriptionChangeLogId | bigint | PK, identity |
| CompanyId | uniqueidentifier | References Companies.CompanyId (no FK constraint) |
| ChangedByUserId | uniqueidentifier | References Users.UserId - the manager who triggered the action (no FK constraint) |
| Action | nvarchar(50) | "SwitchPlan", "FuturePlanCancelled", "Cancel", "Resume" |
| FromBillingPlanId | int | References BillingPlan.BillingPlanId - the plan before the change; null for Cancel/Resume actions (no FK constraint) |
| ToBillingPlanId | int | References BillingPlan.BillingPlanId - the plan after the change; null for Cancel/Resume actions; populated for SwitchPlan and FuturePlanCancelled (no FK constraint) |
| EffectiveDate | datetime | When the change takes or took effect |
| CreatedAt | datetime | When the action was recorded (UTC) |

### Coupon

| Column | Type | Notes |
|--------|------|-------|
| CouponId | int | PK, identity |
| Code | nvarchar(50) | Unique coupon code entered by the user |
| Target | nvarchar(200) | Internal label describing where the coupon was distributed (e.g., "Facebook Q1 campaign") |
| FreeMonths | int | Number of free months granted when redeemed |
| BillingPlanId | int | FK -> BillingPlan.BillingPlanId - the paid plan that activates after the free period |
| IsActive | bit | Whether the coupon can still be redeemed |
| MaxRedemptions | int | Maximum number of times this coupon can be redeemed; null means unlimited |
| ExpiresAt | datetime | UTC expiry date; null means no expiry |
| CreatedAt | datetime | UTC timestamp of creation |

### CouponRedemption

| Column | Type | Notes |
|--------|------|-------|
| CouponRedemptionId | bigint | PK, identity |
| CouponId | int | FK -> Coupon.CouponId |
| CompanyId | uniqueidentifier | FK -> Companies.CompanyId |
| RedeemedByUserId | uniqueidentifier | FK -> Users.UserId |
| RedeemedAt | datetime | UTC timestamp of redemption |

### PaymentProviderAuditLog

| Column | Type | Notes |
|--------|------|-------|
| PaymentProviderAuditLogId | bigint | PK, identity |
| CompanyId | uniqueidentifier | FK -> Companies.CompanyId |
| CreatedAt | datetime | UTC timestamp of the audit entry |
| PaymentProviderToken | nvarchar(100) | Token returned by the payment provider (transaction_response.token) |
| IsSuccess | bit | Whether the transaction was reported as successful by the provider |
| ErrorCode | nvarchar(50) | Processor response code on failure (transaction_response.processor_response_code); null on success |
| ErrorDescription | nvarchar(500) | Human-readable error message on failure (transaction_response.error); null on success |
| RawResponse | nvarchar(max) | Full JSON response from the payment provider |

---

## Table of Contents

1. [Response Conventions](#1-response-conventions)
2. [General Tab](#2-general-tab)
2a. [Onboarding - Subscription Setup](#2a-onboarding---subscription-setup) (validate coupon, initiate subscription)
3. [Billing Tab - Billing Overview](#3-billing-tab---billing-overview)
4. [Billing Tab - Billing Information](#4-billing-tab---billing-information)
5. [Billing Tab - Payment Method](#5-billing-tab---payment-method)
6. [Billing Tab - Subscription Actions](#6-billing-tab---subscription-actions) (cancel, resume, move-to-annual, move-to-monthly, cancel future plan, apply coupon)
7. [Billing History Tab](#7-billing-history-tab)
8. [Payment Provider Audit](#8-payment-provider-audit)
9. [Subscription Change Log](#9-subscription-change-log)
10. [Error Codes](#10-error-codes)

---

## 1. Response Conventions

All responses are wrapped in the standard ApiResponse envelope:

```json
{
  "success": true,
  "message": "...",
  "errorCode": null,
  "data": { }
}
```

On error:
```json
{
  "success": false,
  "message": "Human-readable description",
  "errorCode": "SCREAMING_SNAKE_CASE_CODE",
  "data": null
}
```

**HTTP status codes used:**

| Code | Meaning |
|------|---------|
| 200 | Success |
| 400 | Validation / bad input |
| 401 | Unauthenticated |
| 403 | Insufficient role (non-Manager) |
| 404 | Resource not found |
| 409 | Business rule conflict |
| 500 | Server error |

---

## 2. General Tab

### GET /api/company/general

> Actual route: `GET /api/company`. Returns the current general settings for the company. Called on every app load — the UI uses `subscriptionStatus` to decide which screens to show before any other API calls are made.

**Stored procedure:** `proc_GetCompanyFullDetails` (uses `dbo.fn_GetSubscriptionStatus` UDF for the status field)

**Response data:**

```json
{
  "companyId": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
  "companyName": "Acme Ltd",
  "companyStatus": "Active",
  "createdAt": "2026-01-15T10:00:00Z",
  "cutoverDay": 1,
  "accountantEmail": "accounts@acme.com",
  "countryCode": "IL",
  "countryName": "Israel",
  "currencyCode": "ILS",
  "currencyName": "Israeli Shekel",
  "currencySymbol": "₪",
  "languageId": 2,
  "languageCode": "he",
  "languageName": "Hebrew",
  "timeZoneId": 64,
  "timeZoneName": "Israel Standard Time",
  "timeZoneDisplayName": "Israel Standard Time (GMT +02:00)",
  "subscriptionStatus": "PendingPayment"
}
```

**`subscriptionStatus` — SubscriptionState enum (serialized as string)**

| Value | Meaning | UI behaviour |
|-------|---------|--------------|
| `PendingPayment` | Company has never completed subscription setup. No subscription row exists yet. | Redirect to the subscription setup flow (see Section 2a). Block all features that require an active subscription. |
| `Active` | Subscription is active and the current billing period has not expired. | Normal app access. |
| `Inactive` | Subscription exists but is cancelled, lapsed, or expired. | Show reactivation prompt. Features that require an active subscription should be blocked or shown in read-only mode. |

**Logic (backed by `dbo.fn_GetSubscriptionStatus`):**
- No `CompanySubscription` row → `PendingPayment`
- `SubscriptionStatusId = 1` (Active) **and** `EndDate >= NOW` → `Active`
- Everything else → `Inactive`

> **Client implementation note:** Check `subscriptionStatus` on every app load (the value is included in `GET /api/company`). If the value is `PendingPayment`, the user has not yet set up their subscription - redirect them to the subscription setup flow described in Section 2a below before they can access any other features.

**Stored procedure:** `proc_GetCompanyFullDetails`

---

### PUT /api/company/general

Updates the General tab fields: company name, currency, and cycle day.

**Authorization:** Manager only (RoleId = 1)

**Request body:**

```json
{
  "companyName": "Acme Ltd",
  "currencyCode": "ILS",
  "cutoverDay": 1
}
```

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| companyName | string | Yes | Max 100 chars |
| currencyCode | string | Yes | One of: ILS, USD, EUR |
| cutoverDay | int | Yes | One of: 1, 2, 10, 15 |

**Stored procedure:** `proc_UpdateCompanyConfiguration` (existing — updates CompanyName only; CurrencyCode and CutoverDay are read-only)

**Response data:** null

**Success response (200):**
```json
{
  "success": true,
  "message": "Changes saved successfully",
  "errorCode": null,
  "data": null
}
```

---

## 2a. Onboarding - Subscription Setup

This section covers the one-time subscription setup flow. It applies only when `subscriptionStatus` is `PendingPayment`. Once the company has an active subscription, use the endpoints in Section 6 for plan changes.

### Flow overview

1. *(Optional)* Client calls `GET /api/onboarding/coupon/validate?code=...` to validate a coupon code before showing the subscription form.
2. Client renders the Tranzila payment iframe to tokenize the card.
3. Client calls `POST /api/company/payment-provider/audit` with the raw Tranzila response (always, success or failure).
4. If tokenization succeeded, client calls `POST /api/onboarding/subscription` with the Tranzila response, selected plan, and optional coupon code.

---

### GET /api/onboarding/coupon/validate

Validates a coupon code for the authenticated company without applying it. Runs all the same checks as `proc_ApplyCoupon`: the coupon must exist, be active, not be expired, not have reached its redemption limit, and not have been redeemed by this company before.

**Authorization:** Manager only (RoleId = 1)

**Query parameters:**

| Parameter | Type | Required | Notes |
|-----------|------|----------|-------|
| code | string | Yes | Case-insensitive coupon code |

**Response data:**

```json
{
  "success": true,
  "message": "Coupon is valid",
  "errorCode": null,
  "data": {
    "isValid": true
  }
}
```

If the coupon is invalid (not found, inactive, expired, limit reached, or already redeemed):

```json
{
  "success": true,
  "message": "Coupon is not valid",
  "errorCode": null,
  "data": {
    "isValid": false
  }
}
```

> **Note:** This endpoint always returns HTTP 200. The `isValid` field in `data` carries the result. No specific failure reason is exposed — this is intentional to prevent coupon enumeration.

| Field | Type | Nullable | Notes |
|-------|------|----------|-------|
| isValid | bool | No | `true` if the coupon can be redeemed by this company right now |

---

### POST /api/onboarding/subscription

Completes the initial subscription setup in a single call: saves the payment card, creates the subscription, and optionally applies a coupon for a free introductory period.

**Authorization:** Manager only (RoleId = 1)

**Stored procedures:** `proc_SaveCompanyPaymentMethod` + `proc_InitiateSubscription` + *(optionally)* `proc_ApplyCoupon` + *(if paid and no coupon)* `proc_InsertBillingTransaction`

**Request body:**

```json
{
  "paymentProviderResponse": {
    "errors": null,
    "transaction_response": {
      "success": true,
      "error": null,
      "processor_response_code": "000",
      "credit_card_last_4_digits": "4242",
      "expiry_month": "12",
      "expiry_year": "30",
      "card_type_name": "Visa",
      "token": "yb8255f45728df51369"
    }
  },
  "billingPlanId": 2,
  "couponCode": "1MONTHOFF"
}
```

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| paymentProviderResponse | object | Yes | Full raw Tranzila response - same shape as `POST /api/company/payment-provider/audit` |
| billingPlanId | int | Yes | ID of the billing plan to subscribe to (from reference data) |
| couponCode | string | No | If provided, applied immediately after subscription is created |

**Behaviour:**

- The card is saved regardless of whether a coupon is provided.
- If no coupon: the plan is activated immediately. For paid plans the card is charged at once.
- If a coupon is provided: the current plan is switched to Free for the coupon's free period, and the selected paid plan is scheduled as a future plan. No charge is made during the free period.

**Response data:** null

**Success response (200):**
```json
{
  "success": true,
  "message": "Subscription initiated successfully",
  "errorCode": null,
  "data": null
}
```

**Error cases:**

| HTTP | Error Code | Condition |
|------|------------|-----------|
| 400 | PAYMENT_METHOD_INVALID_TOKEN | Tranzila tokenization failed or token is missing |
| 400 | PAYMENT_METHOD_INVALID_EXPIRY | Card expiry is in the past |
| 409 | COUPON_FAILED_TO_APPLY | Coupon code is invalid, expired, already redeemed, or redemption limit reached |
| 502 | PAYMENT_METHOD_CHARGE_FAILED | Card charge failed - data contains declineReason and paymentProviderErrorCode |

---

## 3. Billing Tab - Billing Overview

### GET /api/company/billing

Returns all data needed to render the Billing tab: the current subscription state, payment method, and billing information summary.

**Authorization:** Manager only

**Stored procedure:** `proc_GetCompanyBilling` (returns 3 result sets: subscription, payment method, billing info)

**Response data:** CompanyBillingResponse

```json
{
  "subscription": {
    "planId": 1,
    "planName": "Annual",
    "subscriptionStatusId": 1,
    "subscriptionStatusName": "Active",
    "endDate": "2026-04-30T00:00:00Z",
    "nextChargeAmount": 300.00,
    "freeMonthsRemaining": 0,
    "futurePlan": {
      "planId": 2,
      "planName": "Monthly",
      "startDate": "2026-04-30T00:00:00Z",
      "chargeAmount": 30.00
    }
  },
  "paymentMethod": {
    "brand": "Visa",
    "lastFourDigits": "4242",
    "expiryMonth": 5,
    "expiryYear": 2026,
    "paymentMethodStatusId": 2,
    "paymentMethodStatusName": "Declined",
    "lastTransactionDate": "2026-03-01T00:00:00Z",
    "lastBillingTransactionStatusId": 2,
    "declineReason": "Card is blocked",
    "paymentProviderErrorCode": "004"
  },
  "billingInfo": {
    "billingName": "Acme Ltd",
    "taxId": "123456789",
    "countryCode": "IL",
    "countryName": "Israel",
    "address": "123 Main St, Tel Aviv",
    "phone": "+972-50-0000000",
    "accountantEmail": "finance@acme.com"
  }
}
```

#### SubscriptionResponse (nested)

| Field | Type | Nullable | Notes |
|-------|------|----------|-------|
| planId | int | No | FK -> Plans.PlanId - the current active plan |
| planName | string | No | e.g., "Monthly", "Annual" |
| subscriptionStatusId | int | No | FK -> SubscriptionStatuses |
| subscriptionStatusName | string | No | "Active", "Expired", or "CancellationRequest" |
| endDate | datetime | No | End date of the current billing period |
| nextChargeAmount | decimal | No | Charge amount in USD if the current plan renews |
| freeMonthsRemaining | int | No | Number of free months still applied; 0 when no promo active |
| futurePlan | object | Yes | Populated when a plan switch is scheduled; null otherwise |
| futurePlan.planId | int | Yes | FK -> Plans.PlanId |
| futurePlan.planName | string | Yes | e.g., "Monthly", "Annual" |
| futurePlan.startDate | datetime | Yes | Date the future plan takes effect (equals current plan endDate) |
| futurePlan.chargeAmount | decimal | Yes | Amount in USD that will be charged when the future plan starts |

#### PaymentMethodResponse (nested)

| Field | Type | Nullable | Notes |
|-------|------|----------|-------|
| brand | string | No | e.g., "Visa", "Mastercard" |
| lastFourDigits | string | No | e.g., "4242" |
| expiryMonth | int | No | 1 to 12 |
| expiryYear | int | No | Four-digit year |
| paymentMethodStatusId | int | No | FK -> PaymentMethodStatuses |
| paymentMethodStatusName | string | No | "Active", "Declined", "ExpiringSoon", or "Expired" |
| lastTransactionDate | datetime | Yes | Date of the most recent charge attempt |
| lastBillingTransactionStatusId | int | Yes | FK -> BillingTransactionStatuses - status of the last charge attempt |
| declineReason | string | Yes | Populated when paymentMethodStatusId is Declined; e.g., "Card is blocked" |
| paymentProviderErrorCode | string | Yes | Populated when paymentMethodStatusId is Declined; processor_response_code from Tranzila; e.g., "004" |

#### BillingInfoResponse (nested)

| Field | Type | Nullable | Notes |
|-------|------|----------|-------|
| billingName | string | No | |
| taxId | string | No | |
| countryCode | string | Yes | ISO 3166-1 alpha-2 |
| countryName | string | Yes | |
| address | string | Yes | |
| phone | string | Yes | |
| accountantEmail | string | Yes | |

---

## 4. Billing Tab - Billing Information

### PUT /api/company/billing/info

Saves the expanded Billing Information form (collapsible section in the Billing tab).

**Authorization:** Manager only

**Stored procedure:** `proc_UpdateCompanyBillingInfo`

**Request body:**

```json
{
  "billingName": "Acme Ltd",
  "taxId": "123456789",
  "countryCode": "IL",
  "address": "123 Main St, Tel Aviv",
  "phone": "+972-50-0000000",
  "accountantEmail": "finance@acme.com"
}
```

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| billingName | string | Yes | |
| taxId | string | Yes | |
| countryCode | string | No | ISO 3166-1 alpha-2 |
| address | string | No | |
| phone | string | No | |
| accountantEmail | string | No | Must be valid email format if provided |

**Response data:** null

**Success response (200):**
```json
{
  "success": true,
  "message": "Changes saved successfully",
  "errorCode": null,
  "data": null
}
```

---

## 5. Billing Tab - Payment Method

Payment method updates flow through Tranzila tokenization. The client uses the existing handshake token to collect card details directly with Tranzila, then submits the full response to our backend.

### GET /api/company/payment-setup

> Existing endpoint. Returns a Tranzila handshake token for the client to initiate the card tokenization iframe/form. Used as the first step before updating a card.

**Stored procedure:** none (calls Tranzila API directly)

---

### POST /api/company/payment-method

Saves a new payment method after the client has completed Tranzila tokenization.

**Authorization:** Manager only

**Stored procedure:** `proc_SaveCompanyPaymentMethod`

**Request body:**

The full Tranzila response object is passed as-is from the client. The backend extracts the relevant fields and applies the business rules.

```json
{
  "paymentProviderResponse": {
    "errors": null,
    "transaction_response": {
      "success": true,
      "error": null,
      "processor_response_code": "000",
      "transaction_id": "7399",
      "auth_number": "0680264",
      "amount": "10",
      "currency_code": 1,
      "credit_card_last_4_digits": "1369",
      "expiry_month": "12",
      "expiry_year": "30",
      "card_type": "2",
      "card_mask": "458028******1369",
      "card_locality": "domestic",
      "txn_type": "verify",
      "tranmode": "V",
      "card_type_name": "Visa",
      "cvv_status": "1",
      "id_status": "0",
      "token": "yb8255f45728df51369",
      "payment_plan": 1
    }
  }
}
```

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| paymentProviderResponse | object | Yes | The raw response object returned by Tranzila after card tokenization |

**Backend extraction logic:**

| Source field | Extracted to | Notes |
|---|---|---|
| transaction_response.token | stored token | Only persist when success: true |
| transaction_response.card_type_name | card brand | e.g., "Visa", "Mastercard" |
| transaction_response.credit_card_last_4_digits | last four digits | |
| transaction_response.expiry_month | expiry month | String, parsed to int |
| transaction_response.expiry_year | expiry year | Two-digit string, stored as-is or converted to 4-digit |
| transaction_response.processor_response_code | decline check | "000" = approved; any other value = declined |

> **Important:** On a failed transaction Tranzila still returns a token - do not store it. Only persist the token when transaction_response.success = true and processor_response_code = "000".

**Response data:** null

**Success response (200):**
```json
{
  "success": true,
  "message": "Changes saved successfully",
  "errorCode": null,
  "data": null
}
```

**Error cases:**

| HTTP | Error Code | Condition |
|------|------------|-----------|
| 400 | PAYMENT_METHOD_INVALID_TOKEN | Tranzila token rejected or expired |
| 400 | PAYMENT_METHOD_INVALID_EXPIRY | Expiry month/year combination is in the past |

---

## 6. Billing Tab - Subscription Actions

### POST /api/company/subscription/cancel

Cancels the active subscription. Access continues until the end of the current billing period; the subscription will not renew.

**Authorization:** Manager only

**Stored procedures:** `proc_CancelSubscription` → `proc_GetCompanyBilling` (for response)

**Request body:** none

**Response data:** SubscriptionResponse - same shape as the subscription object in GET /api/company/billing

**Success response (200):**
```json
{
  "success": true,
  "message": "Subscription cancelled",
  "errorCode": null,
  "data": {
    "planId": 1,
    "planName": "Annual",
    "subscriptionStatusId": 3,
    "subscriptionStatusName": "CancellationRequest",
    "endDate": "2026-04-30T00:00:00Z",
    "nextChargeAmount": 300.00,
    "freeMonthsRemaining": 0,
    "futurePlan": null
  }
}
```

**Error cases:**

| HTTP | Error Code | Condition |
|------|------------|-----------|
| 409 | SUBSCRIPTION_ALREADY_CANCELLED | Subscription is already in cancelled state |

---

### POST /api/company/subscription/resume

Resumes a previously cancelled subscription.

**Stored procedures:** `proc_ValidateResumeSubscription` → *(Tranzila charge if required)* → `proc_CommitResumeSubscription` → `proc_GetCompanyBilling` (for response)

- If the subscription end date is today or in the future: reactivates without an immediate charge.
- If the subscription end date is in the past: reactivates and triggers an immediate charge.

**Authorization:** Manager only

**Request body:** none

**Response data:** SubscriptionResponse - same shape as the subscription object in GET /api/company/billing

**Success response (200):**
```json
{
  "success": true,
  "message": "Subscription reactivated",
  "errorCode": null,
  "data": {
    "planId": 2,
    "planName": "Monthly",
    "subscriptionStatusId": 1,
    "subscriptionStatusName": "Active",
    "endDate": "2026-04-30T00:00:00Z",
    "nextChargeAmount": 30.00,
    "freeMonthsRemaining": 0,
    "futurePlan": null
  }
}
```

**Error cases:**

| HTTP | Error Code | Condition |
|------|------------|-----------|
| 409 | SUBSCRIPTION_ALREADY_ACTIVE | Subscription is not in cancelled state |
| 502 | SUBSCRIPTION_RESUME_PAYMENT_FAILED | Immediate charge attempt failed - data contains declineReason |

When `SUBSCRIPTION_RESUME_PAYMENT_FAILED` is returned, the response `data` contains:
```json
{
  "success": false,
  "message": "Payment failed",
  "errorCode": "SUBSCRIPTION_RESUME_PAYMENT_FAILED",
  "data": {
    "declineReason": "Card is blocked",
    "paymentProviderErrorCode": "004"
  }
}
```

| Field | Source |
|-------|--------|
| declineReason | transaction_response.error |
| paymentProviderErrorCode | transaction_response.processor_response_code |

---

### POST /api/company/subscription/move-to-annual

Upgrades the subscription from Monthly to Annual. Charged immediately; annual plan starts today.

**Authorization:** Manager only

**Stored procedures:** `proc_ValidateMoveToAnnual` → *(Tranzila charge)* → `proc_CommitMoveToAnnual` → `proc_GetCompanyBilling` (for response)

**Request body:** none

**Response data:** SubscriptionResponse - same shape as the subscription object in GET /api/company/billing

**Success response (200):**
```json
{
  "success": true,
  "message": "Plan switched to Annual",
  "errorCode": null,
  "data": {
    "planId": 1,
    "planName": "Annual",
    "subscriptionStatusId": 1,
    "subscriptionStatusName": "Active",
    "endDate": "2027-03-30T00:00:00Z",
    "nextChargeAmount": 300.00,
    "freeMonthsRemaining": 0,
    "futurePlan": null
  }
}
```

**Error cases:**

| HTTP | Error Code | Condition |
|------|------------|-----------|
| 409 | SUBSCRIPTION_ALREADY_ANNUAL | Subscription is already on the Annual plan |
| 409 | SUBSCRIPTION_CANCELLED | Cannot switch plan on a cancelled subscription |
| 409 | SUBSCRIPTION_PENDING_SWITCH_EXISTS | A future plan change is already scheduled; cancel it first before making a new change |
| 502 | SUBSCRIPTION_SWITCH_PAYMENT_FAILED | Immediate charge failed - data contains declineReason and paymentProviderErrorCode |

When `SUBSCRIPTION_SWITCH_PAYMENT_FAILED` is returned:
```json
{
  "success": false,
  "message": "Payment failed",
  "errorCode": "SUBSCRIPTION_SWITCH_PAYMENT_FAILED",
  "data": {
    "declineReason": "Card is blocked",
    "paymentProviderErrorCode": "004"
  }
}
```

---

### POST /api/company/subscription/move-to-monthly

Downgrades the subscription from Annual to Monthly. No immediate charge; monthly billing begins on the next renewal date. A future plan entry is created.

**Authorization:** Manager only

**Stored procedures:** `proc_MoveSubscriptionToMonthly` → `proc_GetCompanyBilling` (for response)

**Request body:** none

**Response data:** SubscriptionResponse - same shape as the subscription object in GET /api/company/billing

**Success response (200):**
```json
{
  "success": true,
  "message": "Plan switch to Monthly scheduled",
  "errorCode": null,
  "data": {
    "planId": 1,
    "planName": "Annual",
    "subscriptionStatusId": 1,
    "subscriptionStatusName": "Active",
    "endDate": "2026-04-30T00:00:00Z",
    "nextChargeAmount": 300.00,
    "freeMonthsRemaining": 0,
    "futurePlan": {
      "planId": 2,
      "planName": "Monthly",
      "startDate": "2026-04-30T00:00:00Z",
      "chargeAmount": 30.00
    }
  }
}
```

**Error cases:**

| HTTP | Error Code | Condition |
|------|------------|-----------|
| 409 | SUBSCRIPTION_ALREADY_MONTHLY | Subscription is already on the Monthly plan |
| 409 | SUBSCRIPTION_CANCELLED | Cannot switch plan on a cancelled subscription |
| 409 | SUBSCRIPTION_PENDING_SWITCH_EXISTS | A future plan change is already scheduled; cancel it first before making a new change |

---

### DELETE /api/company/subscription/future-plan

Cancels a previously scheduled future plan (downgrade only). The current plan continues as-is with no changes.

**Authorization:** Manager only

**Stored procedures:** `proc_CancelFuturePlan` → `proc_GetCompanyBilling` (for response)

**Request body:** none

**Response data:** SubscriptionResponse - same shape as the subscription object in GET /api/company/billing

**Success response (200):**
```json
{
  "success": true,
  "message": "Scheduled change cancelled",
  "errorCode": null,
  "data": {
    "planId": 1,
    "planName": "Annual",
    "subscriptionStatusId": 1,
    "subscriptionStatusName": "Active",
    "endDate": "2026-04-30T00:00:00Z",
    "nextChargeAmount": 300.00,
    "freeMonthsRemaining": 0,
    "futurePlan": null
  }
}
```

**Error cases:**

| HTTP | Error Code | Condition |
|------|------------|-----------|
| 404 | SUBSCRIPTION_NO_FUTURE_PLAN | No future plan exists to cancel |
| 409 | FUTURE_PLAN_NOT_CANCELLABLE | Current plan is Free (coupon period); the future plan is required and cannot be removed |

---

## 7. Billing History Tab

### GET /api/company/billing/transactions

Returns the list of billing transactions for the company, ordered by date descending.

**Authorization:** Manager only

**Stored procedure:** `proc_GetBillingTransactions`

**Query parameters:** none (no pagination in v1)

**Response data:** BillingTransactionListResponse

```json
{
  "transactions": [
    {
      "transactionId": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
      "date": "2026-03-01T00:00:00Z",
      "amount": 30.00,
      "billingTransactionStatusId": 1,
      "billingTransactionStatusName": "Paid",
      "description": "Monthly Plan - March 2026",
      "invoiceUrl": "https://invoices.example.com/inv_abc123.pdf"
    },
    {
      "transactionId": "4ab96e75-6828-5673-c4gd-3d074g77bgb7",
      "date": "2026-02-01T00:00:00Z",
      "amount": 0.00,
      "billingTransactionStatusId": 2,
      "billingTransactionStatusName": "Failed",
      "description": "Monthly Plan - February 2026",
      "invoiceUrl": null
    }
  ]
}
```

#### BillingTransactionItem

| Field | Type | Nullable | Notes |
|-------|------|----------|-------|
| transactionId | Guid | No | |
| date | datetime | No | UTC timestamp of the transaction |
| amount | decimal | No | Always in USD |
| billingTransactionStatusId | int | No | FK -> BillingTransactionStatuses |
| billingTransactionStatusName | string | No | "Paid", "Failed", or "Free" |
| description | string | No | Human-readable description, e.g., "Monthly Plan - March 2026" |
| invoiceUrl | string | Yes | Download URL; null when no invoice exists |

---

## 8. Payment Provider Audit

### POST /api/company/payment-provider/audit

Logs the raw payment provider response for every interaction - success or failure. Called by the client immediately after receiving any response from Tranzila, before any other action.

**Authorization:** Manager only

**Stored procedure:** `proc_LogPaymentProviderAudit`

**Request body:**

```json
{
  "paymentProviderToken": "yb8255f45728df51369",
  "paymentProviderResponse": { }
}
```

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| paymentProviderToken | string | Yes | transaction_response.token from the Tranzila response |
| paymentProviderResponse | object | Yes | The full raw Tranzila response object |

**Response data:** null

**Success response (200):**
```json
{
  "success": true,
  "message": "Audit logged",
  "errorCode": null,
  "data": null
}
```

---

## 9. Subscription Change Log

### GET /api/company/subscription/change-log

Returns the full subscription change history for the company, ordered by CreatedAt descending. Intended for debugging and testing.

**Authorization:** Manager only

**Stored procedure:** `proc_GetSubscriptionChangeLog`

**Query parameters:** none

**Response data:** SubscriptionChangeLogResponse

```json
{
  "changes": [
    {
      "changeId": 3,
      "changedByUserId": "a1b2c3d4-...",
      "changedByUserName": "John Smith",
      "action": "SwitchPlan",
      "fromPlanId": 1,
      "fromPlanName": "Annual",
      "toPlanId": 2,
      "toPlanName": "Monthly",
      "effectiveDate": "2026-04-30T00:00:00Z",
      "createdAt": "2026-03-30T10:00:00Z"
    },
    {
      "changeId": 2,
      "changedByUserId": "a1b2c3d4-...",
      "changedByUserName": "John Smith",
      "action": "FuturePlanCancelled",
      "fromPlanId": null,
      "fromPlanName": null,
      "toPlanId": 2,
      "toPlanName": "Monthly",
      "effectiveDate": "2026-04-30T00:00:00Z",
      "createdAt": "2026-03-28T09:00:00Z"
    },
    {
      "changeId": 1,
      "changedByUserId": "a1b2c3d4-...",
      "changedByUserName": "John Smith",
      "action": "SwitchPlan",
      "fromPlanId": 2,
      "fromPlanName": "Monthly",
      "toPlanId": 1,
      "toPlanName": "Annual",
      "effectiveDate": "2026-03-01T00:00:00Z",
      "createdAt": "2026-03-01T08:00:00Z"
    }
  ]
}
```

| Field | Type | Nullable | Notes |
|-------|------|----------|-------|
| changeId | bigint | No | |
| changedByUserId | Guid | No | |
| changedByUserName | string | No | Full name of the manager who made the change |
| action | string | No | "SwitchPlan", "FuturePlanCancelled", "Cancel", "Resume" |
| fromPlanId | int | Yes | FK -> Plans.PlanId - null for Cancel/Resume/FuturePlanCancelled actions |
| fromPlanName | string | Yes | e.g., "Monthly", "Annual" - null for Cancel/Resume/FuturePlanCancelled actions |
| toPlanId | int | Yes | FK -> Plans.PlanId - null for Cancel/Resume actions; populated for SwitchPlan and FuturePlanCancelled |
| toPlanName | string | Yes | e.g., "Monthly", "Annual" - null for Cancel/Resume actions; populated for SwitchPlan and FuturePlanCancelled |
| effectiveDate | datetime | No | When the change takes or took effect |
| createdAt | datetime | No | When the action was recorded (UTC) |

---

## 10. Error Codes

All error codes follow SCREAMING_SNAKE_CASE convention and are returned in the errorCode field of ApiResponse.

| Error Code | HTTP | Description |
|------------|------|-------------|
| PAYMENT_METHOD_INVALID_TOKEN | 400 | Tranzila tokenization token is invalid or expired |
| PAYMENT_METHOD_INVALID_EXPIRY | 400 | Card expiry month/year is in the past |
| SUBSCRIPTION_ALREADY_CANCELLED | 409 | Cancel requested on already-cancelled subscription |
| SUBSCRIPTION_ALREADY_ACTIVE | 409 | Resume requested on a non-cancelled subscription |
| SUBSCRIPTION_ALREADY_ANNUAL | 409 | Move-to-annual requested but subscription is already Annual |
| SUBSCRIPTION_ALREADY_MONTHLY | 409 | Move-to-monthly requested but subscription is already Monthly |
| SUBSCRIPTION_CANCELLED | 409 | Plan switch attempted on a cancelled subscription |
| SUBSCRIPTION_PENDING_SWITCH_EXISTS | 409 | A future plan change is already scheduled; cancel it first before making a new change |
| SUBSCRIPTION_NO_FUTURE_PLAN | 404 | Delete future-plan called when none exists |
| SUBSCRIPTION_RESUME_PAYMENT_FAILED | 502 | Payment gateway declined the charge during resume; data.declineReason contains the reason |
| SUBSCRIPTION_SWITCH_PAYMENT_FAILED | 502 | Payment gateway declined the charge during upgrade; data.declineReason and data.paymentProviderErrorCode contain the details |
| COUPON_FAILED_TO_APPLY | 409 | Catch-all for any coupon validation failure; specific reason is intentionally not exposed |
| FUTURE_PLAN_NOT_CANCELLABLE | 409 | Future plan cannot be removed while the company is on the Free plan (coupon period) |
