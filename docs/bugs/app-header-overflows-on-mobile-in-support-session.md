# Bug: App header overflows on mobile during a support session

> **Status: new**

## Problem

On a phone-width screen (375px), when a platform admin is connected as a user
("connect as" support session), the top header row does not fit: the orange
support chip plus the cycle-days chip push the XpenseDesk logo past the right
edge. The logo is cut off and covered by Flutter's yellow-and-black overflow
stripe. It shows on every screen of the connected session, so every support
call on mobile looks broken.

Ordinary (non-support) sessions are not affected - the support chip is what
tips the row over.

Found in FS-1010 manual QA, 2026-11-15 (spec docs/completed/company-modules-and-categories-spec.md, Manual QA run 1, finding 5).

## Reproduce Steps

1. Sign in as a platform admin, open a company, and "Connect as this person" on
   any user.
2. In the connected tab, set the viewport to 375x812 (mobile).
3. Open any screen (dashboard, company configuration, ...).
   -- Expected: hamburger, bell, support chip, days chip and logo all fit, or
      the lower-priority items shrink / hide.
   -- Actual: the row overflows by 18-21px on the right; the logo is clipped
      under the overflow stripe. The debug console shows "A RenderFlex
      overflowed by 18 pixels on the right" from
      lib/widgets/header/app_header.dart:303 (the header Row), in both LTR and
      RTL.

## Suggested Solution Approach

On narrow screens the header must always fit. During a support session the
support chip matters most; the days chip (or the logo's wordmark) can give way.

## Suggested Fix

In `AppHeader` (lib/widgets/header/app_header.dart, the Row at ~303), when
`context.isNarrow` and a support session is active: collapse the days chip to
its icon or drop it, or show the logo mark without the wordmark. Alternatively
wrap the middle items in `Flexible` with ellipsis. Needs a quick check of what
the header holds for manager vs employee, since the manager header has more
items.
