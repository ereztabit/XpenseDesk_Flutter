# Support Impersonation - Frontend Spec

Status: BUILT 2026-08-15. Implemented against the live backend; `flutter analyze`
clean and `flutter build web` green. **Not committed** - awaiting manual QA.

Not browser-verified by Claude: port 8080 was already serving the owner's own dev
instance (left untouched), and a second instance could not reach the API from the
sandboxed browser because the dev API's certificate is self-signed and untrusted
there. The flows below are therefore built and statically verified, but the
click-through is the owner's QA pass.

> Mission: FS-1001 (backend: `C:\Projects\XpenseDesk\BackEnd\XpenseDeskServer\docs\admin-panel\support-impersonation-story.md`)

An admin on a support call opens the admin panel, drills from the companies list
into a company, sees its employees, and clicks **Connect** next to the caller. A
new tab opens running the app exactly as that employee sees it, with a
permanent banner saying whose account is on screen.

## The governing constraint: the app does not learn what impersonation is

Impersonation is a server concern. The link the panel produces has the **same
shape as a magic link**, so it is redeemed by the existing
[login_callback_screen.dart](../../lib/screens/login_callback_screen.dart) with
no new route, no new exchange logic, and no change to any screen, provider or
service that serves employee or manager features.

Two additions to the app are unavoidable, and both are deliberately thin:

1. **The banner.** Only the client can render it. It is driven by a single new
   `impersonatorName` field on the user-info payload - the app reads one field
   and renders one widget. No screen becomes impersonation-aware.
2. **Where the session token is stored.** See below - this is the one piece of
   real thinking on the client side.

## Token storage - why this needs care

`AuthService` keeps one `session_token` key in `SharedPreferences`
([auth_service.dart:26](../../lib/services/auth_service.dart:26)), which on web
is `localStorage` and therefore **shared across every tab**. `AdminAuthGate`
admits on `userInfo.roleId == 3`
([admin_auth_gate.dart:38](../../lib/widgets/admin/admin_auth_gate.dart:38)).

So if the impersonation token were written to that key, the impersonated session
would overwrite the admin's own login in the same browser, `userInfoProvider`
would resolve to the employee, and **the admin panel would lock the admin out of
their own session** - breaking the mandatory "panel keeps working in parallel"
guardrail.

Fix: an impersonation token is stored **tab-scoped** (`sessionStorage` on web),
not in `SharedPreferences`. The admin tab has none and stays admin; the tab
opened by the Connect link has one and is impersonated. Both live side by side
and survive refresh.

The read path stays a single chokepoint - `AuthService.getSessionToken()`
returns the tab's impersonation token when there is one, otherwise the stored
session token. Every service keeps calling it unchanged. The one exception is
`AdminService`, the only service that talks to `/api/admin/*`
([admin_service.dart:23](../../lib/services/admin_service.dart:23)): it asks for
the admin token explicitly, so panel calls are never impersonated.

Trade-off accepted: an impersonated session is bound to its tab and does not
survive being reopened elsewhere. That is correct for support.

## Loading the people list — why the company id travels with the rows

`AdminAuthGate` inflates its child **inside its own `build`**, so an
`initState` on any screen it gates runs during the build phase. Writing to a
provider there throws *"Tried to modify a provider while the widget tree was
building"* — which is exactly what happened on the first QA click.

So the load is scheduled in a post-frame callback. That alone would let the
first frame paint the previously-opened company's people under the new
company's name, because `adminCompanyUsersProvider` is `keepAlive`. Rather than
fix that by timing, the state carries its own company id
([AdminCompanyUsers]) and `AdminCompanyUsersQuery` renders nothing until it
matches the company on screen — a mismatch reads as "still loading", never as
"this company has no people".

The guard is on the data, so it holds regardless of when the load is scheduled.

## The company module, and why the id is in the URL

The people list is the **first tab of a company module**
(`/admin/companies/{companyId}/users`), not a standalone screen. Later tabs
(billing, cycles, config) are another entry in `_tabs` plus another path
segment — the shell and the routing do not change.

The company id lives in the **path**, not in route arguments. Arguments are null
on a cold load, so refreshing or pasting a company link dropped the agent back
at the list — which is what QA hit. The tab is in the path too, so a future
second tab is a URL an agent can share rather than a click they have to
describe.

The company **name** is resolved from the already-loaded companies list rather
than passed in: it costs no extra call, and it is the only thing that survives a
refresh.

## Scope

| # | Piece | Notes |
|---|---|---|
| 1 | `/admin/companies/:id/users` screen | New admin module. The companies table is read-only with no drill-down today ([admin_companies_screen.dart:9](../../lib/screens/admin_companies_screen.dart:9)); a row click becomes a navigation. Reuses `StickyReportTable`, `AdminHeader`, `ConstrainedContent`, `AppButton`. |
| 2 | List plumbing | `AdminCompanyUserRow` model, `AdminService.getCompanyUsers()`, notifier + derived view provider in `admin_provider.dart`, added to `adminCachedProviders` so disconnect invalidates it. |
| 3 | Order + inactive toggle | Managers then employees, name asc within each (the API already returns this order). "Show inactive" checkbox, **default off**. Client-side over one payload, matching the companies table. |
| 4 | Connect action | A labelled **Connect** button per person (not an icon), `AdminService.startImpersonation(userId)` -> opens the returned `loginUrl` in a new tab, with the link also copyable as a popup-blocker fallback. The button is wrapped in `SelectionContainer.disabled`: the row sits inside `StickyReportTable`'s `SelectionArea`, and an `ElevatedButton` restyles on hover, which would re-register its label as a selectable on every mouse move and trip `SelectableRegion: _selectable == null is not true`. Taking it out of the selection tree removes the hazard without making the row stateful. |
| 5 | Tab-scoped token in `AuthService` | Impersonation-aware `getSessionToken()`, explicit admin-token accessor, `sessionStorage`-backed write. No screen touches this. |
| 6 | Impersonation banner | Persistent, in `AppHeader` (the impersonated side, **not** `AdminHeader`), showing the target's name. The existing disconnect ends it. |
| 7 | Revoked-impersonation UX | Nothing new: a superseded token 401s and the existing global handler nulls user state and redirects. Verify the message reads sensibly. |
| 8 | Housekeeping | EN + HE ARB keys first, RTL checklist, `/code-review` pass, this spec to `docs/completed/` on ship. |

Roughly 8-10 new files plus ~5 edits; items 1 and 4 are the only new user-facing
surfaces.

## Out of scope

- Any change to employee/manager screens, providers or services.
- Any client-side notion of *what* impersonation permits - permissions are the
  target's, resolved server-side.
- A "stop impersonating" mechanism beyond the existing disconnect.
