# Onboarding & Subscription Setup — Client API Guide (v2)

This document extends the original onboarding guide with the full subscription setup flow.
It covers the new endpoints added for plan selection, Tranzila payment tokenization, coupon validation, and subscription initiation.

> **Prerequisite:** Read `client-onboarding-company-api-guide.md` first for authentication conventions,
> the OTP flow (steps 1–3), and the base `GET /api/company` / `PUT /api/company` endpoints.
> read company-configuration-api.md

---

## Authentication

All protected endpoints require a session token:

```
Authorization: Bearer <session-token>
```

The token is obtained at the end of the OTP flow (`POST /api/onboarding/verify-otp`).

---

## Updated Full Flow Overview

```
--- Company registration (no auth) ---
1. GET  /api/onboarding/reference-data     → populate form dropdowns
2. POST /api/onboarding/company            → submit form, receive OtpKey
3. POST /api/onboarding/verify-otp         → submit OTP, receive SessionToken

--- Session initialization (auth required) ---
4. GET  /api/users/me                      → initialize user session
5. GET  /api/company                       → check subscriptionStatus

    if subscriptionStatus == "Active"      → navigate to dashboard
    if subscriptionStatus == "PendingPayment" → continue to subscription setup ↓

--- Subscription setup (auth required, admin only) ---
6. GET  /api/company/payment-setup         → get Tranzila handshake token (thtk)
7.      [client renders Tranzila iframe with thtk]
8. POST /api/company/payment-provider/audit  → log raw Tranzila response (always, before step 9)
9. POST /api/onboarding/subscription       → save card + plan + optional coupon → done
```

After step 9 succeeds, navigate to the dashboard. `GET /api/company` will now return `subscriptionStatus = "Active"`.

---

## subscriptionStatus — Decision Point

`GET /api/company` returns a `subscriptionStatus` field. Check this on every app launch and after login.

| Value | Meaning | Client action |
|-------|---------|---------------|
| `PendingPayment` | Company registered but no subscription yet. | Show subscription setup flow (steps 6–9). Block all other features. |
| `Active` | Subscription is active and within its billing period. | Normal app access. |
| `Inactive` | Subscription exists but is cancelled, lapsed, or expired. | Show reactivation screen. Block features that require an active subscription. |

> `PendingPayment` is the initial state for every newly registered company.
> It clears to `Active` the moment `POST /api/onboarding/subscription` completes successfully.

Full response shape from `GET /api/company`:

```json
{
  "success": true,
  "message": "Company details retrieved successfully",
  "data": {
    "companyId": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
    "companyName": "Acme Corp",
    "companyStatus": "Active",
    "createdAt": "2026-01-15T10:00:00Z",
    "cutoverDay": 1,
    "accountantEmail": "accountant@acme.com",
    "countryCode": "IL",
    "countryName": "Israel",
    "currencyCode": "ILS",
    "currencyName": "Israeli New Shekel",
    "currencySymbol": "₪",
    "languageId": 2,
    "languageCode": "he",
    "languageName": "Hebrew",
    "timeZoneId": 64,
    "timeZoneName": "Israel Standard Time",
    "timeZoneDisplayName": "Israel Standard Time (GMT +02:00)",
    "subscriptionStatus": "PendingPayment"
  }
}
```

---

## Step 6 — GET /api/company/payment-setup

**Auth:** Required — Admin only (roleId = 1)

**Purpose:** Fetch a Tranzila handshake token (`thtk`). This token authorizes the Tranzila iframe/form to tokenize the card on behalf of this company. Must be called fresh each time the payment screen is shown — tokens expire.

**Request:** No body, no parameters.

**Response:**

```json
{
  "success": true,
  "message": "Handshake token generated successfully",
  "data": {
    "thtk": "a1b2c3d4e5f6..."
  }
}
```

| Field | Notes |
|-------|-------|
| thtk | Pass this to the Tranzila iframe as the `thtk` parameter. Single-use, short TTL. |

**Error responses:**

| HTTP | Meaning |
|------|---------|
| 403 | Non-admin user. Only the company owner/admin can set up billing. |
| 502 | Tranzila API did not return a valid token. Show a retry option. |

---

## Step 7 — Tranzila Iframe Tokenization

The client renders the Tranzila tokenization iframe using the `thtk` from step 6.
Tranzila handles card data directly — the card number never touches our servers.

When tokenization completes (success or failure), Tranzila posts a JSON response back to the client.
The client must:

