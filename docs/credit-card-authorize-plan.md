# Credit Card Authorization Page — Production Plan

---

## ❓ Open Questions — Tranzila Support

**Q1 — `response_language` param in `fields.charge()`:**

> We pass `response_language: 'English'` (or `'Hebrew'`) in the `fields.charge()` call but Tranzila field-level errors still return in Hebrew regardless.
> Does the Hosted Fields SDK actually forward this param to the API, or is it ignored?
we are talking about validation errors
> Note: if unsupported, our `tranzila_response_codes.json` error resolution handles language on our side, making this moot.

**Q2 — 3DS `force_txn_on_3ds_fail` security (ask before implementing Step 6):**

> What is the recommended way to enforce `force_txn_on_3ds_fail` securely?
> Specifically: can this setting be locked at the terminal level or embedded in the `thtk` issuance call so that the client-side `fields.charge()` payload cannot override it?
> We want to ensure a user cannot modify the page URL or JS call to bypass 3DS failure rejection.

**Q3 — 3DS test cards not working on dev terminal:**

> We are unable to complete any 3DS transaction on the dev terminal using the following test cards:
>
> | Card Number | Scenario |
> |-------------|----------|
> | `4907639999909022` | 3DS Frictionless — Success |
> | `4907639999990022` | 3DS Frictionless — Fail |
> | `4918914107195005` | 3DS Challenge Required (enter `555` to pass) |
>
> Questions:
> 1. Does the dev terminal need to be explicitly enrolled in 3DS? If so, please enable it.
> 2. Are these the correct test card numbers for the Hosted Fields integration, or is there a separate test card set for this flow?
> 3. What CVV and expiry date should be used with these cards? We are currently using expiry `12/30` and CVV `123` — are these valid for the 3DS test cards?

**Q4 — Phone number validation for 3DS cardholder fields:**

> When passing `phone_country_code` and `phone_number` to `fields.charge()`:
> 1. Does Tranzila validate the phone country code format? Must it include `+` or just digits (e.g. `972` vs `+972`)?
> 2. Is there a minimum/maximum length enforced on `phone_number`?
> 3. Does the phone number need to be in a specific format (e.g. no leading zero, no spaces, no dashes)?
> 4. If the phone fields are missing or invalid, does the transaction fail or does 3DS simply proceed without them?

**Q5 — Sandbox environment and test credit cards:**

> We are getting real declines on real credit cards during development (e.g. error `003` — "Contact credit company to approve the transaction"). We should not be developing against a live terminal.
>
> 1. How do we get a sandbox/test terminal that does not process real transactions?
> 2. What test credit card numbers can we use against the sandbox that will return controlled success/failure responses?
> 3. **RESOLVED — `sandbox` flag is not an environment toggle.** Tranzila docs explicitly state "Always use `sandbox: false`". The flag is unrelated to test/live mode. Sandbox environment must be provisioned at the terminal level. Please provide a sandbox terminal for development use.

---

## Two-Page Architecture (interim 3DS security)

Until Tranzila confirms a server-authoritative way to lock 3DS settings, we use **two separate HTML pages**:

| Page | URL | 3DS |
|------|-----|-----|
| `Authorize.html` | `/CreditCard/Authorize.html` | No 3DS |
| `AuthorizeCard3DS.html` | `/CreditCard/AuthorizeCard3DS.html` | 3DS enabled |

**Why this works as an interim measure:**
- Flutter decides which page to open based on `AppConfig` — the user never sees or controls the URL
- The 3DS page URL is not guessable from the standard page URL
- No URL param for `force_txn_on_3ds_fail` — it's hardcoded inside the 3DS page itself
- Both pages share the same `authorize.css` and `authorize.js` — 3DS page adds only the extra `fields.charge()` params and the cardholder input fields

**Future state:** once Tranzila confirms server-side enforcement, merge back to a single page and remove the split.

---

## File Structure (target)

