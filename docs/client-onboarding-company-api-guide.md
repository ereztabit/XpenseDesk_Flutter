# Onboarding & Company API � Client Guide

This document is the Flutter client reference for the onboarding flow and company configuration APIs.
It covers what to call, when to call it, what to send, and what to expect back.

---

## Authentication

All protected endpoints require a session token in the Authorization header:

```
Authorization: Bearer <session-token>
```

The session token is obtained at the end of the onboarding flow (verify OTP step) or after a standard magic link login.
Store it securely on the device and attach it to every protected request.

---

## Onboarding Flow Overview

```
1. GET  /api/onboarding/reference-data   ? populate form dropdowns
2. POST /api/onboarding/company          ? submit form, receive OtpKey
3. POST /api/onboarding/verify-otp       ? submit OTP, receive SessionToken
4. GET  /api/users/me                    ? initialize session (same as after login)
```

No session token is needed for steps 1�3.
After step 3, the client is fully authenticated and can call any protected endpoint.

---

## 1. GET /api/onboarding/reference-data

**Auth:** None

**Purpose:** Fetch all dropdown data needed to render the signup form. Call this before showing the form.

**Request:** No body, no parameters.

**Response:**

```json
{
  "success": true,
  "message": "Reference data retrieved successfully",
  "data": {
    "countries": [
      {
        "countryCode": "IL",
        "countryName": "Israel",
        "defaultCurrencyCode": "ILS",
        "defaultLanguageId": 1,
        "defaultTimeZoneId": 1
      }
    ],
    "languages": [
      {
        "languageId": 1,
        "languageCode": "en",
        "languageName": "English",
        "defaultLocaleCode": "en-US"
      }
    ],
    "timeZones": [
      {
        "timeZoneId": 1,
        "timeZoneName": "Israel Standard Time",
        "displayName": "(UTC+02:00) Jerusalem",
        "baseUtcOffsetMin": 120
      }
    ],
    "currencies": [
      {
        "currencyCode": "ILS",
        "currencyName": "Israeli New Shekel",
        "currencySymbol": "?"
      }
    ]
  }
}
```

**Client notes:**
- When the user selects a country, auto-fill currency, language, and timezone using the country's `defaultCurrencyCode`, `defaultLanguageId`, and `defaultTimeZoneId`.
- Display `timeZones[].displayName` in the UI.
- Display `currencies[].currencySymbol` in the UI.

---

## 2. POST /api/onboarding/company

**Auth:** None

**Purpose:** Submit the signup form. The server validates the input, checks that the email is not already registered, and sends an OTP to the provided email. Returns an `otpKey` that identifies this signup attempt.

**Request body:**

```json
{
  "companyName": "Acme Corp",
  "countryCode": "IL",
  "cutoverDay": 1,
  "email": "owner@acme.com",
  "fullName": "Jane Smith",
  "accountantEmail": "accountant@acme.com",
  "isMarketingConsent": true
}
```

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| companyName | string | Yes | Max 200 characters |
| countryCode | string | Yes | 2-character ISO code, e.g. "IL" |
| cutoverDay | int | Yes | Day of month 1�28. Defines when expense cycles reset. |
| email | string | Yes | Owner email. Must be a valid address not already registered. |
| fullName | string | Yes | Owner display name. Max 200 characters. |
| accountantEmail | string | No | If omitted, defaults to owner email on the server. |
| isMarketingConsent | boolean | Yes | `true` if the user opted into marketing communications, `false` if they declined. |

**Success response (200):**

```json
{
  "success": true,
  "message": "OTP sent successfully",
  "data": {
    "otpKey": "a3f7c2d1-0000-0000-0000-aabbccddeeff"
  }
}
```

Store `otpKey`. It is required for the next step.

**Error responses:**

| HTTP | Meaning |
|------|---------|
| 400 | Validation failed. `message` describes the specific error. |
| 409 | Email is already registered to a company. |
| 500 | Server error. |

**Resend OTP:** Call this endpoint again with the same email. The previous OTP is invalidated and a new `otpKey` is returned.

---

## 3. POST /api/onboarding/verify-otp

**Auth:** None

**Purpose:** Verify the OTP the user received. On success, creates the company and the first admin user, and returns a `sessionToken` � the client is now fully authenticated.

**Request body:**

```json
{
  "otpKey": "a3f7c2d1-0000-0000-0000-aabbccddeeff",
  "otp": "123456"
}
```

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| otpKey | string (uuid) | Yes | The value returned from the previous step. |
| otp | string | Yes | The code the user entered. |

**Success response (200):**

```json
{
  "success": true,
  "message": "Company created successfully",
  "data": {
    "sessionToken": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  }
}
```

Save `sessionToken` securely. Use it as the Bearer token for all subsequent requests.
Proceed directly to `GET /api/users/me` to initialize the session.

