# Flutter Web Deployment Guide (Azure Static Web Apps)

How to deploy the XpenseDesk **Flutter web** app to Azure. This guide is for the
Flutter team. The Azure resource is already provisioned; what's left lives in the
**Flutter repo**.

---

## What's already set up (by DevOps)

| Thing | Value |
|-------|-------|
| Azure resource | Static Web App `xd-web-prd` |
| Tier | Free |
| Region | West Europe (metadata only — content is served from a global CDN edge, including a PoP near Israel) |
| Resource group | `RG-XD-PROD-IL` |
| Default URL | `https://yellow-pebble-027d48d03.7.azurestaticapps.net` |
| Production custom domain | `app.xpensedesk.com` (bound by DevOps after the first successful deploy) |
| Backend API | `https://api.xpensedesk.com` (Israel Central) |

You do **not** create or touch the Azure resource. You add two files to the Flutter
repo and one GitHub secret, then push.

---

## Why a custom workflow (read this first)

Azure Static Web Apps' built-in build system (Oryx) does **not** understand Flutter.
So we do **not** let SWA build the app. Instead the GitHub Action:

1. Installs Flutter,
2. runs `flutter build web --release` itself,
3. uploads the already-built `build/web` folder with `skip_app_build: true`.

If you skip this and let SWA build, the deploy will fail or produce an empty site.

---

## Step 1 - Add the GitHub Actions workflow

Create `.github/workflows/azure-static-web-apps.yml` in the **Flutter repo**:

```yaml
name: Deploy Flutter Web to Azure Static Web Apps

on:
  push:
    branches: [ main ]
  pull_request:
    types: [opened, synchronize, reopened, closed]
    branches: [ main ]

jobs:
  build_and_deploy:
    if: github.event_name == 'push' || github.event.action != 'closed'
    runs-on: ubuntu-latest
    name: Build and Deploy
    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          channel: stable
          # pin a version for reproducible builds, e.g.:
          # flutter-version: '3.27.0'

      - run: flutter pub get

      - run: flutter build web --release

      - name: Deploy to Azure Static Web Apps
        uses: Azure/static-web-apps-deploy@v1
        with:
          azure_static_web_apps_api_token: ${{ secrets.AZURE_STATIC_WEB_APPS_API_TOKEN }}
          action: upload
          app_location: build/web   # the already-built output
          skip_app_build: true      # we built it above; do NOT let SWA build
          skip_api_build: true      # no managed API

  close_pull_request:
    if: github.event_name == 'pull_request' && github.event.action == 'closed'
    runs-on: ubuntu-latest
    name: Close PR preview environment
    steps:
      - name: Close
        uses: Azure/static-web-apps-deploy@v1
        with:
          azure_static_web_apps_api_token: ${{ secrets.AZURE_STATIC_WEB_APPS_API_TOKEN }}
          action: close
```

Notes:
- Adjust the branch name if your default branch is not `main`.
- Pin `flutter-version` once you know the exact version you build with, so CI matches local.

---

## Step 2 - Add the SPA routing config

Flutter web uses client-side routing. Without a fallback, a refresh or deep link
(e.g. `app.xpensedesk.com/expenses/123`) returns 404. Add
**`web/staticwebapp.config.json`** in the Flutter project (everything in `web/` is
copied into `build/web` at build time, so it ships with the bundle):

```json
{
  "navigationFallback": {
    "rewrite": "/index.html",
    "exclude": [
      "/assets/*",
      "/icons/*",
      "/canvaskit/*",
      "*.{js,css,png,jpg,jpeg,svg,json,wasm,ttf,woff,woff2}"
    ]
  }
}
```

This rewrites unknown paths to `index.html` (so Flutter's router takes over) while
leaving real asset files alone.

---

## Step 3 - Add the deployment token as a GitHub secret

The Action authenticates to Azure with a deployment token. It is a **secret** -
never commit it.

1. In the Azure Portal, open Static Web App **`xd-web-prd`** -> **Overview** ->
   **Manage deployment token** -> copy.
   (Ask DevOps if you don't have portal access; we can hand it over securely.)
2. In the Flutter repo: **Settings** -> **Secrets and variables** -> **Actions** ->
   **New repository secret**.
   - Name: `AZURE_STATIC_WEB_APPS_API_TOKEN`
   - Value: the token from step 1.

---

## Step 4 - Point the app at the production API

Make sure the app's API base URL for production builds is
**`https://api.xpensedesk.com`** (however your app configures environments -
`--dart-define`, a config file, flavors, etc.). Do not ship a localhost or dev URL
in the production web build.

---

## Step 5 - Push and watch the deploy

- **Push to `main`** -> the workflow builds and deploys to the production environment.
- **Open a PR** -> SWA spins up a temporary **preview environment** with its own URL
  (posted on the PR), so you can review before merge. Closing the PR tears it down.

Watch progress under the repo's **Actions** tab.

---

## Step 6 - Verify (we do this together)

After the first green deploy, confirm on the default URL **before** the custom domain
is attached:

1. Open `https://yellow-pebble-027d48d03.7.azurestaticapps.net` - the app loads.
2. Hard-refresh on a deep link (e.g. `.../expenses` if such a route exists) - it
   loads instead of 404 (confirms the routing config).
3. Open browser DevTools -> Network - the Flutter assets (`main.dart.js`,
   `*.wasm`, canvaskit) load with 200s.
4. Do a real action that calls the API (e.g. login) - the request goes to
   `https://api.xpensedesk.com` and succeeds.

Tell DevOps once steps 1-3 pass. **Step 4 (API calls) may fail with a CORS error
until DevOps adds this origin to the API allow-list** - that's expected and handled
in the next stage.

---

## Step 7 - Custom domain + CORS (DevOps, after verification)

Once the default URL is verified, DevOps will:

1. Bind **`app.xpensedesk.com`** to the Static Web App and issue a free managed TLS
   cert (you add nothing in the app for this).
2. Add `https://app.xpensedesk.com` to the API **CORS allow-list** and set the API's
   `FrontendUrl` to it.

After that, switch any references in the app from the `*.azurestaticapps.net` URL to
`https://app.xpensedesk.com`.

---

## Troubleshooting

- **Blank page / 404 on assets after deploy:** usually a base-href mismatch. For
  serving at the domain root, the default `flutter build web --release` (base href
  `/`) is correct. Only set `--base-href` if serving under a subpath.
- **Deploy "succeeds" but site is empty:** `skip_app_build: true` is missing, or
  `app_location` is not `build/web`. SWA tried to build and produced nothing.
- **Refresh / deep link 404s:** `web/staticwebapp.config.json` missing or not copied
  into `build/web`. Confirm it exists under `web/` in the repo.
- **`.wasm` or canvaskit fails to load:** add explicit MIME types in
  `staticwebapp.config.json` (`mimeTypes` block) - ask DevOps for the snippet.
- **API calls blocked by CORS:** expected until DevOps adds this origin to the API
  allow-list (Step 7). Verify everything else first.
- **401/403 from the API:** that's auth, not deployment - the deploy is fine.

---

## Quick reference

- Resource: `xd-web-prd` (Static Web App, Free, West Europe, `RG-XD-PROD-IL`)
- Default URL: `https://yellow-pebble-027d48d03.7.azurestaticapps.net`
- Prod domain (after binding): `https://app.xpensedesk.com`
- API: `https://api.xpensedesk.com`
- GitHub secret: `AZURE_STATIC_WEB_APPS_API_TOKEN`
- Build: `flutter build web --release` -> deploy `build/web` with `skip_app_build: true`
