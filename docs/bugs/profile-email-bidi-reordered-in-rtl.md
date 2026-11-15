# Bug: Profile email is reordered in Hebrew (RTL)

> **Status: new**

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
