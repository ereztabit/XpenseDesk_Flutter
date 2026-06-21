# PWA — Installable XpenseDesk (home-screen icon)

Status: **planned, not started**

## Goal

Let users **install** the XpenseDesk web app to their device — a home-screen /
desktop icon that opens in its own standalone window (no browser chrome), branded
as XpenseDesk. "PWA" (Progressive Web App) is the right term.

## Current state (checkup)

This is a Flutter **web** app, so the PWA baseline already exists:
- `web/manifest.json` is present with `display: standalone` → the browser *can*
  already offer "Install".
- `flutter build web` auto-generates a service worker (`flutter_service_worker.js`)
  → offline caching + installability criteria are met.

**But it's unbranded / default Flutter scaffold:**

| Item | Current | Problem |
|------|---------|---------|
| `manifest.json` `name` / `short_name` | `"xpensedesk_flutter"` | shows the dev package name on the install prompt / icon label |
| `manifest.json` `description` | `"A new Flutter project."` | default |
| `manifest.json` `theme_color` / `background_color` | `#0175C2` (Flutter blue) | not brand; should be brand purple / app background |
| `manifest.json` `orientation` | `portrait-primary` | locks desktop/tablet to portrait — likely wrong for a desktop-first web app |
| `web/favicon.png` | ✔ branded 32×32 (shipped) | done — browser-tab favicon fixed |
| Icons (`web/icons/Icon-*.png`) | default Flutter logo | not XpenseDesk (and gitignored — see Blocker) |
| `index.html` `<meta description>` | `"A new Flutter project."` | default |
| `index.html` `apple-mobile-web-app-title` | `"xpensedesk_flutter"` | iOS home-screen label is the package name |
| `index.html` `apple-touch-icon` | `icons/Icon-192.png` (default) | iOS uses the Flutter logo |
| `<title>` | `XpenseDesk` ✔ | already branded |
| loader spinner | brand colours (`#362B71`) ✔ | already branded |

**Brand source available:** `assets/images/xpensedesk-main-logo-trans.png` (the in-app logo) — use it to
generate the icon set.
**No icon tooling yet:** `pubspec.yaml` has no `flutter_launcher_icons`.

Brand colours (from `lib/theme/app_theme.dart`):
- `primary` = `#362B71` (deep navy-purple) — proposed `theme_color`
- `primaryDark` = `#2B2462`
- `background` = `#F7F7FC` — proposed `background_color` (matches the loader bg / app)

Related backlog item this subsumes: *"need to replace the icon of the webpage"*
(favicon) under `## general environment` in `current-work.md`.

## ⚠️ Blocker found (2026-06-21): PWA assets are gitignored

`.gitignore` excludes the PWA branding assets under a "Web related" block, so they
were **never committed and never deployed** — the "manifest.json is present" note
above is only true locally:

```
# Web related
/web/icons/
/web/manifest.json
```

Consequences on prod today: `<link rel="manifest" href="manifest.json">` and the
icon refs **404**, so the app is **not actually installable** in production and the
home-screen/install icons fall back to defaults — regardless of any branding work.

**`web/favicon.png` has already been un-ignored and shipped** (the browser-tab
favicon bug, commit `eb7232f`), so only `web/icons/` and `web/manifest.json` remain
ignored.

**First step for this task — must happen before any branding lands:** remove
`/web/icons/` and `/web/manifest.json` from `.gitignore` and commit the (branded)
files so they reach the build/deploy. Without this, none of the scope below ships.

## Scope

1. **Branded `manifest.json`** — `name`: "XpenseDesk", `short_name`: "XpenseDesk",
   real `description`, `theme_color: #362B71`, `background_color: #F7F7FC`,
   `display: standalone`, drop/relax `orientation` (use `any` or omit for desktop),
   keep the 4 icon entries (standard + maskable) but point at branded icons.
