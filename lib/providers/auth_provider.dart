import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_info.dart';
import '../services/auth_service.dart';
import 'locale_provider.dart';

/// Provider for AuthService singleton
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Provider for current authenticated user info
class UserInfoNotifier extends Notifier<UserInfo?> {
  Future<void>? _sessionRestoreFuture;
  bool _hasAttemptedSessionRestore = false;

  @override
  UserInfo? build() => null;

  void setUserInfo(UserInfo? userInfo) {
    state = userInfo;
    if (userInfo != null) {
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

/// Completes when the app's initial session restore attempt has finished.
final authBootstrapProvider = FutureProvider<void>((ref) async {
  await ref.read(userInfoProvider.notifier).loadFromSession();
});

/// Derived provider: company locale string for date/currency formatting.
/// Falls back to 'en' if no user is logged in.
final companyLocaleProvider = Provider<String>((ref) {
  return ref.watch(userInfoProvider)?.languageCode ?? 'en';
});
