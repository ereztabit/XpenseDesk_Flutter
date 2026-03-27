# Credit Card Authorization Page — Production Plan

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

### Step 4 — Pass full result to opener + console error logging
- On success: postMessage the **full** `transaction_response` object (not just selected fields)
- Add explicit console.error calls when expected fields are missing from the response:
  - `token`, `card_mask`, `card_type`, `expiry_month`, `expiry_year`
- On failure: resolve the human-readable message from the response code using the error codes JSON (see Error Codes section below)
- Build & verify

### Step 5 — Flutter side: handle full result
- Update `_listenForResult()` to store the full `transaction_response`
- Update `_ResultCard` widget to display from full response
- Build & verify

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
