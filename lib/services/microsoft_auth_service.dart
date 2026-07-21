import 'dart:js_interop';

/// Thrown when starting the Microsoft redirect sign-in fails (MSAL/config error
/// before the tab navigates away). Callers show a generic message.
class MicrosoftSignInException implements Exception {
  final String message;
  const MicrosoftSignInException(this.message);
  @override
  String toString() => message;
}

@JS('xdMsal.signInRedirect')
external JSPromise<JSAny?> _xdMsalSignInRedirect();

@JS('xdMsal.getRedirectResult')
external JSPromise<JSString> _xdMsalGetRedirectResult();

@JS('xdMsal.setLogsLive')
external void _xdMsalSetLogsLive(JSBoolean on);

@JS('xdMsal.dumpLog')
external JSString _xdMsalDumpLog();

/// Web-only wrapper over the MSAL.js glue (web/msal_interop.js) using the
/// redirect flow.
class MicrosoftAuthService {
  const MicrosoftAuthService();

  /// Starts the interactive Microsoft sign-in by redirecting the whole tab to
  /// Microsoft. On success the page navigates away, so this normally never
  /// completes; it only throws [MicrosoftSignInException] if the redirect could
  /// not be initiated.
  Future<void> startSignInRedirect() async {
    try {
      await _xdMsalSignInRedirect().toDart;
    } catch (e) {
      throw MicrosoftSignInException(e.toString());
    }
  }

  /// On the /auth/microsoft-callback boot, returns the Microsoft ID token when
  /// this load is the return from a redirect sign-in, or '' otherwise (normal
  /// load, or a cancelled/denied response).
  Future<String> getRedirectResult() async {
    try {
      return (await _xdMsalGetRedirectResult().toDart).toDart;
    } catch (e) {
      return '';
    }
  }

  /// Turn on live console streaming of the glue's diagnostic logs. Gated by the
  /// enableMicrosoftLoginLogs feature flag.
  void enableLiveLogs() {
    try {
      _xdMsalSetLogsLive(true.toJS);
    } catch (_) {
      /* glue not loaded — nothing to enable */
    }
  }

  /// The buffered glue log as one string (includes load-time lines emitted
  /// before Dart booted). Empty if the glue is unavailable.
  String dumpLogs() {
    try {
      return _xdMsalDumpLog().toDart;
    } catch (_) {
      return '';
    }
  }
}
