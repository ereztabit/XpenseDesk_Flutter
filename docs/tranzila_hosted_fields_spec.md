# Tranzila Hosted Fields – Tokenization Spec

## 1. What We Are Building

A **card tokenization flow** that captures a credit card using Tranzila's Hosted Fields library and stores the resulting token via the XpenseDesk .NET API.

This is **not a payment**. No money moves. The goal is:

> Card entered → token returned by Tranzila → token saved to company record via our API → confirmed working.

Once this POC passes end-to-end, the same flow is used in the full onboarding integration.

---

## 2. Why Hosted Fields (Not iframe Redirect)

The earlier spec (`card-on-file-flow.md`) described a **full-page iframe redirect** approach (DirectNG). We switched to **Hosted Fields** instead.

| Concern | iframe Redirect | Hosted Fields |
|---|---|---|
| UI ownership | Tranzila owns the form | We own the form, Tranzila injects secure inputs |
| Token delivery | Via URL redirect params | Via JS callback — no page navigation |
| Flutter embedding | Requires intercepting redirects | Clean — just load a web page |
| Styling | Limited | Full CSS control over our containers |
| Flow complexity | High | Low |

---

## 3. How Tranzila Hosted Fields Works

### 3.1 The JavaScript Library

```html
<script src='https://hf.tranzila.com/assets/js/thostedf.js'></script>
```

This library injects Tranzila-hosted `<iframe>` elements into designated `<div>` containers on our page. Card data is entered inside those iframes and sent directly to Tranzila's servers — it never touches our JavaScript or our backend.

### 3.2 The Handshake Token (`thtk`)

Every session requires a `thtk` handshake token:

- Generated **server-side** by our .NET API via `GET /api/company/payment-setup`
- Backend calls Tranzila using HMAC-SHA256 auth
- Valid for **20 minutes**
- **Fetched by Flutter before opening the card page**, then passed as a URL param
- Must never be generated client-side — the secret key must never be exposed to the browser

### 3.3 Initialization

```javascript
var fields = TzlaHostedFields.create({
  sandbox: false,
  fields: {
    credit_card_number: { selector: '#card-number', placeholder: '4580 4580 4580 4580', tabindex: 1 },
    cvv:               { selector: '#cvv',         placeholder: '123',                tabindex: 2 },
    expiry:            { selector: '#expiry',       placeholder: '12/28',              version: '1' }
  },
  styles: {
    'input': { 'font-size': '15px', 'color': '#111827' }
  }
});
```

### 3.4 The Charge Call — Tokenize Only, No Debit

```javascript
fields.charge({
  terminal_name: TERMINAL_NAME,  // passed via URL param ?terminal=
  tran_mode:     'V',            // verify — validates card, no charge
  tokenize:      true,           // return a reusable token
  amount:        10,             // must match the sum used in the handshake on the backend
  currency_code: 'ILS',
  thtk:          thtk            // passed via URL param ?thtk=
}, function(err, response) {
  if (err) { handleErrors(err); return; }
  if (response.transaction_response.success) {
    // postMessage result to Flutter, close popup
  }
});
```

**Important:** `amount` must match the `sum` used when generating the `thtk` on the backend
(`TranzilaTokenizationAmount` config value, currently `10`). Mismatch causes error `10017`.

### 3.5 Success Response Fields

| Field | Description |
|---|---|
| `transaction_response.token` | The reusable token — **store this** |
| `transaction_response.card_mask` | Masked PAN e.g. `458028******1369` |
| `transaction_response.card_type` | 1=MC, 2=Visa, 3=Diners, 4=Amex, 5=Isracard, 6=Maestro |
| `transaction_response.expiry_month` | MM |
| `transaction_response.expiry_year` | YY |

---

## 4. Flutter Web Integration — Popup Window

### Why a popup (not an iframe)

When `tranzila-poc.html` is loaded inside a Flutter `HtmlElementView` iframe, the `fields.charge()` callback **never fires** even though the HTTP transaction succeeds. Root cause:

