# Bug: Move Privacy Policy and Terms of Service to the Main Menu

> **Status: in progress**

## Problem

Privacy Policy and Terms of Service links currently live only in the footer, and
their tap handlers are dead stubs (empty `onPressed`). They should live in the
main navigation menu, placed directly **below Contact Support**.

## Reproduce Steps

1. Open the navigation menu (desktop popover or mobile menu sheet).
   -- Expected: Privacy Policy and Terms of Service entries appear below Contact
      Support.
   -- Actual: They are absent from the menu; they exist only in the footer and do
      nothing when tapped.

## Suggested Solution Approach

Add Privacy Policy and Terms of Service as menu entries, ordered below Contact
Support. Decide whether to also keep them in the footer or remove them there (see
related footer bug `footer-mobile-too-large-single-line.md`).

## Suggested Fix

- `lib/models/menu_items.dart` — add two new `MenuItem`s (`privacy-policy`,
  `terms-of-service`) after the `contact-support` action item. They are
  action-style (not role-gated, `isAction: true`), visible to all roles.
  Add the ARB keys first (`privacyPolicy`, `termsOfService` already exist for the
  footer — reuse them).
- `lib/widgets/header/desktop_menu.dart` and
  `lib/widgets/header/mobile_menu_sheet.dart` — handle the two new ids in the
  selection switch / item rendering.
- Destinations are TBD — there is no privacy/terms screen yet (see
  current-work.md "general environment": "create a real privacy policy" / "create
  a real terms and conditions"). Until those exist, wire to a placeholder route or
  external URL. Confirm target with the user.
- `lib/widgets/app_footer.dart` — remove the dead footer link stubs once the menu
  entries are wired (coordinate with the footer single-line bug).
