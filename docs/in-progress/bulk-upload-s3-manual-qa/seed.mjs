// FS-1007 S3 manual QA: creates fresh test users U1-U6 on the dev API and
// prints their emails. From the repo root:
//   node docs/in-progress/bulk-upload-s3-manual-qa/seed.mjs
import { call, signIn, fileExpenses, makePaid } from './lib.mjs';

const tag = Math.random().toString(16).slice(2, 6);

async function createCompany(name, admin, bulkOn) {
  const email = `qa.${name}.mgr.${tag}@xpensedesk.com`;
  const stage = await call('POST', 'api/onboarding/company', {
    companyName: `QA S3 ${name} ${tag}`, countryCode: 'IL', currencyCode: 'ILS', cutoverDay: 1,
    email, fullName: `QA ${name} Manager`, isMarketingConsent: false,
  });
  const v = await call('POST', 'api/onboarding/verify-otp', { otpKey: stage.otpKey, otp: stage.otp });
  const company = await call('GET', 'api/company', null, v.sessionToken);
  if (bulkOn) {
    await call('PUT', `api/admin/companies/${company.companyId}/configuration`, { isBulkUploadEnabled: true }, admin);
  }
  return { email, token: v.sessionToken };
}

async function inviteEmployee(name, label, managerToken) {
  const email = `qa.${name}.${label}.${tag}@xpensedesk.com`;
  const invite = await call('POST', 'api/users/invite', { emails: [email] }, managerToken);
  const s = await call('POST', 'api/auth/login', { loginToken: invite[0].loginToken });
  await call('POST', 'api/users/onboarding', { fullName: `QA ${name} ${label}`, languageId: 1 }, s.sessionToken);
  return { email, token: s.sessionToken };
}

const admin = await signIn('platformadmin@xpensedesk.com');

// trial: bulk on. Manager low (4 left), employee fresh (20 left), employee used up.
const trial = await createCompany('trial', admin, true);
const trialE1 = await inviteEmployee('trial', 'emp1', trial.token);
const trialE2 = await inviteEmployee('trial', 'emp2', trial.token);
await fileExpenses(trial.token, 16);
await fileExpenses(trialE2.token, 20);

// upgrade: bulk on. Manager used up - for "Upgrade now" and paying.
const upgrade = await createCompany('upgrade', admin, true);
await fileExpenses(upgrade.token, 20);

// nobulk: bulk off. Employee at 1 left.
const nobulk = await createCompany('nobulk', admin, false);
const nobulkE = await inviteEmployee('nobulk', 'emp', nobulk.token);
await fileExpenses(nobulkE.token, 19);

// paid: bulk on, on a paid plan, 22 expenses.
const paid = await createCompany('paid', admin, true);
await makePaid(paid.token);
await fileExpenses(paid.token, 22);

const users = {
  'U1 trial manager (4 left)': trial.email,
  'U2 trial employee (20 left)': trialE1.email,
  'U3 trial employee (used up)': trialE2.email,
  'U4 upgrade manager (used up)': upgrade.email,
  'U5 nobulk employee (1 left)': nobulkE.email,
  'U6 paid manager (no limit)': paid.email,
};
console.log(`Tag: ${tag}  (replace 3f45 with ${tag} in README.md)`);
for (const [label, email] of Object.entries(users)) {
  const s = await call('GET', 'api/users/me/free-receipts', null, await signIn(email));
  console.log(`${label.padEnd(30)} ${email}  ${s.isLimited ? `${s.left} of ${s.allowance} left` : 'no limit'}`);
}
