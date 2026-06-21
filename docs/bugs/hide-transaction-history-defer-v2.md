# Bug: Hide transaction history — defer to v2

> **Status: new**

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
