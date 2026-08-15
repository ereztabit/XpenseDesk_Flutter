import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Opens a support connection in a new browser tab (FS-1001).
///
/// **Why a tab is reserved before the network call.** Browsers only honour
/// `window.open` while a tap's user-gesture credit is unspent, and minting the
/// connect link is a round trip — by the time it returns the credit is gone and
/// the popup blocker refuses the tab. The same problem is documented in
/// `json_viewer_service.dart`, which pays for it with a download fallback.
///
/// Here the tab is opened blank *first*, on the tap itself, and pointed at the
/// link once it arrives. So the ordinary path is one click and no blocker.
/// [reserveTab] still returns null if popups are blocked outright, and the
/// caller falls back to showing the link for the agent to open by hand.
///
/// The connect link is a bearer credential: it mints a session for whoever
/// opens it. Nothing here logs it, and it is never written anywhere persistent.
class ImpersonationLauncher {
  const ImpersonationLauncher();

  /// Call this synchronously from the tap handler, BEFORE any `await`.
  web.Window? reserveTab() => web.window.open('', '_blank');

  void navigate(web.Window tab, String url) {
    tab.location.href = url;
  }

  /// Closes a reserved tab when the link could not be minted, so a failed
  /// connect does not strand a blank tab.
  void abandon(web.Window tab) {
    try {
      tab.close();
    } catch (_) {
      // A tab the browser will not let us close is harmless — it is blank.
    }
  }

  /// Last resort when popups are blocked outright: the agent opens the link
  /// themselves from the dialog.
  void openNow(String url) {
    web.window.open(url, '_blank');
  }

  Future<void> copyToClipboard(String text) async {
    await web.window.navigator.clipboard.writeText(text).toDart;
  }
}
