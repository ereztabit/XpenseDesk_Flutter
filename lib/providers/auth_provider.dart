import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_info.dart';
import '../services/auth_service.dart';

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
  }

  void updateProfile(UserInfo userInfo) {
    state = userInfo;
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
      }
    } catch (e) {
      // Session expired or invalid - clear it
      await authService.clearSessionToken();
      state = null;
    }
  }

  void logout() {
    state = null;
  }
}

final userInfoProvider = NotifierProvider<UserInfoNotifier, UserInfo?>(
  UserInfoNotifier.new,
);
