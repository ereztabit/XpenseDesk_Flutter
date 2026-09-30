// Shared helpers for the FS-1007 S3 manual QA scripts. Dev API only.
process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';
const API = 'https://localhost:7223/';

export async function call(method, path, body, token) {
  const res = await fetch(API + path, {
    method,
    headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) },
    body: body ? JSON.stringify(body) : undefined,
  });
  const json = await res.json().catch(() => ({}));
  if (!res.ok || json.success === false) throw new Error(`${method} ${path} -> ${res.status} ${JSON.stringify(json)}`);
  return json.data;
}

export async function signIn(email) {
  const d = await call('POST', 'api/auth/try-login', { email });
  const s = await call('POST', 'api/auth/login', { loginToken: d.magicLink.split('token=')[1] });
  return s.sessionToken;
}

export async function fileExpenses(token, n) {
  for (let i = 0; i < n; i++) {
    await call('POST', 'api/expenses', {
      expenseDate: new Date().toISOString().slice(0, 10), categoryId: 1, dynamicAmount: 10 + i,
      currencyCode: 'ILS', merchantName: `QA seed ${i + 1}`, isAiData: false,
    }, token);
  }
}

export async function makePaid(token) {
  await call('POST', 'api/onboarding/subscription', {
    paymentProviderResponse: { errors: null, transaction_response: {
      success: true, error: null, processor_response_code: '000', credit_card_last_4_digits: '4242',
      expiry_month: '12', expiry_year: '30', card_type_name: 'Visa', token: 'test-token-qa' } },
    billingPlanId: 2,
  }, token);
}

export async function status(token) {
  const s = await call('GET', 'api/users/me/free-receipts', null, token);
  return s.isLimited ? `${s.left} of ${s.allowance} free receipts left` : 'no limit';
}
