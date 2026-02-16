import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../providers/users_provider.dart';
import '../../services/users_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive_utils.dart';

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
  final _emailController = TextEditingController();
  bool _isLoading = false;
  List<String> _emailList = [];

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final userStats = ref.watch(userStatsProvider);
    final isMobile = context.isNarrow;

    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.inviteNewUsers),
          const SizedBox(height: 4),
          Text(
            l10n.usersCount(userStats.utilized, userStats.capacity),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.normal,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: isMobile ? double.maxFinite : 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Email input field
            TextField(
              controller: _emailController,
              enabled: !_isLoading,
              maxLines: isMobile ? 4 : 3,
              decoration: InputDecoration(
                labelText: l10n.emailAddresses,
                hintText: l10n.pasteOrTypeEmails,
                helperText: widget.remainingSlots > 0
                    ? l10n.separateWithSpacesSlots(widget.remainingSlots)
                    : l10n.noSlotsRemaining,
                helperMaxLines: 2,
              ),
              onChanged: _parseEmails,
            ),
            
            if (_emailList.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                l10n.emailsReadyToInvite(_emailList.length),
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
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
    );
  }

  void _parseEmails(String value) {
    setState(() {
      if (value.trim().isEmpty) {
        _emailList = [];
        return;
      }

      // Split by commas, spaces, semicolons, or newlines
      final parts = value.split(RegExp(r'[,;\s\n]+'));
      
      // Filter valid emails and deduplicate
      final validEmails = <String>{};
      final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
      
      for (var part in parts) {
        final trimmed = part.trim().toLowerCase();
        if (trimmed.isNotEmpty && emailRegex.hasMatch(trimmed)) {
          validEmails.add(trimmed);
        }
      }
      
      // Limit to remaining slots and max 20 per batch
      final maxEmails = widget.remainingSlots < 20 ? widget.remainingSlots : 20;
      _emailList = validEmails.take(maxEmails).toList();
    });
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
