# XpenseDesk API — Support Impersonation Guide

How a platform admin connects as a company user, and the API contract the admin
panel builds against. Mission FS-1001.

> **Status:** implemented and tested on the backend as of 2026-08-15, live on
> dev (338/338 tests green, smoke excluded). Not released to production — the
> schema migration has been applied to dev only.

Related: [platform-admin-api-guide.md](platform-admin-api-guide.md) ·
[authentication_client_guide.md](authentication_client_guide.md) ·
backend story `docs/admin-panel/support-impersonation-story.md` ·
schema script `docs/admin-panel/fs-1001-impersonation-schema.sql`

---

## 1. The one thing to understand first

**Impersonation is a server concern. The app does not implement it.**

The panel asks for a link. The link has the *same shape as a magic link*
(`{frontendUrl}/login?token=...`), so it is redeemed by the client's existing
login callback with no new route and no new exchange logic. From that point the
session simply *is* the target user as far as every endpoint is concerned:
`GET /api/users/me` returns their profile, their role, their company, their
cycle. No screen, provider or service needs to know impersonation exists.

Only two things on the client are impersonation-aware:

1. **The banner** — driven by one new field, `impersonatorName` (§4).
2. **Where the token is stored** — it must not overwrite the admin's own
   session token (§5).

### Whose session is it?

The session belongs to the **admin**, and carries the target:

```
Sessions.UserId             = the platform admin   (who is really here)
Sessions.ImpersonatedUserId = the target user      (whose data is served)
```

Consequences that matter to a client author:

- **The target is never signed out.** Nothing is minted for them; their own
  sessions and login tokens are not read or written. They keep working in
  parallel. This is verified at the database level, not just asserted.
- **The admin's own session is untouched too**, so the admin panel keeps
  working in another tab while a connection is live.
- **Ending a connection is an ordinary `POST /api/auth/logout`** on the
  connected session. There is no stop endpoint.

---

## 2. `GET /api/admin/companies/{companyId}/users`

The people list for one company — the impersonation picker.

**Auth:** `RoleId = 3` only. 401 unauthenticated, 403 for anyone else.

**Order:** managers first (`roleId` 1), then employees (2), each by name
ascending. The server already returns this order, so an unfiltered render is
correct without client-side sorting.

**Response** — `data` is an array:

| Field | Type | Notes |
|---|---|---|
| `userId` | guid | pass this to §3 |
| `fullName` | string? | null if the user never onboarded |
| `email` | string | how the agent matches the caller to a row |
| `roleId` | int | 1 = Manager, 2 = Employee. **Never 3** — see below |
| `status` | string | invite lifecycle: `Pending` / `Active` / `Disabled` |
| `isActive` | bool | whether the account is enabled |
| `createdAt` | datetime | |
| `activationDate` | datetime? | null if never signed in |

```json
{
  "success": true,
  "message": "Company users retrieved successfully",
  "data": [
    { "userId": "1c4c…", "fullName": "Rina Manager", "email": "rina@acme.com",
      "roleId": 1, "status": "Active", "isActive": true,
      "createdAt": "2026-08-15T06:34:07.04", "activationDate": null },
    { "userId": "8790…", "fullName": "Dana Employee", "email": "dana@acme.com",
      "roleId": 2, "status": "Active", "isActive": true,
      "createdAt": "2026-08-15T06:34:07.35", "activationDate": "2026-08-15T06:34:07.49" }
  ]
}
```

### Two things the client must get right

- **Inactive users are included**, flagged by `isActive: false`. The panel hides
  them behind a checkbox (default off) and filters client-side — do not refetch.
  `status` and `isActive` are different things: a `Pending` user has never signed
  in; a `Disabled` one has and was switched off.
- **`roleId` is never 3.** Platform admins are filtered out server-side and the
  platform company is refused outright, so admin-on-admin impersonation is
  impossible rather than merely discouraged. Do not add a client-side filter for
  it — if one ever appears, that is a server bug worth surfacing.

---

## 3. `POST /api/admin/companies/{companyId}/impersonation/start`

Mints the connect link. **Auth:** `RoleId = 3` only.

**Request**

