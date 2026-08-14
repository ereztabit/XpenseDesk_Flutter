# XpenseDesk API — Platform Admin Guide

How the **platform admin** role works in XpenseDesk, and the API contract for the
admin panel. Mission FS-1000.

> **Status:** implemented and tested on the backend as of 2026-08-14, live on dev.
> `GET /api/admin/companies` behaves as documented below. Not yet released to
> production — the schema migration has been applied to dev only.

Related: [authentication_client_guide.md](authentication_client_guide.md) ·
backend story `docs/admin-panel/admin-login-and-companies-management-story.md` ·
schema script `docs/admin-panel/fs-1000-admin-panel-schema.sql`

---

## 1. What a platform admin is

A platform admin is an **XpenseDesk staff account**, not a customer. It exists to
operate the product across all companies — the opposite of every other identity
in the system, which is scoped to exactly one company.

| | Company user (Manager / Employee) | Platform admin |
|---|---|---|
| Belongs to | a real customer company | no customer company |
| Sees | that one company's data | all companies |
| Created by | onboarding / invite | SQL runbook only |
| Logs in via | magic link or Microsoft | **the same two flows, unchanged** |
| Lands on | the normal app | the admin shell (`/admin`) |

### Roles

| RoleId | Name | Meaning |
|---|---|---|
| 1 | `Manager` | Company manager. **Note:** older SQL comments call this "Admin" — it is *not* a platform admin. |
| 2 | `Employee` | Company employee. |
| 3 | `PlatformAdmin` | XpenseDesk staff. Cross-company. |

`RoleId = 3` is the **single source of truth** for admin-ness on the client and
the server. There is no separate flag, and none is needed.

---

## 2. How the identity is modelled (and why it matters to clients)

An admin is a normal `Users` row with `RoleId = 3`, belonging to one hidden
**platform company**, identified by `Companies.IsPlatformCompany = 1` and nothing
else — its id is a surrogate key with no meaning and may differ between
environments, so never hardcode it. That company holds no subscription, no
expense cycles and no billing data, and is excluded from every customer-facing
list and nightly job.

This was chosen over a separate `AdminUsers` table so the authentication
pipeline stays untouched — magic link, Microsoft login and logout all work for
admins with **zero** changes to auth procs. Full reasoning is in the backend
story; it is not repeated here.

### The one consequence clients must respect

Because an admin sits inside a (hidden) company, **an admin session looks
structurally like a normal session.** It does not fail, and it does not report a
null company.

- **Route on `roleId == 3`. Never on a missing/empty company.** A null-company
  check will never fire and would silently drop an admin into the normal app.
- `GET /api/users/me` returns `companyName: "XpenseDesk Platform"` for an admin.
  That is an internal implementation detail — **never display it, never send it
  anywhere, never read its locale.**
- Cycle fields come back `null` for an admin, because the platform company has no
  cycles. Do not treat that as an error state.

---

## 3. Authentication — unchanged

Admins use the **existing** login endpoints with no new UI and no new routes.
Request and response shapes are identical to a company user's; see
[authentication_client_guide.md](authentication_client_guide.md) for full detail.

| Endpoint | Admin behaviour |
|---|---|
| `POST /api/auth/try-login` | Sends a magic link. Unchanged. |
| `POST /api/auth/login` | Exchanges login token for a session token. Unchanged. |
| `POST /api/auth/microsoft-login` | Works for admins too — SSO is not admin-restricted. Unchanged. |
| `POST /api/auth/logout` | Invalidates the session server-side. Unchanged. |

All four return the standard envelope:

```json
{ "success": true, "message": "Login successful.", "data": { "sessionToken": "…" } }
```

Authenticated calls carry the session token:

```http
Authorization: Bearer <sessionToken>
```

### Logout must be a real logout

`POST /api/auth/logout` revokes the session **server-side** — the token is dead
even if a copy was kept. It keys off the session token alone, so it works
identically for admin sessions. There is no admin-specific logout endpoint.

A failed logout call must still clear local state and return the user to login.

---

## 4. Detecting an admin — the routing decision

After login, call `GET /api/users/me` and branch on `data.roleId`.

```http
GET /api/users/me
Authorization: Bearer <sessionToken>
```

**Admin response (abridged):**

```json
{
  "success": true,
  "message": "User info retrieved successfully",
  "data": {
    "email": "admin@example.com",
    "fullName": "Platform Admin",
    "roleId": 3,
    "status": "Active",
    "languageId": 1,
    "languageCode": "en",
    "companyName": "XpenseDesk Platform",
    "currencyCode": "ILS",
    "timeZoneName": "Israel Standard Time",
    "cycleStartAt": null,
    "cycleEndAt": null,
    "cycleLabel": null
  }
}
```

Routing rule:

```
roleId == 3  ->  /admin
otherwise    ->  existing behaviour, unchanged
```

Both login paths (magic link and Microsoft) must run this same dispatch.

> **Note:** `/api/users/me` deliberately returns **no `companyId`** — it exposes
> no internal ids. So there is no company identifier for the client to
> accidentally depend on. `companyName` is the only company field present, and
> admins must ignore it.