Flutter's DWDS (Dart Web Debug Service) sends continuous object-typed `postMessage` events to all child iframes. Tranzila's `hf_global.js` calls `JSON.parse(event.data)` on every message it receives — crashing on Flutter's non-string payloads and corrupting internal SDK state. After submit, Tranzila's result postMessage is sent but never reaches our window.

All attempted mitigations (capture-phase guards, `EventTarget.prototype.addEventListener` wrapping, `window.top` spoofing) failed because DWDS injects into the iframe context before page scripts execute.

**Solution:** open `tranzila-poc.html` as a **popup window** (`window.open()`). A popup is a top-level browsing context — `window.top === window`, no DWDS injection, Tranzila's callback fires cleanly.

This is a web dev environment concern only. On mobile, a native WebView is used instead, which does not have this issue.

### Flutter flow

1. Flutter calls `GET /api/company/payment-setup` → receives `thtk`
2. User clicks "Enter Card Details" button
3. Flutter opens popup: `window.open('/tranzila-poc.html?thtk=...&terminal=...', 'card-tokenization', 'width=520,height=580,...')`
4. Flutter listens for `window.onMessage` events
5. Popup posts result: `window.opener.postMessage({ type: 'tranzila_result', token, card_mask, card_type, expiry }, '*')`
6. Flutter receives message, updates UI, popup closes automatically after 1.5s

**Popup blocking:** `window.open()` returns `null` if blocked. Since the popup opens from a direct button click (user gesture), Chrome allows it. Browser extensions with blanket popup blockers can still block it — detect via null check and show a clear message.

### URL parameters passed to the page

| Param | Description |
|---|---|
| `thtk` | Handshake token fetched by Flutter before opening the popup |
| `terminal` | Tranzila terminal name (defaults to `dev123` if omitted) |

---

## 5. The HTML Page (`web/tranzila-poc.html`)

### What it is

One self-contained `.html` file with all JavaScript embedded inline. Styled to match the XpenseDesk app (same colors, fonts, header). No build tools, no framework.

### Page load sequence

1. Read `thtk` and `terminal` from URL params
2. If `thtk` missing → show error banner, stop
3. Initialize `TzlaHostedFields.create()` with card field containers
4. Show "Enter your card details" banner, enable submit button

### Submit sequence

1. User clicks "Save Card"
2. Call `fields.charge({ terminal_name, tran_mode: 'V', tokenize: true, amount: 10, thtk })`
3. On success → show result table, `window.opener.postMessage(result)`, close after 1.5s
4. On error → show field-level errors or banner

### Result display (success)

```
Type:    Visa
Card:    458028******1369
Expiry:  12/30
Token:   yb8255f45728df51369
```

### Result display (failure)

Field-level errors appear under the relevant input. Banner shows "Please fix the errors below."

---

### Full response examples

**Success (`transaction_response.success = true`):**
```json
{
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
```

**Failure — issuer refusal (`transaction_response.success = false`):**
```json
{
  "errors": null,
  "transaction_response": {
    "success": false,
    "error": "Refusal. Please contact the card owner to check the reason with his credit company.",
    "processor_response_code": "004",
    "transaction_id": "7411",
    "amount": "10",
    "currency_code": 1,
    "credit_card_last_4_digits": "1369",
    "expiry_month": "11",
    "expiry_year": "29",
    "card_type": "2",
    "card_mask": "458028******1369",
    "card_locality": "domestic",
    "txn_type": "verify",
    "tranmode": "V",
    "card_type_name": "Visa",
    "cvv_status": "2",
    "id_status": "0",
    "token": "yb8255f45728df51369",
    "payment_plan": 1
  }
}
```

**Important:** on a failed transaction, Tranzila still returns a `token` — **do not store it**. Only persist the token when `success: true`.

`cvv_status` values: `"1"` = CVV match, `"2"` = CVV mismatch/not checked.
`processor_response_code: "000"` = approved. Any other code = declined.

---

## 6. Backend Endpoints

### 6.1 `GET /api/company/payment-setup` — ✅ Implemented

