# Bug: Sheet detail is cached and never refetched on entry

> **Status: done**

## Resolution

Shipped in commit d4ac5ed, verified by the user. The Sheet Review screen (and
both dashboards) now invalidate their cached sheet providers in
`didChangeDependencies` (once per mount) instead of a post-frame callback, so
each entry re-fetches exactly once. `initState` is too early for a `ref`
inherited-widget lookup (it threw `dependOnInheritedWidget ... before initState
completed`); `didChangeDependencies` runs after initState but before the first
build, giving a single fresh fetch with no stale flash.

## Problem

When a manager opens a sheet from the dashboard, the sheet detail can show stale
data -- e.g. a sheet the employee has since changed still shows the old state
("Waiting for approval") until several manual refreshes. Watching the network in
dev tools shows NO API call when entering the sheet page: the data was loaded
once earlier and is served from cache.

Root cause: `sheetDetailProvider` is a plain cached `FutureProvider` (family by
sheet id). The first read populates it; every subsequent entry reuses the cached
value with no refetch. A manager acting on stale sheet state is a correctness
risk (they may approve/decline against data that no longer matches the server).

Desired: every time the user enters a sheet, fetch fresh data for it.

## Reproduce Steps

1. As an employee, change a sheet's state (e.g. resolve a declined line so it
   re-submits, or otherwise transition it).
2. As a manager, open that sheet from the dashboard.
   -- Expected: the sheet shows its current server state, fetched on entry.
   -- Actual: it shows the previously-cached state; only after several refreshes
      does it update. No API call fires on entry.

## Suggested Solution Approach

Make sheet detail re-fetch on every entry rather than serve a stale cached value.

## Suggested Fix

Options (pick per provider semantics):
- Invalidate on entry: `ref.invalidate(sheetDetailProvider(id))` when the Sheet
  Review screen (and the employee dashboard's selected-sheet view) mounts.
- Or make `sheetDetailProvider` `.autoDispose` so it is disposed when no longer
  watched and re-fetches on the next entry.
Confirm this does not introduce a double-fetch (see the duplicate-API-calls bug)
or a loading flash that regresses UX.
