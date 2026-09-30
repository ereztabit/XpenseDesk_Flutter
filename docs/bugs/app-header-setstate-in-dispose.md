# Bug: AppHeader calls setState while it is being disposed

> **Status: new**

## Problem

Leaving a screen while the desktop avatar menu is open (for example following a
link, or the browser's back button) throws a Flutter framework assertion in
debug builds: `_lifecycleState != _ElementLifecycle.defunct is not true`. There
is no visible effect for the user and release builds skip the assertion, but it
floods the debug console and hides real errors.

Found during the FS-1007 S3 browser checks on 2026-09-30.

## Reproduce Steps

1. Run the app in debug (`flutter run`), desktop width.
2. Open the avatar menu.
3. Without closing it, navigate away (enter another URL, or press back).
   -- Expected: the menu closes quietly.
   -- Actual: the console shows the assertion, thrown from
      `AppHeader._closeMenu` (`lib/widgets/header/app_header.dart:111`), called
      by `dispose` (`:258`).

## Suggested Solution

When the header is being disposed, remove the overlay entries without calling
`setState`. `_closeMenu` and `_closeCyclePopover` guard on `mounted`, which is
still true inside `dispose`, so give `dispose` its own teardown that only
removes the overlays.
