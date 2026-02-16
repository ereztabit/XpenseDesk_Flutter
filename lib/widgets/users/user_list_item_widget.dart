import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/user_list_item.dart';
import '../../theme/app_theme.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../utils/responsive_utils.dart';

class UserListItemWidget extends StatelessWidget {
  final UserListItem user;
  final bool isCurrentUser;
  final VoidCallback? onPromote;
  final VoidCallback? onDemote;
  final VoidCallback? onDisable;
  final VoidCallback? onEnable;

  const UserListItemWidget({
    super.key,
    required this.user,
    required this.isCurrentUser,
    this.onPromote,
    this.onDemote,
    this.onDisable,
    this.onEnable,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (context.isNarrow) {
      return _buildMobileLayout(context, l10n);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Avatar with initials
          _buildAvatar(),
          const SizedBox(width: 16),
          
          // Name and email column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildNameRow(context, l10n),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(child: _buildEmail()),
                    if (user.isPending && user.invitedDate != null) ...[
                      const SizedBox(width: 8),
                      _buildInvitedDate(context, l10n),
                    ],
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Status badge
          _buildStatusBadge(l10n),
          const SizedBox(width: 8),
          
          // Role badge
          _buildRoleBadge(l10n),
          
          // Actions menu (hidden for current user)
          if (!isCurrentUser) ...[
            const SizedBox(width: 8),
            _buildActionsMenu(context, l10n),
          ],
        ],
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar (smaller on mobile)
              CircleAvatar(
                radius: 16,
                backgroundColor: user.isDisabled
                    ? Colors.grey.withAlpha(51)
                    : AppTheme.primary.withAlpha(26),
                child: Text(
                  user.initials,
                  style: TextStyle(
                    color: user.isDisabled ? Colors.grey : AppTheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // Name and email
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildNameRow(context, l10n),
                    const SizedBox(height: 2),
                    _buildEmail(),
                  ],
                ),
              ),
              
              // Actions menu
              if (!isCurrentUser)
                _buildActionsMenu(context, l10n),
            ],
          ),
          
          // Badges row
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildStatusBadge(l10n),
              _buildRoleBadge(l10n),
              if (user.isPending && user.invitedDate != null)
                _buildInvitedDate(context, l10n),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    final isDimmed = user.isDisabled;
    final backgroundColor = isDimmed
        ? Colors.grey.withAlpha(51)
        : AppTheme.primary.withAlpha(26);
    final textColor = isDimmed ? Colors.grey : AppTheme.primary;

    return CircleAvatar(
      radius: 20,
      backgroundColor: backgroundColor,
      child: Text(
        user.initials,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildNameRow(BuildContext context, AppLocalizations l10n) {
    final isDimmed = user.isDisabled;
    final textColor = isDimmed ? Colors.grey : null;

    return Row(
      children: [
        Text(
          user.fullName.isEmpty ? user.email : user.fullName,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: textColor,
          ),
        ),
        if (isCurrentUser) ...[
          const SizedBox(width: 8),
          Text(
            '(you)',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEmail() {
    return Text(
      user.email,
      style: TextStyle(
        fontSize: 14,
        color: Colors.grey.shade600,
      ),
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildInvitedDate(BuildContext context, AppLocalizations l10n) {
    final dateFormat = DateFormat('MMM d, yyyy', l10n.localeName);
    final formattedDate = dateFormat.format(user.invitedDate!);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.withAlpha(26),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.schedule,
            size: 12,
            color: Colors.grey.shade600,
          ),
          const SizedBox(width: 4),
          Text(
            'Invited on $formattedDate',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(AppLocalizations l10n) {
    final String label;
    final Color backgroundColor;
    final Color textColor;

    if (user.isActive) {
      label = l10n.active;
      backgroundColor = AppTheme.primary.withAlpha(26);
      textColor = AppTheme.primary;
    } else if (user.isPending) {
      label = l10n.pending;
      backgroundColor = Colors.purple.withAlpha(26);
      textColor = Colors.purple;
    } else {
      label = l10n.disabled;
      backgroundColor = Colors.grey.withAlpha(26);
      textColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildRoleBadge(AppLocalizations l10n) {
    final isManager = user.roleId == 1;
    final label = isManager ? l10n.manager : l10n.employee;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isManager ? AppTheme.primary : Colors.grey.withAlpha(26),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isManager ? Colors.white : Colors.grey.shade700,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildActionsMenu(BuildContext context, AppLocalizations l10n) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      tooltip: 'Actions',
      itemBuilder: (context) => [
        // Promote/Demote option
        PopupMenuItem(
          value: user.roleId == 1 ? 'demote' : 'promote',
          child: Row(
            children: [
              Icon(
                Icons.shield_outlined,
                size: 20,
                color: Colors.grey.shade700,
              ),
              const SizedBox(width: 12),
              Text(
                user.roleId == 1 ? l10n.demoteToEmployee : l10n.promoteToManager,
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        // Disable/Enable option
        PopupMenuItem(
          value: user.isDisabled ? 'enable' : 'disable',
          child: Row(
            children: [
              Icon(
                user.isDisabled ? Icons.check_circle_outline : Icons.block,
                size: 20,
                color: user.isDisabled ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 12),
              Text(
                user.isDisabled ? l10n.enable : l10n.disable,
                style: TextStyle(
                  color: user.isDisabled ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        switch (value) {
          case 'promote':
            onPromote?.call();
            break;
          case 'demote':
            onDemote?.call();
            break;
          case 'disable':
            onDisable?.call();
            break;
          case 'enable':
            onEnable?.call();
            break;
        }
      },
    );
  }
}
