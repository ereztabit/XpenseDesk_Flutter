import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../generated/l10n/app_localizations.dart';
import '../providers/users_provider.dart';
import '../widgets/users/user_list_card.dart';
import '../widgets/users/invite_users_dialog.dart';
import '../utils/responsive_utils.dart';

class UsersScreen extends ConsumerWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final userStats = ref.watch(userStatsProvider);
    final isNarrow = context.isNarrow;
    final isMobile = context.isMobile;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
          tooltip: l10n.backToDashboard,
        ),
        title: Text(l10n.manageUsers),
      ),
      body: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Column(
          children: [
            // Header bar with counter and invite button
            isNarrow
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.usersCount(userStats.utilized, userStats.capacity),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          icon: const Icon(Icons.person_add),
                          label: Text(l10n.inviteUsers),
                          onPressed: userStats.hasRemainingSlots
                              ? () => _showInviteDialog(context, ref, userStats.remaining)
                              : null,
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.usersCount(userStats.utilized, userStats.capacity),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      FilledButton.icon(
                        icon: const Icon(Icons.person_add),
                        label: Text(l10n.inviteUsers),
                        onPressed: userStats.hasRemainingSlots
                            ? () => _showInviteDialog(context, ref, userStats.remaining)
                            : null,
                      ),
                    ],
                  ),
            const SizedBox(height: 24),

            // Search bar
            TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: l10n.searchByNameOrEmail,
              ),
              onChanged: (value) {
                ref.read(userSearchQueryProvider.notifier).setQuery(value);
              },
            ),
            const SizedBox(height: 24),

            // User list card
            const Expanded(
              child: UserListCard(),
            ),
          ],
        ),
      ),
    );
  }

  void _showInviteDialog(BuildContext context, WidgetRef ref, int remainingSlots) {
    showDialog(
      context: context,
      builder: (context) => InviteUsersDialog(
        remainingSlots: remainingSlots,
      ),
    );
  }
}
