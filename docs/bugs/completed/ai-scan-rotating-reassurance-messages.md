# Bug: AI Receipt Scan Feels Stuck — Rotate Reassuring Messages During Analysis

> **Status: done**

## Problem

When the AI receipt analysis takes a while, the UI feels frozen — the scanning
overlay shows the same single message the entire time, so the user can't tell if
it is still working or stuck. We should cycle a friendly status message every few
seconds so it clearly feels alive and reassuring.

## Reproduce Steps

1. Add a new expense and upload a receipt that takes a while to analyze.
2. Watch the scanning overlay.
   -- Expected: the status text changes every ~5 seconds with reassuring copy
      ("We're almost there", "This is a tricky one", "Working with my best models
      for you", etc.).
   -- Actual: a single static line ("Analyzing...") that never changes, so a slow
      scan reads as frozen.

## Suggested Solution Approach

While `_isAnalyzing` is true, rotate through a small list of reassuring messages
on a ~5s timer. Keep the existing scan-line, pulse, and dot animations — only the
text line cycles. Suggested copy (final wording TBD with user):

- "Reading your receipt..."
- "This is a tricky one..."
- "We're almost there..."
- "Working with my best models for you..."
- "Just double-checking the numbers..."

## Suggested Fix

- `lib/screens/new_expense_screen.dart`:
  - The scanning overlay's text lives in `_buildScanningOverlay` (~line 737),
    currently a static `AppLocalizations.of(context)!.newExpenseAnalyzing`.
  - Add a `Timer.periodic(const Duration(seconds: 5), ...)` started when analysis
    begins (`_analyze`, ~line 355, where `_isAnalyzing = true`) and cancelled when
    it finishes (the `_isAnalyzing = false` paths ~lines 378/388/420) and in
    `dispose`.
  - Hold a `_scanMessageIndex` in state; advance it modulo the message-list length
    on each tick and `setState`. Wrap the message `Text` in an
    `AnimatedSwitcher` for a smooth fade between lines.
- Add ARB keys (en + he) for every message string FIRST, per the localization
  rule. Pull them into a `List<String>` inside `build` from `l10n`. The Hebrew
  copy should be its own natural phrasing, not a literal translation of the
  English jokes.

## Resolution

The scanning overlay now rotates through 8 reassuring status messages on a ~5s
timer while analysis runs, fading between lines.

- `lib/l10n/app_en.arb` + `lib/l10n/app_he.arb`: added `newExpenseScanMsg1`
  through `newExpenseScanMsg8` (Hebrew copy is its own natural phrasing, not a
  literal translation).
- `lib/screens/new_expense_screen.dart`: a `Timer.periodic` advances a
  `_scanMessageIndex` (modulo the message-list length, so it loops) while
  `_isAnalyzing` is true; cancelled on completion and in `dispose`. The overlay
  text is wrapped in an `AnimatedSwitcher` for a smooth fade. Existing scan-line,
  pulse, and dot animations are unchanged.

Verified by the user.
