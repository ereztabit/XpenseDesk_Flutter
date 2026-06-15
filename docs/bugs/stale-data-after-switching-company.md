# Bug: User list (and other cached data) not refreshed after switching company

> **Status: new**

## Problem

After logging out and logging back in as a **different company**, the app shows the
new company's name and some new data, but the **users list still belongs to the
previous company** - including on the User Management screen. Cached Riverpod
provider data from the previous session is not cleared on logout/login, so stale
cross-tenant data leaks into the new session. This is a correctness and privacy
issue: one company's user roster is shown to another company.

## Reproduce Steps

1. Log in as a manager of Company A. Open User Management; note the user list.
2. Log out.
3. Log in as a manager of a **different** Company B.
4. Observe the dashboard (correct new company name) and open User Management.
   -- Expected: all data reflects Company B, including the users list.
   -- Actual: company name/some data is Company B, but the users list is still
      Company A's roster (seen across screens, including User Management).

## Suggested Solution Approach

On every session change (logout AND login), invalidate all session-scoped data
providers so nothing from the previous tenant survives into the new one.

## Suggested Fix

`AuthNotifier.logout()` (`lib/providers/auth_provider.dart`, ~line 79) only does
`state = null`; it does not invalidate downstream data providers. `usersListProvider`
(`lib/providers/users_provider.dart:42`) is only invalidated by the manual
pull-to-refresh in `lib/widgets/refreshable_scroll_view.dart:19`, never on session
change.

Centralize a "reset all session data" step that runs on logout and on a fresh
login, invalidating the tenant-scoped providers: `usersListProvider`, company /
billing, dashboard, payments, cycles, expense-sheet providers, etc. Audit every
`FutureProvider`/`Notifier` that caches company data and ensure it is invalidated
(or made auto-dispose + keyed so it cannot survive a tenant switch). Verify by
repeating the reproduce steps above across all data screens, not just User
Management.
