# PWA Debugging & Verification Guide

How to inspect, debug, and verify XpenseDesk as a Progressive Web App
(manifest, icons, service worker, installability). XpenseDesk is a Flutter **web**
app; `flutter build web` produces the PWA scaffold (manifest + service worker)
that this guide debugs.

The branded PWA config lives in `web/manifest.json`, `web/index.html`, and
`web/icons/`. The source artwork for the icon set is
`assets/branding/app-icon-source.png`.

---

## ⚠️ The #1 gotcha: `flutter run` does NOT serve a real manifest

The local dev server (`flutter run -d chrome`, typically `https://localhost:8080`)
**stubs the manifest and skips the service worker in debug**:

- `GET /manifest.json` returns `{"info":"manifest not generated in run mode."}`
- No service worker is registered in debug mode.

So **DevTools → Application → Manifest will show every field blank/invalid on the
dev server**, no matter how correct `web/manifest.json` is. The Installability
section will list "no name", "start_url invalid", "no suitable icon", etc. — this
is the stub, **not** your manifest.

What the dev server *does* serve correctly: `index.html` meta tags
(`theme-color`, `apple-mobile-web-app-title`, `apple-touch-icon`) and the icon
files under `web/icons/`.

**To verify the real manifest, service worker, and installability you must serve a
release build (see below).**

---

## How to verify on a release build (the authoritative test)

```bash
# 1. Build the release bundle
flutter build web --release --dart-define=ENV=prod

# 2. Serve build/web over localhost (a secure context — SW + install both work).
#    NOTE: on this machine bare `python` is the Windows Store stub and fails.
#    Use the `py` launcher:
py -m http.server 8099 --directory build/web

# 3. Open http://localhost:8099 in Chrome.
```

`localhost` over plain HTTP counts as a secure context, so service workers and the
install prompt work without TLS. (Production is HTTPS via Azure Static Web Apps.)

---

## What to check in Chrome DevTools

### Application → Manifest
- **Identity** populated: Name/Short name = "XpenseDesk", Description set.
- **Theme/background**: `theme_color #362B71`, `background_color #F7F7FC`.
- **Icons**: 192 + 512 standard, 192 + 512 maskable.
- **Maskable preview**: toggle the mask shapes (circle, squircle…). The glyph must
  never clip — that's why maskable icons sit on a white tile with ~15% safe-zone
  padding (the glyph is dark purple, so a purple tile would hide it).
- **Installability**: should show the app as installable; the only expected
  warnings are "add a screenshot for a richer install UI" (optional, not blocking).

### Application → Service workers
- A registered worker with status **activated** after a clean load. The Update
  Cycle shows Install → Wait → Activate.
- "redundant / deleted" status while testing is normal churn from repeated reloads
  and manual re-registration — not a defect.

### The omnibox install icon = ground truth
When Chrome shows the **install icon in the address bar** (monitor-with-arrow), it
has judged the app installable. That's the most reliable single signal. Click it to
install and confirm the windowed app, taskbar/home-screen icon, and label are all
branded "XpenseDesk".

### Lighthouse
Run a Lighthouse audit and review the PWA-related checks (installable manifest,
served over HTTPS, valid icons).

---

## Service worker notes (Flutter 3.41)

- Flutter 3.41's default `flutter build web` generates a **minimal ~815-byte
  `flutter_service_worker.js`**: an install handler only — **no fetch handler, no
  `RESOURCES` map, no caching**. This is normal for the version, not a
  misconfiguration.
- **Consequence:** the app is *installable* but has **no offline support**. The
  "loads with no internet" PWA reliability pillar is not delivered by this SW.
- Modern Chrome installability is **manifest-driven** — a valid manifest + icons +
  secure context is enough for the install prompt; the minimal SW does not block it.
- If offline support is ever required, that's a separate task (investigate the
  Flutter 3.41 SW behavior / add a caching strategy). CI builds with plain
  `flutter build web --release --dart-define=ENV=prod` (no `--pwa-strategy` flag).

---

## Driving Chrome via the Claude-in-Chrome plugin

When debugging through the browser-automation plugin (not hand-driving DevTools):

- **Match the protocol.** The dev server is **HTTPS** (`https://localhost:8080`,
  mkcert local cert — see `localhost+1.pem`). Navigating to `http://localhost:8080`
  lands on a dead context where everything 404s and `isSecureContext` is false.
- **Inspect via `fetch` in page context**, e.g.
  `await fetch('manifest.json', {cache:'no-store'}).then(r => r.text())` to see the
  raw manifest, and fetch each icon URL to confirm `200 image/png`.
- **`navigator.serviceWorker.getRegistrations()` from the plugin's JS context is
  unreliable** — it returned `0` registrations while DevTools showed the worker
  installing/activating. **Trust the DevTools Service Workers panel over JS probes.**
- Raw JS-file contents (`flutter_service_worker.js`, `flutter_bootstrap.js`) may
  come back as `[BLOCKED: Cookie/query string data]`; test for substrings
  (`/serviceWorkerVersion/`, `/addEventListener\(['"]fetch['"]/`) instead of
  returning the whole file.

---

## Quick reference: which surface shows what

| Want to verify | Dev server (`flutter run`, :8080) | Release build (`build/web`, :8099) |
|----------------|-----------------------------------|------------------------------------|
| `index.html` meta tags | ✅ correct | ✅ correct |
| Icon files load | ✅ correct | ✅ correct |
| `manifest.json` contents | ❌ stubbed | ✅ real |
| Service worker | ❌ not registered | ✅ registered (minimal) |
| Install prompt / Installability | ❌ won't show | ✅ authoritative |

---

## Files involved

| File | Role |
|------|------|
| `web/manifest.json` | App identity: name, colors, orientation, icon refs |
| `web/index.html` | Meta tags: description, theme-color, apple title, apple-touch-icon |
| `web/icons/Icon-{192,512}.png` | Standard icons (transparent glyph) |
| `web/icons/Icon-maskable-{192,512}.png` | Maskable icons (glyph on white safe-zone tile) |
| `web/icons/apple-touch-icon.png` | 180px iOS home-screen icon |
| `web/favicon.png` | Browser-tab favicon |
| `assets/branding/app-icon-source.png` | 512² source glyph; regenerate the icon set from this |
| `.gitignore` | Must NOT ignore `web/icons/` or `web/manifest.json` (else they 404 on prod) |

### Regenerating the icon set

The icons were generated from `assets/branding/app-icon-source.png` (512², square,
transparent) using .NET `System.Drawing` (no ImageMagick on the dev machine):
standard icons full-bleed transparent; maskable icons = glyph at ~70% centered on a
white tile; apple-touch = glyph at ~80% on white. See the
`feat(pwa)` commit for the generation script.
