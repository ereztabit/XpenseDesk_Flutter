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

  /// Whether to surface the iOS install hint (banner + menu item): on iOS and
  /// not already installed. Safari vs non-Safari only changes the wording.
  static bool get shouldShowIosHint => isIOS && !isStandalone;
}
