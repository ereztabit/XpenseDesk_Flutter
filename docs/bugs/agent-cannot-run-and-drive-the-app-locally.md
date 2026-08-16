# Bug: Claude cannot run and drive the app locally

> **Status: new**

## Problem

Claude cannot start the app and interact with it -- navigate, click buttons,
read what a screen actually renders. Every change has to be verified by hand by
the developer, which is the single biggest thing slowing development down.

Two independent causes, both real, both fixable:

1. **The agent launch config is wrong**, so any attempt to start the app lands
   on an origin the backend rejects.
2. **Flutter web renders to a canvas**, so even when the app is running the
   browser automation tools see an empty page with nothing to click.

Neither has anything to do with the "Flutter debugger is hard to automate"
reputation -- the debugger/VM-service is not involved in any of this.

## Reproduce Steps

### Cause 1 -- launch config produces a CORS-rejected origin

1. Look at `.claude/launch.json` (the config the agent's `preview_start` reads):
   runtimeArgs are `["run", "-d", "chrome", "--dart-define=ENV=dev"]` with a
   `"port": 8080` field.
2. There is no `--web-port` and no `--web-hostname` in the args, and no TLS.
   The `"port"` field is only a hint the preview pane uses to guess a URL -- it
   is not passed to `flutter run`.
   -- Expected: app serves on `https://localhost:8080`, the one origin the API
      accepts.
   -- Actual: `flutter run` picks a random port over plain http. Every API call
      is then blocked by CORS.
3. Backend side, for reference: `Program.cs:144` calls
   `policy.WithOrigins(frontendUrl)` -- a single origin -- and
   `appsettings.json:7` sets `FrontendUrl` to `https://localhost:8080`.
4. The working recipe already exists in `.vscode/launch.json` under
   "Flutter Dev HTTPS (Chrome)": `--web-hostname localhost --web-port=8080`
   plus `--web-tls-cert-path localhost+1.pem` /
   `--web-tls-cert-key-path localhost+1-key.pem` (both certs are in the repo
   root). `.claude/launch.json` was never brought in line with it.

### Cause 2 -- no DOM to click

1. Start the app on any port and point a browser automation tool at it.
2. Read the page structure.
   -- Expected: buttons, labels, inputs the tool can find and click by name.
   -- Actual: the page is a single `flt-glass-pane` element wrapping a canvas.
      Flutter 3.44 draws everything with CanvasKit/skwasm, so there are no DOM
      nodes for the UI. `read_page` and `find` come back with nothing usable,
      leaving only screenshot-plus-pixel-coordinate clicking, which is too
      brittle to rely on.

NOTE: this second cause is described from how Flutter web works in general. It
was NOT reproduced against this app -- the run was aborted before the page was
inspected. Confirming it is step 1 of the fix, not an assumption to build on.

## Suggested Solution Approach

Claude should be able to start the app the same way the developer does, log in
once, and then navigate the real UI to verify a change -- without the developer
having to drive the browser for it.

## Suggested Fix

Two changes, in this order. Both are small.

**Fix 1 -- make `.claude/launch.json` mirror the working VS Code config.**

Point it at `https://localhost:8080` with the existing mkcert certs, i.e. the
same args as "Flutter Dev HTTPS (Chrome)" in `.vscode/launch.json`. Open
question: `-d chrome` also spawns its own Chrome window on top of the agent's
browser pane (two clients on one dev server); `-d web-server` avoids that but
gives up the browser attach that hot reload uses. Decide which before editing.

**Fix 2 -- enable the semantics tree in dev runs.**

Flutter does build a real DOM tree, with roles and aria-labels, once semantics
are switched on. Gate it behind a dart-define in `lib/main.dart` so production
is untouched:

```dart
if (const bool.fromEnvironment('A11Y')) {
  SemanticsBinding.instance.ensureSemantics();
}
```

and add `--dart-define=A11Y=true` to the agent launch config only. Every `Text`
and every `AppButton` label then becomes a findable, clickable element.

Verify before building on it: start on 8080, read the page structure, and check
the tree is actually populated with the app's labels. If it is not, this whole
approach is dead and the fallback is `integration_test` + `flutter drive`, which
drives widgets directly and needs no DOM.

**Two open risks:**

- The mkcert cert (`localhost+1.pem`) is trusted by the developer's Windows
  certificate store. It is not known whether the agent's browser pane uses that
  store. If it does not, `https://localhost:8080` hits a certificate
  interstitial and none of the above works. This is the most likely thing to
  sink the effort -- check it first, together with the semantics check.
- Login: Claude is not permitted to type passwords into any field, so it cannot
  get past the login screen on its own. Either the developer logs in once in the
  browser pane and the session is inherited, or a dev-only dart-define injects a
  test session token. The first option costs nothing and needs no code.

**Explicitly out of scope here:** building an `integration_test` suite. That is
a separate, larger item -- it needs its own CORS-or-mocking decision, and it
does not help the "does this screen look right" loop that this bug is about.
