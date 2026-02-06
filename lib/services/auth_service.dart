import '../models/user.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
}

class AuthService {
  User? _currentUser;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  Future<User> login(String email) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Mock authentication logic
    if (email == 'erez0502760106@gmail.com') {
      _currentUser = User(email: email, role: UserRole.admin);
      return _currentUser!;
    } else if (email == 'user@domain.com') {
      _currentUser = User(email: email, role: UserRole.employee);
      return _currentUser!;
    } else {
      throw AuthException('Unable to login. Invalid credentials.');
    }
  }

  void logout() {
    _currentUser = null;
  }
}
