# CR -- Login-link sign-in races the startup session restore

Bug: [login-link-races-startup-session-restore.md](login-link-races-startup-session-restore.md)

## TL;DR

Clean -- no blockers, no should-fix. The change is logic-only: `authBootstrapProvider`
returns before `loadFromSession()` when the startup URL is `/login?token=<non-empty>`,
via a new pure predicate `AppRoutes.isLoginLink` (unit-tested). `router.dart` now
uses the new `AppRoutes.loginCallback` constant instead of the `'/login'` literal.
`AuthService.login` keeps a bad link's 401 away from the global handler
(`errorCode: 'LoginLinkInvalid'`, shown via the existing `invalidLoginLink` ARB key --
present in EN and HE), and the failure card's "Back to login" restores the old
session first.

## 0. Reuse audit

No widgets added. The predicate sits next to the existing route parser
`AppRoutes.parseAdminCompanyPath` in `lib/utils/app_navigator.dart` rather than in a
new utils file. Inventory check printed nothing:

```
for f in lib/widgets/*.dart; do grep -q "$(basename $f)" CLAUDE.md || echo "NOT IN INVENTORY: $(basename $f)"; done
(no output)
```

## 1. File-size audit

| File | Lines | Verdict |
|------|-------|---------|
| `lib/providers/auth_provider.dart` | 225 | OK -- provider module, not a widget (+9) |
| `lib/utils/app_navigator.dart` | 75 | OK |
| `lib/router.dart` | 318 | OK -- route table, pre-existing size, 1-line change |
| `lib/services/auth_service.dart` | ~760 | OK -- service module, not a widget |
| `lib/screens/login_callback_screen.dart` | 134 | OK |
| `test/utils/app_navigator_test.dart` | 25 | OK -- new |

## 2. Embedded private classes

None added.

## 3. Inline logic

The URL test is a pure function in `lib/utils/` (`AppRoutes.isLoginLink`), not
inlined in the provider.

## 4. Currencies & captions audit

No user-visible strings or amounts touched. Caption grep on changed files: empty.

## 5. Flutter hygiene

Grep for `withOpacity` / `EdgeInsets.only(left|right)` / `TextAlign.left|right` /
`arrow_back_ios` / raw `http.`: empty.

## 6. Responsive overflow risk

No layout changes.

## Security notes

Security review (2026-09-26): no findings. Re-run after the `AuthService.login`
401 change and the "Back to login" restore: no findings.

- Behavior change in the support-connect flow (FS-1001): that tab also opens on
  `/login?token=`, and previously restored the agent's own shared token in
  parallel. An admin `/me` (roleId 3) winning that race would have redirected the
  support tab to `/admin`. Now skipped too -- covered by manual test T4.
- "The link always wins" is the existing design, now deterministic: a login link
  signs the browser in as the link's owner. Link lifetime (redeemable for 5
  minutes) is server-side; nothing here widens it.
- The old token is not cleared on a link load, and the redemption's 401 no longer
  reaches the global handler, so a bad or expired link cannot sign the user (or a
  support agent) out. Previously it did -- a pre-existing flaw, fixed here because
  the chosen behavior depends on it.

## 7. Recommended fix plan

Nothing to fix. Follow-ups are in the bug doc (hardening, cross-tab).
