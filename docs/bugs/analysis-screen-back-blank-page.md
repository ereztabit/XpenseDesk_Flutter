# Bug: Analysis Screen — Back Button Leads to Blank Page on Direct URL Landing

## Problem

When a user lands directly on `/manager/analysis` (e.g., via a bookmarked URL, a shared link, or a browser refresh), pressing the **Back** arrow button renders a blank page.

The back button calls `Navigator.of(context).pop()`. On web, direct-URL navigation means there is no prior route in the Navigator stack. `pop()` with an empty stack either pops the `AuthGate` shell (leaving a blank scaffold) or fails silently — either way the user is stranded.

This screen is opened from multiple entry points:
- Manager dashboard — "View Analysis" button
- Cycle expenses report screen — analysis drill-down link
- Possibly deep links / notifications in the future

The bug manifests **only** on direct URL access (no back-stack). Users who arrive via in-app navigation are unaffected because `pop()` returns them to the previous route as expected.

## Reproduce

1. Open the app and log in as a manager.
2. In the browser address bar, navigate directly to `/manager/analysis`.
3. Press the back (`←`) button in the screen header.
4. **Result:** Blank page (or the AuthGate shell with no content).
5. **Expected:** Navigate to `/manager/dashboard` (the logical "home" for managers).

## Suggested Solution

Replace the unconditional `Navigator.of(context).pop()` with a safe fallback:

- If the Navigator **can pop** (i.e., there is a prior route in the stack), call `pop()` as today.
- If the Navigator **cannot pop** (direct-URL landing, stack depth = 1), push-replace to `/manager/dashboard` instead.

Pseudocode:
```
if (Navigator.of(context).canPop()) {
  Navigator.of(context).pop();
} else {
  Navigator.of(context).pushReplacementNamed('/manager/dashboard');
}
```

This pattern should be applied consistently to any other screen that has a manual back button and can be reached via direct URL.

**File:** `lib/screens/expenses_analysis_screen.dart` — the `IconButton` with `onPressed: () => Navigator.of(context).pop()` at the back-button in the filter header row.
