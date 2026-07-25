# Bug: Billing Screen Does Not Refresh After Renewing a Subscription

> **Status: new**

## Problem

After renewing (resuming) a subscription, the billing screen continues to show
the old state. The user must reload the page or navigate away and back to see the
subscription reflected as active/renewed. The screen should update immediately
once the renew action succeeds.

## Reproduce Steps

1. Open the billing screen for a company whose subscription is canceled / about to
   end (Company Config -> billing).
2. Renew / resume the subscription (confirm the resume dialog).
   -- Expected: the billing card updates immediately to the renewed/active state.
   -- Actual: the card still shows the pre-renew state until a manual reload.

## Suggested Solution Approach

After the renew/resume call succeeds, the billing data provider must be
invalidated (or refreshed) so the UI rebuilds from the new server state -- the
same pattern other actions use after a successful mutation.

## Suggested Fix

Investigate (not yet pinned to a line):
- `lib/widgets/company_config/resume_subscription_dialog.dart` -- on success, the
  caller should `ref.invalidate(billingProvider)` (or call the provider's refresh)
  before/after closing the dialog.
- The call site in `lib/screens/company_config_screen.dart` (or the card that
  launches the dialog, e.g. `billing_current_plan_card.dart` /
  `billing_danger_zone_card.dart`) -- ensure the success path re-reads billing
  state rather than relying on cached data.
- `lib/providers/billing_provider.dart` -- confirm there is an invalidate/refresh
  entry point and that the renew flow calls it.

Cross-check against the cancel flow (`cancel_subscription_dialog.dart`), which may
already refresh correctly -- mirror that behavior for renew.