```json
{ "userId": "8790f97a-8783-443b-9a27-f8edaaeefa6c" }
```

**Response**

```json
{
  "success": true,
  "message": "Impersonation link created successfully",
  "data": {
    "loginUrl": "https://app.xpensedesk.com/login?token=4E567400-54CD-48B2-96F6-B8ED3DC38BD9",
    "targetUserName": "Employee User"
  }
}
```

| Field | Notes |
|---|---|
| `loginUrl` | Open in a **new tab**. Same shape as a magic link, so the existing `/login?token=` route redeems it. |
| `targetUserName` | Who the link actually connects as, per the server. Show it — it is the agent's last chance to notice they picked the wrong row. |

The company name is deliberately not echoed: the panel navigated from that
company to reach this call.

### `loginUrl` is a credential

It carries a login token that mints a session. Treat it as you would a password:
open it, do not log it, do not put it anywhere persistent. The server already
masks the field in its own audit log. The link lives **10 minutes** and is
multi-use within that window; the session it produces lives **1 hour** and is
**not renewable** — when it lapses the agent starts a new connection from the
panel.

### Errors

| Status | `errorCode` | When |
|---|---|---|
| 400 | — | `userId` missing or empty |
| 403 | `AdminImpersonationTargetNotAllowed` | target is in another company, deactivated, a platform admin, or does not exist |
| 403 | — | caller is not a platform admin, **or is already connected** (no chaining) |

The 403 body is deliberately identical for every target problem — the caller
learns nothing about ids they were not already shown. Do not try to distinguish
them in the UI; "This user cannot be connected to." is the whole answer.

### One connection at a time

Starting a connection **revokes the agent's previous one** (and expires any
unredeemed earlier link). A stale connected tab therefore starts returning 401
on its next call, which the existing global 401 handler already turns into a
redirect. That is the intended behaviour: the agent must never be looking at two
people at once and be unsure which is which.

---

## 4. `GET /api/users/me` — one new field

```jsonc
{
  "email": "dana@acme.com",       // the person being helped, as always
  "fullName": "Dana Employee",
  "roleId": 2,
  // …everything else unchanged…
  "impersonatorName": "Erez Ben David"   // NEW — null on an ordinary session
}
```

`impersonatorName` is the **only** thing the app learns about impersonation. Null
on every normal session, so no existing behaviour changes. When it is non-null,
render the persistent banner: the app is showing someone else's account.

Everything else on the response continues to describe the person being helped —
that is the point of connecting, and it is why the customer's own screens look
normal to them.

---

## 5. Token storage — the one real client design constraint

`AuthService` stores a single `session_token` in `SharedPreferences`, which on
web is `localStorage` and is **shared across every tab**. `AdminAuthGate` admits
on `roleId == 3`.

So if the impersonation token were written to that key, it would overwrite the
admin's own login in the same browser, `userInfoProvider` would resolve to the
employee, and **the admin panel would lock the agent out of their own session.**

The impersonation token is therefore stored **tab-scoped** (`sessionStorage` on
web). The admin tab has none and stays admin; the tab opened by the connect link
has one and is impersonated. Both live side by side and survive refresh.

Read path stays a single chokepoint — `AuthService.getSessionToken()` returns the
tab's impersonation token when there is one, otherwise the stored session token.
Every service keeps calling it unchanged. The **one** exception is
`AdminService`, the only service that talks to `/api/admin/*`: it asks for the
admin token explicitly, so panel calls are never impersonated.

Trade-off accepted: a connected session is bound to its tab and does not survive
being reopened elsewhere. For support work that is correct.

---

## 6. What gets logged

Nothing the client needs to send, but worth knowing when reading a support
incident:

- `ApiLog.UserId` is the **agent's** id for every call made while connected —
  support can never act under a customer's identity.
- `ApiLog.CompanyId` is the **target's** company, because that is where the
  request acted. A platform-company user acting inside a customer company occurs
  in no other flow, which is what makes an impersonated call identifiable.
- Application logs render the user as `<agent> as (<person>)`.

Known limitation, accepted deliberately: because `UserId` is the agent, an
impersonated action does **not** appear under the employee in
"everything this employee did" queries.
