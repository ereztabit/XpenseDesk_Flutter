import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

/// Provider for AuthService singleton
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Provider for current authenticated user
/// Using a simple notifier pattern for state management
class CurrentUserNotifier extends Notifier<User?> {
  @override
  User? build() => null;

  void setUser(User? user) {
    state = user;
  }

  void logout() {
    state = null;
  }
}

final currentUserProvider = NotifierProvider<CurrentUserNotifier, User?>(
  CurrentUserNotifier.new,
);
