import 'package:web/web.dart' as web;

/// Tab-scoped storage for a support-impersonation session token (FS-1001).
///
/// **Why this is not `SharedPreferences`.** On web `SharedPreferences` is
/// `localStorage`, which every tab in the browser shares. The admin panel and
/// the app are the same Flutter application behind one `userInfoProvider`, and
/// `AdminAuthGate` admits on `roleId == 3`. So writing an impersonation token to
/// the shared key would overwrite the agent's own login, resolve the whole app
/// to the impersonated employee, and lock the agent out of the admin panel they
/// started from — while a support call is in progress.
///
/// `sessionStorage` is per-tab, so the panel tab keeps its own session and the
/// tab opened by the connect link is the impersonated one. Both survive refresh
/// and neither can see the other's token.
///
/// ## Two keys, and why the second one is never cleared
///
/// [_tokenKey] holds the credential and goes away when the connection ends.
/// [_tabModeKey] records that **this tab is a support tab**, and is deliberately
/// permanent for the tab's lifetime.
///
/// Without that second key the storage decisions were made by asking "is there
/// an impersonation token right now?", which stops being true the instant the
/// token is cleared. Starting a second connection revokes the first one
/// server-side, so the stale tab takes a burst of 401s: the first cleared its
/// own token, and every one after it saw no token, concluded it was an ordinary
/// tab, and cleared `localStorage` — **the agent's own session, shared by every
/// tab**. One stale support tab logged the agent out everywhere.
///
/// The mode flag makes the answer a property of the tab rather than of whatever
/// happens to be in storage at that moment.
///
/// Web-only, like the rest of this app (see `analytics_service.dart`,
/// `excel_export_service.dart` for the same direct `package:web` use).
class ImpersonationTokenStore {
  static const String _tokenKey = 'impersonation_session_token';
  static const String _tabModeKey = 'impersonation_tab';

  const ImpersonationTokenStore();

  /// The impersonation token for THIS tab, or null when this tab is an ordinary
  /// session — or when its connection has ended.
  String? read() {
    final token = web.window.sessionStorage.getItem(_tokenKey);
    return (token == null || token.isEmpty) ? null : token;
  }

  void write(String token) {
    web.window.sessionStorage.setItem(_tabModeKey, '1');
    web.window.sessionStorage.setItem(_tokenKey, token);
  }

  /// Ends this tab's connection. The mode flag stays: the tab remains a support
  /// tab and must never fall back to, or clear, the agent's shared session.
  void clearToken() {
    web.window.sessionStorage.removeItem(_tokenKey);
  }

  /// Whether this tab is a support connection. Sticky for as long as the tab
  /// stays one — see the note above.
  bool get isImpersonationTab =>
      web.window.sessionStorage.getItem(_tabModeKey) != null;

  /// Turns this back into an ordinary tab.
  ///
  /// The one thing that legitimately ends "support tab" status is somebody
  /// signing in normally here. Without this, a support tab whose connection was
  /// revoked lands on the login screen, the agent signs in, the token goes to
  /// shared storage — and the tab still reads its own empty support slot, so it
  /// bounces straight back to the login screen. Signing in would never take.
  void clearTab() {
    web.window.sessionStorage.removeItem(_tokenKey);
    web.window.sessionStorage.removeItem(_tabModeKey);
  }
}
