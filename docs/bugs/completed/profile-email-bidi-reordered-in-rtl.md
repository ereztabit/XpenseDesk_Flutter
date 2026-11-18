# Bug: Profile email is reordered in Hebrew (RTL)

> **Status: done**
>
> Scope widened 2026-11-17: the same reorder hits every place an email is shown
> as text, so all 8 are fixed together through a shared `LtrText` widget:
> profile field, mobile menu, desktop menu, User Management list, admin company
> users table, Payments email column, Sheet Review header, onboarding Microsoft
> identity card.

Found in the manual QA dry run (2026-11-15, lane A - manager, desktop) on the
XpenseDesk Demo Company.

## Problem

In Hebrew, the read-only email on the profile screen is laid out right-to-left,
so leading or trailing punctuation jumps to the other end. The manager's email
`info@bambayadigital.com_` is shown as `_info@bambayadigital.com`. That is a
different-looking address from the one the user signs in with.

## Reproduce Steps

1. Connect as the manager of XpenseDesk Demo Company (email ends with `_`).
2. Open `/manager/profile` and switch the UI to Hebrew.
   -- Expected: the email reads exactly `info@bambayadigital.com_`, left-to-right.
   -- Actual: it reads `_info@bambayadigital.com`.

## Suggested Solution Approach

Emails (and similarly URLs and phone numbers) are always shown left-to-right,
whatever the UI language, and only their alignment follows the page direction.

## Suggested Fix

In `lib/widgets/profile/profile_identity_card.dart`, give the email
`SelectableText` `textDirection: TextDirection.ltr`. Keep the container aligned
to the start, so it still sits on the right in RTL. Look for other places that
render a raw email in RTL screens (users list, admin users list, payments) and
fix them the same way.

## Manual QA (2026-11-17, branch feature/email-ltr)

Local dev, Hebrew UI, XpenseDesk Demo Company, user `info@bambayadigital.com_`
(Admin User, connected from the admin panel; admin table as platform admin).

| # | Place | Width | Result |
|---|-------|-------|--------|
| 1 | Profile email field | 646 | pass - `info@bambayadigital.com_`, right-aligned |
| 2 | Mobile menu, under the name | 646 | pass |
| 3 | Desktop user menu | 800 | pass - centred |
| 4 | User Management list | 646 | pass |
| 5 | Admin company users table | 467 | pass - aligned under the column header |
| 6 | Payments email column | 800 | pass |
| 7 | Sheet Review header | 800 | pass |
| 8 | Onboarding Microsoft identity card | - | not reachable without a real Microsoft sign-in; covered by `test/widgets/ltr_text_test.dart` |

Before the fix, 1 and 2 were reproduced showing `_info@bambayadigital.com`.

## Resolution

Shipped in v1.47 (release 8c39ad1, 2026-11-17). New shared widget
`lib/widgets/ltr_text.dart` forces left-to-right layout and resolves alignment
against the page; used in all 8 places an email is shown as text. Tests:
`test/widgets/ltr_text_test.dart`. Commit f58c9ba.