```
web/
└── CreditCard/
    ├── Authorize.html       # main page (replaces tranzila-poc.html)
    └── authorize.css        # extracted styles

assets/
└── images/
    └── logo.png             # already exists — served via Flutter at /assets/images/logo.png
```

`TranzilaPocScreen` (Flutter) will be updated to open:
`/CreditCard/Authorize.html?thtk=...&terminal=...&lang=en|he`

---

## Steps

### Step 1 — Create folder + extract CSS ✅ VERIFIED
- Created `web/CreditCard/`
- Created `web/CreditCard/authorize.css` with all styles from current `tranzila-poc.html`
- Created `web/CreditCard/Authorize.html` linking to `authorize.css`
- Updated `TranzilaPocScreen` URL to `/CreditCard/Authorize.html`
- Terminal now from `AppConfig.instance.tranzilaTerminal` (not hardcoded)
- Build & verified page loads ✅

### Step 2 — Logo + PCI DSS badge + Tranzila footer ✅ VERIFIED
- Replaced `<span class="logo">XpenseDesk</span>` with `<img src="/assets/images/logo.png">`
- Added inline SVG PCI DSS badge in header right side
- Added `<footer>Powered by Tranzila</footer>` at the bottom
- Build & verified layout ✅

### Step 3 — Multi-language support ✅ VERIFIED
- Read `?lang=en|he` from URL params (default `en`)
- Defined `STRINGS` object with both languages for all user-visible strings
- Applied `dir="rtl"` / `lang` on `<html>` via JS on load
- `TranzilaPocScreen` passes `&lang=` from `Localizations.localeOf(context).languageCode`
- `response_language: lang === 'he' ? 'Hebrew' : 'English'` passed to `fields.charge()` — **open question**: SDK may not forward it (see comment in Authorize.html)
- Build & verified both languages ✅

### Step 4 — Pass full result to opener + console error logging ✅ VERIFIED
- postMessage now sends full `transaction_response` object
- console.error fires for missing expected fields
- Failure banner resolves via errorMap → tx.error → generic fallback
- JS extracted to `authorize.js`, CSS to `authorize.css`, both cache-busted with `Date.now()`
- No-cache meta tags added to `Authorize.html`
- Build & verified ✅

### Step 5 — Flutter side: handle full result ✅ VERIFIED
- `_listenForResult()` now stores full `transaction_response` from postMessage
- `_ResultCard` reads `card_type_name`, `card_mask`, `expiry_month`/`expiry_year`, `token`
- Build & verified ✅

### Step 6 — 3DS Support

3DS is only active if the Tranzila terminal has the service enabled. When triggered, the SDK injects a 400×600 iframe challenge popup into the page automatically — we don't render it ourselves, just need to make sure nothing in our layout blocks or clips it.

#### HTML changes (`Authorize.html` / `authorize.js`)

**Add visible, editable cardholder identity inputs** below the card fields, pre-filled from URL params. The user can override them before submitting:

```html
<!-- Visible, editable by user -->
<div class="field-group">
  <label for="card_holder_name">Cardholder Name</label>
  <input type="text" id="card_holder_name" autocomplete="cc-name">
</div>
<div class="field-group phone-row">
  <div>
    <label for="phone_country_code">Country Code</label>
    <input type="text" id="phone_country_code" placeholder="+972">
  </div>
  <div>
    <label for="phone_number">Phone</label>
    <input type="tel" id="phone_number" autocomplete="tel">
  </div>
</div>

<!-- Hidden — injected from URL param, never shown -->
<input type="hidden" id="card_holder_email">
```

**Phone country code — pre-filled from URL param, free-text:**

Flutter passes `&phone_country_code=+972` (resolved from company country defaults on the Flutter side). The HTML page reads it and pre-fills the field. If the param is absent the field is left blank. No mapping logic lives in this page.

**Pre-fill all fields from URL params:**

```javascript
document.getElementById('card_holder_name').value  = params.get('card_holder_name')  || '';
document.getElementById('card_holder_email').value = params.get('card_holder_email') || '';
document.getElementById('phone_number').value      = params.get('phone_number')      || '';

// phone_country_code is passed as digits only (e.g. "972") — prepend "+" here
const pcc = params.get('phone_country_code');
document.getElementById('phone_country_code').value = pcc ? '+' + pcc : '';
```

