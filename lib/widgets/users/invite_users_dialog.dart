import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:email_validator/email_validator.dart';
import '../../generated/l10n/app_localizations.dart';
import '../app_button.dart';
import '../../providers/users_provider.dart';
import '../../services/users_service.dart';
import '../../theme/app_theme.dart';
import '../tag_input.dart';

class InviteUsersDialog extends ConsumerStatefulWidget {
  final int remainingSlots;

  const InviteUsersDialog({super.key, required this.remainingSlots});

  @override
  ConsumerState<InviteUsersDialog> createState() => _InviteUsersDialogState();
}

class _InviteUsersDialogState extends ConsumerState<InviteUsersDialog> {
  bool _isLoading = false;
  List<String> _emailList = [];
  Set<String> _conflictEmails = {};
  int _successCount = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final userStats = ref.watch(userStatsProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),

            // Subtitle
            Text(
              '${l10n.usersCount}${userStats.utilized} ${l10n.outOf} ${userStats.capacity}',
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.mutedForeground,
              ),
            ),
            const SizedBox(height: 24),

            // Email tag input
            TagInput(
              tags: _emailList,
              errorTags: _conflictEmails,
              onChanged: (tags) {
                setState(() {
                  final maxEmails = widget.remainingSlots < 20
                      ? widget.remainingSlots
                      : 20;
                  _emailList = tags.take(maxEmails).toList();
                  // Clear resolved conflicts as user removes emails
                  _conflictEmails = _conflictEmails
                      .intersection(_emailList.toSet());
                });
              },
              labelText: l10n.emailAddresses,
              hintText: l10n.pasteOrTypeEmails,
              helperText: () {
                final remaining = widget.remainingSlots - _emailList.length;
                return remaining > 0
                    ? '${l10n.separateWithSpaces} ($remaining ${l10n.slotsRemaining})'
                    : l10n.noSlotsRemaining;
              }(),
              contentTextDirection: TextDirection.ltr,
              enabled: !_isLoading && widget.remainingSlots > 0,
              maxTags: widget.remainingSlots < 20 ? widget.remainingSlots : 20,
              validator: (email) {
                if (!EmailValidator.validate(email)) {
                  return l10n.invalidEmail;
                }
                return null;
              },
            ),

            // Partial success banner
            if (_successCount > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline,
                        size: 18, color: Colors.green.shade700),
                    const SizedBox(width: 8),
                    Text(
                      '${l10n.invitePartialSuccess} $_successCount',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.green.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Inline conflict error — shown when API rejects emails from another company
            if (_conflictEmails.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.error_outline,
                        size: 18, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.inviteEmailBelongsToAnotherCompany,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.red.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AppButton(
                  label: l10n.cancel,
                  variant: AppButtonVariant.ghost,
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                ),
                const SizedBox(width: 12),
                AppButton(
                  label: l10n.inviteUsers,
                  variant: AppButtonVariant.primary,
                  isLoading: _isLoading,
                  onPressed: _emailList.isEmpty || _isLoading
                      ? null
                      : _handleInvite,
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

    // Capture context-dependent references before any async gap —
    // Riverpod rebuilds triggered by the refresh can invalidate context lookups.
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;

    setState(() => _isLoading = true);

    try {
      final service = ref.read(usersServiceProvider);
      await service.inviteUsers(_emailList);

      if (!mounted) return;

      // Refresh users list
      await ref.read(usersListProvider.notifier).refresh();

      navigator.pop();
    } on UsersException catch (e) {
      if (!mounted) return;

      if (e.errorCode == 'UsersInviteEmailBelongsToAnotherCompany' &&
          e.problematicEmails.isNotEmpty) {
        final conflicts = e.problematicEmails.toSet();
        final successCount = _emailList.where((email) => !conflicts.contains(email)).length;
        setState(() {
          _isLoading = false;
          _conflictEmails = conflicts;
          _successCount = successCount;
          // Valid emails were already added server-side — keep only the conflicting ones
          _emailList = _emailList.where((email) => conflicts.contains(email)).toList();
        });
        // Refresh in background so seat count reflects the newly added users
        ref.read(usersListProvider.notifier).refresh();
      } else {
        setState(() => _isLoading = false);
        messenger.showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.anErrorOccurred),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
