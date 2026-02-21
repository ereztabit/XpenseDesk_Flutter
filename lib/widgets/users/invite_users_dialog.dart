import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../providers/users_provider.dart';
import '../../services/users_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive_utils.dart';
import '../tag_input.dart';

class InviteUsersDialog extends ConsumerStatefulWidget {
  final int remainingSlots;

  const InviteUsersDialog({
    super.key,
    required this.remainingSlots,
  });

  @override
  ConsumerState<InviteUsersDialog> createState() => _InviteUsersDialogState();
}

class _InviteUsersDialogState extends ConsumerState<InviteUsersDialog> {
  bool _isLoading = false;
  List<String> _emailList = [];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final userStats = ref.watch(userStatsProvider);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              l10n.inviteNewUsers,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            
            // Subtitle
            Text(
              l10n.usersCount(userStats.utilized, userStats.capacity),
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.mutedForeground,
              ),
            ),
            const SizedBox(height: 24),
            
            // Email tag input
            TagInput(
              tags: _emailList,
              onChanged: (tags) {
                setState(() {
                  // Limit to remaining slots and max 20 per batch
                  final maxEmails = widget.remainingSlots < 20 ? widget.remainingSlots : 20;
                  _emailList = tags.take(maxEmails).toList();
                });
              },
              labelText: l10n.emailAddresses,
              hintText: l10n.pasteOrTypeEmails,
              helperText: () {
                final remaining = widget.remainingSlots - _emailList.length;
                return remaining > 0
                    ? l10n.separateWithSpacesSlots(remaining)
                    : l10n.noSlotsRemaining;
              }(),
              enabled: !_isLoading && widget.remainingSlots > 0,
              maxTags: widget.remainingSlots < 20 ? widget.remainingSlots : 20,
              validator: (email) {
                final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
                if (!emailRegex.hasMatch(email)) {
                  return l10n.invalidEmail;
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            
            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  child: Text(l10n.cancel),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _emailList.isEmpty || _isLoading ? null : _handleInvite,
                  child: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.inviteUsers),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleInvite() async {
    if (_emailList.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final service = ref.read(usersServiceProvider);
      await service.inviteUsers(_emailList);

      if (!mounted) return;

      // Refresh users list
      ref.invalidate(usersListProvider);

      // Show success message
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.usersInvitedSuccess),
          backgroundColor: Colors.green,
        ),
      );

      // Close dialog
      Navigator.pop(context);
    } on UsersException catch (e) {
      if (!mounted) return;
      
      setState(() => _isLoading = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      setState(() => _isLoading = false);
      
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.anErrorOccurred),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
