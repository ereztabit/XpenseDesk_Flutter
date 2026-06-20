# Bug: Organize the Manager Menu by Context

> **Status: completed**

## Problem

The manager navigation menu is a flat, ungrouped list of every destination
(Dashboard, Sheet Approvals, Payments, Profile, Expenses Analysis, Expenses
Detail Report, Company Configuration, User Management, plus the Logout / Contact
Support actions). As the manager feature set has grown, this flat list is hard to
scan. The items should be grouped by context (e.g. approvals/spend, reports,
management/settings, account/actions) with section separation.

## Reproduce Steps

1. Log in as a manager.
2. Open the navigation menu (desktop popover or mobile sheet).
   -- Expected: Items grouped into labelled sections by context.
   -- Actual: One long flat list with no contextual grouping.

## Suggested Solution Approach

Introduce a notion of menu groups/sections and assign each item to a context
group. Render section headers (or at least dividers) between groups in both the
desktop and mobile menus. Define the grouping with the user before implementing.

## Suggested Fix

- `lib/models/menu_items.dart` — add a `group`/`section` field to `MenuItem` (or
  return a grouped structure from `getItems`). Group candidates:
  - Work: Dashboard, Sheet Approvals, Payments
  - Reports: Expenses Analysis, Expenses Detail Report
  - Management: Company Configuration, User Management
  - Account: Profile, (Contact Support, Privacy/Terms), Logout
- `lib/widgets/header/desktop_menu.dart` and
  `lib/widgets/header/mobile_menu_sheet.dart` — render group headers / dividers.
  The desktop menu already inserts dividers ad hoc around action items; replace
  that with proper group-driven separation.
- Add ARB keys for any visible section headers (en + he) before writing widget
  code.

## Note

This was discussed previously but had never been filed as a bug doc — filed now.
Grouping definition needs user sign-off before implementation.