Returns the `thtk` handshake token. Manager role required.

**Response:**
```json
{
  "success": true,
  "message": "Handshake token generated successfully",
  "data": { "thtk": "w5bcd32faf6a60c621663d3f19dd87eda4729e94be" }
}
```

Backend config (appsettings):
```json
"AuthorizationTerminal": "dev123",
"ChargeTerminal": "dev123tok",
"BaseUrl": "https://api.tranzila.com",
"TokenizationAmount": 10
```

The `thtk` is generated using `AuthorizationTerminal` (`dev123`). The `terminal_name` in `fields.charge()` must match this exactly — mismatch causes error `10017 Invalid handshake token`.

### 6.2 `POST /api/payment/save-token` — ⏭️ Next phase

Saves the token + card metadata to the company record. Not part of the current POC.

---

## 7. Full Flow Diagram

```
Flutter (TranzilaPocScreen)
  |
  |-- GET /api/company/payment-setup          XpenseDesk .NET API
  |   Authorization: Bearer {session}           |
  |<-- { thtk } -----------------------------|
  |
  | User clicks "Enter Card Details"
  |
  | window.open('/tranzila-poc.html?thtk=...')
  |
  +----------> Popup: tranzila-poc.html
                 |
                 | TzlaHostedFields.create()
                 | Tranzila injects iframes into #card-number, #cvv, #expiry
                 |
                 | [user enters card details]
                 |
                 | fields.charge({ terminal, thtk, amount:10, tokenize:true })
                 |                                              Tranzila servers
                 |----------------------------------------------------->|
                 |<-- callback({ token, card_mask, expiry }) ------------|
                 |
                 | window.opener.postMessage({ type:'tranzila_result', ... })
                 | window.close() [after 1.5s]
                 |
Flutter receives postMessage → update state ✅
```

---

## 8. Error Handling

### Tranzila error codes

| Code | Meaning |
|---|---|
| `10000` | Mandatory key missing |
| `10001` | Invalid terminal name |
| `10002` | Invalid card number |
| `10003` | Invalid CVV |
| `10004` | Invalid expiration month |
| `10005` | Invalid expiration year |
| `10013` | Terminal not found / bad config |
| `10014` | Invalid tran_mode |
| `10017` | Invalid handshake token — terminal name or amount mismatch |

### Rules

- Parse `err.messages[]` — each has `param` and `message`
- Show field-level errors under the relevant container
- `thtk` is valid for 20 minutes — if expired, Flutter must re-fetch before opening the popup
- If `thtk` missing from URL: show error banner, disable form

---

## 9. Security Notes

- `AppKey` and `Secret` live in .NET app config — never in source code or committed
- `thtk` is generated server-side only — never client-side
- Raw card data never reaches our servers or our JavaScript
- `companyId` is resolved from the session on the backend — never trusted from the client
- `thtk` in the URL is acceptable — it is short-lived (20 min) and tied to a specific terminal + amount

---

## 10. Known Issues / Environment Notes

- **Chrome 146+ regex bug in Tranzila's `genfield.php`:** The pattern attribute `[0-9 /]*` is invalid under Chrome's new `v` (unicodeSets) regex flag. This causes console errors but does **not** affect functionality — the callback fires successfully despite the errors.
- **Flutter web iframe incompatibility:** Tranzila's SDK does not work inside a Flutter `HtmlElementView` iframe in dev mode. Use the popup approach for Flutter web. This does not affect mobile WebView integration.

---

## 11. Next Steps (After POC)

1. Implement `POST /api/payment/save-token` on the backend
2. After successful tokenization, call save-token from Flutter (not from the HTML page)
3. Connect to subscription activation (company status → `Active`)
4. Add `thtk` auto-refresh for sessions > 20 minutes
5. Mobile: integrate via native `webview_flutter` — load `tranzila-poc.html` in a full-screen WebView, use JavaScript channel instead of `postMessage` to return the token
6. Add IPN webhook (`notify_url`) for server-side confirmation
7. Implement recurring billing using stored token
