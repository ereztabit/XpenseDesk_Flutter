# Card on File — Tranzila Integration Flow

## Overview

Add a "Card on File" feature to XpenseDesk so that a company can store their credit card for future billing.
The card number is **never stored** — only a **Tranzila token (`TranzilaTK`)** is stored on the company record.

---

## App Context

- **Framework:** Flutter/Dart with Riverpod state management
- **Onboarding wizard** already has a **Step 5 "Payment" placeholder** — this is where card entry will go
- **`CompanyInfo` model** currently has no payment token field — needs to be extended
- Company data is managed via `companyProvider` → `AuthService` → `PUT /api/company`

---

## Tranzila Integration Flow

### Step 1 — Backend generates a handshake token (`thtk`)

The Flutter app requests a handshake token from our backend.
Our backend calls Tranzila server-side (secret key must never be exposed client-side):

```
POST https://api.tranzila.com/v2/handshake/create
Headers:
  X-tranzila-api-app-key: <appKey>
  X-tranzila-api-request-time: <unixTimestampMs>
  X-tranzila-api-nonce: <80-char hex string>
  X-tranzila-api-access-token: hash_hmac('sha256', appKey, secret + requestTime + nonce)

Body:
{
  "terminal_name": "<terminal>",
  "sum": 0
}
```

**Response:**
```json
{
  "error_code": 0,
  "message": "Success",
  "thtk": "w5bcd32faf6a60c621663d3f19dd87eda4729e94be"
}
```

> `thtk` is valid for **20 minutes**. Must be refreshed if expired.

---

### Step 2 — Flutter renders the Tranzila iFrame

Embed the Tranzila payment iframe using `HtmlElementView` (Flutter web) or `webview_flutter` (mobile).

**Target URL:** `POST https://directng.tranzila.com/{terminal_name}/iframenew.php`

**Key parameters:**

| Parameter | Value | Notes |
|-----------|-------|-------|
| `tranmode` | `VK` | J5 verify + tokenize — validates card is real, no charge |
| `hidesum` | `1` | Hide amount (allowed only on token-only modes) |
| `thtk` | `{thtk}` | Handshake token from Step 1 |
| `currency` | `1` | ILS (or as required) |
| `sum` | `0` | No charge |
| `success_url_address` | `{callback}` | Flutter intercepts this redirect |
| `fail_url_address` | `{callback}` | Flutter intercepts this redirect |
| `notify_url_address` | `{backend_notify}` | Optional server-side IPN |
| `lang` | `il` / `en` | Match app language |

> **Why `VK` over `K`?** `VK` performs a J5 authorization check — it verifies the card is valid and not blocked before storing the token. `K` stores any card number without validation.

---

### Step 3 — Tranzila returns the token

On success, Tranzila redirects to `success_url_address` (or POSTs to `notify_url_address`) with:

| Field | Description |
|-------|-------------|
| `TranzilaTK` | Card token (e.g. `X543c4c9214a1882312`) — **store this** |
| `ccno` | Last 4 digits of card (for display) |
| `cardtype` | Card brand: 1=MC, 2=Visa, 3=Diners, 4=Amex, 5=Isracard, 6=Maestro |
| `Response` | `000` = success, `777` = J5 verify OK (no charge) |
| `expdate` | Card expiry (MMYY format) |

---

### Step 4 — Flutter saves the token to the company record

Flutter sends the token data to our backend, which stores it on the company record.

**Proposed API call:**
```
PUT /api/company/payment-method
Body:
{
  "paymentToken": "X543c4c9214a1882312",
  "cardLastFour": "2312",
  "cardType": 2,
  "cardExpiry": "1226"
}
```

---

## What Needs to Be Built (Flutter Side)

| Item | File | Details |
|------|------|---------|
| `CompanyInfo` model | `lib/models/company_info.dart` | Add `paymentToken`, `cardLastFour`, `cardType`, `cardExpiry` fields |
| `PaymentService` | `lib/services/payment_service.dart` | Fetch `thtk` from backend; save token to company |
| `payment_step.dart` | `lib/screens/onboarding/steps/payment_step.dart` | Replaces the current `_StepPlaceholder` for Step 5 |
| Tranzila iFrame widget | `lib/widgets/tranzila_iframe.dart` | Renders iframe, intercepts success/fail redirect |
| `companyProvider` | `lib/providers/company_provider.dart` | Add `savePaymentToken()` method |
| `paymentServiceProvider` | `lib/providers/payment_provider.dart` | Riverpod provider for `PaymentService` |

---

## What Needs to Be Built (Backend Side)

| Item | Details |
|------|---------|
| `GET /api/company/payment-thtk` | Generates and returns a Tranzila handshake token (server-side HMAC auth) |
| `PUT /api/company/payment-method` | Stores `paymentToken`, `cardLastFour`, `cardType`, `cardExpiry` on the company record |
| Company DB schema | Add payment token fields to the company table |

---

## Open Questions

1. **WebView approach:** Flutter web → `HtmlElementView` (iframe); mobile → `webview_flutter`. Confirm target platforms.
2. **`tranmode`:** Confirmed `VK` (verify + tokenize, no charge) unless there's a reason to use `K` only.
3. **Backend endpoint:** Does the backend already have a field/endpoint for storing the payment token?
4. **Token Module:** Tranzila's tokenization requires the **Token Module** to be purchased and enabled on the terminal. Confirm this is active.
5. **Notify URL (IPN):** Do we need server-side webhook confirmation, or is the client-side redirect sufficient?

---

## Tranzila Key References

- **API base:** `https://api.tranzila.com`
- **iFrame (DirectNG):** `https://directng.tranzila.com/{terminal}/iframenew.php`
- **Hosted Fields JS:** `https://hf.tranzila.com/assets/js/thostedf.js`
- **Auth:** 4-header HMAC-SHA256 (`X-tranzila-api-app-key`, `X-tranzila-api-request-time`, `X-tranzila-api-nonce`, `X-tranzila-api-access-token`)
- **Token Module:** Must be purchased from Tranzila — contact `support@interspace.net`
- **Docs:** https://docs.tranzila.com/
