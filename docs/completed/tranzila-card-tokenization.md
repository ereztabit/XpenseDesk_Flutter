# Tranzila Card Tokenization — Implementation Summary

## What Was Built

A card tokenization and update flow using Tranzila's Hosted Fields library. Card data never touches our servers — Tranzila injects secure iframes into our HTML page, tokenizes the card, and returns a reusable token.

Used in two contexts:
1. **Billing tab** — "Update card" / "Add card" buttons open the Tranzila popup directly
2. **POC screen** — `/manager/payment-poc` route for testing (still available)

---

## Architecture

### Why Hosted Fields (not iframe redirect)

The original plan (`card-on-file-flow.md`) used Tranzila's DirectNG iframe redirect. We switched to Hosted Fields because:
- We own the form layout and styling
- Token returned via JS callback (no page navigation)
- Clean popup integration with Flutter web
- Full CSS control

### Why a popup (not embedded iframe)

Flutter's DWDS (Dart Web Debug Service) sends continuous `postMessage` events to child iframes, which crashes Tranzila's SDK (`JSON.parse` on non-string payloads). A popup window is a top-level browsing context — no DWDS injection, clean callback.

---

## Flow

```
User clicks "Update card" / "Add card"
  |
  ├── Flutter fetches thtk from GET /api/company/payment-setup
  ├── Opens popup: /CreditCard/Authorize.html?lang=he&v={timestamp}
  |
  ├── Popup sends { type: 'ready' } to Flutter via postMessage
  ├── Flutter sends { type: 'init_data', thtk, terminal, cardholder... } back
  |
  ├── User enters card → clicks Save Card
  ├── fields.charge() → Tranzila servers
  ├── Tranzila callback fires
  |
  ├── Popup sends { type: 'tranzila_result', success, errors, transaction_response } to Flutter
  |   (sent for BOTH success and failure — so Flutter can always audit)
  |
  ├── Flutter receives postMessage:
  │   ├── Always: POST /api/company/payment-provider/audit (fire and forget)
  │   ├── On success: POST /api/company/payment-method → refresh billing
  │   └── On failure: show error toast
  |
  └── Popup auto-closes after 1.5s (success) or stays open (failure)
```

---

## File Structure

```
web/CreditCard/
├── Authorize.html         # Standard card entry (no 3DS)
├── AuthorizeCard3DS.html  # 3DS-enabled variant (extra cardholder fields)
├── authorize.css          # Shared styles
└── authorize.js           # Shared logic (init, charge, postMessage, error codes)

assets/data/
└── tranzila_response_codes.json   # SHVA/3DS error codes (en + he)

lib/widgets/company_config/
└── billing_payment_method_card.dart   # Manages popup lifecycle + postMessage
```

Flutter selects which HTML page to open based on `AppConfig.instance.tranzilaUse3ds`.

---

## postMessage Protocol

### Popup → Flutter: ready signal
```json
{ "type": "ready" }
```

### Flutter → Popup: init data (sensitive — uses origin-restricted targetOrigin)
```json
{
  "type": "init_data",
  "thtk": "w5bcd32...",
  "terminal": "dev123",
  "card_holder_name": "John Doe",
  "card_holder_email": "john@example.com",
  "phone_country_code": "972",
  "phone_number": ""
}
```

### Popup → Flutter: result (always sent — success and failure)
```json
{
  "type": "tranzila_result",
  "success": true,
  "errors": null,
  "transaction_response": { "token": "...", "card_mask": "...", ... }
}
```

---

## API Endpoints Used

| Step | Endpoint | Purpose |
|------|----------|---------|
| 1 | `GET /api/company/payment-setup` | Fetch fresh thtk (20 min TTL) |
| 2 | `POST /api/company/payment-provider/audit` | Log raw Tranzila response (fire and forget, always) |
| 3 | `POST /api/company/payment-method` | Save card token + metadata (success only) |

---

## Cache Busting (Three Layers)

1. **HTML page** — Flutter appends `&v={timestamp}` (ms since epoch) to the popup URL so the browser never serves a cached HTML page
2. **JS and CSS** — the HTML page loads `authorize.js` and `authorize.css` via dynamic `<script>` / `<link>` tags with `?v=` + `Date.now()`, busting the cache on every page load
3. **HTTP meta headers** — `Authorize.html` includes `Cache-Control: no-cache, no-store, must-revalidate`, `Pragma: no-cache`, and `Expires: 0` meta tags

---

## Security

- `AppKey` and `Secret` live in .NET config only — never in client code
- `thtk` generated server-side, short-lived (20 min)
- `thtk` and cardholder data sent via postMessage (not URL params) — not in browser history or server logs
- Raw card data never touches our servers or JavaScript
- `companyId` resolved from session on backend — never trusted from client
- Audit fires on every Tranzila interaction (success or failure) — swallowed on error to not block flow

---

## Error Handling

### Tranzila Hosted Fields errors (err.messages[])
Codes 10000-10017: missing fields, invalid terminal, bad thtk, etc. Shown as field-level errors.

### Transaction declined (transaction_response.success = false)
`processor_response_code` looked up in `tranzila_response_codes.json` with en/he translations. Fallback chain: errorMap → tx.error → generic "Payment failed".

### Popup blocked
Detected via null return from `window.open()`. Toast shown to user.

---

## 3DS Support (Two-Page Architecture)

| Page | 3DS | Extra fields |
|------|-----|-------------|
| `Authorize.html` | No | Card number, CVV, expiry only |
| `AuthorizeCard3DS.html` | Yes | + cardholder name, phone, email |

Flutter decides which page based on config. Both share `authorize.css` and `authorize.js`.
`force_txn_on_3ds_fail` hardcoded in the 3DS page (not a URL param — prevents client bypass).

---

## Configuration

```yaml
# assets/config/app_config_dev.yaml
payment:
  tranzilaTerminal: dev123
  tranzilaUse3ds: false

# assets/config/app_config_prod.yaml
payment:
  tranzilaTerminal: xpensedesk
  tranzilaUse3ds: true
```

Accessed via `AppConfig.instance.tranzilaTerminal` and `AppConfig.instance.tranzilaUse3ds`.

---

## Known Issues

- Chrome 146+ regex bug in Tranzila's `genfield.php` — console errors but no functional impact
- Tranzila's SDK iframe validation messages always appear in Hebrew regardless of `response_language` param
- Dev terminal 3DS enrollment status unconfirmed — see open questions in `current-work.md`

---

## Evolution

1. **v1** — `card-on-file-flow.md`: DirectNG iframe redirect approach (never shipped)
2. **v2** — `tranzila_hosted_fields_spec.md`: Hosted Fields POC with popup (shipped as POC)
3. **v3** — `credit-card-authorize-plan.md`: Production implementation (multi-language, 3DS, postMessage init, error codes JSON)
4. **v4** — Integrated into billing module: no dialog, direct popup from payment method card buttons, audit on all outcomes
