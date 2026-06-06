# Bug: Users module looks too dense on mobile

> **Status: new**

## Problem

On mobile (narrow viewport) the Users / team management module feels cramped.
Rows, avatar, name/email, badges and the actions menu are packed tightly with
little breathing room, making the list harder to scan.

## Reproduce Steps

1. Log in as a manager on a narrow / mobile viewport (< 600px).
2. Open the Users screen.
   -- Expected: comfortable spacing, clear separation between user rows.
   -- Actual: the layout is dense -- tight padding, small gaps between the name
      row, email and the wrapped status/role badges.

## Suggested Solution Approach

Loosen the mobile layout: more vertical padding per row, clearer separation
between rows, and more spacing between the name/email block and the badge row.

## Suggested Fix

The mobile branch is `_buildMobileLayout` in
`lib/widgets/users/user_list_item_widget.dart` (padding `12/12`, `SizedBox`
height 2 between name and email, `Wrap` spacing 8 for badges). Increase row
padding/spacing and consider a divider or larger gap between list items. The list
container with the fixed `height: 600` in
`lib/screens/users_screen.dart` and `lib/widgets/users/user_list_card.dart` may
also need review for mobile.
