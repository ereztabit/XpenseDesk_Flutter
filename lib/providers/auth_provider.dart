import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import '../models/user_info.dart';
import '../services/auth_service.dart';
import '../services/microsoft_auth_service.dart';
import 'locale_provider.dart';

/// Provider for AuthService singleton
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Provider for the web-only Microsoft (MSAL) sign-in service.
final microsoftAuthServiceProvider = Provider<MicrosoftAuthService>((ref) {
  return const MicrosoftAuthService();
});

/// Provider for current authenticated user info
class UserInfoNotifier extends Notifier<UserInfo?> {
  Future<void>? _sessionRestoreFuture;
  bool _hasAttemptedSessionRestore = false;

  @override
  UserInfo? build() => null;

  void setUserInfo(UserInfo? userInfo, {bool syncLocale = true}) {
    state = userInfo;
    if (userInfo != null && syncLocale) {
      _setLocaleFromUserInfo(userInfo);
    }
  }

  void updateProfile(UserInfo userInfo) {
    state = userInfo;
    _setLocaleFromUserInfo(userInfo);
  }

  /// Load user info from API using stored session
  Future<void> loadFromSession() {
    if (state != null || _hasAttemptedSessionRestore) {
      return Future.value();
    }

    final inFlightRestore = _sessionRestoreFuture;
    if (inFlightRestore != null) {
      return inFlightRestore;
    }

    final future = _loadFromSessionInternal();
    _sessionRestoreFuture = future;
    return future;
  }

  Future<void> _loadFromSessionInternal() async {
    final authService = ref.read(authServiceProvider);

    try {
      final hasToken = await authService.hasSessionToken();
      if (!hasToken) {
        state = null;
        return;
      }

      final userInfo = await authService.getUserInfo();
      state = userInfo;
      _setLocaleFromUserInfo(userInfo);
    } catch (e) {
      // Session expired or invalid - clear it
      await authService.clearSessionToken();
      state = null;
    } finally {
      _hasAttemptedSessionRestore = true;
      _sessionRestoreFuture = null;
    }
  }

  /// Set application locale based on user's language preference
  void _setLocaleFromUserInfo(UserInfo userInfo) {
    final locale = userInfo.languageId == 1 
        ? const Locale('en') 
        : const Locale('he');
    ref.read(localeProvider.notifier).setLocale(locale);
  }

  void logout() {
    state = null;
  }

  /// Called by the global 401 handler. Clears in-memory user state so any
  /// screen watching [userInfoProvider] immediately sees null and redirects.
  void handleUnauthorized() {
    state = null;
  }
}

final userInfoProvider = NotifierProvider<UserInfoNotifier, UserInfo?>(
  UserInfoNotifier.new,
);

/// Why a Microsoft redirect sign-in failed, surfaced on the login screen after
/// the redirect lands the user back on '/'.
enum MicrosoftLoginError { noAccount, failed }

/// Holds why a returning Microsoft sign-in was rejected. Set by
/// [authBootstrapProvider], read by the login screen, cleared on the next attempt.
class MicrosoftLoginErrorNotifier extends Notifier<MicrosoftLoginError?> {
  @override
  MicrosoftLoginError? build() => null;

  void set(MicrosoftLoginError value) => state = value;
  void clear() => state = null;
}

final microsoftLoginErrorProvider =
    NotifierProvider<MicrosoftLoginErrorNotifier, MicrosoftLoginError?>(
  MicrosoftLoginErrorNotifier.new,
);

/// Completes when the app's initial session restore attempt has finished.
///
/// If this page load is the return from a Microsoft redirect sign-in, MSAL has
/// already produced the ID token (web/msal_interop.js). We exchange it for our
/// session token here — before restoring the session — so the normal
/// [loadFromSession] path then finds the stored token and populates the user,
/// and AuthGate routes to the right dashboard. An unknown user is rejected by the
/// server (401 -> AuthException 'MicrosoftNoAccount'); we record it in
/// [microsoftLoginErrorProvider] so the login screen can explain it. A normal
/// load (no pending redirect) just falls through to session restore.
final authBootstrapProvider = FutureProvider<void>((ref) async {
  final config = AppConfig.instance;

  // Only touch the Microsoft flow when the feature is enabled (feature flag).
  if (config.enableMicrosoftLogin) {
    final msAuth = ref.read(microsoftAuthServiceProvider);
    final logs = config.enableMicrosoftLoginLogs;
    if (logs) msAuth.enableLiveLogs();
    try {
      final idToken = await msAuth.getRedirectResult();
      // Flush the glue's buffered log (captures lines emitted before Dart booted).
      if (logs) debugPrint(msAuth.dumpLogs());
      if (idToken.isNotEmpty) {
        await ref.read(authServiceProvider).microsoftLogin(idToken);
      }
    } on AuthException catch (e) {
      if (logs) debugPrint('[MSLogin] rejected: ${e.errorCode ?? e.message}');
      ref.read(microsoftLoginErrorProvider.notifier).set(
            e.errorCode == 'MicrosoftNoAccount'
                ? MicrosoftLoginError.noAccount
                : MicrosoftLoginError.failed,
          );
    } catch (e) {
      if (logs) debugPrint('[MSLogin] unexpected error: $e');
      ref
          .read(microsoftLoginErrorProvider.notifier)
          .set(MicrosoftLoginError.failed);
    }
  }

  await ref.read(userInfoProvider.notifier).loadFromSession();
});

/// Derived provider: locale string for date/currency formatting.
///
/// Tracks the **live** UI locale ([localeProvider]) rather than the persisted
/// `userInfo.languageCode`, so dates and amounts follow the header language
/// switcher immediately (the switcher only sets [localeProvider]; it doesn't
/// persist to the profile). On login [localeProvider] is initialised from the
/// user's saved language, so the two agree until the user toggles the header.
final companyLocaleProvider = Provider<String>((ref) {
  return ref.watch(localeProvider).languageCode;
});

/// The company's base currency code (e.g. "ILS"), used to render every
/// list/sheet/report amount — those endpoints return base-currency values only
/// and no longer carry a per-row `currencyCode`. Defaults to "ILS" until the
/// user's company info has loaded.
final companyBaseCurrencyProvider = Provider<String>((ref) {
  return ref.watch(userInfoProvider)?.currencyCode ?? 'ILS';
});