**Flutter URL construction** (`TranzilaPocScreen`):

```
/CreditCard/Authorize.html
  ?thtk=...
  &terminal=...
  &lang=he
  &card_holder_name=John+Doe
  &card_holder_email=john@example.com
  &phone_country_code=972
  &phone_number=
  &force_txn_on_3ds_fail=N
```

Flutter passes the dial code as digits only — no `+`, no encoding needed. The HTML page prepends `+` when filling the field. Flutter is responsible for resolving the dial code from company country defaults before building this URL.

`card_holder_name`, `phone_country_code`, `phone_number` need EN/HE labels added to the `STRINGS` object. Email is hidden — no label needed.

**Pass them into `fields.charge()`:**

```javascript
fields.charge({
  terminal_name:       params.get('terminal'),
  amount:              '1.00',
  tranmode:            'V',
  response_language:   lang === 'he' ? 'Hebrew' : 'English',
  // 3DS
  force_challenge:     params.get('force_challenge') || 0,
  force_txn_on_3ds_fail: params.get('force_txn_on_3ds_fail') || 'N',
  // Cardholder identity — improves frictionless rate
  card_holder_name:    document.getElementById('card_holder_name').value,
  card_holder_email:   document.getElementById('card_holder_email').value,
  phone_country_code:  document.getElementById('phone_country_code').value,
  phone_number:        document.getElementById('phone_number').value,
}, function(err, response) { ... });
```

**Layout guard:** the SDK challenge iframe is injected at `position: fixed`, centered in the viewport. Our page has no `overflow: hidden` or `transform` on the root — verify this stays true so the iframe isn't clipped.

#### Flutter changes (`TranzilaPocScreen`)

Pass cardholder data as URL params when opening the page. The Flutter side already has `userInfo` (email, name) and can supply them:

```
/CreditCard/Authorize.html
  ?thtk=...
  &terminal=...
  &lang=en
  &card_holder_name=John+Doe
  &card_holder_email=john@example.com
  &phone_country_code=%2B972
  &phone_number=0501234567
  &force_txn_on_3ds_fail=N
```

`TranzilaPocScreen` reads `userInfo` from Riverpod and URI-encodes the fields before building the URL.

#### Open questions before closing this step

- [ ] Confirm with Tranzila that the dev terminal has 3DS enrolled — without it we cannot test the challenge flow at all
- [ ] Decide: do we pass `force_challenge: 1` during POC testing to force the challenge iframe to appear?
- [ ] Confirm `force_txn_on_3ds_fail` default — `'N'` means a non-3DS-enrolled card will fail; `'Y'` degrades gracefully but loses liability shift

---

### Step 7 — postMessage init_data architecture

**Goal:** Remove `thtk` and all cardholder data from the URL. They must not appear in browser history, server logs, or referrer headers. The popup opens synchronously on click; sensitive data flows via postMessage only.

**URL after this step:** `/CreditCard/Authorize.html?lang=he` — lang only (needed immediately for RTL rendering before any message arrives). Both HTML files are unchanged in structure.

#### JS changes (`authorize.js` — shared by both pages)

- Remove `thtk` and `TERMINAL_NAME` from URL params reading at top — they arrive via `init_data` instead
- `lang` stays in URL params (needed for immediate RTL/string rendering)
- On DOM ready: show "Connecting…" banner, then send `{ type: 'ready' }` to `window.opener`
- Listen for `window.message` with `type: 'init_data'` — extract `thtk`, `terminal`, and cardholder fields, then call `init()`
- `init()` signature unchanged — it just reads from variables that are now set by `init_data` instead of URL params
- **Dev logging:** `const DEV = window.location.hostname === 'localhost'` — when true, `console.log` every postMessage sent and received with a `[Tranzila ▶]` / `[Tranzila ◀]` prefix

#### Flutter changes (`tranzila_poc_screen.dart`)

