# Bug: Budget id taken from the URL is not validated

> **Status: done**

Found in the PC-1 (FS-1012) finish code review, 2026-11-18. Fix in PC-2 (FS-1013).

## Problem

The budget page reads the budget id straight from the URL (`/budgets/<id>`) and
puts it, unchecked and unencoded, into API paths such as `/api/budgets/<id>`. A
crafted link (for example `/budgets/..%2Fsomething`) makes the app call a
different API path with the user's session token. Impact is low - same origin,
and the server still authorizes every call - but a malformed id should never
reach the API, and today it shows a generic load error instead of "not found".

## Reproduce Steps

1. Signed in, open `/budgets/not-a-guid` (or a percent-encoded path segment).
   -- Expected: the app treats it as an unknown budget without calling the API
      with that text.
   -- Actual: the text is sent as part of the API path.

## Suggested Solution Approach

Only a well-formed budget id (a GUID) is ever routed to the budget page or sent
to the API; anything else lands on the Budgets list.

## Suggested Fix

- `lib/utils/app_navigator.dart:41` `parseBudgetPath`: return null unless the
  segment is a GUID.
- `lib/services/budget_service.dart:68` and `:76`: build the path with
  `Uri.encodeComponent(budgetId)` as a second guard.
- Add the non-GUID case to `test/utils/sheet_nav_utils_test.dart`
  (`AppRoutes.parseBudgetPath`).

## Resolution

Fixed in FS-1013 PC-2, shipped as v1.50 (2026-11-18). `AppRoutes.parseBudgetPath`
(`lib/utils/app_navigator.dart`) accepts a GUID only; every budget API path in
`lib/services/budget_service.dart` is built with `Uri.encodeComponent`. Tests in
`test/utils/sheet_nav_utils_test.dart` and `budget_utils_test.dart`. A non-GUID
path now falls to the unknown-route screen - filed separately as
`docs/bugs/unknown-route-shows-login-to-signed-in-user.md`. Commit 62f4d42.