1. **Always** call `POST /api/company/payment-provider/audit` with the raw response (step 8).
2. If `transaction_response.success = true` and `processor_response_code = "000"` — proceed to step 9.
3. If the response indicates failure — show an error to the user and allow retry (call step 6 again for a fresh `thtk`).

**Tranzila response shape (success):**

```json
{
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
}
```

**Tranzila response shape (failure):**

```json
{
  "errors": null,
  "transaction_response": {
    "success": false,
    "error": "Card is blocked",
    "processor_response_code": "004",
    "token": "yb8255f45728df5xxxx"
  }
}
```

> **Important:** Tranzila returns a token even on failure. Do NOT pass a failed response to `POST /api/onboarding/subscription` — the server will reject it. Only proceed to step 9 when `success = true` and `processor_response_code = "000"`.

---

## Step 8 — POST /api/company/payment-provider/audit

**Auth:** Required — Admin only

**Purpose:** Logs the raw Tranzila response for compliance and debugging. Must be called for every Tranzila interaction — success or failure — before attempting step 9.

**Request body:**

```json
{
  "paymentProviderToken": "yb8255f45728df51369",
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
  }
}
```

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| paymentProviderToken | string | Yes | `transaction_response.token` from the Tranzila response |
| paymentProviderResponse | object | Yes | The full raw Tranzila JSON — pass it as-is, do not transform |

**Response:**

```json
{
  "success": true,
  "message": "Audit logged",
  "errorCode": null,
  "data": null
}
```

This endpoint always returns 200. Do not block the user flow on failure — fire and forget, then continue to step 9.

---

## Step 8a (Optional) — GET /api/onboarding/coupon/validate

**Auth:** Required — Admin only

**Purpose:** Validate a coupon code the user entered before submitting the subscription form. Non-blocking — the user can still submit without a coupon, and the coupon is also validated server-side during step 9.

**Query parameters:**

| Parameter | Type | Required | Notes |
|-----------|------|----------|-------|
| code | string | Yes | The coupon code as typed by the user. Case-insensitive. |

**Example:** `GET /api/onboarding/coupon/validate?code=1MONTHOFF`

**Response (always HTTP 200):**

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

If invalid (not found, inactive, expired, already redeemed, or redemption limit reached):

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

| Field | Notes |
|-------|-------|
| isValid | `true` = coupon is valid and can be used. `false` = coupon cannot be applied. |

> This endpoint always returns HTTP 200 — the result is in `data.isValid`, not the HTTP status code.
> No error reason is exposed by design (prevents coupon enumeration).

**Client implementation note:**
- Show a small inline indicator next to the coupon field after the user stops typing (debounce 500ms).
- `isValid: true` → show a green checkmark + brief description (e.g., "1 free month applied").
- `isValid: false` → show an inline error ("This coupon is not valid").
- Do not block form submission — the server re-validates the coupon during step 9.

---

## Step 9 — POST /api/onboarding/subscription

**Auth:** Required — Admin only

**Purpose:** Completes the subscription setup in a single call. Saves the payment card, creates the subscription for the selected plan, and optionally applies a coupon for a free introductory period. This is the final step — on success, `subscriptionStatus` becomes `Active`.

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
| paymentProviderResponse | object | Yes | The full raw Tranzila response — same object sent to the audit endpoint in step 8 |
| billingPlanId | int | Yes | ID of the plan the user selected. See Billing Plans table below. |
| couponCode | string | No | Omit or pass `null` if no coupon was entered |

**Billing Plans:**

See Section "Billing Plans" below for full plan details and presentation guidance. Pass the `billingPlanId` of the plan the user selected.

**Behaviour by scenario:**

| Scenario | What happens |
|----------|-------------|
| Paid plan, no coupon | Card saved, subscription activated, card charged immediately |
| Paid plan + valid coupon | Card saved, subscription activated in Free mode for coupon duration (e.g., 1 month), paid plan scheduled as future plan, no immediate charge |
| Paid plan + invalid coupon | Returns `COUPON_FAILED_TO_APPLY` (409). Card is NOT saved. Show error, let user retry with or without coupon. |

**Success response (200):**

```json
{
  "success": true,
  "message": "Subscription initiated successfully",
  "errorCode": null,
  "data": null
}
```

After this response, navigate to the dashboard. Call `GET /api/company` to refresh `subscriptionStatus` — it will now be `Active`.

**Error cases:**

