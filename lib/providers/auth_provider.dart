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
  Future<void> loadFromSession() async {
    if (state != null) return; // Already loaded
    
    final authService = ref.read(authServiceProvider);
    
    try {
      final hasToken = await authService.hasSessionToken();
      if (hasToken) {
        final userInfo = await authService.getUserInfo();
        state = userInfo;
        _setLocaleFromUserInfo(userInfo);
      }
    } catch (e) {
      // Session expired or invalid - clear it
      await authService.clearSessionToken();
      state = null;
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
}

final userInfoProvider = NotifierProvider<UserInfoNotifier, UserInfo?>(
  UserInfoNotifier.new,
);
