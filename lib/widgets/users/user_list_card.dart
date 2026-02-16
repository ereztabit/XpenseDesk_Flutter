import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../models/user_list_item.dart';
import '../../providers/users_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/users_service.dart';
import 'user_list_item_widget.dart';

class UserListCard extends ConsumerWidget {
  const UserListCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(usersListProvider);
    final filteredUsers = ref.watch(filteredUsersProvider);
    final currentUser = ref.watch(userInfoProvider);

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.people, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Users',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // User list content
          Expanded(
            child: usersAsync.when(
              data: (users) {
                if (filteredUsers.isEmpty) {
                  return _buildEmptyState(context, ref);
                }
                return _buildUserList(context, ref, filteredUsers, currentUser?.email);
              },
              loading: () => _buildLoadingState(),
              error: (err, stack) => _buildErrorState(context, err),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList(
    BuildContext context,
    WidgetRef ref,
    List<UserListItem> users,
    String? currentUserEmail,
  ) {
    return ListView.separated(
      itemCount: users.length,
      separatorBuilder: (context, index) => const Divider(height: 1, indent: 72),
      itemBuilder: (context, index) {
        final user = users[index];
        final isCurrentUser = user.email == currentUserEmail;

        return UserListItemWidget(
          user: user,
          isCurrentUser: isCurrentUser,
          onPromote: () => _handlePromote(context, ref, user),
          onDemote: () => _handleDemote(context, ref, user),
          onDisable: () => _handleDisable(context, ref, user),
          onEnable: () => _handleEnable(context, ref, user),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    final searchQuery = ref.read(userSearchQueryProvider);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              searchQuery.isEmpty ? Icons.people_outline : Icons.search_off,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              searchQuery.isEmpty
                  ? 'No users found'
                  : 'No users match your search',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              searchQuery.isEmpty
                  ? 'Invite users to get started'
                  : 'Try a different search term',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(48),
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    final l10n = AppLocalizations.of(context)!;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.failedToLoadUsers,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handlePromote(BuildContext context, WidgetRef ref, UserListItem user) async {
    final confirmed = await _showRoleChangeConfirmation(
      context,
      user,
      isPromotion: true,
    );

    if (!confirmed || !context.mounted) return;

    final l10n = AppLocalizations.of(context)!;

    try {
      final service = ref.read(usersServiceProvider);
      await service.promoteToAdmin(user.userId);

      if (!context.mounted) return;

      // Refresh users list
      ref.invalidate(usersListProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.userPromotedSuccess),
          backgroundColor: Colors.green,
        ),
      );
    } on UsersException catch (e) {
      if (!context.mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.anErrorOccurred),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleDemote(BuildContext context, WidgetRef ref, UserListItem user) async {
    final confirmed = await _showRoleChangeConfirmation(
      context,
      user,
      isPromotion: false,
    );

    if (!confirmed || !context.mounted) return;

    final l10n = AppLocalizations.of(context)!;

    try {
      final service = ref.read(usersServiceProvider);
      await service.downgradeToEmployee(user.userId);

      if (!context.mounted) return;

      // Refresh users list
      ref.invalidate(usersListProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.userDemotedSuccess),
          backgroundColor: Colors.green,
        ),
      );
    } on UsersException catch (e) {
      if (!context.mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.anErrorOccurred),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleDisable(BuildContext context, WidgetRef ref, UserListItem user) async {
    final confirmed = await _showDisableConfirmation(context, user);

    if (!confirmed || !context.mounted) return;

    final l10n = AppLocalizations.of(context)!;

    try {
      final service = ref.read(usersServiceProvider);
      await service.disableUser(user.userId);

      if (!context.mounted) return;

      // Refresh users list
      ref.invalidate(usersListProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.userDisabledSuccess),
          backgroundColor: Colors.green,
        ),
      );
    } on UsersException catch (e) {
      if (!context.mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.anErrorOccurred),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleEnable(BuildContext context, WidgetRef ref, UserListItem user) async {
    final l10n = AppLocalizations.of(context)!;

    try {
      final service = ref.read(usersServiceProvider);
      await service.enableUser(user.userId);

      if (!context.mounted) return;

      // Refresh users list
      ref.invalidate(usersListProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.userEnabledSuccess),
          backgroundColor: Colors.green,
        ),
      );
    } on UsersException catch (e) {
      if (!context.mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.anErrorOccurred),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<bool> _showRoleChangeConfirmation(
    BuildContext context,
    UserListItem user,
    {required bool isPromotion}
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final userName = user.fullName.isEmpty ? user.email : user.fullName;

    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.changeRoleTitle),
        content: Text(
          isPromotion 
            ? l10n.promoteConfirmMessage(userName)
            : l10n.demoteConfirmMessage(userName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<bool> _showDisableConfirmation(
    BuildContext context,
    UserListItem user,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final userName = user.fullName.isEmpty ? user.email : user.fullName;

    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.disableUserTitle),
        content: Text(l10n.disableUserMessage(userName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(l10n.disable),
          ),
        ],
      ),
    ) ?? false;
  }
}