**Error responses:**

| HTTP | Meaning |
|------|---------|
| 400 | OTP key not found, OTP is incorrect, or the signup session has expired (1-hour TTL). |
| 500 | Server error. |

**On expiry:** If the OTP expires, start over from step 2. The server will issue a new OTP key.

---

## 4. GET /api/users/me

**Auth:** Required (all roles)

**Purpose:** Returns the authenticated user's profile and company locale context. Call this immediately after obtaining a session token to initialize the app session.

**Request:** No body.

**Response:**

```json
{
  "success": true,
  "message": "User info retrieved successfully",
  "data": {
    "email": "owner@acme.com",
    "fullName": "Jane Smith",
    "roleId": 1,
    "status": "Active",
    "languageId": 1,
    "languageCode": "en",
    "languageName": "English",
    "companyName": "Acme Corp",
    "currencyCode": "ILS",
    "currencySymbol": "?",
    "timeZoneId": 1,
    "timeZoneName": "Israel Standard Time",
    "timeZoneDisplayName": "(UTC+02:00) Jerusalem"
  }
}
```

| Field | Notes |
|-------|-------|
| roleId | 1 = Admin/Manager, 2 = Employee |
| status | Active, Pending, or Disabled |
| currencySymbol | Use for all monetary display in the app |
| timeZoneDisplayName | Show to the user in settings |

---

## 5. GET /api/company

**Auth:** Required (all roles)

**Purpose:** Returns the full configuration of the authenticated user's company. Used to populate the company settings screen.

**Request:** No body. Company is derived from the session token.