2. **Branded icon set** from `assets/images/xpensedesk-main-logo-trans.png`:
   - `web/icons/Icon-192.png`, `Icon-512.png` (standard, transparent ok)
   - `web/icons/Icon-maskable-192.png`, `Icon-maskable-512.png` — **maskable needs
     ~10–20% safe-zone padding** so Android's circle/squircle mask doesn't crop the
     logo; use a solid brand background, not transparent.
   - `web/favicon.png` (and ideally a 32/16 favicon)
   - iOS `apple-touch-icon` (180×180 recommended) referenced from `index.html`
   - **Recommend** adding `flutter_launcher_icons` (dev dep, web target) to generate
     these from one source PNG, vs hand-exporting. Decide in open questions.
3. **`index.html` meta polish** — real `description`,
   `apple-mobile-web-app-title: "XpenseDesk"`, `apple-touch-icon` → branded 180px,
   add `<meta name="theme-color" content="#362B71">`, review
   `apple-mobile-web-app-status-bar-style`.
4. **Service worker / updates** — Flutter generates the SW automatically; document
   the cache-update behaviour (new version is picked up on next load). **Optional:**
   an in-app "update available → reload" toast when a new SW is waiting.
5. **Optional — in-app "Install app" affordance.** Capture the
   `beforeinstallprompt` event (Chromium) and show an "Install" button (e.g. in the
   header menu / profile). **iOS Safari has no `beforeinstallprompt`** — there it's a
   manual "Share → Add to Home Screen"; show short instructions instead.

## Files to touch (when implemented)

| File | Change |
|------|--------|
| `.gitignore` | **first:** remove `/web/icons/` and `/web/manifest.json` so they deploy (see Blocker above) |
| `web/manifest.json` | brand name/desc/colours/orientation + icon refs |
| `web/index.html` | description, apple title, theme-color meta, apple-touch-icon |
| `web/icons/*`, `web/favicon.png` | replace with branded, maskable-safe icons |
| `pubspec.yaml` (optional) | add `flutter_launcher_icons` dev dep + config block |
| `lib/` (optional, only for in-app install button) | a small `web`-interop helper to hold the deferred `beforeinstallprompt` event + an `AppButton`; gate to web + event-available |

> Most of this is **web/ config + assets — no Dart UI** unless we add the optional
> in-app install button (item 5).

## Platform notes / caveats

- **Android Chrome / Edge / desktop Chromium:** full install + `beforeinstallprompt`.
- **iOS Safari:** installable via "Add to Home Screen" only; no programmatic prompt;
  uses `apple-touch-icon` + `apple-mobile-web-app-title`; standalone display works.
  Test that the status-bar style looks right.
- **Maskable icons:** verify in Chrome DevTools → Application → Manifest (it previews
  the masked icon) so the logo isn't clipped.
- **Caching gotcha:** Flutter's SW caches aggressively; after a deploy users may need
  a reload to get the new build. The optional update toast (item 4) mitigates this.
- **base href:** install/start_url must respect the deploy path (`--base-href`);
  confirm against where the app is actually served.

## Verification

- Chrome DevTools → **Lighthouse → PWA** audit passes (installable, manifest, SW).
- DevTools → Application → Manifest shows XpenseDesk name + branded (un-clipped)
  maskable icon.
- Install on **Android Chrome**, **desktop Chrome/Edge**, and **iOS Safari**
  (Add to Home Screen); launched icon + label + standalone window are all branded.

## Open questions

1. **Icon generation:** add `flutter_launcher_icons` (one source → all sizes,
   repeatable) vs hand-export the PNGs once? (Recommend the package.)
2. **Source artwork:** is `assets/images/xpensedesk-main-logo-trans.png` square and high-res enough for a
   crisp 512×512, and do we have a **maskable** variant (logo on a solid brand tile
   with padding)? May need a designer asset.
3. **Orientation:** `any` (recommended for desktop-first) vs keep `portrait-primary`?
4. **In-app install button (item 5):** in scope now, or rely on the browser's native
   install affordance for v1?
5. **theme_color:** `#362B71` (primary) confirmed, or a different brand value?