- `_openPopup()`: open with `?lang=` only — no thtk, terminal, or cardholder data in URL. Store popup reference as `_popup`.
- `_listenForResult()`: handles both `tranzila_result` (existing, unchanged) and the new `ready` message — on `ready`, send `init_data` to `_popup`
- `init_data` payload:
  ```dart
  {
    'type':               'init_data',
    'thtk':               _thtk,
    'terminal':           AppConfig.instance.tranzilaTerminal,
    'card_holder_name':   userInfo?.fullName  ?? '',
    'card_holder_email':  userInfo?.email     ?? '',
    'phone_country_code': userInfo?.dailingCode ?? '',
    'phone_number':       '',
  }
  ```
- Use `window.location.origin` as `targetOrigin` when sending `init_data` (sensitive payload — don't use `'*'`)
- **Dev logging:** `if (AppConfig.environment == 'dev') debugPrint(...)` for both send and receive

### Step 8 — Cleanup
- Delete `web/tranzila-poc.html` (replaced by `web/CreditCard/Authorize.html`)
- Commit

---

## Tranzila Callback Response Shape

The `fields.charge()` callback fires with `(err, response)`. The full shape of both outcomes is documented here.

### Success Response

`err` is `null`. `response` contains:

```json
{
  "errors": null,
  "transaction_response": {
    "success": true,
    "error": null,
    "processor_response_code": "000",
    "transaction_id": "97588",
    "auth_number": "0000000",
    "amount": "10.00",
    "currency_code": 1,
    "credit_card_last_4_digits": "2312",
    "expiry_month": "12",
    "expiry_year": "26",
    "user_form_data": {
      "response_language": "",
      "contact": "john.doe@example.com",
      "company": "Example Corp",
      "json_purchase_data": "",
      "force_challenge": "0",
      "force_txn_on_3ds_fail": "N",
      "expiry": "",
      "notify_url": "",
      "shopify_id": "",
      "DCdisable": "",
      "requested_by_user": "merchant_user",
      "card_holder_id_number": ""
    },
    "card_type": "5",
    "card_mask": "458059****2312",
    "card_locality": "domestic",
    "txn_type": "debit",
    "tranmode": "A",
    "card_type_name": "Isracard",
    "cvv_status": "3",
    "id_status": "0",
    "card_issuer": "1",
    "token": "me4b50240d8c6222312",
    "payment_plan": 1,
    "total_installments_number": null
  },
  "response_hash": "7d7dfdbbd6e863ebb8b68c74a6080cdd26bbac4b39fe01a0aa3839ee6c63d217"
}
```

**Fields Flutter needs to extract from `transaction_response`:**

| Field | Description |
|-------|-------------|
| `token` | Reusable card token — the primary output |
| `card_mask` | Display string e.g. `458059****2312` |
| `card_type` | Numeric brand code (see card types below) |
| `card_type_name` | Human-readable brand e.g. `Isracard` |
| `expiry_month` | `MM` |
| `expiry_year` | `YY` |
| `processor_response_code` | `"000"` on approval, `"777"` for J5 verify — both are success |

**Card type codes:**

| Value | Brand |
|-------|-------|
| `1` | Mastercard |
| `2` | Visa |
| `3` | Diners |
| `4` | Amex |
| `5` | Isracard |
| `6` | Maestro |

**Success condition:** `transaction_response.success === true` AND `processor_response_code` is `"000"` or `"777"`.

---

### Failure Response

There are two distinct failure modes:

**Mode A — Hosted Fields validation error** (`err` is non-null, `response` may be null):

```json
{
  "errors": [
    {
      "code": 10017,
      "message": "Invalid handshake token",
      "param": "thtk"
    }
  ],
  "transaction_response": null,
  "response_hash": "9c636a0098729e53e48b16a348229fa19e01d1f99e0f25bf1eceeef17149d603"
}
```

`err.messages[]` — each entry has `code` (integer, `10000–10017` range), `message` (English string from Tranzila), and `param` (which field failed). Display under the relevant field container using `#errors_for_{param}`.

**Mode B — Transaction declined** (`err` is null, `response.transaction_response.success === false`):

`processor_response_code` contains the SHVA/3DS code. Look up in `errorMap` and display in the current language.

---

## Error Codes — Source and Usage

**Source file:** `assets/data/tranzila_response_codes.json`

This file contains every SHVA and 3DS response code from Tranzila, with both English and Hebrew translations. It is served by Flutter's static asset handler at:

```
/assets/data/tranzila_response_codes.json
```

The HTML page fetches this file on load, builds a lookup map keyed by `code`, then resolves the display message using the `?lang=en|he` URL parameter.

### Loading the codes

```javascript
const errorMap = {};   // populated on load

fetch('/assets/data/tranzila_response_codes.json')
  .then(r => r.json())
  .then(data => {
    data.codes.forEach(c => { errorMap[c.code] = { en: c.en, he: c.he }; });
  });
```

### Resolving a code to a user-facing message

```javascript
function resolveErrorMessage(code) {
  const entry = errorMap[String(code)];
  if (!entry) return lang === 'he' ? 'שגיאה לא ידועה (' + code + ')' : 'Unknown error (' + code + ')';
  return (entry[lang] ?? entry.en) || 'Unknown error (' + code + ')';
}
```

### Example

Tranzila returns `processor_response_code: "006"` with `?lang=he`:

```
entry = { en: "Incorrect identity number or CVV.", he: "דחה עסקה: ת.ז. או CVV שגויים" }
resolveErrorMessage("006") → "דחה עסקה: ת.ז. או CVV שגויים"
```

Same code with `?lang=en`:
```
resolveErrorMessage("006") → "Incorrect identity number or CVV."
```

### Fallback chain

1. Look up `processor_response_code` in `errorMap` → display in current `lang`
2. If code not found → show Tranzila's raw `tx.error` string (already in English)
3. If both missing → show generic "Payment failed" string from `STRINGS[lang]`

---

## Strings (en / he)

| Key | English | Hebrew |
|-----|---------|--------|
| `title` | Add Payment Card | הוספת כרטיס אשראי |
| `cardNumber` | Card Number | מספר כרטיס |
| `cvv` | CVV | CVV |
| `expiry` | Expiry | תוקף |
| `saveCard` | Save Card | שמור כרטיס |
| `processing` | Processing… | מעבד… |
| `bannerReady` | Enter your card details below. | הזן את פרטי הכרטיס שלך. |
| `bannerSuccess` | Card saved successfully! | הכרטיס נשמר בהצלחה! |
| `bannerError` | Please fix the errors below. | אנא תקן את השגיאות למטה. |
| `errorMissing` | Missing handshake token. | חסר טוקן לחיבור. |
| `poweredBy` | Powered by Tranzila | מופעל על ידי טרנזילה |

---

## postMessage Result Shape (updated)

```javascript
window.opener.postMessage({
  type:                 'tranzila_result',
  success:              true,
  transaction_response: { /* full object from Tranzila */ }
}, '*');
```

Flutter extracts `token`, `card_mask`, `card_type_name`, `expiry_month`, `expiry_year` from `transaction_response`.

---

## Terminal Name — Config-driven

Terminal name lives in `assets/config/app_config_*.yaml` under `payment.tranzilaTerminal`:

```yaml
# app_config_dev.yaml
payment:
  tranzilaTerminal: dev123

# app_config_prod.yaml
payment:
  tranzilaTerminal: xpensedesk
```

Accessed via `AppConfig.instance.tranzilaTerminal` and passed to the popup as `?terminal=`.
The HTML page reads it from URL params — never hardcoded.

---

## Notes

- Logo path: `/assets/images/logo.png` — served by Flutter's static asset handler
- PCI DSS badge: inline SVG (no external dependency)
- `tranzila-poc.html` remains in `web/` temporarily until Flutter route is updated, then deleted
- Do NOT move the "Enter Card Details" button on `TranzilaPocScreen` — deferred