**Response:**

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
    "currencySymbol": "?",
    "languageId": 1,
    "languageCode": "en",
    "languageName": "English",
    "timeZoneId": 1,
    "timeZoneName": "Israel Standard Time",
    "timeZoneDisplayName": "(UTC+02:00) Jerusalem"
  }
}
```

| Field | Notes |
|-------|-------|
| companyId | Read-only. Display only, never send back to the server. |
| companyStatus | Active, Suspended, or Cancelled |
| createdAt | ISO 8601 UTC |
| cutoverDay | Day of month (1�28) when expense cycles reset. Read-only after creation. |
| accountantEmail | May be null if not set. |

**Locked fields** (read-only, never shown as editable):
`countryCode`, `currencyCode`, `timeZoneId`, `cutoverDay`, `companyStatus`, `createdAt`

**Error responses:**

| HTTP | Meaning |
|------|---------|
| 401 | Missing or invalid session token. |
| 500 | Server error. |

---

## 6. PUT /api/company

**Auth:** Required � Admin only (roleId = 1)

**Purpose:** Update the modifiable company fields. Non-admin users will receive 403.

**Request body:**

```json
{
  "companyName": "Acme Corp International",
  "languageId": 2,
  "accountantEmail": "newaccountant@acme.com"
}
```

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| companyName | string | Yes | New display name. Max 200 characters. |
| languageId | int | Yes | Must be a valid language ID from the reference data. |
| accountantEmail | string | No | Set to null to clear. |

**Success response (200):**

```json
{
  "success": true,
  "message": "Company configuration updated successfully"
}
```

After a successful update, refresh the company details by calling `GET /api/company` again.

**Error responses:**

| HTTP | Meaning |
|------|---------|
| 401 | Missing or invalid session token. |
| 403 | Authenticated user is not an Admin. |
| 500 | Server error. |

---

## Error Handling Summary

All error responses follow the same shape:

```json
{
  "success": false,
  "message": "Description of the error"
}
```

| HTTP | When to expect it |
|------|-------------------|
| 400 | Invalid input. Read `message` to surface to the user. |
| 401 | Session token missing or expired. Redirect to login. |
| 403 | User does not have permission for this action. |
| 409 | Conflict � e.g. email already registered. |
| 500 | Server error. Show a generic retry message. |



# Flutter Client – Onboarding Flow Implementation Guide

This document embeds the complete **Lovable UX & Visual Specification** for the XpenseDesk onboarding flow.

It serves as the single source of truth for:

* Layout
* Colors
* Typography
* Spacing
* Component behavior
* Animation
* Responsive rules
* State structure
* Navigation flow

This is a pixel-accurate recreation guide for Flutter.

---

# 🎨 Design System

## Color Palette (HSL)

| Token              | Light Mode         | Hex Approx. | Usage                                                |
| ------------------ | ------------------ | ----------- | ---------------------------------------------------- |
| Primary            | hsl(250, 45%, 30%) | #2B2462     | Buttons, active step ring, links, encouragement text |
| Primary Foreground | hsl(0, 0%, 100%)   | #FFFFFF     | Text on primary buttons                              |
| Background         | hsl(240, 20%, 98%) | #F8F8FB     | Full page background                                 |
| Card               | hsl(0, 0%, 100%)   | #FFFFFF     | Wizard card surface                                  |
| Foreground         | hsl(250, 30%, 15%) | #1B1635     | Headings, body text                                  |
| Muted              | hsl(250, 15%, 95%) | #F0EFF4     | Inactive step circles, summary backgrounds           |
| Muted Foreground   | hsl(250, 10%, 45%) | #6B6580     | Placeholder, helper, secondary text                  |
| Border             | hsl(250, 20%, 90%) | #E2E0ED     | Card borders, input borders                          |
| Success            | hsl(162, 73%, 46%) | #20C997     | Completed step circles                               |
| Warning            | hsl(25, 95%, 53%)  | #F97316     | Amber alerts                                         |
| Destructive        | hsl(330, 81%, 60%) | #EC4899     | Error states                                         |
| Accent             | hsl(280, 35%, 55%) | #9B59B6     | Best Value badge                                     |
| Accent Foreground  | hsl(0, 0%, 100%)   | #FFFFFF     | Badge text                                           |

---

# 📐 Global Layout

Header (~64px height)

* White background with 95% opacity
* Bottom border: 1px Border color
* Logo height: 32px
* Language toggle: flag (24×16px) + short code

Main Section

* Vertically centered
* Page padding: 16px mobile / 24px tablet / 32px desktop
* Gap between progress and card: 24px

Wizard Card

* Border radius: 12px
* Padding: 24px
* Narrow max width: 448px (Steps 1,2,3,5)
* Wide max width: 672px (Step 4)

Footer (~56px height)

* Background: Muted at 30% opacity
* Top border: 1px Border color
* Links change color on hover

---

# 🔵 Progress Indicator

5 circles (32×32px) connected by 2px lines.

States:

Completed:

* Background: Success
* White checkmark 16px

Active:

* Background: Primary
* White step number
* 4px ring (Primary at 20% opacity)

Upcoming:

* Background: Muted
* Text: Muted Foreground

Encouragement text:

* 14px medium
* Color: Primary
* Center aligned

---

# 📝 Step 1 — Personal Details

Card width: 448px

Fields:

* Full Name (auto-focus)
* Work Email

Checkboxes:

* Terms & Privacy (required)
* Marketing (optional)

Continue disabled until:

* Full name valid
* Email valid
* Terms accepted

Button height: 40px
Radius: 12px

---

# 🏢 Step 2 — Company Details

Auto-load reference data.

Country selection auto-populates:

* Currency
* Language
* Timezone

Country defaults panel:

* Background: Primary at 5%
* Border: Primary at 20%
* Padding: 12px
* Radius: 12px

Amber warning:

* Background: Warning at 10%
* Border: Warning at 50%

Continue button shows Loader spinner when loading.

---

# 📧 Step 3 — OTP Verification

Inner Card component.

OTP slots:

* 6 inputs
* 40×44px
* Radius: 8px
* 2px Primary focus ring

Timer format: M:SS

Shake animation on invalid input (500ms).

Lockout after 5 failures (15 min).

Resend cooldown: 30 seconds.

---

# 💳 Step 4 — Plan Selection

Wide card: 672px

Two plan cards side by side.

Selected state:

* Primary border
* 2px ring
* Shadow-md

Annual plan badge:

* Accent background
* Pill shape
* Positioned -10px top

Clicking plan auto-advances after 400ms.

Cancel opens persuasion dialog.

---

# 💰 Step 5 — Payment

Summary panel:

* Muted at 50% opacity
* Padding: 16px
* Radius: 12px

Card form container:

* 2px dashed border
* Radius: 12px

Pay button:

* Primary
* 40px height
* Lock icon 14px
* Spinner replaces text when loading

On success:
Navigate to dashboard
Show toast:
"Welcome aboard! 🎉"

---

# 🛠 Dev Tools Panel

Floating bottom-right toggle.

Panel:

* Foreground at 90% opacity
* Radius: 12px
* Padding: 12px
* Shadow-xl

Simulation states:

* duplicate_email
* invalid_otp
* otp_expired
* otp_lockout
* payment_declined

Hidden in production build.

---

# 🌍 RTL Support

* Hebrew activates RTL
* Directional icons mirror
* No hardcoded strings
* Entire page rebuilds on language change

---

# 📱 Responsive Rules

Mobile (<640px):

* Card full width
* Plan cards stacked
* Cancel dialog stacked

Tablet/Desktop:

* Fixed max widths
* Two-column plans

---

# 🔄 State Model

Single onboarding state object.

No persistence across refresh.

Separate DevSimulation state.

---

# 🗺 Navigation Flow

Step 1 → Step 2 → Step 3 → Step 4 → Step 5 → Dashboard

Back buttons preserve state.
No skipping allowed.

---

This document now fully embeds the Lovable onboarding UX specification for Flutter implementation.
