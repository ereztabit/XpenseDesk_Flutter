# Bug: Duplicate API calls on normal dashboard load

> **Status: new**

## Problem

On a normal dashboard load, several endpoints are requested twice for no reason:
`queue/all` and the `expense-sheet` detail call each fire x2. Wasteful (extra
load, latency) and a smell that a provider is watched in two places or a rebuild
re-triggers the fetch.

## Reproduce Steps

1. Open the manager dashboard (and/or the employee dashboard) with the network
   tab open.
2. Observe `queue/all` and `expense-sheet` (sheet detail) each requested twice on
   the initial load.
   -- Expected: one request per resource per load.
   -- Actual: duplicate requests.

## Suggested Solution Approach

Find why each provider resolves/fetches twice on first load and dedupe.

## Suggested Fix

Investigate before asserting a fix. Likely causes:
- The same `FutureProvider`/family watched from two widgets that both build on
  first frame, or
- An `initState` `ref.invalidate(...)` combined with the first `watch` causing a
  load + immediate reload, or
- A parent rebuild (e.g. selection bootstrapping via post-frame callback) that
  re-triggers the family with a new arg then the resolved arg.
Trace the watchers of `mySheetsProvider` / the queue provider and the sheet
detail provider; coordinate with the sheet-detail-stale-on-entry fix so the
"refetch on entry" change does not itself create a second call.
