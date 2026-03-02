import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_list_item.dart';
import '../services/users_service.dart';

/// Provider for UsersService singleton
final usersServiceProvider = Provider<UsersService>((ref) {
  return UsersService();
});

/// Notifier for the users list.
/// Uses keepAlive so error state is sticky — the API is not retried
/// automatically on rebuild. Call [refresh] explicitly (e.g. Retry button).
class UsersListNotifier extends AsyncNotifier<List<UserListItem>> {
  @override
  Future<List<UserListItem>> build() async {
    // Keep alive: prevent auto-dispose so the error state is never silently
    // discarded and the API call never re-fires on its own.
    ref.keepAlive();
    return _fetchUsers();
  }

  Future<List<UserListItem>> _fetchUsers() async {
    final service = ref.read(usersServiceProvider);
    return service.getAllUsers();
  }

  /// Explicitly reload the list (e.g. after Retry or a mutation).
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchUsers);
  }
}

final usersListProvider =
    AsyncNotifierProvider<UsersListNotifier, List<UserListItem>>(
  UsersListNotifier.new,
);

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
    error: (_, _) => [],
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
    error: (_, _) => const UserStats(
      utilized: 0,
      capacity: 15,
      remaining: 15,
      activeCount: 0,
      pendingCount: 0,
      disabledCount: 0,
    ),
  );
});
