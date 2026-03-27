// authorize.js — XpenseDesk card tokenization logic
// Loaded with a cache-busting timestamp by Authorize.html.

const params        = new URLSearchParams(window.location.search);
const lang          = params.get('lang') === 'he' ? 'he' : 'en';
const DEV           = window.location.hostname === 'localhost';

// Populated via init_data postMessage — not in URL
let thtk          = null;
let TERMINAL_NAME = null;

function devLog(direction, data) {
  if (!DEV) return;
  console.log('[Tranzila ' + direction + ']', JSON.parse(JSON.stringify(data)));
}

// Apply RTL and lang attribute before rendering
document.documentElement.dir  = lang === 'he' ? 'rtl' : 'ltr';
document.documentElement.lang = lang;

// ---------------------------------------------------------------------------
// Strings
// ---------------------------------------------------------------------------

const STRINGS = {
  en: {
    title:         'Add Payment Card',
    cardNumber:    'Card Number',
    cvv:           'CVV',
    expiry:        'Expiry',
    saveCard:      'Save Card',
    processing:    'Processing\u2026',
    bannerConnecting: 'Connecting\u2026',
    bannerReady:   'Enter your card details below.',
    errorDirectOpen: 'Please open this window directly from XpenseDesk.',
    bannerSuccess: 'Card saved successfully!',
    bannerError:   'Please fix the errors below.',
    errorMissing:  'Missing handshake token.',
    poweredBy:     'Powered by Tranzila',
    paymentFailed:     'Payment failed.',
    cardHolderName:    'Cardholder Name',
    phoneCountryCode:  'Country Code',
    phoneNumber:       'Phone',
  },
  he: {
    title:         '\u05D4\u05D5\u05E1\u05E4\u05EA \u05DB\u05E8\u05D8\u05D9\u05E1 \u05D0\u05E9\u05E8\u05D0\u05D9',
    cardNumber:    '\u05DE\u05E1\u05E4\u05E8 \u05DB\u05E8\u05D8\u05D9\u05E1',
    cvv:           'CVV',
    expiry:        '\u05EA\u05D5\u05E7\u05E3',
    saveCard:      '\u05E9\u05DE\u05D5\u05E8 \u05DB\u05E8\u05D8\u05D9\u05E1',
    processing:    '\u05DE\u05E2\u05D1\u05D3\u2026',
    bannerConnecting: '\u05DE\u05EA\u05D7\u05D1\u05E8\u2026',
    bannerReady:   '\u05D4\u05D6\u05DF \u05D0\u05EA \u05E4\u05E8\u05D8\u05D9 \u05D4\u05DB\u05E8\u05D8\u05D9\u05E1 \u05E9\u05DC\u05DA.',
    errorDirectOpen: '\u05E4\u05EA\u05D7 \u05D7\u05DC\u05D5\u05DF \u05D6\u05D4 \u05D9\u05E9\u05D9\u05E8\u05D5\u05EA \u05DE\u05EA\u05D5\u05DA XpenseDesk.',
    bannerSuccess: '\u05D4\u05DB\u05E8\u05D8\u05D9\u05E1 \u05E0\u05E9\u05DE\u05E8 \u05D1\u05D4\u05E6\u05DC\u05D7\u05D4!',
    bannerError:   '\u05D0\u05E0\u05D0 \u05EA\u05E7\u05DF \u05D0\u05EA \u05D4\u05E9\u05D2\u05D9\u05D0\u05D5\u05EA \u05DC\u05DE\u05D8\u05D4.',
    errorMissing:  '\u05D7\u05E1\u05E8 \u05D0\u05E1\u05D9\u05DE\u05D5\u05DF \u05D7\u05D9\u05D1\u05D5\u05E8.',
    poweredBy:     '\u05DE\u05D5\u05E4\u05E2\u05DC \u05E2\u05DC \u05D9\u05D3\u05D9 \u05D8\u05E8\u05E0\u05D6\u05D9\u05DC\u05D4',
    paymentFailed:     '\u05D4\u05EA\u05E9\u05DC\u05D5\u05DD \u05E0\u05DB\u05E9\u05DC.',
    cardHolderName:    '\u05E9\u05DD \u05D1\u05E2\u05DC \u05D4\u05DB\u05E8\u05D8\u05D9\u05E1',
    phoneCountryCode:  '\u05E7\u05D5\u05D3 \u05DE\u05D3\u05D9\u05E0\u05D4',
    phoneNumber:       '\u05D8\u05DC\u05E4\u05D5\u05DF',
  },
};
const S = STRINGS[lang];

