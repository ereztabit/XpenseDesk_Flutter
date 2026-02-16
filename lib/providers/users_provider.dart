import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_list_item.dart';
import '../services/users_service.dart';

/// Provider for UsersService singleton
final usersServiceProvider = Provider<UsersService>((ref) {
  return UsersService();
});

/// Provider for users list (async data loading)
final usersListProvider = FutureProvider<List<UserListItem>>((ref) async {
  final service = ref.watch(usersServiceProvider);
  return service.getAllUsers();
});

/// Notifier for managing search query state
class UserSearchNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) {
    state = query;
  }

  void clear() {
    state = '';
  }
}

final userSearchQueryProvider = NotifierProvider<UserSearchNotifier, String>(
  UserSearchNotifier.new,
);

/// Provider for filtered users based on search query
final filteredUsersProvider = Provider<List<UserListItem>>((ref) {
  final usersAsync = ref.watch(usersListProvider);
  final searchQuery = ref.watch(userSearchQueryProvider);

  return usersAsync.when(
    data: (users) {
      if (searchQuery.isEmpty) return users;
      
      final lowerQuery = searchQuery.toLowerCase();
      return users.where((user) {
        return user.fullName.toLowerCase().contains(lowerQuery) ||
               user.email.toLowerCase().contains(lowerQuery);
      }).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

/// User statistics model
class UserStats {
  final int utilized;
  final int capacity;
  final int remaining;
  final int activeCount;
  final int pendingCount;
  final int disabledCount;

  const UserStats({
    required this.utilized,
    required this.capacity,
    required this.remaining,
    required this.activeCount,
    required this.pendingCount,
    required this.disabledCount,
  });

  bool get hasRemainingSlots => remaining > 0;
  bool get isAtCapacity => remaining <= 0;
}

/// Provider for user count statistics
final userStatsProvider = Provider<UserStats>((ref) {
  final usersAsync = ref.watch(usersListProvider);

  return usersAsync.when(
    data: (users) {
      final activeCount = users.where((u) => u.isActive).length;
      final pendingCount = users.where((u) => u.isPending).length;
      final disabledCount = users.where((u) => u.isDisabled).length;
      final utilized = activeCount + pendingCount;
      
      return UserStats(
        utilized: utilized,
        capacity: 15,
        remaining: 15 - utilized,
        activeCount: activeCount,
        pendingCount: pendingCount,
        disabledCount: disabledCount,
      );
    },
    loading: () => const UserStats(
      utilized: 0,
      capacity: 15,
      remaining: 15,
      activeCount: 0,
      pendingCount: 0,
      disabledCount: 0,
    ),
    error: (_, __) => const UserStats(
      utilized: 0,
      capacity: 15,
      remaining: 15,
      activeCount: 0,
      pendingCount: 0,
      disabledCount: 0,
    ),
  );
});
