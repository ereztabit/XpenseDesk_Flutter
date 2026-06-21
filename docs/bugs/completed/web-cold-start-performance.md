# Bug: Flutter Web Cold-Start Performance (Lighthouse 0.27)

> **Status: parked — deferred to v2**

## Decision (2026-06-21) — parked for v2

Investigated thoroughly; parking. Summary of why no quick win exists:

- Score (35-36) is consistent and reflects the COLD first-load only. Repeat
  visits are already fast (service worker + HTTP cache + ETag/304), so real
  users are not hit as hard as the number implies.
- Brotli is already enabled; SWA's dynamic compression quality is not
  configurable and pre-compressed q11 is not serveable on SWA (#2 not actionable).
- main.dart.js + canvaskit already download in parallel; preloading for
  parallelism is a no-op (#5 premise wrong).
- The dominant bottleneck is the SWA origin serving main.dart.js slowly
  (~6.5s vs canvaskit's 0.28s from gstatic CDN). The real fix is edge caching /
  CDN (Azure Front Door, #6) — a new billable resource + DNS change, too big for
  now.
- The one clean, in-our-control win remains #3 (drop the 693 KB NotoColorEmoji
  font). Carried into v2 as the first thing to try.

v2 entry points, in priority order: #3 (emoji font), #6 (Front Door / CDN),
#7 (--wasm/skwasm renderer). Details preserved below.

## Problem

A Lighthouse run against the production site (app.xpensedesk.com, 2026-06-21)
scored Performance **0.27**. The app shows a blank white screen for several
seconds on first load. Because Flutter web paints everything to a single
CanvasKit surface, First Contentful Paint and Largest Contentful Paint are both
gated on the full engine bootstrap completing — there is no progressive HTML to
paint early.

Measured metrics:

| Metric | Value | Lighthouse score |
|--------|-------|------------------|
| First Contentful Paint (FCP) | 8.3 s | 0 |
| Largest Contentful Paint (LCP) | 18.2 s | 0 |
| Time to Interactive (TTI) | 18.2 s | 0.03 |
| Total Blocking Time (TBT) | 2,340 ms | 0.05 |
| Speed Index | 12.4 s | 0.03 |
| JS bootup time | 4.5 s | 0 |
| Cumulative Layout Shift (CLS) | 0 | 1.0 (good) |
| Server response time | 80 ms | 1.0 (good) |

## Reproduce Steps

1. Open Chrome, run Lighthouse (Performance, Mobile) against
   https://app.xpensedesk.com.
2. Observe the Performance score and the white screen before first paint.
   -- Expected: usable first paint within ~2-3 s.
   -- Actual: ~8 s to first paint, ~18 s to interactive; score 0.27.

## Root Cause

The cold-start payload that must download + parse + execute before the first
pixel is large:

| Resource | On wire | Uncompressed | Note |
|----------|---------|--------------|------|
| canvaskit.wasm (gstatic CDN) | 1.6 MB | 5.6 MB | CanvasKit renderer, blocks first pixel |
| main.dart.js | 1.28 MB | 4.6 MB | compiled app; 3.6 s of scripting/bootup |
| NotoColorEmoji font | 693 KB | 693 KB | CanvasKit emoji fallback, fetched eagerly |

`main.dart.js` is served **gzip, not Brotli** (4584 -> 1279 KB ~ 3.6x; Brotli
would reach ~5x ~ 900 KB).

Note: the original trace was polluted by browser extensions (Adobe Acrobat etc.,
~700 KB). A clean baseline was captured in Incognito (2026-06-21, run 2): see below.

### Clean baseline (Incognito, extensions off) — 2026-06-21

| Metric | Run 1 (extensions) | Run 2 (clean) |
|--------|--------------------|---------------|
| Performance | 0.27 | 0.36 |
| FCP | 8.3 s | 1.8 s (good, 0.89) |
| LCP | 18.2 s | 17.8 s |
| Speed Index | 12.4 s | 16.7 s |
| TTI | 17.8 s | 17.8 s |
| TBT | 2.34 s | 2.01 s |

Conclusion: extensions were the entire FCP problem — first paint is fine at
1.8 s (early splash/logo). The real target is LCP / TTI / Speed Index ~17-18 s,
i.e. time until the Flutter engine finishes bootstrapping and the app renders.
We are optimizing time-to-interactive, not first paint. Payload unchanged
(canvaskit 1.6 MB, main.dart.js 1.28 MB gzip, NotoColorEmoji 693 KB).

## Suggested Solution Approach

Reduce the cold-start payload and improve perceived load. Work the table below
one item at a time; re-measure after each.

## Action Table (work top-down)

| # | Action | Lever | Effort | Status |
|---|--------|-------|--------|--------|
| 1 | Re-run Lighthouse in Incognito (extensions off) to get a clean baseline | measurement hygiene | XS | DONE (0.36; FCP 1.8s ok, LCP/TTI 17.8s) |
| 2 | Enable Brotli on Azure Static Web Apps | ~30% smaller main.dart.js | S | NOT ACTIONABLE — see note below |
| 3 | Eliminate the 693 KB NotoColorEmoji fetch — audit UI for emoji glyphs in Text/labels that trigger the CanvasKit emoji fallback | -693 KB transfer | S | todo |
| 4 | Add a real HTML/CSS loading indicator (spinner/skeleton) in index.html / flutter_bootstrap.js | perceived perf | S | todo |
| 5 | `<link rel=preload as=script fetchpriority=high>` for main.dart.js | raise Low->High priority | S | todo (see note) |
| 6 | Put a CDN/edge cache (Azure Front Door) in front of SWA so main.dart.js is served fast + pre-compressed like canvaskit | fixes the 6.5s origin serve | L | todo (biggest lever) |
| 7 | Evaluate renderer strategy / `--wasm` (skwasm) build to shrink the ~1.6 MB CanvasKit floor | architectural ceiling | L | todo |

### Item #2 investigation (2026-06-21) — Brotli already on, not improvable on SWA

Verified against live production. Azure SWA already serves Brotli when the client
advertises it (`Content-Encoding: br`). The earlier "it's gzip not Brotli" claim
was a misread — the 1.28 MB transfer WAS Brotli.

main.dart.js bytes by encoding:
- raw (identity): 4,694,002
- gzip: 1,737,980
- Azure dynamic Brotli (served today): 1,306,401
- brotli q5: 1,200,041
- brotli q9: 1,149,594
- brotli q11 (max): 1,006,687

Azure's dynamic Brotli is low quality (worse than q5). Max-quality q11 would save
~290 KB (~23% of main.dart.js, ~6% of the 4.8 MB cold-start payload). BUT it is
not reachable on Azure Static Web Apps:
- No `az staticwebapp` CLI compression setting (managed, fixed behavior).
- No compression knob in staticwebapp.config.json (routing/headers/MIME only).
- SWA re-compresses on the fly; cannot serve pre-built .br files with custom
  Content-Encoding via the deploy action.

The only ways to capture q11 are infra-level (Azure Front Door / Cloudflare in
front, or migrate to Blob+CDN serving pre-compressed assets) — out of scope for a
config tweak. Decision: park #2; pursue #3 (NotoColorEmoji, 693 KB) for a bigger,
in-our-control win.

### Network timing investigation (2026-06-21) — origin serving is the bottleneck

From the clean trace, observed (unthrottled) network times:

| Asset | Start -> End | Size | Effective speed |
|-------|--------------|------|-----------------|
| canvaskit.wasm (gstatic CDN) | 296 -> 576 ms | 1,613 KB | ~46 Mbps |
| main.dart.js (Azure SWA origin) | 299 -> 6,766 ms | 1,279 KB | ~1.6 Mbps |
| NotoColorEmoji | 7,715 -> 8,389 ms | 693 KB | (after engine boot) |

Findings:
- main.dart.js and canvaskit ALREADY download in parallel (both start ~297 ms),
  so preloading-for-parallelism is a no-op. Original item #5 premise was wrong.
- Same connection, same instant: canvaskit (CDN) = 46 Mbps; main.dart.js (SWA
  origin) = 1.6 Mbps for a SMALLER file, on an idle pipe (canvaskit done at
  576 ms). So it is NOT bandwidth/contention -- the SWA origin is slow to serve
  main.dart.js (likely on-the-fly Brotli on cache-miss).
- main.dart.js is fetched at priority Low (canvaskit is High).
- Confirmed reproducible: 3 Lighthouse runs scored 35/35/36. Not a cold-cache
  fluke.
- The emoji font is serialized AFTER the engine boots (starts 7,715 ms), so it
  sits on the tail of the critical path.

Implication: the dominant lever is making main.dart.js serve fast (edge cache /
pre-compressed via Front Door, item #6). fetchpriority preload (#5) is cheap and
worth doing but unlikely to fix a 6.5s origin serve on its own.

## Suggested Fix

Start with items 1-3 (cleanest wins, no architecture change). Items 6-7 are
larger and need their own discussion before committing. Each item should be
treated as its own change with a re-measure before moving on.