// ---------------------------------------------------------------------------
// Error codes (loaded async — available by the time user submits)
// ---------------------------------------------------------------------------

const errorMap = {};
fetch('/assets/data/tranzila_response_codes.json')
  .then(r => r.json())
  .then(data => {
    data.codes.forEach(c => { errorMap[c.code] = { en: c.en, he: c.he }; });
  })
  .catch(e => console.error('Failed to load error codes:', e));

function resolveErrorMessage(code) {
  const entry = errorMap[String(code)];
  if (!entry) return null;
  return entry[lang] || entry.en || null;
}

// ---------------------------------------------------------------------------
// DOM (runs after parse — guards against DOMContentLoaded already having fired
// when this script is loaded asynchronously from <head>)
// ---------------------------------------------------------------------------

function onReady(fn) {
  if (document.readyState !== 'loading') { fn(); }
  else { document.addEventListener('DOMContentLoaded', fn); }
}

onReady(function () {

document.getElementById('page-title').textContent        = S.title;
document.getElementById('label-card-number').textContent = S.cardNumber;
document.getElementById('label-cvv').textContent         = S.cvv;
document.getElementById('label-expiry').textContent      = S.expiry;
document.getElementById('submit-btn').textContent        = S.saveCard;
document.getElementById('footer-powered-by').textContent = S.poweredBy;

// Cardholder fields are only present on AuthorizeCard3DS.html
function setLabel(id, text) { const el = document.getElementById(id); if (el) el.textContent = text; }
function getVal(id)          { const el = document.getElementById(id); return el ? el.value : ''; }

setLabel('label-card-holder-name',   S.cardHolderName);
setLabel('label-phone-country-code', S.phoneCountryCode);
setLabel('label-phone-number',       S.phoneNumber);

const banner    = document.getElementById('status-banner');
const submitBtn = document.getElementById('submit-btn');
const resultDiv = document.getElementById('result');

function showBanner(msg, type) {
  banner.textContent = msg;
  banner.className   = 'banner ' + type;
}

function showFieldError(field, msg) {
  const el = document.getElementById('errors_for_' + field);
  if (!el) return;
  if (msg) { el.textContent = msg; el.classList.add('visible'); }
  else      { el.textContent = ''; el.classList.remove('visible'); }
}

function clearFieldErrors() {
  ['credit_card_number', 'cvv', 'expiry'].forEach(f => showFieldError(f, ''));
}

// ---------------------------------------------------------------------------
// Entry point — wait for init_data from Flutter via postMessage
// ---------------------------------------------------------------------------

showBanner(S.bannerConnecting, 'info');

if (!window.opener) {
  showBanner(S.errorDirectOpen, 'error');
  console.error('Authorize.html: window.opener is null — page must be opened as a popup from XpenseDesk');
} else {
  const readyMsg = { type: 'ready' };
  devLog('▶ send', readyMsg);
  window.opener.postMessage(readyMsg, '*');

  // If init_data never arrives (e.g. opener closed before sending), show error
  const _initTimeout = setTimeout(function () {
    if (!thtk) showBanner(S.errorDirectOpen, 'error');
  }, 8000);

  window.addEventListener('message', function (event) {
    const data = event.data;
    if (!data || data.type !== 'init_data') return;
    clearTimeout(_initTimeout);
    devLog('◀ recv', data);

    thtk          = data.thtk     || null;
    TERMINAL_NAME = data.terminal || null;

    const _nameEl = document.getElementById('card_holder_name');
    if (_nameEl) {
      _nameEl.value = data.card_holder_name || '';
      const _emailEl = document.getElementById('card_holder_email');
      if (_emailEl) _emailEl.value = data.card_holder_email || '';
      const _phoneEl = document.getElementById('phone_number');
      if (_phoneEl) _phoneEl.value = data.phone_number || '';
      const _pccEl = document.getElementById('phone_country_code');
      if (_pccEl) {
        const pcc = data.phone_country_code || '';
        _pccEl.value = pcc ? '+' + pcc : '';
      }
    }

    if (!thtk || !TERMINAL_NAME) {
      showBanner(S.errorDirectOpen, 'error');
      console.error('Authorize.html: init_data missing thtk or terminal');
      return;
    }
    init();
  });
}

function init() {
  const fields = TzlaHostedFields.create({
    sandbox: false,
    fields: {
      credit_card_number: { selector: '#card-number', placeholder: '4580 4580 4580 4580', tabindex: 1 },
      cvv:                { selector: '#cvv',         placeholder: '123',                 tabindex: 2 },
      expiry:             { selector: '#expiry',      placeholder: '12/28',               version: '1' }
    },
    styles: {
      'input': { 'font-size': '15px', 'color': '#111827' }
    }
  });

  showBanner(S.bannerReady, 'info');
  submitBtn.disabled = false;

  // Page-level config injected by AuthorizeCard3DS.html to hardcode 3DS params
  const _pageConfig = window.TZLA_PAGE_CONFIG || {};

  submitBtn.addEventListener('click', function () {
    clearFieldErrors();
    submitBtn.disabled = true;
    submitBtn.innerHTML = '<span class="spinner"></span>' + S.processing;

    fields.charge({
      terminal_name:         TERMINAL_NAME,
      tran_mode:             'V',
      tokenize:              true,
      amount:                10,
      currency_code:         'ILS',
      thtk:                  thtk,
      response_language:     lang === 'he' ? 'Hebrew' : 'English',
      force_challenge:       _pageConfig.force_challenge !== undefined ? _pageConfig.force_challenge : (params.get('force_challenge') || 0),
      force_txn_on_3ds_fail: _pageConfig.force_txn_on_3ds_fail || params.get('force_txn_on_3ds_fail') || 'N',
      card_holder_name:      getVal('card_holder_name'),
      card_holder_email:     getVal('card_holder_email'),
      phone_country_code:    getVal('phone_country_code'),
      phone_number:          getVal('phone_number'),
    }, function (err, response) {
      submitBtn.disabled    = false;
      submitBtn.textContent = S.saveCard;

      if (err) {
        if (err.messages && err.messages.length) {
          err.messages.forEach(function (m) {
            showFieldError(m.param, m.message + ' (' + m.code + ')');
          });
          showBanner(S.bannerError, 'error');
        } else {
          showBanner('Error: ' + JSON.stringify(err), 'error');
        }
        return;
      }

      const tx = response.transaction_response;
      if (tx && tx.success) {
        // Warn if any expected fields are absent
        ['token', 'card_mask', 'card_type', 'expiry_month', 'expiry_year'].forEach(function (f) {
          if (!tx[f]) console.error('tranzila_result: missing field "' + f + '"', tx);
        });

        const cardTypeMap = { 1: 'MasterCard', 2: 'Visa', 3: 'Diners', 4: 'Amex', 5: 'Isracard', 6: 'Maestro' };
        const cardType = cardTypeMap[parseInt(tx.card_type)] || tx.card_type_name || 'Unknown';

        showBanner(S.bannerSuccess, 'success');
        resultDiv.style.display = 'block';
        resultDiv.innerHTML =
          '<table style="border-collapse:collapse;width:100%;font-size:13px;">' +
          '<tr><td style="padding:6px 10px;color:#6b7280;width:80px;">Type</td><td style="padding:6px 10px;font-weight:600;">' + cardType + '</td></tr>' +
          '<tr style="background:#f9fafb"><td style="padding:6px 10px;color:#6b7280;">Card</td><td style="padding:6px 10px;font-weight:600;font-family:monospace;">' + tx.card_mask + '</td></tr>' +
          '<tr><td style="padding:6px 10px;color:#6b7280;">Expiry</td><td style="padding:6px 10px;font-weight:600;">' + tx.expiry_month + '/' + tx.expiry_year + '</td></tr>' +
          '<tr style="background:#f9fafb"><td style="padding:6px 10px;color:#6b7280;">Token</td><td style="padding:6px 10px;font-weight:600;font-family:monospace;word-break:break-all;">' + tx.token + '</td></tr>' +
          '</table>';

        if (window.opener) {
          const resultMsg = {
            type:                 'tranzila_result',
            success:              true,
            transaction_response: tx
          };
          devLog('▶ send', resultMsg);
          window.opener.postMessage(resultMsg, '*');
        }
        setTimeout(function () { window.close(); }, 1500);
      } else {
        // Resolve human-readable error: errorMap → tx.error → generic fallback
        const code    = tx && tx.processor_response_code;
        const message = (code && resolveErrorMessage(code))
                     || (tx && tx.error)
                     || S.paymentFailed;
        showBanner(message, 'error');
      }
    });
  });
}

}); // onReady
