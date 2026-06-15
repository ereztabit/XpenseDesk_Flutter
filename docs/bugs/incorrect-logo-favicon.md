# Bug: Incorrect logo / favicon

> **Status: new**

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
broader PWA-installable task in `docs/in-progress/pwa-installable-app.md` - the
favicon can be fixed independently now, or folded into that effort.
