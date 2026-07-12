{{flutter_js}}
{{flutter_build_config}}

// XpenseDesk production guard — see docs/bugs/magic-link-sandboxed-context-blocks-login.md
//
// Flutter's loader guards service-worker loading with `"serviceWorker" in navigator`,
// which stays TRUE in a sandboxed, opaque-origin context (the property lives on
// Navigator.prototype). It then reads `navigator.serviceWorker` synchronously — and
// in a magic link opened inside an email client's in-app browser (sandbox without
// `allow-same-origin`) that getter throws SecurityError *before* main.dart.js is
// injected, so the whole app fails to boot (blank login page).
//
// Touch the getter defensively and only enable the service worker when it's safe.
// Normal browsers keep the PWA service worker; sandboxed contexts boot without it.
(function () {
  var swSafe = false;
  try {
    swSafe = !!navigator.serviceWorker;
  } catch (e) {
    swSafe = false;
  }

  _flutter.loader.load(
    swSafe
      ? { serviceWorkerSettings: { serviceWorkerVersion: {{flutter_service_worker_version}} } }
      : {}
  );
})();