| HTTP | Error Code | Meaning | Client action |
|------|------------|---------|---------------|
| 400 | `PAYMENT_METHOD_INVALID_TOKEN` | Tranzila tokenization failed or token was from a declined transaction | Show "Card could not be saved" and re-run steps 6–9 |
| 400 | `PAYMENT_METHOD_INVALID_EXPIRY` | Card expiry date is in the past | Show "Card has expired" on the card form |
| 409 | `COUPON_FAILED_TO_APPLY` | Coupon is no longer valid (expired, redeemed, or limit reached between validation and submit) | Clear the coupon field, show "Coupon could not be applied" |
| 502 | `PAYMENT_METHOD_CHARGE_FAILED` | Card was tokenized but the charge was declined | Show decline reason from `data.declineReason` |

**`PAYMENT_METHOD_CHARGE_FAILED` error data:**

```json
{
  "success": false,
  "message": "Initial subscription payment failed",
  "errorCode": "PAYMENT_METHOD_CHARGE_FAILED",
  "data": {
    "declineReason": "Card is blocked",
    "paymentProviderErrorCode": "004"
  }
}
```

---

## Billing Plans

There are two plans available to users. These are static — no API call is needed to fetch them.

| billingPlanId | Name | Price | Billing cycle | Notes |
|---------------|------|-------|---------------|-------|
| 1 | Annual | $300.00 | Charged once, covers 12 months | Best value — saves $60 vs monthly |
| 2 | Monthly | $30.00 | Charged monthly | Flexible, no long-term commitment |

**Presentation guidance:**

- Present both plans side by side on the plan selection screen.
- Highlight the Annual plan as the recommended option (saves $60/year).
- Show the monthly equivalent for Annual: $25.00/month.
- After the user selects a plan, display a summary before they enter card details:
  - Plan name and price
  - What they will be charged today (or "Free for X month" if a coupon is applied)
  - The next charge date

**With a coupon applied:**

When `isValid: true` from the coupon validation endpoint, the charge summary changes:
- Today's charge: $0.00 (free period)
- Free period: 1 month (duration depends on the coupon — currently 1 month for `1MONTHOFF`)
- After free period: the selected plan resumes at its normal price

> The "Free" plan (ID 3) is internal and used by the coupon system. Never show it as a selectable option.

---

## Coupon UX — What Happens After a Free Period

When a coupon is applied, the subscription enters a free introductory period. After that period ends, the paid plan activates automatically. From the client's perspective:

- `GET /api/company/billing` will show `planName: "Free"`, `freeMonthsRemaining: 1`, and a `futurePlan` object.
- The `futurePlan` shows the paid plan that will activate at `futurePlan.startDate`.
- The future plan created by a coupon **cannot be cancelled** — `DELETE /api/company/subscription/future-plan` will return `FUTURE_PLAN_NOT_CANCELLABLE` (409).

---

## Error Handling Summary

All error responses follow this shape:

```json
{
  "success": false,
  "message": "Human-readable description",
  "errorCode": "SCREAMING_SNAKE_CASE_CODE",
  "data": null
}
```

| HTTP | When to expect it |
|------|-------------------|
| 400 | Invalid input — card token/expiry issues. Read `errorCode` for specifics. |
| 401 | Session token missing or expired. Redirect to login. |
| 403 | Non-admin user trying to call an admin-only endpoint. |
| 409 | Business rule conflict — coupon already used, plan already active, etc. |
| 502 | Upstream payment provider error — retry with user confirmation. |
| 500 | Server error — show generic retry message. |

---

## Dev Simulation States

For the subscription setup screen, add these states to the dev tools panel:

| State key | Simulates |
|-----------|-----------|
| `payment_declined` | Step 9 returns `PAYMENT_METHOD_CHARGE_FAILED` |
| `coupon_invalid` | Step 8a returns `isValid: false` |
| `coupon_expired` | Step 9 returns `COUPON_FAILED_TO_APPLY` |
| `token_invalid` | Step 9 returns `PAYMENT_METHOD_INVALID_TOKEN` |

---

## Navigation Flow (Updated)

```
Register (steps 1-3) → Initialize session (steps 4-5)
    |
    ├── subscriptionStatus = "PendingPayment"
    |       ↓
    |   Show Plan Selection screen
    |       ↓
    |   Show Payment screen (steps 6-9)
    |       ↓
    |   Dashboard
    |
    ├── subscriptionStatus = "Active"
    |       ↓
    |   Dashboard
    |
    └── subscriptionStatus = "Inactive"
            ↓
        Reactivation screen
```

**On every app launch / after login:**
Call `GET /api/company` and branch on `subscriptionStatus` before rendering any app screen.
