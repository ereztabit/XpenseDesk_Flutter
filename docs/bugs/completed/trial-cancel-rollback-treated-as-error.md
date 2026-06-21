# Bug: Trial cancel rollback is treated as an error

> **Status: done**

## Resolution

Fixed and shipped in **v1.10** (commit `e2110ff`). The cancel call no longer
branches on the response shape; a successful cancel just validates `success`, and
the UI is driven by a fresh billing fetch.

- `lib/services/auth_service.dart` -> `cancelSubscription()` now returns `void`:
  it validates `success` via `_validateResponse` and no longer throws on
  `data: null` (the legitimate trial-rollback success).
- `lib/providers/billing_provider.dart` -> `BillingNotifier.cancelSubscription()`
  awaits the cancel then `refresh()`es from `GET /api/company/billing`, so the
  trial-vs-`CancellationRequest` state comes from the single source of truth, not
  the cancel response body.
- Plan/billing UI (`plan_selection_step.dart`, `billing_current_plan_card.dart`,
  `plan_card.dart`) verified to render the trial state cleanly with no error toast.

Verified by the user before close.

## Problem

When a company cancels its subscription while still in the free trial and before
any real charge has been taken, the backend now fully rolls back the opt-in: the
subscription is removed and the company returns to a clean trial. In that case the
cancel API responds with `HTTP 200`, `"success": true`, but `data: null` (there is
no subscription left to return).

The app currently treats a null `data` on this success response as a failure and
shows a cancellation error, even though the cancel actually succeeded. The user
should instead land back on the trial screen with no plan selected.

This is not a backend contract change. The cancel endpoint behaves exactly as
before for paying customers; only the trial pre-charge case returns an empty
subscription.

## Reproduce Steps

1. Sign in as a company that is still in its free trial and has opted into a plan
   but has not been charged yet (optionally via a coupon).
2. Open Company Config -> billing, and cancel the subscription.
3. The backend returns `200 { "success": true, "data": null }`.
   -- Expected: cancel is treated as success; billing screen refreshes and shows
      the trial state (the same screen a fresh trial company sees, plan selection
      available again, coupon released and re-enterable).
   -- Actual: app raises an error ("Invalid response from server" / cancellation
      error) because `data` is null.

## Suggested Solution Approach

On any cancel response where `success == true`, treat it as success regardless of
whether `data` is null. Do not branch on the cancel response body -- after a
successful cancel, reload billing from `GET /api/company/billing` and let that
single source of truth drive the UI:

- `subscription` present (`CancellationRequest`) -> existing "cancellation
  requested, access until end date" state.
- `subscription` null -> trial state.

## Suggested Fix

Root cause is in `lib/services/auth_service.dart` -> `cancelSubscription()`
(POST `/api/company/subscription/cancel`): it does
`if (data == null) throw const AuthException('Invalid response from server');`,
which fires on the legitimate trial-rollback success response.

Approach:
- Change `cancelSubscription()` so a null `data` on a successful response is not an
  error. Return type likely needs to become nullable (`BillingSubscription?`) or
  the method should signal "no subscription" rather than throw.
- Update `BillingNotifier.cancelSubscription()` in
  `lib/providers/billing_provider.dart`: instead of `_patchSubscription(updated)`,
  always `refresh()` from `GET /api/company/billing` after a successful cancel, so
  the trial-vs-CancellationRequest distinction is driven by the billing fetch, not
  the cancel response shape.
- Verify `lib/widgets/company_config/cancel_subscription_dialog.dart` and
  `billing_danger_zone_card.dart` render the trial state correctly when
  `subscription` comes back null, with no error toast.

## Related: subscription change log (only if the app shows it)

If the app renders the subscription change log
(`GET /api/company/subscription/change-log`), a rolled-back trial cancel adds a new
`Action` value: `"TrialRollback"` (alongside `Subscribe`, `Cancel`, `Resume`,
`SwitchPlan`). Map it to a user-facing label such as "Reverted to trial", and make
sure any unknown/unmapped action renders gracefully (generic label) rather than
blank or crashing.

## Source

Backend guide:
`C:\Projects\XpenseDesk\BackEnd\XpenseDeskServer\docs\trial-cancel-rollback-flutter-guide.md`
