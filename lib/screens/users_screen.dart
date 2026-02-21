import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../generated/l10n/app_localizations.dart';
import '../providers/users_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/users/user_list_card.dart';
import '../widgets/users/invite_users_dialog.dart';
import '../widgets/constrained_content.dart';
import '../widgets/header/app_header.dart';
import '../widgets/app_footer.dart';
import '../utils/responsive_utils.dart';
import '../theme/app_theme.dart';

class UsersScreen extends ConsumerStatefulWidget {
  const UsersScreen({super.key});

  @override
  ConsumerState<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends ConsumerState<UsersScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeSession();
  }

  Future<void> _initializeSession() async {
    // Check if user info is already loaded (navigating from another page)
    final userInfo = ref.read(userInfoProvider);
    
    if (userInfo == null) {
      // Load user info from API using session token
      await ref.read(userInfoProvider.notifier).loadFromSession();
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Use read instead of watch - we already loaded in initState
    // This prevents unnecessary rebuilds when userInfo provider notifies
    final userInfo = ref.read(userInfoProvider);
    if (userInfo == null) {
      // Navigate back to login if no user info (session expired)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/');
      });
      return const SizedBox.shrink();
    }

    final userStats = ref.watch(userStatsProvider);
    final isNarrow = context.isNarrow;

    return Scaffold(
      body: Column(
        children: [
          const AppHeader(),
          Expanded(
            child: ConstrainedContent(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    // Back button
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => Navigator.pushReplacementNamed(context, '/dashboard'),
                        icon: const Icon(Icons.arrow_back),
                        label: Text(l10n.backToDashboard),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.foreground,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

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
                                  icon: const Icon(Icons.person_add_alt_1),
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
                                icon: const Icon(Icons.person_add_alt_1),
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
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.primary, width: 2),
                        ),
                      ),
                      onChanged: (value) {
                        ref.read(userSearchQueryProvider.notifier).setQuery(value);
                      },
                    ),
                    const SizedBox(height: 24),

                    // User list card
                    SizedBox(
                      height: 600, // Fixed height for scrollable area
                      child: const UserListCard(),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const AppFooter(),
        ],
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
