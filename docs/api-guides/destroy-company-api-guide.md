# XpenseDesk API - Destroy Company (Platform Admin)

Mission FS-1005. The contract the admin panel's "Destroy company" action is built
against.

> **Status:** live in production since 2026-09-26 (backend a873610, app v1.34).

Related: [platform-admin-api-guide.md](platform-admin-api-guide.md) (who a
platform admin is, how the admin session works) - backend story
`docs/done/destroy-company-story.md` (backend repo). The schema script was applied
to prod and removed; see the backend's git history.

---

## 1. What it does

Permanently deletes one company and everything it owns:

- every SQL row: users, expenses, sheets, cycles, billing (subscription, payment
  method, invoices, payment logs), coupons, sessions, login tokens, API log and
  email rows;
- the company's receipt images in blob storage;
- first of all, any active Tranzila standing order is cancelled. If that fails,
  nothing is deleted.

There is no undo. Anyone signed in to the destroyed company is signed out on
their next call (401). Their emails are free to sign up again.

## 2. Who can call it

A platform admin (`RoleId = 3`) with their own admin session. Everyone else gets
403, including an impersonated (support-connect) session.

## 3. Request

    POST /api/admin/companies/{companyId}/destroy
    Authorization: Bearer <admin session token>
    Content-Type: application/json

    { "confirmationName": "Acme Ltd" }

`confirmationName` must equal the company's name exactly - compared after
trimming surrounding spaces, case-sensitive. It is the server-side half of the
typed confirmation; the client should also keep the Destroy button disabled until
the typed text matches.

Rate limit: `Moderated` (same as sign-in and support connect).

## 4. Responses

All responses use the standard envelope
`{ success, message, errorCode, data }`.

| Status | `errorCode` | Meaning | Client should |
|--------|-------------|---------|---------------|
| 200 | - | Destroyed. `data` is null. | Close the dialog, go back to the companies list. |
| 400 | - | `confirmationName` missing or empty. | Treat as a client bug. |
| 400 | `AdminDestroyConfirmationMismatch` | Name does not match. Nothing deleted. | Show "the name does not match". |
| 403 | - | Not a platform admin / impersonated session. | Generic error. |
| 404 | `AdminCompanyNotFound` | No such company (also returned for the platform company, which the panel never lists). | Show "company not found", refresh the list. |
| 429 | - | Rate limited. | Ask to wait and retry. |
| 502 | `DeleteCompanyTranzilaCleanupFailed` | Could not cancel the payment-provider standing order. Nothing deleted. | Show "billing cleanup failed, nothing was deleted, try again". |
| 502 | `DeleteCompanyFileCleanupFailed` | Could not delete the receipt images. Company data NOT deleted, safe to retry. | Same message as above, but "receipt images" instead of "billing". |
| 500 | - | Anything else. | Generic error. Do not assume anything was deleted - refresh the list. |

## 5. Audit trail

There is no separate deletion log. The admin's own API log row for this call
survives (it belongs to the platform company, which is never destroyed): who
called it, when, and the destroyed company's id in the path.
