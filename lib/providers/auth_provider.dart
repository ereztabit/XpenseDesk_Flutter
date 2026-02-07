import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/token_info.dart';
import '../services/auth_service.dart';

/// Provider for AuthService singleton
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Provider for current authenticated user token info
class TokenInfoNotifier extends Notifier<TokenInfo?> {
  @override
  TokenInfo? build() => null;

  void setTokenInfo(TokenInfo? tokenInfo) {
    state = tokenInfo;
  }

  /// Load token info from stored session
  Future<void> loadFromSession() async {
    if (state != null) return; // Already loaded
    
    final authService = ref.read(authServiceProvider);
    
    try {
      final hasToken = await authService.hasSessionToken();
      if (hasToken) {
        final tokenInfo = await authService.getUserInfo();
        state = tokenInfo;
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

final tokenInfoProvider = NotifierProvider<TokenInfoNotifier, TokenInfo?>(
  TokenInfoNotifier.new,
);
