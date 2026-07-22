import 'dart:convert';
import 'dart:js_interop';

/// Thrown when starting the Microsoft redirect sign-in fails (MSAL/config error
/// before the tab navigates away). Callers show a generic message.
class MicrosoftSignInException implements Exception {
  final String message;
  const MicrosoftSignInException(this.message);
  @override
  String toString() => message;
}

/// Result of a Microsoft redirect return: the ID token and the opaque `state`
/// the app passed when starting the sign-in ('' when none / normal load).
typedef MicrosoftRedirectResult = ({String idToken, String state});

@JS('xdMsal.signInRedirect')
external JSPromise<JSAny?> _xdMsalSignInRedirect([JSString? state]);

@JS('xdMsal.getRedirectResult')
external JSPromise<JSString> _xdMsalGetRedirectResult();

@JS('xdMsal.acquireTokenSilent')
external JSPromise<JSString> _xdMsalAcquireTokenSilent();

@JS('xdMsal.clearCache')
external JSPromise<JSAny?> _xdMsalClearCache();

@JS('xdMsal.setLogsLive')
external void _xdMsalSetLogsLive(JSBoolean on);

@JS('xdMsal.dumpLog')
external JSString _xdMsalDumpLog();

/// Web-only wrapper over the MSAL.js glue (web/msal_interop.js) using the
/// redirect flow.
class MicrosoftAuthService {
  const MicrosoftAuthService();

  /// State value marking a sign-in started from the onboarding wizard. The
  /// shared redirect return branches on it; client-side routing data only.
  static const String onboardingState = 'onboarding';

  /// Starts the interactive Microsoft sign-in by redirecting the whole tab to
  /// Microsoft. On success the page navigates away, so this normally never
  /// completes; it only throws [MicrosoftSignInException] if the redirect could
  /// not be initiated. [state] is echoed back in the redirect result so the
  /// return load knows which flow started the sign-in.
  Future<void> startSignInRedirect({String? state}) async {
    try {
      await _xdMsalSignInRedirect(state?.toJS).toDart;
    } catch (e) {
      throw MicrosoftSignInException(e.toString());
    }
  }

  /// On the boot after a redirect sign-in, returns the Microsoft ID token and
  /// the echoed state. Both are '' on a normal load or a cancelled/denied
  /// response.
  Future<MicrosoftRedirectResult> getRedirectResult() async {
    try {
      final raw = (await _xdMsalGetRedirectResult().toDart).toDart;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return (
        idToken: json['idToken'] as String? ?? '',
        state: json['state'] as String? ?? '',
      );
    } catch (e) {
      return (idToken: '', state: '');
    }
  }

  /// Silently re-acquires a fresh ID token for the cached account (ID tokens
  /// live ~1h and the user may park on a wizard step). Returns '' when there is
  /// no cached account or renewal fails — caller falls back to the interactive
  /// sign-in.
  Future<String> acquireTokenSilent() async {
    try {
      return (await _xdMsalAcquireTokenSilent().toDart).toDart;
    } catch (e) {
      return '';
    }
  }

  /// Drops the cached MSAL account/tokens without a logout redirect. Used by
  /// "Use a different account" to restart the onboarding flow from scratch.
  Future<void> clearAccountCache() async {
    try {
      await _xdMsalClearCache().toDart;
    } catch (_) {
      /* cache clear is best-effort */
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
