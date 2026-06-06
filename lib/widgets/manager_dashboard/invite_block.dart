import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../providers/users_provider.dart';
import '../../theme/app_theme.dart';
import '../app_button.dart';
import '../users/invite_users_dialog.dart';

/// Invite block (§6.1) — State A's dominant element. A large, primary-tinted
/// card whose CTA opens the existing bulk-invite dialog. Rendered only when the
/// company has no other active/pending teammates.
class InviteBlock extends ConsumerWidget {
  const InviteBlock({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.primaryTint,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(color: AppTheme.primary.withAlpha(51)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: AppTheme.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.group_add_outlined,
                size: 28, color: AppTheme.primaryForeground),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.managerDashboardInviteHeadline,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.foreground,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.managerDashboardInviteSupporting,
            style: const TextStyle(
              fontSize: 15,
              color: AppTheme.mutedForeground,
            ),
          ),
          const SizedBox(height: 20),
          AppButton(
            label: l10n.managerDashboardInviteCta,
            variant: AppButtonVariant.primary,
            icon: Icons.person_add_alt_1,
            onPressed: () => _openInviteDialog(context, ref),
          ),
        ],
      ),
    );
  }

  void _openInviteDialog(BuildContext context, WidgetRef ref) {
    final remaining = ref.read(userStatsProvider).remaining;
    showDialog<void>(
      context: context,
      builder: (_) => InviteUsersDialog(remainingSlots: remaining),
    );
  }
}
