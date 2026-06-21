# Bug: Hide transaction history — defer to v2

> **Status: done**

## Problem

The transaction history feature is not ready for the MVP launch and should be
hidden from the UI, deferred to v2.

## Reproduce Steps

1. Navigate to where transaction history is shown (billing page / menu).
   -- Expected: transaction history is not visible.
   -- Actual: transaction history is shown.

## Suggested Solution Approach

Hide the transaction history entry point and any related section so it is not
reachable in production, without deleting the code (keep for v2).

## Suggested Fix

Locate the transaction history widget/section and its navigation entry point and
hide them (feature-flag or remove from the layout). Keep the implementation in
place for v2. Note this relates to the broader "spend history - user" backlog
item.

The "transaction history" is the **Billing History** tab (the 3rd tab) on the
Company Config screen (`/manager/company-config`). Only entry point. Approach —
unmount the tab, keep all code for v2:

- `lib/screens/company_config_screen.dart`: `TabController` length 3 -> 2; drop
  the History entry from the `tabs` list; drop the 3rd `TabBarView` child
  (`BillingHistoryTab`).
- `lib/router.dart`: drop the `?tab=history` -> index 2 mapping so a stale/direct
  URL falls back to General (tab 0) instead of an out-of-range index.
- Keep untouched for v2: `BillingHistoryTab`, `billingTransactionsProvider`, the
  `BillingTransaction` model, and the `billingHistory*` ARB keys. The provider is
  lazy, so once the tab is gone it never loads.

## Resolution

Unmounted the Billing History tab on the Company Config screen
(`lib/screens/company_config_screen.dart`): `TabController` length 3 -> 2,
`initialIndex` clamp `(0,2)` -> `(0,1)`, dropped the History tab button from the
`tabs` list and its `TabBarView` child, and commented out the now-unused
`BillingHistoryTab` import. In `lib/router.dart` the `?tab=history` mapping was
removed so a stale/direct URL falls back to General (tab 0) rather than an
out-of-range index.

All code kept in place for v2 (widget, `billingTransactionsProvider`, model, and
`billingHistory*` ARB keys); the provider is lazy and never fires once the tab is
gone. CR clean, security review found no new findings, `flutter analyze` clean on
touched files, prod-config release build succeeded. Shipped on `develop` as part
of the v1.7 bug batch (commit ebd9579).

Files: lib/screens/company_config_screen.dart, lib/router.dart.
