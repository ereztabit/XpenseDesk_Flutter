# Remove Default Flutter Startup Loader

## Background

The web app currently uses Flutter's standard web bootstrap flow from `web/index.html`:

```html
<script src="flutter.js" defer></script>
<script src="flutter_bootstrap.js" async></script>
```

There is no custom bootstrap override file in the repository, so startup behavior falls back to Flutter's default web loading experience.

## What This Task Means

Remove the default Flutter startup loading animation or loader experience shown before the app renders its first frame on web.

The goal is to avoid the generic Flutter loading state and replace it with one of these approved outcomes:

- **selected: a simple spinner, centered on screen** — no branding needed, just a clean centered loader
- no visible loader at all
- a minimal blank startup state
- a custom XpenseDesk-branded startup screen

## Current Behavior

- The app boots through Flutter's standard web initialization path.
- Before the first Flutter frame is painted, users may see the default Flutter startup/loading experience.
- This is framework-default behavior rather than product-specific UI.

## Desired Behavior

- Users should not see Flutter's default startup loader.
- Startup should feel product-owned and visually consistent with XpenseDesk.
- The transition from initial page load to first rendered app frame should be clean and minimal.

## Scope

This task is about the startup phase only.

Included:

- web app boot experience before first Flutter frame
- `web/index.html` and any custom web bootstrap/loading markup or styling
- optional custom branded loading shell

Not included:

- in-app loading indicators after the app has already rendered
- screen-level spinners for API calls
- native Android or iOS splash screens unless explicitly added as a separate task

## Functional Requirements

- Remove reliance on the default visible Flutter loader behavior.
- Ensure the app still boots correctly on web.
- The replacement loader is a simple spinner, centered on screen, no branding required.
- The loader must disappear as soon as the first app frame is ready.
- The implementation must not introduce layout shift or leave stale loading markup on screen.

## Implementation Direction

- Keep `web/index.html` as the control point for startup markup.
- Add a custom startup container only if product wants a branded loading state.
- Hook removal of any custom startup element into the point where Flutter finishes initialization and renders the app.
- Prefer a minimal approach over decorative animation.

## Acceptance Criteria

- On web, the default Flutter startup loading animation is no longer visible.
- The app still initializes normally.
- Users either see no startup loader or a custom XpenseDesk loader.
- The custom loader, if present, is removed immediately after app startup completes.

## Notes For Implementation

- Based on current repository inspection, `web/index.html` references `flutter_bootstrap.js` and there is no custom bootstrap file checked into source control.
- That means the work will likely involve adding a custom startup shell and controlling its removal, or overriding the default bootstrap behavior more explicitly.