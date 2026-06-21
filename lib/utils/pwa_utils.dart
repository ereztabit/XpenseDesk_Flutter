// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Browser/platform detection for the PWA install hint.
///
/// iOS has no `beforeinstallprompt` (that's a Chromium feature) and only Safari
/// can "Add to Home Screen". So on iOS we show a manual hint instead of relying
/// on a native prompt. Desktop/Android use the browser's own install affordance
/// and never see any of this.
///
/// All reads are guarded — any interop failure resolves to a safe `false`.
class PwaUtils {
  PwaUtils._();

  static String get _ua => html.window.navigator.userAgent;

  /// True on iPhone / iPod / iPad — including iPadOS 13+, which reports itself
  /// as a Mac but exposes a touch screen.
  static bool get isIOS {
    final ua = _ua;
    if (ua.contains('iPhone') || ua.contains('iPad') || ua.contains('iPod')) {
      return true;
    }
    final platform = html.window.navigator.platform ?? '';
    final maxTouch = html.window.navigator.maxTouchPoints ?? 0;
    return platform == 'MacIntel' && maxTouch > 1; // iPadOS masquerading as Mac
  }

  /// True on Android. Used to keep the install menu item reliably present (the
  /// drawer falls back to manual browser-menu steps if no native prompt fired).
  static bool get isAndroid => _ua.contains('Android');

  /// True when the app is already running as an installed PWA (standalone
  /// window) — in that case there's nothing to install, so suppress the hint.
  /// Installed PWAs (incl. iOS Safari 16.4+) match the standalone display-mode.
  static bool get isStandalone {
    try {
      return html.window.matchMedia('(display-mode: standalone)').matches;
    } catch (_) {
      return false;
    }
  }

  /// Whether to surface the iOS install hint (drawer + menu item): on iOS and
  /// not already installed. Safari vs non-Safari only changes the wording.
  static bool get shouldShowIosHint => isIOS && !isStandalone;

  // --- Chromium native install (Android Chrome/Edge, desktop Chrome/Edge) ---
  // index.html captures `beforeinstallprompt`, mirrors availability onto the
  // <html data-pwa-installable> attribute, and listens for a trigger event.

  /// True when Chromium has a captured `beforeinstallprompt` we can fire — i.e.
  /// the app is installable now and not yet installed. iOS never sets this.
  static bool get canPromptNativeInstall =>
      html.document.documentElement?.getAttribute('data-pwa-installable') == '1';

  /// Fires the native install dialog. MUST be called from a user gesture, or the
  /// browser ignores it. No-op if nothing is captured.
  static void promptNativeInstall() =>
      html.window.dispatchEvent(html.CustomEvent('pwa-install-trigger'));

  /// Emits when `beforeinstallprompt` is captured — lets the auto-prompt wait for
  /// installability that becomes available after first frame.
  static Stream<html.Event> get onInstallAvailable =>
      const html.EventStreamProvider<html.Event>('pwa-install-available')
          .forTarget(html.window);

  /// Any install affordance worth showing. Keyed off the platform (stable) so
  /// the menu item is reliably present on iOS and Android when not yet
  /// installed — plus desktop Chromium whenever a native prompt is captured.
  /// The drawer adapts to whether a native prompt is actually available.
  static bool get shouldShowInstallAffordance =>
      (!isStandalone && (isIOS || isAndroid)) || canPromptNativeInstall;
}