**Safe by design:** `/api/users/me` also bootstraps the caller's draft expense
sheet. For an admin this is a no-op — sheet creation requires an open cycle, the
platform company has none, and `proc_OpenCompanyCycle` refuses to create one for
it. Do not remove that guard; it is what keeps this call harmless for admins.

---

## 5. `GET /api/admin/companies` — companies overview

Returns one row per **real** company. The platform company is excluded.

```http
GET /api/admin/companies
Authorization: Bearer <sessionToken>
```

### Response — `200 OK`

```json
{
  "success": true,
  "message": "Companies retrieved successfully",
  "data": [
    {
      "companyId": "3036b993-a22e-446f-abb9-7d4ef6311f58",
      "companyName": "XpenseDesk Demo Company",
      "creationDate": "2026-06-20T07:11:21Z",
      "paymentStatus": "Active",
      "isActive": true,
      "companyStatus": "Active",
      "userCount": 2,
      "expenseCount": 0
    }
  ]
}
```

| Field | Type | Notes |
|---|---|---|
| `companyId` | guid | Identifies the row. Not used for drill-down in V1. |
| `companyName` | string | |
| `creationDate` | ISO-8601 UTC | Format client-side; see §6. |
| `paymentStatus` | enum string | `PendingPayment` \| `Active` \| `Inactive`. Server-computed — see below. |
| `isActive` | bool | Whether the company is live. **Read this together with `paymentStatus`** — see below. |
| `companyStatus` | string | Company lifecycle status, e.g. `Active`. |
| `userCount` | int | All users in the company, active or not. |
| `expenseCount` | int | All expenses in the company. |

Ordering: newest first (`creationDate` descending). V1 has **no** sorting,
filtering, search, pagination, drill-down, export or editing — it is a static
table.

### `paymentStatus`

Computed server-side by the existing `fn_GetSubscriptionStatus`. **Display the
returned string; never re-derive payment state on the client.**

| Value | Means |
|---|---|
| `PendingPayment` | No subscription record yet. |
| `Active` | Active subscription, not expired. |
| `Inactive` | Subscription exists but is cancelled or expired. |

**`paymentStatus` alone is not enough to describe a company.** The underlying
function only considers companies that are live, so a **deactivated** company
falls through to `PendingPayment` — identical to a brand-new signup that never
paid. Use `isActive` to tell them apart:

| `isActive` | `paymentStatus` | Read as |
|---|---|---|
| `true` | `PendingPayment` | New or unpaid — never subscribed |
| `true` | `Active` | Paying customer |
| `true` | `Inactive` | Subscription lapsed or cancelled |
| `false` | *(any)* | **Deactivated** — ignore `paymentStatus`, it is not meaningful |

Surface deactivated companies distinctly rather than showing them as merely
unpaid.

### Errors

| Status | When |
|---|---|
| `401 Unauthorized` | Missing, invalid, expired or revoked session token. |
| `403 Forbidden` | Valid session, but `roleId != 3`. |

---

## 6. Language and formatting in the admin panel

Two separate concerns, same as everywhere else in the product.

**UI language — normal.** Full i18n, the same language picker, **default
English**, both `app_en.arb` and `app_he.arb`, RTL must work.

**Formatting locale — pinned to Israel.** Dates, times and amounts always use
Israel conventions (`14.8.2026`, Israel timezone, ILS/₪), because the admin has
no *customer* company to take a locale from.

- Feed a fixed Israel locale into the `format_utils.dart` extensions. Do not
  bypass the extensions.
- **Do not** read the locale off the platform company, even though `/me` returns
  its `currencyCode`/`timeZoneName`. Those values exist to satisfy NOT NULL
  columns and carry no product meaning.
- **Do not** fall back to `Localizations.localeOf(context)` — that is the UI
  language, and dates would flip to US format for an English reader. This is
  already a filed bug pattern in the client repo; do not reproduce it.

Revisit only if XpenseDesk ever serves non-Israeli companies.

---

## 7. Rules for future admin modules

The companies list is module #1. When adding module #2:

1. **Guard every admin endpoint on `roleId == 3`** server-side. Follow the
   existing manual-check convention (`HttpContext.GetRoleId()`); this codebase
   does not use `[Authorize(Roles=)]` anywhere.
2. **Never let cross-company data reach a non-admin-guarded endpoint.** Admin
   endpoints deliberately break per-tenant isolation; that is contained only by
   the role guard.
3. **Exclude the platform company** from anything that lists, bills, or sweeps
   companies — filter on `IsPlatformCompany = 0`. Never hardcode its id, in SQL
   or C#: the flag is the only source of truth, and a filtered unique index
   guarantees at most one row carries it.
4. **Reject `roleId == 3` on company-scoped endpoints.** An admin session carries
   a valid company context, so an unguarded company endpoint will silently serve
   an admin against the platform company instead of refusing them. This is the
   single most important guard in the design.
5. Client side: new routes live under `/admin`, wrapped in `AdminAuthGate`, and
   must not touch company-scoped providers.

## 8. Not available in V1

- **No admin creation/invite API.** Admin accounts are provisioned by SQL runbook
  only, to keep the attack surface for granting the role as small as possible.
  There is no UI to build for this.
- **No company drill-down**, edit, or any write operation from the admin panel.
- **No admin-specific login or logout endpoint** — the existing auth endpoints
  serve both identities.
