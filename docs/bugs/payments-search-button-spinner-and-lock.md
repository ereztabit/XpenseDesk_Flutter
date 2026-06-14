# Bug: Payments search needs an in-button spinner and must block concurrent searches

> **Status: new**

## Problem

The payments-report Search action gives no in-progress feedback and does not
prevent a second search while one is running. Because the underlying DB query can
be slow, the user can fire repeated searches. The Search button should show a
spinner inside it while a search is in flight, and be disabled (no re-search)
until the current search completes.

## Reproduce Steps

1. Open the Payments Report (desktop filter card).
2. Tap Search, then tap Search again before results return.
   -- Expected: the button shows a spinner and is disabled until results arrive.
   -- Actual: no spinner; a second search can be triggered mid-flight.

## Suggested Solution Approach

Drive the Search button's loading state from the payments-result loading state,
and disable it while loading.

## Suggested Fix

- The result lives in `paymentsResultProvider` (AsyncNotifier);
  `resultAsync.isLoading` already reflects an in-flight fetch.
- `lib/widgets/payments/payments_filter_card.dart`: pass `isLoading` into the
  Search `AppButton` (`isLoading:` shows the spinner and disables tap). Wire it
  from the watched `paymentsResultProvider` loading state.
- Confirm `refresh()` / filter-set both flip `isLoading` so the lock covers the
  same-value force-refresh path (`_search` in `payments_report_screen.dart`).
- Mobile path is the tune-icon dialog Apply; apply the same guard if relevant.
