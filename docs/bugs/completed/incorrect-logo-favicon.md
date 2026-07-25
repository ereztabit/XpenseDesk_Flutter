# Bug: Incorrect logo / favicon

> **Status: done** (favicon. PWA install icons/manifest deferred — see Resolution.)

## Problem

The web app does not use the correct XpenseDesk logo as its favicon. The browser
tab shows the default/placeholder Flutter icon instead of the product logo, which
looks unbranded and unfinished for the MVP launch.

## Reproduce Steps

1. Build/run the web app and open it in a browser.
2. Look at the browser tab icon (and the bookmarked/home-screen icon).
   -- Expected: the XpenseDesk logo.
   -- Actual: the default Flutter favicon / wrong icon.

## Suggested Solution Approach

Replace the favicon and PWA icon assets with the correct branded XpenseDesk logo.

## Suggested Fix

In `web/`: replace `favicon.png` and the `icons/` PNGs (Icon-192, Icon-512, and
maskable variants), and make sure `web/index.html` `<link rel="icon">` and
`web/manifest.json` `icons` point at them. Provide the proper sizes (16/32/192/512)
so tab, bookmark, and install icons are all correct. Note: this overlaps with the
broader PWA-installable task in `docs/completed/pwa-installable-app.md` - the
favicon can be fixed independently now, or folded into that effort.

## Resolution

Root cause: the branding assets were **gitignored** under a "Web related" block in
`.gitignore` (`/web/favicon.png`, `/web/icons/`, `/web/manifest.json`), so they
were never committed and never reached the build/deploy — the browser fell back
to the default icon.

Fix (favicon): un-ignored `/web/favicon.png`, committed a 32x32 branded
`web/favicon.png` (2 KB), and added a `?v=2` cache-bust to the `<link rel="icon">`
in `web/index.html` so stale cached favicons refresh. Verified by the user.
Shipped on `develop` as part of the v1.7 batch (no version bump).

Still deferred (tracked under docs/completed/pwa-installable-app.md): the PWA
home-screen icons (`web/icons/Icon-*.png`) and `web/manifest.json` are also
gitignored and need un-ignoring + re-branding so install icons and the manifest
deploy. Not part of the browser-tab favicon fix.

Files: .gitignore, web/favicon.png, web/index.html.
