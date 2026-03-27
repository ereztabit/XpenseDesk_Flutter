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

### Step 2 — Logo + PCI DSS badge + Tranzila footer
- Replace `<span class="logo">XpenseDesk</span>` with `<img src="/assets/images/logo.png">`
- Add inline SVG PCI DSS badge next to logo or in the card header
- Add `<footer>Powered by Tranzila</footer>` at the bottom
- Build & verify layout

### Step 3 — Multi-language support
- Read `?lang=en|he` from URL params (default `en`)
- Define `STRINGS` object with both languages for every user-visible string:
  - Banner messages (loading, ready, processing, success, errors)
  - Field labels (Card Number, CVV, Expiry)
  - Button text (Save Card, Processing…)
  - Error messages
- Apply `dir="rtl"` to `<html>` when `lang=he`
- Update `TranzilaPocScreen` to pass the current app language
- Build & verify both languages

### Step 4 — Pass full result to opener + console error logging
- On success: postMessage the **full** `transaction_response` object (not just selected fields)
- Add explicit console.error calls when expected fields are missing from the response:
  - `token`, `card_mask`, `card_type`, `expiry_month`, `expiry_year`
- On failure: use `tx.error` (Tranzila's actual message) instead of generic "Tokenization failed"
  - Fallback: `processor_response_code` description map for common codes
- Build & verify

### Step 5 — Flutter side: handle full result
- Update `_listenForResult()` to store the full `transaction_response`
- Update `_ResultCard` widget to display from full response
- Build & verify

---

## Processor Response Codes (for human-readable errors)

| Code | User-facing message |
|------|-------------------|
| `000` | Approved |
| `002` | Card stolen — contact your bank |
| `003` | Card not found |
| `004` | Card refused — please contact your bank or try a different card |
| `006` | Incorrect CVV |
| `033` | Card expired |
| `036` | Card restricted |
| `039` | Invalid card number |

Fall back to Tranzila's `tx.error` string if code not in map.

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
